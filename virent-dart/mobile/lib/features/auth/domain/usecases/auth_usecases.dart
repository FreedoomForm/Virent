import '../../../../core/error/api_exceptions.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../entities/auth_entities.dart';

/// Initiates a phone-based login by requesting an OTP.
///
/// Ported from BarqScoot's `LoginWithPhoneUseCase`. Wraps
/// [AuthRepository.sendOtp] and returns the resulting [OtpResponse].
class LoginWithPhoneUseCase implements UseCase<OtpResponse, LoginRequest> {
  /// Creates a [LoginWithPhoneUseCase].
  LoginWithPhoneUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<OtpResponse> call({LoginRequest? params}) async {
    if (params == null ||
        params.phoneNumber == null ||
        params.phoneNumber!.isEmpty) {
      throw const AuthException('Phone number is required');
    }
    return _repository.sendOtp(params.phoneNumber!);
  }
}

/// Verifies a one-time password and completes authentication.
///
/// Ported from BarqScoot's `VerifyOtpUseCase`. On success the repository has
/// already persisted the session; this use case simply surfaces the domain
/// [VerifyOtpResponse] to the caller.
class VerifyOtpUseCase
    implements UseCase<VerifyOtpResponse, VerifyOtpParams> {
  /// Creates a [VerifyOtpUseCase].
  VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<VerifyOtpResponse> call({VerifyOtpParams? params}) async {
    if (params == null) {
      throw const AuthException('OTP verification parameters are required');
    }
    if (params.otp.length < 4) {
      throw const AuthException('OTP must be at least 4 digits');
    }
    return _repository.verifyOtp(params);
  }
}

/// Registers a new user account.
///
/// Ported from BarqScoot's `RegisterUserUsecase`. Returns the backend
/// confirmation message; callers typically follow up with
/// [LoginWithPhoneUseCase] to kick off OTP verification.
class RegisterUserUseCase implements UseCase<String, CreateUserRequest> {
  /// Creates a [RegisterUserUseCase].
  RegisterUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<String> call({CreateUserRequest? params}) async {
    if (params == null) {
      throw const AuthException('Registration details are required');
    }
    return _repository.register(params);
  }
}

/// Persists an authenticated [AuthUser] locally.
///
/// Ported from BarqScoot's `SaveUserUseCase`. Useful when the caller obtains
/// the user out-of-band (e.g. a deep-link login) and wants to cache it
/// without going through the standard OTP flow.
class SaveUserUseCase implements UseCase<void, SaveUserParams> {
  /// Creates a [SaveUserUseCase].
  SaveUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call({SaveUserParams? params}) async {
    if (params == null) {
      throw const AuthException('SaveUserParams are required');
    }
    final user = AuthUser(
      id: params.id,
      phoneNumber: params.phoneNumber,
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      isVerified: params.isVerified,
      walletBalance: params.walletBalance,
      role: params.role,
      status: params.status,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _repository.saveUser(
      token: params.token,
      refreshToken: params.refreshToken,
      user: user,
    );
  }
}

/// Parameters carried by [SaveUserUseCase].
class SaveUserParams {
  /// Server-side identifier.
  final String id;

  /// JWT access token.
  final String token;

  /// JWT refresh token, when available.
  final String? refreshToken;

  /// E.164 phone number.
  final String phoneNumber;

  /// Given name.
  final String firstName;

  /// Family name.
  final String lastName;

  /// Email address.
  final String email;

  /// Whether the phone number has been verified.
  final bool isVerified;

  /// Wallet balance in the smallest currency unit.
  final double walletBalance;

  /// Account role.
  final String role;

  /// Account status.
  final String status;

  /// Creates a [SaveUserParams].
  const SaveUserParams({
    required this.id,
    required this.token,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isVerified,
    required this.walletBalance,
    this.refreshToken,
    this.role = 'user',
    this.status = 'active',
  });
}

/// Terminates the current session and clears local credentials.
///
/// Ported from BarqScoot's logout flow.
class LogoutUseCase implements NoParamsUseCase<void> {
  /// Creates a [LogoutUseCase].
  LogoutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call() => _repository.logout();
}

/// Restores a previously persisted session.
///
/// Returns the [AuthUser] when a valid session exists, `null` otherwise.
class RestoreSessionUseCase implements NoParamsUseCase<AuthUser?> {
  /// Creates a [RestoreSessionUseCase].
  RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<AuthUser?> call() => _repository.restoreSession();
}
