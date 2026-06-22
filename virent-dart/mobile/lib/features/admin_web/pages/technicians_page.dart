import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class TechniciansPage extends ConsumerWidget {
  const TechniciansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Техники',
      provider: techniciansListProvider,
      searchProvider: _technicianSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить техника',
          fields: const [
            AdminField(key: 'name', label: 'Имя'),
            AdminField(key: 'login', label: 'Логин'),
            AdminField(key: 'password', label: 'Пароль', obscure: true),
            AdminField(key: 'companies', label: 'Компании'),
            AdminField(key: 'permissions', label: 'Разрешения'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/technicians',
              values,
              techniciansListProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить техник'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Имя')),
        DataColumn(label: Text('Логин')),
        DataColumn(label: Text('Companies')),
        DataColumn(label: Text('Technick key')),
        DataColumn(label: Text('Permissions')),
        DataColumn(label: Text('Admin')),
        DataColumn(label: Text('Пароль')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(_s('name'))),
          DataCell(Text(_s('login'))),
          DataCell(Text(_s('companies'))),
          DataCell(Text(_s('tech_key'))),
          DataCell(Text(_s('permissions'))),
          DataCell(Text(_s('admin'))),
          DataCell(Text(_s('password'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(
                  context,
                  title: 'Техник #$id',
                  item: item,
                ),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать техника #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'name', label: 'Имя', initial: _s('name')),
                    AdminField(key: 'login', label: 'Логин', initial: _s('login')),
                    AdminField(key: 'password', label: 'Новый пароль', obscure: true),
                    AdminField(key: 'companies', label: 'Компании', initial: _s('companies')),
                    AdminField(key: 'permissions', label: 'Разрешения', initial: _s('permissions')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/technicians', id, values, techniciansListProvider);
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
                    await ref.read(genericDeleteAction)('/admin/technicians', id, techniciansListProvider);
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

final _technicianSearchProvider = StateProvider<String>((ref) => '');
