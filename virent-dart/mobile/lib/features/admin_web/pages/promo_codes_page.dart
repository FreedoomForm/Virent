import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';
import '../widgets/admin_dialogs.dart';

class PromoCodesPage extends ConsumerWidget {
  const PromoCodesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Промокоды',
      provider: promoCodesProvider,
      searchProvider: _promoSearchProvider,
      searchMatcher: (p, query) {
        final code = (p['code'] ?? '').toString().toLowerCase();
        final group = (p['group'] ?? p['promocode_group'] ?? '').toString().toLowerCase();
        return code.contains(query) || group.contains(query);
      },
      createButton: ElevatedButton.icon(
        onPressed: () => showAdminFormDialog(
          context,
          title: 'Добавить промокод',
          fields: const [
            AdminField(key: 'code', label: 'Код'),
            AdminField(key: 'discount', label: 'Скидка'),
            AdminField(key: 'type', label: 'Тип', hint: 'fixed / percent'),
            AdminField(key: 'usage_limit', label: 'Лимит использований', initial: '1'),
            AdminField(key: 'expires_at', label: 'Истекает', hint: 'YYYY-MM-DD'),
          ],
          onSubmit: (values) async {
            await ref.read(createPromoCodeAction)(values);
          },
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Добавить Промокод'),
        style: ElevatedButton.styleFrom(backgroundColor: adminPrimaryColor, foregroundColor: adminPrimaryForeground),
      ),
      columns: const [
        DataColumn(label: Text('Код')),
        DataColumn(label: Text('Скидка')),
        DataColumn(label: Text('Тип')),
        DataColumn(label: Text('Использовано')),
        DataColumn(label: Text('Лимит')),
        DataColumn(label: Text('Истекает')),
        DataColumn(label: Text('Статус')),
      ],
      buildRow: (p) {
        final code = (p['code'] ?? '-').toString();
        final discount = (p['discount'] ?? p['bonus_gift'] ?? p['bonus'] ?? '-').toString();
        final type = (p['type'] ?? p['discount_type'] ?? 'fixed').toString();
        final used = (p['used_count'] ?? p['usage_count'] ?? 0).toString();
        final limit = (p['limit'] ?? p['usage_limit'] ?? p['max_usage'] ?? 1).toString();
        final expires = (p['expires_at'] ?? p['expires'] ?? '-').toString();
        final isActive = (p['is_active'] ?? p['active'] ?? true) == true;
        return DataRow(cells: [
          DataCell(Text(code, style: adminLinkStyle)),
          DataCell(Text(discount)),
          DataCell(Text(type)),
          DataCell(Text(used)),
          DataCell(Text(limit)),
          DataCell(Text(expires)),
          DataCell(Icon(isActive ? Icons.check_box : Icons.check_box_outline_blank, color: isActive ? Colors.green : Colors.grey)),
        ]);
      },
    );
  }
}

final _promoSearchProvider = StateProvider<String>((ref) => '');
