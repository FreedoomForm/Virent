import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class TariffPricesPage extends ConsumerWidget {
  const TariffPricesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Цены',
      provider: tariffPricesProvider,
      searchProvider: _pricesSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить цену',
          fields: const [
            AdminField(key: 'name', label: 'Наименование'),
            AdminField(key: 'json', label: 'Json'),
            AdminField(key: 'time_unit', label: 'Time unit'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/tariff-prices',
              values,
              tariffPricesProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить цены'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('Наименование')),
        DataColumn(label: Text('Json')),
        DataColumn(label: Text('Time unit')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(_s('name'))),
          DataCell(ElevatedButton(
            onPressed: () => showAdminViewDialog(
              context,
              title: 'Цена #$id — Json',
              item: {'id': id, 'name': _s('name'), 'json': _s('json'), 'time_unit': _s('time_unit')},
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: adminPrimaryForeground, minimumSize: const Size(0, 30)),
            child: const Text('Развернуть / Свернуть', style: TextStyle(fontSize: 12)),
          )),
          DataCell(Text(_s('time_unit'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(context, title: 'Цена #$id', item: item),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать цену #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'name', label: 'Наименование', initial: _s('name')),
                    AdminField(key: 'json', label: 'Json', initial: _s('json')),
                    AdminField(key: 'time_unit', label: 'Time unit', initial: _s('time_unit')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/tariff-prices', id, values, tariffPricesProvider);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () => showAdminDeleteDialog(
                  context,
                  name: _s('name'),
                  onDelete: () async {
                    await ref.read(genericDeleteAction)('/admin/tariff-prices', id, tariffPricesProvider);
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

final _pricesSearchProvider = StateProvider<String>((ref) => '');
