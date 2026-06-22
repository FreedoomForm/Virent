// admin_auth_provider.dart — Riverpod providers powering the admin auth flow.
//
// Exposes a single [AdminAuthNotifier] (StateNotifierProvider) that drives the
// whole admin auth lifecycle:
//
//   initial      → before restoreSession() has resolved
//   loading      → a network request is in-flight
//   authenticated → a valid admin session is active
//   unauthenticated → no admin session
//   error        → last operation failed (see AdminAuthState.error)
//
// On a successful login (either via /admin/login or via the rider OTP flow
// when the verified phone belongs to an admin) the notifier stores the
// resolved [AdminUser] and the router's redirect logic ships the user to
// /admin/home instead of the rider home screen.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/configs/services/api_client.dart';
import '../../../../core/configs/services/storage_service.dart';
import '../../../../core/error/api_exceptions.dart';
import '../../../auth/data/models/auth_models.dart' show AuthUser;
import '../../data/models/admin_user_model.dart';
import '../../data/repositories/admin_auth_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart'
    show apiClientProvider, storageServiceProvider;

/// Lifecycle states the admin auth feature can be in.
enum AdminAuthStatus {
  /// Before [AdminAuthNotifier.restoreSession] has resolved.
  initial,

  /// A network request is in-flight.
  loading,

  /// A valid admin session is active.
  authenticated,

  /// No admin session — the user is either logged out or is a regular rider.
  unauthenticated,

  /// The last operation failed; see [AdminAuthState.error].
  error,
}

/// Immutable snapshot of the admin auth feature.
class AdminAuthState {
  /// Current lifecycle status.
  final AdminAuthStatus status;

  /// The authenticated admin, when [status] is [AdminAuthStatus.authenticated].
  final AdminUser? admin;

  /// Cached admin JWT access token (also persisted to SharedPreferences).
  final String? token;

  /// Cached admin JWT refresh token, when available.
  final String? refreshToken;

  /// Human-readable error message, when [status] is [AdminAuthStatus.error].
  final String? error;

  /// Creates an [AdminAuthState].
  const AdminAuthState({
    this.status = AdminAuthStatus.initial,
    this.admin,
    this.token,
    this.refreshToken,
    this.error,
  });

  /// Convenience accessor — `true` when an admin session is active.
  bool get isAuthenticated => status == AdminAuthStatus.authenticated;

  /// Convenience accessor — `true` when an auth operation is in-flight.
  bool get isLoading => status == AdminAuthStatus.loading;

  /// `true` when the active admin holds super privileges.
  bool get isSuperAdmin => admin?.isSuperAdmin ?? false;

  /// Initial state.
  static const AdminAuthState initial =
      AdminAuthState(status: AdminAuthStatus.initial);

  /// Returns a copy with the given fields overridden. `error` is reset to
  /// `null` unless explicitly passed.
  AdminAuthState copyWith({
    AdminAuthStatus? status,
    AdminUser? admin,
    String? token,
    String? refreshToken,
    String? error,
  }) {
    return AdminAuthState(
      status: status ?? this.status,
      admin: admin ?? this.admin,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      error: error,
    );
  }

  @override
  String toString() =>
      'AdminAuthState(status: $status, admin: ${admin?.email}, hasError: ${error != null})';
}

/// Provides the concrete [AdminAuthRepository].
///
/// Shares the global [ApiClient] + [StorageService] instances defined in the
/// auth feature so the bearer token set at login time is automatically
/// attached to every admin request.
final adminAuthRepositoryProvider = Provider<AdminAuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AdminAuthRepositoryImpl(api, storage);
});

/// The main admin auth state notifier.
///
/// Exposes high-level actions ([loginWithEmail], [hydrateFromOtp],
/// [logout], [restoreSession]) that update a single [AdminAuthState].
/// Network / parsing errors are caught and surfaced via
/// [AdminAuthStatus.error] + [AdminAuthState.error] so the UI never sees an
/// exception.
final adminAuthNotifierProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  return AdminAuthNotifier(ref);
});

