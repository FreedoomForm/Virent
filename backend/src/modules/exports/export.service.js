/**
 * export.service.js — CSV export for admin reports
 */
const { getDb } = require('../../shared/db.js');

function toCsv(rows, columns) {
  const header = columns.map(c => `"${c.header}"`).join(',');
  const lines = rows.map(row =>
    columns.map(c => {
      const val = c.get ? c.get(row) : row[c.key];
      if (val == null) return '';
      const str = typeof val === 'object' ? JSON.stringify(val) : String(val);
      return `"${str.replace(/"/g, '""')}"`;
    }).join(',')
  );
  return [header, ...lines].join('\n');
}

const exportService = {
  trips: async (res, query) => {
    const db = await getDb();
    const filter = {};
    if (query.status) filter.status = query.status;
    if (query.from || query.to) {
      filter.created_at = {};
      if (query.from) filter.created_at.$gte = new Date(query.from);
      if (query.to) filter.created_at.$lte = new Date(query.to);
    }
    const trips = await db.collection('trips').find(filter).sort({ created_at: -1 }).limit(10000).toArray();
    const csv = toCsv(trips, [
      { header: 'ID', get: r => String(r._id) },
      { header: 'User ID', get: r => String(r.user_id) },
      { header: 'Scooter ID', get: r => String(r.scooter_id) },
      { header: 'Status', key: 'status' },
      { header: 'Start Time', get: r => r.start_time?.toISOString() || '' },
      { header: 'End Time', get: r => r.end_time?.toISOString() || '' },
      { header: 'Duration (min)', key: 'duration_min' },
      { header: 'Cost (UZS)', key: 'cost' },
      { header: 'End Zone', key: 'end_zone_type' },
    ]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="trips_${Date.now()}.csv"`);
    return res.status(200).send(csv);
  },

  transactions: async (res, query) => {
    const db = await getDb();
    const filter = {};
    if (query.type) filter.type = query.type;
    if (query.from || query.to) { filter.created_at = {}; if (query.from) filter.created_at.$gte = new Date(query.from); if (query.to) filter.created_at.$lte = new Date(query.to); }
    const txns = await db.collection('transactions').find(filter).sort({ created_at: -1 }).limit(10000).toArray();
    const csv = toCsv(txns, [
      { header: 'ID', get: r => String(r._id) },
      { header: 'User ID', get: r => r.user_id ? String(r.user_id) : '' },
      { header: 'Type', key: 'type' },
      { header: 'Amount (UZS)', key: 'amount' },
      { header: 'Method', key: 'method' },
      { header: 'Provider', key: 'provider' },
      { header: 'Status', key: 'status' },
      { header: 'Description', key: 'description' },
      { header: 'Created At', get: r => r.created_at?.toISOString() || '' },
    ]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="transactions_${Date.now()}.csv"`);
    return res.status(200).send(csv);
  },

  users: async (res) => {
    const db = await getDb();
    const users = await db.collection('users').find({}).sort({ created_at: -1 }).limit(10000).toArray();
    const csv = toCsv(users, [
      { header: 'ID', get: r => String(r._id) },
      { header: 'First Name', key: 'firstName' },
      { header: 'Last Name', key: 'lastName' },
      { header: 'Email', key: 'email' },
      { header: 'Phone', key: 'phoneNumber' },
      { header: 'Balance (UZS)', key: 'balance' },
      { header: 'Role', key: 'role' },
      { header: 'Status', key: 'status' },
      { header: 'Created At', get: r => r.created_at?.toISOString() || '' },
    ]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="users_${Date.now()}.csv"`);
    return res.status(200).send(csv);
  },

  scooters: async (res) => {
    const db = await getDb();
    const scooters = await db.collection('scooters').find({}).sort({ created_at: -1 }).limit(10000).toArray();
    const csv = toCsv(scooters, [
      { header: 'ID', get: r => String(r._id) },
      { header: 'Name', key: 'name' },
      { header: 'Model', key: 'model' },
      { header: 'Status', key: 'status' },
      { header: 'Battery (%)', key: 'battery' },
      { header: 'Total Distance (km)', key: 'total_distance_km' },
      { header: 'Total Rides', key: 'total_rides' },
    ]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="scooters_${Date.now()}.csv"`);
    return res.status(200).send(csv);
  },
};

module.exports = exportService;
