/**
 * Scooter domain entity
 */

const SCOOTER_STATUSES = ['available', 'reserved', 'in_use', 'charging_needed',
                          'charging', 'maintenance', 'retired'];

const SCOOTER_TRANSITIONS = {
    available: ['reserved', 'maintenance', 'retired'],
    reserved: ['available', 'in_use'],
    in_use: ['available', 'charging_needed', 'maintenance'],
    charging_needed: ['charging', 'available', 'maintenance'],
    charging: ['available', 'maintenance'],
    maintenance: ['available', 'retired'],
    retired: [],
};

class Scooter {
    constructor(props) {
        this.id = props._id || props.id;
        this.name = props.name;
        this.owner = props.owner; // city_id
        this.coordinates = props.coordinates;
        this.battery = props.battery;
        this.status = props.status || 'available';
        this.serial_number = props.serial_number;
        this.model = props.model;
        this.manufacturer = props.manufacturer;
        this.firmware_version = props.firmware_version;
        this.hardware_version = props.hardware_version;
        this.mac_address = props.mac_address;
        this.imei = props.imei;
        this.sim_number = props.sim_number;
        this.total_distance_km = props.total_distance_km || 0;
        this.total_rides = props.total_rides || 0;
        this.battery_health_percent = props.battery_health_percent || 100;
        this.battery_cycles = props.battery_cycles || 0;
        this.max_speed_kmh = props.max_speed_kmh || 25;
        this.battery_capacity_wh = props.battery_capacity_wh || 280;
        this.purchase_date = props.purchase_date;
        this.purchase_price = props.purchase_price;
        this.last_maintenance_at = props.last_maintenance_at;
        this.next_maintenance_at = props.next_maintenance_at;
        this.retired_at = props.retired_at;
        this.retired_reason = props.retired_reason;
        this.iot_secret_hash = props.iot_secret_hash;
        this.last_seen = props.last_seen;
        this.log = props.log || [];
        this.created_at = props.created_at;
        this.updated_at = props.updated_at;
    }

    canTransitionTo(newStatus) {
        return (SCOOTER_TRANSITIONS[this.status] || []).includes(newStatus);
    }

    isAvailable() { return this.status === 'available'; }
    isUsable() { return ['available', 'reserved', 'in_use'].includes(this.status); }
    needsCharging() { return this.battery < 20 && this.status !== 'charging'; }
    needsMaintenance() { return this.status === 'maintenance'; }
    isRetired() { return this.status === 'retired'; }
}

module.exports = { Scooter, SCOOTER_STATUSES, SCOOTER_TRANSITIONS };
