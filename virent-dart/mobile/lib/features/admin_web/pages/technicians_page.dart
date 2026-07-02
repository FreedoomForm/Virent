import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import '../widgets/admin_dialogs.dart';

class TechniciansPage extends ConsumerWidget {
  const TechniciansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(techniciansListProvider);
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
                        Text('Техники', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        SizedBox(width: 12),
                        Text('Показано 1 до 17 из 17 совпадений', style: TextStyle(fontSize: 11, color: adminTextGray)),
                      ]),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить техник', style: TextStyle(fontSize: 11, color: Colors.white)),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 2000,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 60, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Имя', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Логин', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('Companies', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('Technick key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('Api token', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('Permissions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('Пароль', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Current companies', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ])),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _techRow(context, '18', 'Максим Егорович', 'egor@gmail.com', '', 'egor@gmail.com:M210iK9AG13', 'Uc2onzAwc4vgRNuettopFCFg4EW5iAm3COvmybo3', '', '', '\$2y\$10\$LABLEG6WCc4uVKvcnXenXN6cFTJ3dqS2[...]', '17'),
                          _techRow(context, '22', 'viktor2', 'viktor2', 'ViRent, ИП Асилбеков Шерзод, Virent Motv[...]', 'viktor2:iPhone16,2', '6AnSAGcD2STUPtcenoXKdvwdcj1LbwuAGVpzCFBb7', '["lock_and_unlock","open_akb","change_ca[...]', '1', '\$2y\$10\$EeEILIL3T7XdxmpMzVqCgyKxNTDwQLdf[...]', '17'),
                          _techRow(context, '23', 'Egor', 'eGor', 'ViRent, ИП Асилбеков Шерзод, Virent Motv[...]', '', '', '["lock_and_unlock","open_akb","change_ca[...]', '1', '\$2y\$10\$EGLFfAyuSD6ZpzVbyRpd2S3uvXUWzyS[...]', '17'),
                          _techRow(context, '29', 'aplle', 'apiie@check', 'ViRent, ИП Асилбеков Шерзод, Virent Motv[...]', 'apiie@check:iPad17,4,1', 'MqgpQWXbQXKfj8UVU2EZpZHavJOtoVZVB9CHQyyxB8', '', '0', '\$2y\$10\$Ua4R8LxkKXQEkfmEmwixL22FHgKDDpkm[...]', '17'),
                          _techRow(context, '30', 'google', 'google@check', 'ViRent, ИП Асилбеков Шерзод, Virent Motv[...]', 'google@check:iPhone17,5,1', '4FAPolUNGpN9EQmdGUBRQyHlbVHxM32lYlq63Rt', '', '0', '\$2y\$10\$uYRwXJ89EvqA6oJt5ti6rKcOUq1AfcB9x[...]', '17'),
                          _techRow(context, '34', 'Шерзод Асилбеков', 'sher700@gmail.com', 'ИП Асилбеков Шерзод, ИП Асилбекова Нигор[...]', 'sher700@gmail.com:2201116PG13', 'A7q9ty7C8xysOdEue3DZTWoeh5R6SKMlwqEqkiSppJ', '["lock_and_unlock","open_akb","change_ca[...]', '0', '\$2y\$10\$s4lDAsUgGg20Ufzn1OBdDOQHdUXtKxkPI[...]', ''),
                          _techRow(context, '228', 'TAS-Дмитрий Велесик', 'dima@gmail.com', 'VV-LAND', 'dima@gmail.com:iPhone17,6,1', '6gcrR2Z1t1SPnb2ZlCc2GQMOMKR8PIRqdHB1GMGYfF', '["lock_and_unlock","open_akb","change_ca[...]', '0', '\$2y\$10\$sSUGdZElVKTIsWwmRVvrOd1E7AfcB9x[...]', ''),
                          _techRow(context, '264', 'Ш', 'b@gmail.com', 'ИП Асилбеков Шерзод, ИП Асилбекова Нигор[...]', 'b@gmail.com:2201116PG13', 'AFSnyBa9E4TqhLOFoNwwqC0N3GCxQuZZwDWxX3LmdV', '["lock_and_unlock","open_akb","change_ca[...]', '1', '\$2y\$10\$CaKZWeccj3td2pf99/pXhCOxsqMtKXdk[...]', '1'),
                          _techRow(context, '312', 'Ильдар техник', 'i@gmail.com', 'ViRent, Virent Motion Samarqand, VV-LAND', 'i@gmail.com:2203129G14', 'Dk5NjFhtboKTWZwNZ0mSrHDS3H3vJ4aliyWgqkyWHpe', '["lock_and_unlock","open_akb","change_ca[...]', '0', '\$2y\$10\$8AxiKxgki8j3ss2OxoOMmzYH9BzKq[...]', ''),
                          _techRow(context, '331', 'EVG TECH 1', 'akbopen@gmail.com', 'ИП Асилбеков Шерзод, ИП Асилбекова Нигор[...]', 'akbopen@gmail.com:W-V7710', 'IGOiJ5fOLh1JEle1PqQVrsRVrnxZWxSQ75eZWb', '["open_akb"]', '0', '\$2y\$10\$DVVKXWoSGEwl7O8GSD4VuS/SDfaAwt[...]', ''),
                          _techRow(context, '332', 'Михаил', 'mihail@gmai.com', 'ИП Асилбеков Шерзод, ИП Асилбекова Нигор[...]', 'mihail@gmai.com:SM-G988N13', 'DsE8ztX8fG0be2ZnCHIDf7twVa5eAAvkigjj6vLbu', '["lock_and_unlock","open_akb","change_ca[...]', '0', '\$2y\$10\$JWMF/yvjIVyv4rBMyMneFyevykWWEK2v[...]', ''),
                          _techRow(context, '336', 'Наталья Борисенко', 'admnb', 'ИП Асилбеков Шерзод, VV-LAND, ИП Асилбек[...]', 'admnb:iPhone18,7', 'Bmkx4GZNgrzzAumMyvwHcSckk7Sq4BjkVDLRYy', '["lock_and_unlock","open_akb","change_ca[...]', '1', '\$2y\$10\$QkCAZQqd8CrcffS3gECO6vIXWvLhJj9[...]', ''),
                          _techRow(context, '338', 'Озод Раматбоев', 'ozodramatboev@gmail.com', 'ИП Асилбеков Шерзод, ИП Асилбекова Нигор[...]', 'ozodramatboev@gmail.com:SM-A515F13', 'AVDCsfvMv7fECgjrxQHcoEocvp2TRJO2mw8dUAISSmA', '["open_akb"]', '0', '\$2y\$10\$WQS19MQRtUQh5SWRH4n5zOxAnxRtu3bb[...]', ''),
                          _techRow(context, '340', 'Техник 1 нов', 'tchnw1@gmail.com', 'ИП Асилбеков Шерзод, ИП Асилбекова Нигор[...]', 'tchnw1@gmail.com:220101316UG14', 'wPBsQtVl3RM1jeKnyzEuN11xJISafRnxN5oClsviD', '["open_akb"]', '0', '\$2y\$10\$SFgWtIVx1mN9UugRrxQfbXvAljQqXIL[...]', ''),
                          _techRow(context, '341', 'Евгений', 'evgwhite@gmail.com', 'ИП Асилбеков Шерзод, ИП Асилбекова Нигор[...]', 'evgwhite@gmail.com:25078PCG3EG15', '1pHXLQpL2RQalxa5E9mRhU_19bEuEUyU1XLlBj3', '["open_akb"]', '0', '\$2y\$10\$q1hR5hrGfDYKZZa7gAjw8TQfCrjL[...]', ''),
                          _techRow(context, '343', 'Ночник', 'noch@gmail.com', 'ИП Асилбеков Шерзод, ИП Асилбекова Нигор[...]', 'noch@gmail.com:23049RAD8C15', 'jsCSKFzjtlHYt8DBuBRADmp8UU1FByj6VQ2lzHiv4', '["open_akb"]', '0', '\$2y\$10\$cZ2M2hR7gaA7ioNO0yEua6qDp6MD[...]', ''),
                          _techRow(context, '345', 'Ночь Акб', 'akbnight@gmail.com', 'ИП Асилбеков Шерзод', 'amn_noch@gmail.com:RNX394115', 'dxkqPkAFewhHLUUeHU2LQq2GjWNYJmXfTWYjXPsJ', '["open_akb"]', '0', '\$2y\$10\$H01u2zZk0gEZ2fillQsZqTQ2wutMweM[...]', ''),
                        ])),
                  ])))),
        ]));
      });
  }

  Widget _techRow(BuildContext context, String id, String name, String login, String companies, String techKey, String apiToken, String permissions, String admin, String pass, String curComp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: adminBorder))),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(name, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(login, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text(companies, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 250, child: Text(techKey, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 250, child: Text(apiToken, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 250, child: Text(permissions, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 60, child: Text(admin, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 250, child: Text(pass, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(curComp, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 250,
            child: Row(
              children: [
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.visibility, size: 12, color: adminInfo), SizedBox(width: 4), Text('Просмотр', style: TextStyle(fontSize: 10, color: adminInfo))])),
                const SizedBox(width: 12),
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.edit, size: 12, color: adminInfo), SizedBox(width: 4), Text('Редактировать', style: TextStyle(fontSize: 10, color: adminInfo))])),
                const SizedBox(width: 12),
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.delete, size: 12, color: adminDanger), SizedBox(width: 4), Text('Удалить', style: TextStyle(fontSize: 10, color: adminDanger))])),
              ])),
        ]));
  }
}
