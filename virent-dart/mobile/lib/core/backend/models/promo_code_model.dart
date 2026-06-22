/// Promo-code and referral-program models.
///
/// Ported from `backend/v1/models/promocodes.js`. The backend supports
/// six promo-code types (see [PromoCodeType]) that drive either a flat
/// discount, a percentage discount, free minutes, or a cashback reward.
/// Two of the types (`referral_inviter`, `referral_invitee`) form the
/// referral program: an existing user shares their code, a new user
/// redeems it on first ride, and both receive a bonus.
library;


import 'json_helpers.dart';
/// Promo-code type bucket. Mirrors the `type` enum validated in
/// `promocodes.js::create`.
enum PromoCodeType {
  /// Discount applied to the user's first ride (flat or percentage).
  firstRide,

  /// Discount applied to any ride (flat or percentage).
  anyRide,

  /// N free minutes granted on the ride.
  freeMinutes,

  /// Percentage cashback credited to the user's balance after the ride.
  cashback,

  /// Bonus credited to the inviter after the referee's first ride.
  referralInviter,

  /// Bonus credited to the invitee on their first ride.
  referralInvitee;

  static PromoCodeType? fromString(String? raw) {
    switch (raw) {
      case 'first_ride':
        return PromoCodeType.firstRide;
      case 'any_ride':
        return PromoCodeType.anyRide;
      case 'free_minutes':
        return PromoCodeType.freeMinutes;
      case 'cashback':
        return PromoCodeType.cashback;
      case 'referral_inviter':
        return PromoCodeType.referralInviter;
      case 'referral_invitee':
        return PromoCodeType.referralInvitee;
      default:
        return null;
    }
  }

  String get wire => switch (this) {
        PromoCodeType.firstRide => 'first_ride',
        PromoCodeType.anyRide => 'any_ride',
        PromoCodeType.freeMinutes => 'free_minutes',
        PromoCodeType.cashback => 'cashback',
        PromoCodeType.referralInviter => 'referral_inviter',
        PromoCodeType.referralInvitee => 'referral_invitee',
      };

  /// `true` when the type is part of the referral program.
  bool get isReferral =>
      this == PromoCodeType.referralInviter ||
      this == PromoCodeType.referralInvitee;

  /// `true` when the type yields a discount on the current ride (as
  /// opposed to a post-ride cashback or bonus).
  bool get isRideDiscount =>
      this == PromoCodeType.firstRide ||
      this == PromoCodeType.anyRide ||
      this == PromoCodeType.freeMinutes;
}

/// Lifecycle status of a promo code.
enum PromoCodeStatus {
  /// Active and redeemable.
  active,

  /// Past its `validUntil` date.
  expired,

  /// Disabled by an admin (cannot be redeemed, even if not expired).
  disabled;

  static PromoCodeStatus fromString(String? raw) {
    switch (raw) {
      case 'active':
        return PromoCodeStatus.active;
      case 'expired':
        return PromoCodeStatus.expired;
      case 'disabled':
      case 'revoked':
        return PromoCodeStatus.disabled;
      default:
        return PromoCodeStatus.active;
    }
  }

  String get wire => switch (this) {
        PromoCodeStatus.active => 'active',
        PromoCodeStatus.expired => 'expired',
        PromoCodeStatus.disabled => 'disabled',
      };

  bool get isRedeemable => this == PromoCodeStatus.active;
}

/// Single redemption record embedded inside a [PromoCode].
class PromoRedemption {
  /// `_id` of the user who redeemed the code.
  final String userId;

  /// When the redemption occurred.
  final DateTime? usedAt;

  /// `_id` of the trip during which the redemption was applied, when
  /// known. Referral codes are redeemed before the trip but applied at
  /// trip-end, so this field is only populated post-trip.
  final String? tripId;

  const PromoRedemption({
    required this.userId,
    this.usedAt,
    this.tripId,
  });

