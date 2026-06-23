import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class PromoSeriesPage extends ConsumerWidget {
  const PromoSeriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(promoSeriesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return Container(
      color: const Color(0xFFFFFFFF),
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
                        Text('Серии Промокодов', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 4 из 4 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить Серия промокодов', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B68EE),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  ],
                ),
                SizedBox(
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 100, child: Text('ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 300, child: Text('Название', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Активна', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _seriesRow('5', 'test', true),
                      _seriesRow('6', '1306', true),
                      _seriesRow('7', '1 сентября', true),
                      _seriesRow('8', 'OCTOBER', true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _seriesRow(String id, String name, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 300, child: Text(name, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 200,
            child: Container(
              margin: const EdgeInsets.only(right: 170),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade400),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(Icons.check, size: 12, color: Colors.green.shade400),
            ),
          ),
          Expanded(
            child: Row(
              children: [
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
