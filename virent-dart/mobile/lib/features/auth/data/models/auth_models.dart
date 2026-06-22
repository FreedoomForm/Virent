import '../../../../core/error/api_exceptions.dart';

/// Response returned by the "send OTP" endpoint.
///
/// Mirrors BarqScoot's `OtpResponse`. The backend may return the payload
/// either at the root or nested under a `data` key — [fromJson] handles both
/// shapes so the model is resilient to small API drift.
class OtpResponse {
  /// Server-issued identifier for this OTP attempt. Must be sent back when
  /// verifying the code. May be empty when the backend does not require it.
  final String verificationId;

  /// Human readable confirmation message, suitable for a snackbar.
  final String message;

  /// Optional expiry timestamp (ISO-8601) the server may attach.
  final String? expiresAt;

  /// `true` when the server auto-verified an admin phone and the OTP step
  /// should be skipped. When this is `true`, [token], [userJson] and
  /// [adminToken] are populated and the client should persist the session
  /// directly.
  final bool autoVerified;

  /// JWT token issued by the server when [autoVerified] is `true`.
  final String? token;

  /// User JSON returned by the server when [autoVerified] is `true`.
  final Map<String, dynamic>? userJson;

  /// `true` when the auto-verified account has admin privileges.
  final bool isAdmin;

  /// Admin JWT token issued by the server when [autoVerified] is `true`
  /// and the account is an admin.
  final String? adminToken;

  /// Creates an [OtpResponse].
  const OtpResponse({
    required this.verificationId,
    required this.message,
    this.expiresAt,
    this.autoVerified = false,
    this.token,
    this.userJson,
    this.isAdmin = false,
    this.adminToken,
  });

  /// Parses a JSON payload into an [OtpResponse].
  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    // The Virent embedded server returns {success, message} at the root,
    // while the legacy Node backend wraps under {data: {...}}. Support both.
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final verificationId = (json['verificationId'] ??
            data['verificationId'] ??
            json['verification_id'] ??
            data['verification_id'] ??
            '')
        .toString();

    final message = (json['message'] ??
            data['message'] ??
            'Verification code sent successfully')
        .toString();

    final expiresAt = (json['expires_at'] ?? data['expires_at'])?.toString();

    // Admin auto-login fields
    final autoVerified = (json['auto_verified'] ?? data['auto_verified']) == true;
    final token = (json['token'] ?? data['token'])?.toString();
    final userJson = (json['user'] ?? data['user']) as Map<String, dynamic>?;
    final isAdmin = (json['is_admin'] ?? data['is_admin']) == true;
    final adminToken = (json['admin_token'] ?? data['admin_token'])?.toString();

    return OtpResponse(
      verificationId: verificationId,
      message: message,
      expiresAt: expiresAt,
      autoVerified: autoVerified,
      token: token,
      userJson: userJson,
      isAdmin: isAdmin,
      adminToken: adminToken,
    );
  }

  @override
  String toString() =>
      'OtpResponse(verificationId: $verificationId, message: $message, '
      'autoVerified: $autoVerified)';
}

/// Response returned by the credential / phone login endpoints.
///
/// Combines BarqScoot's `LoginResponse` with the token-pair shape used by the
/// legacy Virent backend (`access_token` / `refresh_token`).
class LoginResponse {
  /// JWT access token used to authenticate subsequent requests.
  final String token;

  /// JWT refresh token, when issued.
  final String? refreshToken;

  /// `true` when the backend created a brand new account during this login.
  final bool isNewUser;

  /// The authenticated user, when the backend includes it inline.
  final AuthUser? user;

  /// Optional human readable message.
  final String? message;

  /// Creates a [LoginResponse].
  const LoginResponse({
    required this.token,
    this.refreshToken,
    this.isNewUser = false,
    this.user,
    this.message,
  });

  /// Parses a JSON payload into a [LoginResponse].
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final token = (json['token'] ??
            json['access_token'] ??
            data['token'] ??
            data['access_token'] ??
            '')
        .toString();

    final refreshToken = (json['refresh_token'] ??
            data['refresh_token'] ??
            json['refreshToken'] ??
            data['refreshToken'])
        ?.toString();

    final isNewUser = (json['is_new_user'] ??
            json['isNewUser'] ??
            data['is_new_user'] ??
            data['isNewUser'] ??
            false) as bool;

    final userJson = json['user'] ?? data['user'];
    final user = userJson is Map<String, dynamic>
        ? AuthUser.fromJson(userJson)
        : null;

    final message = (json['message'] ?? data['message'])?.toString();

    return LoginResponse(
      token: token,
      refreshToken: refreshToken,
      isNewUser: isNewUser,
      user: user,
      message: message,
    );
  }

  @override
  String toString() =>
      'LoginResponse(token: ${token.length > 12 ? '${token.substring(0, 12)}…' : token}, '
      'isNewUser: $isNewUser, hasUser: ${user != null})';
}

/// Data-layer DTO for the "verify OTP" response.
///
/// Equivalent to BarqScoot's `VerifyOtpResponse`. Parses the various payload
/// shapes (embedded server vs. legacy Node backend) and exposes a [toDomain]
/// helper used by the repository.
class VerifyOtpResponseModel {
  /// JWT access token issued after a successful verification.
  final String token;

