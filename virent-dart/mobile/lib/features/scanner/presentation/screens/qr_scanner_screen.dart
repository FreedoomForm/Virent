import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../common/widgets/virent_ui.dart';
import '../../../../core/configs/theme/app_colors.dart';
import '../../../../core/configs/theme/app_styles.dart';
import '../../../rides/presentation/providers/ride_provider.dart';
import '../widgets/manual_entry_form.dart';

/// QR scanner screen — full-screen camera + bottom ride-confirmation sheet.
///
/// Russian-language redesign matching reference screens 07 / 28.
///
/// Layout (Stack over the live camera feed):
///   1. Top-left: 40×40 white square — close (X) button, 8px radius.
///   2. Top-right: 40×40 white square — torch toggle, 8px radius.
///   3. Centre: 240×240 viewfinder — dim backdrop cutout + 4 white corner
///      brackets + animated green scan line.
///   4. Bottom-centre: 60×60 white circular FAB — manual code entry.
///   5. Bottom sheet (16px top radius, white bg, 20px padding):
///      - Scooter info — "Swift Neo" + "V567R" + green battery range.
///      - Tariff selector — "Поминутный" (black, selected) vs "Фиксированный"
///        (gray, unselected).
///      - Payment method — "T-Банк • 1589" with yellow T-Bank chip.
///      - "Начать поездку" CTA — lime green, 56px, full width.
///
/// Business logic (mobile_scanner integration, ride start, navigation to
/// `/active-ride`, loading dialog, manual entry) is preserved.
class QrScannerScreen extends ConsumerStatefulWidget {
  /// Creates a [QrScannerScreen].
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _isTorchOn = false;
  bool _isFrontCamera = false;
  bool _isProcessing = false;
  bool _minuteTariff = true;

