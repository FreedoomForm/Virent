import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class GeozonesPage extends ConsumerWidget {
  const GeozonesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFF5F6FA),
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
                        Text('Геозоны', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 4 из 4 совпадений (отфильтровано из 239 совпадений)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () { /* action */ },
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить геозону', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B68EE),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _labeledInput('ID', 80),
                        const SizedBox(width: 8),
                        _filterButton('Группы ▼', isPurple: true),
                        const SizedBox(width: 8),
                        _filterButton('Разр.Использование', isPurple: false, isLightBg: true),
                        const SizedBox(width: 8),
                        _filterButton('Завершение аренды', isPurple: true),
                        const SizedBox(width: 8),
                        _filterButton('Запрет движения', isPurple: true),
                        const SizedBox(width: 8),
                        _filterButton('Ограничение движения', isPurple: true),
                        const SizedBox(width: 8),
                        _filterButton('Зона запрета завершения', isPurple: true),
                        const SizedBox(width: 8),
                        _filterButton('⊘ Очистить фильтры', isPurple: true),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
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
                      color: const Color(0xFFF8F9FA),
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
                      ref.watch(zonesListProvider).when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text("Ошибка: $e")),
                        data: (items) => ListView(
                          children: items.map((item) => _geozoneRowFromItem(item)).toList(),
                        ),
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
  }

  Widget _filterButton(String text, {bool isPurple = false, bool isLightBg = false}) {
    Color bg = isPurple ? const Color(0xFF7B68EE) : (isLightBg ? const Color(0xFFE8EAF6) : Colors.transparent);
    Color textColor = isPurple ? Colors.white : (isLightBg ? const Color(0xFF7B68EE) : Colors.black);
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: isLightBg ? null : (isPurple ? null : Border.all(color: Colors.grey.shade400)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, color: textColor)),
      ),
    );
  }

  Widget _labeledInput(String label, double width) {
    return Row(
      children: [
        SizedBox(
          width: width,
          height: 28,
          child: TextField(
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(onTap: () {}, child: Icon(Icons.close, size: 14, color: Colors.grey[500])),
      ],
    );
  }

  Widget _geozoneRow(String id, String name, String fill, String stroke, String groups, String opFill, String opStroke, String cmds, String minScooters, bool rUsed, bool reqPark, bool disPark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(name, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
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
                InkWell(onTap: () {}, child: const Row(children: [Icon(Icons.visibility, size: 12, color: Color(0xFF3498DB)), SizedBox(width: 4), Text('Просмотр', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))])),
                const SizedBox(width: 12),
                InkWell(onTap: () {}, child: const Row(children: [Icon(Icons.edit, size: 12, color: Color(0xFF3498DB)), SizedBox(width: 4), Text('Редактировать', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))])),
                const SizedBox(width: 12),
                InkWell(onTap: () {}, child: const Row(children: [Icon(Icons.delete, size: 12, color: Color(0xFF3498DB)), SizedBox(width: 4), Text('Удалить', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkBox(bool isChecked, {bool isGreen = false, bool isRed = false}) {
    IconData icon = isChecked ? Icons.check_box : Icons.check_box_outline_blank;
    Color color = isChecked ? (isGreen ? const Color(0xFF2ECC71) : (isRed ? const Color(0xFFE74C3C) : Colors.grey)) : (isGreen ? const Color(0xFF2ECC71) : (isRed ? const Color(0xFFE74C3C) : Colors.grey));
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

  /// Builds a row from provider data item.
  Widget _geozoneRowFromItem(Map<String, dynamic> item) {
    return _geozoneRow(
      item['id']?.toString() ?? '',
      item['name']?.toString() ?? '',
      item['fill']?.toString() ?? '',
      item['stroke']?.toString() ?? '',
      item['groups']?.toString() ?? '',
      item['opFill']?.toString() ?? '',
      item['opStroke']?.toString() ?? '',
      item['cmds']?.toString() ?? '',
      item['minScooters']?.toString() ?? '',
      item['rUsed']?.toString() ?? '',
      item['reqPark']?.toString() ?? '',
      item['disPark']?.toString() ?? '',
    );
  }

}
