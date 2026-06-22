/**
 * Trip domain entity + value objects
 *
 * Per constitution §12 Domain layer:
 *   - business rules only
 *   - no HTTP, no DB, no framework imports
 */

class Coordinates {
    constructor(longitude, latitude) {
        if (typeof longitude === 'string') longitude = parseFloat(longitude);
        if (typeof latitude === 'string') latitude = parseFloat(latitude);
        if (isNaN(longitude) || isNaN(latitude) || longitude < -180 || longitude > 180
            || latitude < -90 || latitude > 90) {
            throw new Error('Invalid coordinates');
        }
        this.longitude = longitude;
        this.latitude = latitude;
    }
    toJSON() { return { longitude: String(this.longitude), latitude: String(this.latitude) }; }
}

const TRIP_STATUSES = ['reserved', 'active', 'ended', 'cancelled', 'expired'];
const TRIP_TRANSITIONS = {
    reserved: ['active', 'cancelled', 'expired'],
    active: ['ended', 'cancelled'],
    ended: [],
    cancelled: [],
    expired: [],
};

class Trip {
    constructor(props) {
        this._id = props._id || props.id;
        this.id = props._id ? String(props._id) : (props.id ? String(props.id) : undefined);
        this.user_id = props.user_id;
        this.scooter_id = props.scooter_id;
        this.city_id = props.city_id;
        this.status = props.status || 'reserved';
        this.start_time = props.start_time || null;
        this.end_time = props.end_time || null;
        this.reservation_time = props.reservation_time;
        this.reservation_expires = props.reservation_expires;
        this.start_coordinates = props.start_coordinates || null;
        this.end_coordinates = props.end_coordinates || null;
        this.start_battery = props.start_battery;
        this.end_battery = props.end_battery;
        this.distance_km = props.distance_km || 0;
        this.duration_min = props.duration_min || 0;
        this.cost = props.cost || 0;
        this.cost_breakdown = props.cost_breakdown || {};
        this.photo_url = props.photo_url || null;
        this.end_zone_type = props.end_zone_type || null;
        this.refund_amount = props.refund_amount || 0;
        this.refund_reason = props.refund_reason || null;
        this.created_at = props.created_at;
        this.updated_at = props.updated_at;
    }

    canTransitionTo(newStatus) {
        return (TRIP_TRANSITIONS[this.status] || []).includes(newStatus);
    }

    isActive() { return this.status === 'active'; }
    isReserved() { return this.status === 'reserved'; }
    isEnded() { return ['ended', 'cancelled', 'expired'].includes(this.status); }

    isReservationExpired(now = new Date()) {
        return this.isReserved() && this.reservation_expires && new Date(this.reservation_expires) < now;
    }

    /**
     * Calculate trip cost based on city rates and zone.
     * Pure function — no DB access, no side effects.
     */
    static calculateCost({ durationMin, city, endZoneType }) {
        const base = city.fixedRate || 0;
        const time = Math.max(1, durationMin) * (city.timeRate || 0);
        let discount = 0;
        let fee = 0;

        if (endZoneType === 'parking') discount += city.parkingZoneRate || 0;
        if (endZoneType === 'bonus_parking') discount += city.bonusParkingZoneRate || 0;
        if (endZoneType === 'no_parking') fee += city.noParkingZoneRate || 0;
        if (endZoneType === 'street') fee += city.noParkingZoneRate || 0;

        const total = Math.max(0, base + time - discount + fee);
        return {
            base, time, discount, fee, total,
            breakdown: {
                base, time, discount, fee,
                city_rates: {
                    fixedRate: city.fixedRate,
                    timeRate: city.timeRate,
                    parkingZoneRate: city.parkingZoneRate,
                    bonusParkingZoneRate: city.bonusParkingZoneRate,
                    noParkingZoneRate: city.noParkingZoneRate,
                },
            },
        };
    }
}

module.exports = { Trip, Coordinates, TRIP_STATUSES, TRIP_TRANSITIONS };
