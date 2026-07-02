import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_export.dart';
import '../widgets/admin_status_tabs.dart';
import '../widgets/admin_colors.dart';

class ScootersPage extends ConsumerStatefulWidget {
  const ScootersPage({super.key});
  @override
  ConsumerState<ScootersPage> createState() => _ScootersPageState();
}

class _ScootersPageState extends ConsumerState<ScootersPage> {
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
    final async = ref.watch(scootersListProvider);
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
                        const Text('Самокаты', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        const SizedBox(width: 12),
                        Text('Показано ${filtered.length} совпадений', style: const TextStyle(fontSize: 11, color: adminTextGray)),
                      ]),
                      const SizedBox.shrink()
                    ]),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.download, size: 18, color: adminTextSecondary), tooltip: 'Экспорт', onPressed: () => showAdminExportDialog(context, title: 'Экспорт', fields: ['id', 'gosnomer', 'gsm', 'battery', 'status', 'model', 'company'], onExport: (fmt, fields) async {})),
                      IconButton(icon: const Icon(Icons.filter_list, size: 18, color: adminTextSecondary), tooltip: 'Фильтры', onPressed: () => showAdminFilterDialog(context, title: 'Фильтры', fields: const [AdminField(key: 'gosnomer', label: 'Госномер'), AdminField(key: 'status', label: 'Статус'), AdminField(key: 'model', label: 'Модель')], onApply: (v) async {})),
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
                    headingRowColor: WidgetStateProperty.all(adminBgLight), columns: [const DataColumn(label: Text('')), const DataColumn(label: Text('ID')), const DataColumn(label: Text('Gosnomer')), const DataColumn(label: Text('GSM')), const DataColumn(label: Text('Battery')), const DataColumn(label: Text('Status')), const DataColumn(label: Text('Model')), const DataColumn(label: Text('Company')), const DataColumn(label: Text('Действия'))], rows: pageItems.map<DataRow>((i) => _buildRow(context, ref, i)).toList())))),
              _buildPaginationBar(filtered.length, totalPages),
            ]));
      });
  }

  DataRow _buildRow(BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    final battery = item['battery'] ?? item['battery_level'];
    final batteryNum = int.tryParse("${battery ?? ''}") ?? -1;
    Color batteryColor = adminDanger;
    if (batteryNum >= 60) batteryColor = adminSuccess;
    else if (batteryNum >= 25) batteryColor = adminWarning;
    final status = "${item['status'] ?? ''}";
    Color statusColor = adminTextGray;
    if (status.toLowerCase() == 'active' || status.toLowerCase() == 'riding' || status.toLowerCase() == 'активен') statusColor = adminSuccess;
    else if (status.toLowerCase() == 'idle' || status.toLowerCase() == 'ready') statusColor = adminInfo;
    else if (status.toLowerCase() == 'offline' || status.toLowerCase() == 'оффлайн') statusColor = adminDanger;
    else if (status.toLowerCase() == 'charging' || status.toLowerCase() == 'зарядка') statusColor = adminWarning;
    return DataRow(cells: [
      DataCell(Checkbox(value: _selectedIds.contains(item['id']), onChanged: (_) => setState(() { if (_selectedIds.contains(item['id'])) { _selectedIds.remove(item['id']); } else { _selectedIds.add(item['id']); } }))),
      DataCell(Text("${item['id'] ?? ''}")),
      DataCell(Text("${item['gosnomer'] ?? item['plate'] ?? ''}")),
      DataCell(Text("${item['gsm'] ?? item['imei'] ?? ''}", overflow: TextOverflow.ellipsis)),
      DataCell(Row(children: [Icon(batteryNum >= 60 ? Icons.battery_full : (batteryNum >= 25 ? Icons.battery_charging_full : Icons.battery_alert), size: 14, color: batteryColor), const SizedBox(width: 4), Text("$battery%", style: TextStyle(fontSize: 11, color: batteryColor))])),
      DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(3)), child: Text(status, style: const TextStyle(fontSize: 10, color: Colors.white)))),
      DataCell(Text("${item['model'] ?? item['model_name'] ?? ''}")),
      DataCell(Text("${item['company'] ?? item['company_id'] ?? ''}")),
      DataCell(Row(children: [
        TextButton.icon(onPressed: () => showAdminViewDialog(context, title: 'Просмотр', item: item), icon: const Icon(Icons.visibility, size: 12, color: adminInfo), label: const Text('Просмотр', style: TextStyle(fontSize: 10, color: adminInfo))),
        TextButton.icon(onPressed: () => showAdminFormDialog(context, title: 'Редактировать', fields: [AdminField(key: 'gosnomer', label: 'Госномер', initial: "${item['gosnomer'] ?? item['plate'] ?? ''}"), AdminField(key: 'status', label: 'Статус', initial: status), AdminField(key: 'model', label: 'Модель', initial: "${item['model'] ?? item['model_name'] ?? ''}")], onSubmit: (v) async { ref.invalidate(scootersListProvider); }, isEdit: true), icon: const Icon(Icons.edit, size: 12, color: adminInfo), label: const Text('Редактировать', style: TextStyle(fontSize: 10, color: adminInfo))),
        TextButton.icon(onPressed: () => showAdminDeleteDialog(context, name: 'Самокат', onDelete: () async { ref.invalidate(scootersListProvider); }), icon: const Icon(Icons.delete, size: 12, color: adminDanger), label: const Text('Удалить', style: TextStyle(fontSize: 10, color: adminDanger))),
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
        TextButton.icon(onPressed: () => showAdminBulkActionDialog(context, title: 'Удалить', message: 'Удалить выбранные самокаты?', selectedCount: _selectedIds.length, onConfirm: () async { _selectedIds.clear(); }), icon: const Icon(Icons.delete, size: 14, color: adminDanger), label: const Text('Удалить', style: TextStyle(color: adminDanger, fontSize: 11))),
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
