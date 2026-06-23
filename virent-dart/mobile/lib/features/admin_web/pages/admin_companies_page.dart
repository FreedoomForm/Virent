import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class AdminCompaniesPage extends ConsumerWidget {
  const AdminCompaniesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCompaniesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Companies', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 7 из 7 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить company', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B68EE),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: 200,
                    height: 32,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Поиск:',
                        hintStyle: const TextStyle(fontSize: 11),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF8F9FA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 100, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Cp pub', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 250, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _companyRow('12', 'ViRent', '1002'),
                      _companyRow('16', 'ИП Асилбеков Шерзод', '1746'),
                      _companyRow('18', 'Virent Motion Samarqand', '1295'),
                      _companyRow('19', 'VV-LAND', '1409'),
                      _companyRow('22', 'ИП Асилбекова Нигора', ''),
                      _companyRow('23', 'ИП Раматбоев Озод', ''),
                      _companyRow('24', 'ИП Руфатова Зухра', ''),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Container(
                  color: const Color(0xFFF8F9FA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 100, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Cp pub', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 250, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _companyRow(String id, String name, String cpPub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(id, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text(cpPub, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 250,
            child: Row(
              children: [
                InkWell(onTap: () {}, child: const Row(children: [Icon(Icons.visibility, size: 12, color: Color(0xFF3498DB)), SizedBox(width: 4), Text('Просмотр', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))])),
                const SizedBox(width: 12),
                InkWell(onTap: () {}, child: const Row(children: [Icon(Icons.edit, size: 12, color: Color(0xFF3498DB)), SizedBox(width: 4), Text('Редактировать', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))])),
                const SizedBox(width: 12),
                InkWell(onTap: () {}, child: const Row(children: [Icon(Icons.delete, size: 12, color: Color(0xFF3498DB)), SizedBox(width: 4), Text('Удалить', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
