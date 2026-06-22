import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/configs/services/api_client.dart';
import '../../../../core/configs/services/storage_service.dart';
import '../../../../core/error/api_exceptions.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/usecases/auth_usecases.dart';

/// Lifecycle states the auth feature can be in.
enum AuthStatus {
  /// Before [AuthNotifier.restoreSession] has resolved.
  initial,

  /// A network request is in-flight.
  loading,

  /// A valid session exists (token + user cached).
  authenticated,

  /// No session — the user must sign in.
  unauthenticated,

  /// The last operation failed; see [AuthState.error].
  error,
}

/// Immutable snapshot of the auth feature.
class AuthState {
  /// Current lifecycle status.
  final AuthStatus status;

  /// The authenticated user, when [status] is [AuthStatus.authenticated].
  final AuthUser? user;

  /// Cached access token (also persisted to SharedPreferences).
  final String? token;

  /// Cached refresh token, when available.
  final String? refreshToken;

  /// Human readable error message, when [status] is [AuthStatus.error].
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.refreshToken,
    this.error,
  });

  /// Convenience accessor.
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  /// Initial state.
  static const AuthState initial = AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? token,
    String? refreshToken,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      error: error,
    );
  }

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.fullName}, hasError: ${error != null})';
}

/// Whether the auth screen is in login or register mode.
enum AuthMode { login, register }

/// Singleton [ApiClient] used across the auth feature.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Singleton [StorageService].
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provides the concrete [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthRepositoryImpl(api, storage);
});

// ---- Use case providers ---------------------------------------------------
final loginWithPhoneUseCaseProvider = Provider<LoginWithPhoneUseCase>((ref) {
  return LoginWithPhoneUseCase(ref.watch(authRepositoryProvider));
});

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  return VerifyOtpUseCase(ref.watch(authRepositoryProvider));
});

final registerUserUseCaseProvider = Provider<RegisterUserUseCase>((ref) {
  return RegisterUserUseCase(ref.watch(authRepositoryProvider));
});

final saveUserUseCaseProvider = Provider<SaveUserUseCase>((ref) {
  return SaveUserUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  return RestoreSessionUseCase(ref.watch(authRepositoryProvider));
});

/// Login / register toggle shown on the auth screen.
final authModeProvider = StateProvider<AuthMode>((ref) => AuthMode.login);

/// Holds the verification id returned by [sendOtp] so the OTP screen can
/// pass it back during verification.
final verificationIdProvider = StateProvider<String?>((ref) => null);

/// Holds the phone number currently being verified (for resend + display).
final pendingPhoneProvider = StateProvider<String?>((ref) => null);

/// The main auth state notifier.
///
/// Exposes high-level actions ([sendOtp], [verifyOtp], [loginWithEmail],
/// [register], [logout], [restoreSession]) that update a single [AuthState].
/// Network / parsing errors are caught and surfaced via
/// [AuthStatus.error] + [AuthState.error] so the UI never sees an exception.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

/// Controls the [AuthState] for the whole app.
class AuthNotifier extends StateNotifier<AuthState> {
  /// Creates an [AuthNotifier] wired to the provided [ref].
  AuthNotifier(this._ref) : super(AuthState.initial);

  final Ref _ref;

  AuthRepository get _repository => _ref.read(authRepositoryProvider);

  /// Hydrates the auth state from local storage. Should be called once at
  /// app start. Never throws.
  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await _ref.read(restoreSessionUseCaseProvider)();
      if (user != null) {
        final token =
            await _ref.read(storageServiceProvider).getString(StorageKeys.authToken);
        final refresh = await _ref
            .read(storageServiceProvider)
            .getString(StorageKeys.refreshToken);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          token: token,
          refreshToken: refresh,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e is AppException ? e.message : e.toString(),
      );
    }
  }

  /// Requests an OTP for [phoneNumber]. On success stores the verification id
  /// and pending phone so the OTP screen can use them.
  Future<OtpResponse> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response =
          await _ref.read(loginWithPhoneUseCaseProvider)(
              params: LoginRequest.phone(phoneNumber));
      _ref.read(verificationIdProvider.notifier).state =
          response.verificationId;
      _ref.read(pendingPhoneProvider.notifier).state = phoneNumber;
      state = const AuthState(status: AuthStatus.unauthenticated);
      return response;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: e is AppException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  /// Verifies the OTP the user typed in. On success transitions to
  /// [AuthStatus.authenticated].
  Future<VerifyOtpResponse> verifyOtp(String otp) async {
    final phone = _ref.read(pendingPhoneProvider);
    final verificationId = _ref.read(verificationIdProvider) ?? '';
    if (phone == null) {
      const message = 'No pending phone number — request a code first';
      state = const AuthState(status: AuthStatus.error, error: message);
      throw const AuthException(message);
    }
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _ref.read(verifyOtpUseCaseProvider)(
        params: VerifyOtpParams(
          phoneNumber: phone,
          verificationId: verificationId,
          otp: otp,
        ),
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
        token: response.token,
        refreshToken: response.refreshToken,
      );
      // Clear pending verification data.
      _ref.read(verificationIdProvider.notifier).state = null;
      return response;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: e is AppException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  /// Performs an email + password login.
  Future<LoginResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _repository.loginWithEmail(
        LoginRequest.credentials(email: email, password: password),
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
        token: response.token,
        refreshToken: response.refreshToken,
      );
      return response;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: e is AppException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  /// Registers a new account and immediately triggers an OTP for the phone.
  Future<String> register(CreateUserRequest request) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final message = await _ref.read(registerUserUseCaseProvider)(
        params: request,
      );
      // Kick off the OTP flow so the user can verify their phone next.
      await sendOtp(request.phoneNumber);
      return message;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: e is AppException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  /// Logs the current user out and clears local credentials.
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await _ref.read(logoutUseCaseProvider)();
    } catch (_) {
      // Logout must always succeed locally.
    } finally {
      _ref.read(verificationIdProvider.notifier).state = null;
      _ref.read(pendingPhoneProvider.notifier).state = null;
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Resets the error state back to [AuthStatus.unauthenticated].
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

// ---- Derived selectors ----------------------------------------------------

/// The currently authenticated user, or `null`.
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

/// Whether a session is currently active.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

/// Whether an auth operation is currently in-flight.
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoading;
});
