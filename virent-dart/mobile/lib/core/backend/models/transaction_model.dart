/// Transaction (ledger entry) model.
///
/// Ported from `backend/v1/models/transactions.js`. Every balance
/// mutation on a user account is recorded as a transaction with a
/// signed amount (positive for top-ups, negative for trip payments and
/// penalties). The transaction type drives the UI icon and the
/// description text; the provider field identifies the payment gateway
/// (Click, Payme, internal, etc.).
library;


import 'json_helpers.dart';
/// Transaction type bucket. Mirrors the comments at the top of
/// `transactions.js`.
enum TransactionType {
  /// Balance top-up via Click.uz.
  topupClick,

  /// Balance top-up via Payme.uz.
  topupPayme,

  /// Balance top-up via direct card acquiring.
  topupCard,

  /// Balance top-up via a prepaid card redemption.
  topupPrepaid,

  /// Trip cost deduction.
  tripPayment,

  /// Refund (admin or auto).
  refund,

  /// Referral or promo bonus credit.
  bonus,

  /// Penalty (no-parking fee, damage charge, etc.).
  penalty,

  /// Juicer payout liability.
  juicerPayout;

  static TransactionType fromString(String? raw) {
    switch (raw) {
      case 'topup_click':
        return TransactionType.topupClick;
      case 'topup_payme':
        return TransactionType.topupPayme;
      case 'topup_card':
        return TransactionType.topupCard;
      case 'topup_prepaid':
        return TransactionType.topupPrepaid;
      case 'trip_payment':
        return TransactionType.tripPayment;
      case 'refund':
        return TransactionType.refund;
      case 'bonus':
        return TransactionType.bonus;
      case 'penalty':
        return TransactionType.penalty;
      case 'juicer_payout':
        return TransactionType.juicerPayout;
      default:
        return TransactionType.tripPayment;
    }
  }

  String get wire => switch (this) {
        TransactionType.topupClick => 'topup_click',
        TransactionType.topupPayme => 'topup_payme',
        TransactionType.topupCard => 'topup_card',
        TransactionType.topupPrepaid => 'topup_prepaid',
        TransactionType.tripPayment => 'trip_payment',
        TransactionType.refund => 'refund',
        TransactionType.bonus => 'bonus',
        TransactionType.penalty => 'penalty',
        TransactionType.juicerPayout => 'juicer_payout',
      };

  /// `true` when the type yields a credit to the user's balance.
  bool get isCredit =>
      this == TransactionType.topupClick ||
      this == TransactionType.topupPayme ||
      this == TransactionType.topupCard ||
      this == TransactionType.topupPrepaid ||
      this == TransactionType.refund ||
      this == TransactionType.bonus;

  /// `true` when the type is a top-up variant.
  bool get isTopup =>
      this == TransactionType.topupClick ||
      this == TransactionType.topupPayme ||
      this == TransactionType.topupCard ||
      this == TransactionType.topupPrepaid;
}

/// Payment lifecycle status.
enum TransactionStatus {
  /// Created but not yet processed by the provider.
  pending,

  /// Provider pre-confirmed the transaction (Click `prepare` step).
  preparing,

  /// Successfully completed — balance credited/deducted.
  completed,

  /// Provider reported failure.
  failed,

  /// Cancelled by the user or admin.
  cancelled;

  static TransactionStatus fromString(String? raw) {
    switch (raw) {
      case 'pending':
        return TransactionStatus.pending;
      case 'preparing':
        return TransactionStatus.preparing;
      case 'completed':
      case 'success':
        return TransactionStatus.completed;
      case 'failed':
      case 'error':
        return TransactionStatus.failed;
      case 'cancelled':
      case 'canceled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  String get wire => switch (this) {
        TransactionStatus.pending => 'pending',
        TransactionStatus.preparing => 'preparing',
        TransactionStatus.completed => 'completed',
        TransactionStatus.failed => 'failed',
        TransactionStatus.cancelled => 'cancelled',
      };

  bool get isTerminal =>
      this == TransactionStatus.completed ||
      this == TransactionStatus.failed ||
      this == TransactionStatus.cancelled;
}

/// Payment method.
enum PaymentMethod {
  /// Internal balance transfer (no external gateway).
  balance,

