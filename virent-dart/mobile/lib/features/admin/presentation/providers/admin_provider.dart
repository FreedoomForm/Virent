import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/configs/services/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show apiClientProvider;
import '../../data/services/admin_repository.dart';

/// Provides the singleton [AdminRepository] used by every admin screen.
///
/// The repository shares the global [ApiClient] (defined in the auth feature)
/// so it inherits the bearer token set at login time.
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(apiClientProvider));
});

/// Async value of the fleet stats payload returned by `/admin/stats`.
final adminStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).getStats();
});

/// Async list of every scooter in the fleet.
final adminScootersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getScooters();
});

/// Async list of every geofenced zone.
final adminZonesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getZones();
});

/// Async list of every customer.
final adminCustomersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getCustomers();
});

/// Filters applied to the audit-log view.
class AuditLogFilters {
  /// Creates an immutable filter set.
  const AuditLogFilters({
    this.actor,
    this.action,
    this.entity,
    this.fromDate,
    this.toDate,
  });

  /// Substring match on the actor email / id.
  final String? actor;

  /// Exact action (`block`, `unblock`, `refund`, `iot_command`, ...).
  final String? action;

  /// Entity type affected (`user`, `scooter`, `zone`, `trip`).
  final String? entity;

  /// ISO date lower bound (inclusive).
  final String? fromDate;

  /// ISO date upper bound (inclusive).
  final String? toDate;

  /// Returns `true` when no filter is set.
  bool get isEmpty =>
      (actor == null || actor!.isEmpty) &&
      (action == null || action!.isEmpty) &&
      (entity == null || entity!.isEmpty) &&
      (fromDate == null || fromDate!.isEmpty) &&
      (toDate == null || toDate!.isEmpty);

  /// Converts to the query map consumed by [AdminRepository.getAuditLog].
  Map<String, String> toQuery() {
    final m = <String, String>{};
    if (actor != null && actor!.isNotEmpty) m['actor'] = actor!;
    if (action != null && action!.isNotEmpty) m['action'] = action!;
    if (entity != null && entity!.isNotEmpty) m['entity'] = entity!;
    if (fromDate != null && fromDate!.isNotEmpty) m['from'] = fromDate!;
    if (toDate != null && toDate!.isNotEmpty) m['to'] = toDate!;
    return m;
  }

  /// Returns a copy with the supplied fields replaced.
  AuditLogFilters copyWith({
    String? actor,
    String? action,
    String? entity,
    String? fromDate,
    String? toDate,
  }) {
    return AuditLogFilters(
      actor: actor ?? this.actor,
      action: action ?? this.action,
      entity: entity ?? this.entity,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

/// Currently applied audit-log filters.
final auditLogFiltersProvider =
    StateProvider<AuditLogFilters>((ref) => const AuditLogFilters());

/// Async audit-log entries, re-fetched whenever [auditLogFiltersProvider]
/// changes. NOTE: admin_web_providers.dart also defines adminAuditLogProvider
/// (without filters). This one is the filter-aware version used by the old
/// admin screens. The admin_web version is used by the web panel.
final adminAuditLogProviderFiltered =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final filters = ref.watch(auditLogFiltersProvider);
  return ref.read(adminRepositoryProvider).getAuditLog(filters.toQuery());
});

/// Global "is a long-running admin action in flight?" flag used by screens
/// to disable buttons while a command (block / refund / IoT) is being sent.
final adminLoadingProvider = StateProvider<bool>((ref) => false);
