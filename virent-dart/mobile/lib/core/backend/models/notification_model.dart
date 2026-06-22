/// Push-notification model.
///
/// Ported from `backend/v1/models/notifications.js`. Notifications are
/// persisted server-side (the `notifications` MongoDB collection) and
/// pushed via FCM (Android), APNs (iOS) or Web Push. SMS is the fallback
/// channel for critical alerts.
///
/// The mobile client renders two shapes:
///   * individual user-targeted notifications (`POST /notifications/:id/read`)
///   * admin-broadcast campaigns (`POST /notifications/broadcast`)
///
/// This model captures both — a [NotificationModel] is the same shape
/// whether it was produced by `notifications.send()` (single user) or
/// `notifications.broadcast()` (all users).
library;


import 'json_helpers.dart';
/// Notification type slug. Mirrors the `type` field set by various
/// backend modules (`notifications.send`, `iot.event`, `geofencing`,
/// `support.create`, ...).
enum NotificationType {
  /// Generic broadcast (admin → all users).
  broadcast,

  /// General user-targeted message.
  general,

  /// Trip-end summary with cost breakdown.
  tripEnded,

  /// Low-battery warning during an active trip.
  lowBattery,

  /// Scooter-side event (alarm, fall, geofence breach).
  iotEvent,

  /// Zone-violation warning (no-parking, outside-city).
  zoneViolation,

  /// Promo or referral bonus credited.
  promo,

  /// Support-ticket update (admin reply, status change).
  supportUpdate,

  /// Payment / billing event (top-up success, refund, low balance).
  payment,

  /// Anything the client doesn't yet understand.
  unknown;

  static NotificationType fromString(String? raw) {
    switch (raw) {
      case 'broadcast':
        return NotificationType.broadcast;
      case 'general':
        return NotificationType.general;
      case 'trip_ended':
      case 'trip_end':
        return NotificationType.tripEnded;
      case 'low_battery':
        return NotificationType.lowBattery;
      case 'iot_event':
        return NotificationType.iotEvent;
      case 'zone_violation':
        return NotificationType.zoneViolation;
      case 'promo':
        return NotificationType.promo;
      case 'support_update':
        return NotificationType.supportUpdate;
      case 'payment':
        return NotificationType.payment;
      default:
        return NotificationType.unknown;
    }
  }

  String get wire => switch (this) {
        NotificationType.broadcast => 'broadcast',
        NotificationType.general => 'general',
        NotificationType.tripEnded => 'trip_ended',
        NotificationType.lowBattery => 'low_battery',
        NotificationType.iotEvent => 'iot_event',
        NotificationType.zoneViolation => 'zone_violation',
        NotificationType.promo => 'promo',
        NotificationType.supportUpdate => 'support_update',
        NotificationType.payment => 'payment',
        NotificationType.unknown => 'unknown',
      };
}

/// Delivery status for a notification campaign (admin view).
enum NotificationStatus {
  /// Campaign drafted, not yet sent.
  draft,

  /// Campaign queued for delivery.
  queued,

  /// Delivery in progress.
  sending,

  /// All recipients reached (or attempted).
  sent,

  /// Delivery paused (e.g. rate-limit hit).
  paused,

  /// Campaign cancelled by admin.
  cancelled;

  static NotificationStatus fromString(String? raw) {
    switch (raw) {
      case 'draft':
        return NotificationStatus.draft;
      case 'queued':
        return NotificationStatus.queued;
      case 'sending':
        return NotificationStatus.sending;
      case 'sent':
      case 'delivered':
        return NotificationStatus.sent;
      case 'paused':
        return NotificationStatus.paused;
      case 'cancelled':
        return NotificationStatus.cancelled;
      default:
        return NotificationStatus.sent;
    }
  }

  String get wire => switch (this) {
        NotificationStatus.draft => 'draft',
        NotificationStatus.queued => 'queued',
        NotificationStatus.sending => 'sending',
        NotificationStatus.sent => 'sent',
        NotificationStatus.paused => 'paused',
        NotificationStatus.cancelled => 'cancelled',
      };
}

/// User-target or admin-broadcast notification.
///
/// Mirrors the document shape created by `notifications.send()` and
/// `notifications.broadcast()`.
class NotificationModel {
  /// MongoDB `_id` of the notification.
  final String id;

  /// `_id` of the recipient user. `null` for broadcast rows that have
  /// been fanned out to many users (each fan-out row gets the user_id
  /// populated; the campaign document itself keeps it `null`).
  final String? userId;

  /// Short headline shown in the system tray.
  final String title;

  /// Body text. May contain placeholders that the client substitutes
  /// (e.g. `{{amount}}`).
  final String body;

  /// Type slug, mapped to [NotificationType].
  final NotificationType type;

  /// Raw type string (preserved for forward compatibility).
  final String typeRaw;

  /// Audience segment the notification was sent to:
  /// `all`, `active_riders`, `juicers`, `mechanics`, `admins`, `city:XXX`.
  final String segment;

  /// Lifecycle status of the campaign (admin view).
  final NotificationStatus status;

  /// Number of recipients targeted by the campaign.
  final int targetCount;

  /// Number of recipients who have opened (read) the notification.
  final int readCount;

  /// Number of devices that successfully received the push.
  final int deliveredCount;

  /// Free-form data bag (deep-link, trip_id, scooter_id, ...).
  final Map<String, dynamic> data;

