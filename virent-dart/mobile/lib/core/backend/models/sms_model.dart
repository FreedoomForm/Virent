/// SMS log and OTP models.
///
/// Ported from `backend/v1/models/sms.js`. The backend supports multiple
/// SMS providers (Eskiz.uz, PlayMobile, Smsc.ru) via the `SMS_PROVIDER`
/// env var, with a console-log fallback for development.
///
/// OTP codes are stored in the `otp_codes` MongoDB collection with a
/// 10-minute TTL index. This file ports:
///   * [SmsLog] — a single SMS delivery record
///   * [OtpCode] — a single OTP challenge issued to a phone number
///   * [SmsProvider] — enum of supported providers
library;


import 'json_helpers.dart';
/// Supported SMS providers. Mirrors the `SMS_PROVIDER` env-var values.
enum SmsProvider {
  /// Development mode — codes are written to stdout (`SMS DEV MODE`).
  console,

  /// Eskiz.uz SMS gateway (Uzbekistan).
  eskiz,

  /// PlayMobile USSD/SMS gateway (Uzbekistan).
  playmobile,

  /// Smsc.ru SMS gateway (Russia/CIS).
  smsc,

  /// Anything the client doesn't yet understand.
  unknown;

  static SmsProvider fromString(String? raw) {
    switch (raw) {
      case 'console':
      case 'console-fallback':
        return SmsProvider.console;
      case 'eskiz':
        return SmsProvider.eskiz;
      case 'playmobile':
        return SmsProvider.playmobile;
      case 'smsc':
        return SmsProvider.smsc;
      default:
        return SmsProvider.unknown;
    }
  }

  String get wire => switch (this) {
        SmsProvider.console => 'console',
        SmsProvider.eskiz => 'eskiz',
        SmsProvider.playmobile => 'playmobile',
        SmsProvider.smsc => 'smsc',
        SmsProvider.unknown => 'unknown',
      };

  /// `true` when this provider is a dev-only fallback (no real SMS sent).
  bool get isDev => this == SmsProvider.console;
}

/// Delivery status of a single SMS message.
enum SmsStatus {
  /// Message accepted by the provider, awaiting delivery report.
  queued,

  /// Message handed off to the carrier.
  sent,

  /// Carrier confirmed delivery to the handset.
  delivered,

  /// Carrier reported delivery failure (invalid number, DND, etc.).
  failed,

  /// Delivery expired (handset offline for >24h).
  expired;

  static SmsStatus fromString(String? raw) {
    switch (raw) {
      case 'queued':
      case 'pending':
        return SmsStatus.queued;
      case 'sent':
      case 'accepted':
        return SmsStatus.sent;
      case 'delivered':
        return SmsStatus.delivered;
      case 'failed':
      case 'error':
        return SmsStatus.failed;
      case 'expired':
        return SmsStatus.expired;
      default:
        return SmsStatus.sent;
    }
  }

  String get wire => switch (this) {
        SmsStatus.queued => 'queued',
        SmsStatus.sent => 'sent',
        SmsStatus.delivered => 'delivered',
        SmsStatus.failed => 'failed',
        SmsStatus.expired => 'expired',
      };

  bool get isTerminal =>
      this == SmsStatus.delivered ||
      this == SmsStatus.failed ||
      this == SmsStatus.expired;
}

/// Single SMS log entry.
///
/// Mirrors the shape produced by `sms.js::_sendViaProvider` plus the
/// surrounding `otp_codes` document.
class SmsLog {
  /// MongoDB `_id` of the SMS log entry.
  final String id;

  /// Recipient phone in `+998XXXXXXXXX` format.
  final String to;

  /// Message body. For OTP messages this is the templated string sent
  /// to the user (the actual OTP code is in [OtpCode.code]).
  final String body;

  /// Provider used to send this message.
  final SmsProvider provider;

  /// Delivery status.
  final SmsStatus status;

  /// Cost of the message in UZS tiyin. `0` for dev-mode sends.
  final int cost;

  /// Optional provider message ID (for delivery-report reconciliation).
  final String? providerMessageId;

  /// Why this message was sent: `login`, `signup`, `password_reset`,
  /// `transactional`, `marketing`, etc.
  final String purpose;

