import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/widgets/virent_ui.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../data/models/payment_card_model.dart';

/// Payment methods screen — Russian-language redesign matching reference
/// screens 04 / 26.
///
/// Layout (top → bottom):
///   1. AppBar "Способ оплаты" centered (white bg, back arrow).
///   2. "Новая карта" hero card — white, 8px radius, hairline border, 16px
///      padding. "+" icon (lime green) + title + subtitle "Мир, Visa,
///      Mastercard" + chevron-right. Tap opens the add-card sheet.
///   3. Saved cards list — 56px rows, white bg, hairline dividers; brand
///      chip + masked PAN + expiry + checkmark on the default card.
///   4. "Другие способы оплаты" section header.
///   5. Alt payment rails — T-Pay (gold), Сбер-Pay (green), СБП (blue).
///   6. Bottom CTA "Добавить карту" — lime green, full width, 48px.
///
/// Business logic (provider, notifier, add-card sheet, formatters) is
/// preserved from the previous implementation.
class PaymentCardsScreen extends ConsumerWidget {
  /// Creates a [PaymentCardsScreen].
  const PaymentCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentCardsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Способ оплаты',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: state.cards.isEmpty
          ? _EmptyState(onAdd: () => _showAddCardSheet(context, ref))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _NewCardHero(onTap: () => _showAddCardSheet(context, ref)),
                const SizedBox(height: 16),
                _SavedCardsSection(
                  cards: state.cards,
                  onSetDefault: (id) => ref
                      .read(paymentCardsProvider.notifier)
                      .setDefault(id),
                  onDismissed: (id) =>
                      ref.read(paymentCardsProvider.notifier).remove(id),
                  onConfirmDelete: (card) => _confirmDelete(context, card),
                ),
                const SizedBox(height: 24),
                _AltPaymentsSection(),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: CtaButton(
            label: 'Добавить карту',
            icon: Icons.add,
            height: 48,
            onPressed: () => _showAddCardSheet(context, ref),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, PaymentCard card) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMd),
        ),
        title: const Text('Удалить карту?'),
        content: Text(
          'Удалить ${card.brand.label} ${card.maskedNumber} из сохранённых '
          'способов оплаты?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showAddCardSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<PaymentCard?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppStyles.radiusMd)),
      ),
      builder: (sheetContext) => Padding(
        padding: MediaQuery.of(sheetContext).viewInsets,
        child: _AddCardSheet(),
      ),
    );
    if (result != null) {
      ref.read(paymentCardsProvider.notifier).add(result);
    }
  }
}

// ---- Hero "new card" tile ---------------------------------------------------

class _NewCardHero extends StatelessWidget {
  const _NewCardHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppStyles.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryCta.withValues(alpha: 0.18),
                  borderRadius:
                      BorderRadius.circular(AppStyles.radiusSm),
                ),
                child: const Icon(Icons.add,
                    color: AppColors.primaryCta, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Добавить карту',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Мир, Visa, Mastercard',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Saved cards section ----------------------------------------------------

class _SavedCardsSection extends StatelessWidget {
  const _SavedCardsSection({
    required this.cards,
    required this.onSetDefault,
    required this.onDismissed,
    required this.onConfirmDelete,
  });

  final List<PaymentCard> cards;
  final ValueChanged<String> onSetDefault;
  final ValueChanged<String> onDismissed;
  final Future<bool> Function(PaymentCard) onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Мои карты',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppStyles.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
              color: AppColors.border,
            ),
            itemBuilder: (context, index) {
              final card = cards[index];
              return Dismissible(
                key: ValueKey(card.id),
                direction: DismissDirection.startToEnd,
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius:
                        BorderRadius.circular(AppStyles.radiusSm),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.danger),
                ),
                confirmDismiss: (_) => onConfirmDelete(card),
                onDismissed: (_) => onDismissed(card.id),
                child: _CardRow(
                  card: card,
                  isSelected: card.isDefault,
                  onTap: () => onSetDefault(card.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.card,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentCard card;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brandColor = Color(card.brand.colorValue);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: brandColor,
                borderRadius: BorderRadius.circular(AppStyles.radiusSm),
              ),
              alignment: Alignment.center,
              child: Text(
                card.brand.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${card.brand.label} ${card.maskedNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.expiry,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_off,
              color: isSelected
                  ? AppColors.success
                  : AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Alt payment methods section -------------------------------------------

class _AltPaymentsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final methods = <_AltMethod>[
      _AltMethod(
        label: 'T-Pay',
        subtitle: '•• 1589',
        chipColor: AppColors.brandYellow,
        chipText: 'PAY',
      ),
      _AltMethod(
        label: 'Сбер-Pay',
        subtitle: 'Сбербанк',
        chipColor: AppColors.brandSber,
        chipText: 'Pay',
      ),
      _AltMethod(
        label: 'СБП',
        subtitle: 'Быстрый платёж',
        chipColor: AppColors.brandSbp,
        chipText: 'СБП',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Другие способы оплаты',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppStyles.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: methods.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
              color: AppColors.border,
            ),
            itemBuilder: (context, index) =>
                _AltMethodTile(method: methods[index]),
          ),
        ),
      ],
    );
  }
}

