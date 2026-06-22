import '../../data/models/auth_models.dart';

/// Domain entities for the Virent auth feature.
///
/// These are pure-Dart contracts used by the domain / presentation layers.
/// They intentionally carry no JSON parsing logic of their own — the data
/// layer (`auth_models.dart`) is responsible for serialisation.

/// Payload describing a new account to be created.
///
/// Ported from BarqScoot's `CreateUserRequest`. [toJson] produces the wire
/// format expected by the Virent backend.
class CreateUserRequest {
  /// Given name.
  final String firstName;

  /// Family name.
  final String lastName;

  /// Email address.
  final String email;

  /// E.164 phone number.
  final String phoneNumber;

  /// Plaintext password (hashed server-side).
  final String password;

  /// Date of birth.
  final DateTime dateOfBirth;

  /// `Male`, `Female` or `Other`.
  final String gender;

  /// Optional marketing / country hint.
  final String location;

  /// Creates a [CreateUserRequest].
  const CreateUserRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.dateOfBirth,
    required this.gender,
    this.location = 'Uzbekistan',
  });

  /// Serialises to the JSON shape expected by `/auth/register`.
  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'gender': gender,
        'location': location,
      };
}

/// Payload for the phone-based login flow.
///
/// Ported from BarqScoot's `LoginRequest`. When [email] and [password] are
/// supplied the request is treated as a credential login; otherwise the
/// phone number is used to trigger an OTP login.
class LoginRequest {
  /// E.164 phone number.
  final String? phoneNumber;

  /// Email address (credential login only).
  final String? email;

  /// Plaintext password (credential login only).
  final String? password;

  /// `true` when this is a credential (email + password) login.
  bool get isCredentialLogin =>
      email != null && email!.isNotEmpty && password != null;

  /// Creates a [LoginRequest].
  const LoginRequest({this.phoneNumber, this.email, this.password});

  /// Convenience constructor for phone-based login.
  const LoginRequest.phone(this.phoneNumber)
      : email = null,
        password = null;

  /// Convenience constructor for credential-based login.
  const LoginRequest.credentials({required this.email, required this.password})
      : phoneNumber = null;

  /// Serialises to JSON. Only emits the fields relevant to the chosen flow.
  Map<String, dynamic> toJson() {
    if (isCredentialLogin) {
      return {'email': email, 'password': password};
    }
    return {'phoneNumber': phoneNumber};
  }
}

/// Parameters required to verify a one-time password.
///
/// Ported from BarqScoot's `VerifyOtpParams`. [verificationId] may be empty
/// when the backend does not require it (the embedded server identifies OTP
/// attempts by phone number alone).
class VerifyOtpParams {
  /// E.164 phone number the code was sent to.
  final String phoneNumber;

  /// Server-issued identifier for this OTP attempt, when applicable.
  final String verificationId;

  /// The 6-digit code typed by the user.
  final String otp;

  /// Creates a [VerifyOtpParams].
  const VerifyOtpParams({
    required this.phoneNumber,
    required this.verificationId,
    required this.otp,
  });

  @override
  String toString() =>
      'VerifyOtpParams(phoneNumber: $phoneNumber, verificationId: $verificationId)';
}

/// Domain result of a successful OTP verification.
///
/// This is the entity returned to use cases / providers. It is mapped from
/// the data-layer [VerifyOtpResponseModel] by the repository.
class VerifyOtpResponse {
  /// JWT access token.
  final String token;

  /// JWT refresh token, when issued.
  final String? refreshToken;

  /// The authenticated user.
  final AuthUser user;

  /// Human readable message.
  final String message;

  /// `true` when a new account was created.
  final bool isNewUser;

  /// Creates a [VerifyOtpResponse].
  const VerifyOtpResponse({
    required this.token,
    required this.user,
    this.message = 'Verified',
    this.refreshToken,
    this.isNewUser = false,
  });

  @override
  String toString() =>
      'VerifyOtpResponse(isNewUser: $isNewUser, user: $user)';
}
