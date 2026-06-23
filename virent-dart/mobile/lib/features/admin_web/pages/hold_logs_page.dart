import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class HoldLogsPage extends ConsumerWidget {
  const HoldLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hold Logs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _dateInput(),
                    const SizedBox(width: 8),
                    _dateInput(),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF7B68EE), borderRadius: BorderRadius.circular(3)),
                      child: const Text('Filter', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1400,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF8F9FA),
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
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ref.watch(holdLogsProvider).when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Ошибка: $e')),
                        data: (items) => items.isEmpty
                          ? const Center(child: Text('Нет записей...', style: TextStyle(fontSize: 11, color: Colors.grey)))
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final item = items[i];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 2, child: Text(item['transaction_id']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 1, child: Text(item['client_id']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 2, child: Text(item['type_request_1']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 3, child: Text(item['timestamp_type_request_1']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 1, child: Text(item['order_id']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 1, child: Text(item['amount']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 2, child: Text(item['request_source']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 2, child: Text(item['status_response_1']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 2, child: Text(item['type_request_2']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                    ],
                                  ),
                                );
                              },
                            ),
                      ),
                    ),
                    const Divider(height: 1),
                    Container(
                      color: const Color(0xFFF8F9FA),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateInput() {
    return Container(
      width: 120,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('mm/dd/yyyy', style: TextStyle(fontSize: 11, color: Colors.grey)),
          Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
        ],
      ),
    );
  }
}
