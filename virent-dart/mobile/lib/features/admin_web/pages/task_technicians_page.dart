import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';


class TaskTechniciansPage extends ConsumerWidget {
  const TaskTechniciansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(techTasksProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
      data: (items) {
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
            onPressed: () {},
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
            child: Card(
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
                    rows: const [],
                  ),
                ),
              ),
            ),
          ),
          const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('В таблице нет доступных данных', style: TextStyle(color: Colors.grey)),
          ))
        ],
      ),
    );
  )
  },
);
  }
}
