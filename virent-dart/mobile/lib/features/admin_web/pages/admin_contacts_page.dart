import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class AdminContactsPage extends ConsumerWidget {
  const AdminContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Entries',
      provider: adminContactsProvider,
      searchProvider: _contactsSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить контакт',
          fields: const [
            AdminField(key: 'city', label: 'Город'),
            AdminField(key: 'phone', label: 'Телефон'),
            AdminField(key: 'email', label: 'Email'),
            AdminField(key: 'telegram', label: 'Telegram'),
            AdminField(key: 'whatsapp', label: 'Whatsapp'),
            AdminField(key: 'company', label: 'Компания'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/contacts',
              values,
              adminContactsProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить entry'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('City')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Telegram')),
        DataColumn(label: Text('Whatsapp')),
        DataColumn(label: Text('Faq')),
        DataColumn(label: Text('Company')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(_s('city'))),
          DataCell(Text(_s('phone'))),
          DataCell(Text(_s('email'), style: adminLinkStyle)),
          DataCell(Text(_s('telegram'))),
          DataCell(Text(_s('whatsapp'))),
          DataCell(Text(_s('faq'))),
          DataCell(Text(_s('company'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать контакт #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'city', label: 'Город', initial: _s('city')),
                    AdminField(key: 'phone', label: 'Телефон', initial: _s('phone')),
                    AdminField(key: 'email', label: 'Email', initial: _s('email')),
                    AdminField(key: 'telegram', label: 'Telegram', initial: _s('telegram')),
                    AdminField(key: 'whatsapp', label: 'Whatsapp', initial: _s('whatsapp')),
                    AdminField(key: 'company', label: 'Компания', initial: _s('company')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/contacts', id, values, adminContactsProvider);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () => showAdminDeleteDialog(
                  context,
                  name: _s('city'),
                  onDelete: () async {
                    await ref.read(genericDeleteAction)('/admin/contacts', id, adminContactsProvider);
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

final _contactsSearchProvider = StateProvider<String>((ref) => '');
