/// Mechanic profile plus maintenance-request and inventory models.
///
/// Ported from `backend/v1/models/mechanics.js`. Mechanics repair
/// scooters that have been flagged for maintenance (via a breakdown
/// ticket or auto-flag). The lifecycle is:
///
///   1. Admin (or `support.js`) creates a [MaintenanceRequest]
///      (status `open`).
///   2. Admin assigns a mechanic (status `assigned`, scooter →
///      `maintenance`).
///   3. Mechanic starts work (status `in_progress`).
///   4. Mechanic either completes (with parts used) or escalates.
///   5. On completion, parts are decremented from [PartsInventory]
///      and the scooter returns to `available` (or `retired`).
///
/// This file ports the four document shapes that the mobile admin UI
/// needs to render: [MechanicModel], [MaintenanceRequest],
/// [PartsInventory], [PartUsed].
library;


import 'json_helpers.dart';
/// Mechanic account status.
enum MechanicStatus {
  active,
  suspended,
  unknown;

  static MechanicStatus fromString(String? raw) {
    switch (raw) {
      case 'active':
        return MechanicStatus.active;
      case 'suspended':
      case 'paused':
        return MechanicStatus.suspended;
      default:
        return MechanicStatus.unknown;
    }
  }

  String get wire => switch (this) {
        MechanicStatus.active => 'active',
        MechanicStatus.suspended => 'suspended',
        MechanicStatus.unknown => 'unknown',
      };
}

/// Lifecycle of a maintenance request.
enum MaintenanceStatus {
  open,
  assigned,
  inProgress,
  completed,
  escalated,
  cancelled;

  static MaintenanceStatus fromString(String? raw) {
    switch (raw) {
      case 'open':
        return MaintenanceStatus.open;
      case 'assigned':
        return MaintenanceStatus.assigned;
      case 'in_progress':
        return MaintenanceStatus.inProgress;
      case 'completed':
        return MaintenanceStatus.completed;
      case 'escalated':
        return MaintenanceStatus.escalated;
      case 'cancelled':
        return MaintenanceStatus.cancelled;
      default:
        return MaintenanceStatus.open;
    }
  }

  String get wire => switch (this) {
        MaintenanceStatus.open => 'open',
        MaintenanceStatus.assigned => 'assigned',
        MaintenanceStatus.inProgress => 'in_progress',
        MaintenanceStatus.completed => 'completed',
        MaintenanceStatus.escalated => 'escalated',
        MaintenanceStatus.cancelled => 'cancelled',
      };

  bool get isOpen =>
      this == MaintenanceStatus.open ||
      this == MaintenanceStatus.assigned ||
      this == MaintenanceStatus.inProgress;

  bool get isTerminal =>
      this == MaintenanceStatus.completed ||
      this == MaintenanceStatus.cancelled;
}

/// Maintenance request priority bucket.
enum MaintenancePriority {
  low,
  normal,
  high,
  critical;

  static MaintenancePriority fromString(String? raw) {
    switch (raw) {
      case 'low':
        return MaintenancePriority.low;
      case 'high':
        return MaintenancePriority.high;
      case 'critical':
      case 'urgent':
        return MaintenancePriority.critical;
      default:
        return MaintenancePriority.normal;
    }
  }

  String get wire => switch (this) {
        MaintenancePriority.low => 'low',
        MaintenancePriority.normal => 'normal',
        MaintenancePriority.high => 'high',
        MaintenancePriority.critical => 'critical',
      };
}

/// Whitelisted spare-parts catalog. Mirrors the `PARTS_CATALOG` array
/// in `mechanics.js`.
enum SparePart {
  frontWheel,
  rearWheel,
  brakePad,
  brakeCable,
  batteryPack,
  displayUnit,
  throttle,
  controller,
  framePart,
  headlight,
  taillight,
  lockMechanism,
  tire,
  innerTube,
  screwSet,
  other;

  static SparePart? fromString(String? raw) {
    switch (raw) {
      case 'front_wheel':
        return SparePart.frontWheel;
      case 'rear_wheel':
        return SparePart.rearWheel;
      case 'brake_pad':
        return SparePart.brakePad;
      case 'brake_cable':
        return SparePart.brakeCable;
      case 'battery_pack':
        return SparePart.batteryPack;
      case 'display_unit':
        return SparePart.displayUnit;
      case 'throttle':
        return SparePart.throttle;
      case 'controller':
        return SparePart.controller;
      case 'frame_part':
        return SparePart.framePart;
      case 'headlight':
        return SparePart.headlight;
      case 'taillight':
        return SparePart.taillight;
      case 'lock_mechanism':
        return SparePart.lockMechanism;
      case 'tire':
        return SparePart.tire;
      case 'inner_tube':
        return SparePart.innerTube;
      case 'screw_set':
        return SparePart.screwSet;
      case 'other':
        return SparePart.other;
      default:
        return null;
    }
  }

