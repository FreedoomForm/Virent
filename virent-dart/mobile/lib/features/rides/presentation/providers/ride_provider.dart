import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/configs/services/api_client.dart';
import '../../../../core/error/api_exceptions.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/ride_repository.dart';
import '../../domain/entities/ride_entities.dart';
import '../../domain/usecases/ride_usecases.dart';

/// Lifecycle states for the rides feature.
enum RideStatus {
  /// Before the first load.
  initial,

  /// A network operation is in-flight.
  loading,

  /// An active ride is available (or the history list is loaded).
  ready,

  /// The last operation failed — see [RideState.error].
  error,
}

/// Immutable snapshot of the rides feature.
class RideState {
  /// Current lifecycle status.
  final RideStatus status;

  /// The rider's currently ongoing ride, or `null` when none is active.
  final RideModel? activeRide;

  /// The rider's ride history (most-recent first).
  final List<RideModel> history;

  /// Human readable error message, when [status] is [RideStatus.error].
  final String? error;

  const RideState({
    this.status = RideStatus.initial,
    this.activeRide,
    this.history = const [],
    this.error,
  });

  /// Initial state.
  static const RideState initial = RideState();

  RideState copyWith({
    RideStatus? status,
    RideModel? activeRide,
    List<RideModel>? history,
    String? error,
  }) {
    return RideState(
      status: status ?? this.status,
      activeRide: activeRide ?? this.activeRide,
      history: history ?? this.history,
      error: error,
    );
  }

  /// `true` while a ride is currently in progress.
  bool get hasActiveRide => activeRide != null && activeRide!.isOngoing;
}

/// Provides the singleton [ApiClient] used by the ride repository.
final rideApiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Provides the concrete [RideRepository].
final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepositoryImpl(ref.watch(rideApiClientProvider));
});

// ---- Use case providers ----------------------------------------------------
final startRideUseCaseProvider = Provider<StartRideUseCase>((ref) {
  return StartRideUseCase(ref.watch(rideRepositoryProvider));
});

final endRideUseCaseProvider = Provider<EndRideUseCase>((ref) {
  return EndRideUseCase(ref.watch(rideRepositoryProvider));
});

final getHistoryUseCaseProvider = Provider<GetHistoryUseCase>((ref) {
  return GetHistoryUseCase(ref.watch(rideRepositoryProvider));
});

final getActiveRideUseCaseProvider = Provider<GetActiveRideUseCase>((ref) {
  return GetActiveRideUseCase(ref.watch(rideRepositoryProvider));
});

/// The main ride state notifier.
///
/// Exposes high-level actions ([startRide], [endRide], [loadHistory],
/// [refresh]) that update a single [RideState]. Network / parsing errors
/// are caught and surfaced via [RideStatus.error] + [RideState.error] so
/// the UI never sees an exception.
final rideNotifierProvider =
    StateNotifierProvider<RideNotifier, RideState>((ref) {
  return RideNotifier(ref);
});

/// Controls the [RideState] for the active-ride and history screens.
class RideNotifier extends StateNotifier<RideState> {
  /// Creates a [RideNotifier] wired to [ref].
  RideNotifier(this._ref) : super(RideState.initial);

  final Ref _ref;

  /// Starts a new ride for [scooterId] and stores it as the active ride.
  ///
  /// On success the caller typically navigates to the active-ride screen.
  Future<RideModel?> startRide({
    required String scooterId,
    double? startLat,
    double? startLng,
  }) async {
    state = state.copyWith(status: RideStatus.loading, error: null);
    try {
      final ride = await _ref.read(startRideUseCaseProvider)(
        params: StartRideRequest(
          scooterId: scooterId,
          startLat: startLat,
          startLng: startLng,
        ),
      );
      state = state.copyWith(
        status: RideStatus.ready,
        activeRide: ride,
        error: null,
      );
      return ride;
    } catch (e) {
      state = RideState(
        status: RideStatus.error,
        activeRide: state.activeRide,
        history: state.history,
        error: e is AppException ? e.message : e.toString(),
      );
      return null;
    }
  }

