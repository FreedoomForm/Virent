/**
 * City repository — infrastructure layer
 */
const { getDb } = require('../../../shared/db.js');
const { ObjectId } = require('mongodb');
const classifyPoint = require('robust-point-in-polygon');

const COLLECTION = 'cities';

class CityRepository {
    async findById(id) {
        const db = await getDb();
        if (!ObjectId.isValid(id)) return null;
        return db.collection(COLLECTION).findOne({ _id: new ObjectId(id) });
    }

    async listAll() {
        const db = await getDb();
        return db.collection(COLLECTION).find({}).toArray();
    }

    async count() {
        const db = await getDb();
        return db.collection(COLLECTION).countDocuments();
    }

    /**
     * Pure domain operation: find which zone a point falls into.
     * @param city - city document with zones array
     * @param coordinates - { longitude, latitude }
     */
    findZoneForPoint(city, coordinates) {
        if (!city || !city.zones || !city.zones.length || !coordinates) return null;
        const lng = parseFloat(coordinates.longitude);
        const lat = parseFloat(coordinates.latitude);
        if (isNaN(lng) || isNaN(lat)) return null;
        for (const zone of city.zones) {
            if (!zone.polygon || zone.polygon.length < 3) continue;
            const poly = zone.polygon.map(p => [parseFloat(p.longitude), parseFloat(p.latitude)]);
            if (classifyPoint(poly, [lng, lat]) === -1) return zone;
        }
        return null;
    }

    /**
     * Find city for a point across all cities
     */
    async locatePoint(coordinates) {
        const cities = await this.listAll();
        for (const city of cities) {
            const zone = this.findZoneForPoint(city, coordinates);
            if (zone) return { city, zone };
        }
        return null;
    }
}

module.exports = new CityRepository();
