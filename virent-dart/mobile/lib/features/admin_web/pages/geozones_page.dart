import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class GeozonesPage extends ConsumerWidget {
  const GeozonesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Геозоны',
      provider: zonesListProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      createButton: ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.add, size:16),label:const Text("Добавить геозону"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Название')),
        DataColumn(label: Text('Заполнение')),
        DataColumn(label: Text('Обводка')),
        DataColumn(label: Text('Группы')),
        DataColumn(label: Text('кэф.проз.геозоны')),
        DataColumn(label: Text('кэф.ярк.обводки')),
        DataColumn(label: Text('Команды')),
        DataColumn(label: Text('Зона Разрешенного...')),
        DataColumn(label: Text('Зона Завершения...')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final name = (item['name'] ?? '-').toString();
        final fill = (item['fill'] ?? item['fill_color'] ?? '-').toString();
        final stroke = (item['stroke'] ?? item['stroke_color'] ?? '-').toString();
        final groups = (item['groups'] ?? '-').toString();
        final alpha = (item['alpha'] ?? item['fill_opacity'] ?? '-').toString();
        final beta = (item['beta'] ?? item['stroke_opacity'] ?? '-').toString();
        final cmds = (item['commands'] ?? item['cmds'] ?? item['iot_commands'] ?? '-').toString();
        final z1 = (item['allowed_zone'] ?? item['zone_allowed'] ?? item['is_allowed_zone'] ?? '-').toString();
        final z2 = (item['end_zone'] ?? item['zone_end'] ?? item['is_end_zone'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name)),
          DataCell(Text(fill)),
          DataCell(Text(stroke)),
          DataCell(Text(groups)),
          DataCell(Text(alpha)),
          DataCell(Text(beta)),
          DataCell(Text(cmds)),
          DataCell(Text(z1)),
          DataCell(Text(z2)),
          DataCell(Row(
            children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
            ],
          )),
        ]);
      },
    );
  }
}

final _geozonesPageSearchProvider = StateProvider<String>((ref) => '');
