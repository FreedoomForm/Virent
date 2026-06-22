/// Per-user settings model.
///
/// Ported from `backend/v1/models/user_settings.js`. Each user has at
/// most one settings document, keyed by `user_id`. The backend exposes
/// `GET /user_settings` (returns the document, or defaults if absent)
/// and `PUT /user_settings` (upserts the document).
///
/// Fields mirror the `allowed` array in `user_settings.js::update`:
/// language, theme, push_ride_end_reminders, push_low_battery,
/// push_promos, default_city_id.
///
/// The Dart model widens the surface to also include email and SMS
/// notification preferences (the backend will gain these in a future
/// revision; for now they default to mirror the push settings).
library;


import 'json_helpers.dart';
/// Supported UI languages. The backend ships localisations for `ru`
/// (default), `uz`, and `en`.
enum UserLanguage {
  russian,
  uzbek,
  english,
  karakalpak;

  static UserLanguage fromString(String? raw) {
    switch (raw) {
      case 'ru':
      case 'rus':
        return UserLanguage.russian;
      case 'uz':
      case 'uzb':
        return UserLanguage.uzbek;
      case 'en':
      case 'eng':
        return UserLanguage.english;
      case 'kaa':
        return UserLanguage.karakalpak;
      default:
        return UserLanguage.russian;
    }
  }

  String get code => switch (this) {
        UserLanguage.russian => 'ru',
        UserLanguage.uzbek => 'uz',
        UserLanguage.english => 'en',
        UserLanguage.karakalpak => 'kaa',
      };

  /// Human-readable display name in the language itself.
  String get nativeName => switch (this) {
        UserLanguage.russian => 'Русский',
        UserLanguage.uzbek => 'O\'zbekcha',
        UserLanguage.english => 'English',
        UserLanguage.karakalpak => 'Qaraqalpaqsha',
      };
}

/// UI theme preference.
enum UserTheme {
  /// Always use light theme.
  light,

  /// Always use dark theme.
  dark,

  /// Follow the OS theme.
  system;

  static UserTheme fromString(String? raw) {
    switch (raw) {
      case 'light':
        return UserTheme.light;
      case 'dark':
        return UserTheme.dark;
      case 'system':
      case 'auto':
        return UserTheme.system;
      default:
        return UserTheme.light;
    }
  }

  String get wire => switch (this) {
        UserTheme.light => 'light',
        UserTheme.dark => 'dark',
        UserTheme.system => 'system',
      };
}

/// Privacy controls for the user.
class UserPrivacy {
  /// `true` when the user consents to share trip data with the city
  /// for analytics purposes.
  final bool shareTripAnalytics;

  /// `true` when the user consents to receive marketing communications.
  final bool allowMarketing;

  /// `true` when the user's profile should be hidden from public
  /// leaderboards (e.g. top riders).
  final bool hideFromLeaderboards;

  /// `true` when the user consents to location tracking during rides.
  final bool allowLocationTracking;

  const UserPrivacy({
    this.shareTripAnalytics = true,
    this.allowMarketing = false,
    this.hideFromLeaderboards = false,
    this.allowLocationTracking = true,
  });

  factory UserPrivacy.fromJson(Map<String, dynamic> json) => UserPrivacy(
        shareTripAnalytics: json['share_trip_analytics'] ?? true,
        allowMarketing: json['allow_marketing'] ?? false,
        hideFromLeaderboards: json['hide_from_leaderboards'] ?? false,
        allowLocationTracking: json['allow_location_tracking'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'share_trip_analytics': shareTripAnalytics,
        'allow_marketing': allowMarketing,
        'hide_from_leaderboards': hideFromLeaderboards,
        'allow_location_tracking': allowLocationTracking,
      };

  UserPrivacy copyWith({
    bool? shareTripAnalytics,
    bool? allowMarketing,
    bool? hideFromLeaderboards,
    bool? allowLocationTracking,
  }) {
    return UserPrivacy(
      shareTripAnalytics: shareTripAnalytics ?? this.shareTripAnalytics,
      allowMarketing: allowMarketing ?? this.allowMarketing,
      hideFromLeaderboards:
          hideFromLeaderboards ?? this.hideFromLeaderboards,
      allowLocationTracking:
          allowLocationTracking ?? this.allowLocationTracking,
    );
  }

  @override
  String toString() =>
      'UserPrivacy(analytics: $shareTripAnalytics, marketing: $allowMarketing)';
}

/// Per-channel notification preferences.
class UserNotificationSettings {
  /// Push notifications for ride-end reminders (cost summary).
  final bool pushRideEndReminders;

  /// Push notifications for low-battery warnings during a ride.
  final bool pushLowBattery;

  /// Push notifications for promotions and referral rewards.
  final bool pushPromos;

  /// Email notifications (receipts, weekly summaries). Defaults to
  /// `true` when the user has a verified email.
  final bool emailReceipts;

  /// Email notifications for promotions. Defaults to `false`.
  final bool emailPromos;

  /// SMS notifications for critical alerts (e.g. safety events).
  /// Defaults to `true` because the user must have a verified phone
  /// to use the app.
  final bool smsCritical;

  /// SMS notifications for marketing. Defaults to `false` (regulated
  /// by telecom laws in most markets).
  final bool smsMarketing;

  const UserNotificationSettings({
    this.pushRideEndReminders = true,
    this.pushLowBattery = true,
    this.pushPromos = true,
    this.emailReceipts = true,
    this.emailPromos = false,
    this.smsCritical = true,
    this.smsMarketing = false,
  });

