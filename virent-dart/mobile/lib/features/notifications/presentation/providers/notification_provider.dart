import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show apiClientProvider;
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

/// Singleton [NotificationRepository].
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiClientProvider));
});

/// Filter applied to the inbox view.
enum NotificationFilter {
  /// Show every notification.
  all,

  /// Show only unread notifications.
  unread,
}

/// Immutable state held by [NotificationNotifier].
class NotificationState {
  /// Creates the state.
  const NotificationState({
    this.notifications = const <AppNotification>[],
    this.filter = NotificationFilter.all,
    this.loading = false,
    this.error,
  });

  /// Full inbox (unfiltered).
  final List<AppNotification> notifications;

  /// Currently selected filter.
  final NotificationFilter filter;

  /// Whether a fetch / mutation is in flight.
  final bool loading;

  /// Last error message, if any.
  final String? error;

  /// Notifications after the active filter is applied.
  List<AppNotification> get filtered => filter == NotificationFilter.unread
      ? notifications.where((n) => !n.read).toList()
      : notifications;

  /// Count of unread notifications (used by the bell badge).
  int get unreadCount => notifications.where((n) => !n.read).length;

  /// Returns a copy with the supplied fields replaced.
  NotificationState copyWith({
    List<AppNotification>? notifications,
    NotificationFilter? filter,
    bool? loading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// Notifier that owns the inbox state.
class NotificationNotifier extends StateNotifier<NotificationState> {
  /// Creates the notifier, wired to [repo].
  NotificationNotifier(this._repo) : super(const NotificationState());

  final NotificationRepository _repo;

  /// Loads the inbox from the server.
  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final list = await _repo.getNotifications();
      state = state.copyWith(notifications: list, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Switches the active filter.
  void setFilter(NotificationFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// Marks [notificationId] as read both locally and on the server.
  Future<void> markAsRead(String notificationId) async {
    // Optimistic update.
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == notificationId ? n.copyWith(read: true) : n)
          .toList(),
    );
    try {
      await _repo.markAsRead(notificationId);
    } catch (_) {
      // Revert on failure.
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => n.id == notificationId ? n.copyWith(read: false) : n)
            .toList(),
      );
    }
  }

  /// Marks every notification as read.
  Future<void> markAllRead() async {
    final previous = state.notifications;
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(read: true))
          .toList(),
    );
    try {
      await _repo.markAllRead();
    } catch (_) {
      state = state.copyWith(notifications: previous);
    }
  }
}

/// Main provider for the notification feature.
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.read(notificationRepositoryProvider));
});

/// Convenience selector for the unread-count badge.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
