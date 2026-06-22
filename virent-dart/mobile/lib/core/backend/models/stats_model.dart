/// Aggregated statistics models for the admin dashboard.
///
/// Ported from `backend/v1/models/stats.js`. The backend exposes
/// several aggregation endpoints:
///   * `GET /stats/overview` — top-line numbers
///   * `GET /stats/revenue` — revenue time series
///   * `GET /stats/trips` — trips per day time series
///   * `GET /stats/scooters` — fleet utilisation
///   * `GET /stats/users` — user growth
///
/// This file ports the four response shapes the mobile admin UI needs:
/// [StatsOverview], [StatsTimeSeries], [FleetUtilization], and a
/// general [Stats] summary used by the home dashboard.
library;


import 'json_helpers.dart';
/// Time-series granularity. Mirrors the `granularity` query parameter.
enum StatsGranularity {
  hour,
  day,
  week,
  month;

  static StatsGranularity fromString(String? raw) {
    switch (raw) {
      case 'hour':
        return StatsGranularity.hour;
      case 'week':
        return StatsGranularity.week;
      case 'month':
        return StatsGranularity.month;
      default:
        return StatsGranularity.day;
    }
  }

  String get wire => switch (this) {
        StatsGranularity.hour => 'hour',
        StatsGranularity.day => 'day',
        StatsGranularity.week => 'week',
        StatsGranularity.month => 'month',
      };
}

/// Reporting period covered by a [Stats] snapshot.
enum StatsPeriod {
  today,
  week,
  month,
  quarter,
  year,
  allTime,
  custom;

  static StatsPeriod fromString(String? raw) {
    switch (raw) {
      case 'today':
        return StatsPeriod.today;
      case 'week':
      case '7d':
        return StatsPeriod.week;
      case 'month':
      case '30d':
        return StatsPeriod.month;
      case 'quarter':
      case '90d':
        return StatsPeriod.quarter;
      case 'year':
      case '365d':
        return StatsPeriod.year;
      case 'all':
      case 'all_time':
        return StatsPeriod.allTime;
      default:
        return StatsPeriod.custom;
    }
  }

  String get wire => switch (this) {
        StatsPeriod.today => 'today',
        StatsPeriod.week => 'week',
        StatsPeriod.month => 'month',
        StatsPeriod.quarter => 'quarter',
        StatsPeriod.year => 'year',
        StatsPeriod.allTime => 'all_time',
        StatsPeriod.custom => 'custom',
      };
}

/// Single point in a [StatsTimeSeries].
class StatsPoint {
  /// Bucket start timestamp. For `day` granularity this is midnight UTC
  /// of the day; for `hour` it is the hour boundary.
  final DateTime timestamp;

  /// Revenue for the bucket, in UZS tiyin.
  final int revenue;

  /// Spend (refunds, juicer payouts) for the bucket, in UZS tiyin.
  final int spend;

  /// Net revenue (`revenue - spend`).
  final int net;

  /// Number of transactions in the bucket.
  final int count;

  /// Average trip duration in the bucket, in minutes (trips series only).
  final double? avgDurationMin;

  /// Average trip cost in the bucket, in UZS tiyin (trips series only).
  final double? avgCost;

  /// Total trip revenue in the bucket, in UZS tiyin (trips series only).
  final int? totalRevenue;

  const StatsPoint({
    required this.timestamp,
    this.revenue = 0,
    this.spend = 0,
    this.net = 0,
    this.count = 0,
    this.avgDurationMin,
    this.avgCost,
    this.totalRevenue,
  });

  factory StatsPoint.fromJson(Map<String, dynamic> json) {
    // The backend groups by `{year, month, day, [hour], [week]}` and
    // returns that as `_id`. We reconstruct a timestamp from it when
    // possible.
    final id = json['_id'];
    DateTime? ts;
    if (id is Map) {
      final year = id['year'];
      final month = id['month'] ?? 1;
      final day = id['day'] ?? 1;
      final hour = id['hour'] ?? 0;
      if (year is int) {
        ts = DateTime.utc(year, month is int ? month : 1,
            day is int ? day : 1, hour is int ? hour : 0);
      }
    }
    final revenue = toInt(json['revenue']);
    final spend = toInt(json['spend']);
    return StatsPoint(
      timestamp: ts ?? parseDate(json['timestamp']) ?? DateTime.now().toUtc(),
      revenue: revenue,
      spend: spend,
      net: revenue - spend,
      count: toInt(json['count']),
      avgDurationMin: _toDoubleOrNull(json['avg_duration'] ??
          json['avgDuration'] ??
          json['avg_duration_min']),
      avgCost: _toDoubleOrNull(json['avg_cost'] ?? json['avgCost']),
      totalRevenue: json['total_revenue'] == null
          ? null
          : toInt(json['total_revenue']),
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'revenue': revenue,
        'spend': spend,
        'net': net,
        'count': count,
        if (avgDurationMin != null) 'avg_duration_min': avgDurationMin,
        if (avgCost != null) 'avg_cost': avgCost,
        if (totalRevenue != null) 'total_revenue': totalRevenue,
      };

  @override
  String toString() =>
      'StatsPoint($timestamp, revenue: $revenue, count: $count)';
}

/// Time-series response shape returned by `/stats/revenue` and
/// `/stats/trips`.
class StatsTimeSeries {
  /// Ordered list of bucket points (oldest first).
  final List<StatsPoint> series;

