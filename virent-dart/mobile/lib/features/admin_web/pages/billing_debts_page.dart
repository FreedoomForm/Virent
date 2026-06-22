import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class BillingDebtsPage extends ConsumerWidget {
  const BillingDebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Entries',
      provider: _debtorsProvider,
      searchProvider: _debtsSearchProvider,
      searchMatcher: (c, query) {
        final id = (c['id'] ?? '').toString().toLowerCase();
        final name = (c['name'] ?? c['full_name'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? '').toString().toLowerCase();
        return id.contains(query) || name.contains(query) || phone.contains(query);
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
          SizedBox(
            width: 150,
            child: TextField(
              decoration: adminFilterDecoration(hint: 'ID заказа'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: () => showAdminInfoDialog(context, 'Дата', 'Выберите период дат'), icon: const Icon(Icons.calendar_today, size: 16), label: const Text('Дата')),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(_debtsSearchProvider.notifier).state = '';
              showAdminSnack(context, 'Фильтры сброшены');
            },
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Очистить фильтры'),
            style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Client')),
        DataColumn(label: Text('Order')),
        DataColumn(label: Text('General order sum')),
        DataColumn(label: Text('Total sum')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (c) {
        final id = (c['id'] ?? '-').toString();
        final name = (c['name'] ?? c['full_name'] ?? (c['phone'] ?? '-')).toString();
        final order = (c['order_id'] ?? c['last_order_id'] ?? '-').toString();
        final generalSum = (c['general_order_sum'] ?? c['order_sum'] ?? '-').toString();
        final total = (c['balance'] ?? c['debt'] ?? c['total_sum'] ?? 0).toString();
        final status = (c['status'] ?? 'debt').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(name, style: adminLinkStyle)),
          DataCell(Text(order)),
          DataCell(Text(generalSum)),
          DataCell(Text(total)),
          DataCell(Text(status, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          DataCell(Row(
            children: [
              TextButton.icon(
                onPressed: () => showAdminViewDialog(
                  context,
                  title: 'Клиент #$id',
                  item: c,
                ),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Просмотр'),
              ),
              TextButton.icon(
                onPressed: () => showAdminFormDialog(
                  context,
                  title: 'Корректировать баланс #$id',
                  isEdit: true,
                  fields: [
                    AdminField(key: 'balance', label: 'Баланс', initial: total),
                    AdminField(key: 'reason', label: 'Причина', multiline: true),
                  ],
                  onSubmit: (values) async {
                    final delta = int.tryParse(values['balance']?.toString() ?? '') ?? 0;
                    final reason = (values['reason'] ?? '').toString();
                    await ref.read(adjustBalanceAction)(id, delta, reason);
                  },
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Редактировать'),
              ),
            ],
          )),
        ]);
      },
    );
  }
}

/// Provider that filters customers to only debtors (negative balance)
/// and sorts by debt ascending (biggest debt first).
final _debtorsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final customers = await ref.watch(customersListProvider.future);
  final debtors = customers.where((c) {
    final bal = (c['balance'] ?? c['debt'] ?? 0);
    final n = bal is num ? bal : num.tryParse(bal.toString()) ?? 0;
    return n < 0;
  }).toList()
    ..sort((a, b) {
      final ba = (a['balance'] ?? a['debt'] ?? 0);
      final bb = (b['balance'] ?? b['debt'] ?? 0);
      final na = ba is num ? ba : num.tryParse(ba.toString()) ?? 0;
      final nb = bb is num ? bb : num.tryParse(bb.toString()) ?? 0;
      return na.compareTo(nb);
    });
  return debtors;
});

final _debtsSearchProvider = StateProvider<String>((ref) => '');
