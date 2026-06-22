/// IoT telemetry, event, and command models.
///
/// Ported from `backend/v1/models/iot.js`. The backend speaks to scooter
/// firmware over an HTTP polling protocol (in production this would be
/// MQTT, but the polling variant is cheaper for low-cost ESP32 builds):
///
///   * `POST /iot/telemetry` — scooter pushes GPS + battery + speed
///   * `POST /iot/event`     — scooter pushes event (lock/unlock/alarm/...)
///   * `GET  /iot/command`   — scooter polls for pending commands
///   * `POST /iot/command/send` — admin queues a command
///
/// This file captures the three document shapes the mobile admin UI
/// needs to render: [IoTCommand], [Telemetry], [IoTEvent].
library;


import 'json_helpers.dart';
/// Lifecycle status of a command travelling from server to scooter.
enum IoTCommandStatus {
  /// Queued on the server, waiting for the scooter to poll.
  pending,

  /// Scooter has polled and acknowledged receipt (but not execution).
  delivered,

  /// Scooter executed the command and sent an ACK.
  acked,

  /// Command failed (timeout, hardware error, etc.).
  failed,

  /// Anything the client doesn't yet understand.
  unknown;

  static IoTCommandStatus fromString(String? raw) {
    switch (raw) {
      case 'pending':
        return IoTCommandStatus.pending;
      case 'delivered':
        return IoTCommandStatus.delivered;
      case 'acked':
      case 'ack':
        return IoTCommandStatus.acked;
      case 'failed':
      case 'error':
        return IoTCommandStatus.failed;
      default:
        return IoTCommandStatus.unknown;
    }
  }

  String get wire => switch (this) {
        IoTCommandStatus.pending => 'pending',
        IoTCommandStatus.delivered => 'delivered',
        IoTCommandStatus.acked => 'acked',
        IoTCommandStatus.failed => 'failed',
        IoTCommandStatus.unknown => 'unknown',
      };
}

/// Whitelisted command verbs understood by scooter firmware.
///
/// Mirrors the `validCommands` array in `iot.js::sendCommand`.
enum IoTCommandKind {
  lock,
  unlock,
  alarmOn,
  alarmOff,
  ledOn,
  ledOff,
  updateFirmware,
  reboot,
  locate;

  static IoTCommandKind? fromString(String? raw) {
    switch (raw) {
      case 'lock':
        return IoTCommandKind.lock;
      case 'unlock':
        return IoTCommandKind.unlock;
      case 'alarm_on':
        return IoTCommandKind.alarmOn;
      case 'alarm_off':
        return IoTCommandKind.alarmOff;
      case 'led_on':
        return IoTCommandKind.ledOn;
      case 'led_off':
        return IoTCommandKind.ledOff;
      case 'update_firmware':
        return IoTCommandKind.updateFirmware;
      case 'reboot':
        return IoTCommandKind.reboot;
      case 'locate':
        return IoTCommandKind.locate;
      default:
        return null;
    }
  }

  String get wire => switch (this) {
        IoTCommandKind.lock => 'lock',
        IoTCommandKind.unlock => 'unlock',
        IoTCommandKind.alarmOn => 'alarm_on',
        IoTCommandKind.alarmOff => 'alarm_off',
        IoTCommandKind.ledOn => 'led_on',
        IoTCommandKind.ledOff => 'led_off',
        IoTCommandKind.updateFirmware => 'update_firmware',
        IoTCommandKind.reboot => 'reboot',
        IoTCommandKind.locate => 'locate',
      };
}

/// A single queued command bound for a scooter.
class IoTCommand {
  /// MongoDB `_id` of the command document.
  final String id;

  /// MAC address of the target scooter (used as the routing key by the
  /// firmware polling endpoint).
  final String mac;

  /// Command verb (lock, unlock, alarm_on, ...).
  final IoTCommandKind command;

  /// Free-form parameters bag (e.g. `{"duration_sec": 30}` for `alarm_on`).
  final Map<String, dynamic> params;

  /// Lifecycle status of the command.
  final IoTCommandStatus status;

  /// When the command was queued by the admin.
  final DateTime createdAt;

  /// When the scooter polled the command (status → `delivered`).
  final DateTime? deliveredAt;

  /// When the scooter acknowledged execution (status → `acked`).
  final DateTime? ackAt;

