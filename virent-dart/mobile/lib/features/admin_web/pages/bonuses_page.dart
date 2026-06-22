import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class BonusesPage extends ConsumerWidget {
  const BonusesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Бонусы',
      provider: bonusesListProvider,
      searchProvider: _bonusSearchProvider,
      createButton: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => showAdminFormDialog(
              context,
              title: 'Добавить бонус',
              fields: const [
                AdminField(key: 'name', label: 'Название'),
                AdminField(key: 'sum', label: 'Сумма'),
                AdminField(key: 'user_id', label: 'ID пользователя'),
                AdminField(key: 'type', label: 'Тип'),
              ],
              onSubmit: (values) async {
                await ref.read(genericCreateAction)(
                  '/admin/bonuses',
                  values,
                  bonusesListProvider,
                );
              },
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Добавить бонусы'),
            style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'ID клиента'),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => showAdminInfoDialog(context, 'Компания', 'Выберите компанию для фильтрации'),
            style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
            child: const Text('Компания ▼'),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Название')),
        DataColumn(label: Text('Сумма')),
        DataColumn(label: Text('Пользователь')),
        DataColumn(label: Text('Тип')),
        DataColumn(label: Text('Дата')),
      ],
      buildRow: (b) {
        final id = (b['id'] ?? '-').toString();
        final name = (b['name'] ?? b['comment'] ?? b['title'] ?? '-').toString();
        final sum = (b['sum'] ?? b['amount'] ?? b['bonus_sum'] ?? '-').toString();
        final user = (b['user_id'] ?? b['client_id'] ?? b['client_name'] ?? '-').toString();
        final type = (b['type'] ?? b['bonus_type'] ?? '-').toString();
        final date = (b['created_at'] ?? b['create_time'] ?? b['date'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name)),
          DataCell(Text(sum)),
          DataCell(Text(user, style: adminLinkStyle)),
          DataCell(Text(type)),
          DataCell(Text(date)),
        ]);
      },
    );
  }
}

final _bonusSearchProvider = StateProvider<String>((ref) => '');
