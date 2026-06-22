/**
 * Trips API controller — thin layer, no business logic
 *
 * Per constitution §12 API layer:
 *   - validate request
 *   - parse params
 *   - call use case
 *   - format response
 */

const tripService = require('../application/trip.service.js');
const tripDto = require('../contracts/trip.dto.js');
const { parsePagination, itemResponse, listResponse } = require('../../../shared/http.js');
const { validate, isObjectId, isNonEmptyString } = require('../../../shared/validation.js');
const { AppError, ValidationError, toErrorResponse } = require('../../../shared/errors.js');
const logger = require('../../../shared/logger.js');

/**
 * POST /v1/trips:reserve
 */
async function reserve(req, res) {
    try {
        const input = validate(req.body, {
            scooter_id: { type: 'objectId', required: true },
        });
        const result = await tripService.reserveScooter({
            user: req.user, scooter_id: input.scooter_id,
        });
        return res.status(201).json(itemResponse(result, req.requestId));
    } catch (e) {
        return handleErr(res, e, req);
    }
}

/**
 * POST /v1/trips:start
 */
async function start(req, res) {
    try {
        const input = validate(req.body, {
            trip_id: { type: 'objectId', required: true },
        });
        const result = await tripService.startTrip({ user: req.user, trip_id: input.trip_id });
        return res.status(200).json(itemResponse(result, req.requestId));
    } catch (e) {
        return handleErr(res, e, req);
    }
}

/**
 * POST /v1/trips:end
 */
async function end(req, res) {
    try {
        const input = validate(req.body, {
            trip_id: { type: 'objectId', required: true },
            end_coordinates: { type: 'object', required: false },
            photo_url: { type: 'string', required: false, max: 500 },
        });
        const result = await tripService.endTrip({
            user: req.user,
            trip_id: input.trip_id,
            end_coordinates: input.end_coordinates,
            photo_url: input.photo_url,
        });
        return res.status(200).json(itemResponse(result, req.requestId));
    } catch (e) {
        return handleErr(res, e, req);
    }
}

/**
 * POST /v1/trips:cancel
 */
async function cancel(req, res) {
    try {
        const input = validate(req.body, {
            trip_id: { type: 'objectId', required: true },
            reason: { type: 'nonEmptyString', required: false, max: 200 },
        });
        const result = await tripService.cancelTrip({
            user: req.user, trip_id: input.trip_id, reason: input.reason || 'user_cancelled',
        });
        return res.status(200).json(itemResponse({
            message: result.was_active ? 'Trip cancelled (fee may apply)' : 'Reservation cancelled',
            ...result,
        }, req.requestId));
    } catch (e) {
        return handleErr(res, e, req);
    }
}

/**
 * GET /v1/trips/active
 */
async function getActive(req, res) {
    try {
        const trip = await tripService.getActiveTrip({ user: req.user });
        return res.status(200).json(itemResponse({ trip: tripDto.toDetail(trip) }, req.requestId));
    } catch (e) {
        return handleErr(res, e, req);
    }
}

/**
 * GET /v1/trips/history
 */
async function getHistory(req, res) {
    try {
        const { limit, offset, sort } = parsePagination(req.query, { defaultLimit: 20, defaultSort: { created_at: -1 } });
        const { items, total } = await tripService.getTripHistory({
            user: req.user, limit, offset, sort,
        });
        const data = listResponse(items.map(tripDto.toListItem), {
            requestId: req.requestId, limit, offset, total,
        });
        return res.status(200).json(data);
    } catch (e) {
        return handleErr(res, e, req);
    }
}

/**
 * GET /v1/trips (admin)
 */
async function listAll(req, res) {
    try {
        const { limit, offset, sort } = parsePagination(req.query, { defaultLimit: 50, defaultSort: { created_at: -1 } });
        const filters = {};
        if (req.query.status) filters.status = req.query.status;
        if (req.query.user_id) filters.user_id = req.query.user_id;
        if (req.query.scooter_id) filters.scooter_id = req.query.scooter_id;
        if (req.query.from) filters.from = req.query.from;
        if (req.query.to) filters.to = req.query.to;
        const { items, total } = await tripService.listAllTrips({
            admin: req.user, limit, offset, sort, filters,
        });
        const data = listResponse(items.map(tripDto.toListItem), {
            requestId: req.requestId, limit, offset, total,
        });
        return res.status(200).json(data);
    } catch (e) {
        return handleErr(res, e, req);
    }
}

/**
 * POST /v1/trips:refund (admin)
 */
async function refund(req, res) {
    try {
        const input = validate(req.body, {
            trip_id: { type: 'objectId', required: true },
            amount: { type: 'float', required: true, min: 0.01 },
            reason: { type: 'nonEmptyString', required: false, max: 200 },
        });
        const result = await tripService.refundTrip({
            admin: req.user, trip_id: input.trip_id,
            amount: input.amount, reason: input.reason || 'admin_refund',
        });
        return res.status(200).json(itemResponse(result, req.requestId));
    } catch (e) {
        return handleErr(res, e, req);
    }
}

/**
 * Centralized error handler for this controller
 */
function handleErr(res, err, req) {
    if (err instanceof AppError) {
        return res.status(err.statusCode).json(toErrorResponse(err, req.requestId));
    }
    logger.error('Unhandled trip error', { error: err.message, stack: err.stack, requestId: req.requestId });
    return res.status(500).json(toErrorResponse(err, req.requestId));
}

module.exports = { reserve, start, end, cancel, getActive, getHistory, listAll, refund };
