/// Data model representing a Virent ride (a.k.a. "trip").
///
/// Mirrors the JSON shape produced by the embedded server's `/trips/*`
/// endpoints:
///
/// ```json
/// {
///   "id": "t1",
///   "scooter_id": "s1",
///   "start_time": "2025-06-18T10:30:00.000Z",
///   "end_time": null,
///   "cost": 0,
///   "status": "ongoing",
///   "start_lat": 41.3111,
///   "start_lng": 69.2406,
///   "rate_per_min": 1200
/// }
/// ```
class RideModel {
  /// Server-side ride identifier.
  final String id;

  /// Identifier of the scooter this ride was started on.
  final String scooterId;

  /// ISO-8601 timestamp marking when the ride started.
  final String? startTime;

  /// ISO-8601 timestamp marking when the ride ended (`null` while ongoing).
  final String? endTime;

  /// Total cost in the smallest currency unit (UZS tiyin). `0` while the
  /// ride is still in progress; populated by the server on `endRide`.
  final int cost;

  /// Lifecycle status: `ongoing`, `completed`, `cancelled`, `unpaid`.
  final String status;

  /// Latitude captured at ride start, used by the active-ride map view.
  final double? startLat;

  /// Longitude captured at ride start.
  final double? startLng;

  /// Per-minute rate snapshot at ride start. Stored on the model so the
  /// active ride screen can compute the live cost without a second fetch.
  final int ratePerMin;

  /// Creates a [RideModel].
  const RideModel({
    required this.id,
    required this.scooterId,
    this.startTime,
    this.endTime,
    required this.cost,
    required this.status,
    this.startLat,
    this.startLng,
    required this.ratePerMin,
  });

  /// Empty placeholder used before the first load completes.
  static const RideModel empty = RideModel(
    id: '',
    scooterId: '',
    cost: 0,
    status: 'unknown',
    ratePerMin: 1200,
  );

  /// Parses a JSON object into a [RideModel].
  factory RideModel.fromJson(Map<String, dynamic> json) {
    int _readInt(Object? v, [int fallback = 0]) =>
        v == null ? fallback : (v is int ? v : int.tryParse('$v') ?? fallback);
    double? _readDouble(Object? v) => v == null
        ? null
        : (v is num ? v.toDouble() : double.tryParse('$v'));
    return RideModel(
      id: (json['id'] ?? json['trip_id'] ?? '').toString(),
      scooterId: (json['scooter_id'] ?? json['scooterId'] ?? '').toString(),
      startTime: (json['start_time'] ?? json['startTime'])?.toString(),
      endTime: (json['end_time'] ?? json['endTime'])?.toString(),
      cost: _readInt(json['cost'] ?? json['total_cost']),
      status: (json['status'] ?? 'unknown').toString(),
      startLat: _readDouble(json['start_lat'] ?? json['startLat']),
      startLng: _readDouble(json['start_lng'] ?? json['startLng']),
      ratePerMin: _readInt(
          json['rate_per_min'] ?? json['ratePerMin'], 1200),
    );
  }

  /// `true` while the ride is still in progress.
  bool get isOngoing => status == 'ongoing';

  /// `true` once the ride has been ended (whether paid or not).
  bool get isCompleted => status == 'completed' || status == 'unpaid';

  /// Parses [startTime] into a [DateTime], or `null` when missing/invalid.
  DateTime? get startDateTime => _parseIso(startTime);

  /// Parses [endTime] into a [DateTime], or `null` when missing/invalid.
  DateTime? get endDateTime => _parseIso(endTime);

  static DateTime? _parseIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toLocal();
  }

  /// Serialises the model back to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'scooter_id': scooterId,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        'cost': cost,
        'status': status,
        if (startLat != null) 'start_lat': startLat,
        if (startLng != null) 'start_lng': startLng,
        'rate_per_min': ratePerMin,
      };

  /// Returns a copy with the given fields replaced.
  RideModel copyWith({
    String? id,
    String? scooterId,
    String? startTime,
    String? endTime,
    int? cost,
    String? status,
    double? startLat,
    double? startLng,
    int? ratePerMin,
  }) {
    return RideModel(
      id: id ?? this.id,
      scooterId: scooterId ?? this.scooterId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      cost: cost ?? this.cost,
      status: status ?? this.status,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      ratePerMin: ratePerMin ?? this.ratePerMin,
    );
  }

  @override
  String toString() =>
      'RideModel(id: $id, scooter: $scooterId, status: $status, cost: $cost)';
}
