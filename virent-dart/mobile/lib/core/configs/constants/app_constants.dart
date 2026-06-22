/// Application-wide constants for the Virent mobile app.
///
/// Centralises version metadata, networking defaults and feature flags so
/// they can be tuned from a single place. Ported from BarqScoot's
/// `core/configs/constants/app_constants.dart` and extended with Virent
/// specifics (embedded server URL, OTP tuning, etc.).
class AppConstants {
  AppConstants._();

  // ---- App metadata -------------------------------------------------------
  /// User-visible application name.
  static const String appName = 'Virent';

  /// Internal package identifier (used for analytics / crash reporting).
  static const String packageName = 'app.virent.mobile';

  /// Semantic version string, mirrored from pubspec.yaml.
  static const String appVersion = '1.0.0';

  /// Build number suffix appended to [appVersion] where relevant.
  static const int buildNumber = 1;

  /// Tag used by the dev logger.
  static const String debugTag = 'VIRENT';

  // ---- Backend / networking ----------------------------------------------
  /// Default port of the embedded shelf server.
  static const int embeddedServerPort = 8443;

  /// Base URL used by the desktop build (embedded server in-process).
  static const String desktopBaseUrl = 'http://localhost:8443';

  /// Base URL used by the Android emulator (maps to host loopback).
  static const String emulatorBaseUrl = 'http://10.0.2.2:8443';

  /// Default connection timeout for HTTP requests.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Default receive timeout for HTTP requests.
  static const Duration receiveTimeout = Duration(seconds: 20);

  // ---- Auth / OTP ---------------------------------------------------------
  /// Length of the one-time passwords sent by the backend.
  static const int otpLength = 6;

  /// How long an OTP remains valid (must match the backend).
  static const Duration otpValidity = Duration(minutes: 5);

  /// Cooldown before the user can request a new OTP.
  static const Duration otpResendCooldown = Duration(seconds: 60);

  /// Default number of digits expected for a local phone number.
  static const int localPhoneLength = 9;

  // ---- Onboarding ---------------------------------------------------------
  /// SharedPreferences key — set to `false` after the first welcome screen.
  static const String firstRunKey = 'first_run';

  /// Current Terms & Conditions version the user must accept.
  static const String termsVersion = '1.0.0';
}

/// Default country calling codes offered by the phone input.
///
/// Virent launches in Uzbekistan so [+998] is the default; the remaining
/// entries cover neighbouring Central-Asian markets for forward compatibility.
/// Icons are rendered with Material Icons only — no emoji — per the Virent
/// design system.
class CountryDialCode {
  const CountryDialCode({
    required this.code,
    required this.dial,
    required this.iso,
  });

  /// Human readable country name.
  final String code;

  /// E.164 dial code, including the leading `+`.
  final String dial;

  /// Two-letter ISO 3166-1 alpha-2 code.
  final String iso;

  /// Convenience list of supported dial codes.
  static const List<CountryDialCode> defaults = [
    CountryDialCode(code: 'Uzbekistan', dial: '+998', iso: 'UZ'),
    CountryDialCode(code: 'Kazakhstan', dial: '+7', iso: 'KZ'),
    CountryDialCode(code: 'Kyrgyzstan', dial: '+996', iso: 'KG'),
    CountryDialCode(code: 'Tajikistan', dial: '+992', iso: 'TJ'),
    CountryDialCode(code: 'Turkmenistan', dial: '+993', iso: 'TM'),
    CountryDialCode(code: 'Russia', dial: '+7', iso: 'RU'),
  ];
}
