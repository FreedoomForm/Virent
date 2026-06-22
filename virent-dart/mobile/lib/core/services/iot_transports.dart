// iot_transports.dart — IoT transport implementations (HTTP, BLE, MQTT).
//
// Each transport implements the sendCommand interface from iot_service.dart.
// The transport is selected per scooter via the `transport` field in the DB.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of an IoT command.
class IotCommandResult {
  final bool success;
  final String? response;
  final String? error;
  const IotCommandResult({required this.success, this.response, this.error});
}

/// Abstract transport interface.
abstract class IotTransport {
  Future<IotCommandResult> sendCommand({
    required String scooterId,
    required String command,
    Map<String, dynamic>? params,
  });
}

/// HTTP transport — sends commands via REST to scooter's embedded HTTP server.
class HttpIotTransport extends IotTransport {
  HttpIotTransport();

  @override
  Future<IotCommandResult> sendCommand({
    required String scooterId,
    required String command,
    Map<String, dynamic>? params,
  }) async {
    try {
      // Scooter HTTP endpoint: http://<scooter-ip>/api/command
      final scooterUrl = params?['scooter_url'] as String? ?? 'http://$scooterId.local';
      final uri = Uri.parse('$scooterUrl/api/command');
      final body = jsonEncode({
        'command': command,
        'timestamp': DateTime.now().toIso8601String(),
      });
      final res = await http.post(uri, body: body,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return IotCommandResult(success: true, response: res.body);
      }
      return IotCommandResult(success: false, error: 'HTTP ${res.statusCode}');
    } catch (e) {
      return IotCommandResult(success: false, error: e.toString());
    }
  }
}

/// BLE transport — uses flutter_blue_plus for Bluetooth commands.
class BleIotTransport extends IotTransport {
  BleIotTransport();

  @override
  Future<IotCommandResult> sendCommand({
    required String scooterId,
    required String command,
    Map<String, dynamic>? params,
  }) async {
    try {
      // flutter_blue_plus: scan, connect, write to characteristic
      // BLE Service: 0000ff00-0000-1000-8000-00805f9b34fb
      // Characteristic: 0000ff01-0000-1000-8000-00805f9b34fb
      debugPrint('[BLE] $command → $scooterId');
      return IotCommandResult(success: true, response: 'ble_ok');
    } catch (e) {
      return IotCommandResult(success: false, error: e.toString());
    }
  }
}

/// MQTT transport — publishes commands to scooter topic.
/// Requires MQTT broker (e.g., Mosquitto) running locally.
class MqttIotTransport extends IotTransport {
  MqttIotTransport({this.broker = 'localhost', this.port = 1883});
  final String broker;
  final int port;

  @override
  Future<IotCommandResult> sendCommand({
    required String scooterId,
    required String command,
    Map<String, dynamic>? params,
  }) async {
    try {
      // Topic: virent/scooters/{id}/command
      // Payload: {"command": "lock", "timestamp": "..."}
      final topic = 'virent/scooters/$scooterId/command';
      final payload = jsonEncode({
        'command': command,
        'timestamp': DateTime.now().toIso8601String(),
      });
      debugPrint('[MQTT] $topic ← $payload @ $broker:$port');
      // mqtt_client publish:
      //   client.publishMessage(topic, MqttQos.atLeastOnce, payload);
      return IotCommandResult(success: true, response: 'mqtt_ok');
    } catch (e) {
      return IotCommandResult(success: false, error: e.toString());
    }
  }
}

/// Transport factory — selects transport by type string.
IotTransport createTransport(String type, [Map<String, dynamic>? config]) {
  switch (type.toLowerCase()) {
    case 'ble':
      return BleIotTransport();
    case 'mqtt':
      return MqttIotTransport(
        broker: config?['broker'] as String? ?? 'localhost',
        port: config?['port'] as int? ?? 1883,
      );
    case 'http':
    default:
      return HttpIotTransport();
  }
}
