const { getDb } = require('../../shared/db.js');
const { ObjectId } = require('mongodb');
const logger = require('../../shared/logger.js');
const THRESHOLDS = { DISTANCE_KM: 500, BATTERY_CYCLES: 100, BATTERY_HEALTH: 80, DAYS_SINCE_LAST: 90 };
async function scheduleAutoMaintenance() {
    const db = await getDb();
    const threshold = new Date(Date.now() - THRESHOLDS.DAYS_SINCE_LAST * 86400000);
    const scooters = await db.collection('scooters').find({
        status: { $nin: ['maintenance', 'retired'] },
        $or: [
            { total_distance_km: { $gte: THRESHOLDS.DISTANCE_KM } },
            { battery_cycles: { $gte: THRESHOLDS.BATTERY_CYCLES } },
            { battery_health_percent: { $lt: THRESHOLDS.BATTERY_HEALTH } },
            { $and: [{ last_maintenance_at: { $lt: threshold } }, { last_maintenance_at: { $ne: null } }] },
            { $and: [{ last_maintenance_at: null }, { created_at: { $lt: threshold } }] },
        ],
    }).toArray();
    let created = 0;
    for (const scooter of scooters) {
        const existing = await db.collection('maintenance_requests').findOne({
            scooter_id: scooter._id, status: { $in: ['open', 'assigned', 'in_progress'] },
        });
        if (existing) continue;
        const reasons = [];
        if (scooter.total_distance_km >= THRESHOLDS.DISTANCE_KM) reasons.push(`High mileage: ${scooter.total_distance_km}km`);
        if (scooter.battery_cycles >= THRESHOLDS.BATTERY_CYCLES) reasons.push(`Battery cycles: ${scooter.battery_cycles}`);
        if (scooter.battery_health_percent < THRESHOLDS.BATTERY_HEALTH) reasons.push(`Low battery health: ${scooter.battery_health_percent}%`);
        if (reasons.length === 0) continue;
        await db.collection('maintenance_requests').insertOne({
            scooter_id: scooter._id, reason: `Auto: ${reasons.join(', ')}`,
            priority: reasons.length >= 3 ? 'high' : 'normal', status: 'open',
            created_by_admin: false, auto_scheduled: true, created_at: new Date(), updated_at: new Date(),
        });
        await db.collection('scooters').updateOne({ _id: scooter._id },
            { $set: { status: 'maintenance', updated_at: new Date() } });
        created++;
    }
    logger.info('Auto-maintenance scheduled', { checked: scooters.length, created });
    return { checked: scooters.length, created };
}
module.exports = { scheduleAutoMaintenance, THRESHOLDS };
