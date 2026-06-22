import 'json_helpers.dart';
/// Administrative user model with role-based access control.
///
/// Ported from `backend/v1/models/admins.js`. Admins authenticate via
/// email + bcrypt-hashed password and are granted permissions based on
/// their [role]. Every mutation they perform is recorded in the audit log
/// (see [AuditLogEntry]).
///
/// The original JS module exposed CRUD helpers (`getAdmins`, `getSpecificAdmin`,
/// `editAdmin`, `deleteAdmin`) that operated directly against the MongoDB
/// `admins` collection. In the Flutter client we only need the data shape.
class AdminModel {
  /// MongoDB `_id` (24-char hex) or surrogate identifier.
  final String id;

  /// Given name. Editable via `PUT /admins/:id`.
  final String firstName;

  /// Family name. Editable via `PUT /admins/:id`.
  final String lastName;

  /// Unique login email.
  final String email;

  /// Authorisation role. One of: `super_admin`, `admin`, `support`,
  /// `read_only`. Defaults to `admin` when the backend omits the field.
  final String role;

  /// Granular permission scopes (e.g. `scooters.edit`, `users.delete`,
  /// `trips.refund`). Super admins bypass this list.
  final List<String> permissions;

  /// Last successful login timestamp (UTC). `null` until first login.
  final DateTime? lastLogin;

  /// Account creation timestamp.
  final DateTime? createdAt;

  /// Last profile mutation timestamp.
  final DateTime? updatedAt;

  /// Creates an [AdminModel].
  const AdminModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.role = 'admin',
    this.permissions = const [],
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  /// Parses a JSON object (MongoDB document) into an [AdminModel].
  ///
  /// Resilient to missing fields — defaults are substituted so a partial
  /// payload never crashes the UI. Accepts both camelCase and snake_case
  /// variants for forward-compatibility with future backend revisions.
  factory AdminModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id'] ?? json['id'];
    final rawPerms = json['permissions'] ?? json['perms'];
    return AdminModel(
      id: rawId == null
          ? ''
          : (rawId is Map && rawId['\$oid'] != null
              ? rawId['\$oid'].toString()
              : rawId.toString()),
      firstName: (json['firstName'] ?? json['first_name'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'admin').toString(),
      permissions: rawPerms is List
          ? rawPerms.map((p) => p.toString()).toList(growable: false)
          : const [],
      lastLogin: parseDate(json['last_login'] ?? json['lastLogin']),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// Full name helper for display ("First Last").
  String get fullName => '$firstName $lastName'.trim();

  /// `true` when the admin can perform destructive operations on any
  /// resource. Equivalent to the JS `role === 'super_admin'` check.
  bool get isSuperAdmin => role == 'super_admin';

  /// `true` when [permission] is granted either explicitly or because the
  /// admin is a super admin.
  bool can(String permission) =>
      isSuperAdmin || permissions.contains(permission);

  /// Serialises the model back to a JSON map (used for local caching).
  Map<String, dynamic> toJson() => {
        '_id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
        'permissions': permissions,
        if (lastLogin != null) 'last_login': lastLogin!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// Returns a copy of this model with the given fields replaced.
  AdminModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    List<String>? permissions,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'AdminModel(id: $id, email: $email, role: $role, name: $fullName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AdminModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

