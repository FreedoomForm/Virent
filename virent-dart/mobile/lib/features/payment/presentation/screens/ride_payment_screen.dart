import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/widgets/virent_ui.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../providers/promo_provider.dart';

/// Ride payment screen — Russian-language redesign shown after a ride ends.
///
/// Layout (top → bottom):
///   1. AppBar "Оплата поездки" centered (white bg, close X).
///   2. Map preview placeholder (~40% height, light gray).
///   3. Bottom sheet (16px top radius, white bg, 24px padding):
///      - "Поездка завершена" caption (14px gray, centered).
///      - Total cost "312 сум" (32px Bold, centered).
///      - Trip stats row — Дистанция / Время / Скорость (3 columns).
///      - Tariff breakdown — base + per-minute + tax − promo = total.
///      - Promo code input with "Применить" button.
///      - Payment method selector — "T-Банк • 1589" + chevron.
///      - "Оплатить" CTA (lime green, 56px, full width).
///
/// Business logic (promo provider, payment processing, navigation) is
/// preserved from the previous implementation.
class RidePaymentScreen extends ConsumerStatefulWidget {
  /// Server-side identifier of the ride being paid for.
  final String rideId;

  /// Ride duration in minutes (used for the per-minute line item).
  final int duration;

  /// Total cost in the smallest currency unit. Falls back to a computed
  /// value from [duration] when omitted.
  final int? cost;

  /// Battery percentage consumed during the ride (informational).
  final int batteryUsed;

  /// Distance covered, in kilometres (informational).
  final double distance;

  /// Base fare applied to every ride. Defaults to `50` сум.
  final int baseFare;

  /// Per-minute rate. Defaults to `7` сум.
  final int ratePerMin;

  /// Tax rate applied to the subtotal, as a fraction (0.0 – 1.0).
  final double taxRate;

  /// Creates a [RidePaymentScreen].
  const RidePaymentScreen({
    super.key,
    this.rideId = '',
    this.duration = 24,
    this.cost,
    this.batteryUsed = 14,
    this.distance = 3.2,
    this.baseFare = 50,
    this.ratePerMin = 7,
    this.taxRate = 0,
  });

  @override
  ConsumerState<RidePaymentScreen> createState() => _RidePaymentScreenState();
}

