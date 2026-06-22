/// Support-ticket and breakdown-report models.
///
/// Ported from `backend/v1/models/support.js`. The backend supports
/// four ticket types (`breakdown`, `billing`, `account`, `other`) and
/// a status lifecycle `open → in_progress → resolved → closed`.
/// Breakdown tickets additionally carry scooter/problem-category
/// metadata and auto-mark the scooter for maintenance.
library;


import 'json_helpers.dart';
/// Ticket type bucket. Mirrors the `type` enum validated in
/// `support.js::create`.
enum SupportTicketType {
  /// Scooter malfunction report. Requires `scooterId` + `problemCategory`.
  breakdown,

  /// Payment or billing dispute.
  billing,

  /// Account-access issue (login, password, phone change).
  account,

  /// General question or feedback.
  other;

  static SupportTicketType fromString(String? raw) {
    switch (raw) {
      case 'breakdown':
        return SupportTicketType.breakdown;
      case 'billing':
        return SupportTicketType.billing;
      case 'account':
        return SupportTicketType.account;
      default:
        return SupportTicketType.other;
    }
  }

  String get wire => switch (this) {
        SupportTicketType.breakdown => 'breakdown',
        SupportTicketType.billing => 'billing',
        SupportTicketType.account => 'account',
        SupportTicketType.other => 'other',
      };
}

/// Lifecycle status of a ticket.
enum SupportTicketStatus {
  open,
  inProgress,
  resolved,
  closed;

  static SupportTicketStatus fromString(String? raw) {
    switch (raw) {
      case 'open':
        return SupportTicketStatus.open;
      case 'in_progress':
        return SupportTicketStatus.inProgress;
      case 'resolved':
        return SupportTicketStatus.resolved;
      case 'closed':
        return SupportTicketStatus.closed;
      default:
        return SupportTicketStatus.open;
    }
  }

  String get wire => switch (this) {
        SupportTicketStatus.open => 'open',
        SupportTicketStatus.inProgress => 'in_progress',
        SupportTicketStatus.resolved => 'resolved',
        SupportTicketStatus.closed => 'closed',
      };

  bool get isOpen =>
      this == SupportTicketStatus.open ||
      this == SupportTicketStatus.inProgress;

  bool get isTerminal =>
      this == SupportTicketStatus.resolved ||
      this == SupportTicketStatus.closed;
}

/// Priority bucket. Mirrors the `priority` field set at ticket creation
/// (`high` for breakdown, `normal` otherwise) and adjustable by admins.
enum SupportTicketPriority {
  low,
  normal,
  high,
  critical;

  static SupportTicketPriority fromString(String? raw) {
    switch (raw) {
      case 'low':
        return SupportTicketPriority.low;
      case 'high':
        return SupportTicketPriority.high;
      case 'critical':
      case 'urgent':
        return SupportTicketPriority.critical;
      default:
        return SupportTicketPriority.normal;
    }
  }

  String get wire => switch (this) {
        SupportTicketPriority.low => 'low',
        SupportTicketPriority.normal => 'normal',
        SupportTicketPriority.high => 'high',
        SupportTicketPriority.critical => 'critical',
      };
}

/// Breakdown problem category. Mirrors the `PROBLEM_CATEGORIES` array
/// in `support.js`.
enum ProblemCategory {
  wheel,
  brake,
  battery,
  lock,
  display,
  throttle,
  frame,
  lighting,
  other;

  static ProblemCategory fromString(String? raw) {
    switch (raw) {
      case 'wheel':
        return ProblemCategory.wheel;
      case 'brake':
        return ProblemCategory.brake;
      case 'battery':
        return ProblemCategory.battery;
      case 'lock':
        return ProblemCategory.lock;
      case 'display':
        return ProblemCategory.display;
      case 'throttle':
        return ProblemCategory.throttle;
      case 'frame':
        return ProblemCategory.frame;
      case 'lighting':
        return ProblemCategory.lighting;
      default:
        return ProblemCategory.other;
    }
  }

