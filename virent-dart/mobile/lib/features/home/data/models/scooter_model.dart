import 'package:latlong2/latlong.dart';

/// Data model representing a Virent scooter as returned by the backend.
///
/// Mirrors the JSON shape produced by the embedded server's
/// `/scooters/nearby` and `/scooters/:id` endpoints:
///
/// ```json
/// {
///   "id": "s1",
///   "name": "Virent #001",
///   "lat": 41.3111,
///   "lng": 69.2406,
///   "battery": 87,
///   "status": "available",
///   "rate_per_min": 1200,
///   "distance": 120
/// }
/// ```
///
/// The model is intentionally framework-free: no Flutter or Riverpod
/// dependency so it can be unit-tested in isolation and reused by both the
/// home and scanner features.
class ScooterModel {
  /// Server-side unique identifier (also encoded in the QR code).
  final String id;

  /// Human readable label shown on the map marker and bottom sheet.
  final String name;

  /// Latitude in decimal degrees (WGS84).
  final double lat;

  /// Longitude in decimal degrees (WGS84).
  final double lng;

  /// Battery level as an integer percentage (0–100).
  final int battery;

  /// Operational status: `available`, `in_use`, `charging`, `maintenance`
  /// or `offline`.
  final String status;

  /// Per-minute rental rate in the smallest currency unit (UZS tiyin).
  final int ratePerMin;

  /// Distance in metres from the user's current location, when known.
  /// Populated by `/scooters/nearby`; `null` when fetched by id.
  final int? distance;

  /// Creates a [ScooterModel].
  const ScooterModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.battery,
    required this.status,
    required this.ratePerMin,
    this.distance,
  });

  /// Parses a JSON object into a [ScooterModel].
  ///
  /// Resilient to missing fields — defaults are substituted so a partial
  /// payload never crashes the UI.
  factory ScooterModel.fromJson(Map<String, dynamic> json) {
    final rawLat = json['lat'] ?? json['latitude'] ?? 0;
    final rawLng = json['lng'] ?? json['longitude'] ?? 0;
    final rawBattery = json['battery'] ?? json['battery_level'] ?? 0;
    final rawRate = json['rate_per_min'] ?? json['ratePerMin'] ?? 1200;
    final rawDistance = json['distance'] ?? json['distance_m'];
    return ScooterModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['label'] ?? 'Virent Scooter').toString(),
      lat: rawLat is num ? rawLat.toDouble() : double.tryParse('$rawLat') ?? 0,
      lng: rawLng is num ? rawLng.toDouble() : double.tryParse('$rawLng') ?? 0,
      battery: rawBattery is int ? rawBattery : int.tryParse('$rawBattery') ?? 0,
      status: (json['status'] ?? 'unknown').toString(),
      ratePerMin:
          rawRate is int ? rawRate : int.tryParse('$rawRate') ?? 1200,
      distance: rawDistance == null
          ? null
          : (rawDistance is int ? rawDistance : int.tryParse('$rawDistance')),
    );
  }

  /// Latitude/longitude pair ready for `flutter_map` markers.
  LatLng get location => LatLng(lat, lng);

  /// `true` when the scooter can be unlocked by a rider.
  bool get isAvailable => status == 'available';

  /// `true` when the battery is high enough for a safe ride.
  bool get hasSufficientBattery => battery >= 20;

  /// Serialises the model back to a JSON map (used for local caching).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'battery': battery,
        'status': status,
        'rate_per_min': ratePerMin,
        if (distance != null) 'distance': distance,
      };

  /// Returns a copy of this model with the given fields replaced.
  ScooterModel copyWith({
    String? id,
    String? name,
    double? lat,
    double? lng,
    int? battery,
    String? status,
    int? ratePerMin,
    int? distance,
  }) {
    return ScooterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      battery: battery ?? this.battery,
      status: status ?? this.status,
      ratePerMin: ratePerMin ?? this.ratePerMin,
      distance: distance ?? this.distance,
    );
  }

  @override
  String toString() =>
      'ScooterModel(id: $id, name: $name, battery: $battery%, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ScooterModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
