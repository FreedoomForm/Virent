/// Juicer (scooter-charging gig worker) model.
///
/// Ported from `backend/v1/models/juicers.js`. Juicers pick up
/// low-battery scooters at night, charge them at home, and return them
/// to charging zones in the morning. They are paid a flat rate per
/// completed task (`JUICER_PAY_PER_SCOOTER = 5000 UZS` in the JS module).
///
/// This file ports the juicer profile document plus the related
/// `juicer_tasks` document and the earnings-summary response shape.
library;


import 'json_helpers.dart';
/// Juicer account status.
enum JuicerStatus {
  /// Can claim and complete tasks.
  active,

  /// Temporarily blocked (e.g. failed return rate too high).
  suspended,

  /// Anything the client doesn't yet understand.
  unknown;

  static JuicerStatus fromString(String? raw) {
    switch (raw) {
      case 'active':
        return JuicerStatus.active;
      case 'suspended':
      case 'paused':
        return JuicerStatus.suspended;
      default:
        return JuicerStatus.unknown;
    }
  }

  String get wire => switch (this) {
        JuicerStatus.active => 'active',
        JuicerStatus.suspended => 'suspended',
        JuicerStatus.unknown => 'unknown',
      };
}

/// Lifecycle of a juicer task.
enum JuicerTaskStatus {
  /// Claimed by juicer, awaiting pickup.
  assigned,

  /// Juicer has physically picked up the scooter.
  pickedUp,

  /// Juicer has charged the scooter overnight.
  charged,

  /// Juicer returned the scooter to a charging zone.
  /// Terminal state — payout is credited on transition to this status.
  returned,

  /// Task cancelled (scooter recovered by another juicer or admin).
  cancelled;

  static JuicerTaskStatus fromString(String? raw) {
    switch (raw) {
      case 'assigned':
        return JuicerTaskStatus.assigned;
      case 'picked_up':
        return JuicerTaskStatus.pickedUp;
      case 'charged':
        return JuicerTaskStatus.charged;
      case 'returned':
        return JuicerTaskStatus.returned;
      case 'cancelled':
        return JuicerTaskStatus.cancelled;
      default:
        return JuicerTaskStatus.assigned;
    }
  }

  String get wire => switch (this) {
        JuicerTaskStatus.assigned => 'assigned',
        JuicerTaskStatus.pickedUp => 'picked_up',
        JuicerTaskStatus.charged => 'charged',
        JuicerTaskStatus.returned => 'returned',
        JuicerTaskStatus.cancelled => 'cancelled',
      };

  /// `true` when the status is one of the active work-in-progress states.
  bool get isOpen =>
      this == JuicerTaskStatus.assigned ||
      this == JuicerTaskStatus.pickedUp ||
      this == JuicerTaskStatus.charged;
}

/// Juicer profile.
///
/// Mirrors the document shape created by `juicers.js::register` and
/// updated by `markReturned` (which `$inc`s the totals).
class JuicerModel {
  /// MongoDB `_id` of the juicer.
  final String id;

  /// Phone number in `+998XXXXXXXXX` format.
  final String phone;

  /// Given name.
  final String firstName;

  /// Family name.
  final String lastName;

  /// Account status (active/suspended).
  final JuicerStatus status;

  /// Per-scooter pay rate in UZS tiyin. Defaults to 5000 when the backend
  /// does not specify `pay_rate`.
  final int payRate;

  /// Lifetime earnings in UZS tiyin (sum of [JuicerTask.payAmount] across
  /// all `returned` tasks).
  final int earnings;

  /// Total number of scooters charged (count of `returned` tasks).
  final int tasksCompleted;

  /// Count of tasks currently in `assigned`/`picked_up`/`charged` state.
  final int activeTasks;

  /// Optional rating (0–5 average across admin-set scores). `null` until
  /// at least one rating is recorded.
  final double? rating;

  /// Account creation timestamp.
  final DateTime? createdAt;

  /// Last profile mutation timestamp.
  final DateTime? updatedAt;

  /// Creates a [JuicerModel].
  const JuicerModel({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.status = JuicerStatus.active,
    this.payRate = 5000,
    this.earnings = 0,
    this.tasksCompleted = 0,
    this.activeTasks = 0,
    this.rating,
    this.createdAt,
    this.updatedAt,
  });

