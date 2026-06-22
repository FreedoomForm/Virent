/// Trip lifecycle model.
///
/// Ported from `backend/v1/models/trips.js`. A trip moves through the
/// following lifecycle:
///
///   reserved → active → ended → (optional: refunded)
///                  ↘ cancelled
///                       ↘ expired (reservation TTL elapsed)
///
/// Cost calculation (mirrors `trips.js::endTrip`):
///   * `base`     = city.fixedRate
///   * `time`     = durationMin * city.timeRate
///   * `discount` = parkingZoneRate (parking) or bonusParkingZoneRate (bonus)
///   * `fee`      = noParkingZoneRate (no-parking)
///   * `total`    = max(0, base + time - discount + fee)
///
/// Battery drain approximation: 0.5% per minute (configurable per
/// scooter model later).
library;


import 'json_helpers.dart';
/// Lifecycle status of a trip.
enum TripStatus {
  /// User has reserved a scooter; reservation expires in 10 min.
  reserved,

  /// Trip is in progress — scooter unlocked.
  active,

  /// Trip completed normally — end-of-ride cost deducted.
  ended,

  /// User cancelled the reservation or active trip.
  cancelled,

  /// Reservation TTL elapsed without the user starting the ride.
  expired;

  static TripStatus fromString(String? raw) {
    switch (raw) {
      case 'reserved':
        return TripStatus.reserved;
      case 'active':
      case 'in_use':
        return TripStatus.active;
      case 'ended':
      case 'completed':
        return TripStatus.ended;
      case 'cancelled':
      case 'canceled':
        return TripStatus.cancelled;
      case 'expired':
        return TripStatus.expired;
      default:
        return TripStatus.ended;
    }
  }

  String get wire => switch (this) {
        TripStatus.reserved => 'reserved',
        TripStatus.active => 'active',
        TripStatus.ended => 'ended',
        TripStatus.cancelled => 'cancelled',
        TripStatus.expired => 'expired',
      };

  /// `true` when the trip is currently occupying a scooter.
  bool get isActive =>
      this == TripStatus.reserved || this == TripStatus.active;

  /// `true` when the trip reached a terminal state.
  bool get isTerminal =>
      this == TripStatus.ended ||
      this == TripStatus.cancelled ||
      this == TripStatus.expired;
}

/// End-of-ride zone classification.
enum TripEndZone {
  street,
  parking,
  bonusParking,
  noParking,
  outsideCity;

  static TripEndZone fromString(String? raw) {
    switch (raw) {
      case 'parking':
      case 'parkingZone':
        return TripEndZone.parking;
      case 'bonus_parking':
      case 'bonusParkingZone':
        return TripEndZone.bonusParking;
      case 'no_parking':
      case 'noParkingZone':
        return TripEndZone.noParking;
      case 'outside_city':
        return TripEndZone.outsideCity;
      default:
        return TripEndZone.street;
    }
  }

  String get wire => switch (this) {
        TripEndZone.street => 'street',
        TripEndZone.parking => 'parking',
        TripEndZone.bonusParking => 'bonus_parking',
        TripEndZone.noParking => 'no_parking',
        TripEndZone.outsideCity => 'outside_city',
      };

  /// `true` when ending here yields a discount.
  bool get isDiscountZone =>
      this == TripEndZone.parking || this == TripEndZone.bonusParking;

  /// `true` when ending here incurs a penalty fee.
  bool get isPenaltyZone => this == TripEndZone.noParking;
}

/// Cost-breakdown block embedded in an ended trip.
class TripCostBreakdown {
  /// Flat start fee (city `fixedRate`).
  final int base;

  /// Per-minute time charge (`durationMin * city.timeRate`).
  final int time;

  /// Parking discount applied (negative for deduction).
  final int discount;

  /// No-parking penalty fee applied.
  final int fee;

  /// City rate card snapshot used to compute the cost. Useful for
  /// audit / dispute resolution.
  final CityRateSnapshot? cityRates;

  const TripCostBreakdown({
    required this.base,
    required this.time,
    required this.discount,
    required this.fee,
    this.cityRates,
  });

  factory TripCostBreakdown.fromJson(Map<String, dynamic> json) =>
      TripCostBreakdown(
        base: toInt(json['base']),
        time: toInt(json['time']),
        discount: toInt(json['discount']),
        fee: toInt(json['fee']),
        cityRates: json['city_rates'] is Map<String, dynamic>
            ? CityRateSnapshot.fromJson(
                json['city_rates'] as Map<String, dynamic>)
            : null,
      );

  /// Total cost = base + time - discount + fee.
  int get total {
    final t = base + time - discount + fee;
    return t < 0 ? 0 : t;
  }