/// Drives the [AdminAuthState] for the whole app.
class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  /// Creates an [AdminAuthNotifier] wired to the provided [ref].
  AdminAuthNotifier(this._ref) : super(AdminAuthState.initial);

  final Ref _ref;

  AdminAuthRepository get _repository =>
      _ref.read(adminAuthRepositoryProvider);

  /// Hydrates the admin auth state from local storage. Should be called once
  /// at app start (alongside the regular auth restore). Never throws — any
  /// failure simply leaves the state as [AdminAuthStatus.unauthenticated].
  ///
  /// Resolution order:
  ///   1. Admin-specific session (`admin_token` + `admin_user_json` keys)
  ///      written by `/admin/login`.
  ///   2. Regular rider session whose [AuthUser.role] is `admin` or
  ///      `super_admin` — set by `/auth/phone/verify` when the verified phone
  ///      belongs to an admin. In this case an [AdminUser] is synthesised
  ///      from the rider record so the admin home screen has a name + role
  ///      to display.
  Future<void> restoreSession() async {
    state = state.copyWith(status: AdminAuthStatus.loading, error: null);
    try {
      var admin = await _repository.restoreSession();
      admin ??= await _tryRestoreFromRiderSession();
      if (admin != null) {
        final token = await _ref
            .read(storageServiceProvider)
            .getString('admin_token');
        state = AdminAuthState(
          status: AdminAuthStatus.authenticated,
          admin: admin,
          token: token,
        );
      } else {
        state = const AdminAuthState(status: AdminAuthStatus.unauthenticated);
      }
    } catch (e) {
      // Best-effort: never block app startup on an admin session restore error.
      state = AdminAuthState(
        status: AdminAuthStatus.unauthenticated,
        error: e is AppException ? e.message : e.toString(),
      );
    }
  }

  /// Fallback used by [restoreSession] when no admin-specific session exists
  /// but the regular rider session belongs to an admin (OTP login flow).
  ///
  /// Reads `user_json` from storage, parses it into an [AuthUser], and — when
  /// the role is `admin` or `super_admin` — constructs an [AdminUser] and
  /// persists it via the repository so subsequent calls hit the fast path.
  Future<AdminUser?> _tryRestoreFromRiderSession() async {
    final storage = _ref.read(storageServiceProvider);
    final userJson = await storage.getJson(StorageKeys.userJson);
    if (userJson == null) return null;
    final AuthUser rider;
    try {
      rider = AuthUser.fromJson(userJson);
    } catch (_) {
      return null;
    }
    if (rider.role != 'admin' && rider.role != 'super_admin') return null;

    // Synthesise an AdminUser from the rider record. The wildcard permission
    // is granted to super_admin so [AdminUser.hasPermission] always passes;
    // regular admins get an empty list (they can still see the dashboard
    // tiles, just no manage-admins access).
    final admin = AdminUser(
      id: rider.id,
      email: rider.email ?? '',
      name: rider.fullName,
      role: adminRoleFromString(rider.role),
      permissions:
          rider.role == 'super_admin' ? const ['*'] : const <String>[],
      phone: rider.phoneNumber,
      createdAt: rider.createdAt ?? DateTime.now().toIso8601String(),
    );

    // Persist so subsequent restores hit the fast path. We deliberately do
    // NOT write `admin_token` — for OTP-based admin login the regular
    // `auth_token` is used and the server's `_requireAdmin` falls back to
    // its in-memory `currentAdmin` pointer.
    try {
      await storage.setJson('admin_user_json', admin.toJson());
      // Make sure the API client is authenticated with whatever token we
      // have so admin API calls succeed.
      final api = _ref.read(apiClientProvider);
      if (api.token == null || api.token!.isEmpty) {
        final riderToken = await storage.getString(StorageKeys.authToken);
        if (riderToken != null && riderToken.isNotEmpty) {
          api.setToken(riderToken);
        }
      }
    } catch (_) {
      // Persistence is best-effort; the in-memory state is still correct.
    }
    return admin;
  }

  /// Performs an email + password admin login via `/admin/login`.
  ///
  /// On success transitions to [AdminAuthStatus.authenticated]. Throws on
  /// bad credentials so the caller can show a snackbar / inline error.
  Future<AdminUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AdminAuthStatus.loading, error: null);
    try {
      final response = await _repository.loginAdmin(
        email: email,
        password: password,
      );
      state = AdminAuthState(
        status: AdminAuthStatus.authenticated,
        admin: response.admin,
        token: response.token,
        refreshToken: response.refreshToken,
      );
      return response.admin;
    } catch (e) {
      state = AdminAuthState(
        status: AdminAuthStatus.error,
        error: e is AppException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  /// Hydrates the admin session from a phone-OTP verify response.
  ///
  /// Called by the regular auth flow when `/auth/phone/verify` returns
  /// `is_admin: true`. Returns `true` when the response was successfully
  /// turned into an admin session, `false` when the response did not carry
  /// admin data (i.e. the user is a regular rider).
  Future<bool> hydrateFromOtpResponse(Map<String, dynamic> json) async {
    final response = AdminAuthRepositoryImpl.fromOtpResponse(json);
    if (response == null) {
      // Not an admin — leave state untouched (rider auth flow owns it).
      return false;
    }
    try {
      await _repository.persistSession(response);
      state = AdminAuthState(
        status: AdminAuthStatus.authenticated,
        admin: response.admin,
        token: response.token,
        refreshToken: response.refreshToken,
      );
      return true;
    } catch (e) {
      state = AdminAuthState(
        status: AdminAuthStatus.error,
        error: e is AppException ? e.message : e.toString(),
      );
      return false;
    }
  }

  /// Logs the current admin out and clears any cached admin credentials.
  ///
  /// Always succeeds locally — network failures are swallowed so the user is
  /// never stuck on a "logging out…" spinner. Also clears the regular rider
  /// session so the router redirects back to `/auth` on the next navigation.
  Future<void> logout() async {
    state = state.copyWith(status: AdminAuthStatus.loading, error: null);
    try {
      await _repository.clearSession();
      // Clear the rider session too — admin and rider sessions share the
      // same API client + storage namespace, so leaving the rider session
      // around would cause the router to redirect back to /admin/home.
      final storage = _ref.read(storageServiceProvider);
      await storage.clearAuth();
      _ref.read(apiClientProvider).setToken(null);
    } catch (_) {
      // Logout must always succeed locally.
    } finally {
      state = const AdminAuthState(status: AdminAuthStatus.unauthenticated);
    }
  }

  /// Resets the error state back to [AdminAuthStatus.unauthenticated].
  void clearError() {
    if (state.status == AdminAuthStatus.error) {
      state = const AdminAuthState(status: AdminAuthStatus.unauthenticated);
    }
  }
}

// ---- Derived selectors ----------------------------------------------------

/// The currently authenticated admin, or `null` when no admin session exists.
final currentAdminProvider = Provider<AdminUser?>((ref) {
  return ref.watch(adminAuthNotifierProvider).admin;
});

/// `true` when an admin session is currently active.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(adminAuthNotifierProvider).isAuthenticated;
});

/// The role of the current admin, or `null` when no admin is signed in.
final adminRoleProvider = Provider<AdminRole?>((ref) {
  return ref.watch(adminAuthNotifierProvider).admin?.role;
});

/// `true` when the current admin is a `super_admin` (can manage other
/// admins). Convenience selector used by gated UI like the manage-admins
/// screen.
final isSuperAdminProvider = Provider<bool>((ref) {
  return ref.watch(adminAuthNotifierProvider).isSuperAdmin;
});

/// `true` when an admin auth operation is currently in-flight.
final adminAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(adminAuthNotifierProvider).isLoading;
});

/// Async list of every admin account (typed AdminUser version).
/// NOTE: admin_web_providers.dart defines its own adminListProvider that
/// returns List<Map<String,dynamic>>. This typed version is kept for
/// backward compat with admin_home_screen. Renamed to avoid collision.
final adminListTypedProvider =
    FutureProvider.autoDispose<List<AdminUser>>((ref) async {
  ref.watch(adminAuthNotifierProvider);
  return ref.read(adminAuthRepositoryProvider).listAdmins();
});
