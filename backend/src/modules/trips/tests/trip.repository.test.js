/**
 * Integration tests for trips module (direct DB queries)
 *
 * Per constitution §21: integration tests for repositories, database
 *
 * Run: node src/modules/trips/tests/trip.repository.test.js
 *
 * Requires: MongoDB running on localhost:27017
 */

const assert = require('assert');
const { MongoClient, ObjectId } = require('mongodb');

const mongoURI = process.env.DBURI || 'mongodb://localhost:27017';
const DB_NAME = 'spark-rentals-test';
const COLLECTION = 'trips';

let passed = 0, failed = 0;
let client, db;

async function setup() {
    client = new MongoClient(mongoURI);
    await client.connect();
    db = client.db(DB_NAME);
    await db.collection(COLLECTION).deleteMany({});
    console.log('\n=== Trip Repository Integration Tests ===\n');
}

async function teardown() {
    if (client) await client.close();
}

async function test(name, fn) {
    try { await fn(); passed++; console.log(`  ✓ ${name}`); }
    catch (e) { failed++; console.error(`  ✗ ${name}\n    ${e.message}`); }
}

// Helper: insert a trip directly for testing
async function insertTrip(overrides = {}) {
    const now = new Date();
    const doc = {
        user_id: new ObjectId(),
        scooter_id: new ObjectId(),
        city_id: new ObjectId(),
        status: 'reserved',
        start_time: null,
        end_time: null,
        reservation_time: now,
        reservation_expires: new Date(now.getTime() + 10 * 60 * 1000),
        created_at: now,
        updated_at: now,
        ...overrides,
    };
    const result = await db.collection(COLLECTION).insertOne(doc);
    return { ...doc, _id: result.insertedId };
}

(async () => {
    try {
        await setup();

        await test('insert and find trip by ID', async () => {
            const trip = await insertTrip();
            const found = await db.collection(COLLECTION).findOne({ _id: trip._id });
            assert.ok(found, 'Trip should be found');
            assert.strictEqual(String(found._id), String(trip._id));
            assert.strictEqual(found.status, 'reserved');
        });

        await test('find active trip returns null when only ended/cancelled', async () => {
            const userId = new ObjectId();
            await insertTrip({ user_id: userId, status: 'ended' });
            await insertTrip({ user_id: userId, status: 'cancelled' });
            const found = await db.collection(COLLECTION).findOne({
                user_id: userId,
                status: { $in: ['reserved', 'active'] },
            });
            assert.strictEqual(found, null);
        });

        await test('find active trip returns active trip', async () => {
            const userId = new ObjectId();
            await insertTrip({ user_id: userId, status: 'active' });
            const found = await db.collection(COLLECTION).findOne({
                user_id: userId,
                status: { $in: ['reserved', 'active'] },
            });
            assert.ok(found, 'Should find active trip');
            assert.strictEqual(found.status, 'active');
        });

        await test('list by user returns paginated results', async () => {
            const userId = new ObjectId();
            for (let i = 0; i < 5; i++) {
                await insertTrip({ user_id: userId, status: 'ended' });
            }
            const items = await db.collection(COLLECTION).find({ user_id: userId })
                .sort({ created_at: -1 }).skip(0).limit(3).toArray();
            const total = await db.collection(COLLECTION).countDocuments({ user_id: userId });
            assert.strictEqual(items.length, 3);
            assert.strictEqual(total, 5);
        });

        await test('find stale reservations finds expired', async () => {
            await db.collection(COLLECTION).deleteMany({});
            await insertTrip({
                status: 'reserved',
                reservation_expires: new Date(Date.now() - 60000),
            });
            await insertTrip({
                status: 'reserved',
                reservation_expires: new Date(Date.now() + 60000),
            });
            const stale = await db.collection(COLLECTION).find({
                status: 'reserved',
                reservation_expires: { $lt: new Date() },
            }).toArray();
            assert.ok(stale.length >= 1, 'Should find at least 1 stale reservation');
            stale.forEach(s => {
                assert.strictEqual(s.status, 'reserved');
                assert.ok(new Date(s.reservation_expires) < new Date());
            });
        });

        await test('findOneAndUpdate changes status', async () => {
            const trip = await insertTrip({ status: 'reserved' });
            await db.collection(COLLECTION).findOneAndUpdate(
                { _id: trip._id },
                { $set: { status: 'active', start_time: new Date(), updated_at: new Date() } },
                { returnDocument: 'after' }
            );
            // Re-fetch to verify
            const updated = await db.collection(COLLECTION).findOne({ _id: trip._id });
            assert.strictEqual(updated.status, 'active');
            assert.ok(updated.start_time);
        });

        await test('countByStatus groups trips by status', async () => {
            await db.collection(COLLECTION).deleteMany({});
            await insertTrip({ status: 'ended' });
            await insertTrip({ status: 'ended' });
            await insertTrip({ status: 'active' });
            await insertTrip({ status: 'cancelled' });
            const counts = await db.collection(COLLECTION).aggregate([
                { $group: { _id: '$status', count: { $sum: 1 } } },
            ]).toArray();
            const map = {};
            counts.forEach(c => { map[c._id] = c.count; });
            assert.strictEqual(map.ended, 2);
            assert.strictEqual(map.active, 1);
            assert.strictEqual(map.cancelled, 1);
        });

        await test('find long active trips finds trips over threshold', async () => {
            await db.collection(COLLECTION).deleteMany({});
            await insertTrip({
                status: 'active',
                start_time: new Date(Date.now() - 10 * 3600 * 1000),
            });
            await insertTrip({
                status: 'active',
                start_time: new Date(Date.now() - 3600 * 1000),
            });
            const threshold = new Date(Date.now() - 8 * 3600 * 1000);
            const long = await db.collection(COLLECTION).find({
                status: 'active',
                start_time: { $lt: threshold },
            }).toArray();
            assert.ok(long.length >= 1, 'Should find at least 1 long trip');
        });

        await test('repository methods work via injected db', async () => {
            // Mock the getDb to return our test db
            const dbModule = require('../../../shared/db.js');
            const originalGetDb = dbModule.getDb;
            dbModule.getDb = async () => db;

            try {
                const TripRepository = require('../infrastructure/trip.repository.js');
                const userId = new ObjectId();
                await insertTrip({ user_id: userId, status: 'ended' });
                await insertTrip({ user_id: userId, status: 'ended' });

                const result = await TripRepository.listByUser(userId, {
                    limit: 10, offset: 0, sort: { created_at: -1 }
                });
                assert.ok(result.items.length >= 2);
                assert.ok(result.total >= 2);
                result.items.forEach(item => {
                    assert.strictEqual(item.status, 'ended');
                });
            } finally {
                dbModule.getDb = originalGetDb;
            }
        });

        console.log(`\n=== ${passed} passed, ${failed} failed ===\n`);
    } catch (e) {
        console.error('Test setup failed:', e);
        process.exit(1);
    } finally {
        await teardown();
    }
    process.exit(failed > 0 ? 1 : 0);
})();
