/// Scooter discovery query results.
///
/// Ported from `backend/v1/models/discovery.js`. The backend exposes
/// three endpoints:
///   * `GET /discovery/nearest?lat=&lng=&radius_km=` — k-NN by haversine
///   * `GET /discovery/available?city_id=` — all available in city
///   * `GET /discovery/qr/:code` — resolve `SR-XXXXXX` QR → scooter
///
/// This file captures the *result* shapes returned by those endpoints.
/// The mobile client does not run the discovery algorithm itself; it
/// consumes the backend response and may re-sort by distance.
library;

import 'dart:math' as math;
import 'json_helpers.dart';

/// A single scooter row in the `/discovery/nearest` response.
///
/// Augments the base scooter shape with [distanceKm] and [etaMinutes]
/// so the UI can render "120 m · 3 min walk".
class NearestScooter {
  /// Backend scooter `_id`.
  final String id;

  /// Human-readable label.
  final String name;

  /// Latitude in decimal degrees (WGS84).
  final double lat;

  /// Longitude in decimal degrees (WGS84).
  final double lng;

  /// Battery level as integer percentage (0–100).
  final int battery;

  /// Operational status (`available`, `in_use`, `charging_needed`, ...).
  final String status;

  /// Per-minute rental rate in UZS tiyin (smallest currency unit).
  final int ratePerMin;

  /// Straight-line (haversine) distance from the user, in kilometres.
  final double distanceKm;

  /// Estimated walking time to the scooter, in minutes.
  /// Computed at 5 km/h walking speed.
  final int etaMinutes;

  /// Optional scooter model identifier (e.g. "Virent Pro 2").
  final String? model;

  /// Creates a [NearestScooter].
  const NearestScooter({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.battery,
    required this.status,
    required this.ratePerMin,
    required this.distanceKm,
    required this.etaMinutes,
    this.model,
  });

  /// Parses a JSON row from `/discovery/nearest` into a [NearestScooter].
  factory NearestScooter.fromJson(Map<String, dynamic> json) {
    final rawLat = json['lat'] ?? json['latitude'] ??
        (json['coordinates'] is Map ? json['coordinates']['latitude'] : null);
    final rawLng = json['lng'] ?? json['longitude'] ??
        (json['coordinates'] is Map ? json['coordinates']['longitude'] : null);
    final rawBattery = json['battery'] ?? json['battery_level'];
    final rawRate = json['rate_per_min'] ?? json['ratePerMin'] ?? 1200;
    final rawDistance = json['distance_km'] ?? json['distance'];
    final distanceKm = rawDistance is num
        ? rawDistance.toDouble()
        : double.tryParse('${rawDistance ?? 0}') ?? 0;
    final rawEta = toInt(json['eta_minutes'] ?? json['etaMinutes']);
    return NearestScooter(
      id: stringifyId(json['_id'] ?? json['id']),
      name: (json['name'] ?? json['label'] ?? 'Virent Scooter').toString(),
      lat: toDouble(rawLat),
      lng: toDouble(rawLng),
      battery: toInt(rawBattery),
      status: (json['status'] ?? 'unknown').toString(),
      ratePerMin: toInt(rawRate),
      distanceKm: distanceKm,
      etaMinutes: rawEta == 0 ? _walkMinutes(distanceKm) : rawEta,
      model: asString(json['model']),
    );
  }

  /// Distance in metres, rounded.
  int get distanceMeters => (distanceKm * 1000).round();

  /// `true` when the scooter has enough battery for a safe ride.
  bool get hasSufficientBattery => battery >= 15;

  /// `true` when the scooter is within walking distance (<=500 m).
  bool get isWithinWalkingDistance => distanceMeters <= 500;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'battery': battery,
        'status': status,
        'rate_per_min': ratePerMin,
        'distance_km': distanceKm,
        'eta_minutes': etaMinutes,
        if (model != null) 'model': model,
      };

  NearestScooter copyWith({
    String? id,
    String? name,
    double? lat,
    double? lng,
    int? battery,
    String? status,
    int? ratePerMin,
    double? distanceKm,
    int? etaMinutes,
    String? model,
  }) {
    return NearestScooter(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      battery: battery ?? this.battery,
      status: status ?? this.status,
      ratePerMin: ratePerMin ?? this.ratePerMin,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      model: model ?? this.model,
    );
  }

  @override
  String toString() =>
      'NearestScooter(id: $id, ${distanceKm.toStringAsFixed(2)} km, battery: $battery%)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NearestScooter && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Wrapper for the `/discovery/nearest` response.
