import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class AdminCompaniesPage extends ConsumerWidget {
  const AdminCompaniesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Companies',
      provider: adminCompaniesProvider,
      searchProvider: _companiesSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить компанию',
          fields: const [
            AdminField(key: 'name', label: 'Название'),
            AdminField(key: 'cp_pub', label: 'Опубликовано (0/1)', initial: '0'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/companies',
              values,
              adminCompaniesProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить company'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Cp pub')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(_s('name'))),
          DataCell(Text(_s('cp_pub'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(
                  context,
                  title: 'Компания #$id',
                  item: item,
                ),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать компанию #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'name', label: 'Название', initial: _s('name')),
                    AdminField(key: 'cp_pub', label: 'Опубликовано (0/1)', initial: _s('cp_pub')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)(
                      '/admin/companies',
                      id,
                      values,
                      adminCompaniesProvider,
                    );
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
                    await ref.read(genericDeleteAction)(
                      '/admin/companies',
                      id,
                      adminCompaniesProvider,
                    );
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

final _companiesSearchProvider = StateProvider<String>((ref) => '');