  String get wire => switch (this) {
        ProblemCategory.wheel => 'wheel',
        ProblemCategory.brake => 'brake',
        ProblemCategory.battery => 'battery',
        ProblemCategory.lock => 'lock',
        ProblemCategory.display => 'display',
        ProblemCategory.throttle => 'throttle',
        ProblemCategory.frame => 'frame',
        ProblemCategory.lighting => 'lighting',
        ProblemCategory.other => 'other',
      };
}

/// Author of a [TicketMessage].
enum MessageAuthor {
  /// End user (the ticket creator or a subsequent reply).
  user,

  /// Admin/support agent.
  admin,

  /// Automated system message (e.g. status-change notification).
  system;

  static MessageAuthor fromString(String? raw) {
    switch (raw) {
      case 'user':
        return MessageAuthor.user;
      case 'admin':
      case 'support':
        return MessageAuthor.admin;
      default:
        return MessageAuthor.system;
    }
  }

  String get wire => switch (this) {
        MessageAuthor.user => 'user',
        MessageAuthor.admin => 'admin',
        MessageAuthor.system => 'system',
      };
}

/// Single chat-style message on a ticket.
class TicketMessage {
  /// MongoDB `_id` of the message (auto-generated when the backend
  /// pushes to the `messages` array).
  final String? id;

  /// Who authored the message.
  final MessageAuthor from;

  /// `_id` of the user or admin who authored the message.
  final String? authorId;

  /// Plain-text body. Markdown not supported by the backend.
  final String message;

  /// When the message was posted.
  final DateTime? createdAt;

  const TicketMessage({
    this.id,
    required this.from,
    this.authorId,
    required this.message,
    this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) =>
      TicketMessage(
        id: stringifyIdNullable(json['_id'] ?? json['id']),
        from: MessageAuthor.fromString(json['from']?.toString()),
        authorId: stringifyIdNullable(
            json['user_id'] ?? json['admin_id'] ?? json['author_id']),
        message: (json['message'] ?? '').toString(),
        createdAt: parseDate(json['created_at']),
      );

  /// `true` when the message was authored by the end user.
  bool get isFromUser => from == MessageAuthor.user;

  /// `true` when the message was authored by an admin/support agent.
  bool get isFromAdmin => from == MessageAuthor.admin;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'from': from.wire,
        if (authorId != null)
          (from == MessageAuthor.admin ? 'admin_id' : 'user_id'): authorId,
        'message': message,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  @override
  String toString() =>
      'TicketMessage(from: $from, ${createdAt != null ? createdAt : 'unsent'})';
}

/// Support-ticket document.
class SupportTicket {
  /// MongoDB `_id` of the ticket.
  final String id;

  /// `_id` of the user who created the ticket.
  final String userId;

  /// Ticket type bucket.
  final SupportTicketType type;

  /// Short subject line.
  final String subject;

  /// Lifecycle status.
  final SupportTicketStatus status;

  /// Priority bucket.
  final SupportTicketPriority priority;

  /// Ordered chat-style messages (oldest first).
  final List<TicketMessage> messages;

  /// `_id` of the admin assigned to the ticket. `null` while unassigned.
  final String? assignedTo;

  /// `_id` of the scooter referenced by a breakdown ticket.
  final String? scooterId;

  /// `_id` of the trip referenced by the ticket, when applicable.
  final String? tripId;

  /// Problem category for breakdown tickets. `null` for other types.
  final ProblemCategory? problemCategory;

  /// URL of the photo attached to a breakdown report.
  final String? photoUrl;

  /// Admin-written resolution note, populated on `resolved`.
  final String? resolutionNote;

  /// When the ticket was created.
  final DateTime? createdAt;

  /// When the ticket was last updated.
  final DateTime? updatedAt;

  /// When the ticket was resolved.
  final DateTime? resolvedAt;

  /// When the ticket was closed (terminal state).
  final DateTime? closedAt;