class _AltMethod {
  const _AltMethod({
    required this.label,
    required this.subtitle,
    required this.chipColor,
    required this.chipText,
  });

  final String label;
  final String subtitle;
  final Color chipColor;
  final String chipText;
}

class _AltMethodTile extends StatelessWidget {
  const _AltMethodTile({required this.method});

  final _AltMethod method;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: method.chipColor,
                borderRadius: BorderRadius.circular(AppStyles.radiusSm),
              ),
              alignment: Alignment.center,
              child: Text(
                method.chipText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    method.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}

// ---- Empty state ------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card_off,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Карт пока нет',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавьте карту, чтобы оплачивать поездки в один тап.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),
            CtaButton(
              label: 'Добавить карту',
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Provider & state ------------------------------------------------------

/// Immutable snapshot of the saved-cards feature.
class PaymentCardsState {
  /// Creates a [PaymentCardsState].
  const PaymentCardsState({
    this.cards = const [],
    this.loading = false,
    this.error,
  });

  /// The list of saved cards. The first card flagged [PaymentCard.isDefault]
  /// is the one used for one-tap payments.
  final List<PaymentCard> cards;

  /// `true` while a network operation is in-flight.
  final bool loading;

  /// Human-readable error message, when the last operation failed.
  final String? error;

  /// Returns a copy with the supplied fields replaced.
  PaymentCardsState copyWith({
    List<PaymentCard>? cards,
    bool? loading,
    String? error,
  }) {
    return PaymentCardsState(
      cards: cards ?? this.cards,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// Riverpod provider holding the saved-cards state.
final paymentCardsProvider =
    StateNotifierProvider<PaymentCardsNotifier, PaymentCardsState>((ref) {
  return PaymentCardsNotifier();
});

/// Owning notifier for [paymentCardsProvider].
///
/// Seeded with a couple of demo cards so the wallet UI has something to
/// render before the backend `/wallet/cards` endpoint is wired up.
class PaymentCardsNotifier extends StateNotifier<PaymentCardsState> {
  PaymentCardsNotifier() : super(const PaymentCardsState(cards: _seed));

  static const List<PaymentCard> _seed = [
    PaymentCard(
      id: 'card_42',
      brand: CardBrand.visa,
      last4: '4242',
      expiryMonth: 12,
      expiryYear: 27,
      cardholder: 'JANE DOE',
      isDefault: true,
    ),
    PaymentCard(
      id: 'card_17',
      brand: CardBrand.uzcard,
      last4: '8801',
      expiryMonth: 6,
      expiryYear: 26,
      cardholder: 'JANE DOE',
      isDefault: false,
    ),
  ];

  /// Adds [card] to the list and refreshes the default flag if needed.
  void add(PaymentCard card) {
    final next = [...state.cards, card];
    // If this is the first card, mark it default automatically.
    if (next.length == 1) {
      next[0] = next[0].copyWith(isDefault: true);
    } else if (card.isDefault) {
      // New card claims default — clear the previous default.
      for (var i = 0; i < next.length - 1; i++) {
        next[i] = next[i].copyWith(isDefault: false);
      }
    }
    state = state.copyWith(cards: next);
  }

  /// Removes the card with [id] from the list. If the removed card was the
  /// default, the first remaining card takes over.
  void remove(String id) {
    final next = state.cards.where((c) => c.id != id).toList();
    if (next.isNotEmpty && next.none((c) => c.isDefault)) {
      next[0] = next[0].copyWith(isDefault: true);
    }
    state = state.copyWith(cards: next);
  }

  /// Marks the card with [id] as the default, clearing any previous default.
  void setDefault(String id) {
    final next = state.cards.map((c) {
      return c.copyWith(isDefault: c.id == id);
    }).toList();
    state = state.copyWith(cards: next);
  }
}

/// Convenience extension so we can use `none` on lists above.
extension _IterableX<T> on Iterable<T> {
  bool none(bool Function(T) test) => !any(test);
}

// ---- Add card sheet --------------------------------------------------------

class _AddCardSheet extends StatefulWidget {
  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  CardBrand _detectedBrand = CardBrand.unknown;

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Новая карта',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Карты хранятся безопасно у нашего PCI-DSS провайдера.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _numberController,
                decoration: InputDecoration(
                  labelText: 'Номер карты',
                  hintText: '0000 0000 0000 0000',
                  prefixIcon: const Icon(Icons.credit_card_outlined),
                  suffixIcon: _detectedBrand == CardBrand.unknown
                      ? null
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: _BrandChip(brand: _detectedBrand),
                        ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberFormatter(),
                ],
                validator: (v) {
                  final digits = v?.replaceAll(' ', '') ?? '';
                  if (digits.length < 16) return 'Введите 16 цифр';
                  return null;
                },
                onChanged: (v) => setState(() {
                  _detectedBrand = _detectBrand(v);
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Срок',
                        hintText: 'MM/YY',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryFormatter(),
                      ],
                      validator: (v) {
                        if (v == null || v.length < 5) return 'MM/YY';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvcController,
                      decoration: const InputDecoration(
                        labelText: 'CVC',
                        hintText: '123',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (v) {
                        if (v == null || v.length < 3) return '3 цифры';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя владельца',
                  hintText: 'JANE DOE',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+7 900 123-45-67',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
              ),
              const SizedBox(height: 20),
              CtaButton(
                label: 'Добавить карту',
                icon: Icons.check,
                height: 48,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final card = PaymentCard(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      brand: _detectedBrand == CardBrand.unknown
          ? CardBrand.unknown
          : _detectedBrand,
      last4: _numberController.text.replaceAll(' ', '').substring(12),
      expiryMonth: int.tryParse(_expiryController.text.split('/').first) ?? 0,
      expiryYear: int.tryParse(_expiryController.text.split('/').last) ?? 0,
      cardholder: _nameController.text.trim().toUpperCase(),
      isDefault: false,
    );
    Navigator.of(context).pop(card);
  }

  CardBrand _detectBrand(String number) {
    final digits = number.replaceAll(' ', '');
    if (digits.startsWith('4')) return CardBrand.visa;
    if (RegExp(r'^5[1-5]').hasMatch(digits) ||
        RegExp(r'^2[2-7]').hasMatch(digits)) return CardBrand.mastercard;
    if (digits.startsWith('2200') || digits.startsWith('2204')) {
      return CardBrand.mir;
    }
    if (digits.startsWith('8600')) return CardBrand.uzcard;
    if (digits.startsWith('9860')) return CardBrand.humo;
    return CardBrand.unknown;
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.brand});

  final CardBrand brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color(brand.colorValue),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        brand.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

/// Inserts a space every 4 digits while typing the card number.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Inserts a `/` between the month and year while typing the expiry.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length <= 2) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    final formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
