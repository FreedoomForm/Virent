import '../../../../core/configs/services/api_client.dart';

/// Admin repository — talks to the Virent embedded server's admin endpoints.
///
/// All admin operations (fleet stats, scooter management, zones, IoT commands,
/// user blocking, refunds, audit log, push notifications) are funnelled
/// through this class so the presentation layer only depends on a single
/// data source. Each method maps 1:1 to a server route and returns decoded
/// JSON (or a typed list) so Riverpod providers can transform it further.
///
/// The repository is constructed with the shared [ApiClient] (which handles
/// the platform-specific base URL and bearer-token injection), keeping admin
/// calls authenticated once the user logs in.
class AdminRepository {
  /// Creates an [AdminRepository] backed by [api] (or a fresh [ApiClient]).
  AdminRepository([ApiClient? api]) : _api = api ?? ApiClient();

  final ApiClient _api;

  // ---- Fleet stats --------------------------------------------------------

  /// Fetches aggregate fleet stats (scooter counts, active users, revenue,
  /// trips today, etc.).
  Future<Map<String, dynamic>> getStats() => _api.get('/admin/stats');

  // ---- Scooters -----------------------------------------------------------

  /// Lists every scooter in the fleet regardless of status.
  Future<List<Map<String, dynamic>>> getScooters() async {
    final data = await _api.get('/admin/scooters');
    final list = data['scooters'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  // ---- Zones --------------------------------------------------------------

  /// Lists every geofenced zone (parking, no-ride, slow, charging).
  Future<List<Map<String, dynamic>>> getZones() async {
    final data = await _api.get('/zones');
    final list = data['zones'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Creates a new zone.
  ///
  /// [zone] should contain `name`, `type`, `speed_limit` and `vertices`
  /// (or a `polygon` array, depending on the server contract).
  Future<void> createZone(Map<String, dynamic> zone) =>
      _api.post('/zones', zone);

  /// Deletes a zone by its [zoneId].
  Future<void> deleteZone(String zoneId) => _api.delete('/zones/$zoneId');

  // ---- Users / customers --------------------------------------------------

  /// Lists every customer (paginated server-side).
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final data = await _api.get('/admin/customers');
    final list = data['customers'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Blocks a user account with a human-readable [reason].
  Future<void> blockUser(String userId, String reason) =>
      _api.post('/users/$userId/block', {'reason': reason});

  /// Unblocks a previously blocked user.
  Future<void> unblockUser(String userId) =>
      _api.post('/users/$userId/unblock', <String, dynamic>{});

  /// Adjusts a user's wallet balance by [amountDelta] (signed, in UZS) for
  /// the given [reason] (e.g. "manual credit", "chargeback").
  Future<void> adjustBalance(String userId, int amountDelta, String reason) =>
      _api.post('/admin/customers/$userId/adjust-balance', {
        'amount': amountDelta,
        'reason': reason,
      });

  // ---- Trips / refunds ----------------------------------------------------

  /// Refunds [amount] (in UZS) for [tripId] with the supplied [reason].
  Future<void> refundTrip(String tripId, int amount, String reason) =>
      _api.post('/trips/$tripId/refund', {
        'amount': amount,
        'reason': reason,
      });

  // ---- IoT ----------------------------------------------------------------

  /// Sends a raw IoT command (`lock`, `unlock`, `alarm_on`, `reboot`,
  /// `locate`, `led_on`, ...) to the scooter identified by [scooterMac].
  Future<void> sendIoTCommand(String scooterMac, String command) =>
      _api.post('/iot/command', {
        'scooter_mac': scooterMac,
        'command': command,
      });

  // ---- Audit log ----------------------------------------------------------

  /// Returns the most recent audit-log entries.
  ///
  /// Optional [filters] (e.g. `{'actor': 'admin@virent', 'action': 'block'}`)
  /// are forwarded as query parameters when present.
  Future<List<Map<String, dynamic>>> getAuditLog(
      [Map<String, String>? filters]) async {
    final query = filters == null || filters.isEmpty
        ? ''
        : '?${filters.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final data = await _api.get('/audit-log$query');
    final list = data['entries'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  // ---- Notifications ------------------------------------------------------

  /// Broadcasts a push notification to a segment of users.
  ///
  /// [audience] is one of `all`, `active`, `inactive`. [type] is the
  /// notification category (e.g. `promo`, `system`, `zone`).
  Future<void> sendNotification({
    required String title,
    required String body,
    String audience = 'all',
    String type = 'system',
  }) =>
      _api.post('/admin/notifications/broadcast', {
        'title': title,
        'body': body,
        'audience': audience,
        'type': type,
      });
}
