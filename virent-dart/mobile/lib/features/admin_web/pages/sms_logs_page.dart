import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class SmsLogsPage extends ConsumerWidget {
  const SmsLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Entries',
      provider: smsLogsProvider,
      searchProvider: _smsSearchProvider,
      searchMatcher: (l, query) {
        final id = (l['id'] ?? '').toString().toLowerCase();
        final phone = (l['phone'] ?? '').toString().toLowerCase();
        final code = (l['sms_code'] ?? '').toString().toLowerCase();
        return id.contains(query) || phone.contains(query) || code.contains(query);
      },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Sms code')),
        DataColumn(label: Text('Sms try count')),
        DataColumn(label: Text('Sms try count all')),
        DataColumn(label: Text('Sms try login')),
        DataColumn(label: Text('Create time')),
        DataColumn(label: Text('Sms last attempt')),
        DataColumn(label: Text('Check key')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (l) {
        String _s(String key) => (l[key] ?? '-').toString();
        final id = _s('id');
        final phone = _s('phone');
        final code = _s('sms_code');
        final tryCount = _s('sms_try_count');
        final tryCountAll = _s('sms_try_count_all');
        final tryLogin = _s('sms_try_login');
        final createTime = _s('create_time');
        final lastAttempt = _s('sms_last_attempt');
        final checkKey = _s('check_key');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(phone)),
          DataCell(Text(code)),
          DataCell(Text(tryCount)),
          DataCell(Text(tryCountAll)),
          DataCell(Text(tryLogin)),
          DataCell(Text(createTime)),
          DataCell(Text(lastAttempt)),
          DataCell(Text(checkKey)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () {},
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

final _smsSearchProvider = StateProvider<String>((ref) => '');
