// ride_tracker.dart — Real-time GPS route tracking during a ride.
//
// Ported from Lime-RNMapbox's `RideProvider` and re-implemented on top of
// the Geolocator + flutter_map stack. The tracker owns a high-accuracy
// position stream while a ride is in progress, appends each new fix to an
// in-memory route polyline, and notifies its listeners so the UI can
// redraw the live route and stats in real time.
//
// Usage:
//   final tracker = RideTracker();
//   tracker.addListener(() => updateUi(tracker.stats));
//   await tracker.startTracking();
//   ... rider rides ...
//   final route = await tracker.stopTracking();
//   tracker.dispose();

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Immutable snapshot of the running ride stats.
///
/// Computed on every position update so listeners always see a fresh
/// value (e.g. for the bottom-sheet timer).
class RideStats {
  /// Creates a [RideStats].
  const RideStats({
    this.totalDistanceM = 0,
    this.durationSec = 0,
    this.averageSpeedKmh = 0,
    this.pointCount = 0,
  });

  /// Sum of the great-circle distances between consecutive GPS fixes, in
  /// metres.
  final double totalDistanceM;

  /// Elapsed seconds since [RideTracker.startTracking] was called.
  final int durationSec;

  /// Average speed derived from [totalDistanceM] / [durationSec], in
  /// kilometres per hour.
  final double averageSpeedKmh;

  /// Number of GPS fixes recorded so far.
  final int pointCount;

  /// Convenience: [totalDistanceM] expressed in kilometres.
  double get distanceKm => totalDistanceM / 1000;

  @override
  String toString() =>
      'RideStats(distance=${distanceKm.toStringAsFixed(2)}km, '
      'duration=${durationSec}s, avg=${averageSpeedKmh.toStringAsFixed(1)}km/h, '
      'points=$pointCount)';
}

/// Riverpod-scoped [RideTracker] for the currently active ride.
///
/// `autoDispose` ensures a fresh tracker is built each time the active
/// ride screen mounts and torn down (along with its position
/// subscription) when the rider navigates away — there is no need to
/// remember to call `dispose()` manually. `ChangeNotifierProvider`
/// automatically calls [RideTracker.dispose] when the provider is
/// disposed.
final rideTrackerProvider =
    ChangeNotifierProvider.autoDispose<RideTracker>((ref) {
  return RideTracker();
});

/// Records the rider's GPS trace during a ride.
///
/// The tracker is a [ChangeNotifier]: call [addListener] to receive a
/// notification on every position update (and on lifecycle transitions
/// like start / stop). The current state is always available via
/// [route], [stats], [isTracking] and [startedAt].
///
/// All GPS work happens on the platform's background location thread —
/// Geolocator hands us a `Position` on a platform channel, we compute
/// the incremental distance via [Geolocator.distanceBetween] (haversine)
/// and store the cumulative result. No UI work blocks the GPS stream.
class RideTracker extends ChangeNotifier {
  /// Distance (in metres) the rider must travel before a new fix is
  /// emitted by Geolocator. 30 m matches Lime's filter and balances
  /// battery life against polyline smoothness.
  static const int distanceFilterMeters = 30;

  /// Ordered list of recorded GPS fixes (start first, latest last).
  final List<LatLng> _route = <LatLng>[];

  /// Active Geolocator subscription, `null` when not tracking.
  StreamSubscription<Position>? _subscription;

  /// Wall-clock time the ride started (UTC), `null` before
  /// [startTracking] is called.
  DateTime? _startedAt;

  /// Wall-clock time the ride stopped (UTC), `null` until
  /// [stopTracking] is called.
  DateTime? _stoppedAt;

  /// Running total of on-road distance, in metres.
  double _totalDistance = 0;

  /// Last recorded fix — used to compute the incremental distance.
  LatLng? _lastPoint;

  /// `true` between [startTracking] and [stopTracking].
  bool _tracking = false;

  /// Unmodifiable view of the recorded route so far.
  List<LatLng> get route => List.unmodifiable(_route);

  /// `true` while the tracker is actively listening to GPS updates.
  bool get isTracking => _tracking;

  /// When tracking started, or `null`.
  DateTime? get startedAt => _startedAt;

  /// When tracking stopped, or `null` (still `null` while tracking).
  DateTime? get stoppedAt => _stoppedAt;

  /// The most recent fix, or `null` before the first GPS event arrives.
  LatLng? get lastPoint => _lastPoint;

  /// Current [RideStats] — recomputed on every read so the duration
  /// keeps ticking even between position updates.
  RideStats get stats => _currentStats();

  /// Starts GPS tracking.
  ///
  /// Returns `true` when the stream was successfully started (or was
  /// already running). Returns `false` when location services are off or
  /// the rider denied permission — callers should fall back to a
  /// "location required" prompt in that case.
  ///
  /// Calling [startTracking] twice in a row is a no-op (the second call
  /// returns `true` without restarting the stream).
  Future<bool> startTracking() async {
    if (_tracking) return true;

    // Permission gate — mirrors LocationNotifier.requestAndStart().
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('RideTracker: location services disabled');
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('RideTracker: permission denied');
      return false;
    }

    // Reset state for a fresh ride.
    _route.clear();
    _totalDistance = 0;
    _lastPoint = null;
    _startedAt = DateTime.now().toUtc();
    _stoppedAt = null;
    _tracking = true;
    notifyListeners();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );
    _subscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(
      _onPosition,
      onError: (Object error) {
        // Surface the error in debug builds but keep the tracker alive —
        // a single bad fix should not abort the whole ride.
        debugPrint('RideTracker position error: $error');
      },
    );

    // Try to seed the route with the last known position so the UI shows
    // a marker immediately rather than waiting for the first streamed
    // fix (which can take a few seconds on cold starts).
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && _tracking) _onPosition(last);
    } catch (_) {
      // getLastKnownPosition can fail on some emulators — ignore.
    }
    return true;
  }

  /// Stops GPS tracking and returns the final route.
  ///
  /// Safe to call when not tracking — returns the empty route in that
  /// case.
  Future<List<LatLng>> stopTracking() async {
    if (!_tracking) return List.unmodifiable(_route);
    _tracking = false;
    _stoppedAt = DateTime.now().toUtc();
    await _subscription?.cancel();
    _subscription = null;
    notifyListeners();
    return List.unmodifiable(_route);
  }

  /// Handles one streamed position update.
  void _onPosition(Position position) {
    if (!_tracking) return;
    final point = LatLng(position.latitude, position.longitude);
    if (_lastPoint != null) {
      _totalDistance += Geolocator.distanceBetween(
        _lastPoint!.latitude,
        _lastPoint!.longitude,
        point.latitude,
        point.longitude,
      );
    }
    _route.add(point);
    _lastPoint = point;
    notifyListeners();
  }

  /// Builds the current [RideStats] snapshot.
  RideStats _currentStats() {
    final end = _stoppedAt ?? DateTime.now().toUtc();
    final duration =
        _startedAt == null ? 0 : end.difference(_startedAt!).inSeconds;
    final avgKmh =
        duration > 0 ? (_totalDistance / duration) * 3.6 : 0.0;
    return RideStats(
      totalDistanceM: _totalDistance,
      durationSec: duration,
      averageSpeedKmh: avgKmh,
      pointCount: _route.length,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _tracking = false;
    super.dispose();
  }
}
