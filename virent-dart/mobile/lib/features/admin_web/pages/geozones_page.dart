import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class GeozonesPage extends ConsumerWidget {
  const GeozonesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Геозоны',
      provider: zonesListProvider,
      searchProvider: _zoneSearchProvider,
      searchMatcher: (z, query) {
        final name = (z['name'] ?? z['title'] ?? '').toString().toLowerCase();
        final city = (z['city'] ?? z['city_name'] ?? '').toString().toLowerCase();
        return name.contains(query) || city.contains(query);
      },
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить геозону',
          fields: const [
            AdminField(key: 'name', label: 'Название'),
            AdminField(key: 'type', label: 'Тип'),
            AdminField(key: 'speed_limit', label: 'Скорость'),
            AdminField(key: 'city', label: 'Город'),
          ],
          onSubmit: (values) async {
            await ref.read(createZoneAction)(values);
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить геозону'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Название')),
        DataColumn(label: Text('Тип')),
        DataColumn(label: Text('Скорость')),
        DataColumn(label: Text('Город')),
        DataColumn(label: Text('Самокатов')),
      ],
      buildRow: (z) {
        final id = (z['id'] ?? '-').toString();
        final name = (z['name'] ?? z['title'] ?? '-').toString();
        final type = (z['type'] ?? z['zone_type'] ?? '-').toString();
        final speed = (z['speed_limit'] ?? z['speed'] ?? z['max_speed'] ?? '-').toString();
        final city = (z['city'] ?? z['city_name'] ?? z['city_id'] ?? '-').toString();
        final scootersCount = (z['scooters_count'] ?? z['scooter_count'] ?? z['count'] ?? 0).toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name, style: adminLinkStyle)),
          DataCell(Text(type)),
          DataCell(Text(speed)),
          DataCell(Text(city)),
          DataCell(Text(scootersCount)),
        ]);
      },
    );
  }
}

final _zoneSearchProvider = StateProvider<String>((ref) => '');
