// local_network_service.dart — Local network connectivity helper.
//
// When ngrok is down or unavailable, the phone can connect directly to the
// PC's local IP address. This service discovers the local IP and provides
// it as a fallback endpoint.

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../utils/logger.dart';

class LocalNetworkService {
  static final LocalNetworkService instance = LocalNetworkService._();
  LocalNetworkService._();

  String? _localIp;
  static const _port = 8443;

  /// The local network URL (e.g. http://192.168.1.100:8443).
  /// Only works when phone and PC are on same WiFi/LAN.
  String? get localUrl => _localIp != null ? 'http://$_localIp:$_port' : null;

  /// Discover the local IP address. Returns the first non-loopback IPv4.
  Future<String?> discoverLocalIp() async {
    if (_localIp != null) return _localIp;

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            _localIp = addr.address;
            AppLogger.info(
                'Local IP discovered: $_localIp (interface: ${interface.name})',
                tag: 'NETWORK');
            debugPrint('[Virent] Local network: $localUrl');
            return _localIp;
          }
        }
      }
      AppLogger.info('No local IPv4 address found', tag: 'NETWORK');
      return null;
    } catch (e) {
      AppLogger.info('Network interface scan failed: $e', tag: 'NETWORK');
      return null;
    }
  }

  /// Stop the service.
  void stop() {
    _localIp = null;
  }
}
