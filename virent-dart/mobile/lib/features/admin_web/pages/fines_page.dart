import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class FinesPage extends ConsumerWidget {
  const FinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Штрафы',
      provider: finesListProvider,
      searchProvider: _finesSearchProvider,
      searchMatcher: (f, query) {
        final id = (f['id'] ?? '').toString().toLowerCase();
        final cid = (f['client_id'] ?? f['clientId'] ?? '').toString().toLowerCase();
        final desc = (f['description'] ?? '').toString().toLowerCase();
        final bill = (f['bill_id'] ?? '').toString().toLowerCase();
        return id.contains(query) || cid.contains(query) || desc.contains(query) || bill.contains(query);
      },
      filters: Row(
        children: [
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'ID клиента'),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(finesListProvider);
              showAdminSnack(context, 'Фильтры очищены');
            },
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Очистить'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.black, elevation: 0),
          ),
        ],
      ),
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
      buildRow: (f) {
        String _s(String key) => (f[key] ?? '').toString();
        final id = _s('id');
        final cid = _s('client_id');
        final amt = _s('amount');
        final hid = _s('hold_id');
        final oid = _s('order_id');
        final bid = _s('bill_id');
        final desc = _s('description');
        final time = _s('timestamp_response') == '' ? _s('timestamp') : _s('timestamp_response');
        final st = _s('status');
        final pan = _s('card_pan');
        final tid = _s('transaction_id');
        final utid = _s('uzcard_transaction_id');
        final up = _s('updated_at');
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(cid, style: adminLinkStyle)),
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
          DataCell(st == 'HOLD'
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => showAdminSnack(context, 'Холд подтверждён'),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Подтвердить холд', style: TextStyle(color: Colors.blue)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => showAdminSnack(context, 'Холд отменён'),
                      icon: const Icon(Icons.cancel, size: 14),
                      label: const Text('Отменить холд'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                )
              : const SizedBox()),
        ]);
      },
    );
  }
}

final _finesSearchProvider = StateProvider<String>((ref) => '');
