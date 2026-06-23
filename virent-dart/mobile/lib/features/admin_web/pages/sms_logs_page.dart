import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class SmsLogsPage extends ConsumerWidget {
  const SmsLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'SMS Логи',
      provider: smsLogsProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
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
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final phone = (item['phone'] ?? '-').toString();
        final code = (item['sms_code'] ?? item['code'] ?? '-').toString();
        final try_count = (item['sms_try_count'] ?? item['try_count'] ?? '-').toString();
        final try_count_all = (item['sms_try_count_all'] ?? item['try_count_all'] ?? '-').toString();
        final try_login = (item['sms_try_login'] ?? item['try_login'] ?? '-').toString();
        final create_time = (item['create_time'] ?? item['created_at'] ?? '-').toString();
        final last_attempt = (item['sms_last_attempt'] ?? item['last_attempt'] ?? '-').toString();
        final check_key = (item['check_key'] ?? item['key'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(phone)),
          DataCell(Text(code)),
          DataCell(Text(try_count)),
          DataCell(Text(try_count_all)),
          DataCell(Text(try_login)),
          DataCell(Text(create_time)),
          DataCell(Text(last_attempt)),
          DataCell(Text(check_key)),
          DataCell(Row(
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

final _smsLogsPageSearchProvider = StateProvider<String>((ref) => '');
