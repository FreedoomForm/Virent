import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class InspectionDamagesPage extends ConsumerWidget {
  const InspectionDamagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Осмотр Повреждений',
      provider: inspectionDamagesProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      filters: Row(children:[SizedBox(width:120,child:TextField(decoration:adminFilterDecoration(hint:"Самокат"))),SizedBox(width:8),SizedBox(width:120,child:TextField(decoration:adminFilterDecoration(hint:"Номер"))),SizedBox(width:8),Text("Конкретный день ▼"),SizedBox(width:16),Text("Промежуток времени ▼"),SizedBox(width:16),OutlinedButton(onPressed:(){},child:Text("Группировать")),SizedBox(width:8),OutlinedButton(onPressed:(){},child:Text("Фото при начале")),SizedBox(width:8),OutlinedButton(onPressed:(){},child:Text("Фото при завершении",style:TextStyle(color:Colors.orange))),SizedBox(width:8),ElevatedButton.icon(onPressed:(){},icon:Icon(Icons.clear,size:16),label:Text("Очистить фильтры"),style:ElevatedButton.styleFrom(backgroundColor:adminPrimaryColor,foregroundColor:adminPrimaryForeground))]),
      columns: const [
        DataColumn(label: Text('Path')),
        DataColumn(label: Text('Car')),
        DataColumn(label: Text('Order')),
        DataColumn(label: Text('Type')),
      ],
      buildRow: (item) {
        final path = (item['path'] ?? item['image_url'] ?? item['photo'] ?? '-').toString();
        final car = (item['car'] ?? item['scooter_id'] ?? item['car_id'] ?? '-').toString();
        final order = (item['order'] ?? item['order_id'] ?? '-').toString();
        final type = (item['type'] ?? item['inspection_type'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(path)),
          DataCell(Text(car)),
          DataCell(Text(order)),
          DataCell(Text(type)),
        ]);
      },
    );
  }
}

final _inspectionDamagesPageSearchProvider = StateProvider<String>((ref) => '');
