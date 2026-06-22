/**
 * search.service.js — Full-text search across entities
 *
 * Per Backend Design System §30: OLTP DB can do simple search,
 * complex search → Elasticsearch. This is the simple version.
 */
const { getDb } = require('../../shared/db.js');
const { ObjectId } = require('mongodb');

const searchService = {
  /**
   * GET /v1/search?q=term&limit=20
   * Searches across: users (email, phone, name), scooters (name, serial, mac), trips
   */
  search: async function(res, query, admin, path) {
    const q = (query.q || '').trim();
    if (q.length < 2) {
      return res.status(400).json({ errors: { status: 400, detail: 'Query must be at least 2 characters' }});
    }
    const limit = Math.min(parseInt(query.limit) || 20, 50);
    const db = await getDb();

    // Build regex (case-insensitive)
    const regex = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');

    // Search users
    const users = await db.collection('users').find({
      $or: [
        { email: regex },
        { phoneNumber: regex },
        { firstName: regex },
        { lastName: regex },
      ],
    }).limit(limit).toArray();

    // Search scooters
    const scooters = await db.collection('scooters').find({
      $or: [
        { name: regex },
        { serial_number: regex },
        { mac_address: regex },
        { model: regex },
      ],
    }).limit(limit).toArray();

    // Search trips (by ID if valid ObjectId)
    let trips = [];
    if (ObjectId.isValid(q)) {
      trips = await db.collection('trips').find({ _id: new ObjectId(q) }).limit(5).toArray();
    }

    // Search support tickets
    const tickets = await db.collection('support_tickets').find({
      $or: [{ subject: regex }, { message: regex }],
    }).limit(limit).toArray();

    // Search promocodes
    const promocodes = await db.collection('promocodes').find({
      code: regex,
    }).limit(limit).toArray();

    return res.status(200).json({ data: {
      query: q,
      results: {
        users: users.map(u => ({ id: String(u._id), type: 'user', title: `${u.firstName} ${u.lastName}`.trim(), subtitle: u.email || u.phoneNumber })),
        scooters: scooters.map(s => ({ id: String(s._id), type: 'scooter', title: s.name || 'Unknown', subtitle: `${s.model} • ${s.status}` })),
        trips: trips.map(t => ({ id: String(t._id), type: 'trip', title: `Trip ${String(t._id).slice(-6)}`, subtitle: t.status })),
        tickets: tickets.map(t => ({ id: String(t._id), type: 'ticket', title: t.subject, subtitle: t.status })),
        promocodes: promocodes.map(p => ({ id: String(p._id), type: 'promo', title: p.code, subtitle: p.type })),
      },
      total: users.length + scooters.length + trips.length + tickets.length + promocodes.length,
    }});
  },
};

module.exports = searchService;
