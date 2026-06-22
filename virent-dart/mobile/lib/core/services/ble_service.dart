// ble_service.dart — Universal IoT transport layer for Virent scooters.
//
// Architecture:
//   The Virent IoT API is transport-agnostic. ANY scooter can connect:
//
//   Transport       Protocol        Endpoint
//   ───────────────────────────────────────────────────────
//   HTTP/HTTPS      REST            POST /iot/telemetry
//                                   GET  /iot/command?scooter_mac=XX
//                                   POST /iot/command/send
//   BLE             GATT            (this service — one transport option)
//   MQTT            pub/sub         (future: iot/virent/+/telemetry)
//
//   The BLE service connects to scooters advertising as "Virent-XXXX"
//   and communicates via a standard GATT profile. UUIDs are loaded from
//   scooter metadata on first connection (dynamic discovery), falling
//   back to known Virent defaults.
//
//   For HTTP-only scooters (ESP32, SIM800, etc.): no BLE needed —
//   the scooter firmware posts directly to /iot/telemetry and polls
//   /iot/command. Zero Dart code required on the scooter side.

import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../utils/logger.dart';

/// Default Virent BLE service UUIDs (can be overridden per-scooter).
class BleUuids {
  final String service;
  final String command;
  final String telemetry;
  final String deviceInfo;

  const BleUuids({
    this.service = '4fafc201-1fb5-459e-8fcc-c5c9c331914b',
    this.command = 'beb5483e-36e1-4688-b7f5-ea07361b26a8',
    this.telemetry = '6e400003-b5a3-f393-e0a9-e50e24dcca9e',
    this.deviceInfo = '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
  });

  factory BleUuids.fromMetadata(Map<String, dynamic> meta) => BleUuids(
    service: meta['ble_service_uuid'] ?? BleUuids().service,
    command: meta['ble_cmd_uuid'] ?? BleUuids().command,
    telemetry: meta['ble_telemetry_uuid'] ?? BleUuids().telemetry,
    deviceInfo: meta['ble_info_uuid'] ?? BleUuids().deviceInfo,
  );
}

/// Result of a BLE scan for Virent scooters.
class ScooterDevice {
  final String id;
  final String name;
  final String address;
  final int rssi;
  final BluetoothDevice device;
  BleUuids uuids;

  ScooterDevice({
    required this.id,
    required this.name,
    required this.address,
    required this.rssi,
    required this.device,
    this.uuids = const BleUuids(),
  });
}

/// Universal IoT BLE service.
class BleService {
  final List<ScooterDevice> _devices = [];
  BluetoothDevice? _connected;
  BleUuids _activeUuids = const BleUuids();
  StreamSubscription? _scanSub;

  List<ScooterDevice> get devices => List.unmodifiable(_devices);
  bool get isConnected => _connected?.isConnected ?? false;
  String? get connectedId => _connected?.remoteId.str;

  // ── Scanning ────────────────────────────────────────────────────────

