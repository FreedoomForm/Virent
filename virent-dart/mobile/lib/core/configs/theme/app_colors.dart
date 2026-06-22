import 'package:flutter/material.dart';

/// Virent (Swift) color palette — based on the Swift Scooter reference
/// mockup design.
///
/// Key colors:
///   - `primary`        — bright lime `#D2F56A` (Swift brand green) for CTAs
///   - `primaryActive`  — slightly darker lime `#BDE555` for pressed state
///   - `secondary`      — near-black `#1C1C1E` for selected tariff, send btn
///   - `bg.*`           — `#F4F4F6` app/map background, `#FFFFFF` cards
///   - `text.*`         — `#000000` primary, `#999999` secondary, `#BDBDBD` muted
///   - `battery.*`      — `#22A349` high, `#FFC107` mid, `#FF5252` low
class AppColors {
  AppColors._();

  // ---- Brand accents ------------------------------------------------------
  /// Swift brand lime green — primary CTA color ("Поехали", "Получить код",
  /// "Забронировать самокат", "Сделать фото", "Оформить подписку").
  static const primary = Color(0xFFD2F56A);

  /// Slightly darker lime — pressed/active state of primary CTA.
  static const primaryActive = Color(0xFFBDE555);

  /// Lime with 20% opacity — used as soft accent background.
  static const primarySoft = Color(0xFFEFFBB3);

  /// Border color for the "selected OTP cell" — `#BEF264` (tailwind lime-300).
  static const primaryBorder = Color(0xFFBEF264);

  /// Near-black `#1C1C1E` — used as secondary accent (selected tariff card
  /// background, send button, location button, scooter pin).
  static const secondary = Color(0xFF1C1C1E);

  /// Pure black `#000000`.
  static const black = Color(0xFF000000);

  /// White.
  static const white = Color(0xFFFFFFFF);

  // ---- Legacy aliases (kept for back-compat with old screens) ------------
  static const primaryCta = primary;
  static const primaryCtaStrong = primary;
  static const primaryDark = secondary;
  static const primaryLight = primarySoft;
  static const primaryLighter = primarySoft;
  static const primaryHover = primaryActive;
  static const ink = secondary;

  // ---- Backgrounds --------------------------------------------------------
  /// App background (most screens) — Swift uses `#F4F4F6`.
  static const background = Color(0xFFF4F4F6);

  /// Map background — `#E5E5EA` (slightly darker than app bg, light map).
  static const bgMap = Color(0xFFE5E5EA);

  /// Card background (most cards are pure white).
  static const bgCard = Color(0xFFFFFFFF);

  /// App-bar background (white).
  static const bgAppBar = Color(0xFFFFFFFF);

  /// Bottom-sheet / modal background (white).
  static const bgModal = Color(0xFFFFFFFF);

  /// Keypad background — `#D1D5DB` (gray-300, like iOS keypad).
  static const bgKeypad = Color(0xFFD1D5DB);

  /// Keypad key background — white.
  static const bgKeypadKey = Color(0xFFFFFFFF);

  /// Backspace key — `#ABB0B8` (gray-400 ish).
  static const bgKeypadBackspace = Color(0xFFABB0B8);

  /// Dark mode background (for Swift Pass subscription screen).
  static const darkBackground = Color(0xFF1C1C1E);

  /// Dark mode surface (10% white overlay).
  static const darkSurface = Color(0xFF2A2A2D);

  /// Surface (cards, sheets).
  static const surface = Color(0xFFFFFFFF);

  /// Alt surface (slightly off-white for grouping, `#F9F9F9`).
  static const surfaceAlt = Color(0xFFF9F9F9);

  /// App-level alt background.
  static const bgAlt = Color(0xFFF4F4F6);

  /// Subscriptions screen chat gray text.
  static const gray400 = Color(0xFFBDBDBD);
  static const gray500 = Color(0xFF9CA3AF);
  static const gray600 = Color(0xFF6B7280);

  // ---- Text ---------------------------------------------------------------
  /// Headlines, primary values.
  static const textPrimary = Color(0xFF000000);

  /// Subtitles, captions — `#999999` per Swift design.
  static const textSecondary = Color(0xFF999999);

  /// Hints, footer microcopy, placeholder text.
  static const textMuted = Color(0xFFBDBDBD);

  /// Inverse text (on dark backgrounds).
  static const textOnDark = Color(0xFFFFFFFF);

  // ---- Borders / dividers -------------------------------------------------
  /// Hairline divider between list rows.
  static const border = Color(0xFFF3F4F6);

  /// Slightly stronger border — `#E5E7EB`.
  static const borderStrong = Color(0xFFE5E7EB);

  /// Gray-200 for input borders.
  static const inputBorder = Color(0xFFE5E7EB);

  // ---- Semantic colors ----------------------------------------------------
  /// Battery high / success — `#22A349` per Swift design.
  static const success = Color(0xFF22A349);

  /// Success background tint.
  static const successBg = Color(0xFFE8F5E9);

  /// Battery medium / warning.
  static const warning = Color(0xFFFFC107);

  /// Warning background tint.
  static const warningBg = Color(0xFFFFF8E1);

  /// Battery low / error / destructive — `#FF5252`.
  static const danger = Color(0xFFFF5252);

  /// Danger background tint.
  static const dangerBg = Color(0xFFFFEBEE);

  /// Information / iOS blue — `#007AFF`.
  static const info = Color(0xFF007AFF);

  /// Info background tint.
  static const infoBg = Color(0xFFE3F2FD);

  // ---- Map markers --------------------------------------------------------
  /// Scooter marker — black bg with lime icon.
  static const scooterMarker = Color(0xFF1C1C1E);

  /// Scooter marker glow — lime.
  static const scooterMarkerGlow = Color(0xFFD2F56A);

  /// Parking "P" marker — soft blue `#A2CDEB`.
  static const parkingMarker = Color(0xFFA2CDEB);

  /// User location dot — black.
  static const userMarker = Color(0xFF000000);

  /// Destination marker — orange.
  static const destinationMarker = Color(0xFFFF5722);

  /// Map street color (light gray).
  static const mapStreet = Color(0xFFFFFFFF);

  /// Map building color.
  static const mapBuilding = Color(0xFFFFFFFF);

  // ---- Battery traffic light ----------------------------------------------
  /// Battery > 30% — Swift green `#22A349`.
  static const batteryHigh = Color(0xFF22A349);

  /// Battery 20–30%.
  static const batteryMid = Color(0xFFFFC107);

  /// Battery < 20% — red.
  static const batteryLow = Color(0xFFFF5252);

  // ---- Brand payment logos ------------------------------------------------
  /// T-Pay / T-Bank yellow accent — `#FFDD00`.
  static const brandYellow = Color(0xFFFFDD00);

  /// Sber-Pay green — `#21A038`.
  static const brandSber = Color(0xFF21A038);

  /// СБП blue — `#007AFF`.
  static const brandSbp = Color(0xFF007AFF);

  /// Orange accent (used in profile avatar background).
  static const brandOrange = Color(0xFFEAB308);

  // ---- Russian flag colors (phone-input prefix) ---------------------------
  static const flagWhite = Color(0xFFFFFFFF);
  static const flagBlue = Color(0xFF0039A6);
  static const flagRed = Color(0xFFD52B1E);
}