  factory PromoRedemption.fromJson(Map<String, dynamic> json) =>
      PromoRedemption(
        userId: stringifyId(json['user_id'] ?? json['userId']),
        usedAt: parseDate(json['used_at'] ?? json['usedAt']),
        tripId: stringifyIdNullable(json['trip_id'] ?? json['tripId']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        if (usedAt != null) 'used_at': usedAt!.toIso8601String(),
        if (tripId != null) 'trip_id': tripId,
      };

  @override
  String toString() => 'PromoRedemption(user: $userId, at: $usedAt)';
}

/// Promo-code document.
class PromoCode {
  /// MongoDB `_id` of the promo code.
  final String id;

  /// Upper-case, alphanumeric code (e.g. `WELCOME2024`, `REF12AB`).
  final String code;

  /// Type bucket.
  final PromoCodeType type;

  /// Raw type string (preserved for forward compatibility).
  final String typeRaw;

  /// Numeric value of the promo. Interpretation depends on [type]:
  ///   * `firstRide`, `anyRide` — flat UZS amount when `value > 1`,
  ///     percentage when `value <= 1` (e.g. `0.2` for 20%).
  ///   * `freeMinutes` — number of free minutes.
  ///   * `cashback` — percentage (`0.05` for 5% or `5` for 5%).
  ///   * referral — flat UZS bonus.
  final double value;

  /// Lifecycle status.
  final PromoCodeStatus status;

  /// Maximum total redemptions across all users. `0` means unlimited.
  final int maxUses;

  /// Number of redemptions to date.
  final int usedCount;

  /// Maximum redemptions per user. `0` means unlimited (typical for
  /// referral-inviter codes that should count once per referral).
  final int perUserLimit;

  /// Minimum ride cost required to redeem the code (UZS tiyin). `0`
  /// means no minimum.
  final double minRideCost;

  /// Cap on the discount amount (UZS tiyin). `0` means no cap.
  final double maxDiscount;

  /// Window during which the code is valid. `validFrom` defaults to
  /// creation time when the backend omits it; `validTo` of `null` means
  /// the code never expires.
  final DateTime? validFrom;
  final DateTime? validTo;

  /// Whether the code is currently active (computed by the backend from
  /// [status] and the validity window).
  final bool isActive;

  /// List of users who have redeemed the code (embedded `used_by` array).
  final List<PromoRedemption> usedBy;

  /// `_id` of the referrer user, when [type] is a referral variant.
  final String? referrer;

  /// When the code was created.
  final DateTime? createdAt;

  /// When the code was disabled, when applicable.
  final DateTime? disabledAt;

  /// Optional campaign / batch label (e.g. `2024-summer-launch`).
  final String? batch;

  /// Creates a [PromoCode].
  const PromoCode({
    required this.id,
    required this.code,
    required this.type,
    required this.typeRaw,
    required this.value,
    this.status = PromoCodeStatus.active,
    this.maxUses = 0,
    this.usedCount = 0,
    this.perUserLimit = 1,
    this.minRideCost = 0,
    this.maxDiscount = 0,
    this.validFrom,
    this.validTo,
    this.isActive = true,
    this.usedBy = const [],
    this.referrer,
    this.createdAt,
    this.disabledAt,
    this.batch,
  });

