import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class TariffAbonementsPage extends ConsumerWidget {
  const TariffAbonementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Абонементы',
      provider: tariffAbonementsProvider,
      searchProvider: _abonementsSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить абонемент',
          fields: const [
            AdminField(key: 'tariff', label: 'Tariff'),
            AdminField(key: 'description', label: 'Description'),
            AdminField(key: 'overrun_price', label: 'Overrun price', initial: '0'),
            AdminField(key: 'cost', label: 'Cost', initial: '0'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/tariff-abonements',
              values,
              tariffAbonementsProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить абонемент'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('Tariff')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Overrun price')),
        DataColumn(label: Text('Cost')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(_s('tariff'), style: adminLinkStyle)),
          DataCell(Text(_s('description'), style: adminLinkStyle)),
          DataCell(Text(_s('overrun_price'))),
          DataCell(Text(_s('cost'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(context, title: 'Абонемент #$id', item: item),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminInfoDialog(context, 'Геозоны завершения', 'Показаны геозоны завершения абонемента #$id'),
                icon: const Icon(Icons.map, size: 14),
                label: const Text('Геозоны завершения'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать абонемент #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'tariff', label: 'Tariff', initial: _s('tariff')),
                    AdminField(key: 'description', label: 'Description', initial: _s('description')),
                    AdminField(key: 'overrun_price', label: 'Overrun price', initial: _s('overrun_price')),
                    AdminField(key: 'cost', label: 'Cost', initial: _s('cost')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/tariff-abonements', id, values, tariffAbonementsProvider);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () => showAdminDeleteDialog(
                  context,
                  name: _s('tariff'),
                  onDelete: () async {
                    await ref.read(genericDeleteAction)('/admin/tariff-abonements', id, tariffAbonementsProvider);
                  },
                ),
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

final _abonementsSearchProvider = StateProvider<String>((ref) => '');
