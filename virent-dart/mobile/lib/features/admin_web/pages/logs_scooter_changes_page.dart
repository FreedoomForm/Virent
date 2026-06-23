import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class LogsScooterChangesPage extends ConsumerWidget {
  const LogsScooterChangesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Изменения Самокатов',
      provider: logsScooterChangesProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Scooter')),
        DataColumn(label: Text('Field')),
        DataColumn(label: Text('Old value')),
        DataColumn(label: Text('New value')),
        DataColumn(label: Text('Changed at')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final scooter = (item['scooter'] ?? item['scooter_id'] ?? '-').toString();
        final field = (item['field'] ?? item['field_name'] ?? '-').toString();
        final old_value = (item['old_value'] ?? item['old'] ?? '-').toString();
        final new_value = (item['new_value'] ?? item['new'] ?? '-').toString();
        final changed_at = (item['changed_at'] ?? item['created_at'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(scooter)),
          DataCell(Text(field)),
          DataCell(Text(old_value)),
          DataCell(Text(new_value)),
          DataCell(Text(changed_at)),
        ]);
      },
    );
  }
}

final _logsScooterChangesPageSearchProvider = StateProvider<String>((ref) => '');
