// virent_ui.dart — Swift Scooter reusable UI components.
//
// Based on the Swift Scooter reference mockup design system:
//   - Bright lime `#D2F56A` primary CTA color
//   - Near-black `#1C1C1E` secondary (selected tariff, send button)
//   - Inter typography
//   - 20 px radius for primary CTAs (16 px on auth)
//   - 24 px radius for cards
//   - 32 px radius for bottom sheets
//   - Soft single-layer shadows

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/configs/theme/app_colors.dart';
import '../../core/configs/theme/app_styles.dart';

// ---- Brand icon ----------------------------------------------------------

/// Swift brand icon — 32×32 black rounded square with a lime `Zap` icon.
/// Used as the leading chip in scooter info cards, ride-complete sheets,
/// parking lists, etc.
class ScooterBrandIcon extends StatelessWidget {
  const ScooterBrandIcon({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Icon(
          LucideIcons.zap,
          color: AppColors.primary,
          size: size * 0.56,
        ),
      ),
    );
  }
}

// ---- Primary CTA ---------------------------------------------------------

/// Primary call-to-action button — full-width, 56 px tall, 20 px radius,
/// lime `#D2F56A` background, black bold 17 px text.
///
/// Matches the "Поехали", "Получить код", "Забронировать самокат",
/// "Сделать фото", "Оформить подписку", "Привязать карту" CTAs.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.disabled = false,
    this.height = 56,
    this.radius = 20,
    this.fontSize = 17,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool disabled;
  final double height;
  final double radius;
  final double fontSize;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onPressed == null;
    final bg = backgroundColor ??
        (isDisabled ? const Color(0xFFF3F4F6) : AppColors.primary);
    final fg = foregroundColor ??
        (isDisabled ? AppColors.textMuted : AppColors.black);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: isDisabled ? null : onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: fg, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Legacy alias for back-compat with screens still using [CtaButton].
class CtaButton extends PrimaryButton {
  const CtaButton({
    super.key,
    required super.label,
    super.onPressed,
    super.disabled,
    super.height = 48,
    super.radius = 16,
    super.fontSize = 16,
    final IconData? icon,
  });
}

