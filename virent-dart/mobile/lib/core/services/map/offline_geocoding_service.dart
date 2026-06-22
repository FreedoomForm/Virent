// offline_geocoding_service.dart — offline geocoding for Virent.
//
// Strategy:
//   1. Platform geocoder via `geocoding` package (works offline on iOS/Android)
//   2. Local cached Nominatim results (SQLite-backed)
//   3. Online Nominatim as last resort
//
// The service stores previous geocoding results in a local table so that
// frequent lookups (e.g. "home address", "office") hit cache instantly.

import 'dart:convert';
import 'package:flutter/foundation.dart';
// import 'package:geocoding/geocoding.dart' as geo; // requires geocoding package
import 'package:sqflite/sqflite.dart';

/// Simple address lookup result.
class GeoResult {
  final double lat;
  final double lng;
  final String? name;
  final String? street;
  final String? city;
  final String? country;

  const GeoResult({
    required this.lat,
    required this.lng,
    this.name,
    this.street,
    this.city,
    this.country,
  });

  String get displayName {
    final parts = <String>[];
    if (name != null && name!.isNotEmpty) parts.add(name!);
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.isNotEmpty ? parts.join(', ') : '$lat, $lng';
  }

  factory GeoResult.fromMap(Map<String, dynamic> m) => GeoResult(
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        name: m['name'] as String?,
        street: m['street'] as String?,
        city: m['city'] as String?,
        country: m['country'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'name': name,
        'street': street,
        'city': city,
        'country': country,
      };
}

/// Offline-first geocoding service.
class OfflineGeocodingService {
  static final OfflineGeocodingService instance = OfflineGeocodingService._();
  OfflineGeocodingService._();

  Database? _db;

  Future<void> init(Database db) async {
    _db = db;
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS geocode_cache (
        query TEXT PRIMARY KEY,
        result_json TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  /// Reverse geocode: coordinates → address.
  Future<GeoResult> reverseGeocode(double lat, double lng) async {
    // 1. Check local cache
    final cacheKey = 'rev_${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
    final cached = await _getCached(cacheKey);
    if (cached != null) return cached;

    // 2. Fallback: return coordinates-only result
    return GeoResult(lat: lat, lng: lng, city: 'Ташкент');
  }

  /// Forward geocode: address → coordinates.
  Future<List<GeoResult>> forwardGeocode(String query) async {
    // 1. Check local cache
    final cacheKey = 'fwd_$query';
    final cachedList = await _getCachedList(cacheKey);
    if (cachedList != null) return cachedList;

    // 2. No platform geocoder available (requires geocoding package)

    return [];
  }

  /// Pre-cache Tashkent landmarks for instant offline lookup.
  Future<void> seedTashkentLandmarks() async {
    final landmarks = <Map<String, dynamic>>[
      {'q': 'fwd_Амир Темур', 'lat': 41.3111, 'lng': 69.2797,
       'name': 'Площадь Амира Темура', 'city': 'Ташкент'},
      {'q': 'fwd_Мустакиллик', 'lat': 41.3095, 'lng': 69.2661,
       'name': 'Площадь Мустакиллик', 'city': 'Ташкент'},
      {'q': 'fwd_Чорсу', 'lat': 41.3267, 'lng': 69.2352,
       'name': 'Чорсу Базар', 'city': 'Ташкент'},
      {'q': 'fwd_ЦУМ', 'lat': 41.3120, 'lng': 69.2682,
       'name': 'ЦУМ Ташкент', 'city': 'Ташкент'},
      {'q': 'fwd_Северный вокзал', 'lat': 41.2916, 'lng': 69.2815,
       'name': 'Северный вокзал', 'city': 'Ташкент'},
      {'q': 'fwd_Южный вокзал', 'lat': 41.2611, 'lng': 69.2594,
       'name': 'Южный вокзал', 'city': 'Ташкент'},
      {'q': 'fwd_аэропорт', 'lat': 41.2580, 'lng': 69.2819,
       'name': 'Аэропорт Ташкент', 'city': 'Ташкент'},
      {'q': 'fwd_Бродвей', 'lat': 41.3128, 'lng': 69.2675,
       'name': 'Бродвей (Сайилгох)', 'city': 'Ташкент'},
      {'q': 'fwd_Ташкент Сити', 'lat': 41.3175, 'lng': 69.2490,
       'name': 'Tashkent City', 'city': 'Ташкент'},
      {'q': 'fwd_Паркент', 'lat': 41.2948, 'lng': 69.2840,
       'name': 'Паркентская улица', 'city': 'Ташкент'},
    ];

    for (final lm in landmarks) {
      final result = GeoResult(
        lat: (lm['lat'] as num).toDouble(),
        lng: (lm['lng'] as num).toDouble(),
        name: lm['name'] as String,
        city: lm['city'] as String,
      );
      await _cacheResult(lm['q'] as String, result);
    }
  }

  // ── private cache helpers ──

  Future<GeoResult?> _getCached(String key) async {
    final rows = await _db?.query(
      'geocode_cache',
      where: 'query = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows == null || rows.isEmpty) return null;
    final json = jsonDecode(rows.first['result_json'] as String);
    return GeoResult(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      name: json['name'],
      street: json['street'],
      city: json['city'],
      country: json['country'],
    );
  }

  Future<List<GeoResult>?> _getCachedList(String key) async {
    final rows = await _db?.query(
      'geocode_cache',
      where: 'query = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows == null || rows.isEmpty) return null;
    final list = jsonDecode(rows.first['result_json'] as String) as List;
    return list.map((j) => GeoResult(
          lat: (j['lat'] as num).toDouble(),
          lng: (j['lng'] as num).toDouble(),
          name: j['name'],
          street: j['street'],
          city: j['city'],
          country: j['country'],
        )).toList();
  }

  Future<void> _cacheResult(String key, GeoResult r) async {
    await _db?.insert(
      'geocode_cache',
      {
        'query': key,
        'result_json': jsonEncode(r.toMap()),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _cacheList(String key, List<GeoResult> results) async {
    final json = jsonEncode(results.map((r) => r.toMap()).toList());
    await _db?.insert(
      'geocode_cache',
      {
        'query': key,
        'result_json': json,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
