/**
 * Fare estimator — calculates estimated cost before trip starts
 * GET /v1/trips/estimate?city_id=...&duration_min=...&end_zone_type=...
 */
const { getDb } = require('../../../shared/db.js');
const { ObjectId } = require('mongodb');
const { Trip } = require('../domain/trip.entity.js');

const fareEstimator = {
  estimate: async function(res, query, path) {
    const cityId = query.city_id;
    const durationMin = parseInt(query.duration_min) || 10;
    const endZoneType = query.end_zone_type || 'parking';

    if (!cityId || !ObjectId.isValid(cityId)) {
      return res.status(400).json({ errors: { status: 400, detail: 'Valid city_id required' }});
    }

    const db = await getDb();
    const city = await db.collection('cities').findOne({ _id: new ObjectId(cityId) });
    if (!city) {
      return res.status(404).json({ errors: { status: 404, detail: 'City not found' }});
    }

    const cost = Trip.calculateCost({ durationMin, city, endZoneType });

    // Show different zone scenarios
    const scenarios = {};
    for (const zone of ['parking', 'bonus_parking', 'no_parking', 'street']) {
      scenarios[zone] = Trip.calculateCost({ durationMin, city, endZoneType: zone });
    }

    return res.status(200).json({ data: {
      city: { id: String(city._id), name: city.name },
      duration_min: durationMin,
      estimated: cost,
      scenarios: Object.fromEntries(
        Object.entries(scenarios).map(([k, v]) => [k, { total: v.total, base: v.base, time: v.time, discount: v.discount, fee: v.fee }])
      ),
      city_rates: {
        fixedRate: city.fixedRate,
        timeRate: city.timeRate,
        parkingZoneRate: city.parkingZoneRate,
        bonusParkingZoneRate: city.bonusParkingZoneRate,
        noParkingZoneRate: city.noParkingZoneRate,
      },
    }});
  },
};

module.exports = fareEstimator;
