import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class SelfiesPage extends ConsumerWidget {
  const SelfiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(selfiesListProvider);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('Селфи', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF1B2A4E))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 296,168 совпадений (отфильтровано из 296,496 совпадений)',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _filterBtn('Да', const Color(0xFF42BA96)),
                    const SizedBox(width: 4),
                    _filterBtn('Нет', const Color(0xFFFFC107)),
                    const SizedBox(width: 12),
                    const Text('ID клиента', style: TextStyle(fontSize: 11, color: Color(0xFF868686))),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 100,
                      height: 28,
                      child: TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: Icon(Icons.close, size: 14, color: Colors.grey[500])),
                    const SizedBox(width: 12),
                    _filterBtn('Очистить фильтры', const Color(0xFFFFC107)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 120, child: Text('ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Фото', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 120, child: Text('Проверено', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFD9E2EF)))),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text('2966[...]', style: const TextStyle(fontSize: 11, color: Color(0xFFFFC107))),
                            ),
                            Expanded(
                              child: Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.broken_image, size: 20, color: Color(0xFF868686)),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Row(
                                children: [
                                  Icon(Icons.check_box_outline_blank, size: 16, color: Color(0xFF868686)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.play_arrow_outlined, size: 16, color: Color(0xFF868686)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

  Widget _filterBtn(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
