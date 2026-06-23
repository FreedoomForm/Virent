import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class FinesPage extends ConsumerWidget {
  const FinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(finesListProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Штрафы', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ID клиента',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Очистить'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.black, elevation: 0),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              elevation: 0,
              child: asyncItems.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
                data: (items) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('client_id')),
                        DataColumn(label: Text('amount')),
                        DataColumn(label: Text('hold_id')),
                        DataColumn(label: Text('order_id')),
                        DataColumn(label: Text('bill_id')),
                        DataColumn(label: Text('description')),
                        DataColumn(label: Text('timestamp_response')),
                        DataColumn(label: Text('status')),
                        DataColumn(label: Text('CardPan')),
                        DataColumn(label: Text('TransactionId')),
                        DataColumn(label: Text('UzcardTransactionId')),
                        DataColumn(label: Text('updated_at')),
                        DataColumn(label: Text('Управление')),
                      ],
                      rows: items.map(_buildRow).toList(),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      )

  DataRow_buildRow(Map<String, dynamic> f) {
    final id = (f['id'] ?? '-').toString();
    final cid = (f['client_id'] ?? f['client'] ?? '-').toString();
    final amt = (f['amount'] ?? '-').toString();
    final hid = (f['hold_id'] ?? '').toString();
    final oid = (f['order_id'] ?? '').toString();
    final bid = (f['bill_id'] ?? '').toString();
    final desc = (f['description'] ?? '').toString();
    final time = (f['timestamp_response'] ?? f['created_at'] ?? '').toString();
    final st = (f['status'] ?? '').toString();
    final pan = (f['card_pan'] ?? f['CardPan'] ?? '').toString();
    final tid = (f['transaction_id'] ?? f['TransactionId'] ?? '').toString();
    final utid = (f['uzcard_transaction_id'] ?? f['UzcardTransactionId'] ?? '').toString();
    final up = (f['updated_at'] ?? '').toString();

    return DataRow(cells: [
      DataCell(Text(id)),
      DataCell(Text(cid, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(amt)),
      DataCell(Text(hid)),
      DataCell(Text(oid)),
      DataCell(Text(bid)),
      DataCell(Text(desc)),
      DataCell(Text(time)),
      DataCell(Text(st)),
      DataCell(Text(pan)),
      DataCell(Text(tid)),
      DataCell(Text(utid)),
      DataCell(Text(up)),
      DataCell(st == 'HOLD' ? Row(
        children: [
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.check, size: 14), label: const Text('Подтвердить холд', style: TextStyle(color: Colors.blue))),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.cancel, size: 14),
            label: const Text('Отменить холд'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
          )
        ],
      ) : const SizedBox()),
    ]);
    );
  ),
);
  }
}