import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class TaskTechniciansPage extends ConsumerWidget {
  const TaskTechniciansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Задачи Техников',
      provider: techTasksProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Tech')),
        DataColumn(label: Text('Task')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Created')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final tech = (item['tech'] ?? item['technician'] ?? item['tech_id'] ?? '-').toString();
        final task = (item['task'] ?? item['description'] ?? item['title'] ?? '-').toString();
        final status = (item['status'] ?? '-').toString();
        final created = (item['created'] ?? item['created_at'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(tech)),
          DataCell(Text(task)),
          DataCell(Text(status)),
          DataCell(Text(created)),
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

final _taskTechniciansPageSearchProvider = StateProvider<String>((ref) => '');
