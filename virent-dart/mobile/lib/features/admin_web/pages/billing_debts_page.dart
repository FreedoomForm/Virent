import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';


class BillingDebtsPage extends ConsumerWidget {
  const BillingDebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(billingTransactionsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
      data: (items) Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('Entries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                    SizedBox(width: 12),
                    Text('Показано 0 до 0 из 0 совпадений (отфильтровано из 3 совпадений)',
                        style: TextStyle(fontSize: 11, color: Color(0xFFE74C3C))),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _labeledInput('ID клиента', 100),
                      const SizedBox(width: 8),
                      _labeledInput('ID заказа', 100),
                      const SizedBox(width: 8),
                      const Text('Дата ▼', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1C40F), borderRadius: BorderRadius.circular(3)),
                        child: const Text('Завершённые', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Попыток списания:', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 60,
                        height: 28,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'От',
                            hintStyle: const TextStyle(fontSize: 10),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 60,
                        height: 28,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'До',
                            hintStyle: const TextStyle(fontSize: 10),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(onTap: () {}, child: Icon(Icons.close, size: 14, color: Colors.grey[500])),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE74C3C), borderRadius: BorderRadius.circular(3)),
                        child: const Text('Очистить фильтры', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1800,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 50, child: Text('ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Client', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Order', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 130, child: Text('General order sum', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Total sum', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Sum card', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Sum bonus', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Try withdrawals', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Type', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Created', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Updated', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Company', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Действия', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const Expanded(
                      child: Center(
                        child: Text('Совпадений не найдено', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.download, size: 14),
                            label: const Text('Экспорт ▼', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.view_column, size: 14),
                            label: const Text('Видимость колонок ▼', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                          ),
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
  }

  Widget _labeledInput(String label, double width) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
        const SizedBox(width: 4),
        SizedBox(
          width: width,
          height: 28,
          child: TextField(
            decoration: InputDecoration(
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
  )
  }
}
