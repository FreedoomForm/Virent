import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class ClickTransactionsPage extends ConsumerWidget {
  const ClickTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Транзакции CLICK',
      provider: clickTransactionsProvider,
      searchProvider: _clickSearchProvider,
      searchMatcher: (t, query) {
        final id = (t['id'] ?? '').toString().toLowerCase();
        final trans = (t['click_trans_id'] ?? t['click_paydoc_id'] ?? '').toString().toLowerCase();
        final merchant = (t['merchant_trans_id'] ?? '').toString().toLowerCase();
        return id.contains(query) || trans.contains(query) || merchant.contains(query);
      },
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
      buildRow: (t) {
        String _s(String key) => (t[key] ?? '').toString();
        return DataRow(cells: [
          DataCell(Text(_s('id'))),
          DataCell(Text(_s('click_trans_id'))),
          DataCell(Text(_s('click_paydoc_id'))),
          DataCell(Text(_s('merchant_trans_id'))),
          DataCell(Text(_s('merchant_prepare_id'))),
          DataCell(Text(_s('merchant_confirm_id'))),
          DataCell(Text(_s('amount'))),
          DataCell(Text(_s('action'))),
          DataCell(Text(_s('status'))),
          DataCell(Text(_s('error'))),
          DataCell(Text(_s('error_note'))),
          DataCell(Text(_s('sign_time'))),
          DataCell(Text(_s('created_at'))),
          DataCell(Text(_s('updated_at'))),
          DataCell(Text(_s('status') == 'HOLD' ? 'Подтвердить холд' : '')),
        ]);
      },
    );
  }
}

final _clickSearchProvider = StateProvider<String>((ref) => '');
