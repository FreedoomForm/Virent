import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class ScootersPage extends ConsumerWidget {
  const ScootersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Самокаты',
      provider: scootersListProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      createButton: ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.add, size:16),label:const Text("Добавить самокат"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),
      filters: SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[SizedBox(width:120,child:TextField(decoration:adminFilterDecoration(hint:"Номер"))),SizedBox(width:8),SizedBox(width:200,child:TextField(decoration:adminFilterDecoration(hint:"Комментарий"))),SizedBox(width:8),SizedBox(width:80,child:TextField(decoration:adminFilterDecoration(hint:"От (%)"))),SizedBox(width:8),SizedBox(width:80,child:TextField(decoration:adminFilterDecoration(hint:"До (%)"))),SizedBox(width:8),ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.arrow_drop_down, size:16),label:const Text("Модель"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),SizedBox(width:8),ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.arrow_drop_down, size:16),label:const Text("Группы"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),SizedBox(width:8),ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.arrow_drop_down, size:16),label:const Text("Компания"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground)),SizedBox(width:8),ElevatedButton.icon(onPressed:(){},icon:const Icon(Icons.arrow_drop_down, size:16),label:const Text("Геозоны"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground))])),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Gosnomer')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Locks')),
        DataColumn(label: Text('Battery')),
        DataColumn(label: Text('Speed')),
        DataColumn(label: Text('Geozones')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final gosnomer = (item['gosnomer'] ?? item['plate_number'] ?? '-').toString();
        final status = (item['status'] ?? '-').toString();
        final locks = (item['locks'] ?? item['lock_status'] ?? '-').toString();
        final battery = (item['battery'] ?? item['battery_level'] ?? '-').toString();
        final speed = (item['speed'] ?? item['current_speed'] ?? '-').toString();
        final geo = (item['geozones'] ?? item['geo'] ?? item['zone_names'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(gosnomer)),
          DataCell(Text(status)),
          DataCell(Text(locks)),
          DataCell(Text(battery)),
          DataCell(Text(speed)),
          DataCell(Text(geo)),
          DataCell(Row(
            children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
            ],
          )),
        ]);
      },
    );
  }
}

final _scootersPageSearchProvider = StateProvider<String>((ref) => '');
