// error_handler.dart — Centralized error system.
//
// Ported from backend/src/shared/errors.js. Every error carries:
//   - a stable machine code (UPPER_SNAKE_CASE)
//   - a human-readable message
//   - an HTTP status mapping
//   - optional safe details (no PII)
//
// Usage:
//   throw ValidationError(field: 'email', message: 'Invalid email format');
//   throw AuthError('TOKEN_EXPIRED', 'Token has expired');
//   final body = toErrorResponse(err, requestId: 'req_abc');
//
// Per constitution §8.3 + §16: stable error codes are part of the public
// API contract — never renumber or rename them.

/// Stable error code → HTTP status mapping.
///
/// Mirrors `ERROR_CODES` from errors.js. Adding a new code requires bumping
/// the API version and documenting the change in the public contract.
const Map<String, int> errorCodes = {
  // Validation
  'VALIDATION_FAILED': 400,
  'INVALID_INPUT': 400,
  'MISSING_FIELD': 400,

  // Auth
  'UNAUTHORIZED': 401,
  'TOKEN_EXPIRED': 401,
  'TOKEN_INVALID': 401,
  'INVALID_CREDENTIALS': 401,
  'OTP_INVALID': 401,
  'OTP_EXPIRED': 401,

  // Forbidden
  'PERMISSION_DENIED': 403,
  'NOT_ADMIN': 403,
  'NOT_OWNER': 403,
  'NOT_JUICER': 403,
  'NOT_MECHANIC': 403,

  // Not found
  'USER_NOT_FOUND': 404,
  'SCOOTER_NOT_FOUND': 404,
  'TRIP_NOT_FOUND': 404,
  'CITY_NOT_FOUND': 404,
  'TICKET_NOT_FOUND': 404,
  'TRANSACTION_NOT_FOUND': 404,

  // Conflict
  'SCOOTER_NOT_AVAILABLE': 409,
  'SCOOTER_ALREADY_RESERVED': 409,
  'USER_ALREADY_EXISTS': 409,
  'DUPLICATE_PROMO_CODE': 409,
  'ACTIVE_TRIP_EXISTS': 409,

  // Business rules
  'INSUFFICIENT_BALANCE': 422,
  'TRIP_NOT_ACTIVE': 422,
  'RESERVATION_EXPIRED': 410,
  'LOW_BATTERY': 422,

  // Rate limit
  'RATE_LIMIT_EXCEEDED': 429,
  'TOO_MANY_OTP_REQUESTS': 429,

  // Server
  'INTERNAL_ERROR': 500,
  'PROVIDER_NOT_CONFIGURED': 503,
};

/// Base class for all application errors.
///
/// Subclass this for new error categories — never throw a raw [Exception]
/// from a use case or route handler.
class AppError implements Exception {
  /// Stable UPPER_SNAKE_CASE code (must exist in [errorCodes]).
  final String code;

  /// Human-readable message — safe to show to the end user.
  final String message;

  /// HTTP status code derived from [code] via [errorCodes].
  final int statusCode;

  /// Optional safe details (no PII, no secrets).
  final Map<String, dynamic> details;

  /// True for expected / handled errors. False for unexpected crashes.
  final bool isOperational;

  /// Creates an [AppError].
  ///
  /// If [statusCode] is omitted it is looked up from [errorCodes] using
  /// [code]; if neither yields a value, 500 is used as a safe fallback.
  AppError(
    this.code,
    String? message, {
    int? statusCode,
    Map<String, dynamic>? details,
    bool isOperational = true,
  })  : message = message ?? code,
        statusCode = statusCode ?? errorCodes[code] ?? 500,
        details = details ?? const {},
        isOperational = isOperational;

  /// Serializes the error to the `{ error: { code, message, details } }`
  /// envelope. [requestId] is added by [toErrorResponse] at the boundary.
  Map<String, dynamic> toJson() => {
        'error': {
          'code': code,
          'message': message,
          'details': details,
        },
      };

  @override
  String toString() => 'AppError($code, $message)';
}

/// Validation failure for a specific input field.
class ValidationError extends AppError {
  /// Name of the rejected field.
  final String field;

  ValidationError({
    required this.field,
    required String message,
    Map<String, dynamic>? details,
  }) : super(
          'VALIDATION_FAILED',
          'Field "$field": $message',
          statusCode: 400,
          details: {'field': field, if (details != null) ...details},
        );
}

/// Authentication failure (401).
class AuthError extends AppError {
  AuthError(
    String code,
    String? message, {
    Map<String, dynamic>? details,
  }) : super(code, message, statusCode: 401, details: details);
}

/// Authorization failure (403).
class ForbiddenError extends AppError {
  ForbiddenError({
    String code = 'PERMISSION_DENIED',
    String message = 'Permission denied',
    Map<String, dynamic>? details,
  }) : super(code, message, statusCode: 403, details: details);
}

/// Resource not found (404). [resource] is converted to UPPER_SNAKE_CODE.
class NotFoundError extends AppError {
  NotFoundError(
    String resource, {
    String? id,
    Map<String, dynamic>? details,
  }) : super(
          '${resource.toUpperCase().replaceAll(' ', '_')}_NOT_FOUND',
          '$resource not found${id != null && id.isNotEmpty ? ': $id' : ''}',
          statusCode: 404,
          details: {
            'resource': resource,
            if (id != null) 'id': id,
            if (details != null) ...details,
          },
        );
}

/// Conflict with current resource state (409).
class ConflictError extends AppError {
  ConflictError(
    String code,
    String? message, {
    Map<String, dynamic>? details,
  }) : super(code, message, statusCode: 409, details: details);
}

/// Rate limit exceeded (429).
class RateLimitError extends AppError {
  /// Suggested wait time before retry, in milliseconds.
  final int? retryAfterMs;

  RateLimitError({
    String code = 'RATE_LIMIT_EXCEEDED',
    String message = 'Too many requests',
    Map<String, dynamic>? details,
    this.retryAfterMs,
  }) : super(
          code,
          message,
          statusCode: 429,
          details: {
            if (retryAfterMs != null) 'retry_after_ms': retryAfterMs,
            if (details != null) ...details,
          },
        );
}

/// Converts any thrown object into the standard error envelope.
///
/// AppError subclasses expose their stable [code] and [details]; for any
/// other object, a generic `INTERNAL_ERROR` is returned without leaking
/// internals (set [revealInternals] to `true` in development to include
/// the original error message).
Map<String, dynamic> toErrorResponse(
  Object err, {
  String? requestId,
  bool revealInternals = false,
}) {
  if (err is AppError) {
    return {
      'error': {
        'code': err.code,
        'message': err.message,
        'details': err.details,
        if (requestId != null) 'request_id': requestId,
      },
    };
  }
  return {
    'error': {
      'code': 'INTERNAL_ERROR',
      'message': 'An error occurred',
      'details':
          revealInternals ? {'original': err.toString()} : const {},
      if (requestId != null) 'request_id': requestId,
    },
  };
}