  /// Parses a JSON object (MongoDB document) into a [JuicerModel].
  factory JuicerModel.fromJson(Map<String, dynamic> json) => JuicerModel(
        id: stringifyId(json['_id'] ?? json['id']),
        phone: (json['phone'] ?? '').toString(),
        firstName: (json['firstName'] ?? json['first_name'] ?? '').toString(),
        lastName: (json['lastName'] ?? json['last_name'] ?? '').toString(),
        status: JuicerStatus.fromString(json['status']?.toString()),
        payRate: toInt(json['pay_rate'] ?? json['payRate'] ?? 5000),
        earnings: toInt(json['total_earned'] ?? json['earnings']),
        tasksCompleted:
            toInt(json['total_scooters_charged'] ?? json['tasks_completed']),
        activeTasks: toInt(
            json['current_tasks'] is List ? (json['current_tasks'] as List).length : json['current_tasks']),
        rating: _toDoubleOrNull(json['rating']),
        createdAt: parseDate(json['created_at'] ?? json['createdAt']),
        updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
      );

  /// Display name helper.
  String get fullName => '$firstName $lastName'.trim();

  /// `true` when the juicer can claim new tasks.
  bool get canClaim => status == JuicerStatus.active;

  /// Average payout per task, in UZS tiyin. `0` when no tasks completed.
  int get avgPayout =>
      tasksCompleted == 0 ? 0 : (earnings / tasksCompleted).round();

