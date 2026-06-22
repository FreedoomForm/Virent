// admin_home_screen.dart — mobile-adapted admin dashboard.
//
// Replaces the regular rider home screen when an admin signs in on a phone.
// Renders the same sixteen admin modules the desktop dashboard exposes, but
// laid out as a 3-column (mobile) / 4-column (tablet) / 5-column (desktop)
// grid of tappable shortcut tiles. Each tile pushes the corresponding admin
// screen onto the navigator stack.
//
// Layout:
//   ┌──────────────────────────────────────────────┐
//   │  AppBar:  [avatar] Virent Admin    [logout]  │
//   │          <admin name> · <role>               │
//   ├──────────────────────────────────────────────┤
//   │  Greeting card with quick stats              │
//   ├──────────────────────────────────────────────┤
//   │  ▦ ▦ ▦  Admin shortcut grid (16 modules)     │
//   │  ▦ ▦ ▦                                        │
//   │  ▦ ▦ ▦                                        │
//   ├──────────────────────────────────────────────┤
//   │  Bottom nav: Home · Stats · Alerts · Settings│
//   └──────────────────────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../data/models/admin_user_model.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_provider.dart' show adminStatsProvider;
import '../widgets/admin_shortcut_grid.dart';

/// Index of the bottom-nav tab. Kept at file scope so the state survives
/// hot-reload during development.
final _adminHomeNavIndexProvider = StateProvider<int>((ref) => 0);

/// Mobile-adapted admin home screen.
///
/// Shown when the authenticated user holds an admin role. Tapping a shortcut
/// tile pushes the corresponding admin screen onto the stack — the screen
/// itself is identical to the desktop variant, only the entry point differs.
class AdminHomeScreen extends ConsumerStatefulWidget {
  /// Creates the [AdminHomeScreen].
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  /// Ensures [AdminAuthNotifier.restoreSession] is only called once per
  /// widget instance — guards against re-entrancy during rebuilds.
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    // Defer to next frame so [ref] is available inside didChangeDependencies.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_restored) {
        _restored = true;
        ref.read(adminAuthNotifierProvider.notifier).restoreSession();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(currentAdminProvider);
    final navIndex = ref.watch(_adminHomeNavIndexProvider);
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgAlt,
      appBar: _AdminHomeAppBar(admin: admin),
      body: IndexedStack(
        index: navIndex,
        children: [
          _AdminHomeBody(admin: admin, statsAsync: statsAsync),
          _StatsTab(statsAsync: statsAsync),
          const _AlertsTab(),
          _SettingsTab(admin: admin),
        ],
      ),
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: navIndex,
        onTap: (i) =>
            ref.read(_adminHomeNavIndexProvider.notifier).state = i,
      ),
    );
  }
}

/// Top bar — avatar with admin initials, "Virent Admin" title, admin name +
/// role subtitle, logout action.
class _AdminHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AdminHomeAppBar({required this.admin});

  final AdminUser? admin;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 12,
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              admin?.initials ?? '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Virent Admin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (admin != null)
                  Text(
                    '${admin!.name} · ${admin!.role.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout, size: 22),
          onPressed: () => _confirmLogout(context),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('End your admin session and return to the login '
            'screen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await container.read(adminAuthNotifierProvider.notifier).logout();
    if (context.mounted) {
      context.go('/auth');
    }
  }
}

/// Main scrollable body — greeting + quick stats + shortcut grid.
class _AdminHomeBody extends ConsumerWidget {
  const _AdminHomeBody({required this.admin, required this.statsAsync});

