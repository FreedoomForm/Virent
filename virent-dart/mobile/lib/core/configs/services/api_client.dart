import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../error/api_exceptions.dart';
import '../services/storage_service.dart';

/// API client for the Virent backend.
///
/// On desktop (Windows/macOS/Linux): connects to localhost:8443
///   — the embedded shelf server runs inside the same app process.
///
/// On mobile (iOS/Android): connects to the desktop PC's IP address.
///   The user enters this in Settings (default: 10.0.2.2 for Android emulator).
///
/// On web: connects to localhost:8443 (same-origin, since the Flutter web
///   build is served from the same host as the embedded server in dev).
///
/// All non-2xx responses are converted into an [ApiException] (or one of its
/// subtypes) so callers can `try / catch` a single error hierarchy.
class ApiClient {
  String baseUrl;
  String? _token;

  ApiClient()
      : baseUrl = _defaultBaseUrl;

  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8443';
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'http://localhost:8443'; // desktop: embedded server
    }
    return 'https://caliber-lividly-coastline.ngrok-free.dev'; // mobile: ngrok tunnel
  }

  /// Update the base URL (used by mobile to connect to a specific PC).
  ///
  /// **Admin-only.** Throws [UnauthorizedException] when the current
  /// SharedPreferences session is not an admin / super_admin. The check
  /// is performed against the `admin_token` key OR a `user_json` whose
  /// `role` is `admin` / `super_admin`.
  ///
  /// This is the single source of truth — even if a malicious rider
  /// somehow reaches the call site (e.g. by hooking a debug button),
  /// the URL mutation is rejected before it can take effect.
  Future<void> setBaseUrl(String url) async {
    if (!await _isAdminSession()) {
      throw UnauthorizedException(
        'Только администратор может изменить адрес сервера',
      );
    }
    baseUrl = url;
  }

  /// Returns `true` when the active session belongs to an admin.
  /// Mirrors the same check performed by `app_router.dart`.
  Future<bool> _isAdminSession() async {
    final storage = StorageService();
    await storage.init();
    final adminToken = await storage.getString('admin_token');
    if (adminToken != null && adminToken.isNotEmpty) return true;
    final userJson = await storage.getJson(StorageKeys.userJson);
    if (userJson == null) return false;
    final role = (userJson['role'] ?? '').toString().toLowerCase();
    return role == 'admin' || role == 'super_admin';
  }

  /// Attach the bearer token used for authenticated requests.
  void setToken(String? token) => _token = token;

  /// The currently configured bearer token, if any.
  String? get token => _token;

  Map<String, String> get _headers => {
        'ngrok-skip-browser-warning': 'true',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Performs a GET request and returns the decoded JSON body.
  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  /// Performs a POST request with a JSON [body].
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl$path'),
        headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  /// Performs a PUT request with a JSON [body].
  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    final res = await http.put(Uri.parse('$baseUrl$path'),
        headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  /// Performs a DELETE request.
  Future<Map<String, dynamic>> delete(String path) async {
    final res =
        await http.delete(Uri.parse('$baseUrl$path'), headers: _headers)
            .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    // Empty body (e.g. 204 No Content) → return an empty map on success.
    if (res.body.isEmpty) {
      if (res.statusCode >= 200 && res.statusCode < 300) return {};
      throw _mapStatus(res.statusCode, 'Request failed');
    }

    // Try to decode the body as a JSON object.
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {
      // Body was not JSON — fall through to raw handling below.
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data ?? <String, dynamic>{'body': res.body};
    }

    final message = data != null
        ? (data['error'] ??
                data['detail'] ??
                data['message'] ??
                'Request failed (${res.statusCode})')
            .toString()
        : (res.body.isEmpty
            ? 'Request failed (${res.statusCode})'
            : res.body);
    throw _mapStatus(res.statusCode, message);
  }

  /// Maps a status code to the most specific [ApiException] subtype.
  AppException _mapStatus(int statusCode, String message) {
    if (statusCode == 401 || statusCode == 403) {
      return UnauthorizedException(message);
    }
    if (statusCode == 404) {
      return NotFoundException(message);
    }
    if (statusCode == 422 || statusCode == 400) {
      return ValidationException(message);
    }
    if (statusCode >= 500) {
      return ServerException(message);
    }
    return ApiException(message, statusCode: statusCode);
  }
}
