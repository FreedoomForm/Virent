/**
 * db_indexes.js — create MongoDB indexes on startup
 *
 * Run once at boot to ensure all performance + TTL indexes exist.
 */
const { MongoClient } = require('mongodb');
const mongoURI = process.env.DBURI;

async function ensureIndexes() {
    const client = new MongoClient(mongoURI);
    try {
        await client.connect();
        const db = client.db('spark-rentals');
        console.log('[db_indexes] Ensuring indexes...');

        // --- TTL indexes (auto-expire old data) ---
        await db.collection('otp_codes').createIndex(
            { expires_at: 1 },
            { expireAfterSeconds: 0, name: 'ttl_expires' }
        );
        await db.collection('audit_log').createIndex(
            { retention_expires: 1 },
            { expireAfterSeconds: 0, name: 'ttl_retention' }
        );
        await db.collection('refresh_tokens').createIndex(
            { expires_at: 1 },
            { expireAfterSeconds: 0, name: 'ttl_expires' }
        );
        await db.collection('scooter_commands').createIndex(
            { created_at: 1 },
            { expireAfterSeconds: 7 * 24 * 3600, name: 'ttl_7d' } // keep 7 days
        );

        // --- Performance indexes ---
        await db.collection('users').createIndex({ email: 1 }, { unique: true, name: 'uniq_email' });
        await db.collection('users').createIndex({ phoneNumber: 1 }, { sparse: true, name: 'phone_lookup' });
        await db.collection('scooters').createIndex({ status: 1, battery: 1 }, { name: 'status_battery' });
        await db.collection('scooters').createIndex({ owner: 1, status: 1 }, { name: 'city_status' });
        await db.collection('scooters').createIndex({ mac_address: 1 }, { sparse: true, unique: true, name: 'uniq_mac' });
        await db.collection('trips').createIndex({ user_id: 1, status: 1 }, { name: 'user_status' });
        await db.collection('trips').createIndex({ scooter_id: 1, status: 1 }, { name: 'scooter_status' });
        await db.collection('trips').createIndex({ created_at: -1 }, { name: 'created_desc' });
        await db.collection('trips').createIndex({ status: 1, reservation_expires: 1 }, { name: 'stale_reservation_lookup' });
        await db.collection('transactions').createIndex({ user_id: 1, created_at: -1 }, { name: 'user_recent' });
        await db.collection('transactions').createIndex({ type: 1, status: 1 }, { name: 'type_status' });
        await db.collection('notifications').createIndex({ user_id: 1, read_at: 1 }, { name: 'unread_lookup' });
        await db.collection('notifications').createIndex({ created_at: 1 }, { expireAfterSeconds: 90 * 24 * 3600, name: 'ttl_90d' });
        await db.collection('support_tickets').createIndex({ user_id: 1, created_at: -1 }, { name: 'user_tickets' });
        await db.collection('support_tickets').createIndex({ status: 1, priority: 1 }, { name: 'admin_queue' });
        await db.collection('refresh_tokens').createIndex({ user_id: 1, revoked: 1 }, { name: 'user_active' });
        await db.collection('refresh_tokens').createIndex({ token_hash: 1 }, { unique: true, name: 'uniq_token' });
        await db.collection('promocodes').createIndex({ code: 1 }, { unique: true, name: 'uniq_code' });
        await db.collection('promocodes').createIndex({ status: 1, valid_until: 1 }, { name: 'active_lookup' });
        await db.collection('maintenance_requests').createIndex({ scooter_id: 1, status: 1 }, { name: 'scooter_status' });
        await db.collection('juicer_tasks').createIndex({ juicer_id: 1, status: 1 }, { name: 'juicer_active' });
        await db.collection('juicer_tasks').createIndex({ scooter_id: 1, status: 1 }, { name: 'scooter_active' });
        await db.collection('device_tokens').createIndex({ user_id: 1, active: 1 }, { name: 'user_active' });
        await db.collection('uploads').createIndex({ user_id: 1, created_at: -1 }, { name: 'user_recent' });
        await db.collection('audit_log').createIndex({ actor_id: 1, timestamp: -1 }, { name: 'actor_recent' });
        await db.collection('audit_log').createIndex({ action: 1, timestamp: -1 }, { name: 'action_recent' });
        await db.collection('scooter_commands').createIndex({ scooter_mac: 1, status: 1, created_at: 1 }, { name: 'pending_lookup' });

        console.log('[db_indexes] All indexes ensured.');
    } catch (e) {
        console.error('[db_indexes] Failed:', e.message);
    } finally {
        await client.close();
    }
}

module.exports = { ensureIndexes };
