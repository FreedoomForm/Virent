/**
 * notifications.js — push notification management
 *
 * Provider abstraction:
 *   - firebase (FCM) for Android
 *   - apns for iOS
 *   - web_push for web users
 *   - sms fallback
 *
 * Token storage: `device_tokens` collection
 *   { user_id, platform, token, created_at, last_used_at, active }
 *
 * Notification templates: stored in code for now, can be moved to DB later.
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const mongoURI = process.env.DBURI;

const notifications = {
    /**
     * User: POST /notifications/device — register device token
     * Body: { platform: 'android'|'ios'|'web', token }
     */
    registerDevice: async function(res, body, user, path) {
        const platform = sanitize(body.platform);
        const token = sanitize(body.token);
        if (!['android','ios','web'].includes(platform)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "platform must be android, ios, or web" }});
        }
        if (!token || token.length < 10) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid token" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("device_tokens");
            // Upsert: replace existing token for same user+platform+token
            await col.updateOne(
                { user_id: new ObjectId(user.id), platform, token },
                { $set: { active: true, last_used_at: new Date(), updated_at: new Date() },
                  $setOnInsert: { created_at: new Date() } },
                { upsert: true }
            );
            return res.status(200).json({ data: { type: "success",
                message: "Device registered" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * User: DELETE /notifications/device — unregister device
     */
    unregisterDevice: async function(res, body, user, path) {
        const token = sanitize(body.token);
        if (!token) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "token required" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            await db.collection("device_tokens").updateOne(
                { user_id: new ObjectId(user.id), token },
                { $set: { active: false, unregistered_at: new Date() } });
            return res.status(200).json({ data: { type: "success",
                message: "Device unregistered" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * User: GET /notifications — list my notifications
     */
    listMine: async function(res, query, user, path) {
        const limit = Math.min(parseInt(query.limit || '20'), 100);
        const offset = Math.max(parseInt(query.offset || '0'), 0);
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("notifications");
            const items = await col.find({ user_id: new ObjectId(user.id) })
                .sort({ created_at: -1 }).skip(offset).limit(limit).toArray();
            const total = await col.countDocuments({ user_id: new ObjectId(user.id) });
            const unread = await col.countDocuments({
                user_id: new ObjectId(user.id), read_at: null });
            return res.status(200).json({ data: { notifications: items, total, unread,
                limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * User: POST /notifications/:id/read — mark as read
     */
    markRead: async function(res, notifId, user, path) {
        if (!ObjectId.isValid(notifId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid id" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const result = await db.collection("notifications").updateOne(
                { _id: new ObjectId(notifId), user_id: new ObjectId(user.id) },
                { $set: { read_at: new Date() } });
            if (result.matchedCount === 0) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Not found" }});
            }
            return res.status(200).json({ data: { type: "success" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Internal: send notification to a user via all their active devices.
     * Saves to DB + pushes via provider (FCM/APNs/Web Push).
     */
    send: async function(userId, { title, body, type, data }) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            // Save notification record
            await db.collection("notifications").insertOne({
                user_id: new ObjectId(userId),
                title,
                body,
                type: type || 'general',
                data: data || {},
                read_at: null,
                created_at: new Date(),
            });
            // Get active device tokens
            const tokensCol = db.collection("device_tokens");
            const devices = await tokensCol.find({
                user_id: new ObjectId(userId), active: true
            }).toArray();
            // Push via provider (real FCM/APNs integration goes here)
            for (const device of devices) {
                await notifications._pushViaProvider(device, title, body, data);
            }
            return { ok: true, sent_count: devices.length };
        } catch (e) {
            console.error('[notifications] send error:', e);
            return { ok: false, error: e.message };
        } finally { await client.close(); }
    },

    /**
     * Admin: POST /notifications/broadcast — broadcast to all users
     */
    broadcast: async function(res, body, path) {
        const title = sanitize(body.title);
        const bodyText = sanitize(body.body);
        const type = sanitize(body.type) || 'broadcast';
        if (!title || !bodyText) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "title and body required" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const usersCol = db.collection("users");
            const notifCol = db.collection("notifications");
            const users = await usersCol.find({ status: { $ne: 'blocked' } },
                { projection: { _id: 1 } }).toArray();
            const now = new Date();
            const docs = users.map(u => ({
                user_id: u._id, title, body: bodyText, type,
                data: {}, read_at: null, created_at: now,
            }));
            if (docs.length > 0) {
                await notifCol.insertMany(docs);
            }
            return res.status(200).json({ data: { type: "success",
                message: `Broadcast queued to ${users.length} users` }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Internal: push via provider. Currently logs (no FCM/APNs keys in env).
     */
    _pushViaProvider: async function(device, title, body, data) {
        const platform = device.platform;
        const fcmKey = process.env.FCM_SERVER_KEY;
        if (platform === 'android' && fcmKey) {
            // Real FCM v1 HTTP API call would go here
            console.log(`[Push FCM] -> ${device.token.slice(0, 20)}... : ${title}`);
            return { provider: 'fcm', status: 'sent' };
        }
        if (platform === 'ios') {
            const apnsCert = process.env.APNS_CERT_PATH;
            if (apnsCert) {
                console.log(`[Push APNs] -> ${device.token.slice(0, 20)}... : ${title}`);
                return { provider: 'apns', status: 'sent' };
            }
        }
        if (platform === 'web') {
            const vapidKey = process.env.VAPID_PUBLIC_KEY;
            if (vapidKey) {
                console.log(`[Push Web] -> ${device.token.slice(0, 20)}... : ${title}`);
                return { provider: 'web_push', status: 'sent' };
            }
        }
        console.log(`[Push dev-fallback ${platform}] -> ${device.token.slice(0, 20)}... : ${title} - ${body}`);
        return { provider: 'console', status: 'logged' };
    },
};

module.exports = notifications;
