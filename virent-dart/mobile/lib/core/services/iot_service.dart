// iot_service.dart — Universal IoT hub for ANY scooter hardware.
//
// Architecture: transport-agnostic plugin system.
//
//   Scooter metadata (from DB) determines which transport to use:
//
//   Transport    Protocol      Auto-detected by     Use case
//   ─────────────────────────────────────────────────────────────────
//   HTTP         REST API      transport: "http"    ESP32, SIM800, WiFi
//   BLE          GATT          transport: "ble"     Bluetooth scooters
//   MQTT         pub/sub       transport: "mqtt"    Industrial IoT
//
//   Each scooter has a `transport` field and optional `transportConfig`.
//   The IoT hub auto-selects the correct transport plugin.
//
//   Commands (lock, unlock, alarm, etc.) are sent via the active transport.
//   Telemetry (GPS, battery, speed) arrives via the active transport.
//
//   To add a new scooter: just insert a row in the DB with the correct
//   transport field. Zero code changes needed.

import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import '../../core/configs/services/api_client.dart';
import '../../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Data types
// ═══════════════════════════════════════════════════════════════════════════

/// Supported transport protocols.
enum ScooterTransport { http, ble, mqtt }

/// Scooter metadata (loaded from DB).
class ScooterMeta {
  final String id;
  final String name;
  final String macAddress;
  final ScooterTransport transport;
  final Map<String, dynamic> transportConfig;

  const ScooterMeta({
    required this.id,
    required this.name,
    required this.macAddress,
    this.transport = ScooterTransport.http,
    this.transportConfig = const {},
  });

  factory ScooterMeta.fromJson(Map<String, dynamic> json) {
    final t = (json['transport'] ?? 'http').toString().toLowerCase();
    return ScooterMeta(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      macAddress: json['mac_address'] as String? ?? '',
      transport: t == 'ble' ? ScooterTransport.ble
          : t == 'mqtt' ? ScooterTransport.mqtt
          : ScooterTransport.http,
      transportConfig: json['transport_config'] is Map
          ? Map<String, dynamic>.from(json['transport_config'])
          : {},
    );
  }
}

/// An IoT command to send.
class IotCommand {
  final String command;
  final Map<String, dynamic> params;
  final String scooterMac;

  const IotCommand({
    required this.command,
    required this.scooterMac,
    this.params = const {},
  });

  Map<String, dynamic> toJson() => {
    'cmd': command,
    'params': params,
    'ts': DateTime.now().millisecondsSinceEpoch,
  };

  /// Valid commands across all transports.
  static const validCommands = [
    'lock', 'unlock',
    'alarm_on', 'alarm_off',
    'led_on', 'led_off',
    'update_firmware', 'reboot', 'locate',
    'set_speed_limit', 'set_geo_fence',
  ];
}

/// Telemetry data point from a scooter.
class TelemetryPoint {
  final String scooterId;
  final double? lat, lng;
  final int? battery;
  final double? speed;
  final String? status;
  final DateTime timestamp;

