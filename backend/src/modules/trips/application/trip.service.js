/**
 * Trip application services (use cases)
 *
 * Per constitution §12: application layer orchestrates use cases,
 * calls repositories + policies, publishes events.
 * Per constitution §6: Request tree orchestration.
 */

const { ObjectId } = require('mongodb');
const tripRepo = require('../infrastructure/trip.repository.js');
const { Trip } = require('../domain/trip.entity.js');
const { NotFoundError, ConflictError, ValidationError, AppError } = require('../../../shared/errors.js');
const { can } = require('../../../shared/permissions.js');
const logger = require('../../../shared/logger.js');

// Other repositories we depend on (loose coupling via late require)
async function getScooterRepo() { return require('../../scooters/infrastructure/scooter.repository.js'); }
async function getCityRepo() { return require('../../cities/infrastructure/city.repository.js'); }
async function getUserRepo() { return require('../../users/infrastructure/user.repository.js'); }
async function getTxnRepo() { return require('../../transactions/infrastructure/transaction.repository.js'); }

const RESERVATION_TTL_MIN = 10;
const MAX_TRIP_HOURS = 8;
const BATTERY_DRAIN_PER_MIN = 0.5;
const MIN_BATTERY_TO_RESERVE = 10;

/**
 * Reserve a scooter for a user
 */
async function reserveScooter({ user, scooter_id }) {
    if (!scooter_id || !ObjectId.isValid(scooter_id)) {
        throw new ValidationError('scooter_id', 'invalid or missing');
    }
    const scooterRepo = await getScooterRepo();
    const scooter = await scooterRepo.findById(scooter_id);
    if (!scooter) throw new NotFoundError('scooter', scooter_id);
    if (scooter.status !== 'available') {
        throw new ConflictError('SCOOTER_NOT_AVAILABLE',
            `Scooter status: ${scooter.status}`, { scooter_id, status: scooter.status });
    }
    if (scooter.battery < MIN_BATTERY_TO_RESERVE) {
        throw new ConflictError('LOW_BATTERY',
            `Battery at ${scooter.battery}%`, { battery: scooter.battery });
    }

    // Check user doesn't already have an active/reserved trip
    const existing = await tripRepo.findActiveByUser(user.id);
    if (existing) {
        throw new ConflictError('ACTIVE_TRIP_EXISTS',
            'User already has an active reservation or trip',
            { existing_trip_id: String(existing.id) });
    }

    const now = new Date();
    const expiresAt = new Date(now.getTime() + RESERVATION_TTL_MIN * 60 * 1000);

    const trip = await tripRepo.create({
        user_id: user.id,
        scooter_id,
        city_id: scooter.owner,
        reservation_expires: expiresAt,
    });

    // Set scooter to reserved
    await scooterRepo.updateStatus(scooter_id, 'reserved', {
        trip: { trip_id: trip.id, user_id: user.id },
    });

    logger.info('Trip reserved', { trip_id: String(trip.id), user_id: user.id, scooter_id });
    return {
        trip_id: String(trip.id),
        expires_at: expiresAt,
        expires_in_seconds: RESERVATION_TTL_MIN * 60,
    };
}

/**
 * Start an active trip from a reservation
 */
async function startTrip({ user, trip_id }) {
    if (!trip_id || !ObjectId.isValid(trip_id)) {
        throw new ValidationError('trip_id', 'invalid or missing');
    }
    const trip = await tripRepo.findById(trip_id);
    if (!trip) throw new NotFoundError('trip', trip_id);
    can(user, 'trip.readOwn', trip);

    if (!trip.isReserved()) {
        throw new ConflictError('TRIP_NOT_ACTIVE',
            `Trip status: ${trip.status}`, { status: trip.status });
    }
    if (trip.isReservationExpired()) {
        await tripRepo.update(trip.id, { status: 'expired' });
        const scooterRepo = await getScooterRepo();
        await scooterRepo.updateStatus(trip.scooter_id, 'available', { trip: {} });
        throw new AppError('RESERVATION_EXPIRED', 'Reservation expired', { statusCode: 410 });
    }

    const scooterRepo = await getScooterRepo();
    const scooter = await scooterRepo.findById(trip.scooter_id);
    if (!scooter || scooter.status !== 'reserved') {
        throw new ConflictError('SCOOTER_NOT_AVAILABLE',
            'Scooter is no longer reserved for you');
    }

    const now = new Date();
    const updated = await tripRepo.update(trip.id, {
        status: 'active',
        start_time: now,
        start_coordinates: scooter.coordinates,
        start_battery: scooter.battery,
    });
    await scooterRepo.updateStatus(trip.scooter_id, 'in_use');

    logger.info('Trip started', { trip_id: String(trip.id), user_id: user.id });
    return {
        trip_id: String(updated.id),
        start_time: now,
        start_battery: scooter.battery,
        start_coordinates: scooter.coordinates,
    };
}

