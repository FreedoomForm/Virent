import '../../../../core/configs/services/api_client.dart';
import '../../../../core/configs/services/storage_service.dart';
import '../../../../core/error/api_exceptions.dart';
import '../models/auth_models.dart';
import '../../domain/entities/auth_entities.dart';

/// Contract every auth repository implementation must satisfy.
///
/// Defined in the domain layer so use cases depend only on the abstraction,
/// never on the concrete [AuthRepositoryImpl] or its HTTP/SharedPreferences
/// dependencies.
abstract class AuthRepository {
  /// Sends a one-time password to [phoneNumber].
  ///
  /// Returns the [OtpResponse] (which carries the optional `verificationId`
  /// required by some backends).
  Future<OtpResponse> sendOtp(String phoneNumber);

  /// Verifies the OTP issued for [params.phoneNumber].
  ///
  /// On success returns a domain [VerifyOtpResponse] containing the JWT and
  /// the authenticated user.
  Future<VerifyOtpResponse> verifyOtp(VerifyOtpParams params);

  /// Performs a credential (email + password) login.
  Future<LoginResponse> loginWithEmail(LoginRequest request);

  /// Registers a brand new account.
  ///
  /// Returns the backend message (e.g. "User registered").
  Future<String> register(CreateUserRequest request);

  /// Refreshes the access token using [refreshToken].
  ///
  /// Returns the new [LoginResponse].
  Future<LoginResponse> refreshToken(String refreshToken);

  /// Logs the current session out, revoking the refresh token server-side.
  Future<void> logout();

  /// Explicitly persists an [AuthUser] + token pair locally.
  ///
  /// Used when the caller obtains the user out-of-band (e.g. deep-link login)
  /// and wants to cache it without going through the OTP flow.
  Future<void> saveUser({
    required String token,
    String? refreshToken,
    required AuthUser user,
  });

  /// Restores the previously persisted session, if any.
  ///
  /// Returns the [AuthUser] when a valid token & profile were found, `null`
  /// otherwise. Does **not** throw on missing data.
  Future<AuthUser?> restoreSession();
}

/// Concrete [AuthRepository] backed by the Virent [ApiClient] and
/// [StorageService].
///
/// Translates raw `Map<String, dynamic>` payloads from the API client into
/// domain entities and persists the session (token + user) to
/// SharedPreferences so it can be restored by [restoreSession].
class AuthRepositoryImpl implements AuthRepository {
  /// Creates an [AuthRepositoryImpl].
  AuthRepositoryImpl(this._api, this._storage);

  final ApiClient _api;
  final StorageService _storage;

  @override
  Future<OtpResponse> sendOtp(String phoneNumber) async {
    try {
      final json = await _api.post('/auth/phone/send-code', {
        'phone': phoneNumber,
        'purpose': 'login',
      });
      return OtpResponse.fromJson(json);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<VerifyOtpResponse> verifyOtp(VerifyOtpParams params) async {
    try {
      // The Virent embedded server exposes /auth/phone/verify and accepts
      // {phone, code}. The legacy Node backend expects a verification_id
      // header; we pass it through when present.
      final json = await _api.post('/auth/phone/verify', {
        'phone': params.phoneNumber,
        'phoneNumber': params.phoneNumber,
        'code': params.otp,
        'verificationId': params.verificationId,
      });

      final model = VerifyOtpResponseModel.fromJson(json);
      final response = VerifyOtpResponse(
        token: model.token,
        refreshToken: model.refreshToken,
        user: model.user,
        message: model.message,
        isNewUser: model.isNewUser,
      );

      // Persist the freshly minted session so it survives restarts.
      await _persistSession(response.token,
          refreshToken: response.refreshToken, user: response.user);

      // Keep the API client authenticated for subsequent calls.
      _api.setToken(response.token);

      return response;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<LoginResponse> loginWithEmail(LoginRequest request) async {
    if (!request.isCredentialLogin) {
      throw const ValidationException(
          'Email and password are required for credential login');
    }
    try {
      final json = await _api.post('/auth/login', request.toJson());
      final response = LoginResponse.fromJson(json);
      if (response.token.isEmpty) {
        throw const ApiException('Login did not return a token');
      }
      final user = response.user ??
          AuthUser(
            id: '',
            phoneNumber: request.phoneNumber ?? '',
            email: request.email,
          );
      await _persistSession(response.token,
          refreshToken: response.refreshToken, user: user);
      _api.setToken(response.token);
      return response;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<String> register(CreateUserRequest request) async {
    try {
      final json = await _api.post('/auth/register', request.toJson());
      return (json['message'] ?? json['data']?['message'] ?? 'Registered')
          .toString();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<LoginResponse> refreshToken(String refreshToken) async {
    try {
      final json = await _api.post('/auth/refresh', {
        'refresh_token': refreshToken,
      });
      final response = LoginResponse.fromJson(json);
      if (response.token.isEmpty) {
        throw const ApiException('Refresh did not return a token');
      }
      final existing = await _storage.getJson(StorageKeys.userJson);
      final user = response.user ??
          (existing != null ? AuthUser.fromJson(existing) : null) ??
          const AuthUser(id: '', phoneNumber: '');
      await _persistSession(response.token,
          refreshToken: response.refreshToken ?? refreshToken, user: user);
      _api.setToken(response.token);
      return response;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ApiException.fromError(e);
    }
  }

  @override
  Future<void> logout() async {
    final refresh = await _storage.getString(StorageKeys.refreshToken);
    try {
      // Best-effort server-side revocation; never block logout on a failed
      // network call.
      if (refresh != null && refresh.isNotEmpty) {
        await _api.post('/auth/logout', {'refresh_token': refresh});
      }
    } catch (_) {
      // Swallow — we always clear local state below.
    } finally {
      _api.setToken(null);
      await _storage.clearAuth();
    }
  }

  @override
  Future<void> saveUser({
    required String token,
    String? refreshToken,
    required AuthUser user,
  }) async {
    await _persistSession(token, refreshToken: refreshToken, user: user);
    _api.setToken(token);
  }

  @override
  Future<AuthUser?> restoreSession() async {
    final token = await _storage.getString(StorageKeys.authToken);
    if (token == null || token.isEmpty) return null;

    final userJson = await _storage.getJson(StorageKeys.userJson);
    if (userJson == null) return null;

    _api.setToken(token);
    return AuthUser.fromJson(userJson);
  }

  /// Persists the session (token + refresh token + user) to the local store.
  Future<void> _persistSession(
    String token, {
    String? refreshToken,
    required AuthUser user,
  }) async {
    await _storage.setString(StorageKeys.authToken, token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.setString(StorageKeys.refreshToken, refreshToken);
    }
    await _storage.setJson(StorageKeys.userJson, user.toJson());
    await _storage.setString(StorageKeys.userId, user.id);
    await _storage.setString(StorageKeys.userPhone, user.phoneNumber);
    await _storage.setString(StorageKeys.userFirstName, user.firstName);
    await _storage.setString(StorageKeys.userLastName, user.lastName);
    if (user.email != null) {
      await _storage.setString(StorageKeys.userEmail, user.email!);
    }
    await _storage.setBool(StorageKeys.isLoggedIn, true);
  }
}