  /// Optional error message, populated when [status] is [IoTCommandStatus.failed].
  final String? error;

  /// Creates an [IoTCommand].
  const IoTCommand({
    required this.id,
    required this.mac,
    required this.command,
    required this.status,
    required this.createdAt,
    this.params = const {},
    this.deliveredAt,
    this.ackAt,
    this.error,
  });

  /// Parses a JSON object (MongoDB document) into an [IoTCommand].
  factory IoTCommand.fromJson(Map<String, dynamic> json) {
    final rawCmd = json['command']?.toString();
    final parsed = IoTCommandKind.fromString(rawCmd);
    return IoTCommand(
      id: stringifyId(json['_id'] ?? json['id']),
      mac: (json['scooter_mac'] ?? json['mac'] ?? '').toString(),
      command: parsed ?? IoTCommandKind.lock,
      params: json['params'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['params'] as Map)
          : const {},
      status: IoTCommandStatus.fromString(json['status']?.toString()),
      createdAt:
          parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now().toUtc(),
      deliveredAt:
          parseDate(json['delivered_at'] ?? json['deliveredAt']),
      ackAt: parseDate(json['ack_at'] ?? json['ackAt']),
      error: asString(json['error']),
    );
  }

  /// `true` when the command has been polled by the scooter.
  bool get isDelivered =>
      status == IoTCommandStatus.delivered ||
      status == IoTCommandStatus.acked;

  /// `true` when the scooter has executed the command.
  bool get isAcknowledged => status == IoTCommandStatus.acked;

  /// `true` when the command is still waiting to be polled.
  bool get isPending => status == IoTCommandStatus.pending;

  /// Latency between queueing and delivery, in seconds. `null` when not
  /// yet delivered.
  int? get deliveryLatencySec => deliveredAt == null
      ? null
      : deliveredAt!.difference(createdAt).inSeconds;

  /// Latency between delivery and ack, in seconds. `null` when not yet
  /// acknowledged.
  int? get ackLatencySec => ackAt == null || deliveredAt == null
      ? null
      : ackAt!.difference(deliveredAt!).inSeconds;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'scooter_mac': mac,
        'command': command.wire,
        'params': params,
        'status': status.wire,
        'created_at': createdAt.toIso8601String(),
        if (deliveredAt != null) 'delivered_at': deliveredAt!.toIso8601String(),
        if (ackAt != null) 'ack_at': ackAt!.toIso8601String(),
        if (error != null) 'error': error,
      };

  IoTCommand copyWith({
    String? id,
    String? mac,
    IoTCommandKind? command,
    Map<String, dynamic>? params,
    IoTCommandStatus? status,
    DateTime? createdAt,
    DateTime? deliveredAt,
    DateTime? ackAt,
    String? error,
  }) {
    return IoTCommand(
      id: id ?? this.id,
      mac: mac ?? this.mac,
      command: command ?? this.command,
      params: params ?? this.params,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      ackAt: ackAt ?? this.ackAt,
      error: error ?? this.error,
    );
  }

  @override
  String toString() =>
      'IoTCommand($command → $mac, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IoTCommand && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Single telemetry sample pushed by a scooter.
///
/// Mirrors the `telemetry_log` entries appended inside `iot.js::telemetry`.
class Telemetry {
  /// GPS coordinates at sample time. `null` when GPS lock was lost.
  final double? latitude;
  final double? longitude;

  /// Battery percentage (0–100).
  final double battery;

  /// Speed in km/h, as reported by the scooter.
  final double speed;

  /// Sample timestamp (UTC).
  final DateTime timestamp;

  /// Optional status override pushed by the scooter.
  final String? status;

  /// Creates a [Telemetry].
  const Telemetry({
    this.latitude,
    this.longitude,
    required this.battery,
    required this.speed,
    required this.timestamp,
    this.status,
  });

