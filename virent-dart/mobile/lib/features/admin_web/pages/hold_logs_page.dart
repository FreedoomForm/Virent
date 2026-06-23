import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class HoldLogsPage extends ConsumerWidget {
  const HoldLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(holdLogsProvider);

    return asyncItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: \$e', style: const TextStyle(color: Colors.red))),
      data: (items) => Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hold Logs', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Row(
            children: [
               _buildFilterField('mm/dd/yyyy'),
               const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.calendar_today, size: 16)),
               _buildFilterField('mm/dd/yyyy'),
               const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.calendar_today, size: 16)),
               ElevatedButton(
                 onPressed: () {},
                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
                 child: const Text('Filter'),
               )
            ],
          ),
          const SizedBox(height: 16),
          // Table mockup
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
                      DataColumn(label: Text('transaction_id')),
                      DataColumn(label: Text('client_id')),
                      DataColumn(label: Text('type_request_1')),
                      DataColumn(label: Text('timestamp_type_request_1')),
                      DataColumn(label: Text('order_id')),
                      DataColumn(label: Text('amount')),
                      DataColumn(label: Text('request_source')),
                      DataColumn(label: Text('status_response_1')),
                    ],
                    rows: items.isEmpty ? [const DataRow(cells: [DataCell(Center(child: Text("В таблице нет доступных данных", style: TextStyle(color: Colors.grey))))])] : items.map(_buildItemRow).toList()                  ),
                ),
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
    final tid = (item['transaction_id'] ?? '').toString();
    final cid = (item['client_id'] ?? '').toString();
    final req = (item['type_request'] ?? '').toString();
    final time = (item['created_at'] ?? '').toString();
    final oid = (item['order_id'] ?? '').toString();
    final amount = (item['amount'] ?? '').toString();
    final src = (item['request_source'] ?? '').toString();
    final status = (item['status'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(tid)),
      DataCell(Text(cid, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(req)),
      DataCell(Text(time)),
      DataCell(Text(oid)),
      DataCell(Text(amount)),
      DataCell(Text(src)),
      DataCell(Text(status)),
    ]);
  
  }
}
