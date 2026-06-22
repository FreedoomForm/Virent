import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/configs/services/storage_service.dart';
import '../data/theme_state.dart';

/// Riverpod provider exposing the current [ThemeState] and the notifier
/// responsible for toggling / persisting it.
///
/// Ported from BarqScoot's `ThemeNotifier`. The selected mode is hydrated
/// from [StorageKeys.themeMode] on construction and written back on every
/// change so the user's preference survives app restarts.
final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Manages the active [ThemeState] and persists it to SharedPreferences.
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState.light) {
    _hydrate();
  }

  /// Reads the persisted preference and updates the state on first load.
  Future<void> _hydrate() async {
    final storage = StorageService();
    final isDark = await storage.getBool(StorageKeys.themeMode);
    if (mounted) state = isDark ? ThemeState.dark : ThemeState.light;
  }

  /// Flips between light and dark themes and persists the new value.
  Future<void> toggleTheme() async {
    final next = state.isDark ? ThemeState.light : ThemeState.dark;
    state = next;
    await StorageService().setBool(StorageKeys.themeMode, next.isDark);
  }

  /// Explicitly sets the theme to [isDark] and persists it.
  Future<void> setTheme({required bool isDark}) async {
    state = isDark ? ThemeState.dark : ThemeState.light;
    await StorageService().setBool(StorageKeys.themeMode, isDark);
  }
}
