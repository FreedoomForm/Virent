// nominatim_service.dart — fully offline geocoding for Virent.
//
// No external APIs. Uses a local SQLite geocode cache + pre-seeded
// Tashkent landmarks. All lookups work without internet.
//
// To add new addresses: the admin panel can seed additional locations
// into the local cache.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'package:sqflite/sqflite.dart';

/// Riverpod provider.
final nominatimServiceProvider = Provider<NominatimService>((ref) {
  return NominatimService.instance;
});

/// One geocoding result.
class NominatimResult {
  final double lat;
  final double lng;
  final String displayName;
  final Map<String, dynamic> address;

  const NominatimResult({
    required this.lat,
    required this.lng,
    required this.displayName,
    this.address = const {},
  });

  LatLng get location => LatLng(lat, lng);

  factory NominatimResult.fromMap(Map<String, dynamic> m) => NominatimResult(
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        displayName: (m['displayName'] ?? '${m['lat']}, ${m['lng']}').toString(),
      );

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'displayName': displayName,
      };
}

/// Fully offline geocoding service backed by local SQLite cache.
class NominatimService {
  static final NominatimService instance = NominatimService._();
  NominatimService._();

  Database? _db;
  bool _seeded = false;

  Future<void> init(Database db) async {
    _db = db;
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS geocode_cache (
        query TEXT PRIMARY KEY,
        result_json TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    if (!_seeded) {
      await _seedTashkent();
      _seeded = true;
    }
  }

  /// Forward geocode — search address → coordinates.
  Future<List<NominatimResult>> search(
    String query, {
    int limit = 5,
    String? countryCode,
  }) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    // 1. Exact match in local cache
    final results = await _searchLocal(trimmed, limit: limit);
    if (results.isNotEmpty) return results;

    // 2. Fuzzy: partial match against cached landmarks
    return _fuzzyMatch(trimmed, limit: limit);
  }

  /// Reverse geocode — coordinates → address.
  Future<String> reverseGeocode(
    double lat,
    double lng, {
    String language = 'en',
  }) async {
    final key = 'rev_${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
    final cached = await _getCached(key);
    if (cached != null) return cached.displayName;

    // Find nearest landmark
    final nearest = _findNearest(lat, lng);
    if (nearest != null) {
      await _cacheResult(key, nearest);
      return nearest.displayName;
    }

    return '$lat, $lng';
  }

  // ── Local cache ──

  Future<List<NominatimResult>> _searchLocal(String q, {int limit = 5}) async {
    final rows = await _db?.query(
      'geocode_cache',
      where: 'LOWER(query) = ?',
      whereArgs: ['fwd_$q'],
      limit: limit,
    );
    if (rows == null || rows.isEmpty) return [];
    return rows.map((r) {
      final j = jsonDecode(r['result_json'] as String);
      return NominatimResult.fromMap(j);
    }).toList();
  }

  Future<List<NominatimResult>> _fuzzyMatch(String q, {int limit = 5}) async {
    final rows = await _db?.query(
      'geocode_cache',
      where: 'query LIKE ?',
      whereArgs: ['fwd_%'],
    );
    if (rows == null || rows.isEmpty) return [];

    final results = <NominatimResult>[];
    for (final r in rows) {
      final query = (r['query'] as String).replaceFirst('fwd_', '');
      final j = jsonDecode(r['result_json'] as String);
      final name = (j['displayName'] ?? '').toString().toLowerCase();
      if (name.contains(q) || query.toLowerCase().contains(q)) {
        results.add(NominatimResult.fromMap(j));
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  Future<NominatimResult?> _getCached(String key) async {
    final rows = await _db?.query(
      'geocode_cache',
      where: 'query = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows == null || rows.isEmpty) return null;
    final j = jsonDecode(rows.first['result_json'] as String);
    return NominatimResult.fromMap(j);
  }

  Future<void> _cacheResult(String key, NominatimResult r) async {
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

  NominatimResult? _findNearest(double lat, double lng) {
    double best = double.infinity;
    NominatimResult? bestResult;
    for (final lm in _tashkentLandmarks) {
      final d = _haversine(lat, lng, lm.lat, lm.lng);
      if (d < best) {
        best = d;
        bestResult = lm;
      }
    }
    // Only return if within 500m
    return (best < 500) ? bestResult : null;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * 3.141592653589793 / 180;
    final dLon = (lon2 - lon1) * 3.141592653589793 / 180;
    final a = _s(dLat / 2) * _s(dLat / 2) +
        _c(lat1 * 3.141592653589793 / 180) *
            _c(lat2 * 3.141592653589793 / 180) *
            _s(dLon / 2) * _s(dLon / 2);
    return R * 2 * _atan22(_sq(a), _sq(1 - a));
  }



  // ── Tashkent landmarks (fully offline) ──

  static final List<NominatimResult> _tashkentLandmarks = [
    NominatimResult(lat: 41.3111, lng: 69.2797, displayName: 'Площадь Амира Темура, Ташкент'),
    NominatimResult(lat: 41.3095, lng: 69.2661, displayName: 'Площадь Мустакиллик, Ташкент'),
    NominatimResult(lat: 41.3267, lng: 69.2352, displayName: 'Чорсу Базар, Ташкент'),
    NominatimResult(lat: 41.3120, lng: 69.2682, displayName: 'ЦУМ Ташкент'),
    NominatimResult(lat: 41.2916, lng: 69.2815, displayName: 'Северный вокзал, Ташкент'),
    NominatimResult(lat: 41.2611, lng: 69.2594, displayName: 'Южный вокзал, Ташкент'),
    NominatimResult(lat: 41.2580, lng: 69.2819, displayName: 'Аэропорт Ташкент'),
    NominatimResult(lat: 41.3128, lng: 69.2675, displayName: 'Бродвей (Сайилгох), Ташкент'),
    NominatimResult(lat: 41.3175, lng: 69.2490, displayName: 'Tashkent City, Ташкент'),
    NominatimResult(lat: 41.2948, lng: 69.2840, displayName: 'Паркентская улица, Ташкент'),
    NominatimResult(lat: 41.3053, lng: 69.2551, displayName: 'Сквер Амира Темура, Ташкент'),
    NominatimResult(lat: 41.2998, lng: 69.2426, displayName: 'Алайский базар, Ташкент'),
    NominatimResult(lat: 41.3319, lng: 69.2938, displayName: 'Ташкентский государственный университет'),
    NominatimResult(lat: 41.3457, lng: 69.2845, displayName: 'Телевышка, Ташкент'),
    NominatimResult(lat: 41.3033, lng: 69.2405, displayName: 'Минор, Ташкент'),
  ];

  Future<void> _seedTashkent() async {
    for (final lm in _tashkentLandmarks) {
      final name = lm.displayName.toLowerCase();
      await _cacheResult('fwd_$name', lm);
      // Also cache by short name
      final parts = name.split(',');
      if (parts.isNotEmpty) {
        await _cacheResult('fwd_${parts.first.trim()}', lm);
      }
    }
  }

  // Math aliases
  static double _s(double x) => sin(x);
  static double _c(double x) => cos(x);
  static double _sq(double x) => sqrt(x);
  static double _atan22(double y, double x) => atan2(y, x);
}
