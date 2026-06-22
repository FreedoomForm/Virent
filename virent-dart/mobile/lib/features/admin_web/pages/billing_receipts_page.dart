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
        DataColumn(label: Text('Пользователь')),
        DataColumn(label: Text('Поездка')),
        DataColumn(label: Text('Сумма')),
        DataColumn(label: Text('Дата')),
        DataColumn(label: Text('Статус')),
      ],
      buildRow: (r) {
        final id = (r['id'] ?? '-').toString();
        final user = (r['user_id'] ?? r['client_id'] ?? r['user'] ?? '-').toString();
        final trip = (r['trip_id'] ?? r['order_id'] ?? r['bill_id'] ?? '-').toString();
        final amount = (r['amount'] ?? r['sum'] ?? '-').toString();
        final date = (r['created_at'] ?? r['created'] ?? r['date'] ?? '-').toString();
        final status = (r['status'] ?? r['state'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(user, style: adminLinkStyle)),
          DataCell(Text(trip)),
          DataCell(Text(amount)),
          DataCell(Text(date)),
          DataCell(Text(status)),
        ]);
      },
    );
  }
}

final _receiptsSearchProvider = StateProvider<String>((ref) => '');
