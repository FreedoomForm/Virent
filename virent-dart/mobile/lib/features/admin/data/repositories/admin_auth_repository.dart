// admin_auth_repository.dart — Virent admin auth repository.
//
// Wraps every admin-only HTTP endpoint exposed by the embedded server:
//
//   POST /admin/login            email + password login (returns JWT + admin)
//   POST /admin/create           super_admin creates a new admin account
//   GET  /admin/list             list every admin account
//   DELETE /admin/delete/<id>    super_admin deletes an admin
//   PUT  /admin/permissions/<id> super_admin updates an admin's permissions
//
// Admins can also log in through the *same* phone-OTP flow as regular riders
// (POST /auth/phone/send-code + POST /auth/phone/verify). When the verified
// phone belongs to an admin the server includes an `is_admin` flag plus the
// admin record in the verify response; [AdminAuthRepository.fromOtpResponse]
// turns that into an [AdminLoginResponse] so the provider can hydrate the
// admin session without an extra round-trip.

import '../../../../core/configs/services/api_client.dart';
import '../../../../core/configs/services/storage_service.dart';
import '../../../../core/error/api_exceptions.dart';
import '../models/admin_user_model.dart';

/// Contract every admin auth repository must satisfy.
///
/// Defined as an abstract class (rather than an interface) so test doubles
/// can override individual methods without re-implementing the whole thing.
abstract class AdminAuthRepository {
  /// Performs an email + password admin login.
  ///
  /// On success the returned [AdminLoginResponse] contains the JWT token and
  /// the resolved [AdminUser]. Throws [UnauthorizedException] on bad
  /// credentials.
  Future<AdminLoginResponse> loginAdmin({
    required String email,
    required String password,
  });

  /// Creates a new admin account. Only callable by a `super_admin`.
  ///
  /// [role] must be one of `super_admin`, `admin`, `operator`. [permissions]
  /// is a list of dotted codes (see [AdminPermissions]); pass `['*']` for a
  /// super admin. Returns the freshly created [AdminUser] (without password).
  Future<AdminUser> createAdmin({
    required String email,
    required String name,
    required String password,
    required AdminRole role,
    String? phone,
    List<String> permissions = const [],
  });

  /// Lists every admin account registered on the server.
  Future<List<AdminUser>> listAdmins();

  /// Deletes the admin with the given [adminId]. Only callable by a
  /// `super_admin`.
  Future<void> deleteAdmin(String adminId);

  /// Replaces the permission list of the admin with [adminId]. Only callable
  /// by a `super_admin`.
  Future<AdminUser> updateAdminPermissions(
    String adminId,
    List<String> permissions,
  );

  /// Persists an admin session locally so it can be restored on the next
  /// app launch.
  Future<void> persistSession(AdminLoginResponse response);

  /// Restores the previously persisted admin session, if any.
  ///
  /// Returns `null` when no admin session was stored — callers should fall
  /// back to the regular user session in that case.
  Future<AdminUser?> restoreSession();

  /// Clears any cached admin session (called on logout).
  Future<void> clearSession();
}

/// Concrete [AdminAuthRepository] backed by the shared [ApiClient] and
/// [StorageService].
class AdminAuthRepositoryImpl implements AdminAuthRepository {
  /// Creates an [AdminAuthRepositoryImpl].
  AdminAuthRepositoryImpl(this._api, this._storage);

  /// Shared API client (same instance used by the rider auth repository so
  /// the bearer token set at login time is automatically attached).
  final ApiClient _api;

  /// Local storage facade used to persist / restore the admin session.
  final StorageService _storage;

  /// SharedPreferences key holding the JSON-serialised admin record.
  static const _kAdminJson = 'admin_user_json';

  /// SharedPreferences key holding the admin bearer token.
  static const _kAdminToken = 'admin_token';

  /// SharedPreferences key holding the admin refresh token (if any).
  static const _kAdminRefresh = 'admin_refresh_token';