  /// Parses a JSON object (MongoDB document) into a [PromoCode].
  factory PromoCode.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? 'any_ride').toString();
    final rawUsedBy = json['used_by'];
    return PromoCode(
      id: stringifyId(json['_id'] ?? json['id']),
      code: (json['code'] ?? '').toString().toUpperCase(),
      type: PromoCodeType.fromString(rawType) ?? PromoCodeType.anyRide,
      typeRaw: rawType,
      value: toDouble(json['value']),
      status: PromoCodeStatus.fromString(json['status']?.toString()),
      maxUses: toInt(json['max_uses'] ?? json['maxUses']),
      usedCount: toInt(json['used_count'] ?? json['usedCount']),
      perUserLimit: toInt(json['per_user_limit'] ?? json['perUserLimit']),
      minRideCost: toDouble(json['min_ride_cost'] ?? json['minRideCost']),
      maxDiscount: toDouble(json['max_discount'] ?? json['maxDiscount']),
      validFrom: parseDate(json['valid_from'] ?? json['validFrom']),
      validTo: parseDate(json['valid_until'] ??
          json['validUntil'] ??
          json['valid_to']),
      isActive: json['is_active'] ??
          (json['status'] == 'active' || json['status'] == null),
      usedBy: rawUsedBy is List
          ? rawUsedBy
              .whereType<Map>()
              .map((u) => PromoRedemption.fromJson(u as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      referrer: stringifyIdNullable(
          json['referrer'] ?? json['referrer_id']),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      disabledAt: parseDate(json['disabled_at'] ?? json['disabledAt']),
      batch: asString(json['batch']),
    );
  }

  /// `true` when the code is currently redeemable based on [status],
  /// the validity window, and the usage caps.
  ///
  /// Mirrors the JS guard stack in `promocodes.js::redeem`.
  bool get isCurrentlyValid {
    if (!status.isRedeemable || !isActive) return false;
    final now = DateTime.now().toUtc();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTo != null && now.isAfter(validTo!)) return false;
    if (maxUses > 0 && usedCount >= maxUses) return false;
    return true;
  }

  /// Number of redemptions remaining before [maxUses] is hit.
  /// `null` means unlimited.
  int? get remainingUses =>
      maxUses == 0 ? null : (maxUses - usedCount).clamp(0, maxUses);

  /// Number of times [userId] has already redeemed this code.
  int redemptionCountFor(String userId) =>
      usedBy.where((u) => u.userId == userId).length;

  /// `true` when [userId] has hit their per-user limit.
  bool isAtUserLimit(String userId) {
    if (perUserLimit == 0) return false; // unlimited
    return redemptionCountFor(userId) >= perUserLimit;
  }

  /// Previews the discount for a ride of [rideCost] UZS tiyin.
  ///
  /// Mirrors the calculation in `promocodes.js::redeem`. Returns a
  /// [PromoDiscountPreview] with discount / bonus minutes / cashback.
  PromoDiscountPreview previewDiscount({required double rideCost}) {
    double discount = 0;
    int bonusMinutes = 0;
    double cashbackPercent = 0;

    if (type == PromoCodeType.firstRide ||
        type == PromoCodeType.anyRide) {
      if (value <= 1) {
        // Percentage.
        discount = (rideCost * value * 100).round() / 100;
      } else {
        // Flat.
        discount = value < rideCost ? value : rideCost;
      }
      if (maxDiscount > 0 && discount > maxDiscount) {
        discount = maxDiscount;
      }
    } else if (type == PromoCodeType.freeMinutes) {
      bonusMinutes = value.floor();
    } else if (type == PromoCodeType.cashback) {
      cashbackPercent = value <= 1 ? value : value / 100;
    }

    final finalCost = rideCost - discount;
    return PromoDiscountPreview(
      discount: discount,
      bonusMinutes: bonusMinutes,
      cashbackPercent: cashbackPercent,
      finalCost: finalCost < 0 ? 0 : finalCost,
    );
  }

