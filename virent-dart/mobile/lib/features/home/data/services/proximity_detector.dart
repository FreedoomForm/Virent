// proximity_detector.dart — Detects when the rider is near a scooter.
//
// Ported from Lime-RNMapbox's `ScooterProvider` proximity logic and
// re-implemented on top of Geolocator. The detector keeps a 10 m
// distance-filtered position stream and computes the great-circle
// distance to a target scooter on every update. Two callbacks (with
// hysteresis) tell the UI when the rider crosses the threshold:
//
//   * [onNearby] fires once when the distance first drops below
//     `thresholdMeters` (default 100 m). The "Start journey" button on
//     the [SelectedScooterSheet] is gated on this signal.
//   * [onFar] fires once when the distance climbs back above
//     `thresholdMeters * 1.5`. The 1.5x hysteresis prevents the callbacks
//     from flickering on and off as the rider walks along the threshold.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Riverpod-scoped [ProximityDetector] for the home screen.
///
/// `autoDispose` ensures the position stream is torn down (along with
/// the detector itself) when the home screen is popped — there is no
/// need to remember to call `stopWatching()` manually.
/// `ChangeNotifierProvider` automatically calls [ProximityDetector.dispose]
/// when the provider is disposed.
final proximityDetectorProvider =
    ChangeNotifierProvider.autoDispose<ProximityDetector>((ref) {
  return ProximityDetector();
});

/// Watches the rider's distance from a single scooter.
///
/// Construct a fresh detector per selected scooter (or call
/// [watchProximity] with new coordinates) — the class is a
/// [ChangeNotifier] so the UI can listen for distance updates and
/// re-render the "you are 80 m away" hint in real time.
class ProximityDetector extends ChangeNotifier {
  /// Distance (in metres) the rider must travel before a new fix is
  /// emitted by Geolocator while proximity-watching. 10 m gives a smooth
  /// "you are X metres away" countdown without burning the battery.
  static const int distanceFilterMeters = 10;

  /// Active Geolocator subscription, `null` when not watching.
  StreamSubscription<Position>? _subscription;

  // ---- Target scooter -----------------------------------------------------
  double _scooterLat = 0;
  double _scooterLng = 0;

  /// Distance (in metres) below which the rider counts as "nearby".
  double _threshold = 100;

  /// Current great-circle distance to the scooter. [double.infinity]
  /// before the first fix arrives.
  double _currentDistance = double.infinity;

  /// Whether the rider is currently within the threshold.
  bool _isNearby = false;

  /// `true` between [watchProximity] and [stopWatching].
  bool _watching = false;

  /// Current great-circle distance to the scooter (metres).
  ///
  /// [double.infinity] until the first position fix arrives.
  double get currentDistance => _currentDistance;

  /// `true` when [currentDistance] < threshold (i.e. the rider can
  /// unlock the scooter).
  bool get isNearby => _isNearby;

  /// `true` while the position stream is active.
  bool get isWatching => _watching;

  /// Active threshold (metres) — the value passed to [watchProximity].
  double get threshold => _threshold;

  /// Fired once when the rider crosses into the threshold. Assign in
  /// [watchProximity].
  VoidCallback? onNearby;

  /// Fired once when the rider crosses out of the (hysteresis) threshold.
  /// Assign in [watchProximity].
  VoidCallback? onFar;

  /// Starts watching the rider's distance to the scooter at
  /// [scooterLat], [scooterLng].
  ///
  /// [thresholdMeters] is the "nearby" radius (default 100 m). [onNearby]
  /// fires when the distance drops below it, [onFar] when it climbs above
  /// `thresholdMeters * 1.5`. Both callbacks fire at most once per
  /// transition so the UI doesn't see a flood of events.
  ///
  /// Calling [watchProximity] again with new coordinates (or a new
  /// scooter) silently replaces the previous watch — no need to call
  /// [stopWatching] first.
  Future<void> watchProximity({
    required double scooterLat,
    required double scooterLng,
    double thresholdMeters = 100,
    VoidCallback? onNearby,
    VoidCallback? onFar,
  }) async {
    await stopWatching();

    _scooterLat = scooterLat;
    _scooterLng = scooterLng;
    _threshold = thresholdMeters;
    _currentDistance = double.infinity;
    _isNearby = false;
    _watching = true;
    this.onNearby = onNearby;
    this.onFar = onFar;
    notifyListeners();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('ProximityDetector: location services disabled');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('ProximityDetector: permission denied');
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );
    _subscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(_onPosition, onError: (Object error) {
      debugPrint('ProximityDetector stream error: $error');
    });

    // Seed with the last known position so the UI shows a real distance
    // immediately rather than "∞".
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && _watching) _onPosition(last);
    } catch (_) {
      // getLastKnownPosition can fail on some emulators — ignore.
    }
  }

  /// Stops the position stream and resets the detector.
  Future<void> stopWatching() async {
    if (!_watching && _subscription == null) return;
    _watching = false;
    await _subscription?.cancel();
    _subscription = null;
    _currentDistance = double.infinity;
    _isNearby = false;
    onNearby = null;
    onFar = null;
    notifyListeners();
  }

  /// Handles one streamed position update.
  void _onPosition(Position position) {
    if (!_watching) return;
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _scooterLat,
      _scooterLng,
    );
    _currentDistance = distance;

    final wasNearby = _isNearby;
    if (distance < _threshold) {
      _isNearby = true;
      if (!wasNearby) onNearby?.call();
    } else if (distance > _threshold * 1.5) {
      _isNearby = false;
      if (wasNearby) onFar?.call();
    }
    // Between `_threshold` and `_threshold * 1.5` we keep the previous
    // state — that's the hysteresis band.
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _watching = false;
    super.dispose();
  }
}
