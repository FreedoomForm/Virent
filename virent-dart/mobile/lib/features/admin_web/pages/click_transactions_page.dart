import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class ClickTransactionsPage extends ConsumerWidget {
  const ClickTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Транзакции CLICK',
      provider: clickTransactionsProvider,
      searchProvider: _clickSearchProvider,
      filters: Row(
        children: [
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'merchant_trans_id'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'click_trans_id'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'status'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'error'),
            ),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Пользователь')),
        DataColumn(label: Text('ID транзакции')),
        DataColumn(label: Text('Сумма')),
        DataColumn(label: Text('Дата')),
        DataColumn(label: Text('Статус')),
      ],
      buildRow: (t) {
        final id = (t['id'] ?? '-').toString();
        final user = (t['user_id'] ?? t['client_id'] ?? t['merchant_trans_id'] ?? '-').toString();
        final txId = (t['click_trans_id'] ?? t['transaction_id'] ?? '-').toString();
        final amount = (t['amount'] ?? t['sum'] ?? '-').toString();
        final date = (t['created_at'] ?? t['sign_time'] ?? t['date'] ?? '-').toString();
        final status = (t['status'] ?? t['action'] ?? t['state'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(user, style: adminLinkStyle)),
          DataCell(Text(txId)),
          DataCell(Text(amount)),
          DataCell(Text(date)),
          DataCell(Text(status)),
        ]);
      },
    );
  }
}

final _clickSearchProvider = StateProvider<String>((ref) => '');
