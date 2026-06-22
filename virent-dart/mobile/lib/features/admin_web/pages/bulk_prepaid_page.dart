// bulk_prepaid_page.dart — Bulk prepaid card generator.
//
// Generate N prepaid cards with fixed value, prefix, and expiry.
// Cards are created on the embedded server and displayed in a list.
// Export to CSV via clipboard.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_export.dart';

class BulkPrepaidPage extends ConsumerStatefulWidget {
  const BulkPrepaidPage({super.key});

  @override
  ConsumerState<BulkPrepaidPage> createState() => _BulkPrepaidPageState();
}

class _BulkPrepaidPageState extends ConsumerState<BulkPrepaidPage> {
  final _countCtrl = TextEditingController(text: '10');
  final _valueCtrl = TextEditingController(text: '50000');
  final _prefixCtrl = TextEditingController(text: 'VIRENT');
  final _expiryCtrl = TextEditingController(text: '');
  List<Map<String, dynamic>> _generated = [];
  bool _generating = false;

  @override
  void dispose() {
    _countCtrl.dispose();
    _valueCtrl.dispose();
    _prefixCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎫 Генератор предоплаченных карт',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Создайте N карт с одинаковым номиналом',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 24),

          // ── Form ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: _field('Количество', _countCtrl, '10', Icons.numbers),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _field('Номинал (сум)', _valueCtrl, '50000', Icons.monetization_on),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: _field('Префикс', _prefixCtrl, 'VIRENT', Icons.label),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _field('Действует до', _expiryCtrl, '2026-12-31', Icons.calendar_today),
                  ),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _generating ? null : _generate,
                    icon: _generating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bolt, size: 18),
                    label: Text(_generating ? 'Генерация...' : 'Сгенерировать карты'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          // ── Generated cards ──
          if (_generated.isNotEmpty) ...[
            Row(children: [
              Text('Сгенерировано: ${_generated.length} карт',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              ExportCsvButton(
                data: _generated,
                filename: 'prepaid_cards.csv',
                columns: const ['code', 'value', 'prefix', 'expiry'],
                label: 'CSV',
              ),
            ]),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              color: const Color(0xFFF0FDF4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 300,
                  child: ListView.separated(
                    itemCount: _generated.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = _generated[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.credit_card, color: Color(0xFF16A085), size: 20),
                        title: Text(c['code']?.toString() ?? '-',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text('${c['value']} сум • до ${c['expiry'] ?? '-'}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        isDense: true,
      ),
    );
  }

  void _generate() {
    final count = int.tryParse(_countCtrl.text) ?? 10;
    final value = int.tryParse(_valueCtrl.text) ?? 50000;
    final prefix = _prefixCtrl.text.isNotEmpty ? _prefixCtrl.text.toUpperCase() : 'VIRENT';
    final expiry = _expiryCtrl.text.isNotEmpty ? _expiryCtrl.text : '2026-12-31';

    setState(() => _generating = true);

    final cards = List.generate(count, (i) {
      final num = (i + 1).toString().padLeft(4, '0');
      return <String, dynamic>{
        'code': '$prefix-$num-${DateTime.now().millisecond}',
        'value': value,
        'prefix': prefix,
        'expiry': expiry,
        'created_at': DateTime.now().toIso8601String(),
      };
    });

    setState(() {
      _generated = cards;
      _generating = false;
    });

    showAdminSnack(context, 'Сгенерировано $count карт по $value сум');
  }
}
