import 'package:flutter/material.dart';

/// A user-saved favourite location (home, office, landmark, ...).
///
/// Used by the map's "saved places" shortcuts and by the trip planner's
/// destination picker. The model is pure (no Flutter / Riverpod code) so it
/// can be unit-tested in isolation.
class Favorite {
  /// Creates a favourite.
  const Favorite({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.icon = Icons.star,
  });

  /// Server-assigned unique id.
  final String id;

  /// User-supplied label ("Home", "Office", ...).
  final String name;

  /// Latitude in decimal degrees (WGS-84).
  final double latitude;

  /// Longitude in decimal degrees (WGS-84).
  final double longitude;

  /// Optional human-readable address (reverse-geocoded).
  final String? address;

  /// Icon used in the UI; defaults to a star.
  final IconData icon;

  /// Parses a JSON object into a [Favorite].
  ///
  /// Accepts both flat (`{lat, lng}`) and nested
  /// (`{coordinates: {latitude, longitude}}`) shapes.
  factory Favorite.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'];
    double lat;
    double lng;
    if (coords is Map) {
      lat = _toDouble(coords['latitude'] ?? coords['lat']);
      lng = _toDouble(coords['longitude'] ?? coords['lng']);
    } else {
      lat = _toDouble(json['latitude'] ?? json['lat']);
      lng = _toDouble(json['longitude'] ?? json['lng']);
    }
    return Favorite(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['label'] ?? '').toString(),
      latitude: lat,
      longitude: lng,
      address: json['address']?.toString(),
    );
  }

  /// Serialises the favourite back to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
      };

  /// Returns a copy with the supplied fields replaced.
  Favorite copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    IconData? icon,
  }) {
    return Favorite(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      icon: icon ?? this.icon,
    );
  }

  /// Coerces a num / String into a [double].
  static double _toDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0.0;
  }
}