class NearestScooterResult {
  /// Scooters within `radiusKm`, sorted by ascending distance.
  final List<NearestScooter> scooters;

  /// Total number of scooters in [scooters].
  final int count;

  /// Centre of the search circle.
  final DiscoveryCenter center;

  /// Search radius, in kilometres.
  final double radiusKm;

  const NearestScooterResult({
    required this.scooters,
    required this.count,
    required this.center,
    required this.radiusKm,
  });

  factory NearestScooterResult.fromJson(Map<String, dynamic> json) {
    final rawScooters = json['scooters'] ?? const [];
    final rawCenter = json['center'] ?? const <String, dynamic>{};
    return NearestScooterResult(
      scooters: rawScooters is List
          ? rawScooters
              .whereType<Map>()
              .map((s) => NearestScooter.fromJson(s as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      count: toInt(json['count'] ?? (rawScooters is List ? rawScooters.length : 0)),
      center: DiscoveryCenter.fromJson(
          rawCenter is Map<String, dynamic>
              ? rawCenter
              : const <String, dynamic>{}),
      radiusKm: toDouble(json['radius_km'] ?? json['radiusKm'] ?? 2),
    );
  }

  /// Returns the closest scooter, or `null` when the list is empty.
  NearestScooter? get closest =>
      scooters.isEmpty ? null : scooters.first;

  Map<String, dynamic> toJson() => {
        'scooters': scooters.map((s) => s.toJson()).toList(),
        'count': count,
        'center': center.toJson(),
        'radius_km': radiusKm,
      };
}

/// Latitude/longitude pair representing the centre of a discovery search.
class DiscoveryCenter {
  final double lat;
  final double lng;

  const DiscoveryCenter({required this.lat, required this.lng});

  factory DiscoveryCenter.fromJson(Map<String, dynamic> json) =>
      DiscoveryCenter(
        lat: toDouble(json['lat'] ?? json['latitude']),
        lng: toDouble(json['lng'] ?? json['longitude']),
      );

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  @override
  String toString() => 'DiscoveryCenter($lat, $lng)';
}

/// QR-code resolution result returned by `/discovery/qr/:code`.
class QrResolution {
  /// Backend scooter `_id`.
  final String scooterId;

  /// Human-readable name.
  final String name;

  /// Battery percentage (0–100).
  final int battery;

  /// Operational status.
  final String status;

  /// Scooter model identifier.
  final String? model;

  /// Last reported coordinates.
  final DiscoveryCenter? coordinates;

  const QrResolution({
    required this.scooterId,
    required this.name,
    required this.battery,
    required this.status,
    this.model,
    this.coordinates,
  });

  factory QrResolution.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'];
    return QrResolution(
      scooterId: stringifyId(json['scooter_id'] ?? json['_id']),
      name: (json['name'] ?? '').toString(),
      battery: toInt(json['battery']),
      status: (json['status'] ?? 'unknown').toString(),
      model: asString(json['model']),
      coordinates: rawCoords is Map<String, dynamic>
          ? DiscoveryCenter.fromJson(rawCoords)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'scooter_id': scooterId,
        'name': name,
        'battery': battery,
        'status': status,
        if (model != null) 'model': model,
        if (coordinates != null) 'coordinates': coordinates!.toJson(),
      };

  @override
  String toString() =>
      'QrResolution(scooter: $scooterId, battery: $battery%, status: $status)';
}

// --- QR-code helpers -----------------------------------------------------

/// Validates and normalises a QR-code string.
///
/// Returns the upper-cased, alphanumeric code (with hyphen) or `null`
/// when the input does not match the `SR-XXXXXX...` shape produced by
/// `discovery.js::generateQrCode`.
String? normalizeQrCode(String raw) {
  final cleaned = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9-]'), '');
  if (!cleaned.startsWith('SR-')) return null;
  final shortId = cleaned.substring(3);
  if (shortId.length < 6) return null;
  return cleaned;
}

/// Generates the QR-code string for a scooter, mirroring
/// `discovery.js::generateQrCode`.
String generateQrCode(String scooterIdHex) =>
    'SR-${scooterIdHex.substring(0, math.min(6, scooterIdHex.length)).toUpperCase()}';

/// Great-circle distance between two points, in kilometres.
///
/// Mirrors `discovery.js::haversineKm`. Useful for client-side re-sorting
/// after the user moves.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371; // Earth radius, km
  double toRad(double deg) => deg * math.pi / 180;
  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRad(lat1)) *
          math.cos(toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

// --- internal helpers ----------------------------------------------------

int _walkMinutes(double km) => (km / 5 * 60).round(); // 5 km/h walk speed


