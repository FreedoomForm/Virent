/// Range model — converts a scooter's battery percentage into a human
/// readable range estimate.
///
/// Ported from a competitor's scooter card where the range is rendered
/// as `"100% до 40 км на 5 ч 32 мин"`. The model encapsulates the
/// conversion math so the UI stays declarative:
///
/// * **Range** — `battery * 0.4` km (1% ≈ 0.4 km).
/// * **Time** — `range / 12` hours (assumed average speed of 12 km/h),
///   decomposed into whole hours + remaining minutes.
///
/// The model is intentionally framework-free (no Flutter or Riverpod
/// dependency) so it can be unit-tested in isolation and reused by the
/// booking modal, the scooter marker tooltip and the parking-zone list.
class ScooterRangeModel {
  /// Creates a [ScooterRangeModel].
  ///
  /// Prefer the [ScooterRangeModel.fromBattery] factory in calling code —
  /// this constructor is mainly used by `copyWith` and tests.
  const ScooterRangeModel({
    required this.batteryPercent,
    required this.rangeKm,
    required this.estimatedHours,
    required this.estimatedMinutes,
  });

  /// Builds a range estimate from a raw battery percentage.
  ///
  /// [batteryPercent] is clamped to the `[0, 100]` range so a malformed
  /// telemetry payload never produces a nonsensical estimate.
  factory ScooterRangeModel.fromBattery(int batteryPercent) {
    final clamped = batteryPercent.clamp(0, 100);
    // 1% battery ≈ 0.4 km of range.
    final rangeKm = (clamped * 0.4).roundToDouble();
    // Average riding speed is 12 km/h.
    final totalMinutes = (rangeKm / 12 * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return ScooterRangeModel(
      batteryPercent: clamped,
      rangeKm: rangeKm,
      estimatedHours: hours,
      estimatedMinutes: minutes,
    );
  }

  /// The battery percentage the estimate was derived from.
  final int batteryPercent;

  /// Estimated rideable distance in kilometres.
  final double rangeKm;

  /// Whole hours of estimated ride time.
  final int estimatedHours;

  /// Remaining minutes of estimated ride time (always `0–59`).
  final int estimatedMinutes;

  /// Total estimated ride time in minutes (hours × 60 + minutes).
  int get totalMinutes => estimatedHours * 60 + estimatedMinutes;

  /// `true` when the scooter cannot be safely rented (battery <= 0).
  bool get isEmpty => rangeKm <= 0;

  /// Formats the estimate as `"100% до 40 км на 5 ч 32 мин"`.
  ///
  /// When the ride time is shorter than an hour the hours component is
  /// omitted, e.g. `"50% до 20 км на 1 ч 40 мин"` vs.
  /// `"50% до 20 км на 40 мин"` (when the estimate rounds to 0 hours).
  String get displayLabel {
    final buffer = StringBuffer('$batteryPercent% до ');
    buffer.write(_formatKm(rangeKm));
    buffer.write(' км на ');
    buffer.write(_formatDuration());
    return buffer.toString();
  }

  /// Formats only the distance portion, e.g. `"40 км"` (no decimals when
  /// the range is a whole number).
  String get distanceLabel => '${_formatKm(rangeKm)} км';

  /// Formats only the time portion, e.g. `"5 ч 32 мин"` or `"40 мин"`.
  String get durationLabel => _formatDuration();

  String _formatKm(double km) {
    if (km == km.roundToDouble()) return km.toInt().toString();
    return km.toStringAsFixed(1);
  }

  String _formatDuration() {
    if (estimatedHours > 0) {
      return '$estimatedHours ч $estimatedMinutes мин';
    }
    return '$estimatedMinutes мин';
  }

  /// Returns a copy with the supplied fields replaced.
  ScooterRangeModel copyWith({
    int? batteryPercent,
    double? rangeKm,
    int? estimatedHours,
    int? estimatedMinutes,
  }) {
    return ScooterRangeModel(
      batteryPercent: batteryPercent ?? this.batteryPercent,
      rangeKm: rangeKm ?? this.rangeKm,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  @override
  String toString() =>
      'ScooterRangeModel(battery: $batteryPercent%, range: $rangeKm km, '
      'time: ${estimatedHours}h${estimatedMinutes}m)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScooterRangeModel &&
          other.batteryPercent == batteryPercent &&
          other.rangeKm == rangeKm &&
          other.estimatedHours == estimatedHours &&
          other.estimatedMinutes == estimatedMinutes);

  @override
  int get hashCode => Object.hash(
      batteryPercent, rangeKm, estimatedHours, estimatedMinutes);
}
