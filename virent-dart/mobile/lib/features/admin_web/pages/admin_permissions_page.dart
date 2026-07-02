import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import '../widgets/admin_dialogs.dart';

class AdminPermissionsPage extends ConsumerWidget {
  const AdminPermissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPermissionsProvider);
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
                        Text('Разрешения', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 83 совпадений', style: TextStyle(fontSize: 11, color: adminTextGray)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить разрешение', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: adminPrimary,
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
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
                      SizedBox(width: 300, child: Text('Имя', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('backpack::permissionmanager.title', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _permRow(context, '*', ''),
                      _permRow(context, 'send command to device', 'управление самокатом'),
                      _permRow(context, 'send push', 'отправка PUSH'),
                      _permRow(context, 'admin/*', ''),
                      _permRow(context, 'admin/dashboard*', 'Дашборд'),
                      _permRow(context, 'admin/alert*', 'Тревоги'),
                      _permRow(context, 'admin/map*', 'Карта'),
                      _permRow(context, 'admin/car*', 'Самокаты ВСЕ'),
                      _permRow(context, 'admin/bill*', 'Счета'),
                      _permRow(context, 'admin/client*', 'Клиенты'),
                      _permRow(context, 'admin/fine*', 'Штрафы'),
                      _permRow(context, 'admin/order*', 'Заказы'),
                      _permRow(context, 'admin/inspect*', ''),
                      _permRow(context, 'admin/selfie*', 'Селфи'),
                      _permRow(context, 'admin/damage*', 'Осмотр'),
                      _permRow(context, 'admin/damagephoto*', ''),
                      _permRow(context, 'admin/bonus*', 'Бонусы'),
                      _permRow(context, 'admin/transaction*', 'Транзакции'),
                      _permRow(context, 'admin/bankcard*', 'Банковские карты'),
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

  Widget _permRow(BuildContext context, String name, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: adminBorder))),
      child: Row(
        children: [
          SizedBox(width: 300, child: Text(name, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.edit, size: 12, color: adminInfo), SizedBox(width: 4), Text('Редактировать', style: TextStyle(fontSize: 10, color: adminInfo))])),
                const SizedBox(width: 12),
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.delete, size: 12, color: adminDanger), SizedBox(width: 4), Text('Удалить', style: TextStyle(fontSize: 10, color: adminDanger))])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
