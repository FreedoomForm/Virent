import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/configs/services/api_client.dart';
import '../../../../core/error/api_exceptions.dart';
import '../../data/models/scooter_model.dart';
import '../../data/repositories/scooter_repository.dart';
import 'location_provider.dart';

/// Lifecycle states for the scooter list feature.
enum ScooterStatus {
  /// Before the first load.
  initial,

  /// A fetch is in-flight.
  loading,

  /// A list of scooters is available.
  ready,

  /// The last fetch failed — see [ScooterState.error].
  error,
}

/// Immutable snapshot of the scooter list feature.
class ScooterState {
  /// Current lifecycle status.
  final ScooterStatus status;

  /// The list of scooters nearest to the rider, when loaded.
  final List<ScooterModel> scooters;

  /// The currently selected scooter (drives the bottom sheet content).
  final ScooterModel? selected;

  /// Human readable error message, when [status] is [ScooterStatus.error].
  final String? error;

  const ScooterState({
    this.status = ScooterStatus.initial,
    this.scooters = const [],
    this.selected,
    this.error,
  });

  /// Initial state.
  static const ScooterState initial = ScooterState();

  ScooterState copyWith({
    ScooterStatus? status,
    List<ScooterModel>? scooters,
    ScooterModel? selected,
    String? error,
  }) {
    return ScooterState(
      status: status ?? this.status,
      scooters: scooters ?? this.scooters,
      selected: selected ?? this.selected,
      error: error,
    );
  }
}

/// Provides the singleton [ApiClient] used by the scooter repository.
///
/// Re-using the auth feature's [ApiClient] keeps a single token source of
/// truth across the app.
final scooterApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provides the concrete [ScooterRepository].
final scooterRepositoryProvider = Provider<ScooterRepository>((ref) {
  return ScooterRepositoryImpl(ref.watch(scooterApiClientProvider));
});

/// Provides the [ScooterNotifier] that drives the home map.
final scooterNotifierProvider =
    StateNotifierProvider<ScooterNotifier, ScooterState>((ref) {
  return ScooterNotifier(ref);
});

/// Controls the [ScooterState] for the home screen.
///
/// On construction the notifier kicks off an initial fetch using the
/// fallback Tashkent coordinates, then auto-refreshes every 15 seconds so
/// the map reflects new/removed scooters without the user pulling to
/// refresh. When the device position becomes available the notifier
/// re-fetches around the rider.
class ScooterNotifier extends StateNotifier<ScooterState> {
  /// Creates a [ScooterNotifier] wired to [ref].
  ScooterNotifier(this._ref) : super(ScooterState.initial) {
    _init();
  }

  final Ref _ref;
  Timer? _refreshTimer;
  ProviderSubscription<LocationState>? _locationSub;

  /// Auto-refresh interval for the scooter list.
  static const Duration refreshInterval = Duration(seconds: 15);

  void _init() {
    // Initial load using fallback coordinates.
    loadNearby();

    // Re-fetch whenever the device position changes meaningfully.
    _locationSub = _ref.listen(
      locationNotifierProvider,
      (_, next) {
        if (next.status == LocationStatus.ready && next.position != null) {
          loadNearby(
            lat: next.position!.latitude,
            lng: next.position!.longitude,
          );
        }
      },
    );
  }

  /// Fetches the scooters closest to `[lat, lng]` (or the fallback
  /// coordinates when none are supplied) and updates the state.
  Future<void> loadNearby({
    double lat = LocationNotifier.fallbackLat,
    double lng = LocationNotifier.fallbackLng,
  }) async {
    state = state.copyWith(status: ScooterStatus.loading, error: null);
    try {
      final repo = _ref.read(scooterRepositoryProvider);
      final scooters = await repo.getNearby(lat: lat, lng: lng);
      if (!mounted) return;
      final selected = _resolveSelected(scooters, state.selected);
      state = ScooterState(
        status: ScooterStatus.ready,
        scooters: scooters,
        selected: selected,
      );
      _startAutoRefresh(lat: lat, lng: lng);
    } catch (e) {
      if (!mounted) return;
      state = ScooterState(
        status: ScooterStatus.error,
        error: e is AppException ? e.message : e.toString(),
      );
    }
  }

  void _startAutoRefresh({
    double lat = LocationNotifier.fallbackLat,
    double lng = LocationNotifier.fallbackLng,
  }) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) async {
      try {
        final repo = _ref.read(scooterRepositoryProvider);
        final scooters = await repo.getNearby(lat: lat, lng: lng);
        if (!mounted) return;
        final selected = _resolveSelected(scooters, state.selected);
        state = state.copyWith(scooters: scooters, selected: selected);
      } catch (_) {
        // Auto-refresh failures are silently ignored — the user can pull to
        // refresh manually if the network recovers.
      }
    });
  }

  /// Selects a scooter so the bottom sheet shows its details.
  void selectScooter(ScooterModel scooter) {
    state = state.copyWith(selected: scooter);
  }

  /// Clears the current selection.
  void clearSelection() {
    state = state.copyWith(selected: null);
  }

  /// Forces an immediate refresh using the latest device position (or the
  /// fallback coordinates when permission was denied).
  Future<void> refresh() async {
    final loc = _ref.read(locationNotifierProvider);
    await loadNearby(
      lat: loc.position?.latitude ?? LocationNotifier.fallbackLat,
      lng: loc.position?.longitude ?? LocationNotifier.fallbackLng,
    );
  }

  /// Resolves which scooter should be selected after a refresh.
  ///
  /// Returns `null` when the list is empty, otherwise preserves the
  /// previously selected scooter (when it still exists) or falls back to
  /// the first scooter in the list.
  ScooterModel? _resolveSelected(
    List<ScooterModel> scooters,
    ScooterModel? previous,
  ) {
    if (scooters.isEmpty) return null;
    if (previous == null) return scooters.first;
    return scooters.firstWhere(
      (s) => s.id == previous.id,
      orElse: () => scooters.first,
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationSub?.close();
    super.dispose();
  }
}

/// Convenience provider returning only the available scooters.
final availableScootersProvider = Provider<List<ScooterModel>>((ref) {
  final state = ref.watch(scooterNotifierProvider);
  return state.scooters.where((s) => s.isAvailable).toList(growable: false);
});
