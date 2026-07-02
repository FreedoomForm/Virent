import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import './widgets/admin_dialogs.dart';

class PushHistoryPage extends ConsumerWidget {
  const PushHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pushHistoryListProvider);
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
                        Text('История Push', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 1,274,438 совпадений', style: TextStyle(fontSize: 11, color: adminTextGray)),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('ID клиента', style: TextStyle(fontSize: 11, color: adminTextGray)),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 100,
                      height: 28,
                      child: TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: Icon(Icons.close, size: 14, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1500,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 80, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Client', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Client mass', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Text', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Is read', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 70, child: Text('Deleted', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 160, child: Text('Created', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Client', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _pushRow(context, '1274813', '63616', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:10', '063616', 'surname mamurjan'),
                          _pushRow(context, '1274812', '63615', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063615', 'surname Sardor'),
                          _pushRow(context, '1274811', '63614', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063614', 'surname нур'),
                          _pushRow(context, '1274810', '63613', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063613', 'surname Комил'),
                          _pushRow(context, '1274809', '63612', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063612', 'surname Abdulbosit'),
                          _pushRow(context, '1274808', '63611', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063611', 'surname Игнат'),
                          _pushRow(context, '1274807', '63610', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063610', 'surname abuken'),
                          _pushRow(context, '1274806', '63609', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063609', 'surname Islom'),
                          _pushRow(context, '1274805', '63606', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063606', 'surname Cemil'),
                          _pushRow(context, '1274804', '63604', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063604', 'surname s'),
                          _pushRow(context, '1274803', '63603', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063603', 'surname Аброрбек'),
                          _pushRow(context, '1274802', '63602', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063602', 'surname Муhammadbobur'),
                          _pushRow(context, '1274801', '63601', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063601', 'surname firdavs'),
                          _pushRow(context, '1274800', '63599', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063599', 'surname dilshod'),
                          _pushRow(context, '1274799', '63598', 'TEST', 'Нет', 'Нет', '2026-01-27 22:31:09', '063598', 'surname baxa'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _pushRow(BuildContext context, String id, String client, String text, String isRead, String deleted, String created, String clientId, String clientName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: adminBorder))),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 80, child: Text(client, style: const TextStyle(fontSize: 11))),
          const SizedBox(width: 120),
          SizedBox(width: 80, child: Text(text, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 60, child: Text(isRead, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 70, child: Text(deleted, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 160, child: Text(created, style: const TextStyle(fontSize: 11))),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2)),
                  child: Text(clientId, style: const TextStyle(fontSize: 9, color: Colors.white)),
                ),
                const SizedBox(width: 6),
                Text(clientName, style: const TextStyle(fontSize: 11, color: adminInfo)),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: InkWell(
              onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
              child: Row(
                children: [
                  const Icon(Icons.visibility, size: 12, color: adminInfo),
                  const SizedBox(width: 4),
                  const Text('Просмотр', style: TextStyle(fontSize: 10, color: adminInfo)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
