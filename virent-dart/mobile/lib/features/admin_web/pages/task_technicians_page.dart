import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class TaskTechniciansPage extends ConsumerWidget {
  const TaskTechniciansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Task_techicians',
      provider: techTasksProvider,
      searchProvider: _taskTechSearchProvider,
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить задачу',
          fields: const [
            AdminField(key: 'title', label: 'Название'),
            AdminField(key: 'technician', label: 'Техник'),
            AdminField(key: 'description', label: 'Описание', multiline: true),
          ],
          onSubmit: (values) async {
            await ref.read(genericCreateAction)(
              '/admin/tech-tasks',
              values,
              techTasksProvider,
            );
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить tasktechnician'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      filters: SizedBox(
        width: 200,
        child: TextField(
          decoration: adminFilterDecoration(hint: 'columns.tasktechnician.technician_id'),
        ),
      ),
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
      buildRow: (item) {
        String _s(String key) => (item[key] ?? '-').toString();
        final id = _s('id');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(_s('title'))),
          DataCell(Text(_s('technician'))),
          DataCell(Text(_s('description'))),
          DataCell(Text(_s('created_by'))),
          DataCell(Text(_s('created_at'))),
          DataCell(Text(_s('completed'))),
          DataCell(Text(_s('finished_at'))),
          DataCell(Text(_s('finished_by'))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(
                  context,
                  title: 'Задача #$id',
                  item: item,
                ),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Редактировать задачу #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'title', label: 'Название', initial: _s('title')),
                    AdminField(key: 'technician', label: 'Техник', initial: _s('technician')),
                    AdminField(key: 'description', label: 'Описание', multiline: true, initial: _s('description')),
                    AdminField(key: 'completed', label: 'Завершена (0/1)', initial: _s('completed')),
                  ],
                  onSubmit: (values) async {
                    await ref.read(genericUpdateAction)('/admin/tech-tasks', id, values, techTasksProvider);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
              TextButton.icon(
                onPressed: () => showAdminDeleteDialog(
                  context,
                  name: _s('title'),
                  onDelete: () async {
                    await ref.read(genericDeleteAction)('/admin/tech-tasks', id, techTasksProvider);
                  },
                ),
                icon: const Icon(Icons.delete, size: 14),
                label: const Text('Удалить'),
              ),
            ],
          )),
        ]);
      },
    );
  }
}

final _taskTechSearchProvider = StateProvider<String>((ref) => '');
