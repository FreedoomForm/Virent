// app_router.dart — Virent application router.
//
// Centralised go_router configuration for the entire app. Every screen is
// declared here so navigation can use simple `context.go('/path')` calls
// without each widget owning its own Navigator.
//
// Routes:
//   Onboarding : /welcome
//   Auth       : /auth
//   Ride       : /, /trips, /wallet, /scanner, /active-ride, /ride-payment
//   Account    : /profile, /settings, /notifications, /support, /favorites
//   Admin      : /admin/home (mobile-adapted admin dashboard)
//                /admin/dashboard, /admin/scooters, /admin/trips,
//                /admin/customers, /admin/cities, /admin/zones, /admin/iot,
//                /admin/analytics, /admin/audit-log, /admin/prepaids,
//                /admin/juicers, /admin/support, /admin/notifications,
//                /admin/sms-gateway, /admin/server, /admin/logs,
//                /admin/manage-admins
//
// Redirect logic:
//   - First run (onboarding not complete) -> /welcome
//   - Not authenticated -> /welcome (unless already on /welcome or /auth)
//   - Authenticated admin hitting /welcome, /auth or / -> /admin/home
//   - Authenticated rider hitting /welcome or /auth -> / (home)
//   - Authenticated rider hitting any /admin/* route -> / (home)
//   - Non-super-admin hitting /admin/manage-admins -> /admin/home
//
// Admin detection: an admin session is identified by EITHER the
// `admin_token` SharedPreferences key (set by `/admin/login`) OR a regular
// `user_json` whose `role` field is `admin` / `super_admin` (set by
// `/auth/phone/verify` when the verified phone belongs to an admin).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/configs/services/storage_service.dart';
import 'utils/logger.dart';

// Feature screens (owned by Agents 1–4).
import 'features/onboarding/presentation/screens/welcome_screen.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/trips/presentation/screens/trips_screen.dart';
import 'features/wallet/presentation/screens/wallet_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/rides/presentation/screens/active_ride_screen.dart';
import 'features/scanner/presentation/screens/qr_scanner_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/support/presentation/screens/support_screen.dart';
import 'features/favorites/presentation/screens/favorites_screen.dart';
import 'features/payment/presentation/screens/ride_payment_screen.dart';
import 'features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'features/promo_codes/presentation/screens/promo_codes_screen.dart';
import 'features/about/presentation/screens/about_screen.dart';
import 'features/wallet/presentation/screens/payment_cards_screen.dart';
import 'features/admin/presentation/screens/admin_home_screen.dart';
import 'features/admin_web/admin_web_screen.dart';

/// Centralised registry of every route path used by the app.
class AppPaths {
  AppPaths._();

  /// Onboarding entry point.
  static const welcome = '/welcome';

  /// Phone-OTP authentication.
  static const auth = '/auth';

  /// Home / map screen.
  static const home = '/';

  /// Trip history.
  static const trips = '/trips';

  /// Wallet top-up + transactions.
  static const wallet = '/wallet';

  /// User profile.
  static const profile = '/profile';

  /// App settings (server URL, theme, SIM slot).
  static const settings = '/settings';

  /// Active ride screen.
  static const activeRide = '/active-ride';

  /// Post-ride payment summary.
  static const ridePayment = '/ride-payment';

  /// QR scanner.
  static const scanner = '/scanner';

  /// Notification inbox.
  static const notifications = '/notifications';

  /// Support / help.
  static const support = '/support';

  /// Saved favourite locations.
  static const favorites = '/favorites';

  /// Subscription plans (Swift Pass).
  static const subscriptions = '/subscriptions';

  /// Promo codes & discounts.
  static const promoCodes = '/promo-codes';

  /// About app screen.
  static const about = '/about';

  /// Payment methods.
  static const payments = '/payments';

  /// Add a new bank card.
  static const addCard = '/add-card';

  /// Admin web panel (desktop-style header + sidebar layout).
  /// Ported from the user-supplied mockup — 46 pages covering dashboard,
  /// statistics, alerts, scooters, billing, tariffs, logs, technicians,
  /// geozones, settings, chat, promo, etc.
  static const adminWeb = '/admin/web';

  // ---- Admin ----------------------------------------------------------

  /// Mobile-adapted admin home — replaces the rider home screen when an
  /// admin signs in on a phone.
  static const adminHome = '/admin/home';

  /// Manage admin accounts (super_admin only).
  static const adminManageAdmins = '/admin/manage-admins';

  /// Admin dashboard (full desktop variant).
  static const adminDashboard = '/admin/dashboard';

  /// Scooter fleet management.
  static const adminScooters = '/admin/scooters';

  /// All-trips explorer.
  static const adminTrips = '/admin/trips';

  /// SMS gateway queue monitor.
  static const adminSmsGateway = '/admin/sms-gateway';