  /// Ends the currently active ride (or the ride identified by [rideId]).
  ///
  /// Returns the finalised ride on success so the caller can route to the
  /// payment screen.
  Future<RideModel?> endRide({
    String? rideId,
    double? endLat,
    double? endLng,
    String? parkingPhotoUrl,
  }) async {
    final id = rideId ?? state.activeRide?.id;
    if (id == null || id.isEmpty) {
      state = state.copyWith(
        status: RideStatus.error,
        error: 'No active ride to end',
      );
      return null;
    }
    state = state.copyWith(status: RideStatus.loading, error: null);
    try {
      final ride = await _ref.read(endRideUseCaseProvider)(
        params: EndRideRequest(
          rideId: id,
          endLat: endLat,
          endLng: endLng,
          parkingPhotoUrl: parkingPhotoUrl,
        ),
      );
      // Move the now-completed ride to the top of the history list and
      // clear the active ride.
      final updatedHistory = [ride, ...state.history];
      state = RideState(
        status: RideStatus.ready,
        activeRide: null,
        history: updatedHistory,
      );
      return ride;
    } catch (e) {
      state = RideState(
        status: RideStatus.error,
        activeRide: state.activeRide,
        history: state.history,
        error: e is AppException ? e.message : e.toString(),
      );
      return null;
    }
  }

  /// Loads the rider's history from the server.
  Future<void> loadHistory({RideHistoryFilter? filter}) async {
    state = state.copyWith(status: RideStatus.loading, error: null);
    try {
      final history = await _ref.read(getHistoryUseCaseProvider)(
        params: filter ?? const RideHistoryFilter(),
      );
      // Auto-detect an ongoing ride so the home screen can deep-link into
      // the active-ride screen on app launch.
      final ongoing =
          history.firstWhere((r) => r.isOngoing, orElse: () => RideModel.empty);
      state = RideState(
        status: RideStatus.ready,
        activeRide: ongoing.id.isEmpty ? state.activeRide : ongoing,
        history: history,
      );
    } catch (e) {
      state = RideState(
        status: RideStatus.error,
        activeRide: state.activeRide,
        history: state.history,
        error: e is AppException ? e.message : e.toString(),
      );
    }
  }

  /// Refreshes both the active ride and history.
  Future<void> refresh() async {
    try {
      final active = await _ref.read(getActiveRideUseCaseProvider)();
      if (!mounted) return;
      if (active != null) {
        state = state.copyWith(activeRide: active, status: RideStatus.ready);
      } else if (state.hasActiveRide) {
        // The ride was ended elsewhere — clear the active ride.
        state = state.copyWith(activeRide: null);
      }
    } catch (_) {
      // Active-ride lookup failures are non-fatal — fall through to the
      // history refresh below.
    }
    await loadHistory();
  }

  /// Clears the error state back to [RideStatus.ready] (or
  /// [RideStatus.initial] when no data is loaded yet).
  void clearError() {
    if (state.status != RideStatus.error) return;
    state = state.copyWith(
      status:
          state.activeRide != null || state.history.isNotEmpty
              ? RideStatus.ready
              : RideStatus.initial,
      error: null,
    );
  }
}

// ---- Derived selectors ----------------------------------------------------

/// The currently active ride, or `null`.
final activeRideProvider = Provider<RideModel?>((ref) {
  return ref.watch(rideNotifierProvider).activeRide;
});

/// Whether a ride operation is in-flight.
final rideLoadingProvider = Provider<bool>((ref) {
  return ref.watch(rideNotifierProvider).status == RideStatus.loading;
});

/// The rider's ride history.
final rideHistoryProvider = Provider<List<RideModel>>((ref) {
  return ref.watch(rideNotifierProvider).history;
});
