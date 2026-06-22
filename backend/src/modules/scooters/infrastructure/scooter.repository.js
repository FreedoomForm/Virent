/**
 * Scooter repository — infrastructure layer
 */
const { getDb } = require('../../../shared/db.js');
const { ObjectId } = require('mongodb');

const COLLECTION = 'scooters';

class ScooterRepository {
    async findById(id) {
        const db = await getDb();
        if (!ObjectId.isValid(id)) return null;
        return db.collection(COLLECTION).findOne({ _id: new ObjectId(id) });
    }

    async findByIdWithProjection(id, projection) {
        const db = await getDb();
        if (!ObjectId.isValid(id)) return null;
        return db.collection(COLLECTION).findOne({ _id: new ObjectId(id) }, { projection });
    }

    async listAll({ limit, offset, sort, filters = {} }) {
        const db = await getDb();
        const filter = {};
        if (filters.status) filter.status = filters.status;
        if (filters.owner && ObjectId.isValid(filters.owner))
            filter.owner = new ObjectId(filters.owner);
        const cursor = db.collection(COLLECTION).find(filter).sort(sort).skip(offset).limit(limit);
        const [items, total] = await Promise.all([
            cursor.toArray(),
            db.collection(COLLECTION).countDocuments(filter),
        ]);
        return { items, total };
    }

    async listAvailable() {
        const db = await getDb();
        return db.collection(COLLECTION).find({
            status: 'available', battery: { $gte: 15 },
        }).toArray();
    }

    async create(data) {
        const db = await getDb();
        const now = new Date();
        const doc = {
            name: data.name || `SparkRentals#${Date.now()}`,
            owner: new ObjectId(data.owner),
            coordinates: data.coordinates,
            trip: {},
            battery: data.battery || 100,
            status: data.status || 'available',
            log: [],
            serial_number: data.serial_number || `SN-${Date.now()}`,
            model: data.model || 'unknown',
            manufacturer: data.manufacturer || 'unknown',
            purchase_date: data.purchase_date || now,
            purchase_price: data.purchase_price || 0,
            firmware_version: data.firmware_version || '1.0.0',
            hardware_version: data.hardware_version || '1.0',
            mac_address: data.mac_address || null,
            imei: data.imei || null,
            sim_number: data.sim_number || null,
            total_distance_km: 0,
            total_rides: 0,
            last_maintenance_at: null,
            next_maintenance_at: null,
            retired_at: null,
            retired_reason: null,
            max_speed_kmh: data.max_speed_kmh || 25,
            battery_capacity_wh: data.battery_capacity_wh || 280,
            battery_cycles: 0,
            battery_health_percent: 100,
            created_at: now,
            updated_at: now,
        };
        const result = await db.collection(COLLECTION).insertOne(doc);
        return { ...doc, _id: result.insertedId };
    }

    async update(id, updates) {
        const db = await getDb();
        const result = await db.collection(COLLECTION).findOneAndUpdate(
            { _id: new ObjectId(id) },
            { $set: { ...updates, updated_at: new Date() } },
            { returnDocument: 'after' }
        );
        return result;
    }

    async updateStatus(id, status, extra = {}) {
        const db = await getDb();
        return db.collection(COLLECTION).updateOne(
            { _id: new ObjectId(id) },
            { $set: { status, ...extra, updated_at: new Date() } }
        );
    }

    async updateAfterTripEnd(id, data) {
        const db = await getDb();
        return db.collection(COLLECTION).updateOne(
            { _id: new ObjectId(id) },
            {
                $set: {
                    status: data.status,
                    coordinates: data.coordinates,
                    battery: data.battery,
                    trip: {},
                    updated_at: new Date(),
                },
                $push: { log: data.trip_log },
                $inc: { total_rides: 1 },
            }
        );
    }

    async countByStatus() {
        const db = await getDb();
        return db.collection(COLLECTION).aggregate([
            { $group: { _id: '$status', count: { $sum: 1 } } },
        ]).toArray();
    }

    async countByCity() {
        const db = await getDb();
        return db.collection(COLLECTION).aggregate([
            { $group: { _id: '$owner', count: { $sum: 1 }, avg_battery: { $avg: '$battery' } } },
        ]).toArray();
    }

    async count() {
        const db = await getDb();
        return db.collection(COLLECTION).countDocuments();
    }
}

module.exports = new ScooterRepository();