  /// Scan for Virent scooters. Matches any BLE device whose name starts
  /// with "Virent" (case-insensitive) or contains the scooter prefix.
  Stream<List<ScooterDevice>> startScan({
    Duration timeout = const Duration(seconds: 10),
    String namePrefix = 'Virent',
  }) {
    final controller = StreamController<List<ScooterDevice>>.broadcast();

    FlutterBluePlus.startScan(timeout: timeout);

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      _devices.clear();
      for (final r in results) {
        final name = r.advertisementData.advName ?? '';
        if (name.toLowerCase().contains(namePrefix.toLowerCase())) {
          final id = name.replaceFirst(RegExp(namePrefix, caseSensitive: false), '').trim();
          _devices.add(ScooterDevice(
            id: id.isNotEmpty ? id : r.device.remoteId.str,
            name: name,
            address: r.device.remoteId.str,
            rssi: r.rssi,
            device: r.device,
          ));
        }
      }
      controller.add(List.unmodifiable(_devices));
    });

    return controller.stream;
  }

  Future<void> stopScan() async => await _scanSub?.cancel();

  // ── Connection ──────────────────────────────────────────────────────

  /// Connect to a scooter and discover its BLE profile.
  Future<bool> connect(ScooterDevice scooter) async {
    try {
      AppLogger.info('BLE: connecting to ${scooter.name}...', tag: 'BLE');
      await scooter.device.connect(timeout: const Duration(seconds: 15));
      _connected = scooter.device;

      // Discover services — find Virent-compatible ones
      final services = await scooter.device.discoverServices();
      BluetoothService? virentSvc;

      // Try known UUID first, then fall back to scanning
      for (final svc in services) {
        if (svc.uuid.toString().toLowerCase() == scooter.uuids.service.toLowerCase()) {
          virentSvc = svc;
          break;
        }
      }

      if (virentSvc == null) {
        AppLogger.info('BLE: Virent service not found — scooter may use HTTP-only', tag: 'BLE');
        await scooter.device.disconnect();
        return false;
      }

      // Discover actual characteristic UUIDs
      for (final chr in virentSvc.characteristics) {
        final uuid = chr.uuid.toString().toLowerCase();
        if (chr.properties.write || chr.properties.writeWithoutResponse) {
          _activeUuids = BleUuids(
            service: virentSvc.uuid.toString(),
            command: uuid,
            telemetry: _activeUuids.telemetry,
            deviceInfo: _activeUuids.deviceInfo,
          );
        }
        if (chr.properties.notify || chr.properties.indicate) {
          _activeUuids = BleUuids(
            service: virentSvc.uuid.toString(),
            command: _activeUuids.command,
            telemetry: uuid,
            deviceInfo: _activeUuids.deviceInfo,
          );
        }
      }

      AppLogger.info('BLE: connected to ${scooter.name}', tag: 'BLE');
      return true;
    } catch (e) {
      AppLogger.error('BLE connect failed', error: e, tag: 'BLE');
      return false;
    }
  }

  Future<void> disconnect() async {
    await _connected?.disconnect();
    _connected = null;
  }

  // ── Commands ────────────────────────────────────────────────────────

  /// Send an IoT command via BLE. Supported: lock, unlock, alarm_on,
  /// alarm_off, led_on, led_off, reboot, update_firmware, locate.
  Future<bool> sendCommand(String command, {Map<String, dynamic>? params}) async {
    if (!isConnected) return false;
    try {
      final services = await _connected!.discoverServices();
      for (final svc in services) {
        if (svc.uuid.toString().toLowerCase() == _activeUuids.service.toLowerCase()) {
          for (final chr in svc.characteristics) {
            if (chr.uuid.toString().toLowerCase() == _activeUuids.command.toLowerCase()) {
              final payload = utf8.encode(jsonEncode({
                'cmd': command,
                'params': params ?? {},
                'ts': DateTime.now().millisecondsSinceEpoch,
              }));
              await chr.write(payload, withoutResponse: false);
              AppLogger.info('BLE: sent $command', tag: 'BLE');
              return true;
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('BLE command failed', error: e, tag: 'BLE');
    }
    return false;
  }

  // ── Telemetry ───────────────────────────────────────────────────────

  /// Stream telemetry from the connected scooter.
  Stream<Map<String, dynamic>> listenTelemetry() async* {
    if (!isConnected) return;
    try {
      final services = await _connected!.discoverServices();
      for (final svc in services) {
        if (svc.uuid.toString().toLowerCase() == _activeUuids.service.toLowerCase()) {
          for (final chr in svc.characteristics) {
            if (chr.uuid.toString().toLowerCase() == _activeUuids.telemetry.toLowerCase()) {
              await chr.setNotifyValue(true);
              await for (final value in chr.onValueReceived) {
                try {
                  yield jsonDecode(utf8.decode(value)) as Map<String, dynamic>;
                } catch (_) {}
              }
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('BLE telemetry failed', error: e, tag: 'BLE');
    }
  }

  Future<void> dispose() async {
    await stopScan();
    await disconnect();
  }
}
