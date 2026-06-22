/**
 * juicers.js — scooter charging fleet (juicers pick up low-battery scooters
 * at night, charge them at home, return to charging zones in the morning).
 *
 * Workflow:
 *   1. System marks scooters with battery < 20% as 'charging_needed'
 *   2. Juicer sees list of available pickup tasks
 *   3. Juicer claims a pickup task → scooter status → 'picked_up'
 *   4. Juicer charges overnight → marks 'charged'
 *   5. Juicer returns scooter to a charging zone → status → 'available'
 *   6. Juicer gets paid (configurable rate per scooter)
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const mongoURI = process.env.DBURI;

const JUICER_PAY_PER_SCOOTER = 5000; // UZS

const juicers = {
    /**
     * Admin: POST /juicers — register juicer
     * Body: { phone, firstName, lastName, pay_rate? }
     */
    register: async function(res, body, path) {
        const phone = sanitize(body.phone);
        const firstName = sanitize(body.firstName);
        const lastName = sanitize(body.lastName);
        const payRate = parseFloat(sanitize(body.pay_rate)) || JUICER_PAY_PER_SCOOTER;

        if (!phone || !firstName || !lastName) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "phone, firstName, lastName required" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("juicers");
            const existing = await col.findOne({ phone });
            if (existing) {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Juicer with this phone already exists" }});
            }
            const result = await col.insertOne({
                phone, firstName, lastName, pay_rate: payRate,
                status: 'active', // active / suspended
                total_earned: 0,
                total_scooters_charged: 0,
                current_tasks: [],
                created_at: new Date(),
                updated_at: new Date(),
            });
            return res.status(201).json({ data: { type: "success",
                juicer_id: result.insertedId, message: "Juicer registered" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: GET /juicers
     */
    list: async function(res, query, path) {
        const limit = Math.min(parseInt(query.limit || '50'), 200);
        const offset = Math.max(parseInt(query.offset || '0'), 0);
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("juicers");
            const items = await col.find({}).sort({ created_at: -1 })
                .skip(offset).limit(limit).toArray();
            const total = await col.countDocuments({});
            return res.status(200).json({ data: { juicers: items, total, limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Juicer: GET /juicers/tasks/available — see scooters needing charge
     */
    availableTasks: async function(res, juicer, path) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const scootersCol = db.collection("scooters");
            const tasksCol = db.collection("juicer_tasks");
            // Scooters with status 'charging_needed' that don't have an active task
            const alreadyClaimed = await tasksCol.distinct("scooter_id", {
                status: { $in: ['assigned', 'picked_up'] }
            });
            const scooters = await scootersCol.find({
                status: 'charging_needed',
                _id: { $nin: alreadyClaimed.map(id => new ObjectId(id)) }
            }).toArray();
            return res.status(200).json({ data: { available: scooters,
                count: scooters.length }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Juicer: POST /juicers/tasks/claim — claim a pickup task
     * Body: { scooter_id }
     */
    claimTask: async function(res, body, juicer, path) {
        const scooterId = sanitize(body.scooter_id);
        if (!scooterId || !ObjectId.isValid(scooterId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid scooter_id" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const scootersCol = db.collection("scooters");
            const tasksCol = db.collection("juicer_tasks");

            const scooter = await scootersCol.findOne({ _id: new ObjectId(scooterId) });
            if (!scooter) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Scooter not found" }});
            }
            if (scooter.status !== 'charging_needed') {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Scooter not available for pickup" }});
            }
            // Check no active task for this scooter
            const existing = await tasksCol.findOne({
                scooter_id: new ObjectId(scooterId),
                status: { $in: ['assigned', 'picked_up'] }
            });
            if (existing) {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Already claimed by another juicer" }});
            }
            const task = {
                juicer_id: new ObjectId(juicer.id),
                scooter_id: new ObjectId(scooterId),
                status: 'assigned',
                assigned_at: new Date(),
                picked_up_at: null,
                charged_at: null,
                returned_at: null,
                pay_amount: juicer.pay_rate || JUICER_PAY_PER_SCOOTER,
                paid: false,
                pickup_coordinates: scooter.coordinates,
                return_coordinates: null,
                created_at: new Date(),
                updated_at: new Date(),
            };
            const result = await tasksCol.insertOne(task);
            await scootersCol.updateOne({ _id: scooter._id }, {
                $set: { status: 'picked_up', updated_at: new Date() },
                $push: { log: { event: 'juicer_assigned', juicer_id: new ObjectId(juicer.id),
                                task_id: result.insertedId, timestamp: new Date() } }
            });
            return res.status(201).json({ data: { type: "success",
                task_id: result.insertedId, message: "Task claimed" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Juicer: POST /juicers/tasks/:id/pickup — mark picked up
     */
    markPickedUp: async function(res, taskId, juicer, path) {
        if (!ObjectId.isValid(taskId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid task_id" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tasksCol = db.collection("juicer_tasks");
            const task = await tasksCol.findOne({ _id: new ObjectId(taskId),
                juicer_id: new ObjectId(juicer.id) });
            if (!task) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Task not found" }});
            }
            if (task.status !== 'assigned') {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Task not in assigned state" }});
            }
            await tasksCol.updateOne({ _id: task._id }, {
                $set: { status: 'picked_up', picked_up_at: new Date(),
                        updated_at: new Date() }
            });
            return res.status(200).json({ data: { type: "success",
                message: "Marked as picked up" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Juicer: POST /juicers/tasks/:id/charge — mark charged (overnight)
     */
    markCharged: async function(res, taskId, juicer, path) {
        if (!ObjectId.isValid(taskId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid task_id" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tasksCol = db.collection("juicer_tasks");
            const task = await tasksCol.findOne({ _id: new ObjectId(taskId),
                juicer_id: new ObjectId(juicer.id) });
            if (!task) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Task not found" }});
            }
            if (task.status !== 'picked_up') {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Task not in picked_up state" }});
            }
            await tasksCol.updateOne({ _id: task._id }, {
                $set: { status: 'charged', charged_at: new Date(),
                        updated_at: new Date() }
            });
            // Update scooter battery to 100% (charged)
            await db.collection("scooters").updateOne({ _id: task.scooter_id }, {
                $set: { battery: 100, updated_at: new Date() }
            });
            return res.status(200).json({ data: { type: "success",
                message: "Marked as charged (battery = 100%)" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Juicer: POST /juicers/tasks/:id/return — return scooter to charging zone
     * Body: { coordinates }
     */
    markReturned: async function(res, taskId, body, juicer, path) {
        if (!ObjectId.isValid(taskId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid task_id" }});
        }
        const coords = body.coordinates;
        if (!coords || !coords.longitude || !coords.latitude) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "coordinates {longitude, latitude} required" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tasksCol = db.collection("juicer_tasks");
            const scootersCol = db.collection("scooters");
            const juicersCol = db.collection("juicers");
            const txnCol = db.collection("transactions");

            const task = await tasksCol.findOne({ _id: new ObjectId(taskId),
                juicer_id: new ObjectId(juicer.id) });
            if (!task) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Task not found" }});
            }
            if (task.status !== 'charged') {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Task not in charged state" }});
            }
            await tasksCol.updateOne({ _id: task._id }, {
                $set: { status: 'returned', returned_at: new Date(),
                        return_coordinates: coords,
                        paid: true, updated_at: new Date() }
            });
            // Scooter back to available at new location
            await scootersCol.updateOne({ _id: task.scooter_id }, {
                $set: { status: 'available', coordinates: coords,
                        battery: 100, updated_at: new Date() },
                $push: { log: { event: 'juicer_returned', juicer_id: new ObjectId(juicer.id),
                                task_id: task._id, timestamp: new Date(),
                                coordinates: coords } }
            });
            // Pay juicer
            await juicersCol.updateOne({ _id: new ObjectId(juicer.id) }, {
                $inc: { total_earned: task.pay_amount, total_scooters_charged: 1 },
                $set: { updated_at: new Date() }
            });
            // Record transaction (juicer payout liability)
            await txnCol.insertOne({
                juicer_id: new ObjectId(juicer.id),
                scooter_id: task.scooter_id,
                type: 'juicer_payout',
                amount: task.pay_amount,
                method: 'internal',
                provider: 'internal',
                status: 'pending_payout',
                description: `Juicer payout for ${task._id}`,
                created_at: new Date(),
            });
            return res.status(200).json({ data: { type: "success",
                message: "Scooter returned", pay_amount: task.pay_amount }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Juicer: GET /juicers/me/earnings — get earnings summary
     */
    myEarnings: async function(res, juicer, path) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const tasksCol = db.collection("juicer_tasks");
            const total = await tasksCol.countDocuments({
                juicer_id: new ObjectId(juicer.id), status: 'returned' });
            const earned = await tasksCol.aggregate([
                { $match: { juicer_id: new ObjectId(juicer.id), status: 'returned' } },
                { $group: { _id: null, total: { $sum: "$pay_amount" } } }
            ]).toArray();
            const today = await tasksCol.countDocuments({
                juicer_id: new ObjectId(juicer.id), status: 'returned',
                returned_at: { $gte: new Date(new Date().setHours(0,0,0,0)) }
            });
            return res.status(200).json({ data: {
                total_scooters_charged: total,
                total_earned: earned[0]?.total || 0,
                charged_today: today,
                pay_rate: juicer.pay_rate || JUICER_PAY_PER_SCOOTER,
            }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },
};

module.exports = juicers;
module.exports.JUICER_PAY_PER_SCOOTER = JUICER_PAY_PER_SCOOTER;