  /// Geofence zone editor.
  static const adminZones = '/admin/zones';

  /// IoT device list + command console.
  static const adminIot = '/admin/iot';

  /// Customer management (block / unblock / adjust balance).
  static const adminCustomers = '/admin/customers';

  /// City management (service areas).
  static const adminCities = '/admin/cities';

  /// Audit log viewer.
  static const adminAuditLog = '/admin/audit-log';

  /// Analytics & reports.
  static const adminAnalytics = '/admin/analytics';

  /// Prepaid top-up card generation.
  static const adminPrepaids = '/admin/prepaids';

  /// Juicer (scooter-charger) management.
  static const adminJuicers = '/admin/juicers';

  /// Support ticket inbox.
  static const adminSupport = '/admin/support';

  /// Push notification composer.
  static const adminNotifications = '/admin/notifications';

  /// Embedded server / Docker container control.
  static const adminServer = '/admin/server';

  /// Server log viewer.
  static const adminLogs = '/admin/logs';
}

/// SharedPreferences keys the admin auth repository reads / writes. Mirrored
/// from `AdminAuthRepositoryImpl` (kept private there) so the router can
/// detect an admin session without going through Riverpod.
const _kAdminTokenKey = 'admin_token';
const _kAdminUserJsonKey = 'admin_user_json';

/// All routes that should be reachable without authentication.
const _publicRoutes = <String>{
  AppPaths.welcome,
  AppPaths.auth,
};

/// Every route that begins with one of these prefixes is admin-only. Riders
/// are bounced back to `/` if they try to deep-link into an admin route.
const _adminPrefixes = <String>['/admin/'];

