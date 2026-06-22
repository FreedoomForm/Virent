import '../../../../core/configs/services/api_client.dart';
import '../models/notification_model.dart';

/// Repository that fetches and mutates the user's notification inbox.
///
/// Wraps the `/notifications` REST endpoints. Returns typed
/// [AppNotification] objects so the Riverpod layer never has to touch raw
/// JSON. The repository is intentionally stateless — all read/unread state
/// lives on the server.
class NotificationRepository {
  /// Creates a repository backed by [api] (or a fresh [ApiClient]).
  NotificationRepository([ApiClient? api]) : _api = api ?? ApiClient();

  final ApiClient _api;

  /// Fetches the inbox, most-recent first.
  Future<List<AppNotification>> getNotifications() async {
    final data = await _api.get('/notifications');
    final list = (data['notifications'] as List? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
    // Sort newest first when the server doesn't already.
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  /// Marks a single notification as read.
  Future<void> markAsRead(String notificationId) =>
      _api.post('/notifications/$notificationId/read', <String, dynamic>{});

  /// Marks every notification in the inbox as read.
  Future<void> markAllRead() =>
      _api.post('/notifications/mark-all-read', <String, dynamic>{});
}
