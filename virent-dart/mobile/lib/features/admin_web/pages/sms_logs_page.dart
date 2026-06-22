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
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Получатель')),
        DataColumn(label: Text('Сообщение')),
        DataColumn(label: Text('Статус')),
        DataColumn(label: Text('Время')),
      ],
      buildRow: (l) {
        final id = (l['id'] ?? '-').toString();
        final phone = (l['phone'] ?? l['recipient'] ?? l['to'] ?? '-').toString();
        final message = (l['message'] ?? l['body'] ?? l['sms_code'] ?? l['text'] ?? '-').toString();
        final status = (l['status'] ?? l['state'] ?? 'sent').toString();
        final time = (l['created_at'] ?? l['create_time'] ?? l['time'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(phone, style: adminLinkStyle)),
          DataCell(Text(message)),
          DataCell(Text(status)),
          DataCell(Text(time)),
        ]);
      },
    );
  }
}

final _smsSearchProvider = StateProvider<String>((ref) => '');
