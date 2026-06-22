import '../../../../core/error/api_exceptions.dart';

/// Canonical representation of the authenticated Virent user.
///
/// Ported from BarqScoot's `UserModel` and aligned with the Virent
/// embedded-server schema. The model intentionally mirrors the field set
/// required by the profile screen: identity, contact, wallet balance,
/// aggregate trip count and the account creation timestamp. It is the richer
/// profile-scoped counterpart to the lighter `User` model in
/// `features/home/data/models/models.dart` (which only exposes what the map
/// and home screens need).
class UserProfileModel {
  /// Server-side identifier.
  final String id;

  /// Display name (concatenation of first / last name when the backend splits
  /// them, otherwise the single `name` field).
  final String name;

  /// First name (parsed from [name] when the backend does not split it).
  final String firstName;

  /// Last name (parsed from [name] when the backend does not split it).
  final String lastName;

  /// E.164 phone number.
  final String phone;

  /// Email address (may be empty when the user has not provided one).
  final String email;

  /// Wallet balance in the smallest currency unit (tiyin / UZS).
  final int balance;

  /// Total number of completed trips.
  final int tripsCount;

  /// Account role: `user`, `admin`, `juicer`, `mechanic` or `support`.
  final String role;

  /// Account status: `active`, `blocked` or `deleted`.
  final String status;

  /// ISO-8601 account creation timestamp.
  final String createdAt;

  /// Returns the user's initials (max 2 characters) for avatar fallbacks.
  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (phone.isNotEmpty) return phone.substring(phone.length - 2);
    return '?';
  }

  /// `true` when the user holds admin privileges.
  bool get isAdmin => role == 'admin';

  /// `true` when the account can sign in.
  bool get isActive => status == 'active';

  /// Creates a [UserProfileModel].
  const UserProfileModel({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.balance,
    required this.tripsCount,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  /// Parses a JSON payload into a [UserProfileModel].
  ///
  /// Accepts both `snake_case` and `camelCase` keys, handles the case where
  /// the backend returns a single `name` field instead of first/last, and
  /// coerces numeric strings. Throws [ApiException] when `id` is missing.
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    if (id.isEmpty) {
      throw const ApiException('User payload missing `id`');
    }

    String firstName = (json['firstName'] ?? json['first_name'] ?? '').toString();
    String lastName = (json['lastName'] ?? json['last_name'] ?? '').toString();
    String fullName = (json['name'] ?? json['full_name'] ?? '').toString();
    if (fullName.isEmpty) {
      fullName = '$firstName $lastName'.trim();
    }
    if (firstName.isEmpty && lastName.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(RegExp(r'\s+'));
      firstName = parts.first;
      if (parts.length > 1) lastName = parts.sublist(1).join(' ');
    }

    return UserProfileModel(
      id: id,
      name: fullName,
      firstName: firstName,
      lastName: lastName,
      phone: (json['phone'] ??
              json['phoneNumber'] ??
              json['phone_number'] ??
              '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      balance: _coerceInt(json['balance'] ?? json['walletBalance']),
      tripsCount: _coerceInt(json['trips_count'] ??
          json['tripsCount'] ??
          json['total_trips']),
      role: (json['role'] ?? 'user').toString(),
      status: (json['status'] ?? 'active').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
    );
  }

  /// Serialises the model to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'email': email,
        'balance': balance,
        'trips_count': tripsCount,
        'role': role,
        'status': status,
        'created_at': createdAt,
      };

  /// Returns a copy of the model with the given fields overridden.
  UserProfileModel copyWith({
    String? id,
    String? name,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    int? balance,
    int? tripsCount,
    String? role,
    String? status,
    String? createdAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      tripsCount: tripsCount ?? this.tripsCount,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'UserProfileModel(id: $id, name: $name, phone: $phone, '
      'balance: $balance, tripsCount: $tripsCount)';

  // ---- Helpers ---------------------------------------------------------------

  static int _coerceInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Represents a single active session on a user's account.
///
/// Used by [ProfileRepository.getSessions] to render the "Active sessions"
/// list on the settings screen.
class SessionModel {
  /// Server-side session identifier.
  final String id;

  /// Human readable device name (e.g. "Pixel 7", "Chrome on macOS").
  final String device;

  /// Approximate location string (e.g. "Tashkent, UZ").
  final String location;

  /// ISO-8601 timestamp of the last activity.
  final String lastActive;

  /// `true` when this is the session currently in use.
  final bool isCurrent;

  /// Creates a [SessionModel].
  const SessionModel({
    required this.id,
    required this.device,
    required this.location,
    required this.lastActive,
    required this.isCurrent,
  });

  /// Parses a JSON payload into a [SessionModel].
  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      device: (json['device'] ?? json['user_agent'] ?? 'Unknown device')
          .toString(),
      location: (json['location'] ?? json['ip'] ?? 'Unknown location')
          .toString(),
      lastActive:
          (json['last_active'] ?? json['lastActive'] ?? '').toString(),
      isCurrent: (json['is_current'] ?? json['isCurrent'] ?? false) as bool,
    );
  }

  @override
  String toString() =>
      'SessionModel(id: $id, device: $device, current: $isCurrent)';
}
