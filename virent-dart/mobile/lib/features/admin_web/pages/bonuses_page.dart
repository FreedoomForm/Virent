import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class BonusesPage extends ConsumerWidget {
  const BonusesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Бонусы',
      provider: bonusesListProvider,
      searchProvider: _bonusesSearchProvider,
      searchMatcher: (b, query) {
        final id = (b['id'] ?? '').toString().toLowerCase();
        final client = (b['client_id'] ?? b['client'] ?? '').toString().toLowerCase();
        final comment = (b['comment'] ?? '').toString().toLowerCase();
        return id.contains(query) || client.contains(query) || comment.contains(query);
      },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Client')),
        DataColumn(label: Text('Bonus sum')),
        DataColumn(label: Text('Who added')),
        DataColumn(label: Text('Create time')),
        DataColumn(label: Text('Comment')),
        DataColumn(label: Text('Company')),
      ],
      buildRow: (b) {
        String _s(String key) => (b[key] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(_s('id'))),
          DataCell(Text(_s('client_id'), style: adminLinkStyle)),
          DataCell(Text(_s('bonus_sum') == '-' ? _s('sum') : _s('bonus_sum'))),
          DataCell(Text(_s('who_added') == '-' ? _s('added_by') : _s('who_added'))),
          DataCell(Text(_s('create_time') == '-' ? _s('created_at') : _s('create_time'))),
          DataCell(Text(_s('comment'))),
          DataCell(Text(_s('company_id') == '-' ? _s('company') : _s('company_id'))),
        ]);
      },
    );
  }
}

final _bonusesSearchProvider = StateProvider<String>((ref) => '');
