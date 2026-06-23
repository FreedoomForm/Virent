import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class SmsLogsPage extends ConsumerWidget {
  const SmsLogsPage({super.key});

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
              const Text('Entries', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 20 из 15,114 совпадений', style: TextStyle(color: Colors.grey)),
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
          // Table mockup
          Expanded(
            child: ref.watch(smsLogsProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Ошибка: $e')),
              data: (items) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
                elevation: 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('Id')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Sms code')),
                        DataColumn(label: Text('Sms try count')),
                        DataColumn(label: Text('Sms try count all')),
                        DataColumn(label: Text('Sms try login')),
                        DataColumn(label: Text('Create time')),
                        DataColumn(label: Text('Sms last attempt')),
                        DataColumn(label: Text('Check key')),
                        DataColumn(label: Text('Действия')),
                      ],
                      rows: items.isEmpty
                        ? [const DataRow(cells: [
                            DataCell(Text('Нет данных')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                          ])]
                        : items.map((item) => _buildRowFromItem(item)).toList(),
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

  /// Dynamic SMS log row from provider item.
  DataRow _buildRowFromItem(Map<String, dynamic> item) {
    return _buildRow(
      item['id']?.toString() ?? '',
      item['phone']?.toString() ?? '',
      item['sms_code']?.toString() ?? '',
      item['sms_try_count']?.toString() ?? '',
      item['sms_try_count_all']?.toString() ?? '',
      item['sms_try_login']?.toString() ?? '',
      item['create_time']?.toString() ?? '',
      item['sms_last_attempt']?.toString() ?? '',
      item['check_key']?.toString() ?? '',
    );
  }

  DataRow _buildRow(String id, String phone, String code, String t1, String t2, String t3, String ct, String la, String key) {
    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(phone)),
      DataCell(Text(code)),
      DataCell(Text(t1)),
      DataCell(Text(t2)),
      DataCell(Text(t3)),
      DataCell(Text(ct)),
      DataCell(Text(la)),
      DataCell(Text(key)),
      DataCell(Row(
        children: [
          TextButton.icon(onPressed: () { /* action */ }, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
          TextButton.icon(onPressed: () { /* action */ }, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
        ],
      )),
    ]);
  }
}
