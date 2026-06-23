import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class ClickTransactionsPage extends ConsumerWidget {
  const ClickTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(clickTransactionsProvider);

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
              const Text('Транзакции CLICK', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 5 из 5 совпадений', style: TextStyle(color: Colors.grey)),
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
               _buildFilterInput('merchant_trans_id'),
               const SizedBox(width: 8),
               _buildFilterInput('click_trans_id'),
               const SizedBox(width: 8),
               _buildFilterInput('status'),
               const SizedBox(width: 8),
               _buildFilterInput('error'),
            ],
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
                      DataColumn(label: Text('Click trans')),
                      DataColumn(label: Text('Click paydoc')),
                      DataColumn(label: Text('Merchant trans')),
                      DataColumn(label: Text('Merchant prepare')),
                      DataColumn(label: Text('Merchant confirm')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Action')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Error')),
                      DataColumn(label: Text('Error note')),
                      DataColumn(label: Text('Sign time')),
                      DataColumn(label: Text('Created')),
                      DataColumn(label: Text('Updated')),
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

  Widget _buildFilterInput(String hint) {
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
    final t1 = (item['click_trans_id'] ?? '').toString();
    final t2 = (item['click_paydoc_id'] ?? '').toString();
    final t3 = (item['merchant_trans_id'] ?? '').toString();
    final t4 = (item['merchant_prepare_id'] ?? '').toString();
    final t5 = (item['merchant_confirm_id'] ?? '').toString();
    final t6 = (item['amount'] ?? '').toString();
    final t7 = (item['action'] ?? '').toString();
    final t8 = (item['status'] ?? '').toString();
    final t9 = (item['error'] ?? '').toString();
    final t10 = (item['sign_time'] ?? '').toString();
    final t11 = (item['created_at'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(t1)),
      DataCell(const Text('')),
      DataCell(Text(t2)),
      DataCell(Text(t3)),
      DataCell(Text(t4)),
      DataCell(Text(t5)),
      DataCell(Text(t6)),
      DataCell(Text(t7)),
      DataCell(Text(t8)),
      DataCell(Text(t9)),
      DataCell(Text(t10)),
      DataCell(Text(t11)),
      DataCell(Text(t11)),
      DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
    ]);
  
  }
}
