import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import '../widgets/admin_dialogs.dart';

class BankCardsPage extends ConsumerWidget {
  const BankCardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(billingTransactionsProvider);
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
                const Row(
                  children: [
                    Text('Банковские Карты', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                    SizedBox(width: 12),
                    Text('Показано 1 до 20 из 246,192 совпадений', style: TextStyle(fontSize: 11, color: adminTextGray)),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1600,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 50, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('Client', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('Holder name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Bank name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Country', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Card number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('Token', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Card type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Deleted', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _cardRow(context, '15', '1', '', '', 'uz', '422345******3033', '7ada4d5deb[...]', '', '0'),
                          _cardRow(context, '16', 'Viktor Brok', 'ABDUSAMADOV ABDUXOLID', '', 'uz', '860003047...9353', 'NEEZUKYRCB[...]', '', '0'),
                          _cardRow(context, '17', '1', 'ABDUSAMADOV ABDUXOLID', '', 'uz', '860055041...4912', '9D2XQYMLX6[...]', '', '0'),
                          _cardRow(context, '18', '38', '', '', 'uz', '445555******4501', 'f60bda6762[...]', '', '0'),
                          _cardRow(context, '19', '28', 'BEKHZOD MIRZABEKOV', '', 'uz', '860049291...4334', 'WP98Z3PH1B[...]', '', '1'),
                          _cardRow(context, '20', '28', '', '', 'uz', '427832******2804', 'e6b2691130[...]', '', '1'),
                          _cardRow(context, '21', '68', '', '', 'uz', '524680******7539', 'aaf29c7b86[...]', '', '0'),
                          _cardRow(context, '22', 'Наиль Насибулов', '', '', 'uz', '517425******3249', 'ec95c2e9b0[...]', '', '1'),
                          _cardRow(context, '23', 'Diyorbek', 'KARIMOV DILSHOD N', '', 'uz', '860014020...1062', 'H5MMTKIGLF[...]', '', '0'),
                          _cardRow(context, '24', 'Сардор Хамидуллаев', 'KHAMIDULLAEV SARDOR', '', 'uz', '860033295...2327', 'IW3ZTVZLNO[...]', '', '0'),
                          _cardRow(context, '25', 'Сардор Хамидуллаев', 'KHAMIDULLAEV SARDOR', '', 'uz', '860033295...2327', 'IW3ZTVZLNO[...]', '', '0'),
                          _cardRow(context, '26', 'иброхим пирназоров', '', '', 'uz', '547638******7136', 'db538add26[...]', '', '1'),
                          _cardRow(context, '27', 'Александр', 'EKATERINA POLYAKOVA C', '', 'uz', '860049048...4162', '6BL38MMTHW[...]', '', '0'),
                          _cardRow(context, '28', 'dostob tursunnazarov', 'TURSUNNAZAROV DOSTON', '', 'uz', '626273004...5719', 'JUS3LT2FJ9[...]', '', '0'),
                          _cardRow(context, '29', 'мухаммад шавкатов', 'MUHAMMADAMIN SHAVK', '', 'uz', '860049045...9707', 'LSYOGVYIM6[...]', '', '0'),
                          _cardRow(context, '30', 'мухаммад шавкатов', 'MUHAMMADAMIN SHAVK', '', 'uz', '860049045...9707', 'LSYOGVYIM6[...]', '', '0'),
                          _cardRow(context, '31', 'AHMAD EGAMBERDIYEV', 'EGAMBERDIYEV AHMAD', '', 'uz', '860003042...5368', 'SLCCJTVLQB[...]', '', '0'),
                          _cardRow(context, '32', 'Наиль Насибулов', '', '', 'uz', '517425******3249', '75f81d368b[...]', '', '1'),
                          _cardRow(context, '33', 'Наиль Насибулов', '', '', 'uz', '517425******3249', '3b55a249a0[...]', '', '1'),
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

  Widget _cardRow(context, BuildContext context, String id, String client, String holder, String bank, String country, String card, String token, String type, String deleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: adminBorder))),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(id, style: const TextStyle(fontSize: 11, color: adminInfo))),
          SizedBox(width: 200, child: Text(client, style: TextStyle(fontSize: 11, color: client == '1' || client == '38' || client == '28' || client == '68' ? Colors.black : adminInfo))),
          SizedBox(width: 250, child: Text(holder, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(bank, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(country, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(card, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text(token, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(type, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(deleted, style: const TextStyle(fontSize: 11))),
          Expanded(
            child: Row(
              children: [
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.visibility, size: 12, color: adminInfo), SizedBox(width: 4), Text('Просмотр', style: TextStyle(fontSize: 10, color: adminInfo))])),
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
