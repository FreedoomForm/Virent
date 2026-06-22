import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class AdminAgreementsPage extends ConsumerWidget {
  const AdminAgreementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Entries',
      provider: adminAgreementsProvider,
      searchProvider: _agreementsSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить договор',
          fields: const [
            AdminField(key: 'file', label: 'Файл'),
            AdminField(key: 'url_label', label: 'URL label'),
            AdminField(key: 'html_file', label: 'HTML file', multiline: true),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/agreements',
              values,
              adminAgreementsProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить entry'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('File')),
        DataColumn(label: Text('Url lable')),
        DataColumn(label: Text('Html file')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(_s('file'))),
          DataCell(Text(_s('url_label'))),
          DataCell(Text(_s('html_file'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать договор #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'file', label: 'Файл', initial: _s('file')),
                    AdminField(key: 'url_label', label: 'URL label', initial: _s('url_label')),
                    AdminField(key: 'html_file', label: 'HTML file', multiline: true, initial: _s('html_file')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/agreements', id, values, adminAgreementsProvider);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () => showAdminDeleteDialog(
                  context,
                  name: _s('file'),
                  onDelete: () async {
                    await ref.read(genericDeleteAction)('/admin/agreements', id, adminAgreementsProvider);
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

final _agreementsSearchProvider = StateProvider<String>((ref) => '');