  const TelemetryPoint({
    required this.scooterId,
    this.lat, this.lng, this.battery, this.speed, this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'scooter_id': scooterId,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
    if (battery != null) 'battery': battery,
    if (speed != null) 'speed': speed,
    if (status != null) 'status': status,
    'timestamp': timestamp.toIso8601String(),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Transport interface
// ═══════════════════════════════════════════════════════════════════════════

/// Each transport plugin implements this.
abstract class IotTransport {
  /// Whether this transport is currently connected/available.
  bool get isAvailable;

  /// Send a command to a specific scooter.
  Future<bool> sendCommand(ScooterMeta scooter, IotCommand command);

  /// Listen for telemetry from a specific scooter.
  Stream<TelemetryPoint> listenTelemetry(ScooterMeta scooter);

  /// Clean up resources.
  Future<void> dispose();
}

// ═══════════════════════════════════════════════════════════════════════════
// HTTP Transport (works with ANY WiFi-enabled scooter: ESP32, SIM800, etc.)
// ═══════════════════════════════════════════════════════════════════════════

class HttpIotTransport implements IotTransport {
  final String _baseUrl;
  final http.Client _client = http.Client();

  HttpIotTransport({String? baseUrl}) : _baseUrl = baseUrl ?? 'http://localhost:8443';

  @override
  bool get isAvailable => true; // HTTP is always available (local server)

  @override
  Future<bool> sendCommand(ScooterMeta scooter, IotCommand command) async {
    try {
      final url = scooter.transportConfig['command_url'] as String?
          ?? '$_baseUrl/iot/command/send';
      await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'scooter_mac': scooter.macAddress,
          'command': command.command,
          'params': command.params,
        }),
      ).timeout(const Duration(seconds: 5));
      AppLogger.info('HTTP command: ${command.command} → ${scooter.name}', tag: 'IoT');
      return true;
    } catch (e) {
      AppLogger.error('HTTP command failed: $e', tag: 'IoT');
      return false;
    }
  }

  @override
  Stream<TelemetryPoint> listenTelemetry(ScooterMeta scooter) async* {
    // HTTP scooters push telemetry via POST /iot/telemetry — consumed
    // by the embedded server. This transport polls for the latest.
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      // In production: poll scooter's own HTTP endpoint
      // For now: scooter pushes to server, server stores in DB
    }
  }

  @override
  Future<void> dispose() async => _client.close();
}

// ═══════════════════════════════════════════════════════════════════════════
// BLE Transport (Bluetooth Low Energy — direct scooter connection)
// ═══════════════════════════════════════════════════════════════════════════

class BleIotTransport implements IotTransport {
  final Map<String, BluetoothDevice> _devices = {};
  final Map<String, StreamSubscription> _subs = {};

  // Default BLE UUIDs — overridden per-scooter via transportConfig
  static const _defaultServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const _defaultCmdUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  static const _defaultTelemetryUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  @override
  bool get isAvailable => FlutterBluePlus.isSupported;

  String _svcUuid(ScooterMeta s) =>
      s.transportConfig['ble_service_uuid'] ?? _defaultServiceUuid;
  String _cmdUuid(ScooterMeta s) =>
      s.transportConfig['ble_cmd_uuid'] ?? _defaultCmdUuid;
  String _telUuid(ScooterMeta s) =>
      s.transportConfig['ble_telemetry_uuid'] ?? _defaultTelemetryUuid;

  /// Scan for BLE scooters matching the Virent name prefix.
  Stream<List<ScanResult>> scan({String prefix = 'Virent', Duration timeout = const Duration(seconds: 10)}) {
    final ctrl = StreamController<List<ScanResult>>.broadcast();
    FlutterBluePlus.startScan(timeout: timeout);
    FlutterBluePlus.scanResults.listen((results) {
      ctrl.add(results.where((r) {
        final name = r.advertisementData.advName ?? '';
        return name.toLowerCase().contains(prefix.toLowerCase());
      }).toList());
    });
    FlutterBluePlus.isScanning.listen((s) { if (!s) ctrl.close(); });
    return ctrl.stream;
  }

