import '../../../../core/configs/services/api_client.dart';
import '../../../../core/configs/services/storage_service.dart';
import '../../../../core/error/api_exceptions.dart';
import '../models/user_profile_model.dart';

/// Contract for the profile data layer.
///
/// The profile feature needs four operations:
/// - [getProfile]       — read the authenticated user's full profile.
/// - [updateProfile]    — patch editable fields (name, email).
/// - [changePassword]   — exchange the current password for a new one.
/// - [getSessions]      — list the active sessions for the "Active sessions"
///   screen.
abstract class ProfileRepository {
  /// Returns the current user's profile.
  Future<UserProfileModel> getProfile();

  /// Updates the profile with [name] and / or [email].
  ///
  /// Returns the refreshed [UserProfileModel].
  Future<UserProfileModel> updateProfile({String? name, String? email});

  /// Changes the user's password.
  ///
  /// Returns `true` on success. Implementations should throw [ApiException]
  /// (or a subtype) on failure so callers can surface the message.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Returns the list of active sessions, current first.
  Future<List<SessionModel>> getSessions();
}

/// Concrete [ProfileRepository] backed by the Virent [ApiClient].
///
/// On successful profile fetches the repository also persists the JSON to
/// [StorageService] so the UI can hydrate instantly on the next launch.
class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _api;
  final StorageService _storage;

  /// Creates a repository wrapping [api] and [storage].
  ProfileRepositoryImpl([ApiClient? api, StorageService? storage])
      : _api = api ?? ApiClient(),
        _storage = storage ?? StorageService();

  @override
  Future<UserProfileModel> getProfile() async {
    final data = await _api.get('/users/me');
    final userJson = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : (data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data);
    final profile = UserProfileModel.fromJson(userJson);
    await _storage.setJson(StorageKeys.userJson, profile.toJson());
    return profile;
  }

  @override
  Future<UserProfileModel> updateProfile({
    String? name,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (email != null) body['email'] = email;
    if (body.isEmpty) {
      throw const ApiException('Nothing to update');
    }
    final data = await _api.put('/users/me', body);
    final userJson = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : (data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data);
    final profile = UserProfileModel.fromJson(userJson);
    await _storage.setJson(StorageKeys.userJson, profile.toJson());
    return profile;
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw const ApiException('Passwords cannot be empty');
    }
    if (newPassword.length < 6) {
      throw const ApiException('New password must be at least 6 characters');
    }
    await _api.post('/users/me/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    return true;
  }

  @override
  Future<List<SessionModel>> getSessions() async {
    final data = await _api.get('/users/me/sessions');
    final list = (data['sessions'] ??
            data['data'] ??
            const <dynamic>[]) as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(SessionModel.fromJson)
        .toList(growable: false);
  }
}
