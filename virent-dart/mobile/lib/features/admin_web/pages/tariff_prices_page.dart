import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class TariffPricesPage extends ConsumerWidget {
  const TariffPricesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Цены Тарифов',
      provider: tariffPricesProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Tariff')),
        DataColumn(label: Text('Price per minute')),
        DataColumn(label: Text('Start price')),
        DataColumn(label: Text('Max price')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final tariff = (item['tariff'] ?? item['tariff_id'] ?? '-').toString();
        final price_per_minute = (item['price_per_minute'] ?? item['minute_price'] ?? '-').toString();
        final start_price = (item['start_price'] ?? item['base_price'] ?? '-').toString();
        final max_price = (item['max_price'] ?? item['max'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(tariff)),
          DataCell(Text(price_per_minute)),
          DataCell(Text(start_price)),
          DataCell(Text(max_price)),
          DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать'))),
        ]);
      },
    );
  }
}

final _tariffPricesPageSearchProvider = StateProvider<String>((ref) => '');
