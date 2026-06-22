/// Prepaid card / voucher model.
///
/// Ported from `backend/v1/models/prepaid.js`. Prepaid cards are
/// single-or-multi-use codes that credit a user's balance when redeemed
/// via `POST /users/:id/addFunds`. The original JS module uses a flat
/// `users` array to track who has already redeemed; we preserve that
/// shape while also exposing a more conventional status enum.
library;


import 'json_helpers.dart';
/// Lifecycle status of a prepaid card.
enum PrepaidStatus {
  /// Card created but never redeemed; uses remain.
  unused,

  /// Card has been partially redeemed (multi-use card with uses left).
  partiallyUsed,

  /// Card has no uses remaining.
  used,

  /// Card passed its expiry date without being fully redeemed.
  expired,

  /// Admin revoked the card before redemption.
  revoked;

  static PrepaidStatus fromString(String? raw, {int? usesLeft}) {
    // If explicit status provided, use it.
    switch (raw) {
      case 'unused':
        return PrepaidStatus.unused;
      case 'partially_used':
      case 'partiallyUsed':
        return PrepaidStatus.partiallyUsed;
      case 'used':
        return PrepaidStatus.used;
      case 'expired':
        return PrepaidStatus.expired;
      case 'revoked':
      case 'disabled':
        return PrepaidStatus.revoked;
    }
    // Fall back to deriving from `usesLeft`.
    if (usesLeft != null) {
      if (usesLeft <= 0) return PrepaidStatus.used;
      return PrepaidStatus.unused;
    }
    return PrepaidStatus.unused;
  }

  String get wire => switch (this) {
        PrepaidStatus.unused => 'unused',
        PrepaidStatus.partiallyUsed => 'partially_used',
        PrepaidStatus.used => 'used',
        PrepaidStatus.expired => 'expired',
        PrepaidStatus.revoked => 'revoked',
      };

  /// `true` when the card can still be redeemed.
  bool get isRedeemable =>
      this == PrepaidStatus.unused ||
      this == PrepaidStatus.partiallyUsed;
}

/// Prepaid card document.
class PrepaidCard {
  /// MongoDB `_id` of the card.
  final String id;

  /// Human-readable redemption code (e.g. `WELCOME2024`).
  /// Generated via `hat()` when the backend does not specify one.
  final String code;

  /// Face value of the card in [currency] smallest units (UZS tiyin).
  final double amount;

  /// ISO-4217 currency code. Defaults to `UZS`.
  final String currency;

  /// Lifecycle status.
  final PrepaidStatus status;

  /// Maximum number of distinct users that may redeem this card.
  final int totalUses;

  /// Remaining redemptions.
  final int usesLeft;

  /// List of user `_id`s that have already redeemed the card.
  final List<String> usedBy;

  /// When each redemption occurred. Parallel to [usedBy]; `null` for
  /// legacy cards that only stored the user list.
  final List<DateTime?> usedAt;

  /// Optional batch identifier (e.g. `2024-Q1-marketing`).
  final String? batch;

  /// Optional expiry timestamp. Cards past this date cannot be redeemed.
  final DateTime? expiresAt;

  /// Card creation timestamp.
  final DateTime? createdAt;

  /// Creates a [PrepaidCard].
  const PrepaidCard({
    required this.id,
    required this.code,
    required this.amount,
    this.currency = 'UZS',
    required this.status,
    required this.totalUses,
    required this.usesLeft,
    this.usedBy = const [],
    this.usedAt = const [],
    this.batch,
    this.expiresAt,
    this.createdAt,
  });

  /// Parses a JSON object (MongoDB document) into a [PrepaidCard].
  factory PrepaidCard.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'];
    final rawUsedAt = json['used_at'];
    final usesLeft = toInt(json['usesLeft'] ?? json['uses_left']);
    final totalUses = toInt(json['totalUses'] ?? json['total_uses']);
    final usedBy = <String>[];
    if (rawUsers is List) {
      for (final u in rawUsers) {
        usedBy.add(stringifyId(u));
      }
    }
    final usedAt = <DateTime?>[];
    if (rawUsedAt is List) {
      for (final t in rawUsedAt) {
        usedAt.add(parseDate(t));
      }
    }
    return PrepaidCard(
      id: stringifyId(json['_id'] ?? json['id']),
      code: (json['code'] ?? '').toString(),
      amount: toDouble(json['amount']),
      currency: (json['currency'] ?? 'UZS').toString(),
      status: PrepaidStatus.fromString(json['status']?.toString(),
          usesLeft: usesLeft),
      totalUses: totalUses,
      usesLeft: usesLeft,
      usedBy: usedBy,
      usedAt: usedAt,
      batch: asString(json['batch']),
      expiresAt: parseDate(json['expires_at'] ?? json['expiresAt']),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  /// `true` when the card can still be redeemed by [userId].
  ///
  /// Mirrors the JS guard in `users.js::addUserFunds`: a card with
  /// `usesLeft < 1` is exhausted, and a user cannot redeem the same
  /// card twice.
  bool canBeRedeemedBy(String userId) {
    if (!status.isRedeemable) return false;
    if (usesLeft < 1) return false;
    if (usedBy.contains(userId)) return false;
    if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!)) {
      return false;
    }
    return true;
  }

  /// `true` when the card has been at least partially redeemed.
  bool get isPartiallyUsed => usedBy.isNotEmpty && usesLeft > 0;

  /// `true` when the card has expired without being fully redeemed.
  bool get isExpired =>
      expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!) &&
      usesLeft > 0;

  /// Effective status taking expiry into account.
  PrepaidStatus get effectiveStatus {
    if (isExpired) return PrepaidStatus.expired;
    if (usesLeft <= 0) return PrepaidStatus.used;
    if (usedBy.isNotEmpty) return PrepaidStatus.partiallyUsed;
    return PrepaidStatus.unused;
  }

  /// Serialises the card back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        'code': code,
        'amount': amount,
        'currency': currency,
        'status': effectiveStatus.wire,
        'totalUses': totalUses,
        'usesLeft': usesLeft,
        'users': usedBy,
        if (usedAt.isNotEmpty)
          'used_at': usedAt
              .map((t) => t == null ? null : t.toIso8601String())
              .toList(),
        if (batch != null) 'batch': batch,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  /// Returns a copy of this card with the given fields replaced.
  PrepaidCard copyWith({
    String? id,
    String? code,
    double? amount,
    String? currency,
    PrepaidStatus? status,
    int? totalUses,
    int? usesLeft,
    List<String>? usedBy,
    List<DateTime?>? usedAt,
    String? batch,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return PrepaidCard(
      id: id ?? this.id,
      code: code ?? this.code,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      totalUses: totalUses ?? this.totalUses,
      usesLeft: usesLeft ?? this.usesLeft,
      usedBy: usedBy ?? this.usedBy,
      usedAt: usedAt ?? this.usedAt,
      batch: batch ?? this.batch,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'PrepaidCard(code: $code, amount: $amount $currency, usesLeft: $usesLeft/$totalUses)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrepaidCard && other.code == code);

  @override
  int get hashCode => code.hashCode;
}

// --- internal helpers ----------------------------------------------------


