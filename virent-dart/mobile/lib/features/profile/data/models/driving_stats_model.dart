/// Gamification stats for the rider, powering the "Школа вождения" card on
/// the profile screen.
///
/// Ported from the Swift competitor's `DrivingStatsModel`. The model carries
/// four running totals (`totalKm`, `totalRides`, `totalMinutes`,
/// `totalSaved`), a derived [level] computed from the rider's total
/// distance, and a list of [Achievement] badges the rider has unlocked.
///
/// The level system uses fixed distance thresholds:
///
/// | Уровень     | Порог (км) | Английский |
/// |-------------|------------|------------|
/// | Новичок     | 0          | Novice     |
/// | Любитель    | 50         | Amateur    |
/// | Профи       | 200        | Pro        |
/// | Мастер      | 500        | Master     |
///
/// The model is intentionally framework-free (no Flutter / Riverpod) so it
/// can be unit-tested in isolation and reused by both the profile and
/// ride-history features.
library;

/// Rider level in the driving-school progression.
///
/// Ordered from lowest to highest distance threshold. Use [fromKm] to
/// resolve the level for a given total distance.
enum DrivingLevel {
  /// 0–49 km — the rider has just signed up.
  novice,

  /// 50–199 km — the rider has some experience.
  amateur,

  /// 200–499 km — a confident daily commuter.
  pro,

  /// 500+ km — a long-time Virent rider.
  master,
}

/// Extension adding presentation helpers to [DrivingLevel].
extension DrivingLevelX on DrivingLevel {
  /// Russian display label shown in the UI.
  String get label {
    switch (this) {
      case DrivingLevel.novice:
        return 'Новичок';
      case DrivingLevel.amateur:
        return 'Любитель';
      case DrivingLevel.pro:
        return 'Профи';
      case DrivingLevel.master:
        return 'Мастер';
    }
  }

  /// Lower-case transliterated label (useful for analytics events).
  String get slug {
    switch (this) {
      case DrivingLevel.novice:
        return 'novice';
      case DrivingLevel.amateur:
        return 'amateur';
      case DrivingLevel.pro:
        return 'pro';
      case DrivingLevel.master:
        return 'master';
    }
  }

  /// Distance threshold (in km) the rider needs to *enter* this level.
  double get minKm {
    switch (this) {
      case DrivingLevel.novice:
        return 0;
      case DrivingLevel.amateur:
        return 50;
      case DrivingLevel.pro:
        return 200;
      case DrivingLevel.master:
        return 500;
    }
  }

  /// Distance threshold (in km) the rider needs to *leave* this level, or
  /// `null` for [DrivingLevel.master] which has no upper bound.
  double? get maxKm {
    switch (this) {
      case DrivingLevel.novice:
        return 50;
      case DrivingLevel.amateur:
        return 200;
      case DrivingLevel.pro:
        return 500;
      case DrivingLevel.master:
        return null;
    }
  }

  /// Resolves the level for a given total distance in kilometres.
  static DrivingLevel fromKm(double km) {
    if (km >= 500) return DrivingLevel.master;
    if (km >= 200) return DrivingLevel.pro;
    if (km >= 50) return DrivingLevel.amateur;
    return DrivingLevel.novice;
  }
}

/// A single achievement badge unlocked by the rider.
class Achievement {
  /// Creates an [Achievement].
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
  });

  /// Stable identifier (e.g. `'first_ride'`, `'night_owl'`).
  final String id;

  /// Short human-readable title (e.g. `'Первый заезд'`).
  final String title;

  /// One-line explanation shown under the title.
  final String description;

  /// Material icon glyph used to render the badge.
  ///
  /// Stored as `int` (code point) so the model stays framework-free; the
  /// UI layer converts it back to `IconData` via `IconData(icon)`.
  final int icon;

  /// ISO-8601 timestamp marking when the badge was unlocked, or `null`
  /// while the achievement is locked.
  final String? unlockedAt;

  /// `true` when the rider has unlocked this achievement.
  bool get isUnlocked => unlockedAt != null;

  /// Parses a JSON object into an [Achievement].
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      icon: json['icon'] is int
          ? json['icon'] as int
          : int.tryParse('${json['icon']}') ?? 0xe000,
      unlockedAt: (json['unlocked_at'] ?? json['unlockedAt'])?.toString(),
    );
  }

  /// Serialises the achievement back to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        if (unlockedAt != null) 'unlocked_at': unlockedAt,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Achievement && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Immutable snapshot of the rider's driving-school stats.
