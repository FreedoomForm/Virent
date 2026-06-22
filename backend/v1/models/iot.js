/**
 * iot.js — IoT endpoints for ESP32/scooter firmware
 *
 * Endpoints:
 *   POST /iot/telemetry — scooter pushes GPS + battery + status
 *   POST /iot/event      — scooter pushes event (lock/unlock/low_battery/alarm)
 *   GET  /iot/command    — scooter polls for pending commands
 *
 * Auth: scooter authenticates with its mac_address + secret token
 * (set during provisioning; not user JWT).
 *
 * In production, MQTT broker would push these messages, but HTTP polling
 * is a simpler alternative for low-cost ESP32 firmware.
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const crypto = require('crypto');
const mongoURI = process.env.DBURI;

const iot = {
    /**
     * POST /iot/telemetry
     * Body: { scooter_mac, secret, coordinates, battery, speed, status? }
     * Updates scooter coordinates, battery, last_seen, speed.
     * If battery < 20%, status → 'charging_needed'.
     */
    telemetry: async function(res, body, path) {
        const mac = sanitize(body.scooter_mac);
        const secret = sanitize(body.secret);
        const coords = body.coordinates;
        const battery = parseFloat(sanitize(body.battery));
        const speed = parseFloat(sanitize(body.speed)) || 0;
        const newStatus = sanitize(body.status);

        if (!mac || !secret) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "scooter_mac and secret required" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const scootersCol = db.collection("scooters");
            const scooter = await scootersCol.findOne({ mac_address: mac });
            if (!scooter) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Scooter not provisioned" }});
            }
            // Verify secret (per-scooter secret stored at provisioning time)
            const expectedHash = crypto.createHash('sha256')
                .update(mac + (process.env.JWT_SECRET || 'dev')).digest('hex');
            const providedHash = crypto.createHash('sha256').update(secret).digest('hex');
            if (scooter.iot_secret_hash && scooter.iot_secret_hash !== providedHash) {
                return res.status(401).json({ errors: { status: 401, source: path,
                    title: "Invalid scooter secret" }});
            }

            const now = new Date();
            const update = {
                $set: {
                    last_seen: now,
                    updated_at: now,
                },
                $push: {
                    telemetry_log: {
                        $each: [{
                            timestamp: now,
                            coordinates: coords,
                            battery,
                            speed,
                        }],
                        $slice: -100, // keep last 100 telemetry points
                    }
                }
            };
            if (coords) update.$set.coordinates = coords;
            if (!isNaN(battery)) {
                update.$set.battery = battery;
                update.$set.battery_health_percent = scooter.battery_health_percent; // unchanged
                // Auto-flag low battery
                if (battery < 20 && scooter.status === 'available') {
                    update.$set.status = 'charging_needed';
                }
            }
            if (newStatus && ['available', 'in_use', 'charging_needed',
                              'charging', 'maintenance', 'reserved'].includes(newStatus)) {
                update.$set.status = newStatus;
            }
            await scootersCol.updateOne({ _id: scooter._id }, update);

            return res.status(200).json({ data: { type: "success",
                message: "Telemetry received", scooter_id: scooter._id }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * POST /iot/event
     * Body: { scooter_mac, secret, event_type, data? }
     * Events: lock, unlock, low_battery, alarm, fall, geofence_violation, firmware_update
     */
    event: async function(res, body, path) {
        const mac = sanitize(body.scooter_mac);
        const eventType = sanitize(body.event_type);
        const data = body.data || {};

        if (!mac || !eventType) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "scooter_mac and event_type required" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const scootersCol = db.collection("scooters");
            const scooter = await scootersCol.findOne({ mac_address: mac });
            if (!scooter) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Scooter not found" }});
            }

            const now = new Date();
            await scootersCol.updateOne({ _id: scooter._id }, {
                $push: {
                    log: {
                        event: `iot_${eventType}`,
                        timestamp: now,
                        data,
                    }
                },
                $set: { last_seen: now, updated_at: now }
            });

            // Notify active trip user about important events
            if (scooter.trip && scooter.trip.trip_id && scooter.trip.user_id) {
                const notifications = require('./notifications.js');
                const messages = {
                    'low_battery': { title: 'Low battery',
                        body: 'Scooter battery is low. Please end your ride soon.' },
                    'alarm': { title: 'Alarm triggered',
                        body: 'Scooter alarm was triggered. Are you OK?' },
                    'fall': { title: 'Fall detected',
                        body: 'A fall was detected. If you need help, contact support.' },
                    'geofence_violation': { title: 'Zone violation',
                        body: 'You are in a restricted area. Please return.' },
                };
                if (messages[eventType]) {
                    await notifications.send(scooter.trip.user_id, {
                        ...messages[eventType],
                        type: 'iot_event',
                        data: { event: eventType, scooter_id: String(scooter._id),
                                trip_id: String(scooter.trip.trip_id) }
                    });
                }
            }

            return res.status(200).json({ data: { type: "success",
                message: "Event recorded" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * GET /iot/command?scooter_mac=...
     * Scooter polls for pending commands.
     * Returns: { commands: [{ command, params, command_id }] }
     * Commands: lock, unlock, alarm_on, alarm_off, led_on, led_off,
     *           update_firmware, reboot
     */
    pollCommand: async function(res, query, path) {
        const mac = sanitize(query.scooter_mac);
        if (!mac) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "scooter_mac required" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("scooter_commands");
            const commands = await col.find({
                scooter_mac: mac, status: 'pending'
            }).sort({ created_at: 1 }).limit(5).toArray();
            // Mark as delivered
            if (commands.length > 0) {
                await col.updateMany(
                    { _id: { $in: commands.map(c => c._id) } },
                    { $set: { status: 'delivered', delivered_at: new Date() } }
                );
            }
            return res.status(200).json({ data: { commands }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: POST /iot/command/send
     * Body: { scooter_mac, command, params? }
     */
    sendCommand: async function(res, body, path) {
        const mac = sanitize(body.scooter_mac);
        const command = sanitize(body.command);
        const params = body.params || {};
        if (!mac || !command) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "scooter_mac and command required" }});
        }
        const validCommands = ['lock', 'unlock', 'alarm_on', 'alarm_off',
            'led_on', 'led_off', 'update_firmware', 'reboot', 'locate'];
        if (!validCommands.includes(command)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: `command must be one of: ${validCommands.join(', ')}` }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("scooter_commands");
            const result = await col.insertOne({
                scooter_mac: mac,
                command,
                params,
                status: 'pending',
                created_at: new Date(),
                delivered_at: null,
                ack_at: null,
            });
            return res.status(201).json({ data: { type: "success",
                command_id: result.insertedId, message: "Command queued" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },
};

module.exports = iot;