  @override
  Future<AdminLoginResponse> loginAdmin({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const ValidationException('Email and password are required');
    }
    try {
      final json = await _api.post('/admin/login', {
        'email': email.trim(),
        'password': password,
      });
      final response = AdminLoginResponse.fromJson(json);
      if (response.token.isEmpty) {
        throw const ApiException('Admin login did not return a token');
      }
      _api.setToken(response.token);
      await persistSession(response);
      return response;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<AdminUser> createAdmin({
    required String email,
    required String name,
    required String password,
    required AdminRole role,
    String? phone,
    List<String> permissions = const [],
  }) async {
    if (email.trim().isEmpty || name.trim().isEmpty || password.isEmpty) {
      throw const ValidationException(
          'Email, name and password are required');
    }
    try {
      final json = await _api.post('/admin/create', {
        'email': email.trim(),
        'name': name.trim(),
        'password': password,
        'role': role.wire,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'permissions': permissions,
      });
      final adminJson = json['admin'] ?? json['data']?['admin'] ?? json;
      if (adminJson is! Map<String, dynamic>) {
        throw const ApiException('createAdmin: invalid response payload');
      }
      return AdminUser.fromJson(adminJson);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<List<AdminUser>> listAdmins() async {
    try {
      final json = await _api.get('/admin/list');
      final list = json['admins'] ?? json['data']?['admins'] ?? [];
      if (list is! List) {
        throw const ApiException('listAdmins: invalid response payload');
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(AdminUser.fromJson)
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<void> deleteAdmin(String adminId) async {
    if (adminId.isEmpty) {
      throw const ValidationException('adminId is required');
    }
    try {
      await _api.delete('/admin/delete/$adminId');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<AdminUser> updateAdminPermissions(
    String adminId,
    List<String> permissions,
  ) async {
    if (adminId.isEmpty) {
      throw const ValidationException('adminId is required');
    }
    try {
      final json = await _api.put('/admin/permissions/$adminId', {
        'permissions': permissions,
      });
      final adminJson = json['admin'] ?? json['data']?['admin'] ?? json;
      if (adminJson is! Map<String, dynamic>) {
        throw const ApiException(
            'updateAdminPermissions: invalid response payload');
      }
      return AdminUser.fromJson(adminJson);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<void> persistSession(AdminLoginResponse response) async {
    await _storage.setString(_kAdminToken, response.token);
    if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
      await _storage.setString(_kAdminRefresh, response.refreshToken!);
    }
    await _storage.setJson(_kAdminJson, response.admin.toJson());
    // Mark the global "logged in" flag so the router's redirect logic lets
    // the admin through to /admin/home. Without this the router would see
    // `isLoggedIn: false` and bounce the user back to /auth.
    await _storage.setBool(StorageKeys.isLoggedIn, true);
    // Also persist a minimal rider record so the redirect can detect the
    // admin role from `user_json` (used when the explicit `admin_token`
    // check is bypassed, e.g. on app cold-start before the admin auth
    // repository has been queried).
    await _storage.setJson(StorageKeys.userJson, {
      'id': response.admin.id,
      'phone': response.admin.phone ?? '',
      'email': response.admin.email,
      'name': response.admin.name,
      'firstName': response.admin.name,
      'lastName': '',
      'role': response.admin.role.wire,
      'status': 'active',
      'createdAt': response.admin.createdAt,
    });
    await _storage.setString(StorageKeys.authToken, response.token);
  }

  @override
  Future<AdminUser?> restoreSession() async {
    final token = await _storage.getString(_kAdminToken);
    if (token == null || token.isEmpty) return null;
    final json = await _storage.getJson(_kAdminJson);
    if (json == null) return null;
    _api.setToken(token);
    return AdminUser.fromJson(json);
  }

  @override
  Future<void> clearSession() async {
    await _storage.remove(_kAdminToken);
    await _storage.remove(_kAdminRefresh);
    await _storage.remove(_kAdminJson);
  }

  /// Converts a phone-OTP verify response (as returned by `/auth/phone/verify`)
  /// into an [AdminLoginResponse] when the verified phone belongs to an admin.
  ///
  /// Returns `null` when the response does not carry an `is_admin: true` flag
  /// — callers should treat that as "this is a regular rider, not an admin".
  ///
  /// This helper is `static` so the regular auth flow can call it without
  /// instantiating the repository.
  static AdminLoginResponse? fromOtpResponse(Map<String, dynamic> json) {
    final isAdmin = json['is_admin'] == true ||
        json['isAdmin'] == true ||
        json['data']?['is_admin'] == true ||
        json['data']?['isAdmin'] == true;
    if (!isAdmin) return null;
    return AdminLoginResponse.fromJson(json);
  }
}
