/**
 * admin_ext.js — Extended admin routes
 *
 * Implements the missing features from docs/MISSING-FEATURES.md:
 *   - Customer block / unblock with reason + audit log
 *   - Customer balance adjustment (admin manual)
 *   - Trip refund with reason
 *   - Prepaid bulk generator
 *   - Push notification composer with segment targeting
 *   - Scooter decommission / retire
 *   - Scooter telemetry history
 *   - Scooter command history
 *   - Support ticket close / reopen / assign
 *   - Audit log filters
 *
 * Mount at: app.use('/v1/admin', require('./route/admin_ext.js'))
 */

const express = require('express');
const router = express.Router();
const { MongoClient, ObjectId } = require('mongodb');
const crypto = require('crypto');
const sanitize = require('mongo-sanitize');
const authModel = require('../models/auth.js');

const mongoURI = process.env.DBURI;
const DB_NAME = 'spark-rentals';

// Helper: open a mongo client
async function withDb(fn) {
    const client = new MongoClient(mongoURI);
    try {
        await client.connect();
        const db = client.db(DB_NAME);
        return await fn(db);
    } finally {
        await client.close();
    }
}

// Helper: append to audit_log
async function appendAudit(db, entry) {
    await db.collection('audit_log').insertOne({
        timestamp: new Date(),
        actor: entry.actor || 'system',
        action: entry.action,
        entity: entry.entity,
        entity_id: entry.entity_id,
        ip: entry.ip || null,
        details: entry.details || {},
        ...entry.extra,
    });
}

// Helper: require admin
function requireAdmin(req, res, next) {
    authModel.checkValidAdmin(req, res, next);
}