  /// JWT refresh token, when issued.
  final String? refreshToken;

  /// The authenticated user.
  final AuthUser user;

  /// Human readable message.
  final String message;

  /// `success` for 2xx responses.
  final String status;

  /// `true` when a new account was created during verification.
  final bool isNewUser;

  const VerifyOtpResponseModel({
    required this.token,
    required this.user,
    required this.message,
    required this.status,
    this.refreshToken,
    this.isNewUser = false,
  });

  /// Parses a JSON payload into a [VerifyOtpResponseModel].
  ///
  /// Throws [ApiException] when the payload does not contain a token.
  factory VerifyOtpResponseModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final token = (json['token'] ??
            json['access_token'] ??
            data['token'] ??
            data['access_token'])
        ?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException('No token received from server');
    }

    final refreshToken = (json['refresh_token'] ??
            data['refresh_token'] ??
            json['refreshToken'] ??
            data['refreshToken'])
        ?.toString();

    final userJson = json['user'] ?? data['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const ApiException('Invalid user payload in verify-OTP response');
    }

    final message = (json['message'] ?? data['message'] ?? 'Verified')
        .toString();
    final status = (json['status'] ?? data['status'] ?? 'success').toString();
    final isNewUser = (json['is_new_user'] ??
            data['is_new_user'] ??
            json['isNewUser'] ??
            data['isNewUser'] ??
            false) as bool;

    return VerifyOtpResponseModel(
      token: token,
      refreshToken: refreshToken,
      user: AuthUser.fromJson(userJson),
      message: message,
      status: status,
      isNewUser: isNewUser,
    );
  }

  @override
  String toString() =>
      'VerifyOtpResponseModel(status: $status, isNewUser: $isNewUser, user: $user)';
}

/// Canonical model describing the authenticated Virent user.
///
/// Named `AuthUser` (rather than `User`) to avoid clashing with the lighter
/// `User` model in `features/home/data/models/models.dart`. Both describe the
/// same entity; this one is the richer, auth-scoped representation used by
/// the auth feature.
class AuthUser {
  /// Server-side identifier.
  final String id;

  /// E.164 phone number.
  final String phoneNumber;

  /// Given name.
  final String firstName;

  /// Family name.
  final String lastName;

  /// Email address (optional).
  final String? email;

  /// Whether the phone number has been verified.
  final bool isVerified;

  /// Wallet balance in the smallest currency unit (e.g. tiyin).
  final double walletBalance;

  /// Account role: `user`, `admin`, `juicer`, `mechanic` or `support`.
  final String role;

  /// Account status: `active`, `blocked` or `deleted`.
  final String status;

  /// ISO-8601 creation timestamp.
  final String? createdAt;

  /// Returns the user's full name, falling back to the phone number.
  String get fullName {
    final joined = '$firstName $lastName'.trim();
    return joined.isEmpty ? phoneNumber : joined;
  }

  /// `true` when the account can sign in.
  bool get isActive => status == 'active';

  /// `true` when the user holds admin privileges.
  bool get isAdmin => role == 'admin';

  /// Creates an [AuthUser].
  const AuthUser({
    required this.id,
    required this.phoneNumber,
    this.firstName = '',
    this.lastName = '',
    this.email,
    this.isVerified = false,
    this.walletBalance = 0,
    this.role = 'user',
    this.status = 'active',
    this.createdAt,
  });

  /// Parses a JSON payload into an [AuthUser]. Accepts both camelCase and
  /// snake_case keys to stay compatible with both backends.
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final phone = (json['phoneNumber'] ??
            json['phone'] ??
            json['phone_number'] ??
            '')
        .toString();

    // Some backends return a single `name` field instead of first/last.
    String firstName = (json['firstName'] ?? json['first_name'] ?? '').toString();
    String lastName = (json['lastName'] ?? json['last_name'] ?? '').toString();
    if (firstName.isEmpty && lastName.isEmpty) {
      final full = (json['name'] ?? '').toString().trim();
      if (full.isNotEmpty) {
        final parts = full.split(RegExp(r'\s+'));
        firstName = parts.first;
        if (parts.length > 1) {
          lastName = parts.sublist(1).join(' ');
        }
      }
    }

    return AuthUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      phoneNumber: phone,
      firstName: firstName,
      lastName: lastName,
      email: (json['email'] ?? json['mail'])?.toString(),
      isVerified: (json['isVerified'] ??
              json['phone_verified'] ??
              json['phoneVerified'] ??
              false) as bool,
      walletBalance:
          ((json['walletBalance'] ?? json['balance'] ?? 0) as num)
              .toDouble(),
      role: (json['role'] ?? 'user').toString(),
      status: (json['status'] ?? 'active').toString(),
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString(),
    );
  }

  /// Serialises the user to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'isVerified': isVerified,
        'walletBalance': walletBalance,
        'role': role,
        'status': status,
        'createdAt': createdAt,
      };

  /// Returns a copy of this user with the given fields overridden.
  AuthUser copyWith({
    String? id,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? email,
    bool? isVerified,
    double? walletBalance,
    String? role,
    String? status,
    String? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      walletBalance: walletBalance ?? this.walletBalance,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'AuthUser(id: $id, phone: $phoneNumber, name: $fullName)';
}
