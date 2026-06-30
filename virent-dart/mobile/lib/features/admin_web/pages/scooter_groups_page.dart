import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class ScooterGroupsPage extends ConsumerWidget {
  const ScooterGroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settingsScooterGroupsProvider);
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
                        Text('Entries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF1B2A4E))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 12 из 12 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить entry', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C69EF),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
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
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 100, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Trigger equation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _groupRow('0', 'на линии', ''),
                      _groupRow('1', 'на складе', ''),
                      _groupRow('7', 'в техничке', ''),
                      _groupRow('13', 'в поломке', ''),
                      _groupRow('14', 'Демо', ''),
                      _groupRow('17', 'Самарканд', ''),
                      _groupRow('18', 'Ташкент', ''),
                      _groupRow('19', 'SILK ROAD SAMARQAND', ''),
                      _groupRow('20', 'ИП Асилбеков', ''),
                      _groupRow('22', 'Заряд > 50', 'fuel > 50'),
                      _groupRow('23', 'Заряд > 65', 'fuel > 65'),
                      _groupRow('24', '600', ''),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 100, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Trigger equation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
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
      },
    );
  }

  Widget _groupRow(String id, String desc, String trigger) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFD9E2EF)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(id, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(trigger, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.visibility, size: 12, color: Color(0xFF467FD0)), SizedBox(width: 4), Text('Просмотр', style: TextStyle(fontSize: 10, color: Color(0xFF467FD0)))])),
                const SizedBox(width: 12),
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.edit, size: 12, color: Color(0xFF467FD0)), SizedBox(width: 4), Text('Редактировать', style: TextStyle(fontSize: 10, color: Color(0xFF467FD0)))])),
                const SizedBox(width: 12),
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.delete, size: 12, color: Color(0xFF467FD0)), SizedBox(width: 4), Text('Удалить', style: TextStyle(fontSize: 10, color: Color(0xFF467FD0)))])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
