// admin_user_model.dart — Virent admin account model.
//
// Defines the canonical [AdminUser] DTO used by the admin feature. An admin
// account is *not* the same as a regular rider: admins hold a role
// (`super_admin`, `admin`, `operator`), a list of string permission codes
// (e.g. `scooters.edit`, `users.block`) and authenticate either by email +
// password (the `/admin/login` endpoint) or by phone OTP through the same
// `/auth/phone/send-code` + `/auth/phone/verify` flow used by riders.
//
// Pre-seeded super admin (created by [EmbeddedServer] on first boot):
//   email   : admin@virent.io
//   password: Admin123!
//   role    : super_admin
//   phone   : +998900000001

import 'package:flutter/foundation.dart';

/// The three roles an [AdminUser] can hold.
///
/// Ordered from most-privileged to least-privileged. Use [adminRoleFromString]
/// to safely parse a server-supplied role string.
enum AdminRole {
  /// Full control — can create / delete other admins and edit permissions.
  superAdmin,

  /// Standard admin — every dashboard module except "Manage Admins".
  admin,

  /// Read-only operator — limited to monitoring + support tickets.
  staff,
}

/// Extension adding JSON-friendly helpers to [AdminRole].
extension AdminRoleX on AdminRole {
  /// Wire string used in JSON payloads.
  String get wire => switch (this) {
        AdminRole.superAdmin => 'super_admin',
        AdminRole.admin => 'admin',
        AdminRole.staff => 'operator',
      };

  /// Human-readable label shown in the UI.
  String get label => switch (this) {
        AdminRole.superAdmin => 'Super Admin',
        AdminRole.admin => 'Admin',
        AdminRole.staff => 'Operator',
      };

  /// `true` when this role can manage other admin accounts.
  bool get canManageAdmins => this == AdminRole.superAdmin;
}

/// Parses a role string from the server into an [AdminRole].
///
/// Unknown values fall back to [AdminRole.staff] (least-privileged) so a
/// typo on the server side never accidentally grants admin powers.
AdminRole adminRoleFromString(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'super_admin':
    case 'superadmin':
      return AdminRole.superAdmin;
    case 'admin':
      return AdminRole.admin;
    case 'operator':
      return AdminRole.staff;
    default:
      return AdminRole.staff;
  }
}

/// Canonical model describing a Virent admin account.
///
/// Mirrors the `admins` collection held in [DataStore] on the embedded
/// server. Instances are immutable; use [copyWith] to derive a modified
/// copy. Two admins are considered equal when their [id] matches.
@immutable
class AdminUser {
  /// Server-side identifier (e.g. `admin-1`).
  final String id;

  /// Login email — unique across all admins.
  final String email;

  /// Display name shown in the top bar + manage-admins list.
  final String name;

  /// Authorisation role. See [AdminRole].
  final AdminRole role;

  /// Permission codes granted to this admin.
  ///
  /// The wildcard `*` (granted to [AdminRole.superAdmin]) short-circuits
  /// [hasPermission] so super admins can do everything. Otherwise each entry
  /// is a dotted string such as `scooters.edit`, `users.block`, `zones.delete`.
  final List<String> permissions;

  /// Phone number used for OTP login (E.164). Optional — admins may log in
  /// by email + password only.
  final String? phone;

  /// ISO-8601 creation timestamp.
  final String createdAt;

  /// ISO-8601 timestamp of the most recent successful login, or `null` when
  /// the admin has never signed in.
  final String? lastLoginAt;

  /// Creates an [AdminUser].
  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.permissions = const [],
    this.phone,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Convenience accessor — `true` when the admin holds super privileges.
  bool get isSuperAdmin => role == AdminRole.superAdmin;

  /// Convenience accessor — `true` for any non-operator role.
  bool get isStaff => role != AdminRole.staff;

  /// Returns the initials (first letter of each word in [name]) used in the
  /// top-bar avatar.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Returns `true` when this admin holds [permission] or the wildcard `*`.
  ///
  /// Permission codes are matched exactly (case-sensitive). Use dotted
  /// strings such as `scooters.edit` for fine-grained checks.
  bool hasPermission(String permission) {
    if (permissions.contains('*')) return true;
    return permissions.contains(permission);
  }

  /// Parses a JSON payload (as returned by `/admin/login` or `/admin/list`)
  /// into an [AdminUser].
  ///
  /// Accepts both camelCase and snake_case keys so the model is resilient to
  /// small API drift.
  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final permRaw = json['permissions'] ?? json['scopes'];
    final permissions = <String>[];
    if (permRaw is List) {
      for (final p in permRaw) {
        if (p == null) continue;
        permissions.add(p.toString());
      }
    }

