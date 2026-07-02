import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import '../widgets/admin_dialogs.dart';

class TariffAbonementsPage extends ConsumerWidget {
  const TariffAbonementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tariffAbonementsProvider);
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
                        Text('Абонементы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        SizedBox(width: 12),
                        Text('Показано 1 до 17 из 17 совпадений', style: TextStyle(fontSize: 11, color: adminTextGray)),
                      ]),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить абонемент', style: TextStyle(fontSize: 11, color: Colors.white)),
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
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 300, child: Text('Tariff', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 300, child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('Overrun price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('Cost', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ])),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _abonementRow(context, 'для 30мин ViRent Ташкент', '20 Мин ViRent Ташкент', '0.00 С./км', '16 990.00 С.'),
                      _abonementRow(context, 'для 30мин ViRent Ташкент', '30 мин ViRent Ташкент', '0.00 С./км', '24 990.00 С.'),
                      _abonementRow(context, 'Для 30мин ИП Асилбеков', '30 Мин ИП Асилбеков', '0.00 С./км', '24 900.00 С.'),
                      _abonementRow(context, 'Для 60мин ИП Асилбеков', 'Часовой ИП Асилбеков', '0.00 С./км', '34 900.00 С.'),
                      _abonementRow(context, 'для 60мин ViRent Ташкент', 'Часовой ViRent Ташкент', '0.00 С./км', '49 900.00 С.'),
                      _abonementRow(context, 'для 10 минут', '10 Минут Ташкент', '0.00 С./км', '7 000.00 С.'),
                      _abonementRow(context, 'для абонементов 600', '30 мин 600', '0.00 С./км', '24 990.00 С.'),
                      _abonementRow(context, 'Для 30мин ИП Асилбеков', '20 Мин Асилбеков', '0.00 С./км', '14 900.00 С.'),
                      _abonementRow(context, 'Для 20мин ИП Асилбекова Н', '20 минутный ИП Асилбекова Н', '0.00 С./км', '14 900.00 С.'),
                      _abonementRow(context, 'для 30мин ИП Асилбекова Н', '30 Мин ИП Асилбекова Н', '0.00 С./км', '24 900.00 С.'),
                      _abonementRow(context, 'для 60мин ИП Асилбекова Н', 'Часовой ИП Асилбекова Н', '0.00 С./км', '34 900.00 С.'),
                      _abonementRow(context, 'Для 20мин ИП Pахматбоев О', '20 Мин ИП Pахматбоев О', '0.00 С./км', '14 900.00 С.'),
                      _abonementRow(context, 'для 30мин ИП Pахматбоев О', '30 Мин ИП Pахматбоев О', '0.00 С./км', '24 900.00 С.'),
                      _abonementRow(context, 'для 60мин ИП Pахматбоев О', 'Часовой ИП Pахматбоев О', '0.00 С./км', '34 900.00 С.'),
                      _abonementRow(context, 'Для 20мин ИП Руфатова З', '20 Мин ИП Руфатова', '0.00 С./км', '14 900.00 С.'),
                      _abonementRow(context, 'для 30мин ИП Руфатова З', '30 Мин ИП Руфатова З', '0.00 С./км', '24 900.00 С.'),
                      _abonementRow(context, 'для 60мин ИП Руфатова З', 'Часовой ИП Руфатова З', '0.00 С./км', '34 900.00 С.'),
                    ])),
              ])),
        ]));
      });
  }

  Widget _abonementRow(BuildContext context, String tariff, String desc, String overrun, String cost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: adminBorder))),
      child: Row(
        children: [
          SizedBox(width: 300, child: Text(tariff, style: const TextStyle(fontSize: 11, color: adminPrimary))),
          SizedBox(width: 300, child: Text(desc, style: const TextStyle(fontSize: 11, color: adminPrimary))),
          SizedBox(width: 150, child: Text(overrun, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(cost, style: const TextStyle(fontSize: 11))),
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
              ])),
        ]));
  }
}
