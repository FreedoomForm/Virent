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
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      filters: Row(children:[SizedBox(width:150,child:TextField(decoration:adminFilterDecoration(hint:"ID клиента")))]),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Client')),
        DataColumn(label: Text('Text')),
        DataColumn(label: Text('Is read')),
        DataColumn(label: Text('Deleted')),
        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Client Name')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final client_id = (item['client_id'] ?? item['client'] ?? '-').toString();
        final text = (item['text'] ?? item['message'] ?? item['body'] ?? '-').toString();
        final is_read = (item['is_read'] ?? item['read'] ?? '-').toString();
        final deleted = (item['deleted'] ?? item['is_deleted'] ?? '-').toString();
        final created = (item['created'] ?? item['created_at'] ?? '-').toString();
        final client_name = (item['client_name'] ?? item['client'] ?? item['name'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(client_id)),
          DataCell(Text(text)),
          DataCell(Text(is_read)),
          DataCell(Text(deleted)),
          DataCell(Text(created)),
          DataCell(Text(client_name)),
          DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
        ]);
      },
    );
  }
}

final _pushHistoryPageSearchProvider = StateProvider<String>((ref) => '');
