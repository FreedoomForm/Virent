import '../../../../core/configs/services/api_client.dart';
import '../../../../core/error/api_exceptions.dart';
import '../../domain/entities/ride_entities.dart';
import '../models/ride_model.dart';

/// Contract every ride repository implementation must satisfy.
///
/// Declared in the data layer so use cases and providers can depend on the
/// abstraction rather than the concrete HTTP-backed implementation.
abstract class RideRepository {
  /// Starts a new ride for [request.scooterId].
  ///
  /// Returns the freshly created [RideModel] with `status == 'ongoing'`.
  Future<RideModel> startRide(StartRideRequest request);

  /// Ends the ride identified by [request.rideId].
  ///
  /// Returns the updated [RideModel] with the final cost and `endTime`
  /// populated.
  Future<RideModel> endRide(EndRideRequest request);

  /// Returns the current ongoing ride for the authenticated user, or
  /// `null` when no ride is active.
  Future<RideModel?> getActiveRide();

  /// Fetches the rider's ride history, optionally filtered by [filter].
  Future<List<RideModel>> getHistory({RideHistoryFilter filter = const RideHistoryFilter()});
}

/// Concrete [RideRepository] backed by the Virent [ApiClient].
class RideRepositoryImpl implements RideRepository {
  /// Creates a [RideRepositoryImpl].
  RideRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<RideModel> startRide(StartRideRequest request) async {
    try {
      final json = await _api.post('/trips/start', request.toJson());
      final payload = json['trip'] ?? json['ride'] ?? json['data'] ?? json;
      if (payload is! Map<String, dynamic>) {
        throw const ApiException('Malformed start-ride response');
      }
      return RideModel.fromJson(payload);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<RideModel> endRide(EndRideRequest request) async {
    try {
      final json = await _api.post('/trips/end', request.toJson());
      final payload = json['trip'] ?? json['ride'] ?? json['data'] ?? json;
      if (payload is! Map<String, dynamic>) {
        throw const ApiException('Malformed end-ride response');
      }
      return RideModel.fromJson(payload);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<RideModel?> getActiveRide() async {
    try {
      final json = await _api.get('/trips/active');
      final payload = json['trip'] ?? json['ride'];
      if (payload == null) return null;
      if (payload is! Map<String, dynamic>) return null;
      return RideModel.fromJson(payload);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<List<RideModel>> getHistory({
    RideHistoryFilter filter = const RideHistoryFilter(),
  }) async {
    try {
      final qs = filter.toQuery().entries.map((e) => '${e.key}=${e.value}').join('&');
      final json = await _api.get('/trips${qs.isEmpty ? '' : '?$qs'}');
      final raw = json['trips'] ?? json['rides'] ?? json['data'];
      if (raw is! List) return const [];
      return raw
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }
}