  /// Serialises the promo code back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        'code': code,
        'type': typeRaw,
        'value': value,
        'status': status.wire,
        'max_uses': maxUses,
        'used_count': usedCount,
        'per_user_limit': perUserLimit,
        'min_ride_cost': minRideCost,
        'max_discount': maxDiscount,
        if (validFrom != null) 'valid_from': validFrom!.toIso8601String(),
        if (validTo != null) 'valid_until': validTo!.toIso8601String(),
        'is_active': isActive,
        'used_by': usedBy.map((u) => u.toJson()).toList(),
        if (referrer != null) 'referrer': referrer,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (disabledAt != null) 'disabled_at': disabledAt!.toIso8601String(),
        if (batch != null) 'batch': batch,
      };

  /// Returns a copy of this promo code with the given fields replaced.
  PromoCode copyWith({
    String? id,
    String? code,
    PromoCodeType? type,
    String? typeRaw,
    double? value,
    PromoCodeStatus? status,
    int? maxUses,
    int? usedCount,
    int? perUserLimit,
    double? minRideCost,
    double? maxDiscount,
    DateTime? validFrom,
    DateTime? validTo,
    bool? isActive,
    List<PromoRedemption>? usedBy,
    String? referrer,
    DateTime? createdAt,
    DateTime? disabledAt,
    String? batch,
  }) {
    return PromoCode(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      typeRaw: typeRaw ?? this.typeRaw,
      value: value ?? this.value,
      status: status ?? this.status,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      perUserLimit: perUserLimit ?? this.perUserLimit,
      minRideCost: minRideCost ?? this.minRideCost,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      isActive: isActive ?? this.isActive,
      usedBy: usedBy ?? this.usedBy,
      referrer: referrer ?? this.referrer,
      createdAt: createdAt ?? this.createdAt,
      disabledAt: disabledAt ?? this.disabledAt,
      batch: batch ?? this.batch,
    );
  }

  @override
  String toString() =>
      'PromoCode($code, type: $typeRaw, value: $value, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromoCode && other.code == code);

  @override
  int get hashCode => code.hashCode;
}

/// Result of `POST /promocodes/redeem` (preview, not applied yet).
class PromoDiscountPreview {
  /// Discount amount (UZS tiyin) applied to the ride.
  final double discount;

  /// Free minutes granted.
  final int bonusMinutes;

  /// Cashback percentage (e.g. `0.05` for 5%). Applied post-ride.
  final double cashbackPercent;

  /// Final ride cost after discount.
  final double finalCost;

  const PromoDiscountPreview({
    required this.discount,
    required this.bonusMinutes,
    required this.cashbackPercent,
    required this.finalCost,
  });

  factory PromoDiscountPreview.fromJson(Map<String, dynamic> json) =>
      PromoDiscountPreview(
        discount: toDouble(json['discount']),
        bonusMinutes: toInt(json['bonus_minutes'] ?? json['bonusMinutes']),
        cashbackPercent:
            toDouble(json['cashback_percent'] ?? json['cashbackPercent']),
        finalCost: toDouble(json['final_cost'] ?? json['finalCost']),
      );

  /// Cashback amount (UZS tiyin) that will be credited post-ride, given
  /// the original [rideCost].
  double cashbackAmountFor(double rideCost) =>
      (rideCost * cashbackPercent * 100).round() / 100;

  Map<String, dynamic> toJson() => {
        'discount': discount,
        'bonus_minutes': bonusMinutes,
        'cashback_percent': cashbackPercent,
        'final_cost': finalCost,
      };

  @override
  String toString() =>
      'PromoDiscountPreview(discount: $discount, bonus: ${bonusMinutes}min, final: $finalCost)';
}

/// Referral-program summary returned by `GET /promocodes/referral`.
class ReferralSummary {
  /// The user's referral code (e.g. `REF12AB`).
  final String referralCode;

  /// Bonus credited to the invitee on first ride (UZS tiyin).
  final int inviteeBonus;

  /// Bonus credited to the inviter after the invitee's first ride
  /// (UZS tiyin).
  final int inviterBonus;

  /// Localised share text with the code embedded.
  final String shareText;

  const ReferralSummary({
    required this.referralCode,
    required this.inviteeBonus,
    required this.inviterBonus,
    required this.shareText,
  });

  factory ReferralSummary.fromJson(Map<String, dynamic> json) =>
      ReferralSummary(
        referralCode: (json['referral_code'] ?? '').toString(),
        inviteeBonus: toInt(json['invitee_bonus']),
        inviterBonus: toInt(json['inviter_bonus']),
        shareText: (json['share_text'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'referral_code': referralCode,
        'invitee_bonus': inviteeBonus,
        'inviter_bonus': inviterBonus,
        'share_text': shareText,
      };

  @override
  String toString() =>
      'ReferralSummary(code: $referralCode, invitee: $inviteeBonus, inviter: $inviterBonus)';
}

// --- internal helpers ----------------------------------------------------


