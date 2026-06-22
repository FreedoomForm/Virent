import 'package:flutter/material.dart';
import '../../../../core/configs/theme/app_colors.dart' show AppColors;

/// Category of a notification — drives the icon and accent colour used in
/// the notification card and screen list.
enum NotificationType {
  /// Trip started / ended / completed.
  trip,

  /// Wallet top-up, refund, low-balance warning.
  wallet,

  /// Promo code applied, campaign broadcast.
  promo,

  /// Zone created, modified, or geofence breach.
  zone,

  /// System / account notice (e.g. maintenance, terms update).
  system,
}

/// A single notification delivered to the user.
///
/// Ported from BarqScoot's `NotificationItem` model but extended with the
/// extra fields the legacy Node backend stores (`type` as a string + a
/// nullable deep-link `targetId`). The model is pure (no Riverpod / Flutter
/// widgets) so it can be unit-tested in isolation.
class AppNotification {
  /// Creates a notification.
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.time,
    this.targetId,
  });

  /// Server-assigned unique id.
  final String id;

  /// Short headline shown in bold.
  final String title;

  /// Longer body copy (one or two sentences).
  final String body;

  /// Category used to pick the icon and colour.
  final NotificationType type;

  /// Whether the user has already opened this notification.
  final bool read;

  /// Server timestamp of when the notification was created.
  final DateTime time;

  /// Optional deep-link target (e.g. trip id, wallet txn id).
  final String? targetId;

  /// Parses a JSON object (as returned by `/notifications`) into an
  /// [AppNotification].
  ///
  /// Accepts both camelCase and snake_case keys and tolerates missing
  /// fields by falling back to safe defaults.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? json['description'] ?? json['message'] ?? '')
          .toString(),
      type: _parseType(json['type']),
      read: (json['read'] ?? json['is_read'] ?? false) as bool,
      time: _parseTime(json['time'] ?? json['created_at'] ?? json['timestamp']),
      targetId: json['target_id']?.toString(),
    );
  }

  /// Serialises the notification back to JSON (used for local caching).
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'read': read,
        'time': time.toIso8601String(),
        if (targetId != null) 'target_id': targetId,
      };

  /// Returns a copy with the supplied fields replaced.
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    bool? read,
    DateTime? time,
    String? targetId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      read: read ?? this.read,
      time: time ?? this.time,
      targetId: targetId ?? this.targetId,
    );
  }

  /// Coerces a string / int into a [NotificationType].
  static NotificationType _parseType(dynamic raw) {
    switch (raw?.toString()) {
      case 'trip':
      case 'ride':
        return NotificationType.trip;
      case 'wallet':
      case 'payment':
        return NotificationType.wallet;
      case 'promo':
      case 'promotion':
        return NotificationType.promo;
      case 'zone':
        return NotificationType.zone;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

  /// Parses the server timestamp (ISO-8601 or epoch millis) into [DateTime].
  static DateTime _parseTime(dynamic raw) {
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    final s = raw?.toString();
    if (s == null || s.isEmpty) return DateTime.now();
    return DateTime.tryParse(s) ?? DateTime.now();
  }
}

/// Extension adding icon + colour helpers to [NotificationType].
extension NotificationTypeX on NotificationType {
  /// Material icon used for this category.
  IconData get icon {
    switch (this) {
      case NotificationType.trip:
        return Icons.route;
      case NotificationType.wallet:
        return Icons.account_balance_wallet;
      case NotificationType.promo:
        return Icons.card_giftcard;
      case NotificationType.zone:
        return Icons.crop_free;
      case NotificationType.system:
        return Icons.info;
    }
  }

  /// Accent colour used for the icon background.
  Color get color {
    switch (this) {
      case NotificationType.trip:
        return AppColors.primary;
      case NotificationType.wallet:
        return AppColors.success;
      case NotificationType.promo:
        return AppColors.warning;
      case NotificationType.zone:
        return AppColors.info;
      case NotificationType.system:
        return AppColors.textSecondary;
    }
  }
}
