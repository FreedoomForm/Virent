import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: ListView(
        children: [
          _buildSidebarItem(context, 0, Icons.dashboard, 'Дашборд'),
          _buildSidebarItem(context, 1, Icons.show_chart, 'Статистика'),
          _buildSidebarItem(context, 2, Icons.notifications, 'Тревоги'),
          _buildSidebarItem(context, 3, Icons.map, 'Карта', isExpandable: true),
          _buildSidebarItem(context, 4, Icons.electric_scooter, 'Самокаты'),
          _buildSidebarItem(context, 5, Icons.people, 'Клиенты', isExpandable: true),
          _buildSidebarItem(context, 6, Icons.receipt, 'Заказы', isExpandable: true),
          _buildSidebarItem(context, 7, Icons.camera_alt, 'Селфи'),
          _buildSidebarItem(context, 8, Icons.search, 'Осмотр'),
          _buildSidebarItem(context, 9, Icons.payment, 'Биллинг', isExpandable: true),
          _buildSidebarItem(context, 10, Icons.local_offer, 'Промо', isExpandable: true),
          _buildSidebarItem(context, 11, Icons.card_giftcard, 'Бонусы', isExpandable: true),
          _buildSidebarItem(context, 12, Icons.money, 'Тарифы', isExpandable: true),
          _buildSidebarItem(context, 13, Icons.article, 'Логи', isExpandable: true),
          _buildSidebarItem(context, 14, Icons.admin_panel_settings, 'Администратор', isExpandable: true),
          _buildSidebarItem(context, 15, Icons.engineering, 'Техники', isExpandable: true),
          _buildSidebarItem(context, 16, Icons.place, 'Геозоны', isExpandable: true),
          _buildSidebarItem(context, 17, Icons.settings, 'Настройки', isExpandable: true),
          _buildSidebarItem(context, 18, Icons.chat, 'Чат', isExpandable: true),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    int index,
    IconData icon,
    String title, {
    bool isExpandable = false,
  }) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        color: isSelected ? const Color(0xFFF3F4F6) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey[600], size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isExpandable)
              Icon(Icons.keyboard_arrow_right, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }
}
