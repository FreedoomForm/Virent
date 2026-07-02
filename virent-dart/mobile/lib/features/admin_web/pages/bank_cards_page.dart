import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_export.dart';
import '../widgets/admin_status_tabs.dart';
import '../widgets/admin_colors.dart';

class BankCardsPage extends ConsumerStatefulWidget {
  const BankCardsPage({super.key});
  @override
  ConsumerState<BankCardsPage> createState() => _BankCardsPageState();
}

class _BankCardsPageState extends ConsumerState<BankCardsPage> {
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
    final async = ref.watch(bankCardsProvider);
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
                        const Text('Банковские карты', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        const SizedBox(width: 12),
                        Text('Показано ${filtered.length} совпадений', style: const TextStyle(fontSize: 11, color: adminTextGray)),
                      ]),
                      ElevatedButton.icon(
                        onPressed: () => showAdminFormDialog(context, title: 'Добавить карту', fields: const [AdminField(key: 'client_id', label: 'ID клиента'), AdminField(key: 'card_number', label: 'Номер карты')], onSubmit: (values) async { await ref.read(genericCreateAction)('/admin/bank-cards', values, bankCardsProvider); }),
                        icon: const Icon(Icons.add, size: 14, color: Colors.white),
                        label: const Text('Добавить карту', style: TextStyle(fontSize: 11, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: adminPrimary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3))))
                    ]),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.download, size: 18, color: adminTextSecondary), tooltip: 'Экспорт', onPressed: () => showAdminExportDialog(context, title: 'Экспорт', fields: ['id', 'client', 'holder_name', 'bank_name', 'country', 'card_number', 'token', 'card_type', 'deleted'], onExport: (fmt, fields) async {})),
                      IconButton(icon: const Icon(Icons.filter_list, size: 18, color: adminTextSecondary), tooltip: 'Фильтры', onPressed: () => showAdminFilterDialog(context, title: 'Фильтры', fields: const [AdminField(key: 'client', label: 'Client'), AdminField(key: 'holder_name', label: 'Holder name'), AdminField(key: 'card_type', label: 'Card type')], onApply: (v) async {})),
                      SizedBox(width: 200, child: TextField(controller: _searchController, onChanged: (v) => setState(() { _query = v; _currentPage = 1; }), onSubmitted: (v) => setState(() { _query = v; _currentPage = 1; }), decoration: InputDecoration(hintText: 'Поиск...', prefixIcon: Icon(Icons.search, size: 18, color: adminTextGray), filled: true, fillColor: adminBgLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: adminBorder)), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true))),
                    ]),
                  ])),
              const SizedBox(height: 8),
              AdminStatusTabsRow(badges: [AdminStatusBadge(label: 'Всего', count: filtered.length, color: adminPrimary)]),
              const SizedBox(height: 8),
              if (_selectedIds.isNotEmpty) _buildBulkActionBar(context),
              Expanded(child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: adminBorder)), child: pageItems.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inbox, size: 40, color: adminBorder), SizedBox(height: 8), Text('Нет данных', style: TextStyle(color: adminTextGray, fontSize: 13))]))) : SingleChildScrollView(child: DataTable(headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: adminTextDark),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) return adminBgLight;
              return Colors.white;
            }),
            dataRowMinHeight: 40,
            dataRowMaxHeight: 40,
            columnSpacing: 24,
            horizontalMargin: 12,
                    headingRowColor: WidgetStateProperty.all(adminBgLight), columns: [const DataColumn(label: Text('')), const DataColumn(label: Text('Id')), const DataColumn(label: Text('Client')), const DataColumn(label: Text('Holder name')), const DataColumn(label: Text('Bank name')), const DataColumn(label: Text('Country')), const DataColumn(label: Text('Card number')), const DataColumn(label: Text('Token')), const DataColumn(label: Text('Card type')), const DataColumn(label: Text('Deleted')), const DataColumn(label: Text('Действия'))], rows: pageItems.map<DataRow>((i) => _buildRow(context, ref, i)).toList())))),
              _buildPaginationBar(filtered.length, totalPages),
            ]));
      });
  }

  DataRow _buildRow(BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    return DataRow(cells: [
      DataCell(Checkbox(value: _selectedIds.contains(item['id']), onChanged: (_) => setState(() { if (_selectedIds.contains(item['id'])) { _selectedIds.remove(item['id']); } else { _selectedIds.add(item['id']); } }))),
      DataCell(Text("${item['id'] ?? ''}")),
      DataCell(Text("${item['client'] ?? ''}")),
      DataCell(Text("${item['holder_name'] ?? ''}")),
      DataCell(Text("${item['bank_name'] ?? ''}")),
      DataCell(Text("${item['country'] ?? ''}")),
      DataCell(Text("${item['card_number'] ?? ''}")),
      DataCell(Text("${item['token'] ?? ''}")),
      DataCell(Text("${item['card_type'] ?? ''}")),
      DataCell(Text("${item['deleted'] ?? ''}")),
      DataCell(Row(children: [
        TextButton.icon(onPressed: () => showAdminViewDialog(context, title: 'Просмотр', item: item), icon: const Icon(Icons.visibility, size: 12, color: adminInfo), label: const Text('Просмотр', style: TextStyle(fontSize: 10, color: adminInfo))),
        TextButton.icon(onPressed: () => showAdminFormDialog(context, title: 'Редактировать', fields: [AdminField(key: 'client', label: 'Client', initial: "${item['client'] ?? ''}"), AdminField(key: 'holder_name', label: 'Holder name', initial: "${item['holder_name'] ?? ''}"), AdminField(key: 'card_type', label: 'Card type', initial: "${item['card_type'] ?? ''}")], onSubmit: (v) async { ref.invalidate(bankCardsProvider); }, isEdit: true), icon: const Icon(Icons.edit, size: 12, color: adminInfo), label: const Text('Редактировать', style: TextStyle(fontSize: 10, color: adminInfo))),
        TextButton.icon(onPressed: () => showAdminDeleteDialog(context, name: 'Банковская карта', onDelete: () async { ref.invalidate(bankCardsProvider); }), icon: const Icon(Icons.delete, size: 12, color: adminDanger), label: const Text('Удалить', style: TextStyle(fontSize: 10, color: adminDanger))),
      ])),
    ]);
  }

  Widget _buildBulkActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: adminBgLight,
      child: Row(children: [
        Text('Выбрано: ${_selectedIds.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        TextButton.icon(onPressed: () => showAdminBulkActionDialog(context, title: 'Удалить', message: 'Удалить выбранные?', selectedCount: _selectedIds.length, onConfirm: () async { _selectedIds.clear(); }), icon: const Icon(Icons.delete, size: 14, color: adminDanger), label: const Text('Удалить', style: TextStyle(color: adminDanger, fontSize: 11))),
        const Spacer(),
        TextButton(onPressed: () => setState(() => _selectedIds.clear()), child: const Text('Отменить', style: TextStyle(fontSize: 11))),
      ]));
  }

  Widget _buildPaginationBar(int total, int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(alignment: WrapAlignment.spaceBetween, children: [
        Text('Показано ${min(_currentPage * _pageSize, total)} из $total', style: const TextStyle(fontSize: 11, color: adminTextGray)),
        Row(children: [
          IconButton(tooltip: 'Предыдущая страница', icon: const Icon(Icons.chevron_left, size: 16), onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
          Text('$_currentPage / $totalPages', style: const TextStyle(fontSize: 11)),
          IconButton(tooltip: 'Следующая страница', icon: const Icon(Icons.chevron_right, size: 16), onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
        ]),
      ]));
  }
}
