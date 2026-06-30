import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_export.dart';
import '../widgets/admin_status_tabs.dart';

class TariffsSubscriptionsPage extends ConsumerStatefulWidget {
  const TariffsSubscriptionsPage({super.key});
  @override
  ConsumerState<TariffsSubscriptionsPage> createState() => _TariffsSubscriptionsPageState();
}

class _TariffsSubscriptionsPageState extends ConsumerState<TariffsSubscriptionsPage> {
  final _searchController = TextEditingController();
  final _selectedIds = <dynamic>{};
  String _query = '';
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tariffSubscriptionsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
      data: (items) {
        var filtered = items;
        if (_query.isNotEmpty) {
          filtered = filtered.where((i) => i.values.any((v) => v != null && v.toString().toLowerCase().contains(_query.toLowerCase()))).toList();
        }
        final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 9999);
        final pageItems = filtered.skip((_currentPage - 1) * _pageSize).take(_pageSize).toList();
        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Text('Подписочные тарифы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF1B2A4E))),
                        const SizedBox(width: 12),
                        Text('Показано ${filtered.length} совпадений', style: const TextStyle(fontSize: 11, color: Color(0xFF868686))),
                      ]),
                      ElevatedButton.icon(
                      onPressed: () => showAdminFormDialog(context, title: 'Добавить подписочный тариф', fields: const [AdminField(key: 'name', label: 'Name'), AdminField(key: 'name_app', label: 'Name in app'), AdminField(key: 'price', label: 'Price'), AdminField(key: 'group', label: 'Group')], onSubmit: (v) async { ref.invalidate(tariffSubscriptionsProvider); }),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить подписочный тариф', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C69EF), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3))),
                    )
                    ]),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.download, size: 18, color: Color(0xFF6D737A)), tooltip: 'Экспорт', onPressed: () => showAdminExportDialog(context, title: 'Экспорт', fields: [AdminField(key: 'name', label: 'Name'), AdminField(key: 'name_app', label: 'Name in app'), AdminField(key: 'price', label: 'Price'), AdminField(key: 'group', label: 'Group')], onExport: (fmt, fields) async {})),
                      IconButton(icon: const Icon(Icons.filter_list, size: 18, color: Color(0xFF6D737A)), tooltip: 'Фильтры', onPressed: () => showAdminFilterDialog(context, title: 'Фильтры', fields: const [AdminField(key: 'name', label: 'Name'), AdminField(key: 'name_app', label: 'Name in app'), AdminField(key: 'price', label: 'Price'), AdminField(key: 'group', label: 'Group')], onApply: (v) async {})),
                      SizedBox(width: 200, child: TextField(controller: _searchController, onChanged: (v) => setState(() { _query = v; _currentPage = 1; }), decoration: const InputDecoration(hintText: 'Поиск...', prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF868686)), filled: true, fillColor: Color(0xFFF1F4F8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Color(0xFFD9E2EF))), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true))),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AdminStatusTabsRow(badges: [AdminStatusBadge(label: 'Всего', count: filtered.length, color: const Color(0xFF7C69EF))]),
              const SizedBox(height: 8),
              if (_selectedIds.isNotEmpty) _buildBulkActionBar(),
              Expanded(child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFD9E2EF))), child: SingleChildScrollView(child: DataTable(headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B2A4E)),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) return const Color(0xFFF1F4F8);
              return Colors.white;
            }),
            dataRowMinHeight: 40,
            dataRowMaxHeight: 40,
            columnSpacing: 24,
            horizontalMargin: 12,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F4F8)), columns: [const DataColumn(label: Text('')), const DataColumn(label: Text('Name')), const DataColumn(label: Text('Name in app')), const DataColumn(label: Text('Price')), const DataColumn(label: Text('Group')), const DataColumn(label: Text('Active')), const DataColumn(label: Text('Действия'))], rows: pageItems.map((i) => _buildRow(context, ref, i)).toList())))),
              _buildPaginationBar(filtered.length, totalPages),
            ],
          ),
        );
      },
    );
  }

  DataRow _buildRow(BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    return DataRow(cells: [
      DataCell(Checkbox(value: _selectedIds.contains(item['id']), onChanged: (_) => setState(() { if (_selectedIds.contains(item['id'])) { _selectedIds.remove(item['id']); } else { _selectedIds.add(item['id']); } }))),
      DataCell(Text('${item['name'] ?? ''}'))
      DataCell(Text('${item['name_app'] ?? ''}'))
      DataCell(Text('${item['price'] ?? ''}'))
      DataCell(Text('${item['group'] ?? ''}'))
      DataCell(Text('${item['active'] ?? ''}'))
      DataCell(Row(children: [
        TextButton.icon(onPressed: () => showAdminViewDialog(context, title: 'Просмотр', item: item), icon: const Icon(Icons.visibility, size: 12, color: Color(0xFF467FD0)), label: const Text('Просмотр', style: TextStyle(fontSize: 10, color: Color(0xFF467FD0)))),
        TextButton.icon(onPressed: () => showAdminFormDialog(context, title: 'Редактировать', fields: [AdminField(key: 'name', label: 'Name', initial: '${item[\'name\'] ?? \'\'}'), AdminField(key: 'name_app', label: 'Name in app', initial: '${item[\'name_app\'] ?? \'\'}'), AdminField(key: 'price', label: 'Price', initial: '${item[\'price\'] ?? \'\'}'), AdminField(key: 'group', label: 'Group', initial: '${item[\'group\'] ?? \'\'}')], onSubmit: (v) async { ref.invalidate(tariffSubscriptionsProvider); }, isEdit: true), icon: const Icon(Icons.edit, size: 12, color: Color(0xFF467FD0)), label: const Text('Редактировать', style: TextStyle(fontSize: 10, color: Color(0xFF467FD0)))),
        TextButton.icon(onPressed: () => showAdminDeleteDialog(context, name: 'Подписочные тарифы', onDelete: () async { ref.invalidate(tariffSubscriptionsProvider); }), icon: const Icon(Icons.delete, size: 12, color: Color(0xFFDF4759)), label: const Text('Удалить', style: TextStyle(fontSize: 10, color: Color(0xFFDF4759)))),
      ])),
    ]);
  }

  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF1F4F8),
      child: Row(children: [
        Text('Выбрано: ${_selectedIds.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        TextButton.icon(onPressed: () => showAdminBulkActionDialog(context, title: 'Удалить', message: 'Удалить выбранные?', selectedCount: _selectedIds.length, onConfirm: () async { _selectedIds.clear(); }), icon: const Icon(Icons.delete, size: 14, color: Color(0xFFDF4759)), label: const Text('Удалить', style: TextStyle(color: Color(0xFFDF4759), fontSize: 11))),
        const Spacer(),
        TextButton(onPressed: () => setState(() => _selectedIds.clear()), child: const Text('Отменить', style: TextStyle(fontSize: 11))),
      ]),
    );
  }

  Widget _buildPaginationBar(int total, int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(alignment: WrapAlignment.spaceBetween, children: [
        Text('Показано ${min(_currentPage * _pageSize, total)} из $total', style: const TextStyle(fontSize: 11, color: Color(0xFF868686))),
        Row(children: [
          IconButton(icon: const Icon(Icons.chevron_left, size: 16), onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
          Text('$_currentPage / $totalPages', style: const TextStyle(fontSize: 11)),
          IconButton(icon: const Icon(Icons.chevron_right, size: 16), onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
        ]),
      ]),
    );
  }
}
