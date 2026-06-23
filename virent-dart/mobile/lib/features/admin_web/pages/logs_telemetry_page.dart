import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class LogsTelemetryPage extends ConsumerWidget {
  const LogsTelemetryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Логи Телеметрии',
      provider: logsTelemetryProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Scooter')),
        DataColumn(label: Text('Battery')),
        DataColumn(label: Text('Speed')),
        DataColumn(label: Text('Location')),
        DataColumn(label: Text('Timestamp')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final scooter = (item['scooter'] ?? item['scooter_id'] ?? '-').toString();
        final battery = (item['battery'] ?? item['battery_level'] ?? '-').toString();
        final speed = (item['speed'] ?? item['current_speed'] ?? '-').toString();
        final location = (item['location'] ?? item['coordinates'] ?? '-').toString();
        final timestamp = (item['timestamp'] ?? item['created_at'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(scooter)),
          DataCell(Text(battery)),
          DataCell(Text(speed)),
          DataCell(Text(location)),
          DataCell(Text(timestamp)),
        ]);
      },
    );
  }
}

final _logsTelemetryPageSearchProvider = StateProvider<String>((ref) => '');
