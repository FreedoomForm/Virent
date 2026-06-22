// osrm_service.dart — local OSRM routing for Virent.
//
// Default: connects to OSRM running locally on port 5000.
// Setup (one-time): download OSRM + Tashkent map data:
//   docker run -v ./osrm-data:/data ghcr.io/project-osrm/osrm-backend \\
//     osrm-extract -p /opt/car.lua /data/tashkent.osm.pbf
//   docker run -v ./osrm-data:/data ghcr.io/project-osrm/osrm-backend \\
//     osrm-partition /data/tashkent.osrm
//   docker run -p 5000:5000 -v ./osrm-data:/data \\
//     ghcr.io/project-osrm/osrm-backend osrm-routed --algorithm mld /data/tashkent.osrm
//
// For production: OSRM runs as Docker container on the same PC.
// Zero external dependencies — all routing is local.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../error/api_exceptions.dart';

enum OsrmProfile { driving, foot, bicycle }

class OsrmRoute {
  final List<LatLng> geometry;
  final int durationSec;
  final double distanceM;
  bool get isEmpty => geometry.isEmpty;
  const OsrmRoute({
    required this.geometry,
    required this.durationSec,
    required this.distanceM,
  });
}

final osrmServiceProvider = Provider<OsrmService>((ref) => OsrmService());

/// Local-first routing service.
///
/// Tries local OSRM (localhost:5000) first, falls back to straight-line
/// Haversine calculation. OSRM gives real road-level routing; Haversine
/// gives instant straight-line (good enough for short scooter trips).
class OsrmService {
  /// Base URL of local OSRM. Default: Docker container on same PC.
  final String baseUrl;

  OsrmService({this.baseUrl = 'http://localhost:5000'});

  static const _timeout = Duration(seconds: 5);

  /// Tries OSRM first, falls back to straight-line.
  Future<OsrmRoute> getRoute(
    double fromLat, double fromLng,
    double toLat, double toLng, {
    OsrmProfile profile = OsrmProfile.driving,
  }) async {
    // 1. Try local OSRM
    try {
      final route = await _osrmRoute(fromLat, fromLng, toLat, toLng, profile);
      if (!route.isEmpty && route.geometry.length >= 2) return route;
    } catch (_) {
      // OSRM not available — fall through to straight-line
    }

    // 2. Fallback: straight-line Haversine
    return _straightRoute(fromLat, fromLng, toLat, toLng, profile);
  }

  Future<OsrmRoute> matchRoute(
    List<LatLng> gpsPoints, {
    OsrmProfile profile = OsrmProfile.driving,
  }) async {
    if (gpsPoints.length < 2) {
      return const OsrmRoute(geometry: [], durationSec: 0, distanceM: 0);
    }

    // 1. Try local OSRM map-matching
    try {
      final points = gpsPoints.length > 100
          ? gpsPoints.sublist(gpsPoints.length - 100)
          : gpsPoints;
      final coords = points.map((p) => '${p.longitude},${p.latitude}').join(';');
      final uri = Uri.parse(
        '$baseUrl/match/v1/${profile.name}/$coords'
        '?overview=full&geometries=geojson&steps=false&tidy=true',
      );
      final res = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        if (decoded['code']?.toString() == 'Ok') {
          final matchings = decoded['matchings'];
          if (matchings is List && matchings.isNotEmpty) {
            return _parseOsrmJson(matchings.first as Map<String, dynamic>);
          }
        }
      }
    } catch (_) {}

    // 2. Fallback: cumulative straight-line
    double totalDist = 0;
    for (int i = 1; i < gpsPoints.length; i++) {
      totalDist += _haversine(
        gpsPoints[i-1].latitude, gpsPoints[i-1].longitude,
        gpsPoints[i].latitude, gpsPoints[i].longitude,
      );
    }
    return OsrmRoute(
      geometry: List.unmodifiable(gpsPoints),
      durationSec: (totalDist / 5.6).round(),
      distanceM: totalDist,
    );
  }

  // ── OSRM HTTP call ──

  Future<OsrmRoute> _osrmRoute(
    double fromLat, double fromLng,
    double toLat, double toLng,
    OsrmProfile profile,
  ) async {
    final coords = '$fromLng,$fromLat;$toLng,$toLat';
    final uri = Uri.parse(
      '$baseUrl/route/v1/${profile.name}/$coords'
      '?overview=full&geometries=geojson&steps=false',
    );
    final res = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('OSRM HTTP ${res.statusCode}');
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded['code']?.toString() != 'Ok') throw Exception('OSRM code: ${decoded['code']}');
    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) return const OsrmRoute(geometry: [], durationSec: 0, distanceM: 0);
    return _parseOsrmJson(routes.first as Map<String, dynamic>);
  }

  OsrmRoute _parseOsrmJson(Map<String, dynamic> json) {
    final points = <LatLng>[];
    final geom = json['geometry'];
    if (geom is Map<String, dynamic> && geom['coordinates'] is List) {
      for (final c in geom['coordinates'] as List) {
        if (c is List && c.length >= 2) {
          points.add(LatLng(
            (c[1] as num).toDouble(),
            (c[0] as num).toDouble(),
          ));
        }
      }
    }
    return OsrmRoute(
      geometry: points,
      durationSec: ((json['duration'] as num?) ?? 0).toDouble().round(),
      distanceM: ((json['distance'] as num?) ?? 0).toDouble(),
    );
  }

  // ── Straight-line fallback ──

  OsrmRoute _straightRoute(
    double fromLat, double fromLng,
    double toLat, double toLng,
    OsrmProfile profile,
  ) {
    final dist = _haversine(fromLat, fromLng, toLat, toLng);
    final speedMs = (profile == OsrmProfile.foot) ? 1.4 : 5.6;
    return OsrmRoute(
      geometry: [LatLng(fromLat, fromLng), LatLng(toLat, toLng)],
      durationSec: (dist / speedMs).round(),
      distanceM: dist,
    );
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
