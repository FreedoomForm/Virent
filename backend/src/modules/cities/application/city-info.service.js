const { getDb } = require('../../../shared/db.js');
const { ObjectId } = require('mongodb');

const cityInfo = {
  list: async function(res) {
    const db = await getDb();
    const cities = await db.collection('cities').find({}).project({
      name: 1, fixedRate: 1, timeRate: 1, parkingZoneRate: 1,
      bonusParkingZoneRate: 1, noParkingZoneRate: 1, zones: 1,
    }).toArray();
    const result = cities.map(c => ({
      id: String(c._id), name: c.name,
      rates: { base: c.fixedRate, per_minute: c.timeRate,
        parking_discount: c.parkingZoneRate, bonus_parking_discount: c.bonusParkingZoneRate,
        no_parking_fee: c.noParkingZoneRate },
      zones_count: c.zones?.length || 0,
    }));
    return res.status(200).json({ data: { cities: result }});
  },
  detail: async function(res, cityId) {
    if (!ObjectId.isValid(cityId)) return res.status(400).json({ errors: { detail: 'Invalid ID' }});
    const db = await getDb();
    const city = await db.collection('cities').findOne({ _id: new ObjectId(cityId) });
    if (!city) return res.status(404).json({ errors: { detail: 'Not found' }});
    return res.status(200).json({ data: { city: {
      id: String(city._id), name: city.name,
      rates: { base: city.fixedRate, per_minute: city.timeRate,
        parking_discount: city.parkingZoneRate, no_parking_fee: city.noParkingZoneRate },
      zones: (city.zones || []).map(z => ({ id: String(z._id), type: z.type, name: z.name })),
    }}});
  },
};
module.exports = cityInfo;
