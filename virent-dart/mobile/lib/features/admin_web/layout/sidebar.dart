import 'package:flutter/material.dart';

class SidebarItem {
  final int index;
  final IconData icon;
  final String title;
  final List<SidebarSubItem>? children;

  const SidebarItem({
    required this.index,
    required this.icon,
    required this.title,
    this.children,
  });
}

class SidebarSubItem {
  final int index;
  final String title;

  const SidebarSubItem({required this.index, required this.title});
}

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  int? _expandedIndex;

  static const List<SidebarItem> _items = [
    SidebarItem(index: 0, icon: Icons.dashboard_outlined, title: 'Дашборд'),
    SidebarItem(index: 1, icon: Icons.bar_chart_outlined, title: 'Статистика'),
    SidebarItem(index: 2, icon: Icons.notifications_none, title: 'Тревоги'),
    SidebarItem(index: 3, icon: Icons.map_outlined, title: 'Карта', children: [
      SidebarSubItem(index: 30, title: 'Карта'),
    ]),
    SidebarItem(index: 4, icon: Icons.electric_scooter, title: 'Самокаты', children: [
      SidebarSubItem(index: 4, title: 'Самокаты'),
    ]),
    SidebarItem(index: 5, icon: Icons.people_outline, title: 'Клиенты', children: [
      SidebarSubItem(index: 5, title: 'Клиенты'),
    ]),
    SidebarItem(index: 6, icon: Icons.receipt_long_outlined, title: 'Заказы', children: [
      SidebarSubItem(index: 6, title: 'Предоплаченные'),
    ]),
    SidebarItem(index: 7, icon: Icons.camera_alt_outlined, title: 'Селфи'),
    SidebarItem(index: 8, icon: Icons.search, title: 'Осмотр'),
    SidebarItem(index: 9, icon: Icons.account_balance_wallet_outlined, title: 'Биллинг', children: [
      SidebarSubItem(index: 9, title: 'Долги'),
      SidebarSubItem(index: 90, title: 'Штрафы'),
      SidebarSubItem(index: 92, title: 'Счета'),
      SidebarSubItem(index: 93, title: 'Банковские карты'),
      SidebarSubItem(index: 91, title: 'Квитанции'),
      SidebarSubItem(index: 100, title: 'Транзакции Payme'),
      SidebarSubItem(index: 101, title: 'Транзакции CLICK'),
    ]),
    SidebarItem(index: 10, icon: Icons.local_offer_outlined, title: 'Промо', children: [
      SidebarSubItem(index: 10, title: 'Промокоды'),
      SidebarSubItem(index: 111, title: 'Серии промокодов'),
    ]),
    SidebarItem(index: 11, icon: Icons.card_giftcard_outlined, title: 'Бонусы', children: [
      SidebarSubItem(index: 11, title: 'Бонусы'),
      SidebarSubItem(index: 110, title: 'Пакеты бонусов'),
      SidebarSubItem(index: 112, title: 'Логи(Hold Logs)'), // reusing index 13 for Hold Logs later
    ]),
    SidebarItem(index: 12, icon: Icons.monetization_on_outlined, title: 'Тарифы', children: [
      SidebarSubItem(index: 120, title: 'Тарифы'),
      SidebarSubItem(index: 121, title: 'Цены'),
      SidebarSubItem(index: 12, title: 'Абонементы'),
      SidebarSubItem(index: 122, title: 'Тариф подписка'),
      SidebarSubItem(index: 123, title: 'Тариф пока не сядет'),
    ]),
    SidebarItem(index: 13, icon: Icons.article_outlined, title: 'Логи', children: [
      SidebarSubItem(index: 130, title: 'Телеметрия'),
      SidebarSubItem(index: 131, title: 'История действий'),
      SidebarSubItem(index: 20, title: 'Логи авторизации'),
      SidebarSubItem(index: 133, title: 'Неподтвержденные'),
      SidebarSubItem(index: 134, title: 'Логи платежей'),
      SidebarSubItem(index: 136, title: 'Логи изменения самоката'),
      SidebarSubItem(index: 137, title: 'Логи изменения клиента'),
    ]),
    SidebarItem(index: 14, icon: Icons.admin_panel_settings_outlined, title: 'Администратор', children: [
      SidebarSubItem(index: 14, title: 'Учетные записи'),
      SidebarSubItem(index: 141, title: 'Роли'),
      SidebarSubItem(index: 142, title: 'Договора и соглашения'),
      SidebarSubItem(index: 140, title: 'Разрешения'),
      SidebarSubItem(index: 144, title: 'F.A.Q.'),
      SidebarSubItem(index: 145, title: 'Компании'),
      SidebarSubItem(index: 147, title: 'Контакты'),
    ]),
    SidebarItem(index: 15, icon: Icons.build_outlined, title: 'Техники', children: [
      SidebarSubItem(index: 15, title: 'Техники'),
      SidebarSubItem(index: 151, title: 'Задачи техников'),
      SidebarSubItem(index: 152, title: 'sidebar.raidermodelog'),
      SidebarSubItem(index: 153, title: 'Фидбек'),
    ]),
    SidebarItem(index: 16, icon: Icons.place_outlined, title: 'Геозоны', children: [
      SidebarSubItem(index: 160, title: 'Геоточки'),
      SidebarSubItem(index: 161, title: 'Группы геозон'),
      SidebarSubItem(index: 162, title: 'Разр.Использование'),
      SidebarSubItem(index: 163, title: 'Завершение аренды'),
      SidebarSubItem(index: 164, title: 'Запрет движения'),
      SidebarSubItem(index: 165, title: 'Ограничение движения'),
      SidebarSubItem(index: 166, title: 'Зона запрета завершения'),
      SidebarSubItem(index: 167, title: 'Архив'),
    ]),
    SidebarItem(index: 17, icon: Icons.settings_outlined, title: 'Настройки', children: [
      SidebarSubItem(index: 172, title: 'Группы самокатов'),
      SidebarSubItem(index: 17, title: 'Группы клиентов'),
      SidebarSubItem(index: 173, title: 'Драйверы'),
      SidebarSubItem(index: 174, title: 'Тарирование'),
      SidebarSubItem(index: 175, title: 'Модели'),
      SidebarSubItem(index: 170, title: 'Уведомления'),
      SidebarSubItem(index: 171, title: 'Конфиг'),
    ]),
    SidebarItem(index: 18, icon: Icons.chat_bubble_outline, title: 'Чат', children: [
      SidebarSubItem(index: 18, title: 'Чат'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: _items.map((item) => _buildItem(item)).toList(),
      ),
    );
  }

  Widget _buildItem(SidebarItem item) {
    final bool isExpanded = _expandedIndex == item.index;
    final bool hasChildren = item.children != null && item.children!.isNotEmpty;
    final bool isSelected = widget.selectedIndex == item.index && !hasChildren;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (hasChildren) {
              setState(() {
                _expandedIndex = isExpanded ? null : item.index;
              });
            } else {
              widget.onItemSelected(item.index);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: isSelected ? const Color(0xFFFFF3E0) : Colors.transparent,
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: isSelected ? const Color(0xFFE67E22) : const Color(0xFF555555)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? const Color(0xFFE67E22) : const Color(0xFF333333),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (hasChildren)
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 16,
                    color: Colors.grey[500],
                  ),
              ],
            ),
          ),
        ),
        if (hasChildren && isExpanded)
          ...item.children!.map((sub) {
            final bool subSelected = widget.selectedIndex == sub.index;
            return InkWell(
              onTap: () => widget.onItemSelected(sub.index),
              child: Container(
                padding: const EdgeInsets.only(left: 40, right: 12, top: 8, bottom: 8),
                color: subSelected ? const Color(0xFFFFF3E0) : Colors.transparent,
                child: Text(
                  sub.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: subSelected ? const Color(0xFFE67E22) : const Color(0xFF666666),
                    fontWeight: subSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