  /// Parses a JSON object into a [Telemetry].
  factory Telemetry.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'];
    return Telemetry(
      latitude: _toDoubleOrNull(rawCoords is Map
          ? rawCoords['latitude'] ?? rawCoords['lat']
          : json['latitude'] ?? json['lat']),
      longitude: _toDoubleOrNull(rawCoords is Map
          ? rawCoords['longitude'] ?? rawCoords['lng']
          : json['longitude'] ?? json['lng']),
      battery: toDouble(json['battery']),
      speed: toDouble(json['speed']),
      timestamp: parseDate(json['timestamp']) ?? DateTime.now().toUtc(),
      status: asString(json['status']),
    );
  }

  /// `true` when GPS coordinates are present and valid.
  bool get hasGps => latitude != null && longitude != null;

  /// `true` when battery is critically low (<20%).
  bool get isLowBattery => battery < 20;

  /// `true` when the scooter is stationary.
  bool get isStationary => speed < 1.0;

  Map<String, dynamic> toJson() => {
        if (latitude != null && longitude != null)
          'coordinates': {'latitude': latitude, 'longitude': longitude},
        'battery': battery,
        'speed': speed,
        'timestamp': timestamp.toIso8601String(),
        if (status != null) 'status': status,
      };

  @override
  String toString() =>
      'Telemetry(battery: $battery%, speed: $speed km/h, at: $timestamp)';
}

/// Whitelisted IoT event types emitted by scooter firmware.
///
/// Mirrors the `event_type` field in `iot.js::event`.
enum IoTEventType {
  lock,
  unlock,
  lowBattery,
  alarm,
  fall,
  geofenceViolation,
  firmwareUpdate;

  static IoTEventType? fromString(String? raw) {
    if (raw == null) return null;
    // Tolerate `iot_` prefix from scooter log entries.
    final cleaned = raw.startsWith('iot_') ? raw.substring(4) : raw;
    switch (cleaned) {
      case 'lock':
        return IoTEventType.lock;
      case 'unlock':
        return IoTEventType.unlock;
      case 'low_battery':
        return IoTEventType.lowBattery;
      case 'alarm':
        return IoTEventType.alarm;
      case 'fall':
        return IoTEventType.fall;
      case 'geofence_violation':
        return IoTEventType.geofenceViolation;
      case 'firmware_update':
        return IoTEventType.firmwareUpdate;
      default:
        return null;
    }
  }

  String get wire => switch (this) {
        IoTEventType.lock => 'lock',
        IoTEventType.unlock => 'unlock',
        IoTEventType.lowBattery => 'low_battery',
        IoTEventType.alarm => 'alarm',
        IoTEventType.fall => 'fall',
        IoTEventType.geofenceViolation => 'geofence_violation',
        IoTEventType.firmwareUpdate => 'firmware_update',
      };
}

/// Scooter-pushed event recorded in the scooter log.
class IoTEvent {
  /// MongoDB `_id` of the log entry.
  final String id;

  /// Scooter MAC address that emitted the event.
  final String mac;

  /// Event type. `null` when the firmware emitted an unknown type.
  final IoTEventType? type;

  /// Raw event-type string (preserved for forward compatibility).
  final String typeRaw;

  /// Event payload (free-form JSON, e.g. fall acceleration vector).
  final Map<String, dynamic> data;

  /// Event timestamp (UTC).
  final DateTime timestamp;

  /// Creates an [IoTEvent].
  const IoTEvent({
    required this.id,
    required this.mac,
    required this.type,
    required this.typeRaw,
    required this.timestamp,
    this.data = const {},
  });

  /// Parses a JSON object into an [IoTEvent].
  factory IoTEvent.fromJson(Map<String, dynamic> json) {
    final rawType = (json['event'] ?? json['event_type'] ?? '').toString();
    final cleaned = rawType.startsWith('iot_') ? rawType.substring(4) : rawType;
    return IoTEvent(
      id: stringifyId(json['_id'] ?? json['id']),
      mac: (json['scooter_mac'] ?? json['mac'] ?? '').toString(),
      type: IoTEventType.fromString(cleaned),
      typeRaw: cleaned,
      data: json['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      timestamp:
          parseDate(json['timestamp']) ?? DateTime.now().toUtc(),
    );
  }

  /// `true` when the event denotes a user-safety issue (fall, alarm,
  /// geofence violation).
  bool get isSafetyCritical =>
      type == IoTEventType.fall ||
      type == IoTEventType.alarm ||
      type == IoTEventType.geofenceViolation;

  /// `true` when the event marks a state transition (lock/unlock).
  bool get isStateChange =>
      type == IoTEventType.lock || type == IoTEventType.unlock;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'scooter_mac': mac,
        'event': 'iot_${typeRaw}',
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() => 'IoTEvent($typeRaw from $mac at $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IoTEvent && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// --- internal helpers ----------------------------------------------------


double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}


