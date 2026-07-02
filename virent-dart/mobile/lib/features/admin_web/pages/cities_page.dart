import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class CitiesPage extends ConsumerWidget {
  const CitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Города',
      provider: citiesListProvider,
      searchProvider: _citySearchProvider,
      searchMatcher: (c, query) {
        final id = (c['id'] ?? '').toString().toLowerCase();
        final name = (c['name'] ?? c['title'] ?? '').toString().toLowerCase();
        final country = (c['country'] ?? c['country_name'] ?? '').toString().toLowerCase();
        return id.contains(query) || name.contains(query) || country.contains(query);
      },
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить город',
          fields: const [
            AdminField(key: 'name', label: 'Название'),
            AdminField(key: 'country', label: 'Страна'),
            AdminField(key: 'scooters_count', label: 'Самокатов', initial: '0'),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/cities',
              values,
              citiesListProvider);
          }),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить город'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground)),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Название')),
        DataColumn(label: Text('Страна')),
        DataColumn(label: Text('Самокатов')),
        DataColumn(label: Text('Активен')),
      ],
      buildRow: (c) {
        final id = (c['id'] ?? '-').toString();
        final name = (c['name'] ?? c['title'] ?? '-').toString();
        final country = (c['country'] ?? c['country_name'] ?? '-').toString();
        final scootersCount = (c['scooters_count'] ?? c['scooters'] ?? c['count'] ?? '-').toString();
        final active = c['active'] ?? c['is_active'] ?? c['enabled'] ?? false;
        final isActive = active == true || active == 1 || active == '1' || active == 'true';
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name, style: adminLinkStyle)),
          DataCell(Text(country)),
          DataCell(Text(scootersCount)),
          DataCell(Text(isActive ? 'Да' : 'Нет',
              style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
        ]);
      });
  }
}

final _citySearchProvider = StateProvider<String>((ref) => '');
