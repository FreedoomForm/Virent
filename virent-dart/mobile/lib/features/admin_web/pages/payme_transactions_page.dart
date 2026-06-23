import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class PaymeTransactionsPage extends ConsumerWidget {
  const PaymeTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Транзакции Payme',
      provider: paymeTransactionsProvider,
      searchProvider: _paymeSearchProvider,
      searchMatcher: (t, query) {
        final id = (t['id'] ?? '').toString().toLowerCase();
        final trans = (t['payme_transaction'] ?? t['payme_time'] ?? '').toString().toLowerCase();
        final merchant = (t['merchant_transaction'] ?? '').toString().toLowerCase();
        final phone = (t['phone'] ?? '').toString().toLowerCase();
        return id.contains(query) || trans.contains(query) || merchant.contains(query) || phone.contains(query);
      },
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
      buildRow: (t) {
        String _s(String key) => (t[key] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(_s('id'))),
          DataCell(Text(_s('payme_transaction'))),
          DataCell(Text(_s('merchant_transaction'))),
          DataCell(Text(_s('payme_time'))),
          DataCell(Text(_s('state_description'))),
          DataCell(Text(_s('amount'))),
          DataCell(Text(_s('phone'))),
          DataCell(TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Редактировать'),
          )),
        ]);
      },
    );
  }
}

final _paymeSearchProvider = StateProvider<String>((ref) => '');
