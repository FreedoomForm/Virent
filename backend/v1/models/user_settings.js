/**
 * user_settings.js — per-user preferences
 *
 * Fields: language, theme, push preferences, default city
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const mongoURI = process.env.DBURI;

const userSettings = {
    get: async function(res, user, path) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const doc = await db.collection("user_settings").findOne(
                { user_id: new ObjectId(user.id) });
            return res.status(200).json({ data: { settings: doc || {
                user_id: user.id,
                language: 'ru',
                theme: 'light',
                push_ride_end_reminders: true,
                push_low_battery: true,
                push_promos: true,
                default_city_id: null,
            } }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    update: async function(res, body, user, path) {
        const allowed = ['language', 'theme', 'push_ride_end_reminders',
            'push_low_battery', 'push_promos', 'default_city_id'];
        const update = { updated_at: new Date() };
        for (const key of allowed) {
            if (body[key] !== undefined) {
                update[key] = sanitize(body[key]);
            }
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            await db.collection("user_settings").updateOne(
                { user_id: new ObjectId(user.id) },
                { $set: update },
                { upsert: true }
            );
            return res.status(200).json({ data: { type: "success",
                message: "Settings updated" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },
};

module.exports = userSettings;
