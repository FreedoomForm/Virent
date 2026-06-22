/// City model with rate card and operational zones.
///
/// Ported from `backend/v1/models/cities.js`. A city owns a fleet of
/// scooters (via the `owner` field on scooters) and defines:
///   * a [rates] card (start fee, per-minute fee, zone surcharges/discounts)
///   * a list of geofenced [zones] (parking / no-parking / bonus-parking /
///     charging)
///
/// The original JS module also exposes `getAllCitiesOverview` which
/// aggregates scooter counts per status — that derived shape is captured
/// here by [CityOverview].
library;

import 'zone_model.dart' show ZoneModel, GeoPoint;
import 'json_helpers.dart';

/// Top-level city entity returned by `GET /cities` and friends.
class CityModel {
  /// MongoDB `_id` (24-char hex).
  final String id;

  /// Human-readable name (e.g. "Tashkent"). Unique.
  final String name;

  /// Rate card applied to every trip taken in this city.
  final CityRates rates;

  /// Geofenced zones inside the city (parking, no-parking, etc.).
  final List<ZoneModel> zones;

  /// Optional outer service-area polygon. Scooters leaving this boundary
  /// trigger an "outside service area" warning.
  final List<GeoPoint> outerBoundary;

  /// Percentage tax applied on top of trip cost (e.g. 12 for 12% VAT).
  /// Defaults to 0 when the backend does not specify it.
  final double taxPercent;

  /// Total scooter count in this city (denormalised by `getAllCitiesOverview`).
  final int scooterCount;

  /// Snapshot of scooter counts broken down by status.
  final CityScooterStatus? scooterStatus;

  /// Creates a [CityModel].
  const CityModel({
    required this.id,
    required this.name,
    required this.rates,
    this.zones = const [],
    this.outerBoundary = const [],
    this.taxPercent = 0,
    this.scooterCount = 0,
    this.scooterStatus,
  });

  /// Parses a JSON object (MongoDB document) into a [CityModel].
  factory CityModel.fromJson(Map<String, dynamic> json) {
    final rawRates = json['taxRates'] ?? json['rates'];
    final rawZones = json['zones'];
    final rawOuter = json['outer_boundary'] ?? json['outerBoundary'];
    final rawTax =
        json['tax_percent'] ?? json['taxPercent'] ?? json['tax_percentage'];
    return CityModel(
      id: stringifyId(json['_id'] ?? json['id']),
      name: (json['name'] ?? '').toString(),
      rates: rawRates is Map<String, dynamic>
          ? CityRates.fromJson(rawRates)
          : CityRates.zero,
      zones: rawZones is List
          ? rawZones
              .whereType<Map>()
              .map((z) => ZoneModel.fromJson(z as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      outerBoundary: _parsePoints(rawOuter),
      taxPercent: toDouble(rawTax),
      scooterCount: toInt(json['totalScooters'] ?? json['scooter_count']),
      scooterStatus: json['totalAvailable'] != null ||
              json['totalInUse'] != null
          ? CityScooterStatus.fromJson(json)
          : null,
    );
  }

  /// `true` when the city has at least one zone of [type] (modern bucket).
  bool hasZoneType(String type) => zones.any((z) => z.type.wire == type);

  /// All parking zones (regular + bonus) in this city.
  List<ZoneModel> get parkingZones =>
      zones.where((z) => z.isParking).toList(growable: false);

  /// All charging zones in this city (juicer drop-off targets).
  List<ZoneModel> get chargingZones =>
      zones.where((z) => z.isCharging).toList(growable: false);

  /// Serialises the city back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'taxRates': rates.toJson(),
        'zones': zones.map((z) => z.toJson()).toList(),
        if (outerBoundary.isNotEmpty)
          'outer_boundary': outerBoundary.map((p) => p.toJson()).toList(),
        if (taxPercent != 0) 'tax_percent': taxPercent,
        if (scooterCount != 0) 'scooter_count': scooterCount,
        if (scooterStatus != null) ...scooterStatus!.toJson(),
      };

  /// Returns a copy of this city with the given fields replaced.
  CityModel copyWith({
    String? id,
    String? name,
    CityRates? rates,
    List<ZoneModel>? zones,
    List<GeoPoint>? outerBoundary,
    double? taxPercent,
    int? scooterCount,
    CityScooterStatus? scooterStatus,
  }) {
    return CityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rates: rates ?? this.rates,
      zones: zones ?? this.zones,
      outerBoundary: outerBoundary ?? this.outerBoundary,
      taxPercent: taxPercent ?? this.taxPercent,
      scooterCount: scooterCount ?? this.scooterCount,
      scooterStatus: scooterStatus ?? this.scooterStatus,
    );
  }

