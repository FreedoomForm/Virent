import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class LogsUnconfirmedPage extends ConsumerWidget {
  const LogsUnconfirmedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Неподтвержденные Логи',
      provider: logsUnconfirmedProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Trip')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Reason')),
        DataColumn(label: Text('Created')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final trip = (item['trip'] ?? item['trip_id'] ?? '-').toString();
        final status = (item['status'] ?? '-').toString();
        final reason = (item['reason'] ?? '-').toString();
        final created = (item['created'] ?? item['created_at'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(trip)),
          DataCell(Text(status)),
          DataCell(Text(reason)),
          DataCell(Text(created)),
          DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
        ]);
      },
    );
  }
}

final _logsUnconfirmedPageSearchProvider = StateProvider<String>((ref) => '');
