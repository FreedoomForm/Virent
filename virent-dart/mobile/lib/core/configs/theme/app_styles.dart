import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared style constants — Swift Scooter design system.
///
/// Design tokens (extracted from reference mockup):
///   - **Spacing scale**: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 48 px
///   - **Radius scale**:
///       * 12 px — small icon chips, payment brand chips
///       * 14 px — medium buttons (Готово, Очистить)
///       * 16 px — primary CTA (Поехали, Получить код), inputs
///       * 20 px — primary buttons on auth/ride screens, search bar
///       * 24 px — list cards, profile menu, stat cards, hero cards
///       * 32 px — bottom sheet top corners, full-screen modal top
///   - **Shadow scale**:
///       * Card    : `0 4px 16px rgba(0,0,0,0.06)`
///       * Floating: `0 -10px 40px rgba(0,0,0,0.10)` (bottom sheet)
///       * Pin     : `0 0 12px rgba(210,245,106,0.30)` (lime glow)
///   - **Button heights**:
///       * Primary CTA: 56 px (py-4 ≈ 14+14+text)
///       * Map control: 48 px (square)
///       * Keypad key: 46 px
///       * Bottom nav: 64 px
class AppStyles {
  AppStyles._();

  // ---- Spacing scale ------------------------------------------------------
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 20.0;
  static const double space2xl = 24.0;
  static const double space3xl = 32.0;
  static const double space4xl = 48.0;

  /// Legacy alias.
  static const double spacing = spaceLg;

  // ---- Radius scale -------------------------------------------------------
  /// 12 px — small icon chips.
  static const double radiusXs = 12.0;

  /// 14 px — medium buttons.
  static const double radiusSm = 14.0;

  /// 16 px — primary CTA, inputs, keypad keys.
  static const double radiusMd = 16.0;

  /// 20 px — primary buttons on auth/ride screens, search bar, filter chips.
  static const double radiusLg = 20.0;

  /// 24 px — list cards, profile menu, stat cards, hero cards.
  static const double radiusXl = 24.0;

  /// 32 px — bottom sheet top corners, full-screen modal top.
  static const double radius2xl = 32.0;

  /// 40 px — mobile frame corners (welcome, scanner).
  static const double radius3xl = 40.0;

  /// Legacy aliases.
  static const double borderRadius = radiusXl;
  static const double borderRadiusSm = radiusSm;

  // ---- Icon sizes ---------------------------------------------------------
  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double iconSize = iconMd;

  // ---- Button heights -----------------------------------------------------
  static const double buttonHeightSm = 40.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;
  static const double buttonHeightXl = 64.0;

  // ---- Card / container decorations --------------------------------------
  /// Standard card — white bg, 24px radius, hairline border, soft shadow.
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusXl),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 1),
      ),
    ],
  );

  /// Compact card — 16 px radius (for scooter info rows, stat cards).
  static BoxDecoration cardDecorationCompact = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: AppColors.border),
  );

  /// Ride-history tile — 24 px radius with overflow hidden.
  static BoxDecoration rideHistoryTileDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusXl),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 6,
        offset: const Offset(0, 1),
      ),
    ],
  );

  /// Floating bottom sheet — 32 px top radius, big top shadow.
  static BoxDecoration bottomSheetDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(radius2xl)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.10),
        blurRadius: 40,
        offset: const Offset(0, -10),
      ),
    ],
  );

  /// Pill search bar — 20 px radius, white bg, soft shadow.
  static BoxDecoration searchBarDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusLg),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Map control button — 16 px radius square or 24 px circle.
  static BoxDecoration mapControlDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: AppColors.bgAlt),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 8,
        offset: const Offset(0, 1),
      ),
    ],
  );

  /// Map FAB / dark location button — black bg, 16 px radius.
  static BoxDecoration mapFabDecoration = BoxDecoration(
    color: AppColors.secondary,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: const Color(0xFF333333)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.30),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Primary CTA button — lime bg, 20 px radius (or 16 px on auth).
  static BoxDecoration primaryCtaDecoration = BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(radiusLg),
  );

  /// Pill CTA — same as primary but bigger radius.
  static BoxDecoration pillCtaDecoration = BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(radiusLg),
  );

  /// Black CTA — for selected tariff card, "Готово" button, send button.
  static BoxDecoration blackCtaDecoration = BoxDecoration(
    color: AppColors.secondary,
    borderRadius: BorderRadius.circular(radiusMd),
  );

  /// Disabled CTA — gray bg.
  static BoxDecoration disabledCtaDecoration = BoxDecoration(
    color: const Color(0xFFF3F4F6),
    borderRadius: BorderRadius.circular(radiusLg),
  );

  /// Hairline divider — between list rows.
  static Border dividerTop = Border(
    top: BorderSide(color: AppColors.border, width: 0.5),
  );

  static Border dividerBottom = Border(
    bottom: BorderSide(color: AppColors.border, width: 0.5),
  );

  // ---- Edge padding -------------------------------------------------------
  /// Standard horizontal edge padding for screens.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24);

  /// Standard padding for cards (24 px).
  static const EdgeInsets cardPadding = EdgeInsets.all(24);

  /// Bottom-anchored CTA padding (24 from edges, 32 from bottom safe area).
  static const EdgeInsets ctaPadding = EdgeInsets.fromLTRB(24, 16, 24, 32);

  /// Auth screen content padding.
  static const EdgeInsets authPadding = EdgeInsets.symmetric(horizontal: 24);
}
