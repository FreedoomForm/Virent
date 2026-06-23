import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class PromoCodesPage extends ConsumerWidget {
  const PromoCodesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Промокоды',
      provider: promoCodesProvider,
      searchProvider: _promoSearchProvider,
      searchMatcher: (p, query) {
        final id = (p['id'] ?? '').toString().toLowerCase();
        final code = (p['code'] ?? '').toString().toLowerCase();
        final group = (p['promocode_group'] ?? p['group'] ?? '').toString().toLowerCase();
        return id.contains(query) || code.contains(query) || group.contains(query);
      },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Code')),
        DataColumn(label: Text('Bonus gift')),
        DataColumn(label: Text('Usage remains')),
        DataColumn(label: Text('Promocode group')),
        DataColumn(label: Text('Group active')),
        DataColumn(label: Text('Expires')),
        DataColumn(label: Text('Действия')),
      ],
      buildRow: (p) {
        String _s(String key) => (p[key] ?? '-').toString();
        bool _b(String key) {
          final v = p[key];
          if (v == null) return false;
          if (v is bool) return v;
          return v.toString().toLowerCase() == '1' || v.toString().toLowerCase() == 'true';
        }
        return DataRow(cells: [
          DataCell(Text(_s('id'))),
          DataCell(Text(_s('code'))),
          DataCell(Text(_s('bonus_gift') == '-' ? _s('discount') : _s('bonus_gift'))),
          DataCell(Text(_s('usage_remains') == '-' ? _s('usage_limit') : _s('usage_remains'))),
          DataCell(Text(_s('promocode_group') == '-' ? _s('group') : _s('promocode_group'))),
          DataCell(Icon(_b('group_active') ? Icons.check : Icons.close, color: _b('group_active') ? Colors.green : Colors.red)),
          DataCell(Text(_s('expires_at') == '-' ? _s('expires') : _s('expires_at'))),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
            ],
          )),
        ]);
      },
    );
  }
}

final _promoSearchProvider = StateProvider<String>((ref) => '');
