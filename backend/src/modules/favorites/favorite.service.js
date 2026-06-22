const { getDb } = require('../../shared/db.js');
const { ObjectId } = require('mongodb');
const favoriteService = {
  list: async function(userId) {
    const db = await getDb();
    return db.collection('favorites').find({ user_id: new ObjectId(userId) }).toArray();
  },
  add: async function(userId, { name, coordinates, address, type = 'location' }) {
    const db = await getDb();
    const fav = { user_id: new ObjectId(userId), name, coordinates, address: address || null, type, created_at: new Date() };
    const result = await db.collection('favorites').insertOne(fav);
    return { ...fav, _id: result.insertedId };
  },
  remove: async function(userId, favoriteId) {
    const db = await getDb();
    const result = await db.collection('favorites').deleteOne({ _id: new ObjectId(favoriteId), user_id: new ObjectId(userId) });
    return result.deletedCount > 0;
  },
};
module.exports = favoriteService;
