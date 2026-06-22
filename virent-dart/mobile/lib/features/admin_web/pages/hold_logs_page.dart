import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class HoldLogsPage extends ConsumerWidget {
  const HoldLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Hold Logs',
      provider: holdLogsProvider,
      showMatchCount: false,
      filters: Row(
        children: [
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'mm/dd/yyyy'),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.calendar_today, size: 16)),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'mm/dd/yyyy'),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.calendar_today, size: 16)),
          ElevatedButton(
            onPressed: () => showAdminInfoDialog(context, 'Фильтр', 'Выберите период для фильтрации'),
            style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
            child: const Text('Filter'),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('transaction_id')),
        DataColumn(label: Text('client_id')),
        DataColumn(label: Text('type_request_1')),
        DataColumn(label: Text('timestamp_type_request_1')),
        DataColumn(label: Text('order_id')),
        DataColumn(label: Text('amount')),
        DataColumn(label: Text('request_source')),
        DataColumn(label: Text('status_response_1')),
      ],
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(_s('transaction_id'))),
          DataCell(Text(_s('client_id'), style: adminLinkStyle)),
          DataCell(Text(_s('type_request_1'))),
          DataCell(Text(_s('timestamp_type_request_1'))),
          DataCell(Text(_s('order_id'))),
          DataCell(Text(_s('amount'))),
          DataCell(Text(_s('request_source'))),
          DataCell(Text(_s('status_response_1'))),
        ]);
      },
    );
  }
}
