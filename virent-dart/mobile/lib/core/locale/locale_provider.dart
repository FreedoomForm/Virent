// locale_provider.dart — Riverpod state for the active locale.
//
// Ported from BarqScoot's `core/locale/providers/provider/locale_provider.dart`
// and adapted to Virent's three-language setup. The notifier persists the
// user's choice in [StorageService] so the same language is restored on the
// next app launch, and the value is exposed as a [Locale] that the root
// `MaterialApp.router` reads via `ref.watch(localeProvider)` to drive
// `MaterialApp.locale` and the `LocalizationsDelegate` resolution.
//
// Usage:
//   ```dart
//   final locale = ref.watch(localeProvider);
//   MaterialApp.router(
//     locale: locale,
//     supportedLocales: LocaleData.locales,
//     localizationsDelegates: [
//       AppLocalizations.delegate,
//       GlobalMaterialLocalizations.delegate,
//       GlobalWidgetsLocalizations.delegate,
//     ],
//   );
//   ```
//
// To change the language from any widget:
//   ```dart
//   ref.read(localeProvider.notifier).setLocale('ru');
//   ```

import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../configs/services/storage_service.dart';
import 'locale_data.dart';

/// Riverpod provider for the active [Locale].
///
/// Returns the user's previously persisted choice (or [LocaleData.defaultLocale]
/// on first launch). Components that need to react to language changes simply
/// `ref.watch(localeProvider)` — the value is immutable so a change triggers
/// a rebuild of the entire subtree that depends on it.
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LocaleNotifier(storage);
});

/// Owning notifier for [localeProvider].
///
/// On construction the notifier kicks off an async restore from
/// [StorageService]. Until the restore resolves, [state] is the default
/// locale so the very first frame always has something to render.
class LocaleNotifier extends StateNotifier<Locale> {
  /// Creates a [LocaleNotifier] wired to [storage].
  LocaleNotifier(this._storage)
      : super(LocaleData.defaultLocale) {
    _restore();
  }

  final StorageService _storage;

  /// Restores the previously persisted locale from disk, if any.
  ///
  /// Failures are swallowed — a missing or corrupt value simply keeps the
  /// default locale.
  Future<void> _restore() async {
    try {
      final saved = await _storage.getString(StorageKeys.language);
      if (saved != null && LocaleData.isSupported(saved)) {
        state = Locale(saved);
      }
    } catch (_) {
      // Best-effort restore; ignore.
    }
  }

  /// Switches the active language to [languageCode] (e.g. `'en'`, `'ru'`,
  /// `'uz'`) and persists the choice.
  ///
  /// Unknown codes are ignored — the catalogue is the single source of
  /// truth for what is supported.
  Future<void> setLocale(String languageCode) async {
    if (!LocaleData.isSupported(languageCode)) return;
    if (state.languageCode == languageCode) return;
    state = Locale(languageCode);
    try {
      await _storage.setString(StorageKeys.language, languageCode);
    } catch (_) {
      // Persistence failure should not roll back the in-memory state —
      // the user's choice still takes effect for the current session.
    }
  }

  /// Resets the locale back to the application default and clears the
  /// persisted value.
  Future<void> reset() async {
    state = LocaleData.defaultLocale;
    try {
      await _storage.remove(StorageKeys.language);
    } catch (_) {
      // Best-effort.
    }
  }
}

/// Tiny provider that exposes the shared [StorageService] so [LocaleNotifier]
/// can be constructed via Riverpod's auto-wire. Defined here (rather than in
/// `storage_service.dart`) to keep the storage module framework-free.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
