import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/error/api_exceptions.dart';

/// Lifecycle states for the location stream.
enum LocationStatus {
  /// Before the first permission check / position fetch.
  initial,

  /// Currently requesting permission or the first fix.
  loading,

  /// A position is available.
  ready,

  /// The user denied location permission.
  denied,

  /// The user permanently denied location permission (must open settings).
  deniedForever,

  /// Location services are disabled at the OS level.
  serviceDisabled,

  /// Any other failure — see [LocationState.error].
  error,
}

/// Immutable snapshot of the location feature.
class LocationState {
  /// Current lifecycle status.
  final LocationStatus status;

  /// The latest device position, when [status] is [LocationStatus.ready].
  final Position? position;

  /// Human readable error message, when [status] is [LocationStatus.error].
  final String? error;

  const LocationState({
    this.status = LocationStatus.initial,
    this.position,
    this.error,
  });

  /// Initial state.
  static const LocationState initial = LocationState();

  LocationState copyWith({
    LocationStatus? status,
    Position? position,
    String? error,
  }) {
    return LocationState(
      status: status ?? this.status,
      position: position ?? this.position,
      error: error,
    );
  }
}

/// Provides a singleton [Geolocator]-based [LocationNotifier].
///
/// Exposes the current permission state and the latest device position. The
/// notifier keeps a live `StreamSubscription` so the UI updates as the
/// rider moves (used by the home map and the active-ride map).
final locationNotifierProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

/// Wraps `geolocator` so the rest of the app never has to deal with
/// permission booleans or stream plumbing directly.
class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState.initial);

  StreamSubscription<Position>? _subscription;
  StreamSubscription<ServiceStatus>? _serviceSub;

  /// Default coordinates used as a fallback when the device position is
  /// unavailable (Tashkent city centre).
  static const double fallbackLat = 41.3111;
  static const double fallbackLng = 69.2406;

  /// Requests permission (if needed) and starts the position stream.
  ///
  /// Returns `true` when a position is available at the end of the call.
  /// Never throws — failures are surfaced via [LocationState.error].
  Future<bool> requestAndStart() async {
    state = state.copyWith(status: LocationStatus.loading, error: null);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = const LocationState(
          status: LocationStatus.serviceDisabled,
          error: 'Location services are disabled',
        );
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        state = const LocationState(
          status: LocationStatus.denied,
          error: 'Location permission was denied',
        );
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        state = const LocationState(
          status: LocationStatus.deniedForever,
          error: 'Location permission is permanently denied',
        );
        return false;
      }

      // Kick off the live stream so the map follows the rider.
      await _startStream();
      return true;
    } catch (e) {
      state = LocationState(
        status: LocationStatus.error,
        error: e is AppException ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<void> _startStream() async {
    await _subscription?.cancel();
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // metres
    );
    _subscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        state = LocationState(
          status: LocationStatus.ready,
          position: position,
        );
      },
      onError: (Object e) {
        state = LocationState(
          status: LocationStatus.error,
          error: e.toString(),
        );
      },
    );

    // Also surface the last known position immediately so the UI doesn't
    // wait for the first stream event.
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        state = LocationState(
          status: LocationStatus.ready,
          position: last,
        );
      }
    } catch (_) {
      // getLastKnownPosition can fail on some emulators — fall through.
    }
  }

  /// Opens the OS settings app so the user can grant permission manually.
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Opens the OS location settings screen.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _serviceSub?.cancel();
    super.dispose();
  }
}

/// Convenience provider returning the latest position, or `null`.
final currentPositionProvider = Provider<Position?>((ref) {
  return ref.watch(locationNotifierProvider).position;
});

/// Convenience provider returning `true` when the device position is
/// available and the rider has granted permission.
final hasLocationPermissionProvider = Provider<bool>((ref) {
  final status = ref.watch(locationNotifierProvider).status;
  return status == LocationStatus.ready;
});
