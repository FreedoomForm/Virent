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
      provider: adminListProvider,
      searchProvider: _adminSearchProvider,
      searchMatcher: (a, query) {
        final name = (a['name'] ?? a['full_name'] ?? '').toString().toLowerCase();
        final email = (a['email'] ?? '').toString().toLowerCase();
        final role = (a['role'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query) || role.contains(query);
      },
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить роль',
          fields: const [
            AdminField(key: 'name', label: 'Имя'),
            AdminField(key: 'email', label: 'Email'),
            AdminField(key: 'role', label: 'Роль', hint: 'admin / super_admin / ...'),
            AdminField(key: 'password', label: 'Пароль', obscure: true),
          ],
          onSubmit: (values) async {
            await ref.read(createAdminAction)(values);
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить роль'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Имя')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Роль')),
        DataColumn(label: Text('Последняя активность')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (a) {
        final id = (a['id'] ?? '-').toString();
        final name = (a['name'] ?? a['full_name'] ?? '-').toString();
        final email = (a['email'] ?? '-').toString();
        final role = (a['role'] ?? a['role_name'] ?? '-').toString();
        final lastActive = (a['last_activity'] ?? a['last_active'] ?? a['updated_at'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(email)),
          DataCell(Text(role)),
          DataCell(Text(lastActive)),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать админа #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'name', label: 'Имя', initial: name),
                    AdminField(key: 'email', label: 'Email', initial: email),
                    AdminField(key: 'role', label: 'Роль', initial: role),
                    AdminField(key: 'password', label: 'Новый пароль (необязательно)', obscure: true),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/list', id, values, adminListProvider);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () => showAdminDeleteDialog(
                  context,
                  name: name,
                  onDelete: () async {
                    await ref.read(deleteAdminAction)(id);
                  },
                ),
                icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                label: const Text('Удалить', style: TextStyle(color: Colors.red)),
              ),
            ],
          )),
        ]);
      },
    );
  }
}

final _adminSearchProvider = StateProvider<String>((ref) => '');
