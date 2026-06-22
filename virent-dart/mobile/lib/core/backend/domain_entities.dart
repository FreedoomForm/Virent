// domain_entities.dart — Business domain entities ported from the Node.js stack.
//
// Mirrors backend/src/modules/{trips,scooters,users,auth}/domain/*.entity.js.
// Pure business rules — no HTTP, no DB, no framework imports. Safe to use on
// both the embedded shelf server and the standalone backend.
//
// Per constitution §12 Domain layer:
//   - business rules only
//   - no HTTP, no DB, no framework imports

import 'dart:math';

/// GPS coordinate value object.
///
/// Validates longitude ∈ [-180, 180] and latitude ∈ [-90, 90]. String inputs
/// are coerced to doubles.
class Coordinates {
  /// Longitude in degrees (east-west).
  final double longitude;

  /// Latitude in degrees (north-south).
  final double latitude;

  Coordinates(this.longitude, this.latitude) {
    if (longitude.isNaN || latitude.isNaN) {
      throw ArgumentError('Coordinates cannot be NaN');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('longitude must be in [-180, 180], got $longitude');
    }
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('latitude must be in [-90, 90], got $latitude');
    }
  }

  /// Constructs a [Coordinates] from a JSON map.
  ///
  /// Accepts both `{longitude, latitude}` and `{lng, lat}` shapes, with either
  /// numeric or string values.
  factory Coordinates.fromJson(Map<String, dynamic> json) {
    final lon = json['longitude'] ?? json['lng'] ?? json['lon'];
    final lat = json['latitude'] ?? json['lat'];
    if (lon == null || lat == null) {
      throw ArgumentError('longitude and latitude are required');
    }
    return Coordinates(_toLon(lon), _toLat(lat));
  }

  Map<String, dynamic> toJson() => {
        'longitude': longitude.toString(),
        'latitude': latitude.toString(),
      };

  @override
  String toString() => 'Coordinates($longitude, $latitude)';
}

// =========================================================================
// Trip entity
// =========================================================================

/// All possible trip lifecycle states.
///
/// State machine:
///   reserved ─┬─> active ─┬─> ended
///             │           └─> cancelled
///             ├─> cancelled
///             └─> expired
const tripStatuses = <String>[
  'reserved',
  'active',
  'ended',
  'cancelled',
  'expired',
];

/// Allowed transitions: `from -> [to, to, ...]`.
const Map<String, List<String>> tripTransitions = {
  'reserved': ['active', 'cancelled', 'expired'],
  'active': ['ended', 'cancelled'],
  'ended': <String>[],
  'cancelled': <String>[],
  'expired': <String>[],
};

/// End-zone types used by fare calculation.
const zoneTypes = <String>[
  'parking',
  'bonus_parking',
  'no_parking',
  'street',
];

/// Domain entity representing a single scooter rental trip.
class TripEntity {
  final String? id;
  final String? userId;
  final String? scooterId;
  final String? cityId;
  final String status;

  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? reservationTime;
  final DateTime? reservationExpires;

  final Coordinates? startCoordinates;
  final Coordinates? endCoordinates;

  final int? startBattery;
  final int? endBattery;

  final double distanceKm;
  final int durationMin;
  final double cost;
  final Map<String, dynamic> costBreakdown;

  final String? photoUrl;
  final String? endZoneType;

  final double refundAmount;
  final String? refundReason;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  TripEntity({
    this.id,
    this.userId,
    this.scooterId,
    this.cityId,
    String? status,
    this.startTime,
    this.endTime,
    this.reservationTime,
    this.reservationExpires,
    this.startCoordinates,
    this.endCoordinates,
    this.startBattery,
    this.endBattery,
    double? distanceKm,
    int? durationMin,
    double? cost,
    Map<String, dynamic>? costBreakdown,
    this.photoUrl,
    this.endZoneType,
    double? refundAmount,
    this.refundReason,
    this.createdAt,
    this.updatedAt,
  })  : status = status ?? 'reserved',
        distanceKm = distanceKm ?? 0,
        durationMin = durationMin ?? 0,
        cost = cost ?? 0,
        costBreakdown = costBreakdown ?? const {},
        refundAmount = refundAmount ?? 0;

