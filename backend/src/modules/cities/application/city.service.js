/**
 * City service — zone CRUD operations
 * Per constitution: admin can manage parking/charging/no-parking zones
 */
const { getDb } = require('../../../shared/db.js');
const { ObjectId } = require('mongodb');
const { NotFoundError, ValidationError } = require('../../../shared/errors.js');

const cityService = {
  /**
   * POST /cities/:id/zones — add zone to city
   */
  addZone: async function(cityId, zoneData) {
    if (!zoneData.type || !zoneData.polygon || zoneData.polygon.length < 3) {
      throw new ValidationError('zone', 'type and polygon (min 3 points) required');
    }
    const validTypes = ['parking', 'bonus_parking', 'no_parking', 'charging'];
    if (!validTypes.includes(zoneData.type)) {
      throw new ValidationError('type', `must be one of: ${validTypes.join(', ')}`);
    }
    const db = await getDb();
    const zone = {
      _id: new ObjectId(),
      type: zoneData.type,
      name: zoneData.name || null,
      coordinates: zoneData.coordinates || null,
      polygon: zoneData.polygon,
      created_at: new Date(),
    };
    const result = await db.collection('cities').findOneAndUpdate(
      { _id: new ObjectId(cityId) },
      { $push: { zones: zone }, $set: { updated_at: new Date() } },
      { returnDocument: 'after' }
    );
    if (!result) throw new NotFoundError('city', cityId);
    return zone;
  },

  /**
   * DELETE /cities/:id/zones/:zoneId — remove zone
   */
  removeZone: async function(cityId, zoneId) {
    if (!ObjectId.isValid(zoneId)) throw new ValidationError('zoneId', 'invalid');
    const db = await getDb();
    const result = await db.collection('cities').findOneAndUpdate(
      { _id: new ObjectId(cityId) },
      { $pull: { zones: { _id: new ObjectId(zoneId) } },
        $set: { updated_at: new Date() } },
      { returnDocument: 'after' }
    );
    if (!result) throw new NotFoundError('city', cityId);
    return result;
  },

  /**
   * PUT /cities/:id/zones/:zoneId — update zone
   */
  updateZone: async function(cityId, zoneId, updates) {
    if (!ObjectId.isValid(zoneId)) throw new ValidationError('zoneId', 'invalid');
    const db = await getDb();
    const city = await db.collection('cities').findOne({ _id: new ObjectId(cityId) });
    if (!city) throw new NotFoundError('city', cityId);
    
    const zones = city.zones || [];
    const zoneIdx = zones.findIndex(z => String(z._id) === zoneId);
    if (zoneIdx < 0) throw new NotFoundError('zone', zoneId);
    
    const updatedZone = { ...zones[zoneIdx], ...updates, _id: zones[zoneIdx]._id };
    zones[zoneIdx] = updatedZone;
    
    await db.collection('cities').updateOne(
      { _id: city._id },
      { $set: { zones: zones, updated_at: new Date() } }
    );
    return updatedZone;
  },

  /**
   * PUT /cities/:id/rates — update city tariff rates
   */
  updateRates: async function(cityId, rates) {
    const allowed = ['fixedRate', 'timeRate', 'parkingZoneRate', 'bonusParkingZoneRate',
                     'noParkingZoneRate', 'noParkingToValidParking', 'chargingZoneRate'];
    const clean = {};
    for (const k of allowed) {
      if (rates[k] !== undefined) clean[k] = parseFloat(rates[k]);
    }
    clean.updated_at = new Date();
    const db = await getDb();
    const result = await db.collection('cities').findOneAndUpdate(
      { _id: new ObjectId(cityId) },
      { $set: clean },
      { returnDocument: 'after' }
    );
    if (!result) throw new NotFoundError('city', cityId);
    return result;
  },
};

module.exports = cityService;