/// Builds the [GoRouter] used by [MaterialApp.router].
///
/// The router is constructed lazily so that [StorageService] can be
/// initialised first by the caller. The redirect callback enforces the
/// auth + onboarding guards described at the top of this file.
GoRouter buildAppRouter(StorageService storage) {
  return GoRouter(
    initialLocation: AppPaths.welcome,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final location = state.uri.path;
      final isPublic = _publicRoutes.contains(location);
      final isAdminRoute = _adminPrefixes.any(location.startsWith);

      final isFirstRun = await storage.getBool(StorageKeys.isFirstRun,
          defaultValue: true);
      if (isFirstRun && location != AppPaths.welcome) {
        AppLogger.info('First run — redirecting to onboarding',
            tag: 'ROUTER');
        return AppPaths.welcome;
      }

      final isLoggedIn = await storage.getBool(StorageKeys.isLoggedIn);
      if (!isLoggedIn && !isPublic) {
        AppLogger.info('Unauthenticated — redirecting to /auth',
            tag: 'ROUTER');
        return AppPaths.auth;
      }

      // Authenticated user hitting /welcome or /auth — bounce to the right
      // home (admin or rider).
      if (isLoggedIn && (location == AppPaths.welcome ||
          location == AppPaths.auth)) {
        final isAdmin = await _isAdminSession(storage);
        return isAdmin ? AppPaths.adminHome : AppPaths.home;
      }

      // Authenticated admin hitting the rider home — send them to admin home.
      if (isLoggedIn && location == AppPaths.home) {
        final isAdmin = await _isAdminSession(storage);
        if (isAdmin) return AppPaths.adminHome;
      }

      // Authenticated rider trying to access an admin route — deny.
      if (isLoggedIn && isAdminRoute && location != AppPaths.adminHome) {
        final isAdmin = await _isAdminSession(storage);
        if (!isAdmin) {
          AppLogger.info(
              'Rider tried to access admin route $location — redirecting',
              tag: 'ROUTER');
          return AppPaths.home;
        }
        // Admin is fine — but /admin/manage-admins requires super_admin.
        if (location == AppPaths.adminManageAdmins) {
          final isSuper = await _isSuperAdminSession(storage);
          if (!isSuper) {
            AppLogger.info(
                'Non-super-admin tried to access manage-admins — redirecting',
                tag: 'ROUTER');
            return AppPaths.adminHome;
          }
        }
      }

      return null;
    },
    routes: [
      // ---- Onboarding ----------------------------------------------------
      GoRoute(
        path: AppPaths.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),

      // ---- Auth ----------------------------------------------------------
      GoRoute(
        path: AppPaths.auth,
        builder: (_, __) => const AuthScreen(),
      ),

      // ---- Main app ------------------------------------------------------
      GoRoute(
        path: AppPaths.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppPaths.trips,
        builder: (_, __) => const TripsScreen(),
      ),
      GoRoute(
        path: AppPaths.wallet,
        builder: (_, __) => const WalletScreen(),
      ),
      GoRoute(
        path: AppPaths.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppPaths.settings,
        builder: (_, __) => const SettingsScreen(),
      ),

      // ---- Rides ---------------------------------------------------------
      GoRoute(
        path: AppPaths.activeRide,
        builder: (_, state) => ActiveRideScreen(
          tripId: state.uri.queryParameters['tripId'] ?? '',
          scooterId: state.uri.queryParameters['scooterId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppPaths.ridePayment,
        builder: (_, state) {
          final rideId = state.uri.queryParameters['rideId'] ?? '';
          final duration =
              int.tryParse(state.uri.queryParameters['duration'] ?? '') ?? 24;
          final cost =
              int.tryParse(state.uri.queryParameters['cost'] ?? '');
          return RidePaymentScreen(
            rideId: rideId,
            duration: duration,
            cost: cost,
          );
        },
      ),

      // ---- Scanner -------------------------------------------------------
      GoRoute(
        path: AppPaths.scanner,
        builder: (_, __) => const QrScannerScreen(),
      ),

      // ---- More ----------------------------------------------------------
      GoRoute(
        path: AppPaths.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppPaths.support,
        builder: (_, __) => const SupportScreen(),
      ),
      GoRoute(
        path: AppPaths.favorites,
        builder: (_, __) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppPaths.subscriptions,
        builder: (_, __) => const SubscriptionsScreen(),
      ),
      GoRoute(
        path: AppPaths.promoCodes,
        builder: (_, __) => const PromoCodesScreen(),
      ),
      GoRoute(
        path: AppPaths.about,
        builder: (_, __) => const AboutAppScreen(),
      ),
      GoRoute(
        path: AppPaths.payments,
        builder: (_, __) => const PaymentCardsScreen(),
      ),
      GoRoute(
        path: AppPaths.addCard,
        builder: (_, __) => const PaymentCardsScreen(),
      ),

      // ---- Admin (shared by desktop + mobile) ---------------------------
      GoRoute(
        path: AppPaths.adminHome,
        builder: (_, __) => const AdminHomeScreen(),
      ),

      // ---- Admin web panel (desktop-style layout) ----------------------
      // The full 53-page admin web panel — the ONLY admin UI. Replaces
      // all the old mobile admin screens. Renders a header + sidebar +
      // content layout. Admin-only — the redirect callback in
      // buildAppRouter() already bounces non-admin sessions away from
      // any /admin/* path.
      GoRoute(
        path: AppPaths.adminWeb,
        builder: (_, __) => const AdminWebScreen(),
      ),
    ],
    errorBuilder: (_, state) => _AdminPlaceholder(
      title: 'Page not found',
      icon: Icons.error_outline,
      description: 'No route registered for ${state.uri.path}.',
    ),
  );
}

/// Returns `true` when an admin session is detected in [storage].
///
/// An admin session is identified by EITHER:
///   - The `admin_token` SharedPreferences key (set by `/admin/login`), OR
///   - A regular `user_json` whose `role` field is `admin` / `super_admin`
///     (set by `/auth/phone/verify` when the verified phone belongs to an
///     admin).
Future<bool> _isAdminSession(StorageService storage) async {
  final adminToken = await storage.getString(_kAdminTokenKey);
  if (adminToken != null && adminToken.isNotEmpty) return true;

  final userJson = await storage.getJson(StorageKeys.userJson);
  if (userJson == null) return false;
  final role = (userJson['role'] ?? '').toString().toLowerCase();
  return role == 'admin' || role == 'super_admin';
}

/// Returns `true` when the active admin session holds super_admin privileges.
///
/// Used by the router to gate `/admin/manage-admins`. Falls back to `false`
/// when no admin session exists (the caller is expected to have already
/// checked [_isAdminSession]).
Future<bool> _isSuperAdminSession(StorageService storage) async {
  // Prefer the admin-specific JSON (set by both /admin/login and the OTP
  // hydrate path) since it always carries the canonical role.
  final adminJson = await storage.getJson(_kAdminUserJsonKey);
  if (adminJson != null) {
    final role = (adminJson['role'] ?? '').toString().toLowerCase();
    if (role == 'super_admin' || role == 'superadmin') return true;
    if (role == 'admin' || role == 'operator') return false;
  }

  // Fall back to the rider record (OTP path before the admin session is
  // persisted).
  final userJson = await storage.getJson(StorageKeys.userJson);
  if (userJson == null) return false;
  final role = (userJson['role'] ?? '').toString().toLowerCase();
  return role == 'super_admin' || role == 'superadmin';
}

/// Lightweight placeholder used for admin routes whose dedicated screen has
/// not been ported yet. Renders a centered icon + title + description inside
/// a Scaffold with an empty AppBar so the drawer still works.
class _AdminPlaceholder extends StatelessWidget {
  const _AdminPlaceholder({
    required this.title,
    required this.icon,
    this.description,
  });

  final String title;
  final IconData icon;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'This screen is part of the admin feature set and will be '
                  'ported by the admin-feature agent.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
