import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class AdminRolesPage extends ConsumerWidget {
  const AdminRolesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Роли',
      provider: adminRolesProvider,
      searchProvider: _rolesSearchProvider,
      searchMatcher: (r, query) {
        final name = (r['name'] ?? r['title'] ?? '').toString().toLowerCase();
        return name.contains(query);
      },
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить роль',
          fields: const [
            AdminField(key: 'name', label: 'Имя'),
            AdminField(key: 'permissions', label: 'Разрешения', multiline: true),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/roles',
              values,
              adminRolesProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить роль'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('Имя')),
        DataColumn(label: Text('Разрешения')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (r) {
        String _s(String key) => (r[key] ?? '-').toString();
        final name = _s('name') == '-' ? _s('title') : _s('name');
        final permissions = _s('permissions');
        return DataRow(cells: [
          DataCell(Text(name, style: adminLinkStyle)),
          DataCell(Text(permissions)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
            ],
          )),
        ]);
      },
    );
  }
}

final _rolesSearchProvider = StateProvider<String>((ref) => '');