  String get wire => switch (this) {
        SparePart.frontWheel => 'front_wheel',
        SparePart.rearWheel => 'rear_wheel',
        SparePart.brakePad => 'brake_pad',
        SparePart.brakeCable => 'brake_cable',
        SparePart.batteryPack => 'battery_pack',
        SparePart.displayUnit => 'display_unit',
        SparePart.throttle => 'throttle',
        SparePart.controller => 'controller',
        SparePart.framePart => 'frame_part',
        SparePart.headlight => 'headlight',
        SparePart.taillight => 'taillight',
        SparePart.lockMechanism => 'lock_mechanism',
        SparePart.tire => 'tire',
        SparePart.innerTube => 'inner_tube',
        SparePart.screwSet => 'screw_set',
        SparePart.other => 'other',
      };
}

/// Mechanic profile document.
class MechanicModel {
  /// MongoDB `_id` of the mechanic.
  final String id;

  /// Phone in `+998XXXXXXXXX` format.
  final String phone;

  /// Given name.
  final String firstName;

  /// Family name.
  final String lastName;

  /// Specialization bucket (e.g. `general`, `battery`, `electrical`,
  /// `frame`). Free-form string.
  final String specialization;

  /// Whitelisted repair categories this mechanic is certified for.
  /// When the backend doesn't populate this, defaults to a single
  /// entry matching [specialization].
  final List<String> specialties;

  /// Account status.
  final MechanicStatus status;

  /// Lifetime completed repairs.
  final int totalRepairs;

  /// Currently assigned open requests.
  final int currentAssignments;

  /// Total parts consumed across all repairs.
  final int partsUsedTotal;

  /// Average admin-assigned rating (0–5). `null` until first review.
  final double? rating;

  /// Account creation timestamp.
  final DateTime? createdAt;

  /// Last profile mutation timestamp.
  final DateTime? updatedAt;

  /// All maintenance requests assigned to this mechanic.
  /// Populated only when the API returns the embedded list; otherwise
  /// `const []`.
  final List<MaintenanceRequest> maintenanceRequests;

  /// Parts inventory snapshot for this mechanic's warehouse, when
  /// scoped via `GET /mechanics/inventory?warehouse_id=...`.
  final List<PartsInventory> inventory;

  /// Creates a [MechanicModel].
  const MechanicModel({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.specialization = 'general',
    this.specialties = const [],
    this.status = MechanicStatus.active,
    this.totalRepairs = 0,
    this.currentAssignments = 0,
    this.partsUsedTotal = 0,
    this.rating,
    this.createdAt,
    this.updatedAt,
    this.maintenanceRequests = const [],
    this.inventory = const [],
  });