  /// When the message was sent (UTC).
  final DateTime? sentAt;

  /// When the carrier delivered the message, when known.
  final DateTime? deliveredAt;

  /// When the log entry was created.
  final DateTime? createdAt;

  /// Optional error message, populated when [status] is [SmsStatus.failed].
  final String? error;

  /// Creates an [SmsLog].
  const SmsLog({
    required this.id,
    required this.to,
    required this.body,
    required this.provider,
    required this.status,
    this.cost = 0,
    this.providerMessageId,
    this.purpose = 'login',
    this.sentAt,
    this.deliveredAt,
    this.createdAt,
    this.error,
  });

  /// Parses a JSON object into an [SmsLog].
  factory SmsLog.fromJson(Map<String, dynamic> json) => SmsLog(
        id: stringifyId(json['_id'] ?? json['id']),
        to: (json['to'] ?? json['phone'] ?? '').toString(),
        body: (json['body'] ?? json['message'] ?? '').toString(),
        provider: SmsProvider.fromString(
            (json['provider'] ?? 'console').toString()),
        status: SmsStatus.fromString(json['status']?.toString()),
        cost: toInt(json['cost']),
        providerMessageId: asString(json['provider_message_id'] ??
            json['providerMessageId'] ??
            json['message_id']),
        purpose: (json['purpose'] ?? 'login').toString(),
        sentAt: parseDate(json['sent_at'] ?? json['sentAt']),
        deliveredAt: parseDate(json['delivered_at'] ?? json['deliveredAt']),
        createdAt: parseDate(json['created_at'] ?? json['createdAt']),
        error: asString(json['error']),
      );

  /// `true` when the message was sent in dev mode (no real SMS).
  bool get isDevMode => provider.isDev;

  /// `true` when the message was successfully delivered.
  bool get isDelivered => status == SmsStatus.delivered;

  /// Latency between send and delivery, in seconds. `null` when not
  /// yet delivered.
  int? get deliveryLatencySec => deliveredAt == null || sentAt == null
      ? null
      : deliveredAt!.difference(sentAt!).inSeconds;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'to': to,
        'body': body,
        'provider': provider.wire,
        'status': status.wire,
        'cost': cost,
        if (providerMessageId != null) 'provider_message_id': providerMessageId,
        'purpose': purpose,
        if (sentAt != null) 'sent_at': sentAt!.toIso8601String(),
        if (deliveredAt != null)
          'delivered_at': deliveredAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (error != null) 'error': error,
      };

  SmsLog copyWith({
    String? id,
    String? to,
    String? body,
    SmsProvider? provider,
    SmsStatus? status,
    int? cost,
    String? providerMessageId,
    String? purpose,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? createdAt,
    String? error,
  }) {
    return SmsLog(
      id: id ?? this.id,
      to: to ?? this.to,
      body: body ?? this.body,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      providerMessageId: providerMessageId ?? this.providerMessageId,
      purpose: purpose ?? this.purpose,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      error: error ?? this.error,
    );
  }

  @override
  String toString() =>
      'SmsLog(to: $to, provider: ${provider.wire}, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsLog && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// OTP challenge document.
///
/// Mirrors the `otp_codes` MongoDB collection shape, including the
/// 10-minute TTL index on `expires_at`.
class OtpCode {
  /// MongoDB `_id` of the OTP document.
  final String id;

  /// Recipient phone in `+998XXXXXXXXX` format.
  final String phone;

  /// 6-digit OTP code (plaintext, for dev-mode display).
  /// In production this is only stored as [codeHash]; [code] is `null`.
  final String? code;

  /// SHA-256 hash of the code (with JWT_SECRET salt), as stored in DB.
  final String? codeHash;

  /// Why the OTP was issued: `login`, `signup`, `password_reset`, etc.
  final String purpose;

  /// `true` when the code has been consumed (verified or invalidated).
  final bool used;

  /// Number of failed verification attempts so far. After
  /// [OtpCode.maxAttempts] attempts the code is auto-invalidated.
  final int attempts;

  /// When the code was issued.
  final DateTime? createdAt;

  /// When the code expires (10 minutes after [createdAt] by default).
  final DateTime? expiresAt;

