// auth_middleware.dart — Shelf middleware for authentication.
//
// Ported from backend/src/shared/auth-middleware.js. The legacy Node stack
// verified JWTs via `jsonwebtoken`; this Dart port uses opaque tokens held
// in a [TokenRegistry] so we don't need any external crypto dependency.
//
// Provided middlewares:
//   - [requireUser]     — must be authenticated as any user
//   - [requireAdmin]    — must be authenticated as an admin
//   - [requireJuicer]   — must be authenticated as a juicer
//   - [requireMechanic] — must be authenticated as a mechanic
//   - [optionalAuth]    — attaches user if a valid token is present
//
// Per constitution §19.1: separate AuthN (this file) from AuthZ
// (permissions_service.dart).

import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';

import 'permissions_service.dart';

/// Extracts a verified principal (user / admin) from a token.
///
/// The default implementation [InMemoryTokenRegistry] stores tokens in a
/// plain `Map` — suitable for the embedded backend. For a multi-instance
/// deployment swap in a Redis-backed implementation.
abstract class TokenRegistry {
  /// Looks up the principal associated with [token].
  ///
  /// Returns `null` when the token is missing, malformed, expired or
  /// revoked. The returned Map must contain at least `id` and `role`.
  Map<String, dynamic>? verify(String token);

  /// Issues a new token bound to [principal] and returns the token string.
  String issue(Map<String, dynamic> principal);

  /// Revokes [token] immediately.
  void revoke(String token);
}

/// Default in-memory token registry.
///
/// Tokens are random hex strings. The registry grows without bound — for
/// production wrap with an LRU / TTL eviction policy.
class InMemoryTokenRegistry implements TokenRegistry {
  final Map<String, Map<String, dynamic>> _tokens = {};
  final String Function() _tokenGenerator;

  InMemoryTokenRegistry({String Function()? tokenGenerator})
      : _tokenGenerator = tokenGenerator ?? _defaultTokenGenerator;

  static String _defaultTokenGenerator() {
    final rnd = DateTime.now().microsecondsSinceEpoch;
    final rnd2 = Random.secure().nextInt(0x7fffffff);
    return 'virent_${rnd.toRadixString(16)}_${rnd2.toRadixString(16)}';
  }

  @override
  Map<String, dynamic>? verify(String token) {
    final p = _tokens[token];
    if (p == null) return null;
    final exp = p['_exp'] as int?;
    if (exp != null && DateTime.now().millisecondsSinceEpoch > exp) {
      _tokens.remove(token);
      return null;
    }
    return p;
  }

  @override
  String issue(Map<String, dynamic> principal) {
    final token = _tokenGenerator();
    _tokens[token] = Map<String, dynamic>.from(principal);
    return token;
  }

  @override
  void revoke(String token) {
    _tokens.remove(token);
  }
}

/// Extracts the bearer token from a shelf [Request].
///
/// Looks at, in order:
///   1. `Authorization: Bearer <token>` header
///   2. `X-Access-Token` header (legacy Node compatibility)
///   3. `?token=` query parameter (used by WebSocket clients)
String? extractToken(Request request) {
  final authHeader = request.headers['authorization'];
  if (authHeader != null) {
    if (authHeader.toLowerCase().startsWith('bearer ')) {
      final token = authHeader.substring(7).trim();
      if (token.isNotEmpty) return token;
    }
  }
  final xAccess = request.headers['x-access-token'];
  if (xAccess != null && xAccess.isNotEmpty) return xAccess;
  final queryToken = request.url.queryParameters['token'];
  if (queryToken != null && queryToken.isNotEmpty) return queryToken;
  return null;
}

/// Reads the authenticated principal stored by the auth middleware.
///
/// Returns `null` when no middleware has run.
Map<String, dynamic>? currentUser(Request request) =>
    request.context['auth.user'] as Map<String, dynamic>?;

/// Reads the authenticated admin principal (set by [requireAdmin]).
Map<String, dynamic>? currentAdmin(Request request) =>
    request.context['auth.admin'] as Map<String, dynamic>?;

/// Builds a 401 response in the standard error envelope.
Response _unauthorized(String code, String message) {
  return Response(401,
      body: jsonEncode({
        'error': {'code': code, 'message': message},
      }),
      headers: const {'Content-Type': 'application/json'});
}

