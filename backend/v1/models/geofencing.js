/**
 * geofencing.js — real-time zone enforcement
 *
 * Functions:
 *   - checkPoint(coordinate) → returns zone info or null
 *   - enforceSpeedLimit(scooter_id, current_speed) → returns max allowed speed in current zone
 *   - checkTripBoundary(trip_id, current_coordinate) → returns warnings/violations
 *   - notifyUserOnZoneEnter(trip_id, zone_type) — sends push notification
 *
 * Called by:
 *   - Scooter simulator when GPS update arrives
 *   - Mobile app when user location updates
 *   - Cron job that scans active trips and warns on zone violations
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const classifyPoint = require('robust-point-in-polygon');
const mongoURI = process.env.DBURI;

const DEFAULT_SPEED_LIMIT_KMH = 25;
const PARK_SPEED_LIMIT_KMH = 10;
const NO_PARKING_FINE = 5000; // UZS, charged if user ends in no-parking

const geofencing = {
    /**
     * Check what zone a coordinate is in.
     * Returns { zone, city_id } or null if outside all city zones.
     */
    locatePoint: async function(coordinates) {
        if (!coordinates || !coordinates.longitude || !coordinates.latitude) return null;
        const lng = parseFloat(coordinates.longitude);
        const lat = parseFloat(coordinates.latitude);
        if (isNaN(lng) || isNaN(lat)) return null;

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const cities = await db.collection("cities").find({}).toArray();
            for (const city of cities) {
                if (!city.zones || !city.zones.length) continue;
                for (const zone of city.zones) {
                    if (!zone.polygon || zone.polygon.length < 3) continue;
                    const poly = zone.polygon.map(p => [
                        parseFloat(p.longitude), parseFloat(p.latitude)
                    ]);
                    if (classifyPoint(poly, [lng, lat]) === -1) {
                        return { zone, city_id: city._id, city_name: city.name };
                    }
                }
                // Also check city outer boundary if defined
                if (city.outer_boundary && city.outer_boundary.length >= 3) {
                    const outer = city.outer_boundary.map(p => [
                        parseFloat(p.longitude), parseFloat(p.latitude)
                    ]);
                    if (classifyPoint(outer, [lng, lat]) === -1) {
                        return { zone: null, city_id: city._id,
                                 city_name: city.name,
                                 inside_city: true };
                    }
                }
            }
            return null;
        } finally { await client.close(); }
    },

    /**
     * Get max allowed speed at a location.
     * Returns { max_speed_kmh, reason }
     */
    getSpeedLimit: async function(coordinates) {
        const location = await geofencing.locatePoint(coordinates);
        if (!location) {
            return { max_speed_kmh: 0, reason: 'outside_city',
                     message: 'You are outside the service area. Please return.' };
        }
        if (location.zone) {
            if (location.zone.type === 'parking' || location.zone.type === 'bonus_parking') {
                return { max_speed_kmh: PARK_SPEED_LIMIT_KMH,
                         reason: 'parking_zone', zone_type: location.zone.type };
            }
            if (location.zone.type === 'no_parking') {
                return { max_speed_kmh: DEFAULT_SPEED_LIMIT_KMH,
                         reason: 'no_parking_zone',
                         message: 'You are in a no-parking zone. End ride here will incur a fee.' };
            }
        }
        return { max_speed_kmh: DEFAULT_SPEED_LIMIT_KMH, reason: 'street' };
    },

    /**
     * Check active trip for zone violations and send notifications.
     * Called by cron every minute.
     */
    checkActiveTripViolations: async function() {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tripsCol = db.collection("trips");
            const scootersCol = db.collection("scooters");
            const notifications = require('./notifications.js');

            const activeTrips = await tripsCol.find({ status: 'active' }).toArray();
            let violations = 0;
            for (const trip of activeTrips) {
                const scooter = await scootersCol.findOne({ _id: trip.scooter_id });
                if (!scooter || !scooter.coordinates) continue;
                const location = await geofencing.locatePoint(scooter.coordinates);
                if (!location) {
                    // Outside service area — warn user once per trip
                    if (!trip.outside_city_warned) {
                        await notifications.send(trip.user_id, {
                            title: 'Внимание!',
                            body: 'Вы покинули зону обслуживания. Вернитесь, чтобы завершить поездку без штрафа.',
                            type: 'zone_violation',
                            data: { trip_id: String(trip._id), violation: 'outside_city' }
                        });
                        await tripsCol.updateOne({ _id: trip._id },
                            { $set: { outside_city_warned: true } });
                        violations++;
                    }
                    continue;
                }
                if (location.zone && location.zone.type === 'no_parking'
                    && !trip.no_parking_warned) {
                    await notifications.send(trip.user_id, {
                        title: 'Запретная зона',
                        body: 'Вы въехали в зону с запретом парковки. Если закончите поездку здесь — будет штраф.',
                        type: 'zone_violation',
                        data: { trip_id: String(trip._id), violation: 'no_parking_enter' }
                    });
                    await tripsCol.updateOne({ _id: trip._id },
                        { $set: { no_parking_warned: true } });
                    violations++;
                }
            }
            console.log(`[geofencing] Detected ${violations} violations across ${activeTrips.length} active trips`);
            return violations;
        } finally { await client.close(); }
    },

    /**
     * POST /geofencing/check — public endpoint to check a location
     * Body: { coordinates: { longitude, latitude } }
     * Returns: { inside_service_area, city, zone, speed_limit }
     */
    checkLocation: async function(res, body, path) {
        const coords = body.coordinates;
        if (!coords || !coords.longitude || !coords.latitude) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "coordinates {longitude, latitude} required" }});
        }
        try {
            const location = await geofencing.locatePoint(coords);
            const speedLimit = await geofencing.getSpeedLimit(coords);
            return res.status(200).json({ data: {
                coordinates: coords,
                inside_service_area: !!location,
                city: location ? { id: location.city_id, name: location.city_name } : null,
                zone: location?.zone ? { type: location.zone.type,
                                          id: location.zone._id } : null,
                speed_limit_kmh: speedLimit.max_speed_kmh,
                speed_limit_reason: speedLimit.reason,
                message: speedLimit.message || null,
            }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        }
    },
};

module.exports = geofencing;
module.exports.DEFAULT_SPEED_LIMIT_KMH = DEFAULT_SPEED_LIMIT_KMH;
module.exports.PARK_SPEED_LIMIT_KMH = PARK_SPEED_LIMIT_KMH;
