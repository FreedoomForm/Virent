// header.dart — Admin panel top bar.
//
// Shows the ViRent brand, hamburger menu, status badges, and a clickable
// profile section that opens a dropdown menu with:
//   - "Перейти в тестовый режим"        → AdminMode.test
//   - "Перейти в режим клиента"         → AdminMode.client
//   - "Перейти в тестовый режим клиента" → AdminMode.testClient
//   - "Выйти"                            → navigates to /auth
//
// The dropdown is implemented with [PopupMenuButton] (Flutter's built-in
// Material dropdown). Selecting a mode updates [adminModeProvider]; the
// layout in `app_layout.dart` reacts by showing the orange test banner
// and/or overlaying the mobile client UI.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';

/// Items shown in the profile dropdown menu.
enum _ProfileMenu {
  logout,
  testMode,
  clientMode,
  testClientMode,
}

class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(adminModeProvider);
    return Container(
      height: 30,
      color: const Color(0xFF1B2A4E),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text(
            'ViRent',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => showAdminInfoDialog(
                context, 'Информация', 'Действие в разработке'),
            child: const Icon(Icons.menu, color: Colors.white70, size: 16),
          ),
          const Spacer(),
          _buildTag('Разблокирован: 0', const Color(0xFF467FD0)),
          _buildTag('Разряжены: 7', const Color(0xFFFFC107),
              textColor: Colors.black87),
          _buildTag('Не в сети: 9', const Color(0xFFD9E2EF),
              textColor: Colors.black87),
          _buildTag('Выезд из зоны: 0', const Color(0xFF7C69EF)),
          _buildTag('Не включился: 1', const Color(0xFFDF4759)),
          const SizedBox(width: 12),
          _buildProfileMenu(context, ref, mode),
        ],
      ),
    );
  }

  /// Builds the clickable avatar + name + dropdown caret that opens the
  /// [PopupMenuButton]. The avatar colour and the bottom label change to
  /// reflect the current [AdminMode].
  Widget _buildProfileMenu(
      BuildContext context, WidgetRef ref, AdminMode mode) {
    final bool isTest = mode == AdminMode.test || mode == AdminMode.testClient;
    final Color avatarColor =
        isTest ? Colors.deepOrangeAccent : Colors.amber;
    final String subtitle = mode == AdminMode.normal
        ? 'Асилбек'
        : mode == AdminMode.test
            ? 'ТЕСТ'
            : mode == AdminMode.client
                ? 'Клиент'
                : 'ТЕСТ-Клиент';
    final Color subtitleColor =
        mode == AdminMode.normal ? Colors.white70 : Colors.deepOrangeAccent;

    return PopupMenuButton<_ProfileMenu>(
      tooltip: 'Меню профиля',
      offset: const Offset(0, 30),
      color: const Color(0xFF1B2A4E),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: avatarColor,
              child: const Icon(Icons.person, size: 12, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('ViRent',
                    style: TextStyle(color: Colors.white70, fontSize: 9)),
                const Text('Шерзод',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 14),
          ],
        ),
      ),
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: _ProfileMenu.testMode,
          child: Row(children: [
            Icon(Icons.science_outlined, size: 16, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Перейти в тестовый режим',
                style: TextStyle(color: Colors.white)),
          ]),
        ),
        const PopupMenuItem(
          value: _ProfileMenu.clientMode,
          child: Row(children: [
            Icon(Icons.phone_android, size: 16, color: Colors.lightBlueAccent),
            SizedBox(width: 8),
            Text('Перейти в режим клиента',
                style: TextStyle(color: Colors.white)),
          ]),
        ),
        const PopupMenuItem(
          value: _ProfileMenu.testClientMode,
          child: Row(children: [
            Icon(Icons.phone_android_outlined,
                size: 16, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Перейти в тестовый режим клиента',
                style: TextStyle(color: Colors.white)),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _ProfileMenu.logout,
          child: Row(children: [
            Icon(Icons.logout, size: 16, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Выйти', style: TextStyle(color: Colors.redAccent)),
          ]),
        ),
      ],
      onSelected: (value) => _handleMenuSelection(context, ref, value),
    );
  }

  /// Dispatches the selected menu item. Logout resets the mode and pushes
  /// the `/auth` route; the three mode entries set [adminModeProvider] and
  /// show a confirmation SnackBar.
  void _handleMenuSelection(
      BuildContext context, WidgetRef ref, _ProfileMenu value) {
    switch (value) {
      case _ProfileMenu.logout:
        ref.read(adminModeProvider.notifier).state = AdminMode.normal;
        context.go('/auth');
        break;
      case _ProfileMenu.testMode:
        ref.read(adminModeProvider.notifier).state = AdminMode.test;
        showAdminSnack(context, 'Включён тестовый режим');
        break;
      case _ProfileMenu.clientMode:
        ref.read(adminModeProvider.notifier).state = AdminMode.client;
        showAdminSnack(context, 'Включён режим клиента');
        break;
      case _ProfileMenu.testClientMode:
        ref.read(adminModeProvider.notifier).state = AdminMode.testClient;
        showAdminSnack(context, 'Включён тестовый режим клиента');
        break;
    }
  }

  Widget _buildTag(String label, Color color,
      {Color textColor = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
