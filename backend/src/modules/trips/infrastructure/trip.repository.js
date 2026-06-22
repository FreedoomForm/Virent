/**
 * Trip repository — infrastructure layer
 *
 * Per constitution §12: infrastructure can use SQL/ORM/Redis.
 * This implementation uses MongoDB via shared db.js.
 *
 * Per constitution §13: no SELECT *, no N+1, indexes follow access patterns.
 */

const { getDb } = require('../../../shared/db.js');
const { ObjectId } = require('mongodb');
const { Trip } = require('../domain/trip.entity.js');

const COLLECTION = 'trips';

class TripRepository {
    /**
     * Create a new trip (reservation)
     * @accessPattern: trips.create
     * @index: pk_trips_id (auto)
     */
    async create(data) {
        const db = await getDb();
        const now = new Date();
        const doc = {
            user_id: new ObjectId(data.user_id),
            scooter_id: new ObjectId(data.scooter_id),
            city_id: new ObjectId(data.city_id),
            status: 'reserved',
            start_time: null,
            end_time: null,
            reservation_time: now,
            reservation_expires: data.reservation_expires,
            start_coordinates: null,
            end_coordinates: null,
            start_battery: null,
            end_battery: null,
            distance_km: 0,
            duration_min: 0,
            cost: 0,
            cost_breakdown: {},
            photo_url: null,
            end_zone_type: null,
            refund_amount: 0,
            refund_reason: null,
            created_at: now,
            updated_at: now,
        };
        const result = await db.collection(COLLECTION).insertOne(doc);
        return new Trip({ ...doc, _id: result.insertedId });
    }

    /**
     * Find trip by ID
     * @accessPattern: trips.getById
     * @index: pk_trips_id (auto)
     */
    async findById(tripId) {
        const db = await getDb();
        if (!ObjectId.isValid(tripId)) return null;
        const doc = await db.collection(COLLECTION).findOne({ _id: new ObjectId(tripId) });
        return doc ? new Trip(doc) : null;
    }

    /**
     * Find active/reserved trip for a user
     * @accessPattern: trips.getActiveByUser
     * @index: idx_trips_user_status
     */
    async findActiveByUser(userId) {
        const db = await getDb();
        const doc = await db.collection(COLLECTION).findOne({
            user_id: new ObjectId(userId),
            status: { $in: ['reserved', 'active'] },
        });
        return doc ? new Trip(doc) : null;
    }

    /**
     * List user's trips with pagination
     * @accessPattern: trips.listByUser
     * @index: idx_trips_user_created
     */
    async listByUser(userId, { limit, offset, sort }) {
        const db = await getDb();
        const filter = { user_id: new ObjectId(userId) };
        const cursor = db.collection(COLLECTION).find(filter)
            .sort(sort)
            .skip(offset)
            .limit(limit);
        const [items, total] = await Promise.all([
            cursor.toArray(),
            db.collection(COLLECTION).countDocuments(filter),
        ]);
        return { items: items.map(d => new Trip(d)), total };
    }

    /**
     * List all trips (admin) with filters
     * @accessPattern: trips.listAll
     * @index: idx_trips_status_created, idx_trips_user_status, idx_trips_scooter_status
     */
    async listAll({ limit, offset, sort, filters = {} }) {
        const db = await getDb();
        const filter = {};
        if (filters.status) filter.status = filters.status;
        if (filters.user_id && ObjectId.isValid(filters.user_id))
            filter.user_id = new ObjectId(filters.user_id);
        if (filters.scooter_id && ObjectId.isValid(filters.scooter_id))
            filter.scooter_id = new ObjectId(filters.scooter_id);
        if (filters.from || filters.to) {
            filter.created_at = {};
            if (filters.from) filter.created_at.$gte = new Date(filters.from);
            if (filters.to) filter.created_at.$lte = new Date(filters.to);
        }
        const cursor = db.collection(COLLECTION).find(filter)
            .sort(sort).skip(offset).limit(limit);
        const [items, total] = await Promise.all([
            cursor.toArray(),
            db.collection(COLLECTION).countDocuments(filter),
        ]);
        return { items: items.map(d => new Trip(d)), total };
    }

    /**
     * Update trip status and fields
     * @accessPattern: trips.update
     */
    async update(tripId, updates) {
        const db = await getDb();
        const result = await db.collection(COLLECTION).findOneAndUpdate(
            { _id: new ObjectId(tripId) },
            { $set: { ...updates, updated_at: new Date() } },
            { returnDocument: 'after' }
        );
        return result ? new Trip(result) : null;
    }

    /**
     * Find stale reservations for cron job
     * @accessPattern: trips.findStaleReservations
     * @index: idx_trips_status_reservation_expires
     */
    async findStaleReservations() {
        const db = await getDb();
        return db.collection(COLLECTION).find({
            status: 'reserved',
            reservation_expires: { $lt: new Date() },
        }).toArray();
    }

    /**
     * Find active trips longer than maxHours
     * @accessPattern: trips.findLongActive
     */
    async findLongActive(maxHours) {
        const db = await getDb();
        const threshold = new Date(Date.now() - maxHours * 3600 * 1000);
        return db.collection(COLLECTION).find({
            status: 'active',
            start_time: { $lt: threshold },
        }).toArray();
    }

    /**
     * Count trips by status for stats
     * @accessPattern: trips.countByStatus
     */
    async countByStatus(since = null) {
        const db = await getDb();
        const match = since ? { created_at: { $gte: since } } : {};
        return db.collection(COLLECTION).aggregate([
            { $match: match },
            { $group: { _id: '$status', count: { $sum: 1 } } },
        ]).toArray();
    }
}

module.exports = new TripRepository();