  /// External gateway (Click, Payme, card).
  external,

  /// Cash (rare, used by juicer/mechanic payouts in some flows).
  cash;

  static PaymentMethod fromString(String? raw) {
    switch (raw) {
      case 'balance':
      case 'internal':
        return PaymentMethod.balance;
      case 'external':
        return PaymentMethod.external;
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.balance;
    }
  }

  String get wire => switch (this) {
        PaymentMethod.balance => 'balance',
        PaymentMethod.external => 'external',
        PaymentMethod.cash => 'cash',
      };
}

/// Single ledger entry.
class TransactionModel {
  /// MongoDB `_id` of the transaction.
  final String id;

  /// `_id` of the user whose balance was mutated.
  final String? userId;

  /// `_id` of the trip that triggered the transaction, when applicable.
  final String? tripId;

  /// `_id` of the juicer being paid, when [type] is
  /// [TransactionType.juicerPayout].
  final String? juicerId;

  /// `_id` of the scooter referenced by the transaction, when applicable.
  final String? scooterId;

  /// Transaction type bucket.
  final TransactionType type;

  /// Raw type string (preserved for forward compatibility).
  final String typeRaw;

  /// Signed amount in UZS tiyin. Positive for credits, negative for
  /// debits.
  final int amount;

  /// User's balance immediately after this transaction was applied.
  /// `null` for pending/failed transactions.
  final int? balanceAfter;

  /// ISO-4217 currency code. Defaults to `UZS`.
  final String currency;

  /// Human-readable description shown in the transaction list.
  final String description;

  /// Payment method.
  final PaymentMethod method;

  /// Payment provider slug (`click`, `payme`, `card`, `internal`).
  final String provider;

  /// Provider-side transaction ID (e.g. Click `click_trans_id`).
  final String? providerTxnId;

  /// Lifecycle status.
  final TransactionStatus status;

  /// Optional error code returned by the provider on failure.
  final int? errorCode;

  /// Cancellation reason, populated when [status] is
  /// [TransactionStatus.cancelled].
  final String? cancelReason;

  /// When the transaction was created.
  final DateTime? createdAt;

  /// When the transaction was completed.
  final DateTime? completedAt;

  /// When the transaction was last updated.
  final DateTime? updatedAt;

  /// Creates a [TransactionModel].
  const TransactionModel({
    required this.id,
    required this.type,
    required this.typeRaw,
    required this.amount,
    required this.description,
    required this.method,
    required this.provider,
    required this.status,
    this.userId,
    this.tripId,
    this.juicerId,
    this.scooterId,
    this.balanceAfter,
    this.currency = 'UZS',
    this.providerTxnId,
    this.errorCode,
    this.cancelReason,
    this.createdAt,
    this.completedAt,
    this.updatedAt,
  });

