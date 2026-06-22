/// Domain entities for the rides feature.
///
/// These are pure Dart value objects describing *what* the rider wants to
/// do (start a ride, end a ride, fetch history) without any knowledge of
/// HTTP, JSON or storage. The data layer maps them to wire payloads; the
/// presentation layer maps them to UI state.

/// Input payload for starting a new ride.
///
/// Passed to [StartRideUseCase] and forwarded to the repository's
/// `startRide` method.
class StartRideRequest {
  /// The scooter the rider wants to unlock.
  final String scooterId;

  /// Optional starting latitude (overrides the server's geo lookup).
  final double? startLat;

  /// Optional starting longitude.
  final double? startLng;

  /// Creates a [StartRideRequest].
  const StartRideRequest({
    required this.scooterId,
    this.startLat,
    this.startLng,
  });

  /// Serialises the request to the wire format expected by `/trips/start`.
  Map<String, dynamic> toJson() => {
        'scooter_id': scooterId,
        if (startLat != null) 'start_lat': startLat,
        if (startLng != null) 'start_lng': startLng,
      };

  @override
  String toString() => 'StartRideRequest(scooterId: $scooterId)';
}

/// Input payload for ending an ongoing ride.
///
/// Passed to [EndRideUseCase]. The server computes the final cost from
/// the ride duration so callers do not need to send it.
class EndRideRequest {
  /// The ride to end.
  final String rideId;

  /// Optional ending latitude (used for parking validation).
  final double? endLat;

  /// Optional ending longitude.
  final double? endLng;

  /// Optional parking photo URL captured by the rider before ending.
  final String? parkingPhotoUrl;

  /// Creates an [EndRideRequest].
  const EndRideRequest({
    required this.rideId,
    this.endLat,
    this.endLng,
    this.parkingPhotoUrl,
  });

  /// Serialises the request to the wire format expected by `/trips/end`.
  Map<String, dynamic> toJson() => {
        'trip_id': rideId,
        if (endLat != null) 'end_lat': endLat,
        if (endLng != null) 'end_lng': endLng,
        if (parkingPhotoUrl != null) 'parking_photo': parkingPhotoUrl,
      };

  @override
  String toString() => 'EndRideRequest(rideId: $rideId)';
}

/// Filter parameters for fetching ride history.
class RideHistoryFilter {
  /// Maximum number of rides to return.
  final int limit;

  /// Number of rides to skip (for pagination).
  final int offset;

  /// Optional status filter (`ongoing`, `completed`, `cancelled`).
  final String? status;

  /// Creates a [RideHistoryFilter].
  const RideHistoryFilter({
    this.limit = 50,
    this.offset = 0,
    this.status,
  });

  /// Builds the query-string map for `/trips`.
  Map<String, String> toQuery() => {
        'limit': '$limit',
        'offset': '$offset',
        if (status != null) 'status': status!,
      };

  @override
  String toString() =>
      'RideHistoryFilter(limit: $limit, offset: $offset, status: $status)';
}
