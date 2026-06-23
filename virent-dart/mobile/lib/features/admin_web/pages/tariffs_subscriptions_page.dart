import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class TariffsSubscriptionsPage extends ConsumerWidget {
  const TariffsSubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Подписки Тарифов',
      provider: tariffSubscriptionsProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Client')),
        DataColumn(label: Text('Tariff')),
        DataColumn(label: Text('Start')),
        DataColumn(label: Text('End')),
        DataColumn(label: Text('Status')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final client = (item['client'] ?? item['client_id'] ?? '-').toString();
        final tariff = (item['tariff'] ?? item['tariff_id'] ?? '-').toString();
        final start = (item['start'] ?? item['start_date'] ?? item['started_at'] ?? '-').toString();
        final end = (item['end'] ?? item['end_date'] ?? item['ends_at'] ?? '-').toString();
        final status = (item['status'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(client)),
          DataCell(Text(tariff)),
          DataCell(Text(start)),
          DataCell(Text(end)),
          DataCell(Text(status)),
          DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
        ]);
      },
    );
  }
}

final _tariffsSubscriptionsPageSearchProvider = StateProvider<String>((ref) => '');
