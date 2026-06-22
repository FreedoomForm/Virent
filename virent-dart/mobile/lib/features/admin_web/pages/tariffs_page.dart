import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class TariffsPage extends ConsumerWidget {
  const TariffsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Тарифы',
      provider: tariffsListProvider,
      searchProvider: _tariffsSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить тариф',
          fields: const [
            AdminField(key: 'name_admin', label: 'Название в админке'),
            AdminField(key: 'name_app', label: 'Название в приложении'),
            AdminField(key: 'hold', label: 'Hold', initial: '0'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/tariffs',
              values,
              tariffsListProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить тариф'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('Название в админке')),
        DataColumn(label: Text('Название в мобильном приложении')),
        DataColumn(label: Text('Hold')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(_s('name_admin'))),
          DataCell(Text(_s('name_app'), style: adminLinkStyle)),
          DataCell(Text(_s('hold'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(context, title: 'Тариф #$id', item: item),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminInfoDialog(context, 'Геозоны завершения', 'Показаны геозоны завершения тарифа #$id'),
                icon: const Icon(Icons.map, size: 14),
                label: const Text('Геозоны завершения'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать тариф #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'name_admin', label: 'Название в админке', initial: _s('name_admin')),
                    AdminField(key: 'name_app', label: 'Название в приложении', initial: _s('name_app')),
                    AdminField(key: 'hold', label: 'Hold', initial: _s('hold')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/tariffs', id, values, tariffsListProvider);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () => showAdminDeleteDialog(
                  context,
                  name: _s('name_admin'),
                  onDelete: () async {
                    await ref.read(genericDeleteAction)('/admin/tariffs', id, tariffsListProvider);
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

final _tariffsSearchProvider = StateProvider<String>((ref) => '');
