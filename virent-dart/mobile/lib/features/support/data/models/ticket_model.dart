import 'package:flutter/material.dart';
import '../../../../core/configs/theme/app_colors.dart' show AppColors;

/// Status of a support ticket.
enum TicketStatus {
  /// Newly created, awaiting agent response.
  open,

  /// Agent has replied and is waiting for the user.
  waiting,

  /// Issue resolved and the ticket auto-closes after a grace period.
  resolved,

  /// Permanently closed.
  closed,
}

/// Category of a support ticket — drives the badge colour and icon.
enum TicketType {
  /// Scooter malfunction (brakes, battery, IoT).
  breakdown,

  /// Wallet / refund / chargeback question.
  billing,

  /// Login, OTP, account-recovery issue.
  account,

  /// Anything that doesn't fit the above.
  other,
}

/// A single chat message inside a support ticket thread.
class TicketMessage {
  /// Creates a message.
  const TicketMessage({
    required this.id,
    required this.author,
    required this.body,
    required this.fromUser,
    required this.createdAt,
  });

  /// Server-assigned message id.
  final String id;

  /// Display name of the sender (`You`, `Support Agent`, ...).
  final String author;

  /// Message body (plain text).
  final String body;

  /// `true` when the message came from the user, `false` from support.
  final bool fromUser;

  /// When the message was sent.
  final DateTime createdAt;

  /// Parses a JSON object into a [TicketMessage].
  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      author: (json['author'] ??
              (json['from_user'] == true ? 'You' : 'Support'))
          .toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      fromUser: (json['from_user'] ?? json['is_user'] ?? false) as bool,
      createdAt: _parseTime(json['created_at'] ?? json['timestamp']),
    );
  }

  /// Serialises the message back to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'body': body,
        'from_user': fromUser,
        'created_at': createdAt.toIso8601String(),
      };

  static DateTime _parseTime(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    final s = raw?.toString();
    if (s == null || s.isEmpty) return DateTime.now();
    return DateTime.tryParse(s) ?? DateTime.now();
  }
}

/// A support ticket (chat thread between user and support team).
class Ticket {
  /// Creates a ticket.
  const Ticket({
    required this.id,
    required this.subject,
    required this.status,
    required this.type,
    required this.messages,
    required this.createdAt,
    this.updatedAt,
  });

  /// Server-assigned ticket id.
  final String id;

  /// One-line summary entered by the user.
  final String subject;

  /// Current workflow status.
  final TicketStatus status;

  /// Category of the issue.
  final TicketType type;

  /// Chronological list of messages (oldest first).
  final List<TicketMessage> messages;

  /// When the ticket was created.
  final DateTime createdAt;

  /// When the ticket was last updated.
  final DateTime? updatedAt;

  /// Number of messages in the thread.
  int get messageCount => messages.length;

  /// The most recent message, or `null` if the thread is empty.
  TicketMessage? get lastMessage =>
      messages.isEmpty ? null : messages.last;

  /// Parses a JSON object into a [Ticket].
  factory Ticket.fromJson(Map<String, dynamic> json) {
    final rawMessages = (json['messages'] as List? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(TicketMessage.fromJson)
        .toList();
    return Ticket(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      subject: (json['subject'] ?? json['title'] ?? '').toString(),
      status: _parseStatus(json['status']),
      type: _parseType(json['type'] ?? json['category']),
      messages: rawMessages,
      createdAt: _parseTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseTimeOrNull(json['updated_at']),
    );
  }

  /// Serialises the ticket back to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'status': status.name,
        'type': type.name,
        'messages': messages.map((m) => m.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// Returns a copy with the supplied fields replaced.
  Ticket copyWith({
    String? id,
    String? subject,
    TicketStatus? status,
    TicketType? type,
    List<TicketMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      type: type ?? this.type,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static TicketStatus _parseStatus(dynamic raw) {
    switch (raw?.toString()) {
      case 'open':
        return TicketStatus.open;
      case 'waiting':
        return TicketStatus.waiting;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
      default:
        return TicketStatus.closed;
    }
  }

  static TicketType _parseType(dynamic raw) {
    switch (raw?.toString()) {
      case 'breakdown':
        return TicketType.breakdown;
      case 'billing':
        return TicketType.billing;
      case 'account':
        return TicketType.account;
      case 'other':
      default:
        return TicketType.other;
    }
  }

  static DateTime _parseTime(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    final s = raw?.toString();
    if (s == null || s.isEmpty) return DateTime.now();
    return DateTime.tryParse(s) ?? DateTime.now();
  }

  static DateTime? _parseTimeOrNull(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return DateTime.tryParse(raw.toString());
  }
}

/// Extension adding icon + colour helpers to [TicketType].
extension TicketTypeX on TicketType {
  /// Material icon used for the type badge.
  IconData get icon {
    switch (this) {
      case TicketType.breakdown:
        return Icons.build;
      case TicketType.billing:
        return Icons.receipt_long;
      case TicketType.account:
        return Icons.person;
      case TicketType.other:
        return Icons.help;
    }
  }

  /// Accent colour for the badge.
  Color get color {
    switch (this) {
      case TicketType.breakdown:
        return AppColors.danger;
      case TicketType.billing:
        return AppColors.warning;
      case TicketType.account:
        return AppColors.info;
      case TicketType.other:
        return AppColors.textSecondary;
    }
  }
}

/// Extension adding icon + colour helpers to [TicketStatus].
extension TicketStatusX on TicketStatus {
  /// Accent colour for the status badge.
  Color get color {
    switch (this) {
      case TicketStatus.open:
        return AppColors.warning;
      case TicketStatus.waiting:
        return AppColors.info;
      case TicketStatus.resolved:
        return AppColors.success;
      case TicketStatus.closed:
        return AppColors.textSecondary;
    }
  }
}
