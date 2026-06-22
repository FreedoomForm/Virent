// directions_service.dart — High-level directions facade.
//
// Wraps the low-level [OsrmService] in a presentation-friendly API: the
// returned [RouteResult] already carries pre-formatted duration /
// distance strings so widgets (bottom sheets, route planning cards) can
// render the data without re-implementing formatting.
//
// Two profiles are exposed:
//
//   * [getWalkingRoute] — uses OSRM's `foot` profile. Used by the
//     [SelectedScooterSheet] to show "5 min walk, 320 m" alongside a
//     selected scooter.
//   * [getCyclingRoute] — uses OSRM's `bicycle` profile. Used by the
//     route planning screen for the post-unlock leg of the journey.
//
// Both methods require a self-hosted OSRM instance with the appropriate
// profile loaded (the public demo server only ships `driving`). When the
// demo server is in use the call will throw — callers should catch and
// fall back to a straight-line / haversine estimate.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/osrm_service.dart';

/// Immutable, presentation-ready route result.
class RouteResult {
  /// Creates a [RouteResult].
  const RouteResult({
    required this.points,
    required this.durationSec,
    required this.distanceM,
  });

  /// Ordered route vertices (WGS84 lat/lng), start first.
  final List<LatLng> points;

  /// Estimated travel time in seconds.
  final int durationSec;

  /// On-road distance in metres.
  final double distanceM;

  /// `true` when the response carried no usable geometry.
  bool get isEmpty => points.isEmpty;

  /// Human-readable duration, e.g. `"5 min"` or `"1h 12 min"`.
  String get formattedDuration {
    final minutes = (durationSec / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return '${hours}h ${remaining}min';
  }

  /// Human-readable distance, e.g. `"320 m"` or `"1.4 km"`.
  String get formattedDistance {
    final km = distanceM / 1000;
    if (km < 1) return '${distanceM.round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  String toString() =>
      'RouteResult($formattedDistance, $formattedDuration, ${points.length} pts)';
}

/// Riverpod provider exposing a singleton [DirectionsService] wired to the
/// ambient [osrmServiceProvider].
final directionsServiceProvider = Provider<DirectionsService>((ref) {
  return DirectionsService(ref.watch(osrmServiceProvider));
});

/// High-level directions service combining OSRM with presentation helpers.
class DirectionsService {
  /// Creates a [DirectionsService] backed by [osrm].
  DirectionsService(this._osrm);

  final OsrmService _osrm;

  /// Plans a walking route from [from] to [to].
  ///
  /// Throws [ApiException] when the OSRM server rejects the request or
  /// returns a non-`Ok` code. The returned [RouteResult] always carries
  /// the full geometry (possibly empty on failure) plus the formatted
  /// duration / distance strings.
  Future<RouteResult> getWalkingRoute(LatLng from, LatLng to) async {
    final route = await _osrm.getRoute(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
      profile: OsrmProfile.foot,
    );
    return RouteResult(
      points: route.geometry,
      durationSec: route.durationSec,
      distanceM: route.distanceM,
    );
  }

  /// Plans a cycling route from [from] to [to].
  ///
  /// Same semantics as [getWalkingRoute] but uses OSRM's `bicycle`
  /// profile, which prefers cycleways and avoids motorways.
  Future<RouteResult> getCyclingRoute(LatLng from, LatLng to) async {
    final route = await _osrm.getRoute(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
      profile: OsrmProfile.bicycle,
    );
    return RouteResult(
      points: route.geometry,
      durationSec: route.durationSec,
      distanceM: route.distanceM,
    );
  }

  /// Plans a driving route from [from] to [to] — used by the support /
  /// juicer flows when a van is collecting scooters.
  Future<RouteResult> getDrivingRoute(LatLng from, LatLng to) async {
    final route = await _osrm.getRoute(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
      profile: OsrmProfile.driving,
    );
    return RouteResult(
      points: route.geometry,
      durationSec: route.durationSec,
      distanceM: route.distanceM,
    );
  }
}