  /// Parses a JSON object (MongoDB document) into a [TransactionModel].
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? 'trip_payment').toString();
    return TransactionModel(
      id: stringifyId(json['_id'] ?? json['id']),
      userId: stringifyIdNullable(json['user_id'] ?? json['userId']),
      tripId: stringifyIdNullable(json['trip_id'] ?? json['tripId']),
      juicerId: stringifyIdNullable(json['juicer_id'] ?? json['juicerId']),
      scooterId:
          stringifyIdNullable(json['scooter_id'] ?? json['scooterId']),
      type: TransactionType.fromString(rawType),
      typeRaw: rawType,
      amount: toInt(json['amount']),
      balanceAfter: json['balance_after'] == null
          ? null
          : toInt(json['balance_after']),
      currency: (json['currency'] ?? 'UZS').toString(),
      description: (json['description'] ?? '').toString(),
      method: PaymentMethod.fromString(json['method']?.toString()),
      provider: (json['provider'] ?? 'internal').toString(),
      providerTxnId: asString(
          json['provider_txn_id'] ?? json['providerTxnId']),
      status: TransactionStatus.fromString(json['status']?.toString()),
      errorCode: json['error'] == null
          ? null
          : (json['error'] is int
              ? json['error'] as int
              : int.tryParse(json['error'].toString())),
      cancelReason: asString(json['cancel_reason']),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      completedAt: parseDate(json['completed_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  /// Absolute amount in UZS tiyin (always positive regardless of sign).
  int get absAmount => amount.abs();

  /// `true` when the transaction credits the user's balance.
  bool get isCredit => amount > 0;

  /// `true` when the transaction debits the user's balance.
  bool get isDebit => amount < 0;

  /// `true` when the transaction was successfully completed.
  bool get isCompleted => status == TransactionStatus.completed;

  /// `true` when the transaction is still pending (not yet terminal).
  bool get isPending => !status.isTerminal;

  /// Formatted amount string with sign and currency (e.g. `+5 000 UZS`).
  String get formattedAmount {
    final sign = amount >= 0 ? '+' : '-';
    return '$sign${absAmount.toString()} $currency';
  }

  /// Serialises the transaction back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        if (userId != null) 'user_id': userId,
        if (tripId != null) 'trip_id': tripId,
        if (juicerId != null) 'juicer_id': juicerId,
        if (scooterId != null) 'scooter_id': scooterId,
        'type': typeRaw,
        'amount': amount,
        if (balanceAfter != null) 'balance_after': balanceAfter,
        'currency': currency,
        'description': description,
        'method': method.wire,
        'provider': provider,
        if (providerTxnId != null) 'provider_txn_id': providerTxnId,
        'status': status.wire,
        if (errorCode != null) 'error': errorCode,
        if (cancelReason != null) 'cancel_reason': cancelReason,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// Returns a copy of this transaction with the given fields replaced.
  TransactionModel copyWith({
    String? id,
    String? userId,
    String? tripId,
    String? juicerId,
    String? scooterId,
    TransactionType? type,
    String? typeRaw,
    int? amount,
    int? balanceAfter,
    String? currency,
    String? description,
    PaymentMethod? method,
    String? provider,
    String? providerTxnId,
    TransactionStatus? status,
    int? errorCode,
    String? cancelReason,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      juicerId: juicerId ?? this.juicerId,
      scooterId: scooterId ?? this.scooterId,
      type: type ?? this.type,
      typeRaw: typeRaw ?? this.typeRaw,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      method: method ?? this.method,
      provider: provider ?? this.provider,
      providerTxnId: providerTxnId ?? this.providerTxnId,
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      cancelReason: cancelReason ?? this.cancelReason,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'TransactionModel($typeRaw, $formattedAmount, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Paginated transaction-list response wrapper.
class TransactionList {
  final List<TransactionModel> transactions;
  final int total;
  final int sum;
  final int limit;
  final int offset;

  const TransactionList({
    required this.transactions,
    required this.total,
    required this.sum,
    required this.limit,
    required this.offset,
  });

  factory TransactionList.fromJson(Map<String, dynamic> json) {
    final rawTxns = json['transactions'];
    return TransactionList(
      transactions: rawTxns is List
          ? rawTxns
              .whereType<Map>()
              .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      total: toInt(json['total']),
      sum: toInt(json['sum']),
      limit: toInt(json['limit']),
      offset: toInt(json['offset']),
    );
  }

  /// Net balance change across all transactions in the page.
  int get netChange => transactions.fold(0, (s, t) => s + t.amount);

  /// `true` when more pages exist beyond this one.
  bool get hasMore => offset + transactions.length < total;

  Map<String, dynamic> toJson() => {
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'total': total,
        'sum': sum,
        'limit': limit,
        'offset': offset,
      };

  @override
  String toString() =>
      'TransactionList(${transactions.length}/$total, sum: $sum)';
}

// --- internal helpers ----------------------------------------------------