    return AdminUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? json['mail'] ?? '').toString(),
      name: (json['name'] ?? json['full_name'] ?? json['fullName'] ?? 'Admin')
          .toString(),
      role: adminRoleFromString((json['role'] ?? 'operator').toString()),
      permissions: permissions,
      phone: (json['phone'] ?? json['phoneNumber'] ?? json['phone_number'])
          ?.toString(),
      createdAt: (json['createdAt'] ??
              json['created_at'] ??
              DateTime.now().toIso8601String())
          .toString(),
      lastLoginAt: (json['lastLoginAt'] ?? json['last_login_at'])
          ?.toString(),
    );
  }

  /// Serialises the admin to JSON for local persistence (SharedPreferences).
  ///
  /// The password is intentionally **not** included.
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.wire,
        'permissions': permissions,
        'phone': phone,
        'createdAt': createdAt,
        'lastLoginAt': lastLoginAt,
      };

  /// Returns a copy of this admin with the given fields overridden.
  AdminUser copyWith({
    String? id,
    String? email,
    String? name,
    AdminRole? role,
    List<String>? permissions,
    String? phone,
    String? createdAt,
    String? lastLoginAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AdminUser && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AdminUser(id: $id, email: $email, role: ${role.wire}, perms: $permissions)';
}

/// Bundle returned by `/admin/login` and embedded into the OTP verify
/// response when the phone belongs to an admin.
///
/// Carries the bearer token plus the resolved [AdminUser] so the client can
/// hydrate the admin auth state without an extra round-trip.
@immutable
class AdminLoginResponse {
  /// JWT access token issued by the server.
  final String token;

  /// Optional JWT refresh token.
  final String? refreshToken;

  /// The authenticated admin.
  final AdminUser admin;

  /// Human-readable message (e.g. "Login successful").
  final String message;

  /// Creates an [AdminLoginResponse].
  const AdminLoginResponse({
    required this.token,
    required this.admin,
    this.refreshToken,
    this.message = 'Login successful',
  });

  /// Parses a JSON payload into an [AdminLoginResponse].
  factory AdminLoginResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final token = (json['token'] ??
            json['access_token'] ??
            data['token'] ??
            data['access_token'] ??
            '')
        .toString();

    final adminJson =
        json['admin'] ?? data['admin'] ?? json['user'] ?? data['user'];
    if (adminJson is! Map<String, dynamic>) {
      throw const FormatException('admin/login response missing admin payload');
    }

    final refresh = (json['refresh_token'] ??
            data['refresh_token'] ??
            json['refreshToken'] ??
            data['refreshToken'])
        ?.toString();

    return AdminLoginResponse(
      token: token,
      refreshToken: refresh,
      admin: AdminUser.fromJson(adminJson),
      message:
          (json['message'] ?? data['message'] ?? 'Login successful').toString(),
    );
  }

  @override
  String toString() =>
      'AdminLoginResponse(token: ${token.length > 10 ? '${token.substring(0, 10)}…' : token}, '
      'admin: ${admin.email}, role: ${admin.role.wire})';
}

/// The canonical set of permission codes the Virent admin feature knows
/// about. Super admins always pass [AdminUser.hasPermission] regardless of
/// this list — it exists only to populate the permission editor in the
/// manage-admins screen.
class AdminPermissions {
  AdminPermissions._();

  /// Wildcard — granted to super admins only.
  static const all = '*';

  /// Every permission code, grouped by module. Order matters — the UI uses
  /// it to render the grouped checkbox list in the manage-admins dialog.
  static const Map<String, List<String>> grouped = {
    'Dashboard': ['dashboard.view'],
    'Scooters': ['scooters.view', 'scooters.edit', 'scooters.retire'],
    'Trips': ['trips.view', 'trips.refund'],
    'Customers': ['users.view', 'users.block', 'users.adjust_balance'],
    'Cities': ['cities.view', 'cities.edit'],
    'Zones': ['zones.view', 'zones.create', 'zones.delete'],
    'IoT': ['iot.view', 'iot.command'],
    'Analytics': ['analytics.view'],
    'Audit Log': ['audit.view'],
    'Prepaid': ['prepaid.create', 'prepaid.view'],
    'Juicers': ['juicers.view', 'juicers.edit'],
    'Support': ['support.view', 'support.assign', 'support.close'],
    'Push': ['notifications.send'],
    'SMS Gateway': ['sms.view', 'sms.ack'],
    'Settings': ['settings.view', 'settings.edit'],
    'Logs': ['logs.view'],
    'Admins': [
      'admins.view',
      'admins.create',
      'admins.delete',
      'admins.update_permissions',
    ],
  };

  /// Flat list of every non-wildcard permission.
  static List<String> get flat =>
      grouped.values.expand((list) => list).toList(growable: false);
}
