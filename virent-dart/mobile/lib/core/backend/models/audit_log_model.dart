import 'json_helpers.dart';
/// Immutable audit-log entry model.
///
/// Ported from `backend/v1/models/auditlog.js`. Every admin mutation
/// (and, later, juicer/mechanic actions) is appended to the `audit_log`
/// MongoDB collection with a 1-year TTL for compliance, dispute
/// resolution and forensic analysis.
///
/// The JS module exports `log()` (internal) and `query()` (admin-only
/// `GET /audit-log`). The Flutter client only consumes the query result
/// shape, so this model omits the writer helpers.
class AuditLogEntry {
  /// MongoDB `_id` of the log entry.
  final String id;

  /// `_id` of the actor performing the action. `null` for system events.
  final String? actorId;

  /// Actor role: `admin`, `super_admin`, `juicer`, `mechanic`, `system`.
  final String actorRole;

  /// Email of the actor, when known (denormalised for quick search).
  final String? actorEmail;

  /// Action verb in `entity.verb` form, e.g. `scooter.create`,
  /// `user.delete`, `trip.refund`.
  final String action;

  /// Target entity type: `scooter`, `user`, `city`, `trip`, `promocode`,
  /// etc. Mirrors the MongoDB collection name.
  final String? targetType;

  /// `_id` of the affected entity, stringified for portability.
  final String? entityId;

  /// Snapshot of the entity before the mutation. Free-form JSON.
  final Map<String, dynamic>? before;

  /// Snapshot of the entity after the mutation. Free-form JSON.
  final Map<String, dynamic>? after;

  /// Optional human-readable details string (legacy field).
  final String? details;

  /// Client IP captured from the request. `null` for cron/system events.
  final String? ip;

  /// `User-Agent` header of the actor's HTTP client.
  final String? userAgent;

  /// When the action was recorded (UTC).
  final DateTime timestamp;

  /// When the entry is scheduled to be purged by the TTL index.
  /// Defaults to `timestamp + 365 days`.
  final DateTime? retentionExpires;

  /// Creates an [AuditLogEntry].
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.timestamp,
    this.actorId,
    this.actorRole = 'system',
    this.actorEmail,
    this.targetType,
    this.entityId,
    this.before,
    this.after,
    this.details,
    this.ip,
    this.userAgent,
    this.retentionExpires,
  });

  /// Parses a JSON object (MongoDB document) into an [AuditLogEntry].
  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id'] ?? json['id'];
    final rawActor = json['actor_id'];
    return AuditLogEntry(
      id: stringifyId(rawId),
      actorId: rawActor == null ? null : stringifyId(rawActor),
      actorRole: (json['actor_role'] ?? json['actorRole'] ?? 'system')
          .toString(),
      actorEmail: asString(json['actor_email'] ?? json['actorEmail']),
      action: (json['action'] ?? '').toString(),
      targetType: asString(json['target_type'] ?? json['targetType']),
      entityId: asString(
          json['target_id'] ?? json['targetId'] ?? json['entityId']),
      before: json['before'] is Map<String, dynamic>
          ? json['before'] as Map<String, dynamic>
          : null,
      after: json['after'] is Map<String, dynamic>
          ? json['after'] as Map<String, dynamic>
          : null,
      details: asString(json['details']),
      ip: asString(json['ip']),
      userAgent: asString(json['user_agent'] ?? json['userAgent']),
      timestamp: parseDate(json['timestamp']) ?? DateTime.now().toUtc(),
      retentionExpires: parseDate(
          json['retention_expires'] ?? json['retentionExpires']),
    );
  }

  /// `true` when the entry was produced by an automated system job
  /// (cron, webhook, IoT pipeline) rather than a human actor.
  bool get isSystem => actorRole == 'system' || actorId == null;

  /// `true` when the action verb denotes a destructive operation.
  bool get isDestructive =>
      action.endsWith('.delete') ||
      action.endsWith('.purge') ||
      action.endsWith('.disable');

  /// Convenience tuple of `(targetType, entityId)` for diff views.
  ({String type, String id})? get target => targetType == null || entityId == null
      ? null
      : (type: targetType!, id: entityId!);

  /// Serialises the entry back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        if (actorId != null) 'actor_id': actorId,
        'actor_role': actorRole,
        if (actorEmail != null) 'actor_email': actorEmail,
        'action': action,
        if (targetType != null) 'target_type': targetType,
        if (entityId != null) 'target_id': entityId,
        if (before != null) 'before': before,
        if (after != null) 'after': after,
        if (details != null) 'details': details,
        if (ip != null) 'ip': ip,
        if (userAgent != null) 'user_agent': userAgent,
        'timestamp': timestamp.toIso8601String(),
        if (retentionExpires != null)
          'retention_expires': retentionExpires!.toIso8601String(),
      };

  /// Returns a copy of this entry with the given fields replaced.
  AuditLogEntry copyWith({
    String? id,
    String? actorId,
    String? actorRole,
    String? actorEmail,
    String? action,
    String? targetType,
    String? entityId,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    String? details,
    String? ip,
    String? userAgent,
    DateTime? timestamp,
    DateTime? retentionExpires,
  }) {
    return AuditLogEntry(
      id: id ?? this.id,
      actorId: actorId ?? this.actorId,
      actorRole: actorRole ?? this.actorRole,
      actorEmail: actorEmail ?? this.actorEmail,
      action: action ?? this.action,
      targetType: targetType ?? this.targetType,
      entityId: entityId ?? this.entityId,
      before: before ?? this.before,
      after: after ?? this.after,
      details: details ?? this.details,
      ip: ip ?? this.ip,
      userAgent: userAgent ?? this.userAgent,
      timestamp: timestamp ?? this.timestamp,
      retentionExpires: retentionExpires ?? this.retentionExpires,
    );
  }

  @override
  String toString() =>
      'AuditLogEntry(action: $action, actor: $actorRole, at: $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogEntry && other.id == id);

  @override
  int get hashCode => id.hashCode;
}


