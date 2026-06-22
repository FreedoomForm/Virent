import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class PushHistoryPage extends ConsumerWidget {
  const PushHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'История Push',
      provider: pushHistoryListProvider,
      searchProvider: _pushSearchProvider,
      filters: Row(
        children: [
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'ID клиента'),
            ),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Заголовок')),
        DataColumn(label: Text('Сообщение')),
        DataColumn(label: Text('Аудитория')),
        DataColumn(label: Text('Доставлено')),
        DataColumn(label: Text('Открыто')),
        DataColumn(label: Text('Время')),
      ],
      buildRow: (p) {
        final id = (p['id'] ?? '-').toString();
        final title = (p['title'] ?? p['heading'] ?? '-').toString();
        final message = (p['body'] ?? p['message'] ?? p['text'] ?? '-').toString();
        final audience = (p['audience'] ?? p['client_id'] ?? 'all').toString();
        final delivered = (p['delivered'] ?? p['delivered_count'] ?? 0).toString();
        final opened = (p['opened'] ?? p['opened_count'] ?? p['is_read'] ?? 0).toString();
        final time = (p['created_at'] ?? p['time'] ?? p['date'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(title, style: adminLinkStyle)),
          DataCell(Text(message)),
          DataCell(Text(audience)),
          DataCell(Text(delivered)),
          DataCell(Text(opened)),
          DataCell(Text(time)),
        ]);
      },
    );
  }
}

final _pushSearchProvider = StateProvider<String>((ref) => '');