  /// When the notification was created (UTC).
  final DateTime? createdAt;

  /// When the notification was actually pushed to FCM/APNs/Web Push.
  /// For user-targeted single-send notifications this equals [createdAt].
  final DateTime? sentAt;

  /// When the recipient opened the notification (UTC). `null` until read.
  final DateTime? readAt;

  /// Creates a [NotificationModel].
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.typeRaw,
    this.userId,
    this.segment = 'all',
    this.status = NotificationStatus.sent,
    this.targetCount = 0,
    this.readCount = 0,
    this.deliveredCount = 0,
    this.data = const {},
    this.createdAt,
    this.sentAt,
    this.readAt,
  });

  /// Parses a JSON object (MongoDB document) into a [NotificationModel].
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? 'general').toString();
    return NotificationModel(
      id: stringifyId(json['_id'] ?? json['id']),
      userId: stringifyIdNullable(json['user_id'] ?? json['userId']),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      type: NotificationType.fromString(rawType),
      typeRaw: rawType,
      segment: (json['segment'] ?? 'all').toString(),
      status: NotificationStatus.fromString(json['status']?.toString()),
      targetCount: toInt(json['target_count'] ?? json['targetCount']),
      readCount: toInt(json['read_count'] ?? json['readCount']),
      deliveredCount:
          toInt(json['delivered_count'] ?? json['deliveredCount']),
      data: json['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      sentAt: parseDate(json['sent_at'] ?? json['sentAt']),
      readAt: parseDate(json['read_at'] ?? json['readAt']),
    );
  }

  /// `true` when the recipient has opened the notification.
  bool get isRead => readAt != null;

  /// Open rate in the range `[0, 1]`. `0` when [targetCount] is zero.
  double get openRate =>
      targetCount == 0 ? 0 : (readCount / targetCount).clamp(0, 1);

  /// Delivery rate in the range `[0, 1]`. `0` when [targetCount] is zero.
  double get deliveryRate =>
      targetCount == 0 ? 0 : (deliveredCount / targetCount).clamp(0, 1);

  /// `true` when the notification denotes a safety-critical event.
  bool get isSafetyCritical =>
      type == NotificationType.zoneViolation ||
      type == NotificationType.iotEvent;

  /// Serialises the model back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        if (userId != null) 'user_id': userId,
        'title': title,
        'body': body,
        'type': typeRaw,
        'segment': segment,
        'status': status.wire,
        'target_count': targetCount,
        'read_count': readCount,
        'delivered_count': deliveredCount,
        'data': data,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (sentAt != null) 'sent_at': sentAt!.toIso8601String(),
        if (readAt != null) 'read_at': readAt!.toIso8601String(),
      };

  /// Returns a copy of this model with the given fields replaced.
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? typeRaw,
    String? segment,
    NotificationStatus? status,
    int? targetCount,
    int? readCount,
    int? deliveredCount,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      typeRaw: typeRaw ?? this.typeRaw,
      segment: segment ?? this.segment,
      status: status ?? this.status,
      targetCount: targetCount ?? this.targetCount,
      readCount: readCount ?? this.readCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  String toString() =>
      'NotificationModel($typeRaw, title: "$title", read: $isRead)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Registered device token for push delivery.
///
/// Mirrors the `device_tokens` collection shape. Each user may have
/// multiple devices (one phone, one tablet, one web browser).
class DeviceToken {
  /// MongoDB `_id`.
  final String id;

  /// `_id` of the user owning the device.
  final String userId;

  /// Platform: `android`, `ios`, `web`.
  final String platform;

  /// FCM / APNs / Web Push token string.
  final String token;

  /// `true` when the token is still valid (not unregistered).
  final bool active;

  /// When the token was first registered.
  final DateTime? createdAt;

  /// When the token was last used to push a notification.
  final DateTime? lastUsedAt;

  /// When the user explicitly unregistered the device, if applicable.
  final DateTime? unregisteredAt;

  const DeviceToken({
    required this.id,
    required this.userId,
    required this.platform,
    required this.token,
    this.active = true,
    this.createdAt,
    this.lastUsedAt,
    this.unregisteredAt,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) => DeviceToken(
        id: stringifyId(json['_id'] ?? json['id']),
        userId: stringifyId(json['user_id'] ?? json['userId']),
        platform: (json['platform'] ?? 'android').toString(),
        token: (json['token'] ?? '').toString(),
        active: json['active'] != false,
        createdAt: parseDate(json['created_at']),
        lastUsedAt: parseDate(json['last_used_at']),
        unregisteredAt: parseDate(json['unregistered_at']),
      );

  /// `true` when the token is for an Android device.
  bool get isAndroid => platform == 'android';

  /// `true` when the token is for an iOS device.
  bool get isIos => platform == 'ios';

  /// `true` when the token is for a web browser.
  bool get isWeb => platform == 'web';

  Map<String, dynamic> toJson() => {
        '_id': id,
        'user_id': userId,
        'platform': platform,
        'token': token,
        'active': active,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (lastUsedAt != null) 'last_used_at': lastUsedAt!.toIso8601String(),
        if (unregisteredAt != null)
          'unregistered_at': unregisteredAt!.toIso8601String(),
      };

  @override
  String toString() =>
      'DeviceToken($platform, active: $active, lastUsed: $lastUsedAt)';
}

// --- internal helpers ----------------------------------------------------


