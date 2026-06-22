import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/widgets/virent_ui.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart'
    show apiClientProvider;
import '../../data/models/ticket_model.dart';
import '../../data/repositories/support_repository.dart';

/// Riverpod-провайдер для [SupportRepository].
final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.read(apiClientProvider));
});

/// Async-список тикетов пользователя.
final ticketsProvider =
    FutureProvider.autoDispose<List<Ticket>>((ref) async {
  return ref.read(supportRepositoryProvider).getTickets();
});

/// Чат поддержки — список тикетов + раздел FAQ.
///
/// Стиль референса: AppBar с кнопкой «назад» и заголовком «Чат поддержки»,
/// сверху lime-green CTA «Связаться с нами», ниже — список прошлых тикетов
/// (карточки с темой, статусом и датой), внизу — список FAQ со шеврон-вправо.
///
/// Бизнес-логика, провайдеры, модели тикетов и виджеты создания/детали
/// сохранены без изменений — переписан только UI списка.
class SupportScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  Ticket? _selected;
  bool _showCreate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_selected != null) {
              setState(() => _selected = null);
            } else if (_showCreate) {
              setState(() => _showCreate = false);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _titleForState(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: _body(),
    );
  }

  String _titleForState() {
    if (_selected != null) return 'Тикет';
    if (_showCreate) return 'Новый тикет';
    return 'Чат поддержки';
  }

  Widget _body() {
    if (_selected != null) {
      return _TicketDetail(
        ticket: _selected!,
        onClose: () {
          setState(() => _selected = null);
          ref.invalidate(ticketsProvider);
        },
      );
    }
    if (_showCreate) {
      return _CreateTicketForm(
        onCancel: () => setState(() => _showCreate = false),
        onCreated: (ticket) {
          setState(() {
            _showCreate = false;
            _selected = ticket;
          });
          ref.invalidate(ticketsProvider);
        },
      );
    }
    return _SupportList(
      onCreate: () => setState(() => _showCreate = true),
      onSelect: (t) => setState(() => _selected = t),
    );
  }
}

/// Главный список — CTA «Связаться с нами» + список тикетов + FAQ.
class _SupportList extends ConsumerWidget {
  const _SupportList({required this.onCreate, required this.onSelect});

  final VoidCallback onCreate;
  final ValueChanged<Ticket> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ticketsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppStyles.spaceLg, AppStyles.spaceSm, AppStyles.spaceLg, 32),
      children: [
        // CTA «Связаться с нами» — lime-green.
        CtaButton(
          label: 'Связаться с нами',
          icon: Icons.chat_bubble_outline,
          onPressed: onCreate,
          height: 48,
        ),
        const SizedBox(height: AppStyles.spaceXl),

        // Section: Мои обращения.
        const _SectionLabel('Мои обращения'),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _TicketsError(
            message: e.toString(),
            onRetry: () => ref.invalidate(ticketsProvider),
          ),
          data: (tickets) {
            if (tickets.isEmpty) {
              return const _TicketsEmpty();
            }
            return Column(
              children: [
                for (final t in tickets) ...[
                  _TicketCard(ticket: t, onTap: () => onSelect(t)),
                  const SizedBox(height: AppStyles.spaceSm),
                ],
              ],
            );
          },
        ),

        const SizedBox(height: AppStyles.spaceXl),

        // Section: Частые вопросы.
        const _SectionLabel('Частые вопросы'),
        _FaqList(),
      ],
    );
  }
}

/// Карточка тикета — тема + статус + дата + последнее сообщение.
class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});

  final Ticket ticket;
  final VoidCallback onTap;

  String _format(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} д назад';
    return '${t.day.toString().padLeft(2, '0')}.'
        '${t.month.toString().padLeft(2, '0')}.${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppStyles.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(status: ticket.status),
                const Spacer(),
                Text(
                  _format(ticket.updatedAt ?? ticket.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spaceSm),
            Text(
              ticket.subject,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (ticket.lastMessage != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.lastMessage!.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Список FAQ со шеврон-вправо.
class _FaqList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _FaqRow(
            icon: Icons.electric_scooter_outlined,
            question: 'Как арендовать самокат?',
            onTap: () => _showAnswer(
                context,
                'Как арендовать самокат?',
                'Наведите камеру на QR-код на руле самоката или введите код '
                    'вручную. Выберите тариф и нажмите «Начать поездку».'),
          ),
          _FaqRow(
            icon: Icons.local_parking_outlined,
            question: 'Где можно парковать?',
            onTap: () => _showAnswer(
                context,
                'Где можно парковать?',
                'Паркуйте самокат в синих зонах на карте. Завершите поездку, '
                    'сделайте фото припаркованного самоката и подтвердите.'),
          ),
          _FaqRow(
            icon: Icons.payment_outlined,
            question: 'Как оплатить поездку?',
            onTap: () => _showAnswer(
                context,
                'Как оплатить поездку?',
                'Оплата списывается автоматически с привязанной карты в конце '
                    'поездки. Также доступны СБП, T-Pay и Сбер-Pay.'),
          ),
          _FaqRow(
            icon: Icons.account_balance_wallet_outlined,
            question: 'Как пополнить кошелёк?',
            onTap: () => _showAnswer(
                context,
                'Как пополнить кошелёк?',
                'Откройте раздел «Кошелёк» в профиле и нажмите «Пополнить». '
                    'Доступны карты, СБП и промокоды.'),
          ),
          _FaqRow(
            icon: Icons.security_outlined,
            question: 'Что делать при поломке?',
            showDivider: false,
            onTap: () => _showAnswer(
                context,
                'Что делать при поломке?',
                'Завершите поездку безопасно и нажмите «Чат поддержки», чтобы '
                    'сообщить о проблеме. Мы вернём средства за неиспользованное '
                    'время.'),
          ),
        ],
      ),
    );
  }

  void _showAnswer(BuildContext context, String question, String answer) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppStyles.radiusMd)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.spaceXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: AppStyles.spaceMd),
                Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppStyles.spaceLg),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({
    required this.icon,
    required this.question,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String question;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceLg),
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5),
                ),
              )
            : null,
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: AppStyles.spaceLg),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 24),
          ],
        ),
      ),
    );
  }
}

