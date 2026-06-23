import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class PrepaidOrdersPage extends ConsumerWidget {
  const PrepaidOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(prepaidOrdersProvider);

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
              const Text('Предоплаченные Заказы', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 20 из 91 совпадений', style: TextStyle(color: Colors.grey)),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterField('ID клиента'),
                const SizedBox(width: 8),
                _buildFilterField('car_id'),
                const SizedBox(width: 8),
                _buildFilterField('status'),
                const SizedBox(width: 8),
                _buildFilterField('transaction_id', width: 200),
                const SizedBox(width: 8),
                _buildFilterField('order_id'),
              ],
            ),
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
                      DataColumn(label: Text('Id')),
                      DataColumn(label: Text('Redis token')),
                      DataColumn(label: Text('Car')),
                      DataColumn(label: Text('Client')),
                      DataColumn(label: Text('Company')),
                      DataColumn(label: Text('Abonement')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Created')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Действия')),
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

      ),
    );
  );
  Widget _buildFilterField(String hint, {double width = 120}) {
    return SizedBox(
      width: width,
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
    final token = (item['token'] ?? '').toString();
    final car = (item['car_id'] ?? '').toString();
    final client = (item['client_name'] ?? '').toString();
    final company = (item['company'] ?? '').toString();
    final abonement = (item['abonement_id'] ?? '').toString();
    final amount = (item['amount'] ?? '').toString();
    final status = (item['status'] ?? '').toString();
    final created = (item['created_at'] ?? '').toString();
    final type = (item['type'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(token)),
      DataCell(Text(car)),
      DataCell(Text(client, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(company)),
      DataCell(Text(abonement)),
      DataCell(Text(amount)),
      DataCell(Text(status)),
      DataCell(Text(created)),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        color: type == 'PAYME' ? Colors.green : Colors.blue,
        child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      )),
      DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
    ]);
  
  }
}