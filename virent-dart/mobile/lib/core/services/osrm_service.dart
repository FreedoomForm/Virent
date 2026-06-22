// osrm_service.dart — Open-Source Routing Machine (OSRM) client.
//
// Free, key-less alternative to Google / Mapbox Directions. The OSRM project
// (https://project-osrm.org/) ships a public demo server at
// `router.project-osrm.org` that anyone can use without registration. For
// production deployments — or to enable walking / cycling profiles — the
// project ships a first-class Docker image so a fleet operator can host their
// own instance and point [OsrmService.baseUrl] at it.
//
// Endpoints used:
//   * `GET /route/v1/{profile}/{coords}?overview=full&geometries=geojson`
//     Returns one or more routes between the supplied coordinates. We always
//     take the first (fastest) route.
//   * `GET /match/v1/{profile}/{coords}?overview=full&geometries=geojson`
//     Map-matches a noisy GPS trace onto the road network — used by the ride
//     tracker to "snap" recorded points to actual streets.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../error/api_exceptions.dart';

/// OSRM routing profiles. The public demo server only ships `driving`; a
/// self-hosted OSRM with the bundled `foot` and `bicycle` profiles (built
/// from OpenStreetMap data via `osrm-extract`) is required for the other
/// two.
///
/// The values mirror the URL segment expected by OSRM, so they must not be
/// renamed without updating the server-side configuration.
enum OsrmProfile {
  /// Car / scooter routing (default on the demo server).
  driving,

  /// Pedestrian / walking routing.
  foot,

  /// Bicycle routing.
  bicycle,
}

/// Immutable result of a single routing or map-matching call.
///
/// [geometry] is the decoded polyline as a list of [LatLng]s in
/// start-to-end order. [durationSec] is the estimated travel time in
/// seconds and [distanceM] the total on-road distance in metres.
class OsrmRoute {
  /// Creates an [OsrmRoute].
  const OsrmRoute({
    required this.geometry,
    required this.durationSec,
    required this.distanceM,
  });

  /// Ordered route vertices (WGS84 lat/lng).
  final List<LatLng> geometry;

  /// Estimated travel time in seconds.
  final int durationSec;

  /// On-road distance in metres.
  final double distanceM;

  /// `true` when the response carried no usable geometry.
  bool get isEmpty => geometry.isEmpty;
}

/// Riverpod provider exposing a singleton [OsrmService] pointed at the
/// public OSRM demo server.
///
/// Override this provider in `main.dart` (or a `ProviderScope` override)
/// to point at a self-hosted OSRM instance — typically:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     osrmServiceProvider.overrideWithValue(
///       OsrmService(baseUrl: 'https://routing.my-fleet.com'),
///     ),
///   ],
///   child: const VirentApp(),
/// )
/// ```
final osrmServiceProvider = Provider<OsrmService>((ref) {
  return OsrmService();
});

/// Thin HTTP client for an OSRM server.
///
/// All methods are non-throwing in spirit: any failure (network, parse,
/// non-`Ok` status code) is funnelled through [ApiException] so callers
/// can `try / catch` a single error hierarchy.
class OsrmService {
  /// Creates an [OsrmService].
  ///
  /// Pass [baseUrl] to point at a self-hosted OSRM instance. When omitted
  /// the public demo server (`router.project-osrm.org`) is used — fine for
  /// development but not recommended for production traffic.
  OsrmService({String? baseUrl})
      : baseUrl = (baseUrl ?? 'https://router.project-osrm.org').trim();

  /// Base URL of the OSRM server, without a trailing slash.
  final String baseUrl;

  /// Per-request timeout. OSRM is normally sub-second on the demo server.
  static const Duration _timeout = Duration(seconds: 10);

