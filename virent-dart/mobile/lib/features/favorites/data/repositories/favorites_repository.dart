import '../../../../core/configs/services/api_client.dart';
import '../models/favorite_model.dart';

/// Repository that fetches and mutates the user's saved places.
///
/// Wraps the `/favorites` REST endpoints. Returns typed [Favorite] objects
/// so the UI never has to touch raw JSON.
class FavoritesRepository {
  /// Creates a repository backed by [api] (or a fresh [ApiClient]).
  FavoritesRepository([ApiClient? api]) : _api = api ?? ApiClient();

  final ApiClient _api;

  /// Lists every saved place for the current user.
  Future<List<Favorite>> getFavorites() async {
    final data = await _api.get('/favorites');
    final list = (data['favorites'] as List? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(Favorite.fromJson)
        .toList();
    return list;
  }

  /// Saves a new place. Returns the created [Favorite] (with server id).
  Future<Favorite> addFavorite({
    required String name,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final data = await _api.post('/favorites', {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
    });
    final json = (data['favorite'] ?? data) as Map<String, dynamic>;
    return Favorite.fromJson(json);
  }

  /// Deletes the saved place with [favoriteId].
  Future<void> deleteFavorite(String favoriteId) =>
      _api.delete('/favorites/$favoriteId');
}
