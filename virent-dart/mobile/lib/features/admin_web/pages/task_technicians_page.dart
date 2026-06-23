import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class TaskTechniciansPage extends ConsumerWidget {
  const TaskTechniciansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Task_techicians', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 0 до 0 из 0 совпадений', style: TextStyle(color: Colors.grey)),
                  )),
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Поиск...',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () { /* action */ },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Добавить tasktechnician'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'columns.tasktechnician.technician_id',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ref.watch(techTasksProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Ошибка: $e')),
              data: (items) => items.isEmpty
                ? const Center(child: Text('В таблице нет доступных данных', style: TextStyle(color: Colors.grey)))
                : Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
                    elevation: 0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    columns: const [
                      DataColumn(label: Text('Id')),
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Technician')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Create by')),
                      DataColumn(label: Text('Create time')),
                      DataColumn(label: Text('Завершен')),
                      DataColumn(label: Text('Finish time')),
                      DataColumn(label: Text('Finish by')),
                      DataColumn(label: Text('Действия')),
                    ],
                    rows: items.map((item) => DataRow(cells: [
                      DataCell(Text(item['id']?.toString() ?? '')),
                      DataCell(Text(item['title']?.toString() ?? '')),
                      DataCell(Text(item['technician']?.toString() ?? '')),
                      DataCell(Text(item['description']?.toString() ?? '')),
                      DataCell(Text(item['create_by']?.toString() ?? '')),
                      DataCell(Text(item['create_time']?.toString() ?? '')),
                      DataCell(Text(item['finished']?.toString() ?? '')),
                      DataCell(Text(item['finish_time']?.toString() ?? '')),
                      DataCell(Text(item['finish_by']?.toString() ?? '')),
                      DataCell(Row(children: [
                        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Ред.')),
                      ])),
                    ])).toList(),
                  ),
                ),
              ),
            ),
          ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