  /// Plans a route between two coordinates.
  ///
  /// [fromLat]/[fromLng] is the origin, [toLat]/[toLng] the destination.
  /// [profile] selects the routing graph — see [OsrmProfile] for the
  /// trade-offs.
  ///
  /// Returns the fastest route OSRM could find. An empty [OsrmRoute]
  /// (zero geometry / duration / distance) is returned when OSRM replies
  /// with `code: "Ok"` but no usable route (e.g. the points are on
  /// disconnected road networks).
  Future<OsrmRoute> getRoute(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng, {
    OsrmProfile profile = OsrmProfile.driving,
  }) async {
    final coords = '$fromLng,$fromLat;$toLng,$toLat';
    final uri = Uri.parse(
      '$baseUrl/route/v1/${profile.name}/$coords'
      '?overview=full&geometries=geojson&steps=false',
    );

    final res = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw ApiException(
        'OSRM routing failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return _parseRouteResponse(res.body);
  }

  /// Map-matches a noisy GPS trace onto the road network.
  ///
  /// The supplied [gpsPoints] should be ordered chronologically. OSRM
  /// returns one or more "matchings" — contiguous segments it could snap
  /// to the graph — and we return the first (longest) one. Gaps in the
  /// trace (e.g. GPS lost in a tunnel) may produce several matchings; the
  /// caller can re-invoke with a tighter time window if needed.
  ///
  /// Throws [ApiException] when fewer than two points are supplied (OSRM
  /// needs at least a start and an end) or when the server rejects the
  /// request.
  Future<OsrmRoute> matchRoute(
    List<LatLng> gpsPoints, {
    OsrmProfile profile = OsrmProfile.driving,
  }) async {
    if (gpsPoints.length < 2) {
      throw const ApiException(
        'Map matching requires at least 2 GPS points',
      );
    }
    // OSRM's default `--max-matching-points` is 100. Truncate defensively
    // so a long ride doesn't blow the URL length limit.
    final points = gpsPoints.length > 100
        ? gpsPoints.sublist(gpsPoints.length - 100)
        : gpsPoints;
    final coords =
        points.map((p) => '${p.longitude},${p.latitude}').join(';');

    final uri = Uri.parse(
      '$baseUrl/match/v1/${profile.name}/$coords'
      '?overview=full&geometries=geojson&steps=false&tidy=true',
    );

    final res = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw ApiException(
        'OSRM match failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return _parseMatchResponse(res.body);
  }

  /// Decodes a `/route/v1/...` JSON payload.
  OsrmRoute _parseRouteResponse(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final code = decoded['code']?.toString();
    if (code != null && code != 'Ok') {
      throw ApiException(
        'OSRM error: ${decoded['message'] ?? code}',
      );
    }
    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      return const OsrmRoute(geometry: [], durationSec: 0, distanceM: 0);
    }
    final route = routes.first as Map<String, dynamic>;
    return _routeFromJson(route);
  }

  /// Decodes a `/match/v1/...` JSON payload.
  OsrmRoute _parseMatchResponse(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final code = decoded['code']?.toString();
    if (code != null && code != 'Ok') {
      throw ApiException(
        'OSRM match error: ${decoded['message'] ?? code}',
      );
    }
    final matchings = decoded['matchings'];
    if (matchings is! List || matchings.isEmpty) {
      return const OsrmRoute(geometry: [], durationSec: 0, distanceM: 0);
    }
    final best = matchings.first as Map<String, dynamic>;
    return _routeFromJson(best);
  }

  /// Pulls the geometry / duration / distance out of a single route or
  /// matching object.
  OsrmRoute _routeFromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final points = <LatLng>[];
    if (geometry is Map<String, dynamic> &&
        geometry['type'] == 'LineString' &&
        geometry['coordinates'] is List) {
      for (final coord in geometry['coordinates'] as List) {
        if (coord is List && coord.length >= 2) {
          final lng = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          points.add(LatLng(lat, lng));
        }
      }
    }
    final duration = ((json['duration'] as num?) ?? 0).toDouble();
    final distance = ((json['distance'] as num?) ?? 0).toDouble();
    return OsrmRoute(
      geometry: List.unmodifiable(points),
      durationSec: duration.round(),
      distanceM: distance,
    );
  }
}
