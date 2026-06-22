/**
 * discovery.js — scooter discovery for users
 *
 * Endpoints:
 *   GET /discovery/nearest?lat=&lng=&radius_km=  — nearest available scooters
 *   GET /discovery/available?city_id=            — all available in city
 *   GET /discovery/qr/:code                       — resolve QR code → scooter
 *
 * QR code format: SR-{scooter_id_short}  (6-char prefix of _id)
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const mongoURI = process.env.DBURI;

function haversineKm(lat1, lng1, lat2, lng2) {
    const R = 6371; // Earth radius km
    const toRad = (d) => d * Math.PI / 180;
    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a = Math.sin(dLat / 2) ** 2 +
              Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
    return 2 * R * Math.asin(Math.sqrt(a));
}

const discovery = {
    /**
     * GET /discovery/nearest?lat=41.31&lng=69.24&radius_km=2&limit=10
     */
    nearest: async function(res, query, path) {
        const lat = parseFloat(sanitize(query.lat));
        const lng = parseFloat(sanitize(query.lng));
        const radiusKm = parseFloat(sanitize(query.radius_km)) || 2;
        const limit = Math.min(parseInt(sanitize(query.limit)) || 10, 50);

        if (isNaN(lat) || isNaN(lng)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "lat and lng required as numbers" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            // Find all available scooters — in production we'd use $near with geo index
            const scooters = await db.collection("scooters").find({
                status: 'available',
                battery: { $gte: 15 },
            }).toArray();

            const withDistance = scooters.map(s => {
                const sLat = parseFloat(s.coordinates?.latitude);
                const sLng = parseFloat(s.coordinates?.longitude);
                if (isNaN(sLat) || isNaN(sLng)) return null;
                return { ...s, distance_km: haversineKm(lat, lng, sLat, sLng) };
            }).filter(s => s && s.distance_km <= radiusKm)
              .sort((a, b) => a.distance_km - b.distance_km)
              .slice(0, limit);

            return res.status(200).json({ data: {
                scooters: withDistance,
                count: withDistance.length,
                center: { lat, lng },
                radius_km: radiusKm,
            }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * GET /discovery/available?city_id=...&limit=...
     */
    availableInCity: async function(res, query, path) {
        const cityId = sanitize(query.city_id);
        const limit = Math.min(parseInt(sanitize(query.limit)) || 50, 200);
        if (!cityId || !ObjectId.isValid(cityId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Valid city_id required" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const scooters = await db.collection("scooters").find({
                owner: new ObjectId(cityId),
                status: 'available',
                battery: { $gte: 15 },
            }).limit(limit).toArray();
            return res.status(200).json({ data: { scooters, count: scooters.length }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * GET /discovery/qr/:code
     * QR code format: SR-XXXXXX (first 6 chars of _id hex)
     */
    resolveQr: async function(res, code, path) {
        const cleaned = (code || '').toUpperCase().replace(/[^A-Z0-9-]/g, '');
        if (!cleaned.startsWith('SR-')) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid QR code format. Expected SR-XXXXXX..." }});
        }
        const shortId = cleaned.slice(3);
        if (shortId.length < 6) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid QR code length" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            // Find scooter whose _id starts with this short id
            const scooters = await db.collection("scooters").find({
                _id: { $gte: new ObjectId(shortId + "0".repeat(24 - shortId.length)),
                       $lte: new ObjectId(shortId + "f".repeat(24 - shortId.length)) }
            }).limit(1).toArray();
            if (!scooters.length) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Scooter not found for this QR code" }});
            }
            const scooter = scooters[0];
            return res.status(200).json({ data: {
                scooter_id: scooter._id,
                name: scooter.name,
                battery: scooter.battery,
                status: scooter.status,
                model: scooter.model,
                coordinates: scooter.coordinates,
            }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Generate QR code string for a scooter
     */
    generateQrCode: function(scooterId) {
        const hex = String(scooterId);
        return `SR-${hex.slice(0, 6).toUpperCase()}`;
    },
};

module.exports = discovery;