/// Пустое состояние списка тикетов.
class _TicketsEmpty extends StatelessWidget {
  const _TicketsEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceXl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.support_agent,
              size: 48, color: AppColors.textMuted),
          SizedBox(height: AppStyles.spaceMd),
          Text(
            'Нет обращений',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Нажмите «Связаться с нами», чтобы задать вопрос.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

/// Состояние ошибки загрузки тикетов.
class _TicketsError extends StatelessWidget {
  const _TicketsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceXl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppStyles.spaceMd),
          const Text(
            'Не удалось загрузить обращения',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppStyles.spaceSm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppStyles.spaceMd),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

/// Заголовок секции — мелкий серый текст.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppStyles.spaceSm),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

// ---- Создание тикета --------------------------------------------------------

/// Форма создания тикета — сохранена из оригинального экрана, переведена на
/// русский язык и стилизована под референс.
class _CreateTicketForm extends ConsumerStatefulWidget {
  const _CreateTicketForm({required this.onCancel, required this.onCreated});

  final VoidCallback onCancel;
  final ValueChanged<Ticket> onCreated;

  @override
  ConsumerState<_CreateTicketForm> createState() => _CreateTicketFormState();
}

class _CreateTicketFormState extends ConsumerState<_CreateTicketForm> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  TicketType _type = TicketType.breakdown;
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните тему и сообщение')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final ticket = await ref.read(supportRepositoryProvider).createTicket(
            type: _type,
            subject: _subjectController.text.trim(),
            message: _messageController.text.trim(),
          );
      widget.onCreated(ticket);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Новое обращение',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppStyles.spaceSm),
          const Text(
            'Опишите проблему — мы ответим в чате в течение нескольких минут.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppStyles.spaceXl),
          DropdownButtonFormField<TicketType>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Тип обращения',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                  value: TicketType.breakdown,
                  child: Text('Поломка самоката')),
              DropdownMenuItem(
                  value: TicketType.billing, child: Text('Вопрос по оплате')),
              DropdownMenuItem(
                  value: TicketType.account, child: Text('Проблема с аккаунтом')),
              DropdownMenuItem(value: TicketType.other, child: Text('Другое')),
            ],
            onChanged: (v) => setState(() => _type = v ?? TicketType.other),
          ),
          const SizedBox(height: AppStyles.spaceMd),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Тема',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppStyles.spaceMd),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Сообщение',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppStyles.spaceXl),
          Row(
            children: [
              Expanded(
                child: SecondaryCtaButton(
                  label: 'Отмена',
                  onPressed: _submitting ? null : widget.onCancel,
                ),
              ),
              const SizedBox(width: AppStyles.spaceMd),
              Expanded(
                child: CtaButton(
                  label: _submitting ? 'Отправка…' : 'Отправить',
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Детали тикета ----------------------------------------------------------

/// Просмотр тикета с историей сообщений и полем ответа.
class _TicketDetail extends ConsumerStatefulWidget {
  const _TicketDetail({required this.ticket, required this.onClose});

  final Ticket ticket;
  final VoidCallback onClose;

  @override
  ConsumerState<_TicketDetail> createState() => _TicketDetailState();
}

class _TicketDetailState extends ConsumerState<_TicketDetail> {
  final _replyController = TextEditingController();
  late Ticket _ticket = widget.ticket;
  bool _sending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final msg = await ref.read(supportRepositoryProvider).sendMessage(
            ticketId: _ticket.id,
            message: text,
          );
      setState(() {
        _ticket = _ticket.copyWith(
          messages: [..._ticket.messages, msg],
          updatedAt: DateTime.now(),
        );
      });
      _replyController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _close() async {
    try {
      await ref.read(supportRepositoryProvider).closeTicket(_ticket.id);
      widget.onClose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppStyles.spaceLg),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusBadge(status: _ticket.status),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _close,
                    icon: const Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.textSecondary),
                    label: const Text(
                      'Закрыть',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spaceSm),
              Text(
                _ticket.subject,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _ticket.messages.isEmpty
              ? const Center(
                  child: Text(
                    'Нет сообщений',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppStyles.spaceLg),
                  itemCount: _ticket.messages.length,
                  itemBuilder: (_, i) {
                    final m = _ticket.messages[i];
                    return _MessageBubble(message: m);
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(AppStyles.spaceMd),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Введите ответ…',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: AppStyles.spaceSm),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Одно сообщение в тикете — пузырь с именем автора, текстом и временем.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final TicketMessage message;

  String _format(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.spaceMd),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLighter,
              child: Icon(Icons.support_agent,
                  size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: AppStyles.spaceSm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spaceMd, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surfaceAlt,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Text(
                      message.author,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  Text(
                    message.body,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _format(message.createdAt),
                    style: TextStyle(
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textMuted,
                      fontSize: 10,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Бейдж статуса тикета.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TicketStatus status;

  String get _label {
    switch (status) {
      case TicketStatus.open:
        return 'Открыт';
      case TicketStatus.waiting:
        return 'Ожидает';
      case TicketStatus.resolved:
        return 'Решён';
      case TicketStatus.closed:
        return 'Закрыт';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
