import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class PushHistoryPage extends ConsumerWidget {
  const PushHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(pushHistoryListProvider);

    return asyncItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: \$e', style: const TextStyle(color: Colors.red))),
      data: (items) => Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('История Push', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 20 из 1,274,438 совпадений', style: TextStyle(color: Colors.grey)),
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
          Row(
            children: [
              _buildFilterField('ID клиента'),
            ],
          ),
          const SizedBox(height: 16),
          // Table mockup
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              elevation: 0,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('Id')),
                    DataColumn(label: Text('Client')),
                    DataColumn(label: Text('Text')),
                    DataColumn(label: Text('Is read')),
                    DataColumn(label: Text('Deleted')),
                    DataColumn(label: Text('Created')),
                    DataColumn(label: Text('Client')),
                    DataColumn(label: Text('Действия')),
                  ],
                  rows: items.isEmpty ? [const DataRow(cells: [DataCell(Center(child: Text("В таблице нет доступных данных", style: TextStyle(color: Colors.grey))))])] : items.map(_buildItemRow).toList()                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterField(String hint) {
    return SizedBox(
      width: 150,
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  DataRow _buildItemRow(Map<String, dynamic> item) {
    final id = (item['id'] ?? '').toString();
    final clientId = (item['client_id'] ?? '').toString();
    final text = (item['text'] ?? '').toString();
    final isRead = (item['is_read'] ?? '').toString();
    final deleted = (item['deleted'] ?? '').toString();
    final created = (item['created_at'] ?? '').toString();
    final clientName = (item['client_name'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(clientId)),
      DataCell(Text(text)),
      DataCell(Text(isRead)),
      DataCell(Text(deleted)),
      DataCell(Text(created)),
      DataCell(Text(clientName, style: const TextStyle(color: Colors.blue))),
      DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
    ]);
  
  }
}
