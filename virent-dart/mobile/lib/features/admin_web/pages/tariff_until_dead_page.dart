import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class TariffUntilDeadPage extends ConsumerWidget {
  const TariffUntilDeadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Тарифы До Конца',
      provider: tariffsListProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Tariff')),
        DataColumn(label: Text('Days left')),
        DataColumn(label: Text('Status')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final tariff = (item['tariff'] ?? item['tariff_id'] ?? '-').toString();
        final days_left = (item['days_left'] ?? item['remaining_days'] ?? '-').toString();
        final status = (item['status'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(tariff)),
          DataCell(Text(days_left)),
          DataCell(Text(status)),
          DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
        ]);
      },
    );
  }
}

final _tariffUntilDeadPageSearchProvider = StateProvider<String>((ref) => '');
