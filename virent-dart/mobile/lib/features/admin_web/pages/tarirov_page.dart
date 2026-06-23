import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';


class TarirovPage extends ConsumerWidget {
  const TarirovPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tariffsListProvider);
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
                        Text('Entries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 0 до 0 из 0 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить entry', style: TextStyle(fontSize: 11, color: Colors.white)),
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
                      Expanded(child: Text('Json', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Volume', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Cruising range', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Cruising time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: const Center(
                    child: Text('В таблице нет доступных данных', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                ),
                const Divider(height: 1),
                Container(
                  color: const Color(0xFFF8F9FA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 100, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Json', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Volume', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Cruising range', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Cruising time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
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
  )
  },
);
  }
}