  Map<String, dynamic> toJson() => {
        'base': base,
        'time': time,
        'discount': discount,
        'fee': fee,
        if (cityRates != null) 'city_rates': cityRates!.toJson(),
      };

  @override
  String toString() =>
      'TripCostBreakdown(base: $base, time: $time, discount: $discount, fee: $fee, total: $total)';
}

/// Snapshot of the city rate card at the time a trip ended.
class CityRateSnapshot {
  final int fixedRate;
  final int timeRate;
  final int parkingZoneRate;
  final int bonusParkingZoneRate;
  final int noParkingZoneRate;

  const CityRateSnapshot({
    required this.fixedRate,
    required this.timeRate,
    required this.parkingZoneRate,
    required this.bonusParkingZoneRate,
    required this.noParkingZoneRate,
  });

  factory CityRateSnapshot.fromJson(Map<String, dynamic> json) =>
      CityRateSnapshot(
        fixedRate: toInt(json['fixedRate']),
        timeRate: toInt(json['timeRate']),
        parkingZoneRate: toInt(json['parkingZoneRate']),
        bonusParkingZoneRate: toInt(json['bonusParkingZoneRate']),
        noParkingZoneRate: toInt(json['noParkingZoneRate']),
      );

  Map<String, dynamic> toJson() => {
        'fixedRate': fixedRate,
        'timeRate': timeRate,
        'parkingZoneRate': parkingZoneRate,
        'bonusParkingZoneRate': bonusParkingZoneRate,
        'noParkingZoneRate': noParkingZoneRate,
      };
}

/// Latitude/longitude pair used for trip start/end coordinates.
class TripCoordinates {
  final double latitude;
  final double longitude;

  const TripCoordinates({required this.latitude, required this.longitude});

  factory TripCoordinates.fromJson(Map<String, dynamic> json) =>
      TripCoordinates(
        latitude: toDouble(json['latitude'] ?? json['lat']),
        longitude: toDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
      );

  Map<String, dynamic> toJson() =>
      {'latitude': latitude, 'longitude': longitude};

  @override
  String toString() => 'TripCoordinates($latitude, $longitude)';
}

/// Trip document.
class TripModel {
  /// MongoDB `_id` of the trip.
  final String id;

  /// `_id` of the user who owns the trip.
  final String userId;

  /// `_id` of the scooter used for the trip.
  final String scooterId;

  /// Lifecycle status.
  final TripStatus status;

  /// When the trip was created (reservation time).
  final DateTime? startTime;

  /// When the trip ended (status → `ended`).
  final DateTime? endTime;

  /// When the reservation expires (10 minutes after [startTime]).
  final DateTime? reservationExpires;

  /// Coordinates at trip start.
  final TripCoordinates? startCoordinates;

  /// Coordinates at trip end.
  final TripCoordinates? endCoordinates;

  /// Battery percentage at trip start (snapshot of scooter.battery).
  final int? startBattery;

  /// Battery percentage at trip end.
  final int? endBattery;

  /// End-of-ride zone classification.
  final TripEndZone endZone;

  /// Raw end-zone string (preserved for forward compatibility).
  final String? endZoneType;

  /// Trip duration in minutes. `null` while the trip is active.
  final int? durationMin;

  /// Distance travelled, in kilometres. The backend computes this from
  /// the GPS track (TODO in `trips.js`); `0` until implemented.
  final double distanceKm;

  /// Total trip cost, in UZS tiyin. `null` until the trip ends.
  final int? cost;

  /// Detailed cost breakdown, when [status] is [TripStatus.ended].
  final TripCostBreakdown? costBreakdown;

  /// URL of the end-of-ride parking proof photo, when uploaded.
  final String? photoUrl;

  /// `true` when the trip has been refunded (full or partial).
  final bool refunded;

  /// Refund amount, in UZS tiyin. `0` when not refunded.
  final int refundAmount;

  /// Refund reason (e.g. `admin_refund`, `auto_no_parking_double_charge`).
  final String? refundReason;

  /// Cancellation reason, when [status] is [TripStatus.cancelled].
  final String? cancelledReason;

  /// When the trip was cancelled.
  final DateTime? cancelledAt;

  /// Whether the user has been warned for leaving the service area.
  final bool outsideCityWarned;

  /// Whether the user has been warned for entering a no-parking zone.
  final bool noParkingWarned;

  /// `true` when the trip has been flagged for auto-end (active > 8h).
  final bool autoEndFlagged;

  /// When the trip document was last updated.
  final DateTime? updatedAt;

  /// When the trip was created.
  final DateTime? createdAt;

  /// Battery drain per minute, in percentage points. Defaults to 0.5
  /// (mirrors `BATTERY_DRAIN_PER_MIN` in `trips.js`).
  static const double batteryDrainPerMin = 0.5;

