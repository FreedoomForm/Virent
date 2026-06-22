// ble_service.dart — BLE (Bluetooth Low Energy) service for Virent scooters.
//
// Connects to Virent scooters via BLE to send IoT commands (lock, unlock,
// alarm, LED, firmware update) and read telemetry (battery, GPS, speed).
//
// Production notes:
//   Each Virent scooter advertises as "Virent-XXXX" where XXXX is the
//   scooter ID. The BLE GATT service exposes:
//     - Command characteristic (write) — for IoT commands
//     - Telemetry characteristic (notify) — for real-time data
//     - Device info characteristic (read) — firmware version, MAC

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../utils/logger.dart';

/// BLE service for scooter communication.
class BleService {
  final List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  StreamSubscription? _scanSub;
  StreamSubscription? _connectionSub;

  /// UUIDs for Virent scooter BLE service & characteristics.
  static const _serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const _cmdCharUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  static const _telemetryCharUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  // ── Scanning ────────────────────────────────────────────────────────

  /// Start scanning for Virent scooters (prefix "Virent-").
  Stream<List<ScanResult>> startScan({Duration timeout = const Duration(seconds: 10)}) {
    final controller = StreamController<List<ScanResult>>.broadcast();

    FlutterBluePlus.startScan(timeout: timeout);

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      _scanResults.clear();
      for (final r in results) {
        final name = r.advertisementData.advName ?? r.device.remoteId.str;
        if (name.contains('Virent') || name.contains('virent')) {
          _scanResults.add(r);
        }
      }
      controller.add(List.unmodifiable(_scanResults));
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning) {
        controller.add(List.unmodifiable(_scanResults));
      }
    });

    return controller.stream;
  }

  /// Stop scanning.
  Future<void> stopScan() async {
    await _scanSub?.cancel();
  }

  /// Get cached scan results.
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);

  // ── Connection ──────────────────────────────────────────────────────

  /// Connect to a scooter by BluetoothDevice.
  Future<bool> connect(BluetoothDevice device) async {
    try {
      AppLogger.info('Connecting to ${device.remoteId.str}...', tag: 'BLE');
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Discover services
      final services = await device.discoverServices();

      // Find Virent service
      BluetoothService? virentService;
      for (final s in services) {
        if (s.uuid.toString() == _serviceUuid) {
          virentService = s;
          break;
        }
      }

      if (virentService == null) {
        AppLogger.info('Virent BLE service not found on device', tag: 'BLE');
        await device.disconnect();
        return false;
      }

      AppLogger.info('Connected to Virent scooter', tag: 'BLE');
      return true;
    } catch (e) {
      AppLogger.error('BLE connect failed', error: e, tag: 'BLE');
      return false;
    }
  }

  /// Disconnect from the current scooter.
  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
  }

  /// Whether currently connected to a scooter.
  bool get isConnected => _connectedDevice?.isConnected ?? false;

  // ── Commands ────────────────────────────────────────────────────────

  /// Send an IoT command to the connected scooter.
  ///
  /// Commands: lock, unlock, alarm_on, alarm_off, led_on, led_off, reboot.
  Future<bool> sendCommand(String command, {Map<String, dynamic>? params}) async {
    if (!isConnected) {
      AppLogger.error('Not connected to scooter', tag: 'BLE');
      return false;
    }

    try {
      final services = await _connectedDevice!.discoverServices();
      for (final service in services) {
        if (service.uuid.toString() == _serviceUuid) {
          for (final char in service.characteristics) {
            if (char.uuid.toString() == _cmdCharUuid) {
              final payload = jsonEncode({
                'command': command,
                'params': params ?? {},
                'timestamp': DateTime.now().toIso8601String(),
              });
              await char.write(payload.codeUnits, withoutResponse: false);
              AppLogger.info('BLE command sent: $command', tag: 'BLE');
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

  /// Listen to telemetry updates from the connected scooter.
  ///
  /// Emits maps with keys: battery, speed, coordinates, status.
  Stream<Map<String, dynamic>> listenTelemetry() async* {
    if (!isConnected) return;

    try {
      final services = await _connectedDevice!.discoverServices();
      for (final service in services) {
        if (service.uuid.toString() == _serviceUuid) {
          for (final char in service.characteristics) {
            if (char.uuid.toString() == _telemetryCharUuid) {
              await char.setNotifyValue(true);
              await for (final value in char.onValueReceived) {
                try {
                  final data = jsonDecode(String.fromCharCodes(value)) as Map<String, dynamic>;
                  yield data;
                } catch (_) {
                  // Skip malformed telemetry
                }
              }
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('BLE telemetry failed', error: e, tag: 'BLE');
    }
  }

  // ── Cleanup ─────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await stopScan();
    await disconnect();
    await _scanSub?.cancel();
    await _connectionSub?.cancel();
  }
}

/// Riverpod providers for BLE service.
///
/// Usage in widgets:
/// ```dart
/// final bleService = ref.watch(bleServiceProvider);
/// final devices = ref.watch(bleDevicesProvider);
/// ```

import 'package:flutter_riverpod/flutter_riverpod.dart';

final bleServiceProvider = Provider<BleService>((ref) => BleService());

final bleScanResultsProvider = StateProvider<List<ScanResult>>((ref) => []);

final bleConnectedProvider = StateProvider<bool>((ref) => false);