  /// When the code was successfully verified, when applicable.
  final DateTime? verifiedAt;

  /// When the code was invalidated (superseded by a newer code, or
  /// blocked after too many attempts).
  final DateTime? invalidatedAt;

  /// When the code was blocked after exceeding [maxAttempts].
  final DateTime? blockedAt;

  /// Hard cap on verification attempts. Mirrors `MAX_ATTEMPTS = 5` in
  /// `sms.js`.
  static const int maxAttempts = 5;

  /// OTP length in digits. Mirrors `OTP_LENGTH = 6` in `sms.js`.
  static const int length = 6;

  /// TTL in minutes. Mirrors `OTP_TTL_MIN = 10` in `sms.js`.
  static const int ttlMinutes = 10;

  /// Resend cooldown in seconds. Mirrors `RESEND_COOLDOWN_SEC = 60`.
  static const int resendCooldownSec = 60;

  /// Creates an [OtpCode].
  const OtpCode({
    required this.id,
    required this.phone,
    required this.purpose,
    this.code,
    this.codeHash,
    this.used = false,
    this.attempts = 0,
    this.createdAt,
    this.expiresAt,
    this.verifiedAt,
    this.invalidatedAt,
    this.blockedAt,
  });

  /// Parses a JSON object (MongoDB document) into an [OtpCode].
  factory OtpCode.fromJson(Map<String, dynamic> json) => OtpCode(
        id: stringifyId(json['_id'] ?? json['id']),
        phone: (json['phone'] ?? '').toString(),
        code: asString(json['code']),
        codeHash: asString(json['code_hash'] ?? json['codeHash']),
        purpose: (json['purpose'] ?? 'login').toString(),
        used: json['used'] == true,
        attempts: toInt(json['attempts']),
        createdAt: parseDate(json['created_at']),
        expiresAt: parseDate(json['expires_at']),
        verifiedAt: parseDate(json['verified_at']),
        invalidatedAt: parseDate(json['invalidated_at']),
        blockedAt: parseDate(json['blocked_at']),
      );

  /// `true` when the code is still valid (not used, not expired, not
  /// blocked, attempts remaining).
  bool get isStillValid {
    if (used || blockedAt != null) return false;
    if (attempts >= maxAttempts) return false;
    final now = DateTime.now().toUtc();
    if (expiresAt != null && now.isAfter(expiresAt!)) return false;
    return true;
  }

  /// Number of verification attempts remaining before block.
  int get attemptsLeft => maxAttempts - attempts;

  /// `true` when the user can request a new code (cooldown elapsed).
  bool get canResend {
    if (createdAt == null) return true;
    final elapsed = DateTime.now().toUtc().difference(createdAt!);
    return elapsed.inSeconds >= resendCooldownSec;
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'phone': phone,
        if (code != null) 'code': code,
        if (codeHash != null) 'code_hash': codeHash,
        'purpose': purpose,
        'used': used,
        'attempts': attempts,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        if (verifiedAt != null) 'verified_at': verifiedAt!.toIso8601String(),
        if (invalidatedAt != null)
          'invalidated_at': invalidatedAt!.toIso8601String(),
        if (blockedAt != null) 'blocked_at': blockedAt!.toIso8601String(),
      };

  @override
  String toString() =>
      'OtpCode(phone: $phone, purpose: $purpose, used: $used, attempts: $attempts/$maxAttempts)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OtpCode && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Phone-number normalisation helper.
///
/// Mirrors `sms.js::_normalizePhone`. Accepts `+998901234567`,
/// `998901234567`, `901234567`, `+998 90 123 45 67` and returns
/// `+998901234567` or `null` when the input is not a valid Uzbek
/// mobile number.
String? normalizePhone(String raw) {
  if (raw.isEmpty) return null;
  var p = raw.replaceAll(RegExp(r'[^\d+]'), '');
  if (p.startsWith('+')) p = p.substring(1);
  // Uzbekistan country code 998
  if (p.startsWith('998') && p.length == 12) return '+$p';
  if (p.length == 9 &&
      RegExp(r'^(90|91|93|94|95|97|98|99|88|33|71|55|77)').hasMatch(p)) {
    return '+998$p';
  }
  return null;
}

// --- internal helpers ----------------------------------------------------