  /// Constructs a [TripEntity] from a persistence-shaped map.
  ///
  /// Accepts both camelCase and snake_case keys for forward/backward compat
  /// with the Node.js stack.
  factory TripEntity.fromJson(Map<String, dynamic> json) {
    return TripEntity(
      id: (json['id'] ?? json['_id'])?.toString(),
      userId: (json['user_id'] ?? json['userId'])?.toString(),
      scooterId: (json['scooter_id'] ?? json['scooterId'])?.toString(),
      cityId: (json['city_id'] ?? json['cityId'])?.toString(),
      status: json['status'] as String?,
      startTime: _parseDate(json['start_time'] ?? json['startTime']),
      endTime: _parseDate(json['end_time'] ?? json['endTime']),
      reservationTime:
          _parseDate(json['reservation_time'] ?? json['reservationTime']),
      reservationExpires:
          _parseDate(json['reservation_expires'] ?? json['reservationExpires']),
      startCoordinates:
          _parseCoords(json['start_coordinates'] ?? json['startCoordinates']),
      endCoordinates:
          _parseCoords(json['end_coordinates'] ?? json['endCoordinates']),
      startBattery: _parseInt(json['start_battery'] ?? json['startBattery']),
      endBattery: _parseInt(json['end_battery'] ?? json['endBattery']),
      distanceKm: _parseDouble(json['distance_km'] ?? json['distanceKm']),
      durationMin: _parseInt(json['duration_min'] ?? json['durationMin']),
      cost: _parseDouble(json['cost']),
      costBreakdown:
          (json['cost_breakdown'] ?? json['costBreakdown'] ?? const {})
              as Map<String, dynamic>,
      photoUrl: json['photo_url'] as String?,
      endZoneType: json['end_zone_type'] as String?,
      refundAmount: _parseDouble(json['refund_amount']),
      refundReason: json['refund_reason'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (userId != null) 'user_id': userId,
        if (scooterId != null) 'scooter_id': scooterId,
        if (cityId != null) 'city_id': cityId,
        'status': status,
        if (startTime != null) 'start_time': startTime!.toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toIso8601String(),
        if (reservationTime != null)
          'reservation_time': reservationTime!.toIso8601String(),
        if (reservationExpires != null)
          'reservation_expires': reservationExpires!.toIso8601String(),
        if (startCoordinates != null)
          'start_coordinates': startCoordinates!.toJson(),
        if (endCoordinates != null)
          'end_coordinates': endCoordinates!.toJson(),
        if (startBattery != null) 'start_battery': startBattery,
        if (endBattery != null) 'end_battery': endBattery,
        'distance_km': distanceKm,
        'duration_min': durationMin,
        'cost': cost,
        'cost_breakdown': costBreakdown,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (endZoneType != null) 'end_zone_type': endZoneType,
        'refund_amount': refundAmount,
        if (refundReason != null) 'refund_reason': refundReason,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// True if [newStatus] is a valid transition from the current [status].
  bool canTransitionTo(String newStatus) =>
      (tripTransitions[status] ?? const <String>[]).contains(newStatus);

  /// True when the trip is currently in the active riding state.
  bool get isActive => status == 'active';

  /// True when the trip is in the reserved (not yet started) state.
  bool get isReserved => status == 'reserved';

  /// True for any terminal state (ended / cancelled / expired).
  bool get isEnded =>
      status == 'ended' || status == 'cancelled' || status == 'expired';

  /// True when the reservation window has elapsed without the trip starting.
  bool isReservationExpired({DateTime? now}) {
    if (!isReserved || reservationExpires == null) return false;
    return reservationExpires!.isBefore(now ?? DateTime.now());
  }

  /// Pure cost-calculation helper.
  ///
  /// Mirrors `Trip.calculateCost` from the Node entity. Computes the base
  /// fare + time fare - zone discount + zone fee, clamped to >= 0.
  static FareCalculation calculateCost({
    required int durationMin,
    required CityRate city,
    String endZoneType = 'parking',
  }) {
    final base = city.fixedRate;
    final time = max(1, durationMin) * city.timeRate;
    var discount = 0.0;
    var fee = 0.0;

    switch (endZoneType) {
      case 'parking':
        discount += city.parkingZoneRate;
        break;
      case 'bonus_parking':
        discount += city.bonusParkingZoneRate;
        break;
      case 'no_parking':
        fee += city.noParkingZoneRate;
        break;
      case 'street':
        fee += city.noParkingZoneRate;
        break;
    }

    final total = max(0.0, base + time - discount + fee);
    return FareCalculation(
      base: base,
      time: time,
      discount: discount,
      fee: fee,
      total: total,
      cityRates: city,
    );
  }

  @override
  String toString() => 'TripEntity(id=$id, status=$status, cost=$cost)';
}

/// Result of a fare calculation.
class FareCalculation {
  final double base;
  final double time;
  final double discount;
  final double fee;
  final double total;
  final CityRate cityRates;

  const FareCalculation({
    required this.base,
    required this.time,
    required this.discount,
    required this.fee,
    required this.total,
    required this.cityRates,
  });

  Map<String, dynamic> toJson() => {
        'base': base,
        'time': time,
        'discount': discount,
        'fee': fee,
        'total': total,
        'breakdown': {
          'base': base,
          'time': time,
          'discount': discount,
          'fee': fee,
          'city_rates': cityRates.toJson(),
        },
      };
}

/// City rate card used for fare calculation.
class CityRate {
  final String id;
  final String name;
  final double fixedRate;
  final double timeRate;
  final double parkingZoneRate;
  final double bonusParkingZoneRate;
  final double noParkingZoneRate;

  const CityRate({
    required this.id,
    required this.name,
    required this.fixedRate,
    required this.timeRate,
    this.parkingZoneRate = 0,
    this.bonusParkingZoneRate = 0,
    this.noParkingZoneRate = 0,
  });

  factory CityRate.fromJson(Map<String, dynamic> json) => CityRate(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        fixedRate: _parseDouble(json['fixedRate'] ?? json['fixed_rate']) ?? 0,
        timeRate: _parseDouble(json['timeRate'] ?? json['time_rate']) ?? 0,
        parkingZoneRate: _parseDouble(
                json['parkingZoneRate'] ?? json['parking_zone_rate']) ??
            0,
        bonusParkingZoneRate: _parseDouble(
                json['bonusParkingZoneRate'] ?? json['bonus_parking_zone_rate']) ??
            0,
        noParkingZoneRate: _parseDouble(
                json['noParkingZoneRate'] ?? json['no_parking_zone_rate']) ??
            0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fixedRate': fixedRate,
        'timeRate': timeRate,
        'parkingZoneRate': parkingZoneRate,
        'bonusParkingZoneRate': bonusParkingZoneRate,
        'noParkingZoneRate': noParkingZoneRate,
      };
}

// =========================================================================
// Scooter entity
// =========================================================================

const scooterStatuses = <String>[
  'available',
  'reserved',
  'in_use',
  'charging_needed',
  'charging',
  'maintenance',
  'retired',
];

/// Allowed scooter status transitions: `from -> [to, to, ...]`.
const Map<String, List<String>> scooterTransitions = {
  'available': ['reserved', 'maintenance', 'retired'],
  'reserved': ['available', 'in_use'],
  'in_use': ['available', 'charging_needed', 'maintenance'],
  'charging_needed': ['charging', 'available', 'maintenance'],
  'charging': ['available', 'maintenance'],
  'maintenance': ['available', 'retired'],
  'retired': <String>[],
};

/// Domain entity representing a physical scooter.
class ScooterEntity {
  final String? id;
  final String? name;
  final String? owner; // city_id
  final Coordinates? coordinates;
  final int battery;
  final String status;
  final String? serialNumber;
  final String? model;
  final String? manufacturer;
  final String? firmwareVersion;
  final String? hardwareVersion;
  final String? macAddress;
  final String? imei;
  final String? simNumber;
  final double totalDistanceKm;
  final int totalRides;
  final int batteryHealthPercent;
  final int batteryCycles;
  final int maxSpeedKmh;
  final int batteryCapacityWh;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final DateTime? lastMaintenanceAt;
  final DateTime? nextMaintenanceAt;
  final DateTime? retiredAt;
  final String? retiredReason;
  final String? iotSecretHash;
  final DateTime? lastSeen;
  final List<Map<String, dynamic>> log;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ScooterEntity({
    this.id,
    this.name,
    this.owner,
    this.coordinates,
    int? battery,
    String? status,
    this.serialNumber,
    this.model,
    this.manufacturer,
    this.firmwareVersion,
    this.hardwareVersion,
    this.macAddress,
    this.imei,
    this.simNumber,
    double? totalDistanceKm,
    int? totalRides,
    int? batteryHealthPercent,
    int? batteryCycles,
    int? maxSpeedKmh,
    int? batteryCapacityWh,
    this.purchaseDate,
    this.purchasePrice,
    this.lastMaintenanceAt,
    this.nextMaintenanceAt,
    this.retiredAt,
    this.retiredReason,
    this.iotSecretHash,
    this.lastSeen,
    List<Map<String, dynamic>>? log,
    this.createdAt,
    this.updatedAt,
  })  : battery = battery ?? 0,
        status = status ?? 'available',
        totalDistanceKm = totalDistanceKm ?? 0,
        totalRides = totalRides ?? 0,
        batteryHealthPercent = batteryHealthPercent ?? 100,
        batteryCycles = batteryCycles ?? 0,
        maxSpeedKmh = maxSpeedKmh ?? 25,
        batteryCapacityWh = batteryCapacityWh ?? 280,
        log = log ?? const <Map<String, dynamic>>[];

  factory ScooterEntity.fromJson(Map<String, dynamic> json) => ScooterEntity(
        id: (json['id'] ?? json['_id'])?.toString(),
        name: json['name'] as String?,
        owner: (json['owner'] ?? json['city_id'])?.toString(),
        coordinates: _parseCoords(json['coordinates']),
        battery: _parseInt(json['battery']),
        status: json['status'] as String?,
        serialNumber: json['serial_number'] as String?,
        model: json['model'] as String?,
        manufacturer: json['manufacturer'] as String?,
        firmwareVersion: json['firmware_version'] as String?,
        hardwareVersion: json['hardware_version'] as String?,
        macAddress: json['mac_address'] as String?,
        imei: json['imei'] as String?,
        simNumber: json['sim_number'] as String?,
        totalDistanceKm: _parseDouble(json['total_distance_km']),
        totalRides: _parseInt(json['total_rides']),
        batteryHealthPercent: _parseInt(json['battery_health_percent']),
        batteryCycles: _parseInt(json['battery_cycles']),
        maxSpeedKmh: _parseInt(json['max_speed_kmh']),
        batteryCapacityWh: _parseInt(json['battery_capacity_wh']),
        purchaseDate: _parseDate(json['purchase_date']),
        purchasePrice: _parseDouble(json['purchase_price']),
        lastMaintenanceAt: _parseDate(json['last_maintenance_at']),
        nextMaintenanceAt: _parseDate(json['next_maintenance_at']),
        retiredAt: _parseDate(json['retired_at']),
        retiredReason: json['retired_reason'] as String?,
        iotSecretHash: json['iot_secret_hash'] as String?,
        lastSeen: _parseDate(json['last_seen']),
        log: (json['log'] as List?)?.cast<Map<String, dynamic>>().toList(),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (name != null) 'name': name,
        if (owner != null) 'owner': owner,
        if (coordinates != null) 'coordinates': coordinates!.toJson(),
        'battery': battery,
        'status': status,
        if (serialNumber != null) 'serial_number': serialNumber,
        if (model != null) 'model': model,
        if (manufacturer != null) 'manufacturer': manufacturer,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
        if (hardwareVersion != null) 'hardware_version': hardwareVersion,
        if (macAddress != null) 'mac_address': macAddress,
        if (imei != null) 'imei': imei,
        if (simNumber != null) 'sim_number': simNumber,
        'total_distance_km': totalDistanceKm,
        'total_rides': totalRides,
        'battery_health_percent': batteryHealthPercent,
        'battery_cycles': batteryCycles,
        'max_speed_kmh': maxSpeedKmh,
        'battery_capacity_wh': batteryCapacityWh,
        if (purchaseDate != null)
          'purchase_date': purchaseDate!.toIso8601String(),
        if (purchasePrice != null) 'purchase_price': purchasePrice,
        if (lastMaintenanceAt != null)
          'last_maintenance_at': lastMaintenanceAt!.toIso8601String(),
        if (nextMaintenanceAt != null)
          'next_maintenance_at': nextMaintenanceAt!.toIso8601String(),
        if (retiredAt != null) 'retired_at': retiredAt!.toIso8601String(),
        if (retiredReason != null) 'retired_reason': retiredReason,
        if (iotSecretHash != null) 'iot_secret_hash': iotSecretHash,
        if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
        'log': log,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// True if [newStatus] is a valid transition from the current [status].
  bool canTransitionTo(String newStatus) =>
      (scooterTransitions[status] ?? const <String>[]).contains(newStatus);

  bool get isAvailable => status == 'available';
  bool get isUsable =>
      status == 'available' || status == 'reserved' || status == 'in_use';
  bool get needsCharging => battery < 20 && status != 'charging';
  bool get needsMaintenance => status == 'maintenance';
  bool get isRetired => status == 'retired';

  @override
  String toString() =>
      'ScooterEntity(id=$id, status=$status, battery=$battery%)';
}

// =========================================================================
// User entity
// =========================================================================

/// All valid user roles. Mirrors `USER_ROLES` from auth.entity.js.
const userRoles = <String>['user', 'admin', 'juicer', 'mechanic', 'support'];

const userStatuses = <String>['active', 'blocked', 'deleted'];

/// Domain entity representing an authenticated user (rider, admin or staff).
class UserEntity {
  final String? id;
  final String? email;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final double balance;
  final String role;
  final String status;
  final bool phoneVerified;
  final DateTime? acceptedTermsAt;
  final String? termsVersion;
  final DateTime? lastLoginAt;
  final DateTime? passwordChangedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserEntity({
    this.id,
    this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    double? balance,
    String? role,
    String? status,
    this.phoneVerified = false,
    this.acceptedTermsAt,
    this.termsVersion,
    this.lastLoginAt,
    this.passwordChangedAt,
    this.createdAt,
    this.updatedAt,
  })  : balance = balance ?? 0,
        role = role ?? 'user',
        status = status ?? 'active';

  factory UserEntity.fromJson(Map<String, dynamic> json) => UserEntity(
        id: (json['id'] ?? json['_id'])?.toString(),
        email: json['email'] as String?,
        phoneNumber:
            json['phoneNumber'] as String? ?? json['phone'] as String?,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        balance: _parseDouble(json['balance']),
        role: json['role'] as String?,
        status: json['status'] as String?,
        phoneVerified: json['phone_verified'] as bool? ?? false,
        acceptedTermsAt: _parseDate(json['accepted_terms_at']),
        termsVersion: json['terms_version'] as String?,
        lastLoginAt: _parseDate(json['last_login_at']),
        passwordChangedAt: _parseDate(json['password_changed_at']),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        'balance': balance,
        'role': role,
        'status': status,
        'phone_verified': phoneVerified,
        if (acceptedTermsAt != null)
          'accepted_terms_at': acceptedTermsAt!.toIso8601String(),
        if (termsVersion != null) 'terms_version': termsVersion,
        if (lastLoginAt != null)
          'last_login_at': lastLoginAt!.toIso8601String(),
        if (passwordChangedAt != null)
          'password_changed_at': passwordChangedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// Display name for the user.
  String get fullName {
    final parts =
        [firstName ?? '', lastName ?? ''].where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Unknown' : parts.join(' ');
  }

  bool get isActive => status == 'active';
  bool get isAdmin => role == 'admin';
  bool get isJuicer => role == 'juicer';
  bool get isMechanic => role == 'mechanic';
  bool get canLogin => isActive;
  bool get hasAcceptedTerms => acceptedTermsAt != null;

  @override
  String toString() => 'UserEntity(id=$id, role=$role, status=$status)';
}

// =========================================================================
// Auth value objects
// =========================================================================

/// Pair of access + refresh tokens returned on successful authentication.
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final DateTime issuedAt;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn = 900,
    DateTime? issuedAt,
  }) : issuedAt = issuedAt ?? DateTime.now();

  /// True when the access token has passed its expiry window.
  bool get isExpired =>
      DateTime.now().isAfter(issuedAt.add(Duration(seconds: expiresIn)));

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
        'issued_at': issuedAt.toIso8601String(),
      };

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        expiresIn: json['expires_in'] as int? ?? 900,
        issuedAt: _parseDate(json['issued_at']),
      );
}

