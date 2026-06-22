import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class AdminPermissionsPage extends ConsumerWidget {
  const AdminPermissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Разрешения',
      provider: adminPermissionsProvider,
      searchProvider: _permissionsSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить разрешение',
          fields: const [
            AdminField(key: 'name', label: 'Имя'),
            AdminField(key: 'title', label: 'Заголовок'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/permissions',
              values,
              adminPermissionsProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить разрешение'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('Имя')),
        DataColumn(label: Text('backpack::permissionmanager.title')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(_s('name'))),
          DataCell(Text(_s('title'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать разрешение #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'name', label: 'Имя', initial: _s('name')),
                    AdminField(key: 'title', label: 'Заголовок', initial: _s('title')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/permissions', id, values, adminPermissionsProvider);
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
                    await ref.read(genericDeleteAction)('/admin/permissions', id, adminPermissionsProvider);
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

final _permissionsSearchProvider = StateProvider<String>((ref) => '');
