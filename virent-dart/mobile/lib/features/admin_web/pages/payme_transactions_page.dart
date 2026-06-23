import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class PaymeTransactionsPage extends ConsumerWidget {
  const PaymeTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(paymeTransactionsProvider);

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
              const Text('Транзакции Payme', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 20 из 39 совпадений', style: TextStyle(color: Colors.grey)),
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
              const SizedBox(width: 8),
              _buildFilterField('payme_transaction_id', width: 200),
              const SizedBox(width: 8),
              _buildFilterField('state'),
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
                      DataColumn(label: Text('Id')),
                      DataColumn(label: Text('Payme transaction')),
                      DataColumn(label: Text('Merchant transaction')),
                      DataColumn(label: Text('payme_time (UTC ms)')),
                      DataColumn(label: Text('state description')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Phone')),
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

  Widget _buildFilterField(String hint, {double width = 150}) {
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
    final pt = (item['payme_transaction_id'] ?? '').toString();
    final mt = (item['merchant_transaction_id'] ?? '').toString();
    final time = (item['created_at'] ?? '').toString();
    final stateDesc = (item['state_description'] ?? '').toString();
    final amount = (item['amount'] ?? '').toString();
    final phone = (item['phone'] ?? '').toString();
    final stateColor = Colors.grey;

    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(pt)),
      DataCell(Text(mt)),
      DataCell(Text(time)),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: stateColor, borderRadius: BorderRadius.circular(4)),
        child: Text(stateDesc, style: const TextStyle(color: Colors.white, fontSize: 10)),
      )),
      DataCell(Text(amount)),
      DataCell(Text(phone)),
      DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
    ]);
  
  }
      ),
    ),
  );
}