  /// Granularity of the buckets.
  final StatsGranularity granularity;

  /// Inclusive start of the query window.
  final DateTime from;

  /// Inclusive end of the query window.
  final DateTime to;

  const StatsTimeSeries({
    required this.series,
    required this.granularity,
    required this.from,
    required this.to,
  });

  factory StatsTimeSeries.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'];
    return StatsTimeSeries(
      series: rawSeries is List
          ? rawSeries
              .whereType<Map>()
              .map((p) => StatsPoint.fromJson(p as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      granularity: StatsGranularity.fromString(
          (json['granularity'] ?? 'day').toString()),
      from: parseDate(json['from']) ??
          DateTime.now().toUtc().subtract(const Duration(days: 30)),
      to: parseDate(json['to']) ?? DateTime.now().toUtc(),
    );
  }

  /// Total revenue across all buckets.
  int get totalRevenue => series.fold(0, (s, p) => s + p.revenue);

  /// Total net across all buckets.
  int get totalNet => series.fold(0, (s, p) => s + p.net);

  /// Peak revenue point, or `null` when the series is empty.
  StatsPoint? get peak => series.isEmpty
      ? null
      : series.reduce((a, b) => a.revenue > b.revenue ? a : b);

  /// Average revenue per bucket.
  double get avgRevenue =>
      series.isEmpty ? 0 : totalRevenue / series.length;

  Map<String, dynamic> toJson() => {
        'series': series.map((p) => p.toJson()).toList(),
        'granularity': granularity.wire,
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      };

  @override
  String toString() =>
      'StatsTimeSeries(${series.length} points, $granularity, $from → $to)';
}

/// Aggregated fleet-utilisation response returned by `/stats/scooters`.
class FleetUtilization {
  /// Total scooter count.
  final int total;

  /// Scooter counts broken down by status.
  final Map<String, int> byStatus;

  /// Scooter counts and average battery broken down by city.
  final List<FleetCityBucket> byCity;

  const FleetUtilization({
    required this.total,
    required this.byStatus,
    required this.byCity,
  });

  factory FleetUtilization.fromJson(Map<String, dynamic> json) {
    final rawByStatus = json['by_status'];
    final rawByCity = json['by_city'];
    final statusMap = <String, int>{};
    if (rawByStatus is List) {
      for (final entry in rawByStatus) {
        if (entry is Map) {
          final id = entry['_id']?.toString() ?? 'unknown';
          statusMap[id] = toInt(entry['count']);
        }
      }
    }
    return FleetUtilization(
      total: toInt(json['total']),
      byStatus: statusMap,
      byCity: rawByCity is List
          ? rawByCity
              .whereType<Map>()
              .map((c) => FleetCityBucket.fromJson(c as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
    );
  }

  /// Number of scooters currently in use.
  int get inUse =>
      byStatus['in_use'] ?? byStatus['In use'] ?? 0;

  /// Number of scooters currently available.
  int get available =>
      byStatus['available'] ?? byStatus['Available'] ?? 0;

  /// Number of scooters in maintenance.
  int get maintenance =>
      byStatus['maintenance'] ?? byStatus['Maintenance'] ?? 0;

  /// Number of scooters charging or needing charge.
  int get charging =>
      (byStatus['charging'] ?? 0) + (byStatus['charging_needed'] ?? 0);

  /// Utilisation ratio in `[0, 1]`.
  double get utilizationRate =>
      total == 0 ? 0 : inUse / total;

  /// Availability ratio in `[0, 1]`.
  double get availabilityRate =>
      total == 0 ? 0 : available / total;

  Map<String, dynamic> toJson() => {
        'total': total,
        'by_status': byStatus.entries
            .map((e) => {'_id': e.key, 'count': e.value})
            .toList(),
        'by_city': byCity.map((c) => c.toJson()).toList(),
      };

  @override
  String toString() =>
      'FleetUtilization(total: $total, inUse: $inUse, available: $available)';
}

/// Per-city fleet bucket inside [FleetUtilization].
class FleetCityBucket {
  /// City `_id` (stringified).
  final String cityId;

  /// City name.
  final String cityName;

  /// Scooter count in this city.
  final int count;

  /// Average battery across scooters in this city.
  final double avgBattery;

  const FleetCityBucket({
    required this.cityId,
    required this.cityName,
    required this.count,
    required this.avgBattery,
  });

  factory FleetCityBucket.fromJson(Map<String, dynamic> json) =>
      FleetCityBucket(
        cityId: stringifyId(json['_id'] ?? json['city_id']),
        cityName: (json['city_name'] ?? json['name'] ?? 'Unknown').toString(),
        count: toInt(json['count']),
        avgBattery: toDouble(json['avg_battery'] ?? 0),
      );

  Map<String, dynamic> toJson() => {
        '_id': cityId,
        'city_name': cityName,
        'count': count,
        'avg_battery': avgBattery,
      };

  @override
  String toString() =>
      'FleetCityBucket($cityName, count: $count, avgBattery: $avgBattery%)';
}

/// Top-line overview returned by `/stats/overview`.
class StatsOverview {
  final FleetSummary scooters;
  final UserSummary users;
  final CitySummary cities;
  final TripSummary trips;
  final RevenueSummary revenue;
  final DateTime generatedAt;

  const StatsOverview({
    required this.scooters,
    required this.users,
    required this.cities,
    required this.trips,
    required this.revenue,
    required this.generatedAt,
  });

  factory StatsOverview.fromJson(Map<String, dynamic> json) =>
      StatsOverview(
        scooters: FleetSummary.fromJson(
            (json['scooters'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        users: UserSummary.fromJson(
            (json['users'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        cities: CitySummary.fromJson(
            (json['cities'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        trips: TripSummary.fromJson(
            (json['trips'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        revenue: RevenueSummary.fromJson(
            (json['revenue'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        generatedAt: parseDate(json['generated_at']) ??
            DateTime.now().toUtc(),
      );

  Map<String, dynamic> toJson() => {
        'scooters': scooters.toJson(),
        'users': users.toJson(),
        'cities': cities.toJson(),
        'trips': trips.toJson(),
        'revenue': revenue.toJson(),
        'generated_at': generatedAt.toIso8601String(),
      };

  @override
  String toString() =>
      'StatsOverview(scooters: ${scooters.total}, users: ${users.total}, revenue today: ${revenue.today})';
}

/// Fleet summary inside [StatsOverview].
class FleetSummary {
  final int total;
  final int available;
  final int charging;
  final int maintenance;

  const FleetSummary({
    this.total = 0,
    this.available = 0,
    this.charging = 0,
    this.maintenance = 0,
  });

  factory FleetSummary.fromJson(Map<String, dynamic> json) => FleetSummary(
        total: toInt(json['total']),
        available: toInt(json['available']),
        charging: toInt(json['charging']),
        maintenance: toInt(json['maintenance']),
      );

  Map<String, dynamic> toJson() => {
        'total': total,
        'available': available,
        'charging': charging,
        'maintenance': maintenance,
      };
}

/// User summary inside [StatsOverview].
class UserSummary {
  final int total;
  final int activeToday;

  const UserSummary({this.total = 0, this.activeToday = 0});

  factory UserSummary.fromJson(Map<String, dynamic> json) => UserSummary(
        total: toInt(json['total']),
        activeToday: toInt(json['active_today'] ?? json['activeToday']),
      );

  Map<String, dynamic> toJson() =>
      {'total': total, 'active_today': activeToday};
}

/// City summary inside [StatsOverview].
class CitySummary {
  final int total;

  const CitySummary({this.total = 0});

  factory CitySummary.fromJson(Map<String, dynamic> json) =>
      CitySummary(total: toInt(json['total']));

  Map<String, dynamic> toJson() => {'total': total};
}

/// Trip summary inside [StatsOverview].
class TripSummary {
  final int today;
  final int week;
  final int month;

  const TripSummary({this.today = 0, this.week = 0, this.month = 0});

  factory TripSummary.fromJson(Map<String, dynamic> json) => TripSummary(
        today: toInt(json['today']),
        week: toInt(json['week']),
        month: toInt(json['month']),
      );

  Map<String, dynamic> toJson() =>
      {'today': today, 'week': week, 'month': month};
}

/// Revenue summary inside [StatsOverview].
class RevenueSummary {
  final int today;
  final int week;
  final int month;

  const RevenueSummary({this.today = 0, this.week = 0, this.month = 0});

  factory RevenueSummary.fromJson(Map<String, dynamic> json) => RevenueSummary(
        today: toInt(json['today']),
        week: toInt(json['week']),
        month: toInt(json['month']),
      );

  Map<String, dynamic> toJson() =>
      {'today': today, 'week': week, 'month': month};
}

/// Compact stats snapshot used by the mobile home dashboard.
///
/// This is a *derived* view that pulls together a handful of metrics
/// from the overview, time-series, and fleet-utilization responses into
/// a single render-ready shape.
class Stats {
  /// Total revenue across all completed transactions, in UZS tiyin.
  final int totalRevenue;

  /// Total trip count.
  final int totalTrips;

  /// Number of users who took at least one ride in the period.
  final int activeUsers;

  /// Total scooters in the fleet.
  final int totalScooters;

  /// Fleet utilisation ratio in `[0, 1]`.
  final double utilization;

  /// Average trip cost, in UZS tiyin.
  final double avgTripCost;

  /// Reporting period covered by this snapshot.
  final StatsPeriod period;

  /// Optional window the snapshot was computed against.
  final DateTime? from;
  final DateTime? to;

  /// When the snapshot was generated.
  final DateTime? generatedAt;

  const Stats({
    required this.totalRevenue,
    required this.totalTrips,
    required this.activeUsers,
    required this.totalScooters,
    required this.utilization,
    required this.avgTripCost,
    required this.period,
    this.from,
    this.to,
    this.generatedAt,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        totalRevenue: toInt(json['total_revenue'] ?? json['totalRevenue']),
        totalTrips: toInt(json['total_trips'] ?? json['totalTrips']),
        activeUsers: toInt(json['active_users'] ?? json['activeUsers']),
        totalScooters:
            toInt(json['total_scooters'] ?? json['totalScooters']),
        utilization: toDouble(json['utilization']),
        avgTripCost: toDouble(json['avg_trip_cost'] ?? json['avgTripCost']),
        period: StatsPeriod.fromString(
            (json['period'] ?? 'all_time').toString()),
        from: parseDate(json['from']),
        to: parseDate(json['to']),
        generatedAt: parseDate(json['generated_at']),
      );

  /// Builds a compact [Stats] from a full [StatsOverview] + [FleetUtilization].
  factory Stats.fromOverview(
    StatsOverview overview,
    FleetUtilization fleet, {
    StatsPeriod period = StatsPeriod.month,
  }) {
    final avgCost = overview.trips.month == 0
        ? 0.0
        : overview.revenue.month / overview.trips.month;
    return Stats(
      totalRevenue: overview.revenue.month,
      totalTrips: overview.trips.month,
      activeUsers: overview.users.activeToday,
      totalScooters: fleet.total,
      utilization: fleet.utilizationRate,
      avgTripCost: avgCost,
      period: period,
      generatedAt: overview.generatedAt,
    );
  }

  /// Revenue per scooter in the period (a measure of fleet productivity).
  double get revenuePerScooter =>
      totalScooters == 0 ? 0 : totalRevenue / totalScooters;

  /// Trips per active user.
  double get tripsPerActiveUser =>
      activeUsers == 0 ? 0 : totalTrips / activeUsers;

  Map<String, dynamic> toJson() => {
        'total_revenue': totalRevenue,
        'total_trips': totalTrips,
        'active_users': activeUsers,
        'total_scooters': totalScooters,
        'utilization': utilization,
        'avg_trip_cost': avgTripCost,
        'period': period.wire,
        if (from != null) 'from': from!.toIso8601String(),
        if (to != null) 'to': to!.toIso8601String(),
        if (generatedAt != null)
          'generated_at': generatedAt!.toIso8601String(),
      };

  Stats copyWith({
    int? totalRevenue,
    int? totalTrips,
    int? activeUsers,
    int? totalScooters,
    double? utilization,
    double? avgTripCost,
    StatsPeriod? period,
    DateTime? from,
    DateTime? to,
    DateTime? generatedAt,
  }) {
    return Stats(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalTrips: totalTrips ?? this.totalTrips,
      activeUsers: activeUsers ?? this.activeUsers,
      totalScooters: totalScooters ?? this.totalScooters,
      utilization: utilization ?? this.utilization,
      avgTripCost: avgTripCost ?? this.avgTripCost,
      period: period ?? this.period,
      from: from ?? this.from,
      to: to ?? this.to,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  String toString() =>
      'Stats(period: $period, revenue: $totalRevenue, trips: $totalTrips, utilization: ${(utilization * 100).toStringAsFixed(1)}%)';
}

// --- internal helpers ----------------------------------------------------


double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

