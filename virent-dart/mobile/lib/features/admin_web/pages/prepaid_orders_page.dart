import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class PrepaidOrdersPage extends ConsumerWidget {
  const PrepaidOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Предоплаченные Заказы',
      provider: prepaidOrdersProvider,
      searchProvider: _prepaidSearchProvider,
      filters: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: TextField(
                decoration: adminFilterDecoration(hint: 'ID клиента'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                decoration: adminFilterDecoration(hint: 'car_id'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                decoration: adminFilterDecoration(hint: 'status'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 200,
              child: TextField(
                decoration: adminFilterDecoration(hint: 'transaction_id'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                decoration: adminFilterDecoration(hint: 'order_id'),
              ),
            ),
          ],
        ),
      ),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Код')),
        DataColumn(label: Text('Сумма')),
        DataColumn(label: Text('Использован')),
        DataColumn(label: Text('Кем')),
        DataColumn(label: Text('Когда')),
      ],
      buildRow: (o) {
        final id = (o['id'] ?? '-').toString();
        final code = (o['code'] ?? o['redis_token'] ?? o['token'] ?? '-').toString();
        final amount = (o['amount'] ?? o['sum'] ?? '-').toString();
        final used = (o['used'] ?? o['is_used'] ?? false).toString() == 'true' ? 'Да' : 'Нет';
        final who = (o['used_by'] ?? o['client_id'] ?? '-').toString();
        final when = (o['used_at'] ?? o['created_at'] ?? o['date'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(code, style: adminLinkStyle)),
          DataCell(Text(amount)),
          DataCell(Text(used)),
          DataCell(Text(who)),
          DataCell(Text(when)),
        ]);
      },
    );
  }
}

final _prepaidSearchProvider = StateProvider<String>((ref) => '');
