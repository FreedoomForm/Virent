import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class PaymeTransactionsPage extends ConsumerWidget {
  const PaymeTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Транзакции Payme',
      provider: paymeTransactionsProvider,
      searchProvider: _paymeSearchProvider,
      filters: Row(
        children: [
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'ID клиента'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 200,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'payme_transaction_id'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'state'),
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
        final user = (t['user_id'] ?? t['client_id'] ?? t['phone'] ?? '-').toString();
        final txId = (t['transaction_id'] ?? t['payme_transaction_id'] ?? t['payme_trans_id'] ?? '-').toString();
        final amount = (t['amount'] ?? t['sum'] ?? '-').toString();
        final date = (t['created_at'] ?? t['payme_time'] ?? t['date'] ?? '-').toString();
        final status = (t['status'] ?? t['state'] ?? t['state_description'] ?? '-').toString();
        final stLower = status.toLowerCase();
        Color stateColor = Colors.blue;
        if (stLower.contains('успеш') || stLower.contains('success') || stLower.contains('оплач') || stLower == '2') {
          stateColor = Colors.green;
        } else if (stLower.contains('отмен') || stLower.contains('cancel') || stLower == '-2') {
          stateColor = Colors.red;
        } else if (stLower.contains('ожид') || stLower.contains('pending') || stLower == '1') {
          stateColor = Colors.orange;
        }
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(user, style: adminLinkStyle)),
          DataCell(Text(txId)),
          DataCell(Text(amount)),
          DataCell(Text(date)),
          DataCell(Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: stateColor, borderRadius: BorderRadius.circular(4)),
            child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10)),
          )),
        ]);
      },
    );
  }
}

final _paymeSearchProvider = StateProvider<String>((ref) => '');