  factory UserNotificationSettings.fromJson(Map<String, dynamic> json) =>
      UserNotificationSettings(
        pushRideEndReminders:
            json['push_ride_end_reminders'] ?? true,
        pushLowBattery: json['push_low_battery'] ?? true,
        pushPromos: json['push_promos'] ?? true,
        emailReceipts: json['email_receipts'] ?? true,
        emailPromos: json['email_promos'] ?? false,
        smsCritical: json['sms_critical'] ?? true,
        smsMarketing: json['sms_marketing'] ?? false,
      );

  /// `true` when *any* push notification channel is enabled.
  bool get anyPushEnabled =>
      pushRideEndReminders || pushLowBattery || pushPromos;

  /// `true` when *any* email channel is enabled.
  bool get anyEmailEnabled => emailReceipts || emailPromos;

  /// `true` when *any* SMS channel is enabled.
  bool get anySmsEnabled => smsCritical || smsMarketing;

  Map<String, dynamic> toJson() => {
        'push_ride_end_reminders': pushRideEndReminders,
        'push_low_battery': pushLowBattery,
        'push_promos': pushPromos,
        'email_receipts': emailReceipts,
        'email_promos': emailPromos,
        'sms_critical': smsCritical,
        'sms_marketing': smsMarketing,
      };

  UserNotificationSettings copyWith({
    bool? pushRideEndReminders,
    bool? pushLowBattery,
    bool? pushPromos,
    bool? emailReceipts,
    bool? emailPromos,
    bool? smsCritical,
    bool? smsMarketing,
  }) {
    return UserNotificationSettings(
      pushRideEndReminders:
          pushRideEndReminders ?? this.pushRideEndReminders,
      pushLowBattery: pushLowBattery ?? this.pushLowBattery,
      pushPromos: pushPromos ?? this.pushPromos,
      emailReceipts: emailReceipts ?? this.emailReceipts,
      emailPromos: emailPromos ?? this.emailPromos,
      smsCritical: smsCritical ?? this.smsCritical,
      smsMarketing: smsMarketing ?? this.smsMarketing,
    );
  }

  @override
  String toString() =>
      'UserNotifications(push: $anyPushEnabled, email: $anyEmailEnabled, sms: $anySmsEnabled)';
}

/// Per-user settings document.
class UserSettings {
  /// `_id` of the user these settings belong to.
  final String userId;

  /// UI language preference.
  final UserLanguage language;

  /// UI theme preference.
  final UserTheme theme;

  /// Per-channel notification preferences.
  final UserNotificationSettings notifications;

  /// Privacy controls.
  final UserPrivacy privacy;

  /// `_id` of the user's preferred city. `null` until the user picks
  /// one in onboarding.
  final String? defaultCityId;

  /// When the settings document was last updated.
  final DateTime? updatedAt;

  /// When the settings document was first created.
  final DateTime? createdAt;

  /// Creates a [UserSettings].
  const UserSettings({
    required this.userId,
    this.language = UserLanguage.russian,
    this.theme = UserTheme.light,
    this.notifications = const UserNotificationSettings(),
    this.privacy = const UserPrivacy(),
    this.defaultCityId,
    this.updatedAt,
    this.createdAt,
  });

  /// Parses a JSON object (MongoDB document) into a [UserSettings].
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final rawNotifications = json['notifications'];
    final rawPrivacy = json['privacy'];
    return UserSettings(
      userId: stringifyId(json['user_id'] ?? json['userId']),
      language:
          UserLanguage.fromString(json['language']?.toString()),
      theme: UserTheme.fromString(json['theme']?.toString()),
      notifications: rawNotifications is Map<String, dynamic>
          ? UserNotificationSettings.fromJson(rawNotifications)
          : UserNotificationSettings.fromJson(
              _flattenNotificationFields(json)),
      privacy: rawPrivacy is Map<String, dynamic>
          ? UserPrivacy.fromJson(rawPrivacy)
          : const UserPrivacy(),
      defaultCityId: stringifyIdNullable(
          json['default_city_id'] ?? json['defaultCityId']),
      updatedAt: parseDate(json['updated_at']),
      createdAt: parseDate(json['created_at']),
    );
  }

  /// `true` when the user has explicitly opted into dark mode.
  bool get prefersDarkTheme => theme == UserTheme.dark;

  /// `true` when the user wants the OS to drive the theme.
  bool get followsSystemTheme => theme == UserTheme.system;

  /// Serialises the settings back to a JSON map.
  ///
  /// The output preserves both the flat push_* fields (for back-compat
  /// with the JS backend) and the nested `notifications`/`privacy`
  /// blocks (for forward compatibility).
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'language': language.code,
        'theme': theme.wire,
        ...notifications.toJson(),
        'notifications': notifications.toJson(),
        'privacy': privacy.toJson(),
        if (defaultCityId != null) 'default_city_id': defaultCityId,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  /// Returns a copy of this settings with the given fields replaced.
  UserSettings copyWith({
    String? userId,
    UserLanguage? language,
    UserTheme? theme,
    UserNotificationSettings? notifications,
    UserPrivacy? privacy,
    String? defaultCityId,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      defaultCityId: defaultCityId ?? this.defaultCityId,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'UserSettings(user: $userId, lang: ${language.code}, theme: ${theme.wire})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSettings && other.userId == userId);

  @override
  int get hashCode => userId.hashCode;
}

// --- internal helpers ----------------------------------------------------

/// Builds a flat notification-settings map from the legacy top-level
/// fields (`push_ride_end_reminders`, `push_low_battery`, `push_promos`)
/// when the backend hasn't migrated to the nested `notifications` block.
Map<String, dynamic> _flattenNotificationFields(Map<String, dynamic> json) {
  final result = <String, dynamic>{};
  const fields = [
    'push_ride_end_reminders',
    'push_low_battery',
    'push_promos',
  ];
  for (final f in fields) {
    if (json.containsKey(f)) result[f] = json[f];
  }
  return result;
}