/// Secondary CTA — white bg with hairline border. Legacy back-compat alias.
class SecondaryCtaButton extends StatelessWidget {
  const SecondaryCtaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary CTA — gray `#F4F4F6` background, black text. Used for "Пауза".
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.flex = 1,
  });

  final String label;
  final VoidCallback? onPressed;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: SizedBox(
        height: 56,
        child: Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Black "selected" tariff card — used in scooter selection / QR scan sheets.
/// Two states:
///   - `selected = true`  : black bg, white text (Поминутный selected)
///   - `selected = false` : light gray bg, gray text (На 1 час unselected)
class TariffCard extends StatelessWidget {
  const TariffCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: selected ? null : Border.all(color: AppColors.bgAlt),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.gray500,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.gray500,
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

// ---- Battery indicator ---------------------------------------------------

/// Battery indicator with traffic-light color logic, styled like the
/// reference (18×12 px battery body with colored fill).
class BatteryBadge extends StatelessWidget {
  const BatteryBadge({
    super.key,
    required this.percent,
    this.showText = true,
    this.compact = false,
  });

  final int percent;
  final bool showText;
  final bool compact;

  Color get _color {
    if (percent < 20) return AppColors.batteryLow;
    if (percent < 30) return AppColors.batteryMid;
    return AppColors.batteryHigh;
  }

  @override
  Widget build(BuildContext context) {
    final bodyWidth = compact ? 14.0 : 18.0;
    final bodyHeight = compact ? 9.0 : 12.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: bodyWidth,
          height: bodyHeight,
          decoration: BoxDecoration(
            border: Border.all(color: _color, width: 1),
            borderRadius: BorderRadius.circular(3),
          ),
          padding: const EdgeInsets.all(1),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (percent / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 6),
          Text(
            '$percent%',
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ],
    );
  }
}

// ---- Map controls --------------------------------------------------------

/// Map control button — 48×48 white rounded square with soft shadow.
/// Used for menu (grid icon), zoom +/−, list toggle, etc.
class MapControlButton extends StatelessWidget {
  const MapControlButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 48,
    this.radius = 16,
    this.iconColor,
    this.backgroundColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double radius;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.bgAlt),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: Icon(
            icon,
            color: iconColor ?? AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Dark location FAB — 48×48 black rounded square with Target icon.
/// Used on the map screen to recenter on user location.
class MapLocationButton extends StatelessWidget {
  const MapLocationButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: const Icon(
            LucideIcons.locate_fixed,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Legacy alias — circular white FAB for QR scanner trigger.
/// Back-compat with screens still using `MapFab`.
class MapFab extends StatelessWidget {
  const MapFab({
    super.key,
    this.icon,
    this.onPressed,
    this.size = 60,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData? icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(
            icon ?? LucideIcons.qr_code,
            color: iconColor ?? AppColors.textPrimary,
            size: 28,
          ),
        ),
      ),
    );
  }
}

// ---- Search bar ----------------------------------------------------------

/// Pill search bar — "Куда едем?" with search icon on the left.
class PillSearchBar extends StatelessWidget {
  const PillSearchBar({
    super.key,
    this.hint = 'Куда едем?',
    this.onTap,
    this.value,
  });

  final String hint;
  final VoidCallback? onTap;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppStyles.searchBarDecoration,
        child: Row(
          children: [
            Icon(LucideIcons.search, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- List rows -----------------------------------------------------------

/// Profile menu row — 40×40 gray icon tile + label + chevron-right.
/// Lives inside a 24-px-radius bordered card.
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconBackgroundColor,
    this.iconColor,
    this.showDivider = true,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final bool showDivider;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: isFirst ? const Radius.circular(24) : Radius.zero,
      topRight: isFirst ? const Radius.circular(24) : Radius.zero,
      bottomLeft: isLast ? const Radius.circular(24) : Radius.zero,
      bottomRight: isLast ? const Radius.circular(24) : Radius.zero,
    );
    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBackgroundColor ??
                          const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor ?? AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.chevron_left,
                    color: AppColors.textMuted,
                    size: 20,
                    // Rotated 180° to point right
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            if (showDivider && !isLast)
              Padding(
                padding: const EdgeInsets.only(left: 72, right: 16),
                child: Container(height: 1, color: AppColors.border),
              ),
          ],
        ),
      ),
    );
  }
}

/// Legacy alias for back-compat with screens still using [ListRow].
class ListRow extends MenuRow {
  const ListRow({
    super.key,
    required super.icon,
    required super.label,
    super.onTap,
    super.iconColor,
    super.showDivider = true,
  });
}

// ---- Stat column ---------------------------------------------------------

/// Stat card — label on top (gray, 12 px bold), value below (black, 17 px bold).
/// Used in the 3-column stat row on the active ride screen.
class StatColumn extends StatelessWidget {
  const StatColumn({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Back button ---------------------------------------------------------

/// Standard back button — 40×40 gray-100 circle with chevron-left icon.
/// Used in AppBar.leading on every secondary screen.
class BackButtonCircle extends StatelessWidget {
  const BackButtonCircle({super.key, this.onPressed, this.icon});

  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon ?? LucideIcons.chevron_left,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

// ---- App bar -------------------------------------------------------------

/// Standard Swift app bar — white bg, no elevation, back button circle
/// on the left, centered bold 18 px title, optional right action.
class SwiftAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SwiftAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.backgroundColor,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.white,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12),
      child: Row(
        children: [
          BackButtonCircle(onPressed: onBack),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          if (actions != null) ...actions! else const SizedBox(width: 40),
        ],
      ),
    );
  }
}
