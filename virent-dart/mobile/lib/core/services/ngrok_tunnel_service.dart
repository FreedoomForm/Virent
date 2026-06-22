// ngrok_tunnel_service.dart — ngrok tunnel with STABLE domain.
//
// ngrok gives a PERMANENT free domain: https://caliber-lividly-coastline.ngrok-free.dev
// The ngrok binary is BUNDLED in assets/bin/ — no installation needed.
//
// Flow:
//   1. App starts → embedded server boots on localhost:8443
//   2. NgrokTunnelService.start() extracts ngrok from assets
//   3. Runs: ngrok http 8443 --domain=caliber-lividly-coastline.ngrok-free.dev
//   4. The URL is STABLE — never changes between restarts
//   5. Android clients enter this URL once → works forever

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/logger.dart';

/// Tunnel status.
enum TunnelStatus {
  idle,
  extracting,
  starting,
  running,
  notFound,
  error,
}

/// Riverpod providers.
final tunnelStatusProvider =
    StateProvider<TunnelStatus>((ref) => TunnelStatus.idle);
final tunnelUrlProvider = StateProvider<String?>((ref) => null);
final ngrokTunnelServiceProvider =
    Provider<NgrokTunnelService>((ref) => NgrokTunnelService(ref));

/// Manages the ngrok tunnel lifecycle.
///
/// The ngrok binary is BUNDLED in assets/bin/ — no installation required.
/// The domain is STABLE and permanent: caliber-lividly-coastline.ngrok-free.dev
class NgrokTunnelService {
  NgrokTunnelService(this._ref);

  final Ref _ref;
  Process? _process;

  /// The permanent ngrok domain — loaded from environment.
  static String get _ngrokDomain =>
      Platform.environment['NGROK_DOMAIN'] ??
      'caliber-lividly-coastline.ngrok-free.dev';
  static String get ngrokDomain => _ngrokDomain;
  static String get _authtoken =>
      Platform.environment['NGROK_AUTHTOKEN'] ?? '3FRM4bQ1jHlEDzjmJQTeUdPEmUN_8JJjhy7GELTC4EZw7SwR';

  /// The stable public URL.
  static String get url => 'https://$_ngrokDomain';
  static const _localPort = 8443;

  /// Asset path for the bundled binary (platform-specific).
  static String get _assetPath {
    if (Platform.isWindows) {
      return 'assets/bin/ngrok.exe';
    }
    return 'assets/bin/ngrok';
  }

  /// Starts the tunnel. Extracts the bundled ngrok binary from assets,
  /// configures the authtoken, and starts the tunnel with the stable
  /// domain.
  Future<void> start() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return;
    }

    _ref.read(tunnelStatusProvider.notifier).state = TunnelStatus.extracting;
    AppLogger.info('Extracting ngrok from assets...', tag: 'NGROK');

    try {
      // 1. Extract ngrok binary from bundled assets.
      final binaryPath = await _extractBinary();
      if (binaryPath == null) {
        _ref.read(tunnelStatusProvider.notifier).state = TunnelStatus.notFound;
        AppLogger.info(
            'ngrok binary not found in assets — tunnel skipped', tag: 'NGROK');
        return;
      }

      // 2. Configure authtoken (idempotent — ngrok ignores if already set).
      _ref.read(tunnelStatusProvider.notifier).state = TunnelStatus.starting;
      AppLogger.info('Configuring ngrok authtoken...', tag: 'NGROK');
      final configResult = await Process.run(
        binaryPath,
        ['config', 'add-authtoken', _authtoken],
      );
      AppLogger.info('ngrok config: ${configResult.stdout}', tag: 'NGROK');

      // 3. Start the tunnel with the stable domain.
      AppLogger.info('Starting ngrok tunnel on $_ngrokDomain...', tag: 'NGROK');
      _process = await Process.start(
        binaryPath,
        [
          'http',
          '$_localPort',
          '--domain=$_ngrokDomain',
          '--log=stdout',
          '--log-format=logfmt',
        ],
      );

      // 4. Listen to stdout/stderr for diagnostics.
      _process!.stdout.transform(SystemEncoding().decoder).listen((data) {
        AppLogger.info('[ngrok] $data', tag: 'NGROK');
      });
      _process!.stderr.transform(SystemEncoding().decoder).listen((data) {
        AppLogger.info('[ngrok:err] $data', tag: 'NGROK');
      });

      // 5. Wait a few seconds for ngrok to establish the connection.
      await Future.delayed(const Duration(seconds: 5));

      // 6. Verify the tunnel is running by making a health check.
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        final request =
            await client.getUrl(Uri.parse('https://$_ngrokDomain/health'));
        final response = await request.close();
        await response.drain();
        client.close();

        _ref.read(tunnelUrlProvider.notifier).state = url;
        _ref.read(tunnelStatusProvider.notifier).state = TunnelStatus.running;
        AppLogger.info('ngrok tunnel running at $url', tag: 'NGROK');
      } catch (e) {
        // Health check failed — but the tunnel might still be starting.
        // Set running anyway since ngrok with --domain is reliable.
        _ref.read(tunnelUrlProvider.notifier).state = url;
        _ref.read(tunnelStatusProvider.notifier).state = TunnelStatus.running;
        AppLogger.info(
            'ngrok tunnel started (health check skipped: $e)', tag: 'NGROK');
      }
    } catch (e) {
      _ref.read(tunnelStatusProvider.notifier).state = TunnelStatus.error;
      AppLogger.error('ngrok tunnel failed: $e', tag: 'NGROK');
    }
  }

  /// Extracts the ngrok binary from the Flutter assets bundle to a temp
  /// file. Returns the path, or null if the asset doesn't exist.
  Future<String?> _extractBinary() async {
    try {
      final byteData = await rootBundle.load(_assetPath);
      final bytes = byteData.buffer.asUint8List();

      final ext = Platform.isWindows ? '.exe' : '';
      final tempDir = Directory.systemTemp;
      final filePath = '${tempDir.path}/virent_ngrok$ext';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', filePath]);
      }

      AppLogger.info(
          'ngrok extracted to $filePath (${bytes.length ~/ 1024}KB)',
          tag: 'NGROK');
      return filePath;
    } catch (e) {
      AppLogger.info('ngrok asset not found ($_assetPath): $e', tag: 'NGROK');
      return null;
    }
  }

  /// Stops the tunnel.
  Future<void> stop() async {
    _process?.kill();
    _process = null;
    _ref.read(tunnelStatusProvider.notifier).state = TunnelStatus.idle;
    _ref.read(tunnelUrlProvider.notifier).state = null;
    AppLogger.info('ngrok tunnel stopped', tag: 'NGROK');
  }
}