/**
 * End an active trip with cost calculation
 */
async function endTrip({ user, trip_id, end_coordinates, photo_url }) {
    if (!trip_id || !ObjectId.isValid(trip_id)) {
        throw new ValidationError('trip_id', 'invalid or missing');
    }
    const trip = await tripRepo.findById(trip_id);
    if (!trip) throw new NotFoundError('trip', trip_id);
    can(user, 'trip.endOwn', trip);

    if (!trip.isActive()) {
        throw new ConflictError('TRIP_NOT_ACTIVE', `Trip status: ${trip.status}`);
    }

    const scooterRepo = await getScooterRepo();
    const cityRepo = await getCityRepo();
    const userRepo = await getUserRepo();
    const txnRepo = await getTxnRepo();

    const [scooter, city, userDoc] = await Promise.all([
        scooterRepo.findById(trip.scooter_id),
        cityRepo.findById(trip.city_id),
        userRepo.findById(user.id),
    ]);
    if (!scooter) throw new NotFoundError('scooter', String(trip.scooter_id));
    if (!city) throw new NotFoundError('city', String(trip.city_id));
    if (!userDoc) throw new NotFoundError('user', user.id);

    const now = new Date();
    const durationMin = Math.max(1, Math.ceil((now - new Date(trip.start_time)) / 60000));
    const batteryDrain = Math.min(scooter.battery,
        Math.round(durationMin * BATTERY_DRAIN_PER_MIN * 100) / 100);
    const endBattery = Math.round((scooter.battery - batteryDrain) * 100) / 100;

    // Determine end zone
    const endCoords = end_coordinates || scooter.coordinates;
    const zoneResult = cityRepo.findZoneForPoint(city, endCoords);
    const endZoneType = zoneResult ? zoneResult.type : 'street';

    // Calculate cost (pure domain function)
    const cost = Trip.calculateCost({ durationMin, city, endZoneType });

    // Update user balance
    const newBalance = (userDoc.balance || 0) - cost.total;

    // Create transaction record
    await txnRepo.create({
        user_id: user.id,
        trip_id: trip.id,
        type: 'trip_payment',
        amount: -cost.total,
        balance_after: newBalance,
        method: 'balance',
        provider: 'internal',
        status: 'completed',
        description: `Trip ${trip.id} — ${durationMin} min, zone: ${endZoneType}`,
    });

    // Update trip
    const updatedTrip = await tripRepo.update(trip.id, {
        status: 'ended',
        end_time: now,
        end_coordinates: endCoords,
        end_battery: endBattery,
        end_zone_type: endZoneType,
        duration_min: durationMin,
        cost: cost.total,
        cost_breakdown: cost.breakdown,
        photo_url: photo_url,
    });

    // Update scooter
    const newScooterStatus = endBattery < 20 ? 'charging_needed' : 'available';
    await scooterRepo.updateAfterTripEnd(scooter.id, {
        status: newScooterStatus,
        coordinates: endCoords,
        battery: endBattery,
        trip_log: {
            event: 'trip_ended',
            trip_id: trip.id,
            user_id: new ObjectId(user.id),
            timestamp: now,
            battery_before: scooter.battery,
            battery_after: endBattery,
            duration_min: durationMin,
            cost: cost.total,
            zone: endZoneType,
        },
    });

    // Update user balance + history
    await userRepo.updateAfterTripEnd(user.id, {
        balance: newBalance,
        history_entry: {
            trip_id: trip.id,
            scooter_id: scooter.id,
            start_time: trip.start_time,
            end_time: now,
            duration_min: durationMin,
            cost: cost.total,
            zone: endZoneType,
        },
    });

    logger.info('Trip ended', {
        trip_id: String(trip.id), user_id: user.id, cost: cost.total,
        duration_min: durationMin, zone: endZoneType,
    });

    return {
        trip_id: String(updatedTrip.id),
        duration_min: durationMin,
        cost: cost.total,
        cost_breakdown: { base: cost.base, time: cost.time, discount: cost.discount, fee: cost.fee },
        end_zone: endZoneType,
        end_battery: endBattery,
        new_balance: newBalance,
    };
}

