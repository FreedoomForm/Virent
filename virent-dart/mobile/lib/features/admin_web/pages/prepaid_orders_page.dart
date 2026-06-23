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
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      filters: SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[SizedBox(width:120,child:TextField(decoration:adminFilterDecoration(hint:"ID клиента"))),SizedBox(width:8),SizedBox(width:120,child:TextField(decoration:adminFilterDecoration(hint:"car_id"))),SizedBox(width:8),SizedBox(width:120,child:TextField(decoration:adminFilterDecoration(hint:"status"))),SizedBox(width:8),SizedBox(width:200,child:TextField(decoration:adminFilterDecoration(hint:"transaction_id"))),SizedBox(width:8),SizedBox(width:120,child:TextField(decoration:adminFilterDecoration(hint:"order_id")))])),
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Redis token')),
        DataColumn(label: Text('Car')),
        DataColumn(label: Text('Client')),
        DataColumn(label: Text('Company')),
        DataColumn(label: Text('Abonement')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Type')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final token = (item['redis_token'] ?? item['token'] ?? '-').toString();
        final car = (item['car'] ?? item['scooter_id'] ?? item['car_id'] ?? '-').toString();
        final client = (item['client'] ?? item['client_id'] ?? '-').toString();
        final company = (item['company'] ?? item['company_id'] ?? '-').toString();
        final abonement = (item['abonement'] ?? item['abonement_id'] ?? '-').toString();
        final amount = (item['amount'] ?? '-').toString();
        final status = (item['status'] ?? '-').toString();
        final created = (item['created'] ?? item['created_at'] ?? '-').toString();
        final type = (item['type'] ?? item['payment_type'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(token)),
          DataCell(Text(car)),
          DataCell(Text(client)),
          DataCell(Text(company)),
          DataCell(Text(abonement)),
          DataCell(Text(amount)),
          DataCell(Text(status)),
          DataCell(Text(created)),
          DataCell(Text(type)),
          DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
        ]);
      },
    );
  }
}

final _prepaidOrdersPageSearchProvider = StateProvider<String>((ref) => '');
