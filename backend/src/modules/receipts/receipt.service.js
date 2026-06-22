/**
 * Receipt service — generates trip receipt as JSON (PDF-ready)
 * Per constitution: business needs receipts for tax/legal purposes
 */
const { getDb } = require('../../shared/db.js');
const { ObjectId } = require('mongodb');

const receiptService = {
  /**
   * GET /v1/receipts/:tripId — get receipt data for a trip
   */
  getReceipt: async function(res, tripId, user, path) {
    if (!ObjectId.isValid(tripId)) {
      return res.status(400).json({ errors: { status: 400, detail: 'Invalid trip ID' }});
    }
    const db = await getDb();
    const trip = await db.collection('trips').findOne({ _id: new ObjectId(tripId) });
    if (!trip) return res.status(404).json({ errors: { status: 404, detail: 'Trip not found' }});

    // Check ownership
    if (String(trip.user_id) !== String(user.id) && user.role !== 'admin') {
      return res.status(403).json({ errors: { status: 403, detail: 'Not your trip' }});
    }

    // Get scooter + city info
    const [scooter, city, userDoc, txn] = await Promise.all([
      db.collection('scooters').findOne({ _id: trip.scooter_id }),
      db.collection('cities').findOne({ _id: trip.city_id }),
      db.collection('users').findOne({ _id: trip.user_id }),
      db.collection('transactions').findOne({ trip_id: trip._id, type: 'trip_payment' }),
    ]);

    const receipt = {
      receipt_number: `VIR-${String(trip._id).slice(-8).toUpperCase()}`,
      receipt_date: trip.end_time || new Date(),
      company: {
        name: 'Virent LLC',
        address: 'Tashkent, Uzbekistan',
        tax_id: '', // INN
      },
      customer: {
        name: userDoc ? `${userDoc.firstName} ${userDoc.lastName}`.trim() : 'Unknown',
        phone: userDoc?.phoneNumber || '',
        email: userDoc?.email || '',
      },
      trip: {
        id: String(trip._id),
        start_time: trip.start_time,
        end_time: trip.end_time,
        duration_min: trip.duration_min,
        distance_km: trip.distance_km,
        start_battery: trip.start_battery,
        end_battery: trip.end_battery,
        end_zone: trip.end_zone_type,
      },
      scooter: {
        name: scooter?.name || 'Unknown',
        model: scooter?.model || 'Unknown',
        serial: scooter?.serial_number || '',
      },
      city: {
        name: city?.name || 'Unknown',
      },
      payment: {
        breakdown: trip.cost_breakdown || {},
        total: trip.cost || 0,
        method: txn?.method || 'balance',
        transaction_id: txn ? String(txn._id) : null,
        refund_amount: trip.refund_amount || 0,
      },
      currency: 'UZS',
    };

    return res.status(200).json({ data: { receipt }});
  },

  /**
   * GET /v1/receipts — list user's receipts
   */
  listReceipts: async function(res, user, query, path) {
    const db = await getDb();
    const limit = Math.min(parseInt(query.limit) || 25, 100);
    const trips = await db.collection('trips').find({
      user_id: new ObjectId(user.id),
      status: 'ended',
    }).sort({ end_time: -1 }).limit(limit).toArray();

    const receipts = trips.map(trip => ({
      receipt_number: `VIR-${String(trip._id).slice(-8).toUpperCase()}`,
      trip_id: String(trip._id),
      date: trip.end_time,
      total: trip.cost,
      duration_min: trip.duration_min,
    }));

    return res.status(200).json({ data: { receipts, count: receipts.length }});
  },
};

module.exports = receiptService;
