import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import '../widgets/admin_dialogs.dart';

class GeozonesPage extends ConsumerWidget {
  const GeozonesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(zonesListProvider);
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
                        Text('Геозоны', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                        SizedBox(width: 12),
                        Text('Показано 1 до 4 из 4 совпадений (отфильтровано из 239 совпадений)', style: TextStyle(fontSize: 11, color: adminTextGray)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить геозону', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: adminPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _labeledInput(context, 'ID', 80),
                        const SizedBox(width: 8),
                        _filterButton(context, 'Группы ▼', isPurple: true),
                        const SizedBox(width: 8),
                        _filterButton(context, 'Разр.Использование', isPurple: false, isLightBg: true),
                        const SizedBox(width: 8),
                        _filterButton(context, 'Завершение аренды', isPurple: true),
                        const SizedBox(width: 8),
                        _filterButton(context, 'Запрет движения', isPurple: true),
                        const SizedBox(width: 8),
                        _filterButton(context, 'Ограничение движения', isPurple: true),
                        const SizedBox(width: 8),
                        _filterButton(context, 'Зона запрета завершения', isPurple: true),
                        const SizedBox(width: 8),
                        _filterButton(context, '⊘ Очистить фильтры', isPurple: true),
                      ],
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 2200,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 40, child: Text('ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Название', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Заполнение', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Обводка', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('columns.geozone.company_id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Группы', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('кэф.проз.геозоны', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('кэф.ярк.обводки', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('Команды', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('Минимальное количество самокатов', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('Зона Разрешенного Использования', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('Зона Завершения Аренды', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Зона Ог...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _geozoneRow(context, '1', 'Main (0)', '#cc62dc', '#1bffca', '-', '30 %', '30 %', 'unlockWheel,switchDriveModeSport', '0', true, false, false),
                          _geozoneRow(context, '10', 'Donute test geozone (0)', '#e82f17', '#7a3a00', '-', '75 %', '90 %', 'switchDriveModeEco,switchDriveModeSport', '0', true, false, false),
                          _geozoneRow(context, '420', 'ЗИ ТАШКЕНТ НОВАЯ (1)', '#16FF17', '#ED0505', 'Города (ЗИ)', '50 %', '100 %', 'speedModeOn,switchDriveModeSport,setSpee[...]', '0', true, false, false),
                          _geozoneRow(context, '466', 'SAMARKAND (1)', '#00EB27', '#00EB27', 'Города (ЗИ)', '1 %', '100 %', 'speedModeOn,switchDriveModeSport,setSpee[...]', '0', true, false, false),
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

  Widget _filterButton(BuildContext context, String text, {bool isPurple = false, bool isLightBg = false}) {
    Color bg = isPurple ? adminPrimary : (isLightBg ? const Color(0xFFE8EAF6) : Colors.transparent);
    Color textColor = isPurple ? Colors.white : (isLightBg ? adminPrimary : Colors.black);
    return InkWell(
      onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: isLightBg ? null : (isPurple ? null : Border.all(color: adminTextGray)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, color: textColor)),
      ),
    );
  }

  Widget _labeledInput(BuildContext context, String label, double width) {
    return Row(
      children: [
        SizedBox(
          width: width,
          height: 28,
          child: TextField(
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(fontSize: 11, color: adminTextGray),
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
    );
  }

  Widget _geozoneRow(BuildContext context, String id, String name, String fill, String stroke, String groups, String opFill, String opStroke, String cmds, String minScooters, bool rUsed, bool reqPark, bool disPark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: adminBorder))),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(name, style: const TextStyle(fontSize: 11, color: adminPrimary))),
          SizedBox(width: 100, child: Text(fill, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(stroke, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text('-', style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(groups, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(opFill, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(opStroke, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 250, child: Text(cmds, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text(minScooters, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 250,
            child: Row(
              children: [
                _checkBox(rUsed, isGreen: true),
              ],
            ),
          ),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                _checkBox(reqPark, isRed: true),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              children: [
                _checkBox(disPark, isRed: true),
              ],
            ),
          ),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: const Row(children: [Icon(Icons.visibility, size: 12, color: adminInfo), SizedBox(width: 4), Text('Просмотр', style: TextStyle(fontSize: 10, color: adminInfo))])),
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

  Widget _checkBox(bool isChecked, {bool isGreen = false, bool isRed = false}) {
    IconData icon = isChecked ? Icons.check_box : Icons.check_box_outline_blank;
    Color color = isChecked ? (isGreen ? adminSuccess : (isRed ? adminDanger : Colors.grey)) : (isGreen ? adminSuccess : (isRed ? adminDanger : Colors.grey));
    // The screenshot has the checkbox outline in color even when empty.
    if (!isChecked && isGreen) icon = Icons.check_box_outline_blank;
    if (!isChecked && isRed) icon = Icons.check_box_outline_blank;
    if (isChecked) {
       // if it's checked in the screenshot, it's a square with a check mark inside
       // actually using icons is fine
       icon = Icons.check_box_outlined;
    }
    
    return Icon(icon, size: 16, color: color);
  }
}
