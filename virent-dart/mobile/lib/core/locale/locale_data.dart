// locale_data.dart — Supported locales for the Virent app.
//
// Ported from BarqScoot's `core/locale/providers/data/locale_data.dart`
// (which only supported `en` + `ar`) and adapted for Virent's three target
// markets: English (default), Russian (CIS-wide lingua franca) and Uzbek
// (the domestic market).
//
// Keeping the catalogue in a single file makes it trivial to add a new
// language: append an entry to [LocaleData.supportedLocales] and ship the
// corresponding translation map in `lib/l10n/app_localizations.dart`.

import 'package:flutter/material.dart' show Locale;

/// A single supported language descriptor.
class LocaleOption {
  /// Creates a [LocaleOption].
  const LocaleOption({
    required this.code,
    required this.displayName,
    required this.nativeName,
    required this.flagCode,
  });

  /// ISO 639-1 language code (e.g. `en`, `ru`, `uz`).
  final String code;

  /// Language name in English (used by the language picker when the
  /// currently active locale would render the name in its own script and
  /// the user needs a recognisable anchor).
  final String displayName;

  /// Language name in its own script (e.g. `O‘zbekcha`, `Русский`).
  final String nativeName;

  /// Two-letter ISO 3166-1 alpha-2 country code used to render a flag
  /// emoji / icon. Kept as a string (not an Icon) so this file stays
  /// UI-framework free.
  final String flagCode;

  /// A [Locale] constructed from [code].
  Locale get locale => Locale(code);
}

/// Read-only catalogue of every language Virent ships with.
///
/// The order matters: the first entry ([LocaleData.english]) is the
/// application's default and is always returned from [LocaleData.defaultOption].
class LocaleData {
  LocaleData._();

  /// English — default / fallback.
  static const LocaleOption english = LocaleOption(
    code: 'en',
    displayName: 'English',
    nativeName: 'English',
    flagCode: 'GB',
  );

  /// Russian — CIS-wide second language.
  static const LocaleOption russian = LocaleOption(
    code: 'ru',
    displayName: 'Russian',
    nativeName: 'Русский',
    flagCode: 'RU',
  );

  /// Uzbek — domestic market language.
  static const LocaleOption uzbek = LocaleOption(
    code: 'uz',
    displayName: 'Uzbek',
    nativeName: 'O‘zbekcha',
    flagCode: 'UZ',
  );

  /// All supported locales, in the order they should appear in the
  /// language picker.
  static const List<LocaleOption> supportedLocales = <LocaleOption>[
    english,
    russian,
    uzbek,
  ];

  /// The application's default locale (used before the user has picked one
  /// and as a fallback for missing translations).
  static const LocaleOption defaultOption = english;

  /// The default [Locale].
  static Locale get defaultLocale => defaultOption.locale;

  /// Convenience: list of [Locale]s ready to pass to `MaterialApp.locales`.
  static List<Locale> get locales =>
      supportedLocales.map((o) => o.locale).toList(growable: false);

  /// Looks up a [LocaleOption] by its ISO 639-1 [code].
  ///
  /// Returns [defaultOption] when [code] is unknown so the caller never
  /// has to handle a `null` return.
  static LocaleOption optionFor(String code) {
    for (final option in supportedLocales) {
      if (option.code == code) return option;
    }
    return defaultOption;
  }

  /// Returns `true` when [code] corresponds to a supported language.
  static bool isSupported(String code) {
    return supportedLocales.any((o) => o.code == code);
  }
}
