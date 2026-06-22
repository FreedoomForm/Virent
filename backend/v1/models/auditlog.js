/**
 * auditlog.js — audit log for admin actions
 *
 * Records every mutation performed by admins (and later, juicers/mechanics):
 *   actor_id, actor_role, action, target_type, target_id, before, after, ip, user_agent, timestamp
 *
 * Used for compliance, dispute resolution, and forensic analysis.
 *
 * MongoDB TTL index on `retention_expires` keeps logs for 1 year by default.
 */
const { MongoClient, ObjectId } = require('mongodb');
const mongoURI = process.env.DBURI;

const auditlog = {
    /**
     * Internal: log an action. Not exposed via API directly.
     */
    log: async function(entry) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("audit_log");
            const now = new Date();
            const retentionExpires = new Date(
                now.getTime() + 365 * 24 * 3600 * 1000 // 1 year
            );
            await col.insertOne({
                actor_id: entry.actor_id ? new ObjectId(entry.actor_id) : null,
                actor_role: entry.actor_role || 'system',
                actor_email: entry.actor_email || null,
                action: entry.action, // e.g. 'scooter.create', 'user.delete', 'trip.refund'
                target_type: entry.target_type, // 'scooter', 'user', 'city', 'trip'
                target_id: entry.target_id ? String(entry.target_id) : null,
                before: entry.before || null,
                after: entry.after || null,
                ip: entry.ip || null,
                user_agent: entry.user_agent || null,
                timestamp: now,
                retention_expires: retentionExpires,
            });
        } catch (e) {
            console.error('[auditlog] Failed to log:', e.message);
        } finally { await client.close(); }
    },

    /**
     * Admin: GET /audit-log
     * Filter by actor_id, action, target_type, from, to
     */
    query: async function(res, query, path) {
        const limit = Math.min(parseInt(query.limit || '100'), 500);
        const offset = Math.max(parseInt(query.offset || '0'), 0);
        const filter = {};
        if (query.actor_id && ObjectId.isValid(query.actor_id))
            filter.actor_id = new ObjectId(query.actor_id);
        if (query.action) filter.action = query.action;
        if (query.target_type) filter.target_type = query.target_type;
        if (query.target_id) filter.target_id = query.target_id;
        if (query.from || query.to) {
            filter.timestamp = {};
            if (query.from) filter.timestamp.$gte = new Date(query.from);
            if (query.to) filter.timestamp.$lte = new Date(query.to);
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("audit_log");
            const items = await col.find(filter).sort({ timestamp: -1 })
                .skip(offset).limit(limit).toArray();
            const total = await col.countDocuments(filter);
            return res.status(200).json({ data: { log: items, total, limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },
};

module.exports = auditlog;