  /// Scooter id used when the rider taps "Начать поездку" without scanning.
  /// Matches the static scooter info shown on the confirmation sheet.
  static const _scooterId = 'V567R';

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    for (final barcode in barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        _handleScannedCode(value);
        return;
      }
    }
  }

  Future<void> _handleScannedCode(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _scannerController.stop();
    } catch (_) {
      // Stop failures are non-fatal — the dialog still shows.
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const _LoadingDialog(message: 'Запускаем поездку…'),
    );

    final ride = await ref.read(rideNotifierProvider.notifier).startRide(
          scooterId: code,
        );

    if (!mounted) return;
    if (mounted) Navigator.of(context).pop(); // close the loading dialog

    if (ride != null) {
      // Refresh ride history in the background so the trips screen is up to
      // date when the ride ends.
      unawaited(ref.read(rideNotifierProvider.notifier).refresh());
      if (!mounted) return;
      context.go(
        '/active-ride?tripId=${ride.id}&scooterId=${ride.scooterId}',
      );
    } else {
      final error =
          ref.read(rideNotifierProvider).error ?? 'Не удалось начать поездку';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          action: SnackBarAction(
            label: 'Повторить',
            textColor: Colors.white,
            onPressed: () => _handleScannedCode(code),
          ),
        ),
      );
      // Resume scanning so the rider can try again.
      try {
        await _scannerController.start();
      } catch (_) {
        // Ignore start failures — the user can also type the id manually.
      }
    }
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _showManualEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: ManualEntryForm(
          onClose: () => Navigator.of(context).maybePop(),
          onSubmit: (code) {
            Navigator.of(context).maybePop();
            _handleScannedCode(code);
          },
        ),
      ),
    );
  }

  void _toggleTorch() {
    setState(() => _isTorchOn = !_isTorchOn);
    _scannerController.toggleTorch();
  }

  void _switchCamera() {
    setState(() => _isFrontCamera = !_isFrontCamera);
    _scannerController.switchCamera();
  }

  void _confirmStart() {
    // Funnel the manual "Начать поездку" tap through the same handler as a
    // successful QR scan so the ride-start flow stays single-path.
    _handleScannedCode(_scooterId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Camera preview fills the entire screen.
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),
          // Dark fallback gradient — visible only before the camera frame is
          // rendered, prevents the white flash on cold start.
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.black54],
                  ),
                ),
              ),
            ),
          ),
          // Top bar — close (X) + flash toggle.
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MapControlButton(
                  icon: Icons.close,
                  onPressed: () => context.go('/'),
                ),
                MapControlButton(
                  icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  onPressed: _toggleTorch,
                  iconColor: _isTorchOn ? AppColors.primary : null,
                ),
              ],
            ),
          ),
          // Center viewfinder — dimmed backdrop cutout + corner brackets +
          // animated scan line.
          const Positioned.fill(child: _QrViewfinder()),
          // Bottom-centre FAB — manual code entry.
          Positioned(
            left: 0,
            right: 0,
            bottom: 220,
            child: Center(
              child: MapFab(
                icon: Icons.qr_code,
                onPressed: _showManualEntry,
              ),
            ),
          ),
          // Bottom ride-confirmation sheet.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _RideStartSheet(
              isMinuteTariff: _minuteTariff,
              onTariffChanged: (v) => setState(() => _minuteTariff = v),
              onStart: _confirmStart,
              onSwitchCamera: _switchCamera,
            ),
          ),
          // Invisible helper that ensures the scanner is started once
          // after the first frame.
          Positioned.fill(
            child: IgnorePointer(
              child: _CameraStarter(controller: _scannerController),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Viewfinder -------------------------------------------------------------

class _QrViewfinder extends StatefulWidget {
  const _QrViewfinder();

  @override
  State<_QrViewfinder> createState() => _QrViewfinderState();
}

class _QrViewfinderState extends State<_QrViewfinder>
    with SingleTickerProviderStateMixin {
  static const double _scanSize = 240;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Dimmed backdrop with a transparent hole for the scan area.
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.55),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(color: Colors.transparent),
                Center(
                  child: Container(
                    width: _scanSize,
                    height: _scanSize,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Corner brackets.
          Center(
            child: SizedBox(
              width: _scanSize,
              height: _scanSize,
              child: const Stack(
                children: [
                  _CornerBracket(alignment: Alignment.topLeft),
                  _CornerBracket(alignment: Alignment.topRight),
                  _CornerBracket(alignment: Alignment.bottomLeft),
                  _CornerBracket(alignment: Alignment.bottomRight),
                ],
              ),
            ),
          ),
          // Animated scan line.
          Center(
            child: SizedBox(
              width: _scanSize - 16,
              height: _scanSize - 16,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  return Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: t * (_scanSize - 24),
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Hint label below the viewfinder.
          Positioned(
            left: 0,
            right: 0,
            bottom: 280,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Сканируйте QR-код',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    const double length = 32;
    const double thickness = 4;
    const Color color = Colors.white;
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: length,
        height: length,
        child: Stack(
          children: [
            if (alignment == Alignment.topLeft ||
                alignment == Alignment.topRight)
              const Align(
                alignment: Alignment.topCenter,
                child:
                    SizedBox(width: length, height: thickness, child: ColoredBox(color: color)),
              ),
            if (alignment == Alignment.bottomLeft ||
                alignment == Alignment.bottomRight)
              const Align(
                alignment: Alignment.bottomCenter,
                child:
                    SizedBox(width: length, height: thickness, child: ColoredBox(color: color)),
              ),
            if (alignment == Alignment.topLeft ||
                alignment == Alignment.bottomLeft)
              const Align(
                alignment: Alignment.centerLeft,
                child:
                    SizedBox(width: thickness, height: length, child: ColoredBox(color: color)),
              ),
            if (alignment == Alignment.topRight ||
                alignment == Alignment.bottomRight)
              const Align(
                alignment: Alignment.centerRight,
                child:
                    SizedBox(width: thickness, height: length, child: ColoredBox(color: color)),
              ),
          ],
        ),
      ),
    );
  }
}

// ---- Ride start bottom sheet -----------------------------------------------

class _RideStartSheet extends StatelessWidget {
  const _RideStartSheet({
    required this.isMinuteTariff,
    required this.onTariffChanged,
    required this.onStart,
    required this.onSwitchCamera,
  });

  final bool isMinuteTariff;
  final ValueChanged<bool> onTariffChanged;
  final VoidCallback onStart;
  final VoidCallback onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppStyles.radiusMd)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header — scooter name + ID.
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Swift Neo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const Text(
                'V567R',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSwitchCamera,
                child: const Icon(Icons.cameraswitch_outlined,
                    color: AppColors.textSecondary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Battery status row.
          Row(
            children: const [
              Icon(Icons.battery_full, color: AppColors.success, size: 16),
              SizedBox(width: 6),
              Text(
                '100% до 40 км на 5 ч 32 мин',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.success,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tariff selector — two side-by-side cards.
          Row(
            children: [
              Expanded(
                child: _TariffCard(
                  label: 'Поминутный',
                  price: '50 сум + 7 сум/мин',
                  selected: isMinuteTariff,
                  onTap: () => onTariffChanged(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TariffCard(
                  label: 'Фиксированный',
                  price: '249 сум / час',
                  selected: !isMinuteTariff,
                  onTap: () => onTariffChanged(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Payment method row.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppStyles.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'T',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Start ride CTA.
          CtaButton(
            label: 'Начать поездку',
            height: 56,
            fontSize: 18,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _TariffCard extends StatelessWidget {
  const _TariffCard({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.black : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.black : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppStyles.radiusSm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                price,
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Helpers ----------------------------------------------------------------

/// Invisible helper that ensures the scanner is started once after the
/// first frame so the OS permission prompt is surfaced before we attempt
/// to read barcodes.
class _CameraStarter extends StatefulWidget {
  const _CameraStarter({required this.controller});

  final MobileScannerController controller;

  @override
  State<_CameraStarter> createState() => _CameraStarterState();
}

class _CameraStarterState extends State<_CameraStarter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await widget.controller.start();
      } catch (_) {
        // Permission denied or camera unavailable — the rider can still
        // use the manual entry form.
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Animated loading dialog shown while the start-ride request is in
/// flight.
class _LoadingDialog extends StatefulWidget {
  const _LoadingDialog({required this.message});

  final String message;

  @override
  State<_LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<_LoadingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: child,
                );
              },
              child: Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: const Icon(
                  Icons.electric_scooter,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
