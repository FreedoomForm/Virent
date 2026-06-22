/// Geofencing check result.
///
/// Ported from `backend/v1/models/geofencing.js`. The original module
/// exposes `locatePoint`, `getSpeedLimit`, `checkActiveTripViolations`
/// and the public `POST /geofencing/check` endpoint. The mobile client
/// only consumes the result of the public check; it does not run the
/// polygon-inclusion test itself (that stays server-side).
library;

import 'zone_model.dart' show ZoneType, GeoPoint;
import 'json_helpers.dart';

/// Outcome of a single `POST /geofencing/check` call.
///
/// Encodes both the "where am I?" answer (`city`/`zone`) and the
/// "what should the scooter do here?" answer (`speedLimit`, `violation`).
class GeofenceCheck {
  /// Coordinates the check was performed against.
  final GeoPoint coordinates;

  /// `true` when the point is inside the city's outer service area.
  final bool insideServiceArea;

  /// City the point falls into, when known.
  final GeofenceCity? city;

  /// Specific zone the point falls into, when any.
  final GeofenceZone? zone;

  /// Maximum allowed scooter speed at this location, in km/h.
  /// `0` means "do not ride" (outside service area).
  final int speedLimit;

  /// Machine-readable reason for the speed limit:
  /// `street`, `parking_zone`, `no_parking_zone`, `slow_zone`,
  /// `outside_city`, `charging_zone`.
  final String speedLimitReason;

  /// Optional human-readable message for the user (e.g. zone-violation
  /// warning).
  final String? message;

  /// `true` when ending the ride here will incur a penalty
  /// (no-parking zone) or otherwise requires user attention.
  final bool violation;

  /// When [violation] is `true`, the machine-readable violation slug.
  /// Examples: `outside_city`, `no_parking_enter`, `geofence_breach`.
  final String? violationType;

  /// Creates a [GeofenceCheck].
  const GeofenceCheck({
    required this.coordinates,
    required this.insideServiceArea,
    required this.speedLimit,
    required this.speedLimitReason,
    this.city,
    this.zone,
    this.message,
    this.violation = false,
    this.violationType,
  });

  /// Parses the JSON returned by `POST /geofencing/check` into a
  /// [GeofenceCheck].
  factory GeofenceCheck.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'] ?? const <String, dynamic>{};
    final rawCity = json['city'];
    final rawZone = json['zone'];
    final rawViolation = json['violation'] ??
        (json['speed_limit_reason'] == 'outside_city' ||
            json['speed_limit_reason'] == 'no_parking_zone');
    return GeofenceCheck(
      coordinates: GeoPoint.fromJson(
          rawCoords is Map<String, dynamic>
              ? rawCoords
              : const <String, dynamic>{}),
      insideServiceArea: json['inside_service_area'] == true ||
          json['insideServiceArea'] == true,
      city: rawCity is Map<String, dynamic>
          ? GeofenceCity.fromJson(rawCity)
          : null,
      zone: rawZone is Map<String, dynamic>
          ? GeofenceZone.fromJson(rawZone)
          : null,
      speedLimit: toInt(json['speed_limit_kmh'] ??
          json['speedLimitKmh'] ??
          json['max_speed_kmh']),
      speedLimitReason:
          (json['speed_limit_reason'] ?? json['reason'] ?? 'street')
              .toString(),
      message: asString(json['message']),
      violation: rawViolation == true,
      violationType: asString(json['violation_type'] ?? json['violation']),
    );
  }

  /// `true` when the user is in a no-parking zone (penalty on end of ride).
  bool get isInNoParking => speedLimitReason == 'no_parking_zone';

  /// `true` when the user is in a parking or bonus-parking zone (discount).
  bool get isInParkingZone =>
      speedLimitReason == 'parking_zone' ||
      speedLimitReason == 'bonus_parking_zone';

  /// `true` when the scooter must come to a complete stop.
  bool get mustStop => speedLimit == 0;

  /// `true` when the user must return to the service area.
  bool get mustReturn => speedLimitReason == 'outside_city';

  Map<String, dynamic> toJson() => {
        'coordinates': coordinates.toJson(),
        'inside_service_area': insideServiceArea,
        if (city != null) 'city': city!.toJson(),
        if (zone != null) 'zone': zone!.toJson(),
        'speed_limit_kmh': speedLimit,
        'speed_limit_reason': speedLimitReason,
        if (message != null) 'message': message,
        'violation': violation,
        if (violationType != null) 'violation_type': violationType,
      };

  GeofenceCheck copyWith({
    GeoPoint? coordinates,
    bool? insideServiceArea,
    GeofenceCity? city,
    GeofenceZone? zone,
    int? speedLimit,
    String? speedLimitReason,
    String? message,
    bool? violation,
    String? violationType,
  }) {
    return GeofenceCheck(
      coordinates: coordinates ?? this.coordinates,
      insideServiceArea: insideServiceArea ?? this.insideServiceArea,
      city: city ?? this.city,
      zone: zone ?? this.zone,
      speedLimit: speedLimit ?? this.speedLimit,
      speedLimitReason: speedLimitReason ?? this.speedLimitReason,
      message: message ?? this.message,
      violation: violation ?? this.violation,
      violationType: violationType ?? this.violationType,
    );
  }

  @override
  String toString() =>
      'GeofenceCheck(reason: $speedLimitReason, limit: $speedLimit km/h, violation: $violation)';
}

/// City reference returned inside a [GeofenceCheck].
class GeofenceCity {
  /// MongoDB `_id` of the city.
  final String id;

  /// City name.
  final String name;

  const GeofenceCity({required this.id, required this.name});

  factory GeofenceCity.fromJson(Map<String, dynamic> json) => GeofenceCity(
        id: stringifyId(json['id'] ?? json['_id']),
        name: (json['name'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  String toString() => 'GeofenceCity($name)';
}

/// Zone reference returned inside a [GeofenceCheck].
class GeofenceZone {
  /// Zone `_id`.
  final String id;

  /// Modern zone type (parking / bonus_parking / no_parking / slow /
  /// charging).
  final ZoneType type;

  /// Legacy `zoneType` bucket, when present.
  final String? zoneType;

  /// Optional active-hours window.
  final DateTime? activeFrom;

  /// Optional active-hours window end.
  final DateTime? activeUntil;

  const GeofenceZone({
    required this.id,
    required this.type,
    this.zoneType,
    this.activeFrom,
    this.activeUntil,
  });

  factory GeofenceZone.fromJson(Map<String, dynamic> json) => GeofenceZone(
        id: stringifyId(json['id'] ?? json['_id']),
        type: ZoneType.fromString(
            (json['type'] ?? json['zone_type'] ?? '').toString()),
        zoneType: asString(json['zone_type'] ?? json['zoneType']),
        activeFrom: parseDate(json['active_from']),
        activeUntil: parseDate(json['active_until']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.wire,
        if (zoneType != null) 'zone_type': zoneType,
        if (activeFrom != null) 'active_from': activeFrom!.toIso8601String(),
        if (activeUntil != null) 'active_until': activeUntil!.toIso8601String(),
      };

  @override
  String toString() => 'GeofenceZone($type)';
}

/// Speed-limit policy mirrors `geofencing.js` constants.
class GeofenceSpeedPolicy {
  static const int defaultStreet = 25; // km/h
  static const int parkingZone = 10; // km/h
  static const int slowZone = 15; // km/h (typical school zone)
  static const int outsideCity = 0; // do not ride

  /// UZS penalty charged when a ride ends in a no-parking zone.
  static const int noParkingFine = 5000;
}

// --- internal helpers ----------------------------------------------------


