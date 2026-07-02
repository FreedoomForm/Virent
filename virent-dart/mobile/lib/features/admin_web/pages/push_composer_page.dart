// push_composer_page.dart — Push notification composer.
//
// Compose and send push notifications to users. Supports:
//   - Title + body
//   - Segment targeting (all / by city / by status)
//   - Scheduled send (future timestamp)
//   - Test send to single user

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart' show apiClientProvider;
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_colors.dart';

class PushComposerPage extends ConsumerStatefulWidget {
  const PushComposerPage({super.key});

  @override
  ConsumerState<PushComposerPage> createState() => _PushComposerPageState();
}

class _PushComposerPageState extends ConsumerState<PushComposerPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _testUserCtrl = TextEditingController();
  String _segment = 'all';
  bool _sending = false;

  static const _segments = {
    'all': 'Всем пользователям',
    'active': 'Активные (в поездке)',
    'registered': 'Зарегистрированные',
    'tashkent': 'Ташкент',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _testUserCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📢 Композер уведомлений',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
          const SizedBox(height: 6),
          Text('Отправьте push-уведомление пользователям',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 24),

          // ── Segment selector ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            color: const Color(0xFFF9FAFB),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Получатели', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _segments.entries.map((e) => ChoiceChip(
                      label: Text(e.value, style: const TextStyle(fontSize: 12)),
                      selected: _segment == e.key,
                      onSelected: (_) => setState(() => _segment = e.key),
                      selectedColor: const Color(0xFF1A1A2E),
                      labelStyle: TextStyle(
                        color: _segment == e.key ? Colors.white : Colors.black87,
                        fontSize: 12))).toList()),
                ]))),
          const SizedBox(height: 16),

          // ── Title ──
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Заголовок',
              hintText: 'Акция! Скидка 20% на все поездки',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white)),
          const SizedBox(height: 12),

          // ── Body ──
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Текст уведомления',
              hintText: 'Только сегодня — минута поездки всего 300 сум!',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
              alignLabelWithHint: true)),
          const SizedBox(height: 16),

          // ── Actions ──
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty || _sending)
                        ? null
                        : _sendBroadcast,
                    icon: _sending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 18),
                    label: Text(_sending ? 'Отправка...' : 'Отправить всем'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))))),
            ]),
          const SizedBox(height: 12),

          // ── Test send ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            color: const Color(0xFFFFF8E1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.science, size: 16, color: Color(0xFFF57F17)),
                    SizedBox(width: 6),
                    Text('Тестовая отправка', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _testUserCtrl,
                        decoration: InputDecoration(
                          hintText: '+998901234567',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _sendTest,
                      child: const Text('Тест')),
                  ]),
                ]))),
        ]));
  }

  Future<void> _sendBroadcast() async {
    setState(() => _sending = true);
    try {
      await ref.read(apiClientProvider).post('/admin/notifications/send', {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'segment': _segment,
      });
      if (mounted) {
        showAdminSnack(context, 'Уведомление отправлено (сегмент: $_segment)');
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() => _sending = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        showAdminSnack(context, 'Ошибка: $e', isError: true);
      }
    }
  }

  Future<void> _sendTest() async {
    final phone = _testUserCtrl.text.trim();
    if (phone.isEmpty || _titleCtrl.text.isEmpty) return;
    try {
      await ref.read(apiClientProvider).post('/admin/notifications/send', {
        'title': '[ТЕСТ] ${_titleCtrl.text.trim()}',
        'body': _bodyCtrl.text.trim(),
        'segment': 'test',
        'test_phone': phone,
      });
      if (mounted) {
        showAdminSnack(context, 'Тест отправлен на $phone');
      }
    } catch (e) {
      if (mounted) {
        showAdminSnack(context, 'Ошибка: $e', isError: true);
      }
    }
  }
}