  @override
  Future<bool> sendCommand(ScooterMeta scooter, IotCommand command) async {
    try {
      // Find device by MAC from scan cache
      final device = _devices[scooter.macAddress];
      if (device == null) return false;

      await device.connect(timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();

      for (final svc in services) {
        if (svc.uuid.toString().toLowerCase() == _svcUuid(scooter).toLowerCase()) {
          for (final chr in svc.characteristics) {
            if (chr.uuid.toString().toLowerCase() == _cmdUuid(scooter).toLowerCase()) {
              await chr.write(utf8.encode(jsonEncode(command.toJson())), withoutResponse: false);
              AppLogger.info('BLE command: ${command.command} → ${scooter.name}', tag: 'IoT');
              return true;
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('BLE command failed: $e', tag: 'IoT');
    }
    return false;
  }

  @override
  Stream<TelemetryPoint> listenTelemetry(ScooterMeta scooter) async* {
    final device = _devices[scooter.macAddress];
    if (device == null) return;

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();

      for (final svc in services) {
        if (svc.uuid.toString().toLowerCase() == _svcUuid(scooter).toLowerCase()) {
          for (final chr in svc.characteristics) {
            if (chr.uuid.toString().toLowerCase() == _telUuid(scooter).toLowerCase()) {
              await chr.setNotifyValue(true);
              await for (final value in chr.onValueReceived) {
                try {
                  final data = jsonDecode(utf8.decode(value)) as Map<String, dynamic>;
                  yield TelemetryPoint(
                    scooterId: scooter.id,
                    lat: (data['lat'] as num?)?.toDouble(),
                    lng: (data['lng'] as num?)?.toDouble(),
                    battery: (data['battery'] as num?)?.toInt(),
                    speed: (data['speed'] as num?)?.toDouble(),
                    status: data['status'] as String?,
                  );
                } catch (_) {}
              }
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('BLE telemetry failed: $e', tag: 'IoT');
    }
  }

  /// Cache a discovered device for later use.
  void cacheDevice(String mac, BluetoothDevice device) {
    _devices[mac] = device;
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subs.values) { await sub.cancel(); }
    for (final d in _devices.values) { await d.disconnect(); }
    _devices.clear();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MQTT Transport (placeholder — industrial/mass-deployment IoT)
// ═══════════════════════════════════════════════════════════════════════════

class MqttIotTransport implements IotTransport {
  @override
  bool get isAvailable => false; // Requires mqtt_client package

  @override
  Future<bool> sendCommand(ScooterMeta scooter, IotCommand command) async {
    AppLogger.info('MQTT not yet implemented — use HTTP or BLE', tag: 'IoT');
    return false;
  }

  @override
  Stream<TelemetryPoint> listenTelemetry(ScooterMeta scooter) async* {
    // Future: subscribe to virent/{scooterId}/telemetry
  }

  @override
  Future<void> dispose() async {}
}

// ═══════════════════════════════════════════════════════════════════════════
// Universal IoT Hub
// ═══════════════════════════════════════════════════════════════════════════

/// Central IoT hub — auto-selects transport per scooter.
///
/// Usage:
/// ```dart
/// final iot = IotHub();
/// // Scooter s1 uses HTTP (ESP32), s2 uses BLE
/// await iot.sendCommand(s1, IotCommand(command: 'lock', scooterMac: s1.macAddress));
/// await iot.sendCommand(s2, IotCommand(command: 'unlock', scooterMac: s2.macAddress));
/// ```
class IotHub {
  final HttpIotTransport http = HttpIotTransport();
  final BleIotTransport ble = BleIotTransport();
  final MqttIotTransport mqtt = MqttIotTransport();

  /// Get the correct transport for a scooter based on its metadata.
  IotTransport _transportFor(ScooterMeta scooter) {
    switch (scooter.transport) {
      case ScooterTransport.ble:
        return ble;
      case ScooterTransport.mqtt:
        return mqtt;
      case ScooterTransport.http:
      default:
        return http;
    }
  }

  /// Send a command to a scooter using its configured transport.
  Future<bool> sendCommand(ScooterMeta scooter, IotCommand command) async {
    final transport = _transportFor(scooter);
    return transport.sendCommand(scooter, command);
  }

  /// Listen for telemetry from a scooter.
  Stream<TelemetryPoint> listenTelemetry(ScooterMeta scooter) {
    final transport = _transportFor(scooter);
    return transport.listenTelemetry(scooter);
  }

  /// Quick check: can we reach this scooter?
  Future<bool> ping(ScooterMeta scooter) async {
    return sendCommand(scooter, IotCommand(command: 'locate', scooterMac: scooter.macAddress));
  }

  Future<void> dispose() async {
    await http.dispose();
    await ble.dispose();
    await mqtt.dispose();
  }
}