/**
 * Cancel a reservation or active trip
 */
async function cancelTrip({ user, trip_id, reason = 'user_cancelled' }) {
    if (!trip_id || !ObjectId.isValid(trip_id)) {
        throw new ValidationError('trip_id', 'invalid or missing');
    }
    const trip = await tripRepo.findById(trip_id);
    if (!trip) throw new NotFoundError('trip', trip_id);
    can(user, 'trip.cancelOwn', trip);

    if (!['reserved', 'active'].includes(trip.status)) {
        throw new ConflictError('TRIP_NOT_ACTIVE', `Trip status: ${trip.status}`);
    }

    const wasActive = trip.isActive();
    await tripRepo.update(trip.id, {
        status: 'cancelled',
        cancelled_reason: reason,
        cancelled_at: new Date(),
    });
    const scooterRepo = await getScooterRepo();
    await scooterRepo.updateStatus(trip.scooter_id, 'available', { trip: {} });

    logger.info('Trip cancelled', { trip_id: String(trip.id), was_active: wasActive });
    return { trip_id: String(trip.id), was_active: wasActive };
}

/**
 * Get user's active trip
 */
async function getActiveTrip({ user }) {
    const trip = await tripRepo.findActiveByUser(user.id);
    if (!trip) throw new NotFoundError('active_trip');
    return trip;
}

/**
 * Get user's trip history with pagination
 */
async function getTripHistory({ user, limit, offset, sort }) {
    return tripRepo.listByUser(user.id, { limit, offset, sort });
}

/**
 * Admin: list all trips
 */
async function listAllTrips({ admin, limit, offset, sort, filters }) {
    can(admin, 'admin.any');
    return tripRepo.listAll({ limit, offset, sort, filters });
}

/**
 * Admin: refund a trip
 */
async function refundTrip({ admin, trip_id, amount, reason }) {
    can(admin, 'admin.refundTrip');
    if (!trip_id || !ObjectId.isValid(trip_id)) {
        throw new ValidationError('trip_id', 'invalid or missing');
    }
    if (!amount || amount <= 0) throw new ValidationError('amount', 'must be positive');

    const trip = await tripRepo.findById(trip_id);
    if (!trip) throw new NotFoundError('trip', trip_id);

    const refundAmount = Math.min(amount, trip.cost || 0);
    const userRepo = await getUserRepo();
    const txnRepo = await getTxnRepo();
    const userDoc = await userRepo.findById(trip.user_id);
    if (!userDoc) throw new NotFoundError('user', String(trip.user_id));

    const newBalance = (userDoc.balance || 0) + refundAmount;
    await tripRepo.update(trip.id, {
        refund_amount: refundAmount,
        refund_reason: reason,
    });
    await userRepo.updateBalance(userDoc.id, newBalance);
    await txnRepo.create({
        user_id: String(trip.user_id),
        trip_id: String(trip.id),
        type: 'refund',
        amount: refundAmount,
        balance_after: newBalance,
        method: 'balance',
        provider: 'internal',
        status: 'completed',
        description: `Refund for trip ${trip.id}: ${reason}`,
    });

    logger.info('Trip refunded', {
        trip_id: String(trip.id), amount: refundAmount,
        admin_id: admin.id, reason,
    });
    return { trip_id: String(trip.id), refund_amount: refundAmount, new_balance: newBalance };
}

module.exports = {
    reserveScooter,
    startTrip,
    endTrip,
    cancelTrip,
    getActiveTrip,
    getTripHistory,
    listAllTrips,
    refundTrip,
    // Exported for cron
    expireStaleReservations: async () => {
        const stale = await tripRepo.findStaleReservations();
        const scooterRepo = await getScooterRepo();
        for (const tripDoc of stale) {
            await tripRepo.update(tripDoc._id, { status: 'expired' });
            await scooterRepo.updateStatus(tripDoc.scooter_id, 'available', { trip: {} });
        }
        logger.info('Expired stale reservations', { count: stale.length });
        return stale.length;
    },
    flagLongTrips: async () => {
        const long = await tripRepo.findLongActive(MAX_TRIP_HOURS);
        for (const tripDoc of long) {
            await tripRepo.update(tripDoc._id, { auto_end_flagged: true });
        }
        logger.info('Flagged long trips', { count: long.length });
        return long.length;
    },
};
