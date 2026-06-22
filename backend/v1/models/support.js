/**
 * support.js — support tickets & breakdown reports
 *
 * Ticket types:
 *   - breakdown      — scooter malfunction report
 *   - billing        — payment/billing issue
 *   - account        — account access issue
 *   - other          — general question
 *
 * Ticket status: open → in_progress → resolved → closed
 *
 * For breakdown tickets, includes: scooter_id, problem_category, photo_url
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const mongoURI = process.env.DBURI;

const PROBLEM_CATEGORIES = [
    'wheel', 'brake', 'battery', 'lock', 'display',
    'throttle', 'frame', 'lighting', 'other'
];

const support = {
    /**
     * User: POST /support — create ticket
     */
    create: async function(res, body, user, path) {
        const type = sanitize(body.type);
        const subject = sanitize(body.subject);
        const message = sanitize(body.message);
        const scooterId = sanitize(body.scooter_id);
        const problemCategory = sanitize(body.problem_category);
        const photoUrl = sanitize(body.photo_url);
        const tripId = sanitize(body.trip_id);

        if (!['breakdown','billing','account','other'].includes(type)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid type" }});
        }
        if (!subject || !message) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "subject and message required" }});
        }
        if (type === 'breakdown') {
            if (!scooterId) {
                return res.status(400).json({ errors: { status: 400, source: path,
                    title: "scooter_id required for breakdown tickets" }});
            }
            if (!PROBLEM_CATEGORIES.includes(problemCategory)) {
                return res.status(400).json({ errors: { status: 400, source: path,
                    title: `problem_category must be one of: ${PROBLEM_CATEGORIES.join(', ')}` }});
            }
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("support_tickets");
            const ticket = {
                user_id: new ObjectId(user.id),
                type,
                subject,
                status: 'open',
                priority: type === 'breakdown' ? 'high' : 'normal',
                messages: [{
                    from: 'user',
                    user_id: new ObjectId(user.id),
                    message,
                    created_at: new Date(),
                }],
                scooter_id: scooterId ? new ObjectId(scooterId) : null,
                trip_id: tripId ? new ObjectId(tripId) : null,
                problem_category: type === 'breakdown' ? problemCategory : null,
                photo_url: photoUrl || null,
                assigned_to: null, // admin user_id
                resolved_at: null,
                resolution_note: null,
                created_at: new Date(),
                updated_at: new Date(),
            };
            const result = await col.insertOne(ticket);

            // If breakdown, mark scooter for maintenance
            if (type === 'breakdown' && scooterId) {
                await db.collection("scooters").updateOne(
                    { _id: new ObjectId(scooterId) },
                    { $set: { status: 'maintenance', maintenance_reason: `Ticket ${result.insertedId}`,
                              updated_at: new Date() },
                      $push: { log: { event: 'breakdown_reported',
                                       ticket_id: result.insertedId,
                                       user_id: new ObjectId(user.id),
                                       category: problemCategory,
                                       timestamp: new Date() } } });
            }

            return res.status(201).json({ data: { type: "success",
                message: "Ticket created",
                ticket_id: result.insertedId, status: 'open' }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * User: GET /support — list my tickets
     */
    listMine: async function(res, query, user, path) {
        const limit = Math.min(parseInt(query.limit || '20'), 100);
        const offset = Math.max(parseInt(query.offset || '0'), 0);
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("support_tickets");
            const items = await col.find({ user_id: new ObjectId(user.id) })
                .sort({ created_at: -1 }).skip(offset).limit(limit).toArray();
            const total = await col.countDocuments({ user_id: new ObjectId(user.id) });
            return res.status(200).json({ data: { tickets: items, total, limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * User: GET /support/:id — get ticket detail
     */
    getMine: async function(res, ticketId, user, path) {
        if (!ObjectId.isValid(ticketId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid ticket_id" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const ticket = await db.collection("support_tickets").findOne({
                _id: new ObjectId(ticketId),
                user_id: new ObjectId(user.id),
            });
            if (!ticket) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Ticket not found" }});
            }
            return res.status(200).json({ data: { ticket }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * User: POST /support/:id/message — add message to ticket
     */
    addMessage: async function(res, ticketId, body, user, path) {
        const message = sanitize(body.message);
        if (!message) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "message required" }});
        }
        if (!ObjectId.isValid(ticketId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid ticket_id" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("support_tickets");
            const ticket = await col.findOne({
                _id: new ObjectId(ticketId),
                user_id: new ObjectId(user.id),
            });
            if (!ticket) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Ticket not found" }});
            }
            if (ticket.status === 'closed') {
                return res.status(400).json({ errors: { status: 400, source: path,
                    title: "Ticket is closed" }});
            }
            await col.updateOne({ _id: ticket._id }, {
                $push: { messages: {
                    from: 'user',
                    user_id: new ObjectId(user.id),
                    message,
                    created_at: new Date(),
                } },
                $set: { updated_at: new Date(),
                        status: ticket.status === 'resolved' ? 'in_progress' : ticket.status }
            });
            return res.status(200).json({ data: { type: "success",
                message: "Message added" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: GET /support/admin — list all tickets
     */
    listAll: async function(res, query, path) {
        const limit = Math.min(parseInt(query.limit || '50'), 200);
        const offset = Math.max(parseInt(query.offset || '0'), 0);
        const filter = {};
        if (query.status) filter.status = sanitize(query.status);
        if (query.type) filter.type = sanitize(query.type);
        if (query.priority) filter.priority = sanitize(query.priority);

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("support_tickets");
            const items = await col.find(filter).sort({ created_at: -1 })
                .skip(offset).limit(limit).toArray();
            const total = await col.countDocuments(filter);
            return res.status(200).json({ data: { tickets: items, total, limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: POST /support/admin/:id/reply — reply to ticket
     */
    adminReply: async function(res, ticketId, body, admin, path) {
        const message = sanitize(body.message);
        const newStatus = sanitize(body.status); // optional: in_progress/resolved/closed
        const resolutionNote = sanitize(body.resolution_note);

        if (!message && !newStatus) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "message or status required" }});
        }
        if (!ObjectId.isValid(ticketId)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid ticket_id" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("support_tickets");
            const update = {
                $set: { assigned_to: new ObjectId(admin.user_id || admin.id),
                        updated_at: new Date() },
            };
            if (message) {
                update.$push = { messages: {
                    from: 'admin',
                    admin_id: new ObjectId(admin.user_id || admin.id),
                    message,
                    created_at: new Date(),
                }};
            }
            if (newStatus) {
                update.$set.status = newStatus;
                if (newStatus === 'resolved') update.$set.resolved_at = new Date();
                if (newStatus === 'resolved' && resolutionNote) {
                    update.$set.resolution_note = resolutionNote;
                }
            }
            const result = await col.updateOne({ _id: new ObjectId(ticketId) }, update);
            if (result.matchedCount === 0) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Ticket not found" }});
            }
            return res.status(200).json({ data: { type: "success",
                message: "Reply added" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },
};

module.exports = support;
module.exports.PROBLEM_CATEGORIES = PROBLEM_CATEGORIES;