  @override
  String toString() =>
      'CityModel(id: $id, name: $name, zones: ${zones.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CityModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Per-city rate card. All amounts are in UZS tiyin-equivalent integers
/// (the smallest unit the backend operates on).
class CityRates {
  /// Flat start fee charged the moment a trip begins.
  final int fixedRate;

  /// Per-minute rental fee.
  final int timeRate;

  /// Discount applied when the user ends the ride inside a parking zone.
  final int parkingZoneRate;

  /// Additional discount when the user ends inside a *bonus* parking zone
  /// (high-priority charging hub).
  final int bonusParkingZoneRate;

  /// Penalty fee charged when the user ends inside a no-parking zone.
  final int noParkingZoneRate;

  /// Discount when the user moves from a no-parking zone to a valid
  /// parking zone in the same ride (positive reinforcement).
  final int noParkingToValidParking;

  /// Reward paid to juicers when they return a charged scooter into a
  /// charging zone of this city.
  final int chargingZoneRate;

  const CityRates({
    required this.fixedRate,
    required this.timeRate,
    required this.parkingZoneRate,
    required this.bonusParkingZoneRate,
    required this.noParkingZoneRate,
    required this.noParkingToValidParking,
    this.chargingZoneRate = 0,
  });

  /// Default zero-rate card for safety when the backend omits fields.
  static const CityRates zero = CityRates(
    fixedRate: 0,
    timeRate: 0,
    parkingZoneRate: 0,
    bonusParkingZoneRate: 0,
    noParkingZoneRate: 0,
    noParkingToValidParking: 0,
  );

  factory CityRates.fromJson(Map<String, dynamic> json) {
    int pickInt(Object? v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return CityRates(
      fixedRate: pickInt(json['fixedRate']),
      timeRate: pickInt(json['timeRate']),
      parkingZoneRate: pickInt(json['parkingZoneRate']),
      bonusParkingZoneRate: pickInt(json['bonusParkingZoneRate']),
      noParkingZoneRate: pickInt(json['noParkingZoneRate']),
      noParkingToValidParking: pickInt(json['noParkingToValidParking']),
      chargingZoneRate: pickInt(json['chargingZoneRate']),
    );
  }

  /// Calculates the total cost of a trip in this city.
  ///
  /// Mirrors the formula in `trips.js::endTrip`:
  ///   `total = max(0, base + time - discount + fee)`.
  int calculateCost({
    required int durationMinutes,
    String? endZoneType,
  }) {
    final base = fixedRate;
    final time = durationMinutes * timeRate;
    int discount = 0;
    int fee = 0;
    switch (endZoneType) {
      case 'parkingZone':
      case 'parking':
        discount = parkingZoneRate;
        break;
      case 'bonusParkingZone':
      case 'bonus_parking':
        discount = bonusParkingZoneRate;
        break;
      case 'noParkingZone':
      case 'no_parking':
        fee = noParkingZoneRate;
        break;
    }
    final total = base + time - discount + fee;
    return total < 0 ? 0 : total;
  }

  Map<String, dynamic> toJson() => {
        'fixedRate': fixedRate,
        'timeRate': timeRate,
        'parkingZoneRate': parkingZoneRate,
        'bonusParkingZoneRate': bonusParkingZoneRate,
        'noParkingZoneRate': noParkingZoneRate,
        'noParkingToValidParking': noParkingToValidParking,
        'chargingZoneRate': chargingZoneRate,
      };

  @override
  String toString() =>
      'CityRates(fixed: $fixedRate, time: $timeRate, parking: $parkingZoneRate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CityRates &&
          other.fixedRate == fixedRate &&
          other.timeRate == timeRate);