/// Builds a 403 response in the standard error envelope.
Response _forbidden(String code, String message) {
  return Response(403,
      body: jsonEncode({
        'error': {'code': code, 'message': message},
      }),
      headers: const {'Content-Type': 'application/json'});
}

/// Middleware that requires an authenticated user (any role).
///
/// On success the principal is attached to `request.context['auth.user']`.
Middleware requireUser(TokenRegistry registry) {
  return (Handler innerHandler) {
    return (Request request) async {
      final token = extractToken(request);
      if (token == null) return _unauthorized('UNAUTHORIZED', 'Authentication required');
      final user = registry.verify(token);
      if (user == null) return _unauthorized('TOKEN_INVALID', 'Invalid or expired token');
      return innerHandler(request.change(context: {'auth.user': user}));
    };
  };
}

/// Middleware that requires an authenticated admin.
///
/// On success the principal is attached to BOTH `auth.user` and `auth.admin`
/// (controllers typically check `auth.admin`).
Middleware requireAdmin(TokenRegistry registry) {
  return (Handler innerHandler) {
    return (Request request) async {
      final token = extractToken(request);
      if (token == null) return _unauthorized('UNAUTHORIZED', 'Admin authentication required');
      final user = registry.verify(token);
      if (user == null) return _unauthorized('TOKEN_INVALID', 'Invalid or expired token');
      if (user['role'] != Roles.admin) {
        return _forbidden('NOT_ADMIN', 'Admin access required');
      }
      return innerHandler(request.change(context: {
        'auth.user': user,
        'auth.admin': user,
      }));
    };
  };
}

/// Middleware that requires the authenticated user to have the `juicer` role.
Middleware requireJuicer(TokenRegistry registry) {
  return (Handler innerHandler) {
    return (Request request) async {
      final token = extractToken(request);
      if (token == null) return _unauthorized('UNAUTHORIZED', 'Authentication required');
      final user = registry.verify(token);
      if (user == null) return _unauthorized('TOKEN_INVALID', 'Invalid or expired token');
      if (user['role'] != Roles.juicer) {
        return _forbidden('NOT_JUICER', 'Juicer access required');
      }
      return innerHandler(request.change(context: {'auth.user': user}));
    };
  };
}

/// Middleware that requires the authenticated user to have the `mechanic` role.
Middleware requireMechanic(TokenRegistry registry) {
  return (Handler innerHandler) {
    return (Request request) async {
      final token = extractToken(request);
      if (token == null) return _unauthorized('UNAUTHORIZED', 'Authentication required');
      final user = registry.verify(token);
      if (user == null) return _unauthorized('TOKEN_INVALID', 'Invalid or expired token');
      if (user['role'] != Roles.mechanic) {
        return _forbidden('NOT_MECHANIC', 'Mechanic access required');
      }
      return innerHandler(request.change(context: {'auth.user': user}));
    };
  };
}

/// Middleware that attaches a principal if a valid token is present, but
/// does not reject the request when one isn't.
///
/// Use for endpoints that behave differently for anonymous vs. authenticated
/// users (e.g. scooter list with personalized pricing).
Middleware optionalAuth(TokenRegistry registry) {
  return (Handler innerHandler) {
    return (Request request) async {
      final token = extractToken(request);
      if (token == null) return innerHandler(request);
      final user = registry.verify(token);
      if (user == null) return innerHandler(request);
      return innerHandler(request.change(context: {'auth.user': user}));
    };
  };
}

/// Convenience: wraps [requireUser] then asserts [permission] via the
/// centralized [Policies] catalog.
///
/// Example:
///   Pipeline().addMiddleware(requirePermission(registry, 'trip.endOwn', resource: trip))
Middleware requirePermission(
  TokenRegistry registry,
  String permission, {
  Map<String, dynamic>? Function(Request)? resourceExtractor,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final token = extractToken(request);
      if (token == null) return _unauthorized('UNAUTHORIZED', 'Authentication required');
      final user = registry.verify(token);
      if (user == null) return _unauthorized('TOKEN_INVALID', 'Invalid or expired token');
      final resource =
          resourceExtractor != null ? resourceExtractor(request) : null;
      if (!canDo(user, permission, resource)) {
        return _forbidden('PERMISSION_DENIED', "You don't have permission: $permission");
      }
      return innerHandler(request.change(context: {'auth.user': user}));
    };
  };
}
