/**
 * Transaction repository — infrastructure layer
 */
const { getDb } = require('../../../shared/db.js');
const { ObjectId } = require('mongodb');

const COLLECTION = 'transactions';

class TransactionRepository {
    async create(data) {
        const db = await getDb();
        const now = new Date();
        const doc = {
            user_id: data.user_id ? new ObjectId(data.user_id) : null,
            trip_id: data.trip_id ? new ObjectId(data.trip_id) : null,
            type: data.type,
            amount: data.amount,
            balance_after: data.balance_after,
            method: data.method || 'balance',
            provider: data.provider || 'internal',
            provider_txn_id: data.provider_txn_id || null,
            status: data.status || 'completed',
            description: data.description || '',
            created_at: now,
            updated_at: now,
        };
        const result = await db.collection(COLLECTION).insertOne(doc);
        return { ...doc, _id: result.insertedId };
    }

    async listByUser(userId, { limit, offset, sort, filters = {} }) {
        const db = await getDb();
        const filter = { user_id: new ObjectId(userId) };
        if (filters.type) filter.type = filters.type;
        if (filters.from || filters.to) {
            filter.created_at = {};
            if (filters.from) filter.created_at.$gte = new Date(filters.from);
            if (filters.to) filter.created_at.$lte = new Date(filters.to);
        }
        const cursor = db.collection(COLLECTION).find(filter).sort(sort).skip(offset).limit(limit);
        const [items, total] = await Promise.all([
            cursor.toArray(),
            db.collection(COLLECTION).countDocuments(filter),
        ]);
        return { items, total };
    }

    async listAll({ limit, offset, sort, filters = {} }) {
        const db = await getDb();
        const filter = {};
        if (filters.user_id && ObjectId.isValid(filters.user_id))
            filter.user_id = new ObjectId(filters.user_id);
        if (filters.type) filter.type = filters.type;
        if (filters.status) filter.status = filters.status;
        const cursor = db.collection(COLLECTION).find(filter).sort(sort).skip(offset).limit(limit);
        const [items, total] = await Promise.all([
            cursor.toArray(),
            db.collection(COLLECTION).countDocuments(filter),
        ]);
        return { items, total };
    }

    async aggregateRevenue(since) {
        const db = await getDb();
        const match = since ? { created_at: { $gte: since }, status: 'completed' }
                            : { status: 'completed' };
        return db.collection(COLLECTION).aggregate([
            { $match: match },
            { $group: {
                _id: null,
                revenue: { $sum: { $cond: [{ $gt: ['$amount', 0] }, '$amount', 0] } },
                spend:   { $sum: { $cond: [{ $lt: ['$amount', 0] }, { $abs: '$amount' }, 0] } },
                count: { $sum: 1 },
            } },
        ]).toArray();
    }

    async timeSeries({ from, to, granularity = 'day' }) {
        const db = await getDb();
        let groupId;
        if (granularity === 'hour') {
            groupId = { year: { $year: '$created_at' }, month: { $month: '$created_at' },
                        day: { $dayOfMonth: '$created_at' }, hour: { $hour: '$created_at' } };
        } else if (granularity === 'week') {
            groupId = { year: { $year: '$created_at' }, week: { $week: '$created_at' } };
        } else {
            groupId = { year: { $year: '$created_at' }, month: { $month: '$created_at' },
                        day: { $dayOfMonth: '$created_at' } };
        }
        return db.collection(COLLECTION).aggregate([
            { $match: { created_at: { $gte: from, $lte: to }, status: 'completed' } },
            { $group: { _id: groupId,
                revenue: { $sum: { $cond: [{ $gt: ['$amount', 0] }, '$amount', 0] } },
                spend: { $sum: { $cond: [{ $lt: ['$amount', 0] }, { $abs: '$amount' }, 0] } },
                count: { $sum: 1 } } },
            { $sort: { _id: 1 } },
        ]).toArray();
    }
}

module.exports = new TransactionRepository();