class DrivingStatsModel {
  /// Creates a [DrivingStatsModel].
  const DrivingStatsModel({
    this.totalKm = 0,
    this.totalRides = 0,
    this.totalMinutes = 0,
    this.totalSaved = 0,
    this.achievements = const [],
  });

  /// Empty placeholder used before the first load completes.
  static const DrivingStatsModel empty = DrivingStatsModel();

  /// Total distance ridden, in kilometres.
  final double totalKm;

  /// Number of completed rides.
  final int totalRides;

  /// Total time spent riding, in minutes.
  final int totalMinutes;

  /// Total savings vs the per-minute tariff (thanks to packages and promos),
  /// in the smallest currency unit.
  final int totalSaved;

  /// Achievement badges the rider has unlocked (or could unlock).
  final List<Achievement> achievements;

  /// Resolved level for the rider's [totalKm].
  DrivingLevel get level => DrivingLevelX.fromKm(totalKm);

  /// Progress (0.0–1.0) toward the next level.
  ///
  /// `1.0` once the rider has reached [DrivingLevel.master] since there is
  /// no further level to attain.
  double get progressToNextLevel {
    final current = level;
    final next = current.maxKm;
    if (next == null) return 1.0;
    final span = next - current.minKm;
    if (span <= 0) return 1.0;
    final travelled = totalKm - current.minKm;
    final ratio = travelled / span;
    if (ratio <= 0) return 0;
    if (ratio >= 1) return 1;
    return ratio;
  }

  /// Remaining kilometres the rider needs to ride to reach the next level.
  /// `0` for [DrivingLevel.master].
  double get kmToNextLevel {
    final next = level.maxKm;
    if (next == null) return 0;
    final remaining = next - totalKm;
    return remaining < 0 ? 0 : remaining;
  }

  /// Parses a JSON object into a [DrivingStatsModel].
  ///
  /// Resilient to missing fields — defaults are substituted so a partial
  /// payload never crashes the UI.
  factory DrivingStatsModel.fromJson(Map<String, dynamic> json) {
    double _readDouble(Object? v, [double fallback = 0]) =>
        v == null ? fallback : (v is num ? v.toDouble() : double.tryParse('$v') ?? fallback);
    int _readInt(Object? v, [int fallback = 0]) =>
        v == null ? fallback : (v is int ? v : int.tryParse('$v') ?? fallback);
    final rawAchievements = json['achievements'];
    return DrivingStatsModel(
      totalKm: _readDouble(json['total_km'] ?? json['totalKm']),
      totalRides: _readInt(json['total_rides'] ?? json['totalRides']),
      totalMinutes: _readInt(json['total_minutes'] ?? json['totalMinutes']),
      totalSaved: _readInt(json['total_saved'] ?? json['totalSaved']),
      achievements: rawAchievements is List
          ? rawAchievements
              .whereType<Map<String, dynamic>>()
              .map(Achievement.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  /// Serialises the model back to JSON (used for local caching).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'total_km': totalKm,
        'total_rides': totalRides,
        'total_minutes': totalMinutes,
        'total_saved': totalSaved,
        'achievements': achievements.map((a) => a.toJson()).toList(),
      };

  /// Returns a copy with the supplied fields replaced.
  DrivingStatsModel copyWith({
    double? totalKm,
    int? totalRides,
    int? totalMinutes,
    int? totalSaved,
    List<Achievement>? achievements,
  }) {
    return DrivingStatsModel(
      totalKm: totalKm ?? this.totalKm,
      totalRides: totalRides ?? this.totalRides,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      totalSaved: totalSaved ?? this.totalSaved,
      achievements: achievements ?? this.achievements,
    );
  }

  @override
  String toString() =>
      'DrivingStatsModel(km: $totalKm, rides: $totalRides, level: ${level.slug})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrivingStatsModel &&
          other.totalKm == totalKm &&
          other.totalRides == totalRides &&
          other.totalMinutes == totalMinutes &&
          other.totalSaved == totalSaved);

  @override
  int get hashCode =>
      Object.hash(totalKm, totalRides, totalMinutes, totalSaved);
}