  /// Serialises the model back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'status': status.wire,
        'pay_rate': payRate,
        'total_earned': earnings,
        'total_scooters_charged': tasksCompleted,
        if (rating != null) 'rating': rating,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// Returns a copy of this model with the given fields replaced.
  JuicerModel copyWith({
    String? id,
    String? phone,
    String? firstName,
    String? lastName,
    JuicerStatus? status,
    int? payRate,
    int? earnings,
    int? tasksCompleted,
    int? activeTasks,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JuicerModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      status: status ?? this.status,
      payRate: payRate ?? this.payRate,
      earnings: earnings ?? this.earnings,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      activeTasks: activeTasks ?? this.activeTasks,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'JuicerModel($fullName, phone: $phone, tasks: $tasksCompleted, earned: $earnings)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JuicerModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Single juicer task (pickup → charge → return).
class JuicerTask {
  /// MongoDB `_id` of the task.
  final String id;

  /// `_id` of the juicer assigned to the task.
  final String juicerId;

  /// `_id` of the scooter being charged.
  final String scooterId;

  /// Lifecycle status.
  final JuicerTaskStatus status;

  /// Coordinates where the scooter was picked up.
  final TaskCoordinates? pickupCoordinates;

  /// Coordinates where the scooter was returned (charging zone).
  final TaskCoordinates? returnCoordinates;

  /// When the task was assigned.
  final DateTime? assignedAt;

  /// When the juicer physically picked up the scooter.
  final DateTime? pickedUpAt;

  /// When the scooter reached 100% battery (charged overnight).
  final DateTime? chargedAt;

  /// When the scooter was returned to a charging zone.
  final DateTime? returnedAt;

  /// Payout amount credited to the juicer on completion, in UZS tiyin.
  final int payAmount;

  /// `true` when the payout has been credited to the juicer's balance.
  final bool paid;

  /// Task creation timestamp.
  final DateTime? createdAt;

  /// Creates a [JuicerTask].
  const JuicerTask({
    required this.id,
    required this.juicerId,
    required this.scooterId,
    required this.status,
    this.pickupCoordinates,
    this.returnCoordinates,
    this.assignedAt,
    this.pickedUpAt,
    this.chargedAt,
    this.returnedAt,
    this.payAmount = 5000,
    this.paid = false,
    this.createdAt,
  });

  /// Parses a JSON object into a [JuicerTask].
  factory JuicerTask.fromJson(Map<String, dynamic> json) {
    final rawPickup = json['pickup_coordinates'];
    final rawReturn = json['return_coordinates'];
    return JuicerTask(
      id: stringifyId(json['_id'] ?? json['id']),
      juicerId: stringifyId(json['juicer_id'] ?? json['juicerId']),
      scooterId: stringifyId(json['scooter_id'] ?? json['scooterId']),
      status: JuicerTaskStatus.fromString(json['status']?.toString()),
      pickupCoordinates: rawPickup is Map<String, dynamic>
          ? TaskCoordinates.fromJson(rawPickup)
          : null,
      returnCoordinates: rawReturn is Map<String, dynamic>
          ? TaskCoordinates.fromJson(rawReturn)
          : null,
      assignedAt: parseDate(json['assigned_at']),
      pickedUpAt: parseDate(json['picked_up_at']),
      chargedAt: parseDate(json['charged_at']),
      returnedAt: parseDate(json['returned_at']),
      payAmount: toInt(json['pay_amount'] ?? 5000),
      paid: json['paid'] == true,
      createdAt: parseDate(json['created_at']),
    );
  }

  /// `true` when the task is in a terminal state (returned or cancelled).
  bool get isTerminal =>
      status == JuicerTaskStatus.returned ||
      status == JuicerTaskStatus.cancelled;

  /// Total time the scooter spent in the juicer's custody, in minutes.
  /// `null` until the task is returned.
  int? get custodyMinutes => returnedAt == null || assignedAt == null
      ? null
      : returnedAt!.difference(assignedAt!).inMinutes;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'juicer_id': juicerId,
        'scooter_id': scooterId,
        'status': status.wire,
        if (pickupCoordinates != null)
          'pickup_coordinates': pickupCoordinates!.toJson(),
        if (returnCoordinates != null)
          'return_coordinates': returnCoordinates!.toJson(),
        if (assignedAt != null) 'assigned_at': assignedAt!.toIso8601String(),
        if (pickedUpAt != null) 'picked_up_at': pickedUpAt!.toIso8601String(),
        if (chargedAt != null) 'charged_at': chargedAt!.toIso8601String(),
        if (returnedAt != null) 'returned_at': returnedAt!.toIso8601String(),
        'pay_amount': payAmount,
        'paid': paid,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  @override
  String toString() =>
      'JuicerTask($status, scooter: $scooterId, pay: $payAmount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JuicerTask && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Latitude/longitude pair attached to a juicer task (pickup or return).
class TaskCoordinates {
  final double latitude;
  final double longitude;

  const TaskCoordinates({required this.latitude, required this.longitude});

  factory TaskCoordinates.fromJson(Map<String, dynamic> json) =>
      TaskCoordinates(
        latitude: toDouble(
            json['latitude'] ?? json['lat']),
        longitude: toDouble(
            json['longitude'] ?? json['lng'] ?? json['lon']),
      );

  Map<String, dynamic> toJson() =>
      {'latitude': latitude, 'longitude': longitude};

  @override
  String toString() => 'TaskCoordinates($latitude, $longitude)';
}

/// Earnings summary returned by `GET /juicers/me/earnings`.
class JuicerEarnings {
  final int totalScootersCharged;
  final int totalEarned;
  final int chargedToday;
  final int payRate;

  const JuicerEarnings({
    this.totalScootersCharged = 0,
    this.totalEarned = 0,
    this.chargedToday = 0,
    this.payRate = 5000,
  });

  factory JuicerEarnings.fromJson(Map<String, dynamic> json) =>
      JuicerEarnings(
        totalScootersCharged:
            toInt(json['total_scooters_charged'] ?? json['totalScootersCharged']),
        totalEarned: toInt(json['total_earned'] ?? json['totalEarned']),
        chargedToday: toInt(json['charged_today'] ?? json['chargedToday']),
        payRate: toInt(json['pay_rate'] ?? json['payRate'] ?? 5000),
      );

  /// Projected monthly earnings at the current daily rate.
  int get projectedMonthly => chargedToday * 30 * payRate;

  Map<String, dynamic> toJson() => {
        'total_scooters_charged': totalScootersCharged,
        'total_earned': totalEarned,
        'charged_today': chargedToday,
        'pay_rate': payRate,
      };

  @override
  String toString() =>
      'JuicerEarnings(earned: $totalEarned, today: $chargedToday)';
}

// --- internal helpers ----------------------------------------------------


double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

