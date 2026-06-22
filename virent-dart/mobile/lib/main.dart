// main.dart — Virent app entry point.
import 'package:go_router/go_router.dart';
//
// Boots the Flutter app inside a [ProviderScope], starts the embedded shelf
// server on desktop platforms (Windows / macOS / Linux) so the desktop app
// *is* the backend, and wires up [MaterialApp.router] with the Virent
// theme + go_router configuration.
//
// On mobile platforms (Android / iOS) the embedded server is NOT started;
// the app connects to the desktop PC's IP address (or a Cloudflare tunnel
// URL) configured in Settings.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'core/backend/embedded_server.dart';
import 'core/configs/services/storage_service.dart';
import 'core/configs/theme/app_theme.dart';
import 'core/services/ngrok_tunnel_service.dart';
import 'core/database/virent_database.dart';
import 'features/theme/presentation/providers/theme_provider.dart';
import 'utils/logger.dart';
import 'web_init.dart' if (dart.library.io) 'web_init_stub.dart';
import 'common/widgets/update_banner.dart';

/// The single embedded server instance, or `null` on mobile / before start.
final embeddedServerProvider = StateProvider<EmbeddedServer?>((ref) => null);

/// Live tail of server log lines (most recent last, capped at 200).
final serverLogProvider = StateProvider<List<String>>((ref) => const []);

/// Human-readable server status: `stopped`, `starting`, `running`,
/// `client mode` or `error: ...`.
final serverStatusProvider = StateProvider<String>((ref) => 'stopped');

/// The IP address mobile clients should use to reach this PC, or `null`
/// when running on mobile / before the server has started.


final serverIpProvider = StateProvider<String?>((ref) => null);

/// Entry point. Runs the app inside a [ProviderScope].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initWeb(); // Enable path URL strategy on web (no-op on mobile/desktop).
  final storage = StorageService();
  await storage.init();
  runApp(ProviderScope(child: VirentApp(storage: storage)));
}

/// Root widget for the Virent app.
class VirentApp extends ConsumerStatefulWidget {
  /// Creates the app with a pre-initialised [StorageService] so the router
  /// can read auth state synchronously during redirect.
  const VirentApp({required this.storage, super.key});

  /// Persistent storage facade used by the router for auth checks.
  final StorageService storage;

  @override
  ConsumerState<VirentApp> createState() => _VirentAppState();
}

class _VirentAppState extends ConsumerState<VirentApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildAppRouter(widget.storage);
    _bootEmbeddedServer();
  }

  /// Starts the embedded shelf server on desktop platforms. On mobile the
  /// server is skipped — the device runs in client mode.
  Future<void> _bootEmbeddedServer() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      ref.read(serverStatusProvider.notifier).state = 'client mode';
      AppLogger.info('Mobile platform — running in client mode',
          tag: 'SERVER');
      return;
    }

    ref.read(serverStatusProvider.notifier).state = 'starting';

    final server = EmbeddedServer(
      port: 8443,
      onLog: (msg) {
        final logs = ref.read(serverLogProvider);
        final next = <String>[...logs, msg];
        // Keep only the most recent 200 lines so memory stays bounded.
        final capped = next.length > 200
            ? next.sublist(next.length - 200)
            : next;
        ref.read(serverLogProvider.notifier).state = capped;
      },
    );
    try {
      await server.start();

      // ── SQLite persistence ────────────────────────────────────────
      final dbPath = '${server.data.virentDir}/virent.db';
      await VirentDatabase.init(dbPath);
      await server.data.loadFromDb();
      AppLogger.info('Loaded from SQLite', tag: 'SERVER');

      // Sync to SQLite every 30 seconds
      Timer.periodic(const Duration(seconds: 30), (_) async {
        await server.data.syncToDb();
      });

      ref.read(embeddedServerProvider.notifier).state = server;
      ref.read(serverStatusProvider.notifier).state = 'running';
      final url = server.url;
      AppLogger.info('Embedded server listening on $url', tag: 'SERVER');

      // Start ngrok tunnel with STABLE domain for remote access.
      // URL: https://caliber-lividly-coastline.ngrok-free.dev
      // ngrok binary is bundled in assets/bin/ — no installation needed.
      await ref.read(ngrokTunnelServiceProvider).start();
    } catch (e, st) {
      ref.read(serverStatusProvider.notifier).state = 'error: $e';
      AppLogger.error('Embedded server failed to start',
          error: e, stackTrace: st, tag: 'SERVER');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider).isDark;
    return MaterialApp.router(
      title: 'Virent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
      builder: (context, child) {
        // Wrap every screen with the update banner overlay.
        return UpdateBannerWrapper(child: child ?? const SizedBox());
      },
    );
  }
}
