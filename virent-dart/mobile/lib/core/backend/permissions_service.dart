// permissions_service.dart — Centralized authorization policies.
//
// Ported from backend/src/shared/permissions.js. Per constitution §19.1:
// separate AuthN (who are you?) from AuthZ (what can you do?). Per §19.2:
// permissions are centralized here, never scattered in controllers.

import 'error_handler.dart';

/// All recognized roles in the system. Mirrors `ROLES` from permissions.js.
class Roles {
  static const String user = 'user';
  static const String admin = 'admin';
  static const String juicer = 'juicer';
  static const String mechanic = 'mechanic';
  static const String support = 'support';

  /// All roles, in order of privilege.
  static const List<String> all = [user, admin, juicer, mechanic, support];

  /// True if [role] is a recognized role.
  static bool isKnown(String role) => all.contains(role);
}

/// Signature of an authorization policy.
///
/// [user] is the authenticated principal (a [Map] with at least `id` and
/// `role`). [resource] is the optional resource the policy is being checked
/// against (e.g. the trip being cancelled).
typedef PolicyFn = bool Function(Map<String, dynamic>? user,
    [Map<String, dynamic>? resource]);

/// The policy catalog.
///
/// Each entry is keyed by its dotted policy name. Add new policies here —
/// never inline an `if (user.role == 'admin')` check in a controller.
class Policies {
  Policies._();

  /// User can read / update their own record.
  static bool userReadOwn(Map<String, dynamic>? user,
      [Map<String, dynamic>? resource]) {
    if (user == null || resource == null) return false;
    final userId = user['id']?.toString();
    final resourceId =
        (resource['user_id'] ?? resource['_id'] ?? resource['id'])?.toString();
    return userId != null && userId == resourceId;
  }

  /// User can read their own trip.
  static bool tripReadOwn(Map<String, dynamic>? user,
      [Map<String, dynamic>? trip]) {
    if (user == null || trip == null) return false;
    return user['id']?.toString() == trip['user_id']?.toString();
  }

  /// User can cancel their own trip.
  static bool tripCancelOwn(Map<String, dynamic>? user,
      [Map<String, dynamic>? trip]) {
    if (user == null || trip == null) return false;
    return user['id']?.toString() == trip['user_id']?.toString();
  }

  /// User can end their own trip.
  static bool tripEndOwn(Map<String, dynamic>? user,
      [Map<String, dynamic>? trip]) {
    if (user == null || trip == null) return false;
    return user['id']?.toString() == trip['user_id']?.toString();
  }

  /// Admin can do anything.
  static bool adminAny(Map<String, dynamic>? user,
      [Map<String, dynamic>? _]) {
    return user != null && user['role'] == Roles.admin;
  }

  /// Admin can refund a trip.
  static bool adminRefundTrip(Map<String, dynamic>? user,
      [Map<String, dynamic>? _]) {
    return user != null && user['role'] == Roles.admin;
  }

  /// Admin can create a promo code.
  static bool adminCreatePromo(Map<String, dynamic>? user,
      [Map<String, dynamic>? _]) {
    return user != null && user['role'] == Roles.admin;
  }

  /// Admin can create a scooter.
  static bool adminCreateScooter(Map<String, dynamic>? user,
      [Map<String, dynamic>? _]) {
    return user != null && user['role'] == Roles.admin;
  }

  /// Admin can delete a scooter.
  static bool adminDeleteScooter(Map<String, dynamic>? user,
      [Map<String, dynamic>? _]) {
    return user != null && user['role'] == Roles.admin;
  }

  /// Admin can broadcast a notification.
  static bool adminBroadcast(Map<String, dynamic>? user,
      [Map<String, dynamic>? _]) {
    return user != null && user['role'] == Roles.admin;
  }

  /// Juicer can claim a charging task.
  static bool juicerClaimTask(Map<String, dynamic>? user,
      [Map<String, dynamic>? _]) {
    return user != null && user['role'] == Roles.juicer;
  }

  /// Juicer owns a task assigned to them.
  static bool juicerOwnTask(Map<String, dynamic>? user,
      [Map<String, dynamic>? task]) {
    if (user == null || task == null) return false;
    return user['id']?.toString() == task['juicer_id']?.toString();
  }

  /// Mechanic owns a maintenance request assigned to them.
  static bool mechanicOwnRequest(Map<String, dynamic>? user,
      [Map<String, dynamic>? req]) {
    if (user == null || req == null) return false;
    return user['id']?.toString() == req['mechanic_id']?.toString();
  }

  /// The full catalog. Add new policies here.
  static const Map<String, PolicyFn> catalog = {
    'user.readOwn': userReadOwn,
    'user.updateOwn': userReadOwn,
    'trip.readOwn': tripReadOwn,
    'trip.cancelOwn': tripCancelOwn,
    'trip.endOwn': tripEndOwn,
    'admin.any': adminAny,
    'admin.refundTrip': adminRefundTrip,
    'admin.createPromo': adminCreatePromo,
    'admin.createScooter': adminCreateScooter,
    'admin.deleteScooter': adminDeleteScooter,
    'admin.broadcast': adminBroadcast,
    'juicer.claimTask': juicerClaimTask,
    'juicer.ownTask': juicerOwnTask,
    'mechanic.ownRequest': mechanicOwnRequest,
  };
}

/// Checks [policyName] against [user] / [resource].
///
/// Throws [ForbiddenError] when the policy denies the action. Use [canDo]
/// for a soft (boolean) check that never throws.
///
/// Throws a [StateError] when [policyName] is not in the catalog — this
/// usually indicates a typo in a controller.
bool can(
  Map<String, dynamic>? user,
  String policyName, [
  Map<String, dynamic>? resource,
]) {
  final policy = Policies.catalog[policyName];
  if (policy == null) {
    throw StateError('Unknown policy: $policyName');
  }
  if (!policy(user, resource)) {
    throw ForbiddenError(
      code: policyName,
      message: "You don't have permission: $policyName",
    );
  }
  return true;
}

/// Soft check — returns `true` when the policy allows the action, `false`
/// otherwise (including when the policy doesn't exist).
bool canDo(
  Map<String, dynamic>? user,
  String policyName, [
  Map<String, dynamic>? resource,
]) {
  final policy = Policies.catalog[policyName];
  if (policy == null) return false;
  return policy(user, resource);
}
