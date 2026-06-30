import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';

class TariffOffersPage extends ConsumerWidget {
  const TariffOffersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tariffsListProvider);
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
                        Text('Тарифы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 23 совпадений', style: TextStyle(fontSize: 11, color: adminTextGray)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить тариф', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: adminPrimary,
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
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
                      SizedBox(width: 300, child: Text('Название в админке', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 300, child: Text('Название в мобильном приложении', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('Hold', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _tariffRow('Минутный ViRent Ташкент', 'Minute', '500000 Тийны'),
                      _tariffRow('Минутный ИП Асилбеков', 'Minute', '500000 Тийны'),
                      _tariffRow('TEST', 'test', '100000 Тийны'),
                      _tariffRow('для 30мин ViRent Ташкент', 'Минутный', '500000 Тийны'),
                      _tariffRow('для 60мин ViRent Ташкент', 'минутный', '500000 Тийны'),
                      _tariffRow('Для 30мин ИП Асилбеков', 'Минутный', '500000 Тийны'),
                      _tariffRow('Для 60мин ИП Асилбеков', 'Hour', '500000 Тийны'),
                      _tariffRow('Минутный 600-самокаты', 'Минутный', '500000 Тийны'),
                      _tariffRow('тест', 'тест', '500000 Тийны'),
                      _tariffRow('для 10 минут', '10 Минут', '500000 Тийны'),
                      _tariffRow('для абонементов 600', 'Минутный', '500000 Тийны'),
                      _tariffRow('Минутный ИП Асилбекова Нигора', 'Minute', '500000 Тийны'),
                      _tariffRow('Минутный ИП Pахматбоев Озод', 'Minute', '500000 Тийны'),
                      _tariffRow('Минутный ИП Руфатова Зухра', 'Minute', '500000 Тийны'),
                      _tariffRow('Для 20мин ИП Асилбекова H', 'Минутный', '500000 Тийны'),
                      _tariffRow('для 30мин ИП Асилбекова H', 'Минутный', '500000 Тийны'),
                      _tariffRow('для 60мин ИП Асилбекова H', 'Минутный', '500000 Тийны'),
                      _tariffRow('Для 20мин ИП Pахматбоев О', 'Минутный', '500000 Тийны'),
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

  Widget _tariffRow(String adminName, String appName, String hold) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: adminBorder))),
      child: Row(
        children: [
          SizedBox(width: 300, child: Text(adminName, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 300, child: Text(appName, style: const TextStyle(fontSize: 11, color: adminPrimary))),
          SizedBox(width: 150, child: Text(hold, style: const TextStyle(fontSize: 11))),
          Expanded(
            child: Row(
              children: [
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.visibility, size: 12, color: adminInfo), SizedBox(width: 4), Text('Просмотр', style: TextStyle(fontSize: 10, color: adminInfo))])),
                const SizedBox(width: 12),
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.map, size: 12, color: adminInfo), SizedBox(width: 4), Text('Геозоны завершения', style: TextStyle(fontSize: 10, color: adminInfo))])),
                const SizedBox(width: 12),
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
