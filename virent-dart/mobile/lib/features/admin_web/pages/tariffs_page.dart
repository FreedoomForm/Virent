import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';


class TariffsPage extends ConsumerWidget {
  const TariffsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tariffsListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
      data: (items) => Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Тарифы', style: TextStyle(fontSize: 24)),
              const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Показано 1 до 20 из 23 совпадений', style: TextStyle(color: Colors.grey)),
                  )),
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Поиск...',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Добавить тариф'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B68EE), foregroundColor: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              elevation: 0,
              child: ListView(
                children: [
                  DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    columns: const [
                      DataColumn(label: Text('Название в админке')),
                      DataColumn(label: Text('Название в мобильном приложении')),
                      DataColumn(label: Text('Hold')),
                      DataColumn(label: Text('Действия')),
                    ],
                    rows: [
                      _buildRow('Минутный ViRent Ташкент', 'Minute', '500000 Тийны'),
                      _buildRow('Минутный ИП Асилбеков', 'Minute', '500000 Тийны'),
                      _buildRow('TEST', 'test', '100000 Тийны'),
                      _buildRow('для 30мин ViRent Ташкент', 'Минутный', '500000 Тийны'),
                      _buildRow('для 60мин ViRent Ташкент', 'минутный', '500000 Тийны'),
                      _buildRow('Для 30мин ИП Асилбеков', 'Минутный', '500000 Тийны'),
                      _buildRow('Для 60мин ИП Асилбеков', 'Hour', '500000 Тийны'),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  )
  }

  DataRow _buildRow(String nameAdmin, String nameApp, String hold) {
    return DataRow(cells: [
      DataCell(Text(nameAdmin)),
      DataCell(Text(nameApp, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(hold)),
      DataCell(Row(
        children: [
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.map, size: 14), label: const Text('Геозоны завершения')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Редактировать')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete, size: 14), label: const Text('Удалить')),
        ],
      )),
    ]);
  )
  }
}
