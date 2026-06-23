import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class BillingReceiptsPage extends ConsumerWidget {
  const BillingReceiptsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Квитанции',
      provider: billingReceiptsProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Client')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Fiscal sign')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Created')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final client = (item['client'] ?? item['client_id'] ?? '-').toString();
        final amount = (item['amount'] ?? '-').toString();
        final fiscal_sign = (item['fiscal_sign'] ?? item['fiscal'] ?? '-').toString();
        final status = (item['status'] ?? '-').toString();
        final created = (item['created'] ?? item['created_at'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(client)),
          DataCell(Text(amount)),
          DataCell(Text(fiscal_sign)),
          DataCell(Text(status)),
          DataCell(Text(created)),
          DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
        ]);
      },
    );
  }
}

final _billingReceiptsPageSearchProvider = StateProvider<String>((ref) => '');
