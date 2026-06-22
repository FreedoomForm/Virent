/**
 * mechanics.js — maintenance & repair team
 *
 * Workflow:
 *   1. Breakdown ticket creates a maintenance request automatically (via support.js)
 *   2. Or system auto-flags scooter with low battery + offline > 24h
 *   3. Admin assigns mechanic to maintenance request
 *   4. Mechanic picks up / inspects scooter
 *   5. Mechanic marks fixed or escalates (needs spare parts)
 *   6. Parts used logged in inventory
 *   7. Scooter back to 'available' status
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const mongoURI = process.env.DBURI;

const PARTS_CATALOG = [
    'front_wheel', 'rear_wheel', 'brake_pad', 'brake_cable',
    'battery_pack', 'display_unit', 'throttle', 'controller',
    'frame_part', 'headlight', 'taillight', 'lock_mechanism',
    'tire', 'inner_tube', 'screw_set', 'other'
];

const mechanics = {
    /**
     * Admin: POST /mechanics — register mechanic
     */
    register: async function(res, body, path) {
        const phone = sanitize(body.phone);
        const firstName = sanitize(body.firstName);
        const lastName = sanitize(body.lastName);
        const specialization = sanitize(body.specialization) || 'general';

        if (!phone || !firstName || !lastName) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "phone, firstName, lastName required" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("mechanics");
            const existing = await col.findOne({ phone });
            if (existing) {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Mechanic with this phone exists" }});
            }
            const result = await col.insertOne({
                phone, firstName, lastName, specialization,
                status: 'active',
                total_repairs: 0,
                current_assignments: 0,
                parts_used_total: 0,
                created_at: new Date(),
                updated_at: new Date(),
            });
            return res.status(201).json({ data: { type: "success",
                mechanic_id: result.insertedId }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: POST /mechanics/requests/:id/assign — assign mechanic
     */
    assignRequest: async function(res, requestId, body, path) {
        const mechanicId = sanitize(body.mechanic_id);
        if (!ObjectId.isValid(requestId) || !ObjectId.isValid(mechanicId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid ids" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const reqCol = db.collection("maintenance_requests");
            const request = await reqCol.findOne({ _id: new ObjectId(requestId) });
            if (!request) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Request not found" }});
            }
            if (request.status !== 'open') {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Request already assigned/closed" }});
            }
            await reqCol.updateOne({ _id: request._id }, {
                $set: { status: 'assigned', mechanic_id: new ObjectId(mechanicId),
                        assigned_at: new Date(), updated_at: new Date() }
            });
            await db.collection("mechanics").updateOne(
                { _id: new ObjectId(mechanicId) },
                { $inc: { current_assignments: 1 }, $set: { updated_at: new Date() } });
            return res.status(200).json({ data: { type: "success",
                message: "Assigned" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Mechanic: GET /mechanics/me/requests — my assigned requests
     */
    myRequests: async function(res, mechanic, query, path) {
        const limit = Math.min(parseInt(query.limit || '50'), 200);
        const offset = Math.max(parseInt(query.offset || '0'), 0);
        const filter = { mechanic_id: new ObjectId(mechanic.id) };
        if (query.status) filter.status = sanitize(query.status);
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("maintenance_requests");
            const items = await col.find(filter).sort({ assigned_at: -1 })
                .skip(offset).limit(limit).toArray();
            const total = await col.countDocuments(filter);
            return res.status(200).json({ data: { requests: items, total, limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Mechanic: POST /mechanics/requests/:id/start — start working
     */
    startWork: async function(res, requestId, mechanic, path) {
        if (!ObjectId.isValid(requestId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid request_id" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("maintenance_requests");
            const req = await col.findOne({ _id: new ObjectId(requestId),
                mechanic_id: new ObjectId(mechanic.id) });
            if (!req) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Not found or not assigned to you" }});
            }
            if (req.status !== 'assigned') {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Cannot start — already started or completed" }});
            }
            await col.updateOne({ _id: req._id }, {
                $set: { status: 'in_progress', work_started_at: new Date(),
                        updated_at: new Date() }
            });
            await db.collection("scooters").updateOne({ _id: req.scooter_id }, {
                $set: { status: 'maintenance', updated_at: new Date() }
            });
            return res.status(200).json({ data: { type: "success",
                message: "Work started" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Mechanic: POST /mechanics/requests/:id/complete
     * Body: { resolution_note, parts_used: [{part, quantity}], photo_url, scoooter_status }
     */
    completeWork: async function(res, requestId, body, mechanic, path) {
        if (!ObjectId.isValid(requestId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid request_id" }});
        }
        const resolutionNote = sanitize(body.resolution_note);
        const partsUsed = body.parts_used || [];
        const photoUrl = sanitize(body.photo_url);
        const scooterStatus = sanitize(body.scooter_status) || 'available';

        if (!resolutionNote) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "resolution_note required" }});
        }
        if (!['available', 'maintenance', 'retired'].includes(scooterStatus)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "scooter_status must be: available, maintenance, or retired" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("maintenance_requests");
            const req = await col.findOne({ _id: new ObjectId(requestId),
                mechanic_id: new ObjectId(mechanic.id) });
            if (!req) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Not found" }});
            }
            if (req.status !== 'in_progress') {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Request not in progress" }});
            }
            // Validate parts
            for (const p of partsUsed) {
                if (!PARTS_CATALOG.includes(p.part)) {
                    return res.status(400).json({ errors: { status: 400, source: path,
                        title: `Invalid part: ${p.part}. Allowed: ${PARTS_CATALOG.join(', ')}` }});
                }
                if (!p.quantity || p.quantity < 1) {
                    return res.status(400).json({ errors: { status: 400, source: path,
                        title: `Invalid quantity for ${p.part}` }});
                }
            }

            const now = new Date();
            await col.updateOne({ _id: req._id }, {
                $set: { status: 'completed', completed_at: now,
                        resolution_note: resolutionNote,
                        parts_used: partsUsed,
                        completion_photo_url: photoUrl,
                        updated_at: now }
            });
            await db.collection("scooters").updateOne({ _id: req.scooter_id }, {
                $set: { status: scooterStatus, updated_at: now },
                $push: { log: { event: 'maintenance_completed',
                                mechanic_id: new ObjectId(mechanic.id),
                                request_id: req._id,
                                parts_used: partsUsed,
                                note: resolutionNote,
                                timestamp: now } }
            });
            await db.collection("mechanics").updateOne(
                { _id: new ObjectId(mechanic.id) },
                { $inc: { total_repairs: 1, current_assignments: -1,
                          parts_used_total: partsUsed.reduce((s,p) => s + p.quantity, 0) },
                  $set: { updated_at: now } });
            // Decrement inventory
            for (const p of partsUsed) {
                await db.collection("parts_inventory").updateOne(
                    { part: p.part },
                    { $inc: { quantity: -p.quantity },
                      $set: { updated_at: now },
                      $push: { history: { request_id: req._id,
                                          mechanic_id: new ObjectId(mechanic.id),
                                          delta: -p.quantity, timestamp: now } } },
                    { upsert: true }
                );
            }
            return res.status(200).json({ data: { type: "success",
                message: "Work completed" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Mechanic: POST /mechanics/requests/:id/escalate
     * Body: { escalate_reason, needs_parts: [{part, quantity}] }
     */
    escalate: async function(res, requestId, body, mechanic, path) {
        if (!ObjectId.isValid(requestId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid request_id" }});
        }
        const reason = sanitize(body.escalate_reason);
        const needsParts = body.needs_parts || [];
        if (!reason) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "escalate_reason required" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("maintenance_requests");
            const req = await col.findOne({ _id: new ObjectId(requestId),
                mechanic_id: new ObjectId(mechanic.id) });
            if (!req) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Not found" }});
            }
            await col.updateOne({ _id: req._id }, {
                $set: { status: 'escalated', escalate_reason: reason,
                        needed_parts: needsParts,
                        escalated_at: new Date(), updated_at: new Date() }
            });
            return res.status(200).json({ data: { type: "success",
                message: "Escalated. Admin will review needed parts." }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: GET /mechanics/requests — list all maintenance requests
     */
    listRequests: async function(res, query, path) {
        const limit = Math.min(parseInt(query.limit || '50'), 200);
        const offset = Math.max(parseInt(query.offset || '0'), 0);
        const filter = {};
        if (query.status) filter.status = sanitize(query.status);
        if (query.scooter_id && ObjectId.isValid(query.scooter_id))
            filter.scooter_id = new ObjectId(sanitize(query.scooter_id));

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("maintenance_requests");
            const items = await col.find(filter).sort({ created_at: -1 })
                .skip(offset).limit(limit).toArray();
            const total = await col.countDocuments(filter);
            return res.status(200).json({ data: { requests: items, total, limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: POST /mechanics/requests — create maintenance request manually
     * Body: { scooter_id, reason, priority }
     */
    createRequest: async function(res, body, path) {
        const scooterId = sanitize(body.scooter_id);
        const reason = sanitize(body.reason);
        const priority = sanitize(body.priority) || 'normal';
        if (!scooterId || !ObjectId.isValid(scooterId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid scooter_id" }});
        }
        if (!reason) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "reason required" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("maintenance_requests");
            const result = await col.insertOne({
                scooter_id: new ObjectId(scooterId),
                reason,
                priority,
                status: 'open',
                created_by_admin: true,
                created_at: new Date(),
                assigned_at: null,
                mechanic_id: null,
                work_started_at: null,
                completed_at: null,
                resolution_note: null,
                parts_used: [],
                needed_parts: [],
                completion_photo_url: null,
                updated_at: new Date(),
            });
            // Mark scooter as needing maintenance
            await db.collection("scooters").updateOne(
                { _id: new ObjectId(scooterId) },
                { $set: { status: 'maintenance', updated_at: new Date() } });
            return res.status(201).json({ data: { type: "success",
                request_id: result.insertedId }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: GET /mechanics/inventory — parts inventory
     */
    getInventory: async function(res, path) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const items = await db.collection("parts_inventory").find({}).toArray();
            return res.status(200).json({ data: { inventory: items,
                parts_catalog: PARTS_CATALOG }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: POST /mechanics/inventory/restock
     * Body: { part, quantity, note }
     */
    restock: async function(res, body, path) {
        const part = sanitize(body.part);
        const quantity = parseInt(sanitize(body.quantity));
        const note = sanitize(body.note) || 'restock';
        if (!PARTS_CATALOG.includes(part)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid part" }});
        }
        if (!quantity || quantity < 1) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid quantity" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            await db.collection("parts_inventory").updateOne(
                { part },
                { $inc: { quantity: quantity },
                  $set: { updated_at: new Date() },
                  $push: { history: { delta: quantity, note, timestamp: new Date() } } },
                { upsert: true }
            );
            return res.status(200).json({ data: { type: "success",
                message: `Restocked ${quantity} of ${part}` }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },
};

module.exports = mechanics;
module.exports.PARTS_CATALOG = PARTS_CATALOG;