  /// Reservation TTL in minutes. Mirrors `RESERVATION_TTL_MIN = 10`.
  static const int reservationTtlMin = 10;

  /// Maximum trip duration in hours before auto-end flag. Mirrors
  /// `MAX_TRIP_HOURS = 8`.
  static const int maxTripHours = 8;

  /// Creates a [TripModel].
  const TripModel({
    required this.id,
    required this.userId,
    required this.scooterId,
    required this.status,
    this.startTime,
    this.endTime,
    this.reservationExpires,
    this.startCoordinates,
    this.endCoordinates,
    this.startBattery,
    this.endBattery,
    this.endZone = TripEndZone.street,
    this.endZoneType,
    this.durationMin,
    this.distanceKm = 0,
    this.cost,
    this.costBreakdown,
    this.photoUrl,
    this.refunded = false,
    this.refundAmount = 0,
    this.refundReason,
    this.cancelledReason,
    this.cancelledAt,
    this.outsideCityWarned = false,
    this.noParkingWarned = false,
    this.autoEndFlagged = false,
    this.updatedAt,
    this.createdAt,
  });

  /// Parses a JSON object (MongoDB document) into a [TripModel].
  factory TripModel.fromJson(Map<String, dynamic> json) {
    final rawStart = json['start_coordinates'];
    final rawEnd = json['end_coordinates'];
    final rawEndZone = json['end_zone_type'] ?? json['end_zone'];
    final rawBreakdown = json['cost_breakdown'];
    final rawCost = json['cost'];
    return TripModel(
      id: stringifyId(json['_id'] ?? json['id']),
      userId: stringifyId(json['user_id'] ?? json['userId']),
      scooterId: stringifyId(json['scooter_id'] ?? json['scooterId']),
      status: TripStatus.fromString(json['status']?.toString()),
      startTime: parseDate(json['start_time'] ?? json['startTime']),
      endTime: parseDate(json['end_time'] ?? json['endTime']),
      reservationExpires:
          parseDate(json['reservation_expires'] ?? json['reservationExpires']),
      startCoordinates: rawStart is Map<String, dynamic>
          ? TripCoordinates.fromJson(rawStart)
          : null,
      endCoordinates: rawEnd is Map<String, dynamic>
          ? TripCoordinates.fromJson(rawEnd)
          : null,
      startBattery: json['start_battery'] == null
          ? null
          : toInt(json['start_battery']),
      endBattery: json['end_battery'] == null
          ? null
          : toInt(json['end_battery']),
      endZone: TripEndZone.fromString(rawEndZone?.toString()),
      endZoneType: asString(rawEndZone),
      durationMin: json['duration_min'] == null
          ? null
          : toInt(json['duration_min']),
      distanceKm: toDouble(json['distance_km'] ?? json['distanceKm']),
      cost: rawCost == null ? null : toInt(rawCost),
      costBreakdown: rawBreakdown is Map<String, dynamic>
          ? TripCostBreakdown.fromJson(rawBreakdown)
          : null,
      photoUrl: asString(json['photo_url'] ?? json['photoUrl']),
      refunded: json['refunded'] == true ||
          (json['refund_amount'] != null && toInt(json['refund_amount']) > 0),
      refundAmount: toInt(json['refund_amount'] ?? json['refundAmount']),
      refundReason: asString(json['refund_reason'] ?? json['refundReason']),
      cancelledReason:
          asString(json['cancelled_reason'] ?? json['cancelledReason']),
      cancelledAt: parseDate(json['cancelled_at']),
      outsideCityWarned: json['outside_city_warned'] == true,
      noParkingWarned: json['no_parking_warned'] == true,
      autoEndFlagged: json['auto_end_flagged'] == true,
      updatedAt: parseDate(json['updated_at']),
      createdAt: parseDate(json['created_at']),
    );
  }

  /// `true` when the trip is currently occupying a scooter.
  bool get isActive => status.isActive;

  /// `true` when the trip ended normally (cost was charged).
  bool get isEnded => status == TripStatus.ended;

  /// Net cost after refund, in UZS tiyin. `0` when not yet ended.
  int get netCost {
    if (cost == null) return 0;
    final net = cost! - refundAmount;
    return net < 0 ? 0 : net;
  }

  /// Estimated battery drain for a trip of [durationMin] minutes.
  static double estimatedBatteryDrain(int minutes) =>
      minutes * batteryDrainPerMin;

  /// `true` when the reservation has expired but the trip is still in
  /// `reserved` status (i.e. the cron hasn't yet flipped it to `expired`).
  bool get isReservationStale {
    if (status != TripStatus.reserved || reservationExpires == null) {
      return false;
    }
    return DateTime.now().toUtc().isAfter(reservationExpires!);
  }