  /// Parses a JSON object (MongoDB document) into a [MechanicModel].
  factory MechanicModel.fromJson(Map<String, dynamic> json) {
    final rawSpecs = json['specialties'] ??
        (json['specialization'] != null ? [json['specialization']] : null);
    final rawReqs = json['maintenance_requests'] ?? json['requests'];
    final rawInv = json['inventory'];
    return MechanicModel(
      id: stringifyId(json['_id'] ?? json['id']),
      phone: (json['phone'] ?? '').toString(),
      firstName: (json['firstName'] ?? json['first_name'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['last_name'] ?? '').toString(),
      specialization: (json['specialization'] ?? 'general').toString(),
      specialties: rawSpecs is List
          ? rawSpecs.map((s) => s.toString()).toList(growable: false)
          : const ['general'],
      status: MechanicStatus.fromString(json['status']?.toString()),
      totalRepairs: toInt(json['total_repairs'] ?? json['totalRepairs']),
      currentAssignments:
          toInt(json['current_assignments'] ?? json['currentAssignments']),
      partsUsedTotal:
          toInt(json['parts_used_total'] ?? json['partsUsedTotal']),
      rating: _toDoubleOrNull(json['rating']),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
      maintenanceRequests: rawReqs is List
          ? rawReqs
              .whereType<Map>()
              .map((r) => MaintenanceRequest.fromJson(r as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      inventory: rawInv is List
          ? rawInv
              .whereType<Map>()
              .map((i) => PartsInventory.fromJson(i as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
    );
  }

  /// Display name helper.
  String get fullName => '$firstName $lastName'.trim();

  /// `true` when the mechanic can accept new assignments.
  bool get canAccept =>
      status == MechanicStatus.active && currentAssignments < 5;

  /// Throughput rate: repairs per day, computed against account age.
  /// Returns `0` when the account is less than a day old.
  double get repairsPerDay {
    final age = createdAt == null
        ? null
        : DateTime.now().toUtc().difference(createdAt!);
    if (age == null || age.inDays < 1) return 0;
    return totalRepairs / age.inDays;
  }

  /// Serialises the model back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'specialization': specialization,
        'specialties': specialties,
        'status': status.wire,
        'total_repairs': totalRepairs,
        'current_assignments': currentAssignments,
        'parts_used_total': partsUsedTotal,
        if (rating != null) 'rating': rating,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (maintenanceRequests.isNotEmpty)
          'maintenance_requests':
              maintenanceRequests.map((r) => r.toJson()).toList(),
        if (inventory.isNotEmpty)
          'inventory': inventory.map((i) => i.toJson()).toList(),
      };

  /// Returns a copy of this model with the given fields replaced.
  MechanicModel copyWith({
    String? id,
    String? phone,
    String? firstName,
    String? lastName,
    String? specialization,
    List<String>? specialties,
    MechanicStatus? status,
    int? totalRepairs,
    int? currentAssignments,
    int? partsUsedTotal,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MaintenanceRequest>? maintenanceRequests,
    List<PartsInventory>? inventory,
  }) {
    return MechanicModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      specialization: specialization ?? this.specialization,
      specialties: specialties ?? this.specialties,
      status: status ?? this.status,
      totalRepairs: totalRepairs ?? this.totalRepairs,
      currentAssignments: currentAssignments ?? this.currentAssignments,
      partsUsedTotal: partsUsedTotal ?? this.partsUsedTotal,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      maintenanceRequests: maintenanceRequests ?? this.maintenanceRequests,
      inventory: inventory ?? this.inventory,
    );
  }

  @override
  String toString() =>
      'MechanicModel($fullName, spec: $specialization, repairs: $totalRepairs)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MechanicModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Single maintenance request.
class MaintenanceRequest {
  /// MongoDB `_id` of the request.
  final String id;

  /// `_id` of the scooter being repaired.
  final String scooterId;

  /// `_id` of the assigned mechanic, `null` while unassigned.
  final String? mechanicId;

  /// Human-readable reason for the request (e.g. "Front wheel wobbles").
  final String reason;

  /// Priority bucket.
  final MaintenancePriority priority;

  /// Lifecycle status.
  final MaintenanceStatus status;

  /// `true` when the request was created manually by an admin rather
  /// than auto-flagged by the system.
  final bool createdByAdmin;

  /// Free-form escalation reason, populated when [status] is
  /// [MaintenanceStatus.escalated].
  final String? escalateReason;

  /// Resolution note written by the mechanic on completion.
  final String? resolutionNote;

  /// URL of the completion photo uploaded by the mechanic.
  final String? completionPhotoUrl;

  /// Parts consumed during the repair.
  final List<PartUsed> partsUsed;

  /// Parts the mechanic requested for escalation (not yet available).
  final List<PartUsed> neededParts;

  /// When the request was created.
  final DateTime? createdAt;

  /// When the mechanic was assigned.
  final DateTime? assignedAt;

  /// When the mechanic started work.
  final DateTime? workStartedAt;

  /// When the request was escalated.
  final DateTime? escalatedAt;

  /// When the request was completed.
  final DateTime? completedAt;

  /// When the request was last updated.
  final DateTime? updatedAt;

  /// Creates a [MaintenanceRequest].
  const MaintenanceRequest({
    required this.id,
    required this.scooterId,
    required this.reason,
    this.mechanicId,
    this.priority = MaintenancePriority.normal,
    this.status = MaintenanceStatus.open,
    this.createdByAdmin = false,
    this.escalateReason,
    this.resolutionNote,
    this.completionPhotoUrl,
    this.partsUsed = const [],
    this.neededParts = const [],
    this.createdAt,
    this.assignedAt,
    this.workStartedAt,
    this.escalatedAt,
    this.completedAt,
    this.updatedAt,
  });

  /// Parses a JSON object into a [MaintenanceRequest].
  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    final rawParts = json['parts_used'];
    final rawNeeded = json['needed_parts'];
    return MaintenanceRequest(
      id: stringifyId(json['_id'] ?? json['id']),
      scooterId: stringifyId(json['scooter_id'] ?? json['scooterId']),
      mechanicId: stringifyIdNullable(json['mechanic_id'] ?? json['mechanicId']),
      reason: (json['reason'] ?? '').toString(),
      priority: MaintenancePriority.fromString(json['priority']?.toString()),
      status: MaintenanceStatus.fromString(json['status']?.toString()),
      createdByAdmin: json['created_by_admin'] == true,
      escalateReason: asString(json['escalate_reason']),
      resolutionNote: asString(json['resolution_note']),
      completionPhotoUrl: asString(json['completion_photo_url']),
      partsUsed: rawParts is List
          ? rawParts
              .whereType<Map>()
              .map((p) => PartUsed.fromJson(p as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      neededParts: rawNeeded is List
          ? rawNeeded
              .whereType<Map>()
              .map((p) => PartUsed.fromJson(p as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      createdAt: parseDate(json['created_at']),
      assignedAt: parseDate(json['assigned_at']),
      workStartedAt: parseDate(json['work_started_at']),
      escalatedAt: parseDate(json['escalated_at']),
      completedAt: parseDate(json['completed_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  /// `true` when the request is awaiting assignment.
  bool get isUnassigned =>
      status == MaintenanceStatus.open && mechanicId == null;

  /// Total quantity of parts consumed.
  int get totalPartsQuantity =>
      partsUsed.fold(0, (sum, p) => sum + p.quantity);

  /// Wall-clock duration from work-start to completion, in minutes.
  /// `null` when work hasn't completed.
  int? get workDurationMinutes =>
      completedAt == null || workStartedAt == null
          ? null
          : completedAt!.difference(workStartedAt!).inMinutes;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'scooter_id': scooterId,
        if (mechanicId != null) 'mechanic_id': mechanicId,
        'reason': reason,
        'priority': priority.wire,
        'status': status.wire,
        'created_by_admin': createdByAdmin,
        if (escalateReason != null) 'escalate_reason': escalateReason,
        if (resolutionNote != null) 'resolution_note': resolutionNote,
        if (completionPhotoUrl != null)
          'completion_photo_url': completionPhotoUrl,
        'parts_used': partsUsed.map((p) => p.toJson()).toList(),
        'needed_parts': neededParts.map((p) => p.toJson()).toList(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (assignedAt != null) 'assigned_at': assignedAt!.toIso8601String(),
        if (workStartedAt != null)
          'work_started_at': workStartedAt!.toIso8601String(),
        if (escalatedAt != null) 'escalated_at': escalatedAt!.toIso8601String(),
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  MaintenanceRequest copyWith({
    String? id,
    String? scooterId,
    String? mechanicId,
    String? reason,
    MaintenancePriority? priority,
    MaintenanceStatus? status,
    bool? createdByAdmin,
    String? escalateReason,
    String? resolutionNote,
    String? completionPhotoUrl,
    List<PartUsed>? partsUsed,
    List<PartUsed>? neededParts,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? workStartedAt,
    DateTime? escalatedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceRequest(
      id: id ?? this.id,
      scooterId: scooterId ?? this.scooterId,
      mechanicId: mechanicId ?? this.mechanicId,
      reason: reason ?? this.reason,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      escalateReason: escalateReason ?? this.escalateReason,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      completionPhotoUrl: completionPhotoUrl ?? this.completionPhotoUrl,
      partsUsed: partsUsed ?? this.partsUsed,
      neededParts: neededParts ?? this.neededParts,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      workStartedAt: workStartedAt ?? this.workStartedAt,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'MaintenanceRequest($status, scooter: $scooterId, priority: $priority)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceRequest && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Quantity of a single spare part consumed in a repair.
class PartUsed {
  /// Part catalog entry.
  final SparePart part;

  /// Quantity consumed (must be >= 1).
  final int quantity;

  /// Optional unit cost in UZS tiyin, used for cost-of-repair accounting.
  final int? unitCost;

  const PartUsed({
    required this.part,
    required this.quantity,
    this.unitCost,
  });

  factory PartUsed.fromJson(Map<String, dynamic> json) => PartUsed(
        part: SparePart.fromString(json['part']?.toString()) ??
            SparePart.other,
        quantity: toInt(json['quantity']),
        unitCost: json['unit_cost'] == null
            ? null
            : toInt(json['unit_cost']),
      );

  /// Total cost of this line item, in UZS tiyin.
  int get totalCost => unitCost == null ? 0 : unitCost! * quantity;

  Map<String, dynamic> toJson() => {
        'part': part.wire,
        'quantity': quantity,
        if (unitCost != null) 'unit_cost': unitCost,
      };

  @override
  String toString() => 'PartUsed(${part.wire} x$quantity)';
}

/// Parts-inventory document.
class PartsInventory {
  /// Part catalog entry.
  final SparePart part;

  /// Current on-hand quantity.
  final int quantity;

  /// Optional minimum threshold below which a restock alert fires.
  final int minThreshold;

  /// Optional per-unit cost in UZS tiyin.
  final int? unitCost;

  /// Inventory change history (newest last).
  final List<InventoryHistoryEntry> history;

  /// Last update timestamp.
  final DateTime? updatedAt;

  const PartsInventory({
    required this.part,
    required this.quantity,
    this.minThreshold = 0,
    this.unitCost,
    this.history = const [],
    this.updatedAt,
  });

  factory PartsInventory.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'];
    return PartsInventory(
      part: SparePart.fromString(json['part']?.toString()) ?? SparePart.other,
      quantity: toInt(json['quantity']),
      minThreshold: toInt(json['min_threshold'] ?? json['minThreshold']),
      unitCost:
          json['unit_cost'] == null ? null : toInt(json['unit_cost']),
      history: rawHistory is List
          ? rawHistory
              .whereType<Map>()
              .map((h) =>
                  InventoryHistoryEntry.fromJson(h as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      updatedAt: parseDate(json['updated_at']),
    );
  }

  /// `true` when the on-hand quantity is below the reorder threshold.
  bool get needsRestock => quantity <= minThreshold;

  /// Total inventory value, in UZS tiyin.
  int get totalValue => unitCost == null ? 0 : unitCost! * quantity;

  Map<String, dynamic> toJson() => {
        'part': part.wire,
        'quantity': quantity,
        'min_threshold': minThreshold,
        if (unitCost != null) 'unit_cost': unitCost,
        if (history.isNotEmpty)
          'history': history.map((h) => h.toJson()).toList(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  @override
  String toString() =>
      'PartsInventory(${part.wire}: $quantity, threshold: $minThreshold)';
}

/// Single inventory history entry (restock or consumption).
class InventoryHistoryEntry {
  /// Signed delta (positive for restock, negative for consumption).
  final int delta;

  /// Optional note (e.g. "restock from supplier", or `_id` of the
  /// maintenance request that consumed the part).
  final String? note;

  /// `_id` of the maintenance request that consumed parts, when
  /// applicable (delta < 0).
  final String? requestId;

  /// `_id` of the mechanic who consumed the parts, when applicable.
  final String? mechanicId;

  /// Timestamp of the change.
  final DateTime? timestamp;

  const InventoryHistoryEntry({
    required this.delta,
    this.note,
    this.requestId,
    this.mechanicId,
    this.timestamp,
  });

  factory InventoryHistoryEntry.fromJson(Map<String, dynamic> json) =>
      InventoryHistoryEntry(
        delta: toInt(json['delta']),
        note: asString(json['note']),
        requestId: stringifyIdNullable(
            json['request_id'] ?? json['requestId']),
        mechanicId: stringifyIdNullable(
            json['mechanic_id'] ?? json['mechanicId']),
        timestamp: parseDate(json['timestamp']),
      );

  /// `true` when this entry represents a consumption (negative delta).
  bool get isConsumption => delta < 0;

  /// `true` when this entry represents a restock (positive delta).
  bool get isRestock => delta > 0;

  Map<String, dynamic> toJson() => {
        'delta': delta,
        if (note != null) 'note': note,
        if (requestId != null) 'request_id': requestId,
        if (mechanicId != null) 'mechanic_id': mechanicId,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };

  @override
  String toString() => 'InventoryHistoryEntry(delta: $delta)';
}

// --- internal helpers ----------------------------------------------------


double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}


