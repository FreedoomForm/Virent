/**
 * Trip DTOs (Data Transfer Objects)
 *
 * Per constitution §9: DTO levels — Summary, ListItem, Detail, AdminDetail
 * Per constitution §15: DB row != API DTO
 */

/**
 * TripListItem — minimal info for list views (history, admin list)
 */
function toListItem(trip) {
    return {
        id: String(trip._id || trip.id),
        status: trip.status,
        start_time: trip.start_time,
        end_time: trip.end_time,
        duration_min: trip.duration_min || 0,
        cost: trip.cost || 0,
        end_zone_type: trip.end_zone_type || null,
        scooter_id: String(trip.scooter_id),
        user_id: String(trip.user_id),
    };
}

/**
 * TripDetail — full info for detail view (user's own trip detail)
 */
function toDetail(trip) {
    return {
        id: String(trip._id || trip.id),
        user_id: String(trip.user_id),
        scooter_id: String(trip.scooter_id),
        city_id: String(trip.city_id),
        status: trip.status,
        start_time: trip.start_time,
        end_time: trip.end_time,
        reservation_time: trip.reservation_time,
        reservation_expires: trip.reservation_expires,
        start_coordinates: trip.start_coordinates,
        end_coordinates: trip.end_coordinates,
        start_battery: trip.start_battery,
        end_battery: trip.end_battery,
        distance_km: trip.distance_km || 0,
        duration_min: trip.duration_min || 0,
        cost: trip.cost || 0,
        cost_breakdown: trip.cost_breakdown || {},
        photo_url: trip.photo_url,
        end_zone_type: trip.end_zone_type,
        refund_amount: trip.refund_amount || 0,
        refund_reason: trip.refund_reason,
        created_at: trip.created_at,
        updated_at: trip.updated_at,
    };
}

/**
 * TripAdminDetail — extended info for admin (includes user info, scooter info)
 */
function toAdminDetail(trip, user, scooter) {
    const base = toDetail(trip);
    return {
        ...base,
        user: user ? {
            id: String(user._id),
            email: user.email,
            phone: user.phoneNumber,
            first_name: user.firstName,
            last_name: user.lastName,
        } : null,
        scooter: scooter ? {
            id: String(scooter._id),
            name: scooter.name,
            model: scooter.model,
            status: scooter.status,
        } : null,
    };
}

/**
 * TripSummary — minimal for embedding in other DTOs
 */
function toSummary(trip) {
    return {
        id: String(trip._id || trip.id),
        status: trip.status,
        cost: trip.cost || 0,
        start_time: trip.start_time,
    };
}

module.exports = { toListItem, toDetail, toAdminDetail, toSummary };
