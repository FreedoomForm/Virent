/// Geofenced zone model embedded inside a [CityModel].
///
/// Ported from `backend/v1/models/cities.js` (`registerZone`, `editZone`,
/// `deleteZone`). The backend stores zones inside the parent city document
/// as an array; each zone has a MongoDB `_id`, a [zoneType] bucket, a
/// geometric [type] (currently always `"Polygon"`) and a list of polygon
/// vertex [points].
///
/// Note: the backend uses two distinct enum schemes — `zoneType`
/// (`chargingZone`, `noParkingZone`, `bonusParkingZone`, `parkingZone`)
/// for legacy CRUD, and a modern `type` (`parking`, `bonus_parking`,
/// `no_parking`, `slow`, `charging`) used by `geofencing.js`. This model
/// exposes both for forward compatibility.
library; // allow `part of` consumers without implicit name conflicts

import 'json_helpers.dart';

/// Type-safe enumeration of zone types understood by the geofencing
/// engine. Values mirror the `type` field on zone documents.
enum ZoneType {
  /// Standard parking zone — reduced speed, no parking fee.
  parking,

  /// High-priority parking / charging hub — extra discount on end of ride.
  bonusParking,

  /// No-parking zone — ending a ride here incurs a penalty fee.
  noParking,

  /// Slow-speed zone — scooter hardware speed cap is reduced.
  slow,

  /// Charging zone — target drop-off for juicers.
  charging,

  /// Anything the client doesn't yet understand.
  unknown;

  /// Parses a raw string into a [ZoneType].
  static ZoneType fromString(String? raw) {
    switch (raw) {
      case 'parking':
      case 'parkingZone':
        return ZoneType.parking;
      case 'bonus_parking':
      case 'bonusParkingZone':
        return ZoneType.bonusParking;
      case 'no_parking':
      case 'noParkingZone':
        return ZoneType.noParking;
      case 'slow':
      case 'slowZone':
        return ZoneType.slow;
      case 'charging':
      case 'chargingZone':
        return ZoneType.charging;
      default:
        return ZoneType.unknown;
    }
  }

  /// String form matching the modern `geofencing.js` schema.
  String get wire => switch (this) {
        ZoneType.parking => 'parking',
        ZoneType.bonusParking => 'bonus_parking',
        ZoneType.noParking => 'no_parking',
        ZoneType.slow => 'slow',
        ZoneType.charging => 'charging',
        ZoneType.unknown => 'unknown',
      };
}

/// Single geofenced zone inside a city.
class ZoneModel {
  /// MongoDB `_id` of the zone (assigned at `registerZone` time).
  final String id;

  /// Legacy bucket string (`parkingZone`, `noParkingZone`,
  /// `bonusParkingZone`, `chargingZone`). Retained for back-compat.
  final String zoneType;

  /// Modern type-safe bucket.
  final ZoneType type;

  /// Geometry type from GeoJSON (`"Polygon"`).
  final String geometryType;

  /// Polygon vertices in winding order. Treated as a single ring.
  final List<GeoPoint> points;

  /// Maximum speed (km/h) the scooter hardware should enforce while
  /// inside this zone. Mirrors constants in `geofencing.js`:
  /// parking/bonus = 10, street = 25, slow zones configurable.
  final int speedLimit;

  /// Optional active-hours window. Outside this window the zone is
  /// treated as inactive (e.g. a slow-school-zone active only 07:00-09:00).
  final ZoneActiveHours? activeHours;

  /// Free-form metadata bag (color, label, internal notes).
  final Map<String, dynamic> metadata;

  /// Creates a [ZoneModel].
  const ZoneModel({
    required this.id,
    required this.zoneType,
    required this.type,
    this.geometryType = 'Polygon',
    this.points = const [],
    this.speedLimit = 25,
    this.activeHours,
    this.metadata = const {},
  });

