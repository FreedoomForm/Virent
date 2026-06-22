/**
 * stats.js — aggregated statistics for admin dashboard
 *
 * Endpoints:
 *   GET /stats/overview — top-line numbers (today/week/month)
 *   GET /stats/revenue?from=&to=&granularity=day — revenue time series
 *   GET /stats/trips?from=&to=&granularity=day — trips per day
 *   GET /stats/scooters — fleet utilization
 *   GET /stats/users — user growth
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const mongoURI = process.env.DBURI;

const stats = {
    overview: async function(res, query, path) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const now = new Date();
            const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
            const weekStart = new Date(todayStart.getTime() - 7 * 24 * 3600 * 1000);
            const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

            const [scootersTotal, usersTotal, citiesTotal,
                  tripsToday, tripsWeek, tripsMonth,
                  revenueToday, revenueWeek, revenueMonth,
                  availableScooters, chargingScooters, maintenanceScooters,
                  activeUsers] = await Promise.all([
                db.collection("scooters").countDocuments(),
                db.collection("users").countDocuments(),
                db.collection("cities").countDocuments(),
                db.collection("trips").countDocuments({ created_at: { $gte: todayStart } }),
                db.collection("trips").countDocuments({ created_at: { $gte: weekStart } }),
                db.collection("trips").countDocuments({ created_at: { $gte: monthStart } }),
                aggregateRevenue(db, todayStart),
                aggregateRevenue(db, weekStart),
                aggregateRevenue(db, monthStart),
                db.collection("scooters").countDocuments({ status: 'available' }),
                db.collection("scooters").countDocuments({ status: { $in: ['charging', 'charging_needed'] }}),
                db.collection("scooters").countDocuments({ status: 'maintenance' }),
                db.collection("users").countDocuments({ last_login_at: { $gte: todayStart } }),
            ]);

            return res.status(200).json({ data: {
                scooters: { total: scootersTotal, available: availableScooters,
                            charging: chargingScooters, maintenance: maintenanceScooters },
                users: { total: usersTotal, active_today: activeUsers },
                cities: { total: citiesTotal },
                trips: { today: tripsToday, week: tripsWeek, month: tripsMonth },
                revenue: { today: revenueToday, week: revenueWeek, month: revenueMonth },
                generated_at: now,
            }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    revenueTimeSeries: async function(res, query, path) {
        const from = sanitize(query.from) ? new Date(sanitize(query.from)) : new Date(Date.now() - 30 * 86400000);
        const to = sanitize(query.to) ? new Date(sanitize(query.to)) : new Date();
        const granularity = sanitize(query.granularity) || 'day';

        let groupFormat;
        if (granularity === 'hour') {
            groupFormat = { year: { $year: "$created_at" }, month: { $month: "$created_at" },
                            day: { $dayOfMonth: "$created_at" }, hour: { $hour: "$created_at" } };
        } else if (granularity === 'week') {
            groupFormat = { year: { $year: "$created_at" }, week: { $week: "$created_at" } };
        } else {
            groupFormat = { year: { $year: "$created_at" }, month: { $month: "$created_at" },
                            day: { $dayOfMonth: "$created_at" } };
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const result = await db.collection("transactions").aggregate([
                { $match: { created_at: { $gte: from, $lte: to }, status: 'completed' } },
                { $group: { _id: groupFormat,
                            revenue: { $sum: { $cond: [{ $gt: ["$amount", 0] }, "$amount", 0] } },
                            spend: { $sum: { $cond: [{ $lt: ["$amount", 0] }, { $abs: "$amount" }, 0] } },
                            count: { $sum: 1 } } },
                { $sort: { _id: 1 } },
            ]).toArray();
            return res.status(200).json({ data: { series: result, granularity,
                from, to }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    tripsTimeSeries: async function(res, query, path) {
        const from = sanitize(query.from) ? new Date(sanitize(query.from)) : new Date(Date.now() - 30 * 86400000);
        const to = sanitize(query.to) ? new Date(sanitize(query.to)) : new Date();
        const granularity = sanitize(query.granularity) || 'day';

        let groupFormat;
        if (granularity === 'hour') {
            groupFormat = { year: { $year: "$start_time" }, month: { $month: "$start_time" },
                            day: { $dayOfMonth: "$start_time" }, hour: { $hour: "$start_time" } };
        } else if (granularity === 'week') {
            groupFormat = { year: { $year: "$start_time" }, week: { $week: "$start_time" } };
        } else {
            groupFormat = { year: { $year: "$start_time" }, month: { $month: "$start_time" },
                            day: { $dayOfMonth: "$start_time" } };
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const result = await db.collection("trips").aggregate([
                { $match: { start_time: { $gte: from, $lte: to }, status: 'ended' } },
                { $group: { _id: groupFormat,
                            count: { $sum: 1 },
                            avg_duration: { $avg: "$duration_min" },
                            avg_cost: { $avg: "$cost" },
                            total_revenue: { $sum: "$cost" } } },
                { $sort: { _id: 1 } },
            ]).toArray();
            return res.status(200).json({ data: { series: result, granularity, from, to }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    fleetUtilization: async function(res, path) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const total = await db.collection("scooters").countDocuments();
            const byStatus = await db.collection("scooters").aggregate([
                { $group: { _id: "$status", count: { $sum: 1 } } }
            ]).toArray();
            const byCity = await db.collection("scooters").aggregate([
                { $group: { _id: "$owner", count: { $sum: 1 },
                            avg_battery: { $avg: "$battery" } } }
            ]).toArray();
            // Get city names
            const cityIds = byCity.map(c => c._id);
            const cities = await db.collection("cities").find({ _id: { $in: cityIds } })
                .project({ name: 1 }).toArray();
            const cityMap = {};
            cities.forEach(c => cityMap[c._id] = c.name);

            return res.status(200).json({ data: {
                total,
                by_status: byStatus,
                by_city: byCity.map(c => ({ ...c, city_name: cityMap[c._id] || 'Unknown' })),
            }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },
};

async function aggregateRevenue(db, since) {
    const result = await db.collection("transactions").aggregate([
        { $match: { created_at: { $gte: since }, status: 'completed' } },
        { $group: { _id: null,
                    revenue: { $sum: { $cond: [{ $gt: ["$amount", 0] }, "$amount", 0] } },
                    spend: { $sum: { $cond: [{ $lt: ["$amount", 0] }, { $abs: "$amount" }, 0] } } } },
    ]).toArray();
    return result[0] || { revenue: 0, spend: 0 };
}

module.exports = stats;
