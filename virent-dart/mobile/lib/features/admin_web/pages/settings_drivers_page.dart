import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class SettingsDriversPage extends ConsumerWidget {
  const SettingsDriversPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settingsDriversProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Entries', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 4 из 4 совпадений', style: TextStyle(color: Colors.grey)),
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
            onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Добавить entry'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C69EF), foregroundColor: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Color(0xFFD9E2EF))),
              elevation: 0,
              child: ListView(
                children: [
                  DataTable(
                    headingRowColor: WidgetStateProperty.all(Color(0xFFF1F4F8)),
                    columns: const [
                      DataColumn(label: Text('Id')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Действия')),
                    ],
                    rows: [
                      _buildRow('7', 'Ninebot', 'FLESPI'),
                      _buildRow('10', 'OKAI 400', 'FLESPI'),
                      _buildRow('11', 'ecu200', 'gospi'),
                      _buildRow('12', 'ecu201', 'gospi'),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
      },
    );
  }

  DataRow _buildRow(String id, String desc, String type) {
    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(desc)),
      DataCell(Text(type)),
      DataCell(Row(
        children: [
          TextButton.icon(onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр')),
          TextButton.icon(onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
          TextButton.icon(onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
        ],
      )),
    ]);
  }
}
