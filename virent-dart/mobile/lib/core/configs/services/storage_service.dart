import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence facade built on top of [SharedPreferences].
///
/// Ported from BarqScoot's `StorageService`. Provides typed accessors for
/// primitive values plus convenience helpers to persist / restore the
/// authenticated user as a JSON document. The underlying
/// [SharedPreferences] instance is loaded lazily and cached so callers can
/// use [StorageService] without an explicit `init()` call.
///
/// All keys live in [StorageKeys] to avoid stringly-typed typos.
class StorageService {
  SharedPreferences? _prefs;

  /// Lazily loads (and caches) the [SharedPreferences] instance.
  Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Forces initialisation of the underlying store. Safe to call multiple
  /// times. Useful at app start to warm the cache.
  Future<void> init() async {
    await _instance();
  }

  // ---- Bool ---------------------------------------------------------------
  /// Returns the bool stored at [key], or [defaultValue] when unset.
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await _instance();
    return prefs.getBool(key) ?? defaultValue;
  }

  /// Persists [value] at [key].
  Future<void> setBool(String key, bool value) async {
    final prefs = await _instance();
    await prefs.setBool(key, value);
  }

  // ---- String -------------------------------------------------------------
  /// Returns the string stored at [key], or `null` when unset.
  Future<String?> getString(String key) async {
    final prefs = await _instance();
    return prefs.getString(key);
  }

  /// Persists [value] at [key].
  Future<void> setString(String key, String value) async {
    final prefs = await _instance();
    await prefs.setString(key, value);
  }

  // ---- Int ----------------------------------------------------------------
  /// Returns the int stored at [key], or [defaultValue] when unset.
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final prefs = await _instance();
    return prefs.getInt(key) ?? defaultValue;
  }

  /// Persists [value] at [key].
  Future<void> setInt(String key, int value) async {
    final prefs = await _instance();
    await prefs.setInt(key, value);
  }

  // ---- JSON object --------------------------------------------------------
  /// Reads a JSON object stored at [key], or `null` when unset / invalid.
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Serialises [value] to JSON and stores it at [key].
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, jsonEncode(value));
  }

  // ---- Misc ----------------------------------------------------------------
  /// Removes the value stored at [key] (no-op when unset).
  Future<void> remove(String key) async {
    final prefs = await _instance();
    await prefs.remove(key);
  }

  /// Returns `true` when [key] has been set.
  Future<bool> containsKey(String key) async {
    final prefs = await _instance();
    return prefs.containsKey(key);
  }

  /// Wipes every Virent-owned key. Used during logout.
  Future<void> clearAuth() async {
    await remove(StorageKeys.authToken);
    await remove(StorageKeys.refreshToken);
    await remove(StorageKeys.userId);
    await remove(StorageKeys.userPhone);
    await remove(StorageKeys.userEmail);
    await remove(StorageKeys.userFirstName);
    await remove(StorageKeys.userLastName);
    await remove(StorageKeys.userJson);
    await remove(StorageKeys.isLoggedIn);
  }
}

/// Central registry of every SharedPreferences key used by Virent.
///
/// Keeping them here prevents drift between writers and readers and makes
/// auditing the on-device footprint trivial.
class StorageKeys {
  StorageKeys._();

  // ---- Theme / locale -----------------------------------------------------
  /// `bool` — `true` when dark theme is selected.
  static const themeMode = 'theme_mode';

  /// `String` — ISO 639-1 language code.
  static const language = 'language_code';

  // ---- Auth ---------------------------------------------------------------
  /// `String` — JWT access token.
  static const authToken = 'auth_token';

  /// `String` — JWT refresh token.
  static const refreshToken = 'refresh_token';

  /// `bool` — whether the user is currently logged in.
  static const isLoggedIn = 'is_logged_in';

  /// `String` — authenticated user id.
  static const userId = 'user_id';

  /// `String` — authenticated user phone (E.164).
  static const userPhone = 'user_phone';

  /// `String` — authenticated user email.
  static const userEmail = 'user_email';

  /// `String` — authenticated user first name.
  static const userFirstName = 'user_first_name';

  /// `String` — authenticated user last name.
  static const userLastName = 'user_last_name';

  /// `String` — JSON blob of the full user profile.
  static const userJson = 'user_json';

  /// `bool` — whether the user accepted the current T&C version.
  static const termsAccepted = 'terms_accepted';

  // ---- Onboarding ---------------------------------------------------------
  /// `bool` — `true` until the welcome screen has been shown once.
  static const isFirstRun = 'first_run';

  /// `bool` — `true` once onboarding has been completed.
  static const onboardingComplete = 'onboarding_complete';

  // ---- App settings -------------------------------------------------------
  /// `String` — base URL the mobile app should talk to.
  static const serverUrl = 'server_url';

  /// `bool` — whether the desktop UI is running in admin mode.
  static const adminMode = 'admin_mode';

  /// `int` — selected SIM slot for the SMS-gateway fallback.
  static const selectedSimSlot = 'sim_slot';
}