  /// Parses a JSON object (zone sub-document) into a [ZoneModel].
  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] ?? json['zoneType'];
    final rawCoords = json['coordinates'] ?? json['points'] ?? json['polygon'];
    final rawMeta = json['metadata'] ?? json['meta'];
    return ZoneModel(
      id: stringifyId(json['_id'] ?? json['id']),
      zoneType: (json['zoneType'] ?? json['zone_type'] ?? '').toString(),
      type: ZoneType.fromString(rawType?.toString()),
      geometryType: (json['geometryType'] ??
              json['geometry_type'] ??
              (json['type'] == 'Polygon' ? 'Polygon' : 'Polygon'))
          .toString(),
      points: _parsePoints(rawCoords),
      speedLimit: toInt(json['speedLimit'] ?? json['speed_limit'] ?? 25),
      activeHours: json['active_hours'] != null || json['activeHours'] != null
          ? ZoneActiveHours.fromJson(
              (json['active_hours'] ?? json['activeHours']) as Map<String, dynamic>)
          : null,
      metadata: rawMeta is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawMeta)
          : const {},
    );
  }

  /// `true` when the zone polygon has at least 3 vertices (minimum
  /// required by `robust-point-in-polygon`).
  bool get isValidPolygon => points.length >= 3;

  /// `true` when the zone is a parking variant (regular or bonus).
  bool get isParking =>
      type == ZoneType.parking || type == ZoneType.bonusParking;

  /// `true` when ending a ride in this zone triggers a penalty.
  bool get isNoParking => type == ZoneType.noParking;

  /// `true` when this is a juicer drop-off / charging hub.
  bool get isCharging => type == ZoneType.charging;

  /// Serialises the zone back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        'zoneType': zoneType,
        'type': type.wire,
        'geometryType': geometryType,
        'coordinates': points.map((p) => p.toJson()).toList(),
        'speedLimit': speedLimit,
        if (activeHours != null) 'active_hours': activeHours!.toJson(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Returns a copy of this zone with the given fields replaced.
  ZoneModel copyWith({
    String? id,
    String? zoneType,
    ZoneType? type,
    String? geometryType,
    List<GeoPoint>? points,
    int? speedLimit,
    ZoneActiveHours? activeHours,
    Map<String, dynamic>? metadata,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      zoneType: zoneType ?? this.zoneType,
      type: type ?? this.type,
      geometryType: geometryType ?? this.geometryType,
      points: points ?? this.points,
      speedLimit: speedLimit ?? this.speedLimit,
      activeHours: activeHours ?? this.activeHours,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() =>
      'ZoneModel(id: $id, type: $type, points: ${points.length}, speed: $speedLimit)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ZoneModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Active-hours window for time-scoped zones (e.g. school slow zones).
class ZoneActiveHours {
  /// Local-time start in `"HH:mm"` 24h format.
  final String start;

  /// Local-time end in `"HH:mm"` 24h format.
  final String end;

  /// Days of week the window applies to (1 = Monday ... 7 = Sunday).
  /// Empty means every day.
  final List<int> daysOfWeek;

  const ZoneActiveHours({
    required this.start,
    required this.end,
    this.daysOfWeek = const [],
  });

  factory ZoneActiveHours.fromJson(Map<String, dynamic> json) =>
      ZoneActiveHours(
        start: (json['start'] ?? '00:00').toString(),
        end: (json['end'] ?? '23:59').toString(),
        daysOfWeek: (json['days_of_week'] ?? json['daysOfWeek'] ?? const [])
                is List
            ? (json['days_of_week'] ?? json['daysOfWeek'] as List)
                .map((d) => d is int ? d : int.tryParse(d.toString()) ?? 0)
                .where((d) => d >= 1 && d <= 7)
                .toList(growable: false)
            : const [],
      );

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        if (daysOfWeek.isNotEmpty) 'days_of_week': daysOfWeek,
      };

  @override
  String toString() => 'ZoneActiveHours($start-$end, days: $daysOfWeek)';
}

/// Lightweight latitude/longitude pair used inside zone polygons.
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude});

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
        latitude: toDouble(json['latitude'] ?? json['lat']),
        longitude: toDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeoPoint &&
          other.latitude == latitude &&
          other.longitude == longitude);

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

// --- internal helpers ----------------------------------------------------


List<GeoPoint> _parsePoints(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((p) => GeoPoint.fromJson(p as Map<String, dynamic>))
      .toList(growable: false);
}
