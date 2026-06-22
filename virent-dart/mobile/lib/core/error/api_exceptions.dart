import 'package:http/http.dart' as http;

/// Base type for every exception thrown by the Virent data layer.
///
/// All Virent exceptions implement [Exception] and expose a human readable
/// [message] plus an optional HTTP [statusCode]. Presentation code can catch
/// [AppException] to handle every flavour of failure in a single clause, or
/// catch a specific subtype to tailor the UX (e.g. [UnauthorizedException]
/// → force logout).
sealed class AppException implements Exception {
  /// Human readable description of what went wrong.
  final String message;

  /// HTTP status code associated with the failure, when applicable.
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// Generic API failure — the catch-all for non 2xx responses that do not map
/// to a more specific exception below.
class ApiException extends AppException {
  const ApiException(super.message, {super.statusCode});

  /// Builds an [ApiException] from a raw [http.Response].
  ///
  /// Tries to extract a server-provided message from the JSON `error` /
  /// `detail` / `message` fields before falling back to the raw body.
  factory ApiException.fromResponse(http.Response response) {
    String detail = response.body;
    try {
      // Best-effort JSON message extraction; mirrors the conventions used by
      // the Virent embedded server and the legacy Node backend.
      // ignore: avoid_dynamic_calls
      final decoded = response.body.isEmpty
          ? null
          : Uri.splitQueryString(response.body);
      if (decoded != null && decoded.containsKey('error')) {
        detail = decoded['error']!;
      }
    } catch (_) {
      // Body was not query-encoded; keep the raw body.
    }
    return ApiException(
      detail.isEmpty ? 'Request failed (${response.statusCode})' : detail,
      statusCode: response.statusCode,
    );
  }

  /// Builds an [ApiException] from an arbitrary error (network, parsing, …).
  factory ApiException.fromError(dynamic error) {
    if (error is AppException) {
      return ApiException(error.message, statusCode: error.statusCode);
    }
    return ApiException('Network error: $error');
  }
}

/// Raised when authentication credentials are missing, invalid or expired.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Unauthorized'])
      : super(message, statusCode: 401);
}

/// Raised when a requested resource cannot be found.
class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Not found'])
      : super(message, statusCode: 404);
}

/// Raised when the server rejects the request due to validation errors.
class ValidationException extends ApiException {
  const ValidationException([String message = 'Validation failed'])
      : super(message, statusCode: 422);
}

/// Raised when the server returns 5xx or otherwise signals a server fault.
class ServerException extends ApiException {
  const ServerException([String message = 'Server error'])
      : super(message, statusCode: 500);
}

/// Raised when the device cannot reach the server (timeout, DNS, offline).
class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection'])
      : super(message);
}

/// Raised when a request takes longer than the configured timeout.
class TimeoutException extends AppException {
  const TimeoutException([String message = 'Request timed out']) : super(message);
}

/// Raised by the auth feature for anything auth-specific that is not a raw
/// API failure — e.g. "no refresh token stored", "session expired", etc.
class AuthException extends AppException {
  const AuthException(super.message);
}