// =====================================================
// 1. Customer block / unblock
// =====================================================
router.post('/users/:id/block', requireAdmin, async (req, res) => {
    const userId = sanitize(req.params.id);
    const reason = String(sanitize(req.body.reason) || '').slice(0, 500);
    if (!reason) return res.status(400).json({ errors: { status: 400, source: '/admin/users/block', title: 'reason required' } });

    try {
        const result = await withDb(async db => {
            const r = await db.collection('users').updateOne(
                { _id: new ObjectId(userId) },
                { $set: { status: 'blocked', blocked_reason: reason, blocked_at: new Date() } }
            );
            await appendAudit(db, {
                actor: req.user?.email || 'admin',
                action: 'user.block',
                entity: 'user',
                entity_id: userId,
                ip: req.ip,
                details: { reason },
            });
            return r;
        });
        if (result.matchedCount === 0) return res.status(404).json({ errors: { status: 404, title: 'user not found' } });
        res.status(200).json({ data: { type: 'success', message: 'user blocked' } });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

router.post('/users/:id/unblock', requireAdmin, async (req, res) => {
    const userId = sanitize(req.params.id);
    try {
        const result = await withDb(async db => {
            const r = await db.collection('users').updateOne(
                { _id: new ObjectId(userId) },
                { $set: { status: 'active_user' }, $unset: { blocked_reason: '', blocked_at: '' } }
            );
            await appendAudit(db, {
                actor: req.user?.email || 'admin',
                action: 'user.unblock',
                entity: 'user',
                entity_id: userId,
                ip: req.ip,
            });
            return r;
        });
        if (result.matchedCount === 0) return res.status(404).json({ errors: { status: 404, title: 'user not found' } });
        res.status(200).json({ data: { type: 'success', message: 'user unblocked' } });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

// =====================================================
// 2. Customer balance adjustment (admin)
// =====================================================
router.post('/users/:id/adjust-balance', requireAdmin, async (req, res) => {
    const userId = sanitize(req.params.id);
    const delta = parseFloat(sanitize(req.body.delta));  // can be negative
    const reason = String(sanitize(req.body.reason) || '').slice(0, 500);
    if (isNaN(delta) || !reason) return res.status(400).json({ errors: { status: 400, title: 'delta (number) and reason required' } });

    try {
        const result = await withDb(async db => {
            const user = await db.collection('users').findOne({ _id: new ObjectId(userId) });
            if (!user) return null;
            const newBalance = (user.balance || 0) + delta;
            if (newBalance < 0) return { error: 'balance would be negative' };
            await db.collection('users').updateOne(
                { _id: user._id },
                { $set: { balance: newBalance, updated_at: new Date() } }
            );
            await db.collection('transactions').insertOne({
                user_id: user._id,
                type: 'admin_adjustment',
                amount: delta,
                currency: 'UZS',
                reason,
                admin_email: req.user?.email || 'admin',
                created_at: new Date(),
            });
            await appendAudit(db, {
                actor: req.user?.email || 'admin',
                action: 'user.adjust_balance',
                entity: 'user',
                entity_id: userId,
                ip: req.ip,
                details: { delta, reason, new_balance: newBalance },
            });
            return { newBalance };
        });
        if (!result) return res.status(404).json({ errors: { status: 404, title: 'user not found' } });
        if (result.error) return res.status(400).json({ errors: { status: 400, title: result.error } });
        res.status(200).json({ data: { type: 'success', new_balance: result.newBalance } });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

// =====================================================
// 3. Trip refund with reason
// =====================================================
router.post('/trips/:id/refund', requireAdmin, async (req, res) => {
    const tripId = sanitize(req.params.id);
    const amount = parseFloat(sanitize(req.body.amount));
    const reason = String(sanitize(req.body.reason) || '').slice(0, 500);
    if (isNaN(amount) || amount <= 0 || !reason) {
        return res.status(400).json({ errors: { status: 400, title: 'amount (>0) and reason required' } });
    }
    try {
        const result = await withDb(async db => {
            const trip = await db.collection('trips').findOne({ _id: new ObjectId(tripId) });
            if (!trip) return null;
            if (amount > (trip.cost || 0)) return { error: 'refund exceeds trip cost' };
            // Refund to user balance
            await db.collection('users').updateOne(
                { _id: new ObjectId(trip.user_id) },
                { $inc: { balance: amount } }
            );
            // Mark trip as refunded
            await db.collection('trips').updateOne(
                { _id: trip._id },
                { $set: { refunded: true, refund_amount: amount, refund_reason: reason, refunded_at: new Date() } }
            );
            await db.collection('transactions').insertOne({
                trip_id: trip._id,
                user_id: trip.user_id,
                type: 'refund',
                amount: amount,
                currency: 'UZS',
                reason,
                admin_email: req.user?.email || 'admin',
                created_at: new Date(),
            });
            await appendAudit(db, {
                actor: req.user?.email || 'admin',
                action: 'trip.refund',
                entity: 'trip',
                entity_id: tripId,
                ip: req.ip,
                details: { amount, reason },
            });
            return { ok: true };
        });
        if (!result) return res.status(404).json({ errors: { status: 404, title: 'trip not found' } });
        if (result.error) return res.status(400).json({ errors: { status: 400, title: result.error } });
        res.status(200).json({ data: { type: 'success', message: 'refund processed' } });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

// =====================================================
// 4. Prepaid bulk generator
// =====================================================
router.post('/prepaids/bulk', requireAdmin, async (req, res) => {
    const count = Math.min(parseInt(sanitize(req.body.count)) || 0, 1000);
    const amount = parseFloat(sanitize(req.body.amount));
    const prefix = String(sanitize(req.body.prefix) || 'VIRENT').slice(0, 12).toUpperCase();
    const expiresInDays = parseInt(sanitize(req.body.expires_in_days)) || 365;
    if (!count || count < 1 || isNaN(amount) || amount <= 0) {
        return res.status(400).json({ errors: { status: 400, title: 'count (1..1000) and amount (>0) required' } });
    }
    const expiresAt = new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000);
    const cards = [];
    for (let i = 0; i < count; i++) {
        const rand = crypto.randomBytes(6).toString('hex').toUpperCase();
        cards.push({
            code: `${prefix}-${rand}`,
            amount,
            currency: 'UZS',
            status: 'unused',
            used_by: null,
            used_at: null,
            expires_at: expiresAt,
            batch: prefix,
            created_at: new Date(),
        });
    }
    try {
        const result = await withDb(async db => {
            const r = await db.collection('prepaids').insertMany(cards);
            await appendAudit(db, {
                actor: req.user?.email || 'admin',
                action: 'prepaid.bulk_create',
                entity: 'prepaid',
                entity_id: prefix,
                ip: req.ip,
                details: { count, amount, prefix, expires_at: expiresAt },
            });
            return r;
        });
        res.status(201).json({ data: { type: 'success', count: result.insertedCount, codes: cards.map(c => c.code) } });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

// =====================================================
// 5. Push notification composer
// =====================================================
router.post('/notifications/send', requireAdmin, async (req, res) => {
    const title = String(sanitize(req.body.title) || '').slice(0, 200);
    const body = String(sanitize(req.body.body) || '').slice(0, 1000);
    const segment = sanitize(req.body.segment) || 'all'; // all | active | city:ID | blocked
    const scheduledAt = sanitize(req.body.scheduled_at) ? new Date(sanitize(req.body.scheduled_at)) : null;
    if (!title || !body) return res.status(400).json({ errors: { status: 400, title: 'title and body required' } });

    try {
        const result = await withDb(async db => {
            // Build user filter from segment
            let filter = {};
            if (segment === 'active') filter.status = 'active_user';
            else if (segment === 'blocked') filter.status = 'blocked';
            else if (segment.startsWith('city:')) filter.city_id = segment.slice(5);

            const users = await db.collection('users').find(filter, { projection: { _id: 1 } }).toArray();
            const r = await db.collection('notifications').insertOne({
                title,
                body,
                segment,
                status: scheduledAt ? 'scheduled' : 'sent',
                scheduled_at: scheduledAt,
                sent_at: scheduledAt ? null : new Date(),
                target_count: users.length,
                delivered_count: 0,
                read_count: 0,
                created_by: req.user?.email || 'admin',
                created_at: new Date(),
            });
            await appendAudit(db, {
                actor: req.user?.email || 'admin',
                action: 'notification.send',
                entity: 'notification',
                entity_id: r.insertedId.toString(),
                ip: req.ip,
                details: { title, segment, target_count: users.length, scheduled_at: scheduledAt },
            });
            return { id: r.insertedId, target_count: users.length };
        });
        res.status(201).json({ data: { type: 'success', notification_id: result.id, target_count: result.target_count } });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

// Notification delivery stats
router.get('/notifications/stats', requireAdmin, async (req, res) => {
    try {
        const stats = await withDb(async db => {
            return await db.collection('notifications')
                .find({})
                .sort({ created_at: -1 })
                .limit(50)
                .project({ title: 1, segment: 1, status: 1, target_count: 1, delivered_count: 1, read_count: 1, sent_at: 1, scheduled_at: 1 })
                .toArray();
        });
        res.status(200).json({ data: stats });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

// =====================================================
// 6. Scooter decommission / retire
// =====================================================
router.post('/scooters/:id/retire', requireAdmin, async (req, res) => {
    const scooterId = sanitize(req.params.id);
    const reason = String(sanitize(req.body.reason) || '').slice(0, 500);
    if (!reason) return res.status(400).json({ errors: { status: 400, title: 'reason required' } });
    try {
        const result = await withDb(async db => {
            const r = await db.collection('scooters').updateOne(
                { _id: new ObjectId(scooterId) },
                { $set: { status: 'retired', retired_at: new Date(), retired_reason: reason } }
            );
            await appendAudit(db, {
                actor: req.user?.email || 'admin',
                action: 'scooter.retire',
                entity: 'scooter',
                entity_id: scooterId,
                ip: req.ip,
                details: { reason },
            });
            return r;
        });
        if (result.matchedCount === 0) return res.status(404).json({ errors: { status: 404, title: 'scooter not found' } });
        res.status(200).json({ data: { type: 'success', message: 'scooter retired' } });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

// =====================================================
// 7. Scooter telemetry history
// =====================================================
router.get('/scooters/:id/telemetry', requireAdmin, async (req, res) => {
    const scooterId = sanitize(req.params.id);
    const limit = Math.min(parseInt(sanitize(req.query.limit)) || 100, 1000);
    try {
        const data = await withDb(async db => {
            const scooter = await db.collection('scooters').findOne(
                { _id: new ObjectId(scooterId) },
                { projection: { telemetry_log: { $slice: -limit } } }
            );
            return scooter?.telemetry_log || [];
        });
        res.status(200).json({ data });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

// =====================================================
// 8. Scooter command history
// =====================================================
router.get('/scooters/:id/commands', requireAdmin, async (req, res) => {
    const scooterId = sanitize(req.params.id);
    const limit = Math.min(parseInt(sanitize(req.query.limit)) || 50, 500);
    try {
        const data = await withDb(async db => {
            const scooter = await db.collection('scooters').findOne({ _id: new ObjectId(scooterId) });
            if (!scooter) return [];
            return await db.collection('scooter_commands')
                .find({ scooter_mac: scooter.mac_address })
                .sort({ created_at: -1 })
                .limit(limit)
                .toArray();
        });
        res.status(200).json({ data });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

// =====================================================
// 9. Support ticket close / reopen / assign
// =====================================================
router.post('/support/:id/close', requireAdmin, async (req, res) => {
    const ticketId = sanitize(req.params.id);
    const resolution = String(sanitize(req.body.resolution) || '').slice(0, 1000);
    try {
        const result = await withDb(async db => {
            return await db.collection('support_tickets').updateOne(
                { _id: new ObjectId(ticketId) },
                { $set: { status: 'closed', resolution, closed_at: new Date() } }
            );
        });
        if (result.matchedCount === 0) return res.status(404).json({ errors: { status: 404, title: 'ticket not found' } });
        res.status(200).json({ data: { type: 'success' } });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

router.post('/support/:id/reopen', requireAdmin, async (req, res) => {
    const ticketId = sanitize(req.params.id);
    try {
        const result = await withDb(async db => {
            return await db.collection('support_tickets').updateOne(
                { _id: new ObjectId(ticketId) },
                { $set: { status: 'open', reopened_at: new Date() }, $unset: { resolution: '', closed_at: '' } }
            );
        });
        if (result.matchedCount === 0) return res.status(404).json({ errors: { status: 404, title: 'ticket not found' } });
        res.status(200).json({ data: { type: 'success' } });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

router.post('/support/:id/assign', requireAdmin, async (req, res) => {
    const ticketId = sanitize(req.params.id);
    const assignee = String(sanitize(req.body.assignee) || '').slice(0, 200);
    if (!assignee) return res.status(400).json({ errors: { status: 400, title: 'assignee required' } });
    try {
        const result = await withDb(async db => {
            return await db.collection('support_tickets').updateOne(
                { _id: new ObjectId(ticketId) },
                { $set: { assigned_to: assignee, assigned_at: new Date() } }
            );
        });
        if (result.matchedCount === 0) return res.status(404).json({ errors: { status: 404, title: 'ticket not found' } });
        res.status(200).json({ data: { type: 'success' } });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

// =====================================================
// 10. Audit log filters
// =====================================================
router.get('/audit-log', requireAdmin, async (req, res) => {
    const actor = sanitize(req.query.actor);
    const action = sanitize(req.query.action);
    const entity = sanitize(req.query.entity);
    const fromDate = sanitize(req.query.from) ? new Date(sanitize(req.query.from)) : null;
    const toDate = sanitize(req.query.to) ? new Date(sanitize(req.query.to)) : null;
    const limit = Math.min(parseInt(sanitize(req.query.limit)) || 100, 1000);

    const filter = {};
    if (actor) filter.actor = { $regex: actor, $options: 'i' };
    if (action) filter.action = action;
    if (entity) filter.entity = entity;
    if (fromDate || toDate) {
        filter.timestamp = {};
        if (fromDate) filter.timestamp.$gte = fromDate;
        if (toDate) filter.timestamp.$lte = toDate;
    }

    try {
        const data = await withDb(async db => {
            return await db.collection('audit_log')
                .find(filter)
                .sort({ timestamp: -1 })
                .limit(limit)
                .toArray();
        });
        res.status(200).json({ data, count: data.length, filter });
    } catch (e) {
        res.status(500).json({ errors: { status: 500, title: e.message } });
    }
});

module.exports = router;
