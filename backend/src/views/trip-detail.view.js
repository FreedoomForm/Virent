/**
 * Trip detail view — aggregates all data needed for trip detail page
 *
 * GET /v1/views/trip-detail/:tripId?sections=main,scooter,user,city
 *
 * Request tree:
 *   trip-detail
 *   ├── main [B0]
 *   │   └── trip (full detail)
 *   ├── user [B1, depends on trip.user_id]
 *   │   └── user summary
 *   ├── scooter [B1, depends on trip.scooter_id]
 *   │   └── scooter summary
 *   └── city [B2, depends on trip.city_id]
 *       └── city summary
 */
const { executeTree } = require('./executor.js');
const { getDb } = require('../shared/db.js');
const { ObjectId } = require('mongodb');
const tripRepo = require('../modules/trips/infrastructure/trip.repository.js');
const scooterRepo = require('../modules/scooters/infrastructure/scooter.repository.js');
const userRepo = require('../modules/users/infrastructure/user.repository.js');
const cityRepo = require('../modules/cities/infrastructure/city.repository.js');
const tripDto = require('../modules/trips/contracts/trip.dto.js');

const tripDetailView = {
    sections: {
        main: {
            required: true,
            cacheTtlSec: 30,
            cacheNamespace: 'trip_detail',
            cacheContextKeys: ['tripId'],
            nodes: [
                {
                    id: 'trip',
                    useCase: async (ctx) => {
                        const trip = await tripRepo.findById(ctx.tripId);
                        if (!trip) throw new Error('TRIP_NOT_FOUND');
                        return tripDto.toDetail(trip);
                    },
                    cache: { ttlSec: 30, contextKeys: ['tripId'] },
                },
            ],
        },
        user: {
            required: false,
            cacheTtlSec: 60,
            cacheNamespace: 'trip_detail_user',
            cacheContextKeys: ['tripId'],
            nodes: [
                {
                    id: 'user_summary',
                    dependsOn: ['trip'],
                    useCase: async (ctx) => {
                        const userId = ctx.deps.trip.user_id;
                        if (!userId) return null;
                        const user = await userRepo.findById(userId);
                        if (!user) return null;
                        return {
                            id: String(user._id),
                            email: user.email,
                            phone: user.phoneNumber,
                            first_name: user.firstName,
                            last_name: user.lastName,
                        };
                    },
                    cache: { ttlSec: 60, contextKeys: ['tripId'] },
                },
            ],
        },
        scooter: {
            required: false,
            cacheTtlSec: 60,
            cacheNamespace: 'trip_detail_scooter',
            cacheContextKeys: ['tripId'],
            nodes: [
                {
                    id: 'scooter_summary',
                    dependsOn: ['trip'],
                    useCase: async (ctx) => {
                        const scooterId = ctx.deps.trip.scooter_id;
                        if (!scooterId) return null;
                        const scooter = await scooterRepo.findByIdWithProjection(scooterId,
                            { name: 1, model: 1, status: 1, battery: 1, mac_address: 1, serial_number: 1 });
                        if (!scooter) return null;
                        return {
                            id: String(scooter._id),
                            name: scooter.name,
                            model: scooter.model,
                            status: scooter.status,
                            battery: scooter.battery,
                            mac_address: scooter.mac_address,
                            serial_number: scooter.serial_number,
                        };
                    },
                    cache: { ttlSec: 60, contextKeys: ['tripId'] },
                },
            ],
        },
        city: {
            required: false,
            cacheTtlSec: 300,
            cacheNamespace: 'trip_detail_city',
            cacheContextKeys: ['tripId'],
            nodes: [
                {
                    id: 'city_summary',
                    dependsOn: ['trip'],
                    useCase: async (ctx) => {
                        const cityId = ctx.deps.trip.city_id;
                        if (!cityId) return null;
                        const city = await cityRepo.findById(cityId);
                        if (!city) return null;
                        return {
                            id: String(city._id),
                            name: city.name,
                            fixed_rate: city.fixedRate,
                            time_rate: city.timeRate,
                        };
                    },
                    cache: { ttlSec: 300, contextKeys: ['tripId'] },
                },
            ],
        },
    },
};

async function getTripDetail(req, res) {
    try {
        const tripId = req.params.tripId;
        if (!ObjectId.isValid(tripId)) {
            return res.status(400).json({
                error: { code: 'VALIDATION_FAILED', message: 'Invalid trip_id', requestId: req.requestId },
            });
        }
        const requestedSections = req.query.sections
            ? req.query.sections.split(',').map(s => s.trim())
            : null;
        const result = await executeTree(tripDetailView, requestedSections, {
            requestId: req.requestId,
            tripId,
            user: req.user,
            admin: req.admin,
        });
        return res.status(200).json({
            data: result.data,
            meta: { ...result.meta, requestId: req.requestId },
        });
    } catch (e) {
        const code = e.message === 'TRIP_NOT_FOUND' ? 'TRIP_NOT_FOUND' : 'INTERNAL_ERROR';
        const status = code === 'TRIP_NOT_FOUND' ? 404 : 500;
        return res.status(status).json({
            error: { code, message: e.message, requestId: req.requestId },
        });
    }
}

module.exports = { getTripDetail, tripDetailView };