  /// Creates a [SupportTicket].
  const SupportTicket({
    required this.id,
    required this.userId,
    required this.type,
    required this.subject,
    required this.status,
    required this.priority,
    required this.messages,
    this.assignedTo,
    this.scooterId,
    this.tripId,
    this.problemCategory,
    this.photoUrl,
    this.resolutionNote,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.closedAt,
  });

  /// Parses a JSON object (MongoDB document) into a [SupportTicket].
  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final rawProblem = json['problem_category'];
    return SupportTicket(
      id: stringifyId(json['_id'] ?? json['id']),
      userId: stringifyId(json['user_id'] ?? json['userId']),
      type: SupportTicketType.fromString(json['type']?.toString()),
      subject: (json['subject'] ?? '').toString(),
      status: SupportTicketStatus.fromString(json['status']?.toString()),
      priority: SupportTicketPriority.fromString(
          json['priority']?.toString()),
      messages: rawMessages is List
          ? rawMessages
              .whereType<Map>()
              .map((m) => TicketMessage.fromJson(m as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      assignedTo: stringifyIdNullable(
          json['assigned_to'] ?? json['assignedTo']),
      scooterId: stringifyIdNullable(
          json['scooter_id'] ?? json['scooterId']),
      tripId: stringifyIdNullable(json['trip_id'] ?? json['tripId']),
      problemCategory: rawProblem == null
          ? null
          : ProblemCategory.fromString(rawProblem.toString()),
      photoUrl: asString(json['photo_url'] ?? json['photoUrl']),
      resolutionNote: asString(json['resolution_note']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      resolvedAt: parseDate(json['resolved_at']),
      closedAt: parseDate(json['closed_at']),
    );
  }

  /// Most recent message in the thread, or `null` when empty.
  TicketMessage? get lastMessage =>
      messages.isEmpty ? null : messages.last;

  /// Count of admin replies in the thread.
  int get adminReplyCount =>
      messages.where((m) => m.isFromAdmin).length;

  /// `true` when the ticket is awaiting first admin response.
  bool get isAwaitingResponse =>
      status == SupportTicketStatus.open && adminReplyCount == 0;

  /// `true` when the ticket is a breakdown report.
  bool get isBreakdown => type == SupportTicketType.breakdown;

  /// Wall-clock duration from creation to resolution, in minutes.
  /// `null` when not yet resolved.
  int? get resolutionMinutes => resolvedAt == null || createdAt == null
      ? null
      : resolvedAt!.difference(createdAt!).inMinutes;

  /// Serialises the ticket back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        'user_id': userId,
        'type': type.wire,
        'subject': subject,
        'status': status.wire,
        'priority': priority.wire,
        'messages': messages.map((m) => m.toJson()).toList(),
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (scooterId != null) 'scooter_id': scooterId,
        if (tripId != null) 'trip_id': tripId,
        if (problemCategory != null)
          'problem_category': problemCategory!.wire,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (resolutionNote != null) 'resolution_note': resolutionNote,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
        if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
      };

  /// Returns a copy of this ticket with the given fields replaced.
  SupportTicket copyWith({
    String? id,
    String? userId,
    SupportTicketType? type,
    String? subject,
    SupportTicketStatus? status,
    SupportTicketPriority? priority,
    List<TicketMessage>? messages,
    String? assignedTo,
    String? scooterId,
    String? tripId,
    ProblemCategory? problemCategory,
    String? photoUrl,
    String? resolutionNote,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    DateTime? closedAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      messages: messages ?? this.messages,
      assignedTo: assignedTo ?? this.assignedTo,
      scooterId: scooterId ?? this.scooterId,
      tripId: tripId ?? this.tripId,
      problemCategory: problemCategory ?? this.problemCategory,
      photoUrl: photoUrl ?? this.photoUrl,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  @override
  String toString() =>
      'SupportTicket($type, status: $status, subject: "$subject", msgs: ${messages.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupportTicket && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// --- internal helpers ----------------------------------------------------