class _RidePaymentScreenState extends ConsumerState<RidePaymentScreen> {
  final _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _promoController.addListener(() {
      ref
          .read(promoProvider.notifier)
          .setEnteredCode(_promoController.text);
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  int get _subtotal => widget.baseFare + (widget.duration * widget.ratePerMin);
  int get _tax => (_subtotal * widget.taxRate).round();
  int get _promoDiscount {
    final promo = ref.read(promoProvider).activePromo;
    if (promo == null) return 0;
    return promo.discountFor(_subtotal.toDouble()).round();
  }

  int get _total => _subtotal + _tax - _promoDiscount;

  @override
  Widget build(BuildContext context) {
    final promoState = ref.watch(promoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Оплата поездки',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: Column(
        children: [
          // Map preview placeholder (~40% of available height).
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.32,
            width: double.infinity,
            child: _MapPreviewPlaceholder(),
          ),
          // Bottom sheet with ride summary + payment actions.
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(AppStyles.radiusMd)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  const Text(
                    'Поездка завершена',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_format(_total)} сум',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Trip stats row — Дистанция / Время / Скорость.
                  Row(
                    children: [
                      Expanded(
                        child: StatColumn(
                          label: 'Дистанция',
                          value: '${widget.distance.toStringAsFixed(1)} км',
                        ),
                      ),
                      Expanded(
                        child: StatColumn(
                          label: 'Время',
                          value: '${widget.duration} мин',
                        ),
                      ),
                      Expanded(
                        child: StatColumn(
                          label: 'Скорость',
                          value:
                              '${(widget.distance / widget.duration * 60).toStringAsFixed(0)} км/ч',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _BreakdownCard(
                    duration: widget.duration,
                    baseFare: widget.baseFare,
                    ratePerMin: widget.ratePerMin,
                    subtotal: _subtotal,
                    tax: _tax,
                    taxRate: widget.taxRate,
                    promoDiscount: _promoDiscount,
                    total: _total,
                  ),
                  const SizedBox(height: 16),
                  _PromoSection(
                    controller: _promoController,
                    state: promoState,
                    onApply: () => ref
                        .read(promoProvider.notifier)
                        .validatePromo((_subtotal + _tax).toDouble()),
                    onClear: () {
                      _promoController.clear();
                      ref.read(promoProvider.notifier).clearPromo();
                    },
                  ),
                  if (promoState.message != null) ...[
                    const SizedBox(height: 12),
                    _PromoMessage(state: promoState),
                  ],
                  const SizedBox(height: 16),
                  _PaymentMethodSelector(),
                  const SizedBox(height: 20),
                  CtaButton(
                    label: 'Оплатить',
                    height: 56,
                    fontSize: 18,
                    disabled: promoState.paying,
                    onPressed: promoState.paying ? null : () => _pay('card'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pay(String method) async {
    final notifier = ref.read(promoProvider.notifier);
    final charged = await notifier.processPayment(
      rideId: widget.rideId.isEmpty ? 'demo-ride' : widget.rideId,
      method: method,
      total: _total.toDouble(),
    );
    if (!mounted) return;
    if (charged != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Оплачено ${_format(charged)} сум'),
          behavior: SnackBarBehavior.floating,
        ));
      context.go('/');
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Оплата не прошла — попробуйте ещё раз'),
          behavior: SnackBarBehavior.floating,
        ));
    }
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

// ---- Map preview placeholder ------------------------------------------------

class _MapPreviewPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgMap,
      child: Stack(
        children: [
          // Faux map grid.
          Positioned.fill(
            child: CustomPaint(painter: _MapGridPainter()),
          ),
          // Centre marker — black dot.
          Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---- Tariff breakdown -------------------------------------------------------

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.duration,
    required this.baseFare,
    required this.ratePerMin,
    required this.subtotal,
    required this.tax,
    required this.taxRate,
    required this.promoDiscount,
    required this.total,
  });

  final int duration;
  final int baseFare;
  final int ratePerMin;
  final int subtotal;
  final int tax;
  final double taxRate;
  final int promoDiscount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row('Базовый тариф', '${_format(baseFare)} сум'),
          _divider(),
          _row(
            'Поминутно ($duration мин × ${_format(ratePerMin)} сум)',
            '${_format(duration * ratePerMin)} сум',
          ),
          if (taxRate > 0) ...[
            _divider(),
            _row(
              'Налог (${(taxRate * 100).toStringAsFixed(0)}%)',
              '${_format(tax)} сум',
            ),
          ],
          if (promoDiscount > 0) ...[
            _divider(),
            _row(
              'Промокод',
              '- ${_format(promoDiscount)} сум',
              valueColor: AppColors.success,
            ),
          ],
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Итого',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  '${_format(total)} сум',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      );

  Widget _divider() =>
      const Divider(height: 1, thickness: 0.5, color: AppColors.border);

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

// ---- Promo section ---------------------------------------------------------

class _PromoSection extends StatelessWidget {
  const _PromoSection({
    required this.controller,
    required this.state,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController controller;
  final PromoState state;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined,
              color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              enabled: !state.validating && !state.hasActivePromo,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintText: 'Промокод',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontFamily: 'Inter',
                ),
                border: InputBorder.none,
                isCollapsed: false,
                suffixIcon: state.hasActivePromo
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textMuted, size: 18),
                        onPressed: onClear,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: TextButton(
              onPressed: state.validating || state.hasActivePromo
                  ? null
                  : onApply,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: state.validating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Применить',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoMessage extends StatelessWidget {
  const _PromoMessage({required this.state});

  final PromoState state;

  @override
  Widget build(BuildContext context) {
    final color = state.isSuccess
        ? AppColors.success
        : state.isError
            ? AppColors.danger
            : AppColors.info;
    final bg = state.isSuccess
        ? AppColors.successBg
        : state.isError
            ? AppColors.dangerBg
            : AppColors.infoBg;
    final icon = state.isSuccess
        ? Icons.check_circle_outline
        : state.isError
            ? Icons.error_outline
            : Icons.info_outline;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.message ?? '',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Payment method selector ----------------------------------------------

class _PaymentMethodSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppStyles.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandYellow,
                  borderRadius: BorderRadius.circular(AppStyles.radiusSm),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'T',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'T-Банк • 1589',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