/// Verification result of an [OtpCode] check.
class OtpVerifyResult {
  final bool ok;
  final String? error;
  final int? attemptsLeft;

  const OtpVerifyResult({required this.ok, this.error, this.attemptsLeft});

  const OtpVerifyResult.success()
      : ok = true,
        error = null,
        attemptsLeft = null;

  const OtpVerifyResult.failure(this.error, {this.attemptsLeft}) : ok = false;
}

/// One-time password value object.
///
/// Tracks attempts and used-flag. Use [verify] to consume the code.
class OtpCode {
  final String phone;
  final String purpose;
  final String code;
  final DateTime expiresAt;
  int attempts;
  bool used;

  OtpCode({
    required this.phone,
    required this.purpose,
    required this.code,
    required this.expiresAt,
    this.attempts = 0,
    this.used = false,
  });

  bool isExpired({DateTime? now}) =>
      expiresAt.isBefore(now ?? DateTime.now());

  bool isBlocked({int maxAttempts = 5}) => attempts >= maxAttempts;

  /// Verifies [inputCode] against the stored code.
  ///
  /// Increments [attempts] on mismatch and marks the code as used on success.
  OtpVerifyResult verify(String inputCode, {int maxAttempts = 5}) {
    if (used) {
      return const OtpVerifyResult.failure('Code already used');
    }
    if (isExpired()) {
      return const OtpVerifyResult.failure('Code expired');
    }
    if (isBlocked(maxAttempts: maxAttempts)) {
      return const OtpVerifyResult.failure('Too many attempts');
    }
    if (code != inputCode) {
      attempts++;
      return OtpVerifyResult.failure('Wrong code',
          attemptsLeft: maxAttempts - attempts);
    }
    used = true;
    return const OtpVerifyResult.success();
  }

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'purpose': purpose,
        'expires_at': expiresAt.toIso8601String(),
        'attempts': attempts,
        'used': used,
      };
}

// =========================================================================
// Parsing helpers
// =========================================================================

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) {
    if (v.isEmpty) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
  if (v is num) {
    return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  }
  return null;
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

Coordinates? _parseCoords(dynamic v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) {
    try {
      return Coordinates.fromJson(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}

double _toLon(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.parse(v);
  throw ArgumentError('Cannot convert $v to longitude');
}

double _toLat(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.parse(v);
  throw ArgumentError('Cannot convert $v to latitude');
}
