import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';

/// Уведомления — экран входящих уведомлений с табами «Все / Непрочитанные».
///
/// Стиль референса: белый фон, AppBar с кнопкой «назад» и заголовком
/// «Уведомления», пилюля-переключатель фильтров сверху, список карточек
/// (белый фон, 8px скругление, padding 16, заголовок 16px Medium +
/// текст 14px серый + время 12px приглушённый), и пустое состояние
/// «Нет уведомлений».
///
/// Бизнес-логика, провайдеры и состояние сохранены без изменений — переписан
/// только UI (build-метод и приватные виджеты-секции).
class NotificationsScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Уведомления',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Отметить все прочитанными',
            icon: const Icon(Icons.done_all,
                color: AppColors.textPrimary, size: 22),
            onPressed: state.unreadCount == 0
                ? null
                : () => ref.read(notificationProvider.notifier).markAllRead(),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterTabs(state: state),
          Expanded(
            child: _Body(
              state: state,
              onRefresh: () => ref.read(notificationProvider.notifier).load(),
              onMarkRead: (id) =>
                  ref.read(notificationProvider.notifier).markAsRead(id),
              onRetry: () => ref.read(notificationProvider.notifier).load(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Пилюльные табы «Все / Непрочитанные».
class _FilterTabs extends ConsumerWidget {
  const _FilterTabs({required this.state});

  final NotificationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppStyles.spaceLg, AppStyles.spaceSm, AppStyles.spaceLg, AppStyles.spaceSm),
      child: Row(
        children: [
          _PillTab(
            label: 'Все',
            count: state.notifications.length,
            selected: state.filter == NotificationFilter.all,
            onTap: () => ref
                .read(notificationProvider.notifier)
                .setFilter(NotificationFilter.all),
          ),
          const SizedBox(width: AppStyles.spaceSm),
          _PillTab(
            label: 'Непрочитанные',
            count: state.unreadCount,
            selected: state.filter == NotificationFilter.unread,
            onTap: () => ref
                .read(notificationProvider.notifier)
                .setFilter(NotificationFilter.unread),
          ),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppStyles.spaceLg, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      selected ? Colors.white : AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Тело экрана: loading / error / empty / list.
class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.onRefresh,
    required this.onMarkRead,
    required this.onRetry,
  });

  final NotificationState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String id) onMarkRead;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.notifications.isEmpty) {
      return _ErrorView(message: state.error!, onRetry: onRetry);
    }
    if (state.filtered.isEmpty) {
      return const _EmptyView();
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppStyles.spaceLg, AppStyles.spaceSm, AppStyles.spaceLg, 24),
        itemCount: state.filtered.length,
        itemBuilder: (_, i) {
          final n = state.filtered[i];
          return _NotificationCard(
            notification: n,
            onTap: () {
              if (!n.read) onMarkRead(n.id);
            },
          );
        },
      ),
    );
  }
}

/// Карточка уведомления — белый фон, 8px скругление, padding 16,
/// заголовок 16px Medium + текст 14px серый + время 12px приглушённый.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  String _formatRelative(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} д назад';
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${t.day} ${months[t.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;
    final color = notification.type.color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spaceSm),
      padding: const EdgeInsets.all(AppStyles.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        border: Border.all(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppStyles.radiusSm),
              ),
              child: Icon(notification.type.icon, color: color, size: 18),
            ),
            const SizedBox(width: AppStyles.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: AppStyles.spaceSm),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatRelative(notification.time),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Пустое состояние — «Нет уведомлений» по центру.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: AppColors.textMuted,
          ),
          SizedBox(height: AppStyles.spaceLg),
          Text(
            'Нет уведомлений',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: AppStyles.spaceSm),
          Text(
            'Здесь появятся важные оповещения о поездках и акциях',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

/// Состояние ошибки.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: AppStyles.spaceMd),
            const Text(
              'Не удалось загрузить уведомления',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spaceSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: AppStyles.spaceLg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
