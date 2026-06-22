/**
 * db.js — MongoDB connection pool (shared across all modules)
 *
 * Single MongoClient reused across requests.
 * Connection pool size configurable via env.
 */
const { MongoClient } = require('mongodb');
const logger = require('./logger.js');

const MONGO_URI = process.env.DBURI || 'mongodb://localhost:27017';
const DB_NAME = process.env.DB_NAME || 'spark-rentals';
const POOL_SIZE = parseInt(process.env.MONGO_POOL_SIZE || '10', 10);

let client = null;
let db = null;

async function getDb() {
    if (db) return db;
    client = new MongoClient(MONGO_URI, {
        maxPoolSize: POOL_SIZE,
        minPoolSize: 2,
        serverSelectionTimeoutMS: 5000,
        socketTimeoutMS: 30000,
        connectTimeoutMS: 10000,
    });
    try {
        await client.connect();
        db = client.db(DB_NAME);
        logger.info('MongoDB connected', {
            uri: MONGO_URI.replace(/\/\/[^@]+@/, '//***:***@'),
            dbName: DB_NAME, poolSize: POOL_SIZE,
        });
        return db;
    } catch (e) {
        logger.error('MongoDB connection failed', { error: e.message });
        throw e;
    }
}

async function getClient() {
    if (!client) await getDb();
    return client;
}

async function close() {
    if (client) {
        await client.close();
        client = null;
        db = null;
        logger.info('MongoDB connection closed');
    }
}

/**
 * Health check — used by /health endpoint
 */
async function ping() {
    if (!db) await getDb();
    const start = Date.now();
    await db.command({ ping: 1 });
    return { ok: true, latencyMs: Date.now() - start };
}

module.exports = { getDb, getClient, close, ping };
