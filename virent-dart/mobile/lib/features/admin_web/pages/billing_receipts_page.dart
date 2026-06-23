import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class BillingReceiptsPage extends ConsumerWidget {
  const BillingReceiptsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Чеки',
      provider: billingReceiptsProvider,
      searchProvider: _receiptsSearchProvider,
      searchMatcher: (r, query) {
        final id = (r['id'] ?? '').toString().toLowerCase();
        final check = (r['check'] ?? r['provider'] ?? '').toString().toLowerCase();
        final bill = (r['bill'] ?? r['bill_id'] ?? '').toString().toLowerCase();
        final client = (r['client_id'] ?? r['client'] ?? '').toString().toLowerCase();
        return id.contains(query) || check.contains(query) || bill.contains(query) || client.contains(query);
      },
      filters: Row(
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'columns.bonus.order_id'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 200,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'ID клиента'),
            ),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Чек')),
        DataColumn(label: Text('Bill')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Client')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Company')),
        DataColumn(label: Text('Sendable')),
      ],
      buildRow: (r) {
        String _s(String key) => (r[key] ?? '-').toString();
        final id = _s('id');
        final check = _s('check') == '-' ? 'CLICK' : _s('check');
        final bill = _s('bill_id') == '-' ? _s('bill') : _s('bill_id');
        final status = _s('status') == '-' ? 'SUCCESS' : _s('status');
        final client = _s('client_id');
        final amount = _s('amount');
        final created = _s('created_at') == '-' ? _s('created') : _s('created_at');
        final company = _s('company_id');
        final sendable = _s('sendable');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(check, style: adminLinkStyle)),
          DataCell(Text(bill)),
          DataCell(Text(status)),
          DataCell(Text(client, style: adminLinkStyle)),
          DataCell(Text(amount)),
          DataCell(Text(created)),
          DataCell(Text(company)),
          DataCell(Text(sendable == '-' ? 'Нет' : sendable)),
        ]);
      },
    );
  }
}

final _receiptsSearchProvider = StateProvider<String>((ref) => '');
