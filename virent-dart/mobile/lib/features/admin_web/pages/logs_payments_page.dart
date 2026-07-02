import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import '../widgets/admin_dialogs.dart';

class LogsPaymentsPage extends ConsumerWidget {
  const LogsPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(logsPaymentsProvider);
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
                        Text('Entries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        SizedBox(width: 12),
                        Text('Показано 0 до 0 из 0 совпадений', style: TextStyle(fontSize: 11, color: adminTextGray)),
                      ]),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить entry', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: adminPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)))),
                  ]),
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
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder))),
                    style: const TextStyle(fontSize: 11))),
              ])),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1600,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _col('Key1'), _col('Key2'), _col('Key3'), _col('Key4'), _col('Key5'), _col('Key6'), _col('Key7'), _col('Key8'), _col('Key9'), _col('Key10'), _col('Key11'), _col('Key12'),
                          const Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ])),
                    const Divider(height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: const Center(
                        child: Text('В таблице нет доступных данных', style: TextStyle(fontSize: 11, color: Colors.grey)))),
                    const Divider(height: 1),
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _col('Key1'), _col('Key2'), _col('Key3'), _col('Key4'), _col('Key5'), _col('Key6'), _col('Key7'), _col('Key8'), _col('Key9'), _col('Key10'), _col('Key11'), _col('Key12'),
                          const Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ])),
                    const Divider(height: 1),
                    const Expanded(child: SizedBox()),
                  ])))),
        ]));
      });
  }

  Widget _col(String text) {
    return SizedBox(
      width: 100, // Reduced width since there's 12 keys
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)));
  }
}