  final AdminUser? admin;
  final AsyncValue<Map<String, dynamic>> statsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminStatsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppStyles.spacing,
          AppStyles.spacing,
          AppStyles.spacing,
          24,
        ),
        children: [
          _GreetingCard(admin: admin),
          const SizedBox(height: AppStyles.spacing),
          _QuickStatsRow(statsAsync: statsAsync, theme: theme),
          const SizedBox(height: AppStyles.spacing),
          Text(
            'Modules',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          AdminShortcutGrid(items: _moduleShortcuts),
          const SizedBox(height: AppStyles.spacing),
          if (admin?.isSuperAdmin ?? false) ...[
            _ManageAdminsCard(theme: theme),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  /// The admin modules exposed by the home grid. Each route now points to
  /// the unified /admin/web panel (the only admin UI). The old per-screen
  /// routes have been removed.
  List<AdminShortcut> get _moduleShortcuts => const [
        AdminShortcut(
            icon: Icons.web_outlined,
            label: 'Веб-панель',
            route: '/admin/web',
            color: AppColors.primary),
        AdminShortcut(
            icon: Icons.dashboard_outlined,
            label: 'Дашборд',
            route: '/admin/web',
            color: AppColors.primary),
        AdminShortcut(
            icon: Icons.electric_scooter,
            label: 'Самокаты',
            route: '/admin/web',
            color: AppColors.info),
        AdminShortcut(
            icon: Icons.route_outlined,
            label: 'Поездки',
            route: '/admin/web',
            color: AppColors.success),
        AdminShortcut(
            icon: Icons.people_outline,
            label: 'Клиенты',
            route: '/admin/web',
            color: AppColors.warning),
        AdminShortcut(
            icon: Icons.location_city,
            label: 'Города',
            route: '/admin/web',
            color: AppColors.textSecondary),
        AdminShortcut(
            icon: Icons.crop_free,
            label: 'Зоны',
            route: '/admin/web',
            color: AppColors.primary),
        AdminShortcut(
            icon: Icons.sensors,
            label: 'IoT',
            route: '/admin/web',
            color: AppColors.info),
        AdminShortcut(
            icon: Icons.bar_chart,
            label: 'Аналитика',
            route: '/admin/web',
            color: AppColors.warning),
        AdminShortcut(
            icon: Icons.receipt_long,
            label: 'Аудит',
            route: '/admin/web',
            color: AppColors.textSecondary),
        AdminShortcut(
            icon: Icons.card_giftcard,
            label: 'Предоплаченные',
            route: '/admin/web',
            color: AppColors.success),
        AdminShortcut(
            icon: Icons.bolt,
            label: 'Джусеры',
            route: '/admin/web',
            color: AppColors.warning),
        AdminShortcut(
            icon: Icons.support_agent,
            label: 'Поддержка',
            route: '/admin/web',
            color: AppColors.primary),
        AdminShortcut(
            icon: Icons.notifications_active,
            label: 'Push',
            route: '/admin/web',
            color: AppColors.danger),
        AdminShortcut(
            icon: Icons.sms,
            label: 'SMS-шлюз',
            route: '/admin/web',
            color: AppColors.danger),
        AdminShortcut(
            icon: Icons.dns_outlined,
            label: 'Сервер',
            route: '/admin/web',
            color: AppColors.info),
        AdminShortcut(
            icon: Icons.list_alt,
            label: 'Логи',
            route: '/admin/web',
            color: AppColors.textSecondary),
      ];
}

/// Top greeting card — personalised welcome + last login timestamp.
class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.admin});

  final AdminUser? admin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryHover],
        ),
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  admin?.name ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14, color: Colors.white.withValues(alpha: 0.85)),
                    const SizedBox(width: 4),
                    Text(
                      admin?.role.label ?? 'Operator',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

/// Compact 4-up stat row shown above the module grid.
class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.statsAsync, required this.theme});

  final AsyncValue<Map<String, dynamic>> statsAsync;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const SizedBox(
        height: 84,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox(height: 84),
      data: (stats) => Row(
        children: [
          _StatChip(
            label: 'Scooters',
            value: '${stats['total_scooters'] ?? 0}',
            icon: Icons.electric_scooter,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Available',
            value: '${stats['available_scooters'] ?? 0}',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Users',
            value: '${stats['total_users'] ?? 0}',
            icon: Icons.people_outline,
            color: AppColors.info,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Revenue',
            value: '${stats['revenue'] ?? 0}',
            icon: Icons.payments,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

/// A single compact stat chip used by [_QuickStatsRow].
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card shown only to super admins — shortcut to the manage-admins screen.
class _ManageAdminsCard extends StatelessWidget {
  const _ManageAdminsCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      child: InkWell(
        onTap: () => context.push('/admin/manage-admins'),
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.manage_accounts,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Admins',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Create, delete and edit permissions for admin accounts.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom nav — admin-specific tabs (Home · Stats · Alerts · Settings).
class _AdminBottomNav extends StatelessWidget {
  _AdminBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primaryLight,
      height: 64,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Stats',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none_outlined),
          selectedIcon: Icon(Icons.notifications_active),
          label: 'Alerts',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

/// Stats tab — full-width KPI grid (a re-arrangement of the dashboard cards).
class _StatsTab extends ConsumerWidget {
  const _StatsTab({required this.statsAsync});

  final AsyncValue<Map<String, dynamic>> statsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('Could not load stats'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(adminStatsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (stats) => GridView.count(
        padding: const EdgeInsets.all(AppStyles.spacing),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _BigStatCard(
            label: 'Total Scooters',
            value: '${stats['total_scooters'] ?? 0}',
            icon: Icons.electric_scooter,
            color: AppColors.primary,
          ),
          _BigStatCard(
            label: 'Available',
            value: '${stats['available_scooters'] ?? 0}',
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
          _BigStatCard(
            label: 'Total Users',
            value: '${stats['total_users'] ?? 0}',
            icon: Icons.people,
            color: AppColors.info,
          ),
          _BigStatCard(
            label: 'Trips Today',
            value: '${stats['total_trips'] ?? 0}',
            icon: Icons.route,
            color: AppColors.warning,
          ),
          _BigStatCard(
            label: 'Active Trips',
            value: '${stats['active_trips'] ?? 0}',
            icon: Icons.play_arrow,
            color: AppColors.primary,
          ),
          _BigStatCard(
            label: 'Revenue (UZS)',
            value: '${stats['revenue'] ?? 0}',
            icon: Icons.payments,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  const _BigStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alerts tab — placeholder list of recent audit / IoT alerts.
class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alerts = <_AlertItem>[
      _AlertItem(
        icon: Icons.battery_alert,
        color: AppColors.danger,
        title: 'Low battery',
        body: 'Virent#3 dropped to 45% — schedule a juicer pickup.',
        time: '2m ago',
      ),
      _AlertItem(
        icon: Icons.lock_open,
        color: AppColors.warning,
        title: 'Forced unlock',
        body: 'Virent#2 reported an unlock without a reservation.',
        time: '14m ago',
      ),
      _AlertItem(
        icon: Icons.block,
        color: AppColors.danger,
        title: 'User blocked',
        body: 'A rider was blocked for repeated no-payment trips.',
        time: '1h ago',
      ),
      _AlertItem(
        icon: Icons.dns,
        color: AppColors.success,
        title: 'Server restarted',
        body: 'Embedded server came back up after a config change.',
        time: '3h ago',
      ),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(AppStyles.spacing),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = alerts[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(a.icon, color: a.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.title,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          a.time,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.body,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlertItem {
  const _AlertItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
}

/// Settings tab — links to the full Settings screen plus admin-only quick
/// toggles (admin-mode lock, manage admins).
class _SettingsTab extends ConsumerWidget {
  const _SettingsTab({required this.admin});

  final AdminUser? admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppStyles.spacing),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  admin?.initials ?? '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin?.name ?? 'Admin',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      admin?.email ?? '',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  admin?.role.label ?? 'Operator',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SettingsLink(
          icon: Icons.settings,
          label: 'App Settings',
          subtitle: 'Server URL, theme, language',
          onTap: () => context.push('/settings'),
        ),
        if (admin?.isSuperAdmin ?? false)
          _SettingsLink(
            icon: Icons.manage_accounts,
            label: 'Manage Admins',
            subtitle: 'Create, delete, edit permissions',
            onTap: () => context.push('/admin/manage-admins'),
          ),
        _SettingsLink(
          icon: Icons.receipt_long,
          label: 'Audit Log',
          subtitle: 'Every admin action, filterable',
          onTap: () => context.push('/admin/audit-log'),
        ),
        _SettingsLink(
          icon: Icons.list_alt,
          label: 'Server Logs',
          subtitle: 'Live tail of the embedded server',
          onTap: () => context.push('/admin/logs'),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () async {
            await ref.read(adminAuthNotifierProvider.notifier).logout();
            if (context.mounted) context.go('/auth');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
