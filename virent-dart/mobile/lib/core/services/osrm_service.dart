// osrm_service.dart — local-only routing for Virent.
//
// No external services. Uses straight-line distance calculation (Haversine)
// for scooter routing. For road-level routing, self-host OSRM Docker image
// and point baseUrl at your local instance.

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

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

/// Local-only routing service.
/// Uses straight-line distance for short scooter trips (accurate enough
/// for < 5 km trips in Tashkent).
class OsrmService {
  OsrmService();

  /// Returns a straight-line route between two coordinates.
  Future<OsrmRoute> getRoute(
    double fromLat, double fromLng,
    double toLat, double toLng, {
    OsrmProfile profile = OsrmProfile.driving,
  }) async {
    final dist = _haversine(fromLat, fromLng, toLat, toLng);
    // Assume 20 km/h average scooter speed → m/s
    final speedMs = (profile == OsrmProfile.foot) ? 1.4 : 5.6;
    final durationSec = (dist / speedMs).round();

    return OsrmRoute(
      geometry: [LatLng(fromLat, fromLng), LatLng(toLat, toLng)],
      durationSec: durationSec,
      distanceM: dist,
    );
  }

  /// Returns straight-line segments for GPS points (no road snapping).
  Future<OsrmRoute> matchRoute(
    List<LatLng> gpsPoints, {
    OsrmProfile profile = OsrmProfile.driving,
  }) async {
    if (gpsPoints.length < 2) {
      return const OsrmRoute(geometry: [], durationSec: 0, distanceM: 0);
    }
    double totalDist = 0;
    for (int i = 1; i < gpsPoints.length; i++) {
      totalDist += _haversine(
        gpsPoints[i-1].latitude, gpsPoints[i-1].longitude,
        gpsPoints[i].latitude, gpsPoints[i].longitude,
      );
    }
    final speedMs = 5.6;
    return OsrmRoute(
      geometry: List.unmodifiable(gpsPoints),
      durationSec: (totalDist / speedMs).round(),
      distanceM: totalDist,
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
