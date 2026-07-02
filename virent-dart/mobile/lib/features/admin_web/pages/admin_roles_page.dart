import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import '../widgets/admin_dialogs.dart';

class AdminRolesPage extends ConsumerWidget {
  const AdminRolesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminListProvider);
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
                        Text('Роли', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        SizedBox(width: 12),
                        Text('Показано 1 до 8 из 8 совпадений', style: TextStyle(fontSize: 11, color: adminTextGray)),
                      ]),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить роль', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: adminPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)))),
                  ]),
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
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder))),
                      style: const TextStyle(fontSize: 11)))),
              ])),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 100, child: Text('Имя', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Разрешения', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ])),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _roleRow(context, 'Админ', 'send command to device, send push, admin/*, ignore companies, admin/delete_client_card*'),
                      _roleRow(context, 'Техник', 'send command to device, admin/alert*, admin/map*, admin/damage*, admin/damagephoto*, admin/preview/*, admin/techview*, admin/car, admin/car/*'),
                      _roleRow(context, 'Партнер', 'send command to device, send push, admin/alert*, admin/map*, admin/bill*, admin/order*, admin/inspect*, admin/selfie*, admin/damage*, admin/damagephoto*, admin/bonus*, admin/transaction*, admin/activity_log*, admin/unconfirmed_client*, admin/dot*, admin/preview/*, admin/car, admin/car/*, admin/client, admin/client/*, admin/stats'),
                      _roleRow(context, 'Оператор', 'send command to device, send push, admin/alert*, admin/map*, admin/bill*, admin/fine*, admin/order*, admin/inspect*, admin/damage*, admin/damagephoto*, admin/bonus*, admin/transaction*, admin/car_log*, admin/activity_log*, admin/client_login_attempt*, admin/unconfirmed_client*, admin/clientselfie*, admin/preview/*, admin/car, admin/car/*, admin...'),
                      _roleRow(context, 'Helper', 'admin/map*, admin/preview/*, admin/car'),
                      _roleRow(context, 'Техник', 'admin/alert*, admin/map*, admin/damage*, admin/damagephoto*'),
                      _roleRow(context, 'Оператор', 'send push, admin/alert*, admin/map*, admin/bill*, admin/fine*, admin/order*, admin/inspect*, admin/selfie*, admin/damage*, admin/damagephoto*, admin/bonus*, admin/transaction*, admin/car_log*, admin/activity_log*, admin/client_login_attempt*'),
                      _roleRow(context, 'Бехзод', '*, send command to device, send push, pay all debts, restart java, delete_tariff, delete_abonement, pay_all_debt_button, Raider, admin/getHoldLogs, admin/clientStatus, startmessage'),
                    ])),
                const Divider(height: 1),
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 100, child: Text('Имя', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Разрешения', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ])),
                const Divider(height: 1),
              ])),
        ]));
      });
  }

  Widget _roleRow(BuildContext context, String name, String permissions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: adminBorder))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(name, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(permissions, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.edit, size: 12, color: adminInfo), SizedBox(width: 4), Text('Редактировать', style: TextStyle(fontSize: 10, color: adminInfo))])),
                const SizedBox(width: 12),
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.delete, size: 12, color: adminDanger), SizedBox(width: 4), Text('Удалить', style: TextStyle(fontSize: 10, color: adminDanger))])),
              ])),
        ]));
  }
}
