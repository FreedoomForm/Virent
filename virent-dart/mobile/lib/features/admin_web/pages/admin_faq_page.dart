import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class AdminFaqPage extends ConsumerWidget {
  const AdminFaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Faqs',
      provider: adminFaqProvider,
      searchProvider: _faqSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить FAQ',
          fields: const [
            AdminField(key: 'name', label: 'Название'),
            AdminField(key: 'description', label: 'Описание', multiline: true),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/faq',
              values,
              adminFaqProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить faq'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(_s('name'))),
          DataCell(Text(_s('description'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать FAQ #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'name', label: 'Название', initial: _s('name')),
                    AdminField(key: 'description', label: 'Описание', multiline: true, initial: _s('description')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/faq', id, values, adminFaqProvider);
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
                    await ref.read(genericDeleteAction)('/admin/faq', id, adminFaqProvider);
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

final _faqSearchProvider = StateProvider<String>((ref) => '');
