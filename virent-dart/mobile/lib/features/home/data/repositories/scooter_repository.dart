import '../../../../core/configs/services/api_client.dart';
import '../../../../core/error/api_exceptions.dart';
import '../models/scooter_model.dart';

/// Contract every scooter repository implementation must satisfy.
///
/// Declared in the data layer so the presentation layer (providers / use
/// cases) can depend on the abstraction rather than the concrete HTTP-backed
/// implementation. This makes it trivial to swap in a mock repository for
/// tests or a cached repository for offline mode.
abstract class ScooterRepository {
  /// Returns the scooters closest to `[lat, lng]`, nearest first.
  ///
  /// [radiusM] limits the search radius in metres (defaults to 2 km).
  Future<List<ScooterModel>> getNearby({
    required double lat,
    required double lng,
    int radiusM = 2000,
  });

  /// Fetches a single scooter by [id].
  ///
  /// Throws [NotFoundException] when the server cannot find the scooter.
  Future<ScooterModel> getById(String id);
}

/// Concrete [ScooterRepository] backed by the Virent [ApiClient].
///
/// Translates raw `Map<String, dynamic>` payloads from the API client into
/// strongly typed [ScooterModel]s and normalises any unexpected error into
/// the [AppException] hierarchy so callers can pattern-match a single
/// sealed type.
class ScooterRepositoryImpl implements ScooterRepository {
  /// Creates a [ScooterRepositoryImpl].
  ScooterRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<ScooterModel>> getNearby({
    required double lat,
    required double lng,
    int radiusM = 2000,
  }) async {
    try {
      final json = await _api.get(
        '/scooters/nearby?lat=$lat&lng=$lng&radius=$radiusM',
      );
      final raw = json['scooters'] ?? json['data'];
      if (raw is! List) {
        return const [];
      }
      return raw
          .map((e) => ScooterModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<ScooterModel> getById(String id) async {
    try {
      final json = await _api.get('/scooters/$id');
      final payload = json['scooter'] ?? json['data'] ?? json;
      if (payload is! Map<String, dynamic>) {
        throw const ApiException('Malformed scooter payload');
      }
      return ScooterModel.fromJson(payload);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }
}
