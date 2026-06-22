import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class TariffsSubscriptionsPage extends ConsumerWidget {
  const TariffsSubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Абонементы',
      provider: tariffsSubscriptionsProvider,
      searchProvider: _subSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminInfoDialog(
          context, 'Добавить абонемент', 'Форма создания абонемента',
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить абонемент'),
        style: ElevatedButton.styleFrom(
          backgroundColor: adminPrimaryColor,
          foregroundColor: adminPrimaryForeground,
        ),
      ),
      columns: const [
        DataColumn(label: Text('Tariff')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Overrun price')),
        DataColumn(label: Text('Cost')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (t) {
        final tariff = (t['tariff'] ?? t['name'] ?? '-').toString();
        final desc = (t['description'] ?? t['desc'] ?? '-').toString();
        final overrun = (t['overrun_price'] ?? t['overrun'] ?? '-').toString();
        final cost = (t['cost'] ?? t['price'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(tariff, style: adminLinkStyle)),
          DataCell(Text(desc, style: adminLinkStyle)),
          DataCell(Text(overrun)),
          DataCell(Text(cost)),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminInfoDialog(
                  context, 'Просмотр', 'Детали абонемента: $tariff',
                ),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminInfoDialog(
                  context, 'Геозоны', 'Геозоны завершения: $tariff',
                ),
                icon: const Icon(Icons.map, size: 14),
                label: const Text('Геозоны завершения'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать абонемент',
                  fields: const [
                    AdminField(key: 'tariff', label: 'Tariff'),
                    AdminField(key: 'description', label: 'Description'),
                    AdminField(key: 'overrun_price', label: 'Overrun price'),
                    AdminField(key: 'cost', label: 'Cost'),
                  ],
                  onSubmit: (_) async {},
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () async {
                  await showDeleteConfirmDialog(context, 'абонемент $tariff');
                },
                icon: const Icon(Icons.delete, size: 14),
                label: const Text('Удалить'),
              ),
            ],
          )),
        ]);
      },
    );
  }
}

final _subSearchProvider = StateProvider<String>((ref) => '');

final tariffsSubscriptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(tariffsListProvider);
});
