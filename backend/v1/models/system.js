/**
 * system.js — system info & maintenance
 */
const os = require('os');
const { MongoClient } = require('mongodb');
const mongoURI = process.env.DBURI;

const startedAt = Date.now();

const system = {
    info: async function(res, path) {
        const client = new MongoClient(mongoURI);
        let dbStats = null;
        try {
            await client.connect();
            const db = client.db('spark-rentals');
            const collections = ['users','scooters','trips','transactions','cities',
                'promocodes','support_tickets','notifications','audit_log',
                'refresh_tokens','otp_codes','juicers','mechanics',
                'maintenance_requests','juicer_tasks','parts_inventory',
                'device_tokens','uploads','scooter_commands','user_settings'];
            const counts = {};
            for (const c of collections) {
                try {
                    counts[c] = await db.collection(c).countDocuments();
                } catch { counts[c] = 'error'; }
            }
            dbStats = counts;
        } catch (e) {
            console.error('system.info db error:', e);
        } finally { await client.close(); }

        const uptimeSec = Math.floor((Date.now() - startedAt) / 1000);
        const memUsage = process.memoryUsage();

        return res.status(200).json({ data: {
            app: {
                name: 'SparkRentals REST API',
                version: '1.0.0',
                node_version: process.version,
                environment: process.env.NODE_ENV || 'development',
                started_at: new Date(startedAt).toISOString(),
                uptime_seconds: uptimeSec,
                uptime_human: `${Math.floor(uptimeSec/3600)}h ${Math.floor(uptimeSec/60)%60}m ${uptimeSec%60}s`,
            },
            system: {
                hostname: os.hostname(),
                platform: os.platform(),
                arch: os.arch(),
                cpus: os.cpus().length,
                total_memory_mb: Math.round(os.totalmem() / 1024 / 1024),
                free_memory_mb: Math.round(os.freemem() / 1024 / 1024),
                load_avg: os.loadavg(),
            },
            process: {
                pid: process.pid,
                memory: {
                    rss_mb: Math.round(memUsage.rss / 1024 / 1024),
                    heap_used_mb: Math.round(memUsage.heapUsed / 1024 / 1024),
                    heap_total_mb: Math.round(memUsage.heapTotal / 1024 / 1024),
                },
                uptime_seconds: Math.floor(process.uptime()),
            },
            database: {
                uri: mongoURI?.replace(/\/\/[^@]+@/, '//***:***@'),
                collections: dbStats,
            },
            features: {
                sms_provider: process.env.SMS_PROVIDER || 'console',
                click_configured: !!(process.env.CLICK_MERCHANT_ID && process.env.CLICK_SECRET_KEY),
                payme_configured: !!(process.env.PAYME_MERCHANT_ID && process.env.PAYME_KEY),
                fcm_configured: !!process.env.FCM_SERVER_KEY,
                apns_configured: !!process.env.APNS_CERT_PATH,
                google_oauth: !!process.env.GOOGLE_CLIENT_ID,
            },
        }});
    },
};

module.exports = system;
