import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';


class TariffPricesPage extends ConsumerWidget {
  const TariffPricesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tariffPricesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
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
                        Text('Цены', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 9 из 9 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить цены', style: TextStyle(fontSize: 11, color: Colors.white)),
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
                  color: const Color(0xFFF8F9FA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 300, child: Text('Наименование', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 300, child: Text('Json', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('Time unit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _priceRow('ViRent Ташкент', '60'),
                      _priceRow('ViRent Самарканд', '60'),
                      _priceRow('ViRent Motion', '60'),
                      _priceRow('ИП Асилбеков', '60'),
                      _priceRow('Минутный Ташкент Е600 самокаты', '60'),
                      _priceRow('тест', '60'),
                      _priceRow('Асилбекова Нигора', '60'),
                      _priceRow('Раматбоев Озод', '60'),
                      _priceRow('Руфатова Зухра', '60'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  )
  },
);
  }

  Widget _priceRow(String name, String timeUnit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 300, child: Text(name, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 300,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF3498DB), borderRadius: BorderRadius.circular(3)),
                child: const Text('Развернуть / Свернуть', style: TextStyle(fontSize: 10, color: Colors.white)),
              ),
            ),
          ),
          SizedBox(width: 150, child: Text(timeUnit, style: const TextStyle(fontSize: 11))),
          Expanded(
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
