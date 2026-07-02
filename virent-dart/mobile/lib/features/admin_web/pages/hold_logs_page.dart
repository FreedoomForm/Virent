import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';

class HoldLogsPage extends ConsumerWidget {
  const HoldLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(holdLogsProvider);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Логи удержаний', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _dateInput(),
                    const SizedBox(width: 8),
                    _dateInput(),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: adminPrimary, borderRadius: BorderRadius.circular(3)),
                      child: const Text('Фильтр', style: TextStyle(color: Colors.white, fontSize: 11))),
                  ]),
              ])),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1400,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('transaction_id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 1, child: Text('client_id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text('type_request_1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 3, child: Text('timestamp_type_request_1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 1, child: Text('order_id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 1, child: Text('amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text('request_source', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text('status_response_1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text('type_request_2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ])),
                    const Divider(height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Center(
                        child: Text('Нет записей...', style: TextStyle(fontSize: 11, color: Colors.grey)))),
                    const Divider(height: 1),
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('transaction_id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 1, child: Text('client_id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text('type_request_1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 3, child: Text('timestamp_type_request_1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 1, child: Text('order_id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 1, child: Text('amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text('request_source', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text('status_response_1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text('type_request_2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ])),
                    const Divider(height: 1),
                    const Expanded(child: SizedBox()), // Fill remaining space
                  ])))),
        ]));
      });
  }

  Widget _dateInput() {
    return Container(
      width: 120,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: adminBorder),
        borderRadius: BorderRadius.circular(3)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('mm/dd/yyyy', style: TextStyle(fontSize: 11, color: Colors.grey)),
          Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
        ]));
  }
}
