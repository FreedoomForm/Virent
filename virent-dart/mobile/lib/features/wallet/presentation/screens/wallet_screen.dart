import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/widgets/virent_ui.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../data/models/transaction_model.dart';
import '../providers/wallet_provider.dart';
import '../widgets/payment_methods.dart';
import 'payment_cards_screen.dart';

/// Wallet screen — Russian-language redesign matching reference screens 04/26.
///
/// Layout (top → bottom):
///   1. Balance card (green gradient, 16px radius) — "Баланс" / value сум /
///      "Пополнить" pill button.
///   2. Quick top-up grid — 4 chips (1000сум, 2000сум, 5000сум, 10000сум) in a 2×2
///      grid with hairline borders.
///   3. "Транзакции" header + see-all link.
///   4. Transaction list — each row shows coloured icon + title + date +
///      signed amount (green/red) with hairline dividers.
///   5. "Добавить карту" CTA — lime-green, full width, navigates to
///      [PaymentCardsScreen].
///
/// State is driven by [walletProvider]; payment-method selection is owned by
/// [paymentMethodsProvider]. All business logic from the previous
/// implementation is preserved.
class WalletScreen extends ConsumerStatefulWidget {
  /// Creates a [WalletScreen].
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  static const List<int> _quickAmounts = [1000, 2000, 5000, 10000];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Кошелёк',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => ref.read(walletProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textPrimary, size: 22),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(walletProvider.notifier).refresh(),
        child: state.loading && state.transactions.isEmpty
            ? const _WalletSkeleton()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _BalanceCard(
                    balance: state.balance,
                    actionInProgress: state.actionInProgress,
                    onTopUp: _showAddMoneySheet,
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: state.error!),
                  ],
                  const SizedBox(height: 16),
                  _QuickTopUpGrid(
                    amounts: _quickAmounts,
                    disabled: state.actionInProgress,
                    onTopUp: _topUp,
                  ),
                  const SizedBox(height: 24),
                  _TransactionsHeader(),
                  const SizedBox(height: 8),
                  _TransactionsList(transactions: state.transactions),
                  const SizedBox(height: 20),
                  CtaButton(
                    label: 'Добавить карту',
                    icon: Icons.add,
                    height: 48,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaymentCardsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  // ---- Actions -------------------------------------------------------------

  Future<void> _topUp(int amount) async {
    final provider = ref.read(paymentMethodsProvider.notifier).selected.id;
    final ok = await ref
        .read(walletProvider.notifier)
        .topUp(amount, provider: provider);
    if (!mounted) return;
    _snack(ok
        ? 'Кошелёк пополнен на ${_format(amount)} сум'
        : 'Не удалось пополнить — попробуйте ещё раз');
  }

  Future<void> _showAddMoneySheet() async {
    final controller = TextEditingController();
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppStyles.radiusMd)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
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
              const SizedBox(height: 16),
              const Text(
                'Пополнение кошелька',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Введите сумму в сумах',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                autofocus: true,
                decoration: const InputDecoration(
                  prefixText: 'сум ',
                  hintText: '1000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              CtaButton(
                label: 'Пополнить',
                onPressed: () {
                  final value = int.tryParse(controller.text.trim());
                  if (value != null && value > 0) {
                    Navigator.pop(sheetContext, value);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (amount != null && amount > 0) {
      await _topUp(amount);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  static String _format(int value) {
    final str = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return value < 0 ? '-${buffer.toString()}' : buffer.toString();
  }
}

// ---- Balance card -----------------------------------------------------------

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.actionInProgress,
    required this.onTopUp,
  });

  final int balance;
  final bool actionInProgress;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Баланс',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_WalletScreenState._format(balance)} сум',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppStyles.radiusSm),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusSm),
                      onTap: actionInProgress ? null : onTopUp,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add, color: AppColors.black, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Пополнить',
                              style: TextStyle(
                                color: AppColors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Quick top-up grid ------------------------------------------------------

class _QuickTopUpGrid extends StatelessWidget {
  const _QuickTopUpGrid({
    required this.amounts,
    required this.disabled,
    required this.onTopUp,
  });

  final List<int> amounts;
  final bool disabled;
  final ValueChanged<int> onTopUp;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.6,
      ),
      itemCount: amounts.length,
      itemBuilder: (context, index) {
        final amount = amounts[index];
        return Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppStyles.radiusSm),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppStyles.radiusSm),
            onTap: disabled ? null : () => onTopUp(amount),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppStyles.radiusSm),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                '${_WalletScreenState._format(amount)} сум',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---- Transactions section ---------------------------------------------------

class _TransactionsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Транзакции',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/trips'),
          child: const Text(
            'Все',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppStyles.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 32, color: AppColors.textMuted),
              SizedBox(height: 8),
              Text(
                'Транзакций пока нет',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 0.5,
          indent: 16,
          endIndent: 16,
          color: AppColors.border,
        ),
        itemBuilder: (context, index) =>
            _TransactionTile(transaction: transactions[index]),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final accent =
        isCredit ? AppColors.success : AppColors.danger;
    final icon = _iconFor(transaction, isCredit);
    final title = transaction.description.isEmpty
        ? _titleForType(transaction.type)
        : transaction.description;
    final subtitle = _subtitleFor(transaction);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppStyles.radiusSm),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isCredit ? '+' : '-'}${_WalletScreenState._format(transaction.absoluteAmount)} сум',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: accent,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(TransactionModel tx, bool isCredit) {
    final type = tx.type.toLowerCase();
    if (type == 'topup' || type == 'top_up' || isCredit) {
      return Icons.arrow_downward;
    }
    if (type == 'penalty') return Icons.warning_amber_rounded;
    if (type == 'ride' || type == 'fare') return Icons.directions_bike;
    return isCredit ? Icons.arrow_downward : Icons.arrow_upward;
  }

  String _titleForType(String type) {
    switch (type.toLowerCase()) {
      case 'topup':
      case 'top_up':
        return 'Пополнение';
      case 'ride':
      case 'fare':
        return 'Поездка';
      case 'penalty':
        return 'Штраф';
      case 'refund':
        return 'Возврат';
      case 'promo':
      case 'reward':
        return 'Бонус';
      default:
        return 'Операция';
    }
  }

  String _subtitleFor(TransactionModel tx) {
    final date = _formatDate(tx.createdAt);
    final type = tx.type.toLowerCase();
    if (type == 'penalty') return 'Штраф · $date';
    if (type == 'ride' || type == 'fare') return 'Аренда самоката · $date';
    if (type == 'topup' || type == 'top_up') return 'Пополнение · $date';
    return date;
  }

  static String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso.length > 16 ? iso.substring(0, 16) : iso;
    final d = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} · ${two(d.hour)}:${two(d.minute)}';
  }
}

// ---- Misc -------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletSkeleton extends StatelessWidget {
  const _WalletSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 48),
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
        SizedBox(height: 48),
      ],
    );
  }
}
