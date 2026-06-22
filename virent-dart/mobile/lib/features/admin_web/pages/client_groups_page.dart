import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class ClientGroupsPage extends ConsumerWidget {
  const ClientGroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Группы Клиентов',
      provider: clientGroupsProvider,
      searchProvider: _clientGroupsSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить группу клиентов',
          fields: const [
            AdminField(key: 'description', label: 'Описание', multiline: true),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/client-groups',
              values,
              clientGroupsProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить группу клиентов'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(_s('description'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(
                  context,
                  title: 'Группа #$id',
                  item: item,
                ),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать группу #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'description', label: 'Описание', multiline: true, initial: _s('description')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/client-groups', id, values, clientGroupsProvider);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () => showAdminDeleteDialog(
                  context,
                  name: _s('description'),
                  onDelete: () async {
                    await ref.read(genericDeleteAction)('/admin/client-groups', id, clientGroupsProvider);
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

final _clientGroupsSearchProvider = StateProvider<String>((ref) => '');
