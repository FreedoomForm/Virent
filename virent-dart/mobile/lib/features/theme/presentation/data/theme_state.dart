/// Immutable representation of the active visual theme.
///
/// Ported from BarqScoot's `features/theme/presentation/data/theme_state.dart`.
/// Kept deliberately small (a single [isDark] boolean) so it can be trivially
/// serialised to SharedPreferences and consumed by `MaterialApp.themeMode`.
class ThemeState {
  /// `true` when the dark theme should be active.
  final bool isDark;

  /// Creates a theme state.
  const ThemeState(this.isDark);

  /// Pre-built light theme state.
  static const ThemeState light = ThemeState(false);

  /// Pre-built dark theme state.
  static const ThemeState dark = ThemeState(true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ThemeState && other.isDark == isDark);

  @override
  int get hashCode => isDark.hashCode;

  @override
  String toString() => 'ThemeState(isDark: $isDark)';
}
