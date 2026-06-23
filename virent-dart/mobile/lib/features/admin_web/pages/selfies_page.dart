import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class SelfiesPage extends ConsumerWidget {
  const SelfiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Селфи',
      provider: selfiesListProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Client')),
        DataColumn(label: Text('Scooter')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Created')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final client = (item['client'] ?? item['client_id'] ?? '-').toString();
        final scooter = (item['scooter'] ?? item['scooter_id'] ?? '-').toString();
        final type = (item['type'] ?? item['selfie_type'] ?? '-').toString();
        final created = (item['created'] ?? item['created_at'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(client)),
          DataCell(Text(scooter)),
          DataCell(Text(type)),
          DataCell(Text(created)),
          DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
        ]);
      },
    );
  }
}

final _selfiesPageSearchProvider = StateProvider<String>((ref) => '');
