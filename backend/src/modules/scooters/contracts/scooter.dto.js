/**
 * Scooter DTOs
 */
function toSummary(scooter) {
    if (!scooter) return null;
    return {
        id: String(scooter._id || scooter.id),
        name: scooter.name,
        status: scooter.status,
        battery: scooter.battery,
    };
}

function toListItem(scooter) {
    return {
        id: String(scooter._id || scooter.id),
        name: scooter.name,
        model: scooter.model,
        status: scooter.status,
        battery: scooter.battery,
        coordinates: scooter.coordinates,
        city_id: String(scooter.owner),
        last_seen: scooter.last_seen,
    };
}

function toDetail(scooter) {
    return {
        id: String(scooter._id || scooter.id),
        name: scooter.name,
        model: scooter.model,
        manufacturer: scooter.manufacturer,
        serial_number: scooter.serial_number,
        mac_address: scooter.mac_address,
        imei: scooter.imei,
        sim_number: scooter.sim_number,
        firmware_version: scooter.firmware_version,
        hardware_version: scooter.hardware_version,
        status: scooter.status,
        battery: scooter.battery,
        battery_capacity_wh: scooter.battery_capacity_wh,
        battery_cycles: scooter.battery_cycles,
        battery_health_percent: scooter.battery_health_percent,
        max_speed_kmh: scooter.max_speed_kmh,
        coordinates: scooter.coordinates,
        city_id: String(scooter.owner),
        total_distance_km: scooter.total_distance_km,
        total_rides: scooter.total_rides,
        purchase_date: scooter.purchase_date,
        purchase_price: scooter.purchase_price,
        last_maintenance_at: scooter.last_maintenance_at,
        next_maintenance_at: scooter.next_maintenance_at,
        retired_at: scooter.retired_at,
        retired_reason: scooter.retired_reason,
        last_seen: scooter.last_seen,
        created_at: scooter.created_at,
        updated_at: scooter.updated_at,
    };
}

function toAdminDetail(scooter) {
    return toDetail(scooter); // For now same as detail; could add internal fields
}

module.exports = { toSummary, toListItem, toDetail, toAdminDetail };
