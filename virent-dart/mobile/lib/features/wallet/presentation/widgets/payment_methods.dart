import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';

/// Metadata describing a single payment method shown in the wallet screen.
class PaymentMethod {
  /// Stable identifier persisted with the top-up request (`click`, `payme`,
  /// `prepaid`).
  final String id;

  /// Human readable label.
  final String label;

  /// Material icon rendered in the leading avatar.
  final IconData icon;

  /// Accent colour used for the icon background.
  final Color accent;

  /// Short subtitle shown beneath the label.
  final String subtitle;

  /// `true` when this method is currently selected.
  final bool selected;

  /// Creates a [PaymentMethod].
  const PaymentMethod({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
    required this.subtitle,
    this.selected = false,
  });

  /// Returns a copy with the given fields overridden.
  PaymentMethod copyWith({bool? selected}) {
    return PaymentMethod(
      id: id,
      label: label,
      icon: icon,
      accent: accent,
      subtitle: subtitle,
      selected: selected ?? this.selected,
    );
  }
}

/// Provider exposing the ordered list of selectable payment methods.
///
/// Virent launches in Uzbekistan so the default set is Click, Payme and a
/// prepaid wallet card — the three rails supported by the backend.
final paymentMethodsProvider =
    StateNotifierProvider<PaymentMethodsNotifier, List<PaymentMethod>>((ref) {
  return PaymentMethodsNotifier();
});

/// Notifier that owns the selected payment method.
class PaymentMethodsNotifier extends StateNotifier<List<PaymentMethod>> {
  PaymentMethodsNotifier()
      : super(const [
          PaymentMethod(
            id: 'click',
            label: 'Click',
            icon: Icons.account_balance_wallet_rounded,
            accent: Color(0xFF00B9FD),
            subtitle: 'Pay with Click wallet',
            selected: true,
          ),
          PaymentMethod(
            id: 'payme',
            label: 'Payme',
            icon: Icons.qr_code_rounded,
            accent: Color(0xFF33CCCC),
            subtitle: 'Pay with Payme',
          ),
          PaymentMethod(
            id: 'prepaid',
            label: 'Prepaid card',
            icon: Icons.credit_card_rounded,
            accent: AppColors.primary,
            subtitle: 'Visa / Mastercard',
          ),
        ]);

  /// Returns the currently selected method.
  PaymentMethod get selected =>
      state.firstWhere((m) => m.selected, orElse: () => state.first);

  /// Marks the method with [id] as the only selected one.
  void select(String id) {
    state = [
      for (final m in state) m.copyWith(selected: m.id == id),
    ];
  }
}

/// Selector widget for the user's preferred top-up method.
///
/// Renders a horizontal list of cards; tapping one updates
/// [paymentMethodsProvider] so the rest of the wallet screen can react.
class PaymentMethods extends ConsumerWidget {
  /// Creates a [PaymentMethods] widget.
  const PaymentMethods({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final methods = ref.watch(paymentMethodsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment methods',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: methods.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final m = methods[index];
              return _PaymentMethodTile(
                method: m,
                onTap: () =>
                    ref.read(paymentMethodsProvider.notifier).select(m.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final VoidCallback onTap;

  const _PaymentMethodTile({required this.method, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusSm),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: method.selected
                ? AppColors.primaryLight
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusSm),
            border: Border.all(
              color: method.selected
                  ? AppColors.primary
                  : AppColors.border,
              width: method.selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: method.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(method.icon, color: method.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      method.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                method.selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: method.selected
                    ? AppColors.primary
                    : AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
