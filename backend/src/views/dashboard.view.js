/**
 * Dashboard view — admin dashboard data aggregation
 *
 * GET /v1/views/dashboard
 *
 * Request tree:
 *   dashboard
 *   ├── main [B0]
 *   │   ├── scooters_overview
 *   │   ├── users_overview
 *   │   ├── cities_overview
 *   │   └── trips_today
 *   ├── revenue [B1]
 *   │   ├── revenue_today
 *   │   ├── revenue_week
 *   │   └── revenue_month
 *   └── fleet [B1]
 *       └── fleet_utilization
 *
 * Per constitution §6.2 + §14: P95 budget 400-600ms for complex view
 */
const { executeTree } = require('./executor.js');
const { getDb } = require('../shared/db.js');

const dashboardTree = {
    sections: {
        main: {
            required: true,
            cacheTtlSec: 30,
            cacheNamespace: 'admin_dashboard',
            cacheContextKeys: [],
            nodes: [
                {
                    id: 'scooters_overview',
                    useCase: async () => {
                        const db = await getDb();
                        const [total, byStatus] = await Promise.all([
                            db.collection('scooters').countDocuments(),
                            db.collection('scooters').aggregate([
                                { $group: { _id: '$status', count: { $sum: 1 } } },
                            ]).toArray(),
                        ]);
                        const statusMap = {};
                        byStatus.forEach(s => statusMap[s._id] = s.count);
                        return {
                            total,
                            available: statusMap.available || 0,
                            in_use: statusMap.in_use || 0,
                            charging: (statusMap.charging || 0) + (statusMap.charging_needed || 0),
                            maintenance: statusMap.maintenance || 0,
                            reserved: statusMap.reserved || 0,
                        };
                    },
                    cache: { ttlSec: 30 },
                },
                {
                    id: 'users_overview',
                    useCase: async () => {
                        const db = await getDb();
                        const total = await db.collection('users').countDocuments();
                        const todayStart = new Date(new Date().setHours(0, 0, 0, 0));
                        const activeToday = await db.collection('users').countDocuments({
                            last_login_at: { $gte: todayStart },
                        });
                        return { total, active_today: activeToday };
                    },
                    cache: { ttlSec: 60 },
                },
                {
                    id: 'cities_overview',
                    useCase: async () => {
                        const db = await getDb();
                        const total = await db.collection('cities').countDocuments();
                        return { total };
                    },
                    cache: { ttlSec: 300 },
                },
                {
                    id: 'trips_today',
                    useCase: async () => {
                        const db = await getDb();
                        const todayStart = new Date(new Date().setHours(0, 0, 0, 0));
                        const weekStart = new Date(todayStart.getTime() - 7 * 24 * 3600 * 1000);
                        const monthStart = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
                        const [today, week, month] = await Promise.all([
                            db.collection('trips').countDocuments({ created_at: { $gte: todayStart } }),
                            db.collection('trips').countDocuments({ created_at: { $gte: weekStart } }),
                            db.collection('trips').countDocuments({ created_at: { $gte: monthStart } }),
                        ]);
                        return { today, week, month };
                    },
                    cache: { ttlSec: 60 },
                },
            ],
        },
        revenue: {
            required: false,
            cacheTtlSec: 60,
            cacheNamespace: 'admin_dashboard_revenue',
            nodes: [
                {
                    id: 'revenue_today',
                    useCase: async () => {
                        const db = await getDb();
                        const todayStart = new Date(new Date().setHours(0, 0, 0, 0));
                        const r = await db.collection('transactions').aggregate([
                            { $match: { created_at: { $gte: todayStart }, status: 'completed' } },
                            { $group: {
                                _id: null,
                                revenue: { $sum: { $cond: [{ $gt: ['$amount', 0] }, '$amount', 0] } },
                                spend: { $sum: { $cond: [{ $lt: ['$amount', 0] }, { $abs: '$amount' }, 0] } },
                                count: { $sum: 1 },
                            } },
                        ]).toArray();
                        return r[0] || { revenue: 0, spend: 0, count: 0 };
                    },
                    cache: { ttlSec: 30 },
                },
                {
                    id: 'revenue_week',
                    useCase: async () => {
                        const db = await getDb();
                        const weekStart = new Date(Date.now() - 7 * 24 * 3600 * 1000);
                        const r = await db.collection('transactions').aggregate([
                            { $match: { created_at: { $gte: weekStart }, status: 'completed' } },
                            { $group: {
                                _id: null,
                                revenue: { $sum: { $cond: [{ $gt: ['$amount', 0] }, '$amount', 0] } },
                                spend: { $sum: { $cond: [{ $lt: ['$amount', 0] }, { $abs: '$amount' }, 0] } },
                                count: { $sum: 1 },
                            } },
                        ]).toArray();
                        return r[0] || { revenue: 0, spend: 0, count: 0 };
                    },
                    cache: { ttlSec: 60 },
                },
                {
                    id: 'revenue_month',
                    useCase: async () => {
                        const db = await getDb();
                        const monthStart = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
                        const r = await db.collection('transactions').aggregate([
                            { $match: { created_at: { $gte: monthStart }, status: 'completed' } },
                            { $group: {
                                _id: null,
                                revenue: { $sum: { $cond: [{ $gt: ['$amount', 0] }, '$amount', 0] } },
                                spend: { $sum: { $cond: [{ $lt: ['$amount', 0] }, { $abs: '$amount' }, 0] } },
                                count: { $sum: 1 },
                            } },
                        ]).toArray();
                        return r[0] || { revenue: 0, spend: 0, count: 0 };
                    },
                    cache: { ttlSec: 300 },
                },
            ],
        },
        fleet: {
            required: false,
            cacheTtlSec: 60,
            cacheNamespace: 'admin_dashboard_fleet',
            nodes: [
                {
                    id: 'fleet_by_city',
                    useCase: async () => {
                        const db = await getDb();
                        const byCity = await db.collection('scooters').aggregate([
                            { $group: {
                                _id: '$owner',
                                count: { $sum: 1 },
                                avg_battery: { $avg: '$battery' },
                            } },
                        ]).toArray();
                        // Hydrate city names
                        const cityIds = byCity.map(c => c._id);
                        const cities = await db.collection('cities').find({ _id: { $in: cityIds } })
                            .project({ name: 1 }).toArray();
                        const cityMap = {};
                        cities.forEach(c => cityMap[c._id] = c.name);
                        return byCity.map(c => ({
                            city_id: String(c._id),
                            city_name: cityMap[c._id] || 'Unknown',
                            count: c.count,
                            avg_battery: Math.round(c.avg_battery * 100) / 100,
                        }));
                    },
                    cache: { ttlSec: 60 },
                },
                {
                    id: 'fleet_by_status',
                    useCase: async () => {
                        const db = await getDb();
                        return db.collection('scooters').aggregate([
                            { $group: { _id: '$status', count: { $sum: 1 } } },
                        ]).toArray();
                    },
                    cache: { ttlSec: 30 },
                },
            ],
        },
    },
};

/**
 * Controller for GET /v1/views/dashboard
 */
async function getDashboard(req, res) {
    try {
        const requestedSections = req.query.sections
            ? req.query.sections.split(',').map(s => s.trim())
            : null;
        const result = await executeTree(dashboardTree, requestedSections, {
            requestId: req.requestId,
            user: req.user,
            admin: req.admin,
        });
        return res.status(200).json({
            data: result.data,
            meta: { ...result.meta, requestId: req.requestId },
        });
    } catch (e) {
        return res.status(500).json({
            error: { code: 'INTERNAL_ERROR', message: e.message, requestId: req.requestId },
        });
    }
}

module.exports = { getDashboard, dashboardTree };
