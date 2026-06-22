/**
 * trips.js — Trip lifecycle model for SparkRentals
 *
 * Lifecycle: reserved → active → ended → (optional: refunded)
 *
 * Cost calculation:
 *   base = city.fixedRate
 *   time = minutes * city.timeRate
 *   parking_discount = -parkingZoneRate (if ended in parking zone)
 *   bonus_discount    = -bonusParkingZoneRate (if ended in bonus zone)
 *   no_parking_fee    = +noParkingZoneRate (if ended in no-parking zone)
 *   total = max(0, base + time - discounts + fees)
 *
 * Battery drain approximation:
 *   drain_per_minute = 0.5%  (configurable per scooter model later)
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const mongoURI = process.env.DBURI;

const BATTERY_DRAIN_PER_MIN = 0.5; // % per minute
const RESERVATION_TTL_MIN = 10;    // reservation expires after 10 min
const MAX_TRIP_HOURS = 8;          // auto-end trip after 8h

const trips = {
    /**
     * POST /trips/reserve
     * Body: { scooter_id, api_key, x-access-token }
     * - User must be authenticated
     * - Scooter must be 'available' and have battery > 10%
     * - Creates reservation, sets scooter status to 'reserved'
     * - Reservation expires in RESERVATION_TTL_MIN minutes
     */
    reserveScooter: async function(res, body, user, path) {
        const scooterId = sanitize(body.scooter_id);
        const userId = user.id;

        if (!scooterId || !ObjectId.isValid(scooterId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid scooter_id", detail: "scooter_id missing or invalid" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const scootersCol = db.collection("scooters");
            const tripsCol = db.collection("trips");

            const scooter = await scootersCol.findOne({ _id: new ObjectId(scooterId) });
            if (!scooter) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Scooter not found" }});
            }
            if (scooter.status !== 'available') {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Scooter not available",
                    detail: `Current status: ${scooter.status}` }});
            }
            if (scooter.battery < 10) {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Low battery", detail: `Battery at ${scooter.battery}%` }});
            }

            // Check user has no active trip already
            const existing = await tripsCol.findOne({
                user_id: new ObjectId(userId),
                status: { $in: ['reserved', 'active'] }
            });
            if (existing) {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Active trip exists",
                    detail: "User already has an active reservation or trip" }});
            }

            const now = new Date();
            const expiresAt = new Date(now.getTime() + RESERVATION_TTL_MIN * 60 * 1000);

            const trip = {
                user_id: new ObjectId(userId),
                scooter_id: new ObjectId(scooterId),
                city_id: scooter.owner,
                status: 'reserved',
                start_time: null,
                end_time: null,
                reservation_time: now,
                reservation_expires: expiresAt,
                start_coordinates: null,
                end_coordinates: null,
                start_battery: null,
                end_battery: null,
                distance_km: 0,
                duration_min: 0,
                cost: 0,
                cost_breakdown: {},
                photo_url: null,
                end_zone_type: null,
                refund_amount: 0,
                refund_reason: null,
                created_at: now,
                updated_at: now,
            };

            const result = await tripsCol.insertOne(trip);
            await scootersCol.updateOne(
                { _id: new ObjectId(scooterId) },
                { $set: { status: 'reserved', trip: { trip_id: result.insertedId, user_id: userId },
                          updated_at: now } }
            );

            return res.status(201).json({
                data: {
                    type: "success",
                    message: "Scooter reserved",
                    trip_id: result.insertedId,
                    expires_at: expiresAt,
                    expires_in_seconds: RESERVATION_TTL_MIN * 60,
                }
            });
        } catch (e) {
            console.error("reserveScooter error:", e);
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally {
            await client.close();
        }
    },

    /**
     * POST /trips/start
     * Body: { trip_id, api_key, x-access-token }
     * - Converts reservation to active trip
     * - Records start coordinates and battery
     * - Sets scooter status to 'in_use'
     */
    startTrip: async function(res, body, user, path) {
        const tripId = sanitize(body.trip_id);
        const userId = user.id;

        if (!tripId || !ObjectId.isValid(tripId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid trip_id" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tripsCol = db.collection("trips");
            const scootersCol = db.collection("scooters");

            const trip = await tripsCol.findOne({ _id: new ObjectId(tripId) });
            if (!trip) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Trip not found" }});
            }
            if (trip.user_id.toString() !== userId) {
                return res.status(403).json({ errors: { status: 403, source: path,
                    title: "Forbidden", detail: "This trip belongs to another user" }});
            }
            if (trip.status !== 'reserved') {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Trip not reservable",
                    detail: `Current status: ${trip.status}` }});
            }
            // Check reservation not expired
            if (new Date() > trip.reservation_expires) {
                await tripsCol.updateOne({ _id: trip._id },
                    { $set: { status: 'expired', updated_at: new Date() }});
                await scootersCol.updateOne({ _id: trip.scooter_id },
                    { $set: { status: 'available', trip: {}, updated_at: new Date() }});
                return res.status(410).json({ errors: { status: 410, source: path,
                    title: "Reservation expired",
                    detail: "Please reserve the scooter again" }});
            }

            const scooter = await scootersCol.findOne({ _id: trip.scooter_id });
            if (!scooter || scooter.status !== 'reserved') {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Scooter state changed",
                    detail: "Scooter is no longer reserved for you" }});
            }

            const now = new Date();
            await tripsCol.updateOne({ _id: trip._id }, {
                $set: {
                    status: 'active',
                    start_time: now,
                    start_coordinates: scooter.coordinates,
                    start_battery: scooter.battery,
                    updated_at: now,
                }
            });
            await scootersCol.updateOne({ _id: scooter._id },
                { $set: { status: 'in_use', updated_at: now } });

            return res.status(200).json({
                data: {
                    type: "success",
                    message: "Trip started",
                    trip_id: tripId,
                    start_time: now,
                    start_battery: scooter.battery,
                    start_coordinates: scooter.coordinates,
                }
            });
        } catch (e) {
            console.error("startTrip error:", e);
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally {
            await client.close();
        }
    },

    /**
     * POST /trips/end
     * Body: { trip_id, end_coordinates?, photo_url?, api_key, x-access-token }
     * - Calculates cost based on city rates and zones
     * - Detects end zone type (parking/bonus/no-parking/charging)
     * - Updates scooter battery based on duration
     * - Deducts from user balance
     */
    endTrip: async function(res, body, user, path) {
        const tripId = sanitize(body.trip_id);
        const userId = user.id;
        const endCoordinates = body.end_coordinates || null;
        const photoUrl = sanitize(body.photo_url) || null;

        if (!tripId || !ObjectId.isValid(tripId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid trip_id" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tripsCol = db.collection("trips");
            const scootersCol = db.collection("scooters");
            const citiesCol = db.collection("cities");
            const usersCol = db.collection("users");
            const transactionsCol = db.collection("transactions");

            const trip = await tripsCol.findOne({ _id: new ObjectId(tripId) });
            if (!trip) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Trip not found" }});
            }
            if (trip.user_id.toString() !== userId) {
                return res.status(403).json({ errors: { status: 403, source: path,
                    title: "Forbidden" }});
            }
            if (trip.status !== 'active') {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Trip not active", detail: `Current status: ${trip.status}` }});
            }

            const scooter = await scootersCol.findOne({ _id: trip.scooter_id });
            if (!scooter) {
                return res.status(500).json({ errors: { status: 500, source: path,
                    title: "Scooter missing" }});
            }

            const city = await citiesCol.findOne({ _id: scooter.owner });
            if (!city) {
                return res.status(500).json({ errors: { status: 500, source: path,
                    title: "City missing for scooter" }});
            }

            const now = new Date();
            const durationMs = now - trip.start_time;
            const durationMin = Math.max(1, Math.ceil(durationMs / 60000));
            const batteryDrain = Math.min(scooter.battery,
                Math.round(durationMin * BATTERY_DRAIN_PER_MIN * 100) / 100);
            const endBattery = Math.round((scooter.battery - batteryDrain) * 100) / 100;

            // Determine end zone
            const endCoords = endCoordinates || scooter.coordinates;
            const zoneResult = trips._detectZone(endCoords, city.zones || []);

            // Cost calculation
            const base = city.fixedRate || 0;
            const time = durationMin * (city.timeRate || 0);
            let discount = 0;
            let fee = 0;
            let endZoneType = 'street'; // default: outside any zone

            if (zoneResult) {
                endZoneType = zoneResult.type;
                if (zoneResult.type === 'parking') discount += city.parkingZoneRate || 0;
                if (zoneResult.type === 'bonus_parking') discount += city.bonusParkingZoneRate || 0;
                if (zoneResult.type === 'no_parking') fee += city.noParkingZoneRate || 0;
            } else {
                // Outside zones — full no-parking fee
                endZoneType = 'street';
                fee += city.noParkingZoneRate || 0;
            }

            const totalCost = Math.max(0, base + time - discount + fee);

            // Update user balance
            const userDoc = await usersCol.findOne({ _id: new ObjectId(userId) });
            if (!userDoc) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "User not found" }});
            }
            const newBalance = (userDoc.balance || 0) - totalCost;

            // Transaction record
            const txn = {
                user_id: new ObjectId(userId),
                trip_id: trip._id,
                type: 'trip_payment',
                amount: -totalCost,
                balance_after: newBalance,
                method: 'balance',
                provider: 'internal',
                provider_txn_id: null,
                status: 'completed',
                description: `Trip ${tripId} — ${durationMin} min, zone: ${endZoneType}`,
                created_at: now,
            };
            await transactionsCol.insertOne(txn);

            // Update trip
            await tripsCol.updateOne({ _id: trip._id }, {
                $set: {
                    status: 'ended',
                    end_time: now,
                    end_coordinates: endCoords,
                    end_battery: endBattery,
                    end_zone_type: endZoneType,
                    duration_min: durationMin,
                    distance_km: 0, // TODO: calculate from GPS track later
                    cost: totalCost,
                    cost_breakdown: {
                        base, time, discount, fee,
                        city_rates: {
                            fixedRate: city.fixedRate,
                            timeRate: city.timeRate,
                            parkingZoneRate: city.parkingZoneRate,
                            bonusParkingZoneRate: city.bonusParkingZoneRate,
                            noParkingZoneRate: city.noParkingZoneRate,
                        }
                    },
                    photo_url: photoUrl,
                    updated_at: now,
                }
            });

            // Update scooter
            const newScooterStatus = endBattery < 20 ? 'charging_needed' : 'available';
            await scootersCol.updateOne({ _id: scooter._id }, {
                $set: {
                    status: newScooterStatus,
                    coordinates: endCoords,
                    battery: endBattery,
                    trip: {},
                    updated_at: now,
                },
                $push: {
                    log: {
                        event: 'trip_ended',
                        trip_id: trip._id,
                        user_id: new ObjectId(userId),
                        timestamp: now,
                        battery_before: scooter.battery,
                        battery_after: endBattery,
                        duration_min: durationMin,
                        cost: totalCost,
                        zone: endZoneType,
                    }
                }
            });

            // Update user balance + history
            await usersCol.updateOne({ _id: userDoc._id }, {
                $set: { balance: newBalance, updated_at: now },
                $push: {
                    history: {
                        trip_id: trip._id,
                        scooter_id: scooter._id,
                        start_time: trip.start_time,
                        end_time: now,
                        duration_min: durationMin,
                        cost: totalCost,
                        zone: endZoneType,
                    }
                }
            });

            return res.status(200).json({
                data: {
                    type: "success",
                    message: "Trip ended",
                    trip_id: tripId,
                    duration_min: durationMin,
                    cost: totalCost,
                    cost_breakdown: { base, time, discount, fee },
                    end_zone: endZoneType,
                    end_battery: endBattery,
                    new_balance: newBalance,
                }
            });
        } catch (e) {
            console.error("endTrip error:", e);
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally {
            await client.close();
        }
    },

    /**
     * POST /trips/cancel
     * Cancels a reservation (no cost) or active trip (small fee if active > 1 min).
     */
    cancelTrip: async function(res, body, user, path) {
        const tripId = sanitize(body.trip_id);
        const reason = sanitize(body.reason) || 'user_cancelled';
        const userId = user.id;

        if (!tripId || !ObjectId.isValid(tripId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid trip_id" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tripsCol = db.collection("trips");
            const scootersCol = db.collection("scooters");

            const trip = await tripsCol.findOne({ _id: new ObjectId(tripId) });
            if (!trip) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Trip not found" }});
            }
            if (trip.user_id.toString() !== userId) {
                return res.status(403).json({ errors: { status: 403, source: path,
                    title: "Forbidden" }});
            }
            if (!['reserved', 'active'].includes(trip.status)) {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Cannot cancel",
                    detail: `Trip status: ${trip.status}` }});
            }

            const wasActive = trip.status === 'active';
            await tripsCol.updateOne({ _id: trip._id }, {
                $set: { status: 'cancelled', cancelled_reason: reason,
                        cancelled_at: new Date(), updated_at: new Date() }
            });
            await scootersCol.updateOne({ _id: trip.scooter_id }, {
                $set: { status: 'available', trip: {}, updated_at: new Date() }
            });

            return res.status(200).json({
                data: {
                    type: "success",
                    message: wasActive ? "Trip cancelled (fee may apply)" : "Reservation cancelled",
                    trip_id: tripId,
                }
            });
        } catch (e) {
            console.error("cancelTrip error:", e);
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally {
            await client.close();
        }
    },

    /**
     * GET /trips/active?user_id=...
     * Returns the user's currently active or reserved trip.
     */
    getActiveTrip: async function(res, user, path) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tripsCol = db.collection("trips");
            const trip = await tripsCol.findOne({
                user_id: new ObjectId(user.id),
                status: { $in: ['reserved', 'active'] }
            });
            if (!trip) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "No active trip" }});
            }
            return res.status(200).json({ data: { trip }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * GET /trips/history
     * Returns paginated trip history for the user.
     */
    getTripHistory: async function(res, query, user, path) {
        const limit = Math.min(parseInt(query.limit || '20'), 100);
        const offset = Math.max(parseInt(query.offset || '0'), 0);

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tripsCol = db.collection("trips");
            const cursor = tripsCol.find({ user_id: new ObjectId(user.id) })
                .sort({ created_at: -1 })
                .skip(offset)
                .limit(limit);
            const items = await cursor.toArray();
            const total = await tripsCol.countDocuments({ user_id: new ObjectId(user.id) });
            return res.status(200).json({ data: { trips: items, total, limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: GET /trips
     * Returns all trips (paginated, filterable by status/user/scooter).
     */
    getAllTrips: async function(res, query, path) {
        const limit = Math.min(parseInt(query.limit || '50'), 200);
        const offset = Math.max(parseInt(query.offset || '0'), 0);
        const filter = {};
        if (query.status) filter.status = sanitize(query.status);
        if (query.user_id && ObjectId.isValid(query.user_id))
            filter.user_id = new ObjectId(sanitize(query.user_id));
        if (query.scooter_id && ObjectId.isValid(query.scooter_id))
            filter.scooter_id = new ObjectId(sanitize(query.scooter_id));

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tripsCol = db.collection("trips");
            const items = await tripsCol.find(filter)
                .sort({ created_at: -1 }).skip(offset).limit(limit).toArray();
            const total = await tripsCol.countDocuments(filter);
            return res.status(200).json({ data: { trips: items, total, limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: POST /trips/refund
     * Body: { trip_id, amount, reason }
     */
    refundTrip: async function(res, body, path) {
        const tripId = sanitize(body.trip_id);
        const amount = parseFloat(sanitize(body.amount));
        const reason = sanitize(body.reason) || 'admin_refund';

        if (!tripId || !ObjectId.isValid(tripId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid trip_id" }});
        }
        if (!amount || amount <= 0) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid amount" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tripsCol = db.collection("trips");
            const usersCol = db.collection("users");
            const transactionsCol = db.collection("transactions");

            const trip = await tripsCol.findOne({ _id: new ObjectId(tripId) });
            if (!trip) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Trip not found" }});
            }
            const refundAmount = Math.min(amount, trip.cost || 0);
            const userDoc = await usersCol.findOne({ _id: trip.user_id });
            if (!userDoc) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "User not found" }});
            }
            const newBalance = (userDoc.balance || 0) + refundAmount;

            await tripsCol.updateOne({ _id: trip._id }, {
                $set: { refund_amount: refundAmount, refund_reason: reason,
                        updated_at: new Date() }
            });
            await usersCol.updateOne({ _id: userDoc._id },
                { $set: { balance: newBalance, updated_at: new Date() }});
            await transactionsCol.insertOne({
                user_id: userDoc._id,
                trip_id: trip._id,
                type: 'refund',
                amount: refundAmount,
                balance_after: newBalance,
                method: 'balance',
                provider: 'internal',
                provider_txn_id: null,
                status: 'completed',
                description: `Refund for trip ${tripId}: ${reason}`,
                created_at: new Date(),
            });

            return res.status(200).json({
                data: { type: "success", message: "Refund processed",
                        trip_id: tripId, refund_amount: refundAmount,
                        new_balance: newBalance }
            });
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Helper: detect which zone a coordinate falls into.
     * Uses robust-point-in-polygon for point-in-polygon test.
     */
    _detectZone: function(coordinates, zones) {
        if (!zones || !zones.length || !coordinates) return null;
        const classifyPoint = require('robust-point-in-polygon');
        const lng = parseFloat(coordinates.longitude);
        const lat = parseFloat(coordinates.latitude);
        if (isNaN(lng) || isNaN(lat)) return null;

        for (const zone of zones) {
            if (!zone.polygon || zone.polygon.length < 3) continue;
            const poly = zone.polygon.map(p => [parseFloat(p.longitude), parseFloat(p.latitude)]);
            const inside = classifyPoint(poly, [lng, lat]) === -1;
            if (inside) return zone;
        }
        return null;
    },

    /**
     * Cron helper: expire stale reservations
     */
    expireStaleReservations: async function() {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tripsCol = db.collection("trips");
            const scootersCol = db.collection("scooters");
            const stale = await tripsCol.find({
                status: 'reserved',
                reservation_expires: { $lt: new Date() }
            }).toArray();
            for (const trip of stale) {
                await tripsCol.updateOne({ _id: trip._id }, {
                    $set: { status: 'expired', updated_at: new Date() }
                });
                await scootersCol.updateOne({ _id: trip.scooter_id }, {
                    $set: { status: 'available', trip: {}, updated_at: new Date() }
                });
            }
            console.log(`[trips] Expired ${stale.length} stale reservations`);
            return stale.length;
        } finally { await client.close(); }
    },

    /**
     * Cron helper: auto-end trips longer than MAX_TRIP_HOURS
     */
    autoEndLongTrips: async function() {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tripsCol = db.collection("trips");
            const threshold = new Date(Date.now() - MAX_TRIP_HOURS * 3600 * 1000);
            const longTrips = await tripsCol.find({
                status: 'active',
                start_time: { $lt: threshold }
            }).toArray();
            // Mark for review; actual end requires user input or admin intervention
            for (const trip of longTrips) {
                await tripsCol.updateOne({ _id: trip._id }, {
                    $set: { auto_end_flagged: true, updated_at: new Date() }
                });
            }
            console.log(`[trips] Flagged ${longTrips.length} long trips for auto-end`);
            return longTrips.length;
        } finally { await client.close(); }
    },
};

module.exports = trips;
