/**
 * User repository — infrastructure layer
 */
const { getDb } = require('../../../shared/db.js');
const { ObjectId } = require('mongodb');

const COLLECTION = 'users';

class UserRepository {
    async findById(id) {
        const db = await getDb();
        if (!ObjectId.isValid(id)) return null;
        return db.collection(COLLECTION).findOne({ _id: new ObjectId(id) });
    }

    async findByEmail(email) {
        const db = await getDb();
        return db.collection(COLLECTION).findOne({ email });
    }

    async findByPhone(phone) {
        const db = await getDb();
        return db.collection(COLLECTION).findOne({ phoneNumber: phone });
    }

    async listAll({ limit, offset, sort, filters = {} }) {
        const db = await getDb();
        const filter = {};
        if (filters.status) filter.status = filters.status;
        if (filters.role) filter.role = filters.role;
        const cursor = db.collection(COLLECTION).find(filter).sort(sort).skip(offset).limit(limit);
        const [items, total] = await Promise.all([
            cursor.toArray(),
            db.collection(COLLECTION).countDocuments(filter),
        ]);
        return { items, total };
    }

    async create(data) {
        const db = await getDb();
        const now = new Date();
        const doc = {
            googleId: null,
            firstName: data.firstName || '',
            lastName: data.lastName || '',
            phoneNumber: data.phoneNumber || null,
            email: data.email || null,
            password: data.password || null,
            balance: data.balance || 0,
            history: [],
            phone_verified: data.phone_verified || false,
            accepted_terms_at: data.accepted_terms_at || null,
            terms_version: data.terms_version || null,
            role: data.role || 'user',
            status: data.status || 'active',
            created_at: now,
            updated_at: now,
        };
        const result = await db.collection(COLLECTION).insertOne(doc);
        return { ...doc, _id: result.insertedId };
    }

    async update(id, updates) {
        const db = await getDb();
        return db.collection(COLLECTION).updateOne(
            { _id: new ObjectId(id) },
            { $set: { ...updates, updated_at: new Date() } }
        );
    }

    async updateBalance(id, newBalance) {
        const db = await getDb();
        return db.collection(COLLECTION).updateOne(
            { _id: new ObjectId(id) },
            { $set: { balance: newBalance, updated_at: new Date() } }
        );
    }

    async updateAfterTripEnd(id, { balance, history_entry }) {
        const db = await getDb();
        return db.collection(COLLECTION).updateOne(
            { _id: new ObjectId(id) },
            {
                $set: { balance, updated_at: new Date() },
                $push: { history: history_entry },
            }
        );
    }

    async count() {
        const db = await getDb();
        return db.collection(COLLECTION).countDocuments();
    }

    async countActiveSince(since) {
        const db = await getDb();
        return db.collection(COLLECTION).countDocuments({ last_login_at: { $gte: since } });
    }
}

module.exports = new UserRepository();