  /// `true` when the trip has been running long enough to trigger
  /// auto-end (>= [maxTripHours] hours).
  bool get shouldAutoEnd {
    if (status != TripStatus.active || startTime == null) return false;
    final elapsed = DateTime.now().toUtc().difference(startTime!);
    return elapsed.inHours >= maxTripHours;
  }

  /// Serialises the trip back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        'user_id': userId,
        'scooter_id': scooterId,
        'status': status.wire,
        if (startTime != null) 'start_time': startTime!.toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toIso8601String(),
        if (reservationExpires != null)
          'reservation_expires': reservationExpires!.toIso8601String(),
        if (startCoordinates != null)
          'start_coordinates': startCoordinates!.toJson(),
        if (endCoordinates != null)
          'end_coordinates': endCoordinates!.toJson(),
        if (startBattery != null) 'start_battery': startBattery,
        if (endBattery != null) 'end_battery': endBattery,
        if (endZoneType != null) 'end_zone_type': endZoneType,
        if (durationMin != null) 'duration_min': durationMin,
        'distance_km': distanceKm,
        if (cost != null) 'cost': cost,
        if (costBreakdown != null) 'cost_breakdown': costBreakdown!.toJson(),
        if (photoUrl != null) 'photo_url': photoUrl,
        'refunded': refunded,
        if (refundAmount > 0) 'refund_amount': refundAmount,
        if (refundReason != null) 'refund_reason': refundReason,
        if (cancelledReason != null) 'cancelled_reason': cancelledReason,
        if (cancelledAt != null) 'cancelled_at': cancelledAt!.toIso8601String(),
        'outside_city_warned': outsideCityWarned,
        'no_parking_warned': noParkingWarned,
        'auto_end_flagged': autoEndFlagged,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  /// Returns a copy of this trip with the given fields replaced.
  TripModel copyWith({
    String? id,
    String? userId,
    String? scooterId,
    TripStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? reservationExpires,
    TripCoordinates? startCoordinates,
    TripCoordinates? endCoordinates,
    int? startBattery,
    int? endBattery,
    TripEndZone? endZone,
    String? endZoneType,
    int? durationMin,
    double? distanceKm,
    int? cost,
    TripCostBreakdown? costBreakdown,
    String? photoUrl,
    bool? refunded,
    int? refundAmount,
    String? refundReason,
    String? cancelledReason,
    DateTime? cancelledAt,
    bool? outsideCityWarned,
    bool? noParkingWarned,
    bool? autoEndFlagged,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scooterId: scooterId ?? this.scooterId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reservationExpires: reservationExpires ?? this.reservationExpires,
      startCoordinates: startCoordinates ?? this.startCoordinates,
      endCoordinates: endCoordinates ?? this.endCoordinates,
      startBattery: startBattery ?? this.startBattery,
      endBattery: endBattery ?? this.endBattery,
      endZone: endZone ?? this.endZone,
      endZoneType: endZoneType ?? this.endZoneType,
      durationMin: durationMin ?? this.durationMin,
      distanceKm: distanceKm ?? this.distanceKm,
      cost: cost ?? this.cost,
      costBreakdown: costBreakdown ?? this.costBreakdown,
      photoUrl: photoUrl ?? this.photoUrl,
      refunded: refunded ?? this.refunded,
      refundAmount: refundAmount ?? this.refundAmount,
      refundReason: refundReason ?? this.refundReason,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      outsideCityWarned: outsideCityWarned ?? this.outsideCityWarned,
      noParkingWarned: noParkingWarned ?? this.noParkingWarned,
      autoEndFlagged: autoEndFlagged ?? this.autoEndFlagged,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'TripModel(id: $id, status: $status, scooter: $scooterId, cost: $cost)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Paginated trip-list response wrapper.
class TripList {
  final List<TripModel> trips;
  final int total;
  final int limit;
  final int offset;

  const TripList({
    required this.trips,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TripList.fromJson(Map<String, dynamic> json) {
    final rawTrips = json['trips'];
    return TripList(
      trips: rawTrips is List
          ? rawTrips
              .whereType<Map>()
              .map((t) => TripModel.fromJson(t as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      total: toInt(json['total']),
      limit: toInt(json['limit']),
      offset: toInt(json['offset']),
    );
  }

  /// `true` when more pages exist beyond this one.
  bool get hasMore => offset + trips.length < total;

  /// Total revenue across all ended trips in the page.
  int get totalRevenue => trips
      .where((t) => t.isEnded)
      .fold(0, (s, t) => s + (t.cost ?? 0));

  Map<String, dynamic> toJson() => {
        'trips': trips.map((t) => t.toJson()).toList(),
        'total': total,
        'limit': limit,
        'offset': offset,
      };

  @override
  String toString() => 'TripList(${trips.length}/$total)';
}

// --- internal helpers ----------------------------------------------------