  @override
  int get hashCode => Object.hash(fixedRate, timeRate);
}

/// Aggregated scooter-status counts for a city.
class CityScooterStatus {
  final int total;
  final int inUse;
  final int available;
  final int unavailable;
  final int maintenance;
  final int off;

  const CityScooterStatus({
    this.total = 0,
    this.inUse = 0,
    this.available = 0,
    this.unavailable = 0,
    this.maintenance = 0,
    this.off = 0,
  });

  factory CityScooterStatus.fromJson(Map<String, dynamic> json) =>
      CityScooterStatus(
        total: toInt(json['totalScooters'] ?? json['total']),
        inUse: toInt(json['totalInUse'] ?? json['in_use']),
        available: toInt(json['totalAvailable'] ?? json['available']),
        unavailable: toInt(json['totalUnavailable'] ?? json['unavailable']),
        maintenance: toInt(json['totalMaintenance'] ?? json['maintenance']),
        off: toInt(json['totalOff'] ?? json['off']),
      );

  Map<String, dynamic> toJson() => {
        'totalScooters': total,
        'totalInUse': inUse,
        'totalAvailable': available,
        'totalUnavailable': unavailable,
        'totalMaintenance': maintenance,
        'totalOff': off,
      };

  @override
  String toString() =>
      'CityScooterStatus(total: $total, available: $available, inUse: $inUse)';
}

/// Aggregated overview row returned by `GET /cities/overview`.
class CityOverview {
  final String id;
  final String name;
  final int totalScooters;
  final int totalInUse;
  final int totalAvailable;
  final int totalUnavailable;
  final int totalMaintenance;
  final int totalOff;
  final int totalZones;

  const CityOverview({
    required this.id,
    required this.name,
    this.totalScooters = 0,
    this.totalInUse = 0,
    this.totalAvailable = 0,
    this.totalUnavailable = 0,
    this.totalMaintenance = 0,
    this.totalOff = 0,
    this.totalZones = 0,
  });

  factory CityOverview.fromJson(Map<String, dynamic> json) => CityOverview(
        id: stringifyId(json['_id'] ?? json['id']),
        name: (json['name'] ?? '').toString(),
        totalScooters: toInt(json['totalScooters']),
        totalInUse: toInt(json['totalInUse']),
        totalAvailable: toInt(json['totalAvailable']),
        totalUnavailable: toInt(json['totalUnavailable']),
        totalMaintenance: toInt(json['totalMaintenance']),
        totalOff: toInt(json['totalOff']),
        totalZones: toInt(json['totalZones']),
      );

  /// Fleet utilisation ratio in the range `[0, 1]`.
  double get utilization =>
      totalScooters == 0 ? 0 : totalInUse / totalScooters;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'totalScooters': totalScooters,
        'totalInUse': totalInUse,
        'totalAvailable': totalAvailable,
        'totalUnavailable': totalUnavailable,
        'totalMaintenance': totalMaintenance,
        'totalOff': totalOff,
        'totalZones': totalZones,
      };

  @override
  String toString() => 'CityOverview($name, scooters: $totalScooters)';
}

// --- internal helpers (file-private) ------------------------------------


List<GeoPoint> _parsePoints(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((p) => GeoPoint.fromJson(p as Map<String, dynamic>))
      .toList(growable: false);
}
