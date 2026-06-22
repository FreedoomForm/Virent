import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class LogsUnconfirmedPage extends ConsumerWidget {
  const LogsUnconfirmedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Entries',
      provider: logsUnconfirmedProvider,
      searchProvider: _unconfirmedSearchProvider,
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Sms code')),
        DataColumn(label: Text('Sms try count')),
        DataColumn(label: Text('Sms try count all')),
        DataColumn(label: Text('Sms try logIn')),
        DataColumn(label: Text('Create time')),
        DataColumn(label: Text('Sms last attempt')),
        DataColumn(label: Text('Check key')),
        DataColumn(label: Text('Api token')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (item) {
        String _s(String key, [String fallback = '-']) => (item[key] ?? fallback).toString();
        final id = _s('id');
        final time = _s('create_time');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(_s('phone'))),
          DataCell(Text(_s('sms_code'))),
          DataCell(Text(_s('sms_try_count'))),
          DataCell(Text(_s('sms_try_count_all'))),
          DataCell(Text(_s('sms_try_login'))),
          DataCell(Text(time)),
          DataCell(Text(_s('sms_last_attempt', time))),
          DataCell(Text(_s('check_key'))),
          DataCell(Text(_s('api_token'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать запись #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'phone', label: 'Телефон', initial: _s('phone')),
                    AdminField(key: 'sms_code', label: 'SMS код', initial: _s('sms_code')),
                    AdminField(key: 'api_token', label: 'API токен', initial: _s('api_token')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/logs/unconfirmed', id, values, logsUnconfirmedProvider);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () => showAdminDeleteDialog(
                  context,
                  name: _s('phone'),
                  onDelete: () async {
                    await ref.read(genericDeleteAction)('/admin/logs/unconfirmed', id, logsUnconfirmedProvider);
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

final _unconfirmedSearchProvider = StateProvider<String>((ref) => '');
