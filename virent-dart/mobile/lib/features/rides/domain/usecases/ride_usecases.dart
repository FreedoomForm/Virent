import '../../../../core/error/api_exceptions.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/ride_repository.dart';
import '../entities/ride_entities.dart';

/// Starts a new ride.
///
/// Wraps [RideRepository.startRide]. Validates that a scooter id was
/// supplied before delegating to the repository so the user gets a clear
/// error message instead of an opaque 422.
class StartRideUseCase implements UseCase<RideModel, StartRideRequest> {
  /// Creates a [StartRideUseCase].
  StartRideUseCase(this._repository);

  final RideRepository _repository;

  @override
  Future<RideModel> call({StartRideRequest? params}) async {
    if (params == null || params.scooterId.isEmpty) {
      throw const ApiException('Scooter id is required to start a ride');
    }
    return _repository.startRide(params);
  }
}

/// Ends an ongoing ride.
///
/// Wraps [RideRepository.endRide]. Validates that a ride id was supplied
/// before delegating.
class EndRideUseCase implements UseCase<RideModel, EndRideRequest> {
  /// Creates an [EndRideUseCase].
  EndRideUseCase(this._repository);

  final RideRepository _repository;

  @override
  Future<RideModel> call({EndRideRequest? params}) async {
    if (params == null || params.rideId.isEmpty) {
      throw const ApiException('Ride id is required to end a ride');
    }
    return _repository.endRide(params);
  }
}

/// Fetches the rider's ride history.
///
/// Wraps [RideRepository.getHistory] and accepts an optional
/// [RideHistoryFilter] for pagination / status filtering.
class GetHistoryUseCase implements UseCase<List<RideModel>, RideHistoryFilter> {
  /// Creates a [GetHistoryUseCase].
  GetHistoryUseCase(this._repository);

  final RideRepository _repository;

  @override
  Future<List<RideModel>> call({RideHistoryFilter? params}) {
    return _repository.getHistory(filter: params ?? const RideHistoryFilter());
  }
}

/// Fetches the rider's currently ongoing ride, if any.
///
/// Convenience use case used by the home screen to deep-link into the
/// active-ride screen when the user reopens the app mid-ride.
class GetActiveRideUseCase implements NoParamsUseCase<RideModel?> {
  /// Creates a [GetActiveRideUseCase].
  GetActiveRideUseCase(this._repository);

  final RideRepository _repository;

  @override
  Future<RideModel?> call() => _repository.getActiveRide();
}
