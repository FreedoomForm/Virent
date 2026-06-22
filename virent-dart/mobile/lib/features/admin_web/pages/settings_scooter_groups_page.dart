import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class SettingsScooterGroupsPage extends ConsumerWidget {
  const SettingsScooterGroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Entries',
      provider: settingsScooterGroupsProvider,
      searchProvider: _scooterGroupsSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить запись',
          fields: const [
            AdminField(key: 'description', label: 'Описание', multiline: true),
            AdminField(key: 'trigger_equation', label: 'Уравнение триггера'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/settings/scooter-groups',
              values,
              settingsScooterGroupsProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить entry'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Trigger equation')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(_s('description'))),
          DataCell(Text(_s('trigger_equation'))),
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
                    AdminField(key: 'trigger_equation', label: 'Уравнение триггера', initial: _s('trigger_equation')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/settings/scooter-groups', id, values, settingsScooterGroupsProvider);
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
                    await ref.read(genericDeleteAction)('/admin/settings/scooter-groups', id, settingsScooterGroupsProvider);
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

final _scooterGroupsSearchProvider = StateProvider<String>((ref) => '');
