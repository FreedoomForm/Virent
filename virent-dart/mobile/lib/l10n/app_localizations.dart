// app_localizations.dart — Virent translation strings (en / ru / uz).
//
// Ported from BarqScoot's `l10n/app_localizations.dart` (which only shipped
// English + Arabic) and extended to cover Virent's three markets:
//
//   * `en` — default / fallback.
//   * `ru` — Russian (CIS-wide lingua franca).
//   * `uz` — Uzbek (domestic market).
//
// The implementation is intentionally hand-rolled (rather than generated from
// `.arb` files) so the project does not have to depend on the
// `intl_translation` / `flutter_gen` toolchain. Missing keys gracefully fall
// back to English, and finally to the raw key itself, so a missing translation
// never throws.
//
// Usage:
//   ```dart
//   final l = ref.watch(appLocalizationsProvider);
//   Text(l.t(L10n.startRide));
//   ```
//
// Add new strings by:
//   1. Adding a constant to [L10n].
//   2. Adding the English value to [_en].
//   3. Adding the Russian value to [_ru].
//   4. Adding the Uzbek value to [_uz].

import 'package:flutter/material.dart' show LocalizationsDelegate, Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale/locale_data.dart';
import '../core/locale/locale_provider.dart';

/// Stable string keys for every translatable message in the app.
///
/// Using a constant (rather than a raw `String`) lets the compiler catch
/// typos and lets future tooling extract `.arb` files automatically.
abstract final class L10n {
  L10n._();

  // ---- Common ---------------------------------------------------------------
  static const appName = 'appName';
  static const ok = 'ok';
  static const cancel = 'cancel';
  static const confirm = 'confirm';
  static const save = 'save';
  static const delete = 'delete';
  static const retry = 'retry';
  static const loading = 'loading';
  static const seeAll = 'seeAll';
  static const guest = 'guest';
  static const account = 'account';
  static const logout = 'logout';
  static const back = 'back';
  static const next = 'next';
  static const skip = 'skip';
  static const search = 'search';

  // ---- Auth -----------------------------------------------------------------
  static const phoneNumber = 'phoneNumber';
  static const enterOtp = 'enterOtp';
  static const verifyOtp = 'verifyOtp';
  static const resendOtp = 'resendOtp';
  static const otpSentTo = 'otpSentTo';
  static const resendIn = 'resendIn';
  static const seconds = 'seconds';
  static const login = 'login';
  static const signup = 'signup';
  static const welcomeBack = 'welcomeBack';

  // ---- Rides ----------------------------------------------------------------
  static const findNearby = 'findNearby';
  static const scanQr = 'scanQr';
  static const startRide = 'startRide';
  static const endRide = 'endRide';
  static const pauseRide = 'pauseRide';
  static const resumeRide = 'resumeRide';
  static const searching = 'searching';
  static const rideInProgress = 'rideInProgress';
  static const rideEnded = 'rideEnded';
  static const rideEndedSuccessfully = 'rideEndedSuccessfully';
  static const failedToEndRide = 'failedToEndRide';
  static const noActiveRide = 'noActiveRide';
  static const noActiveRideHint = 'noActiveRideHint';
  static const timeElapsed = 'timeElapsed';
  static const duration = 'duration';
  static const distance = 'distance';
  static const cost = 'cost';
  static const estimatedCost = 'estimatedCost';
  static const ratePerMin = 'ratePerMin';
  static const batteryLevel = 'batteryLevel';
  static const lastStation = 'lastStation';
  static const scooterStatus = 'scooterStatus';
  static const scooterId = 'scooterId';
  static const firmwareVersion = 'firmwareVersion';
  static const currentSpeed = 'currentSpeed';
  static const riding = 'riding';
  static const sos = 'sos';

  // ---- Wallet ---------------------------------------------------------------
  static const wallet = 'wallet';
  static const addMoney = 'addMoney';
  static const transactions = 'transactions';
  static const balance = 'balance';
  static const topUp = 'topUp';
  static const paymentMethods = 'paymentMethods';
  static const addPaymentMethod = 'addPaymentMethod';
  static const transactionHistory = 'transactionHistory';

  // ---- Profile --------------------------------------------------------------
  static const profile = 'profile';
  static const editProfile = 'editProfile';
  static const firstName = 'firstName';
  static const lastName = 'lastName';
  static const email = 'email';
  static const gender = 'gender';
  static const verifyIdentity = 'verifyIdentity';

  // ---- Settings -------------------------------------------------------------
  static const settings = 'settings';
  static const language = 'language';
  static const appearance = 'appearance';
  static const darkMode = 'darkMode';
  static const lightMode = 'lightMode';
  static const systemMode = 'systemMode';
  static const langAndRegion = 'langAndRegion';
  static const notifications = 'notifications';
  static const pushNotifications = 'pushNotifications';
  static const emailNotifications = 'emailNotifications';
  static const about = 'about';
  static const appVersion = 'appVersion';
  static const privacyPolicy = 'privacyPolicy';
  static const termsOfService = 'termsOfService';
  static const helpAndSupport = 'helpAndSupport';
  static const serverUrl = 'serverUrl';
  static const adminMode = 'adminMode';

  // ---- Admin ----------------------------------------------------------------
  static const adminDashboard = 'adminDashboard';
  static const adminSmsGateway = 'adminSmsGateway';
  static const adminZones = 'adminZones';
  static const adminIot = 'adminIot';
  static const adminCustomers = 'adminCustomers';
  static const adminAuditLog = 'adminAuditLog';
  static const adminAnalytics = 'adminAnalytics';
  static const totalTrips = 'totalTrips';
  static const totalRevenue = 'totalRevenue';
  static const activeScooters = 'activeScooters';
  static const totalCustomers = 'totalCustomers';

  // ---- Ride history ---------------------------------------------------------
  static const rideHistory = 'rideHistory';
  static const totalTime = 'totalTime';
  static const totalSpent = 'totalSpent';
  static const filterBy = 'filterBy';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const ongoing = 'ongoing';

  // ---- Notifications --------------------------------------------------------
  static const all = 'all';
  static const unread = 'unread';
  static const trip = 'trip';
  static const promo = 'promo';
  static const markAllRead = 'markAllRead';
  static const noNotifications = 'noNotifications';
  static const allCaughtUp = 'allCaughtUp';

  // ---- Errors ---------------------------------------------------------------
  static const error = 'error';
  static const errorGeneric = 'errorGeneric';
  static const errorNetwork = 'errorNetwork';
  static const errorAuth = 'errorAuth';
  static const errorNotFound = 'errorNotFound';
  static const errorPermission = 'errorPermission';
  static const errorLocationDenied = 'errorLocationDenied';
  static const errorScooterUnavailable = 'errorScooterUnavailable';
  static const errorInsufficientBalance = 'errorInsufficientBalance';
}

/// English translations — the canonical source.
const Map<String, String> _en = <String, String>{
  // Common
  L10n.appName: 'Virent',
  L10n.ok: 'OK',
  L10n.cancel: 'Cancel',
  L10n.confirm: 'Confirm',
  L10n.save: 'Save',
  L10n.delete: 'Delete',
  L10n.retry: 'Retry',
  L10n.loading: 'Loading...',
  L10n.seeAll: 'See All',
  L10n.guest: 'Guest',
  L10n.account: 'Account',
  L10n.logout: 'Logout',
  L10n.back: 'Back',
  L10n.next: 'Next',
  L10n.skip: 'Skip',
  L10n.search: 'Search',

  // Auth
  L10n.phoneNumber: 'Phone Number',
  L10n.enterOtp: 'Enter OTP',
  L10n.verifyOtp: 'Verify OTP',
  L10n.resendOtp: 'Resend OTP',
  L10n.otpSentTo: 'OTP sent to',
  L10n.resendIn: 'Resend in',
  L10n.seconds: 'seconds',
  L10n.login: 'Login',
  L10n.signup: 'Sign Up',
  L10n.welcomeBack: 'Welcome back',

  // Rides
  L10n.findNearby: 'Find Nearby Scooters',
  L10n.scanQr: 'Scan QR Code',
  L10n.startRide: 'Start Ride',
  L10n.endRide: 'End Ride',
  L10n.pauseRide: 'Pause Ride',
  L10n.resumeRide: 'Resume Ride',
  L10n.searching: 'Searching for Scooters',
  L10n.rideInProgress: 'Ride in Progress',
  L10n.rideEnded: 'Ride Ended',
  L10n.rideEndedSuccessfully: 'Your ride has been ended successfully.',
  L10n.failedToEndRide: 'Failed to end ride',
  L10n.noActiveRide: 'No Active Rides',
  L10n.noActiveRideHint: 'Scan a scooter to start riding',
  L10n.timeElapsed: 'Time Elapsed',
  L10n.duration: 'Duration',
  L10n.distance: 'Distance',
  L10n.cost: 'Cost',
  L10n.estimatedCost: 'Estimated cost',
  L10n.ratePerMin: 'UZS / min',
  L10n.batteryLevel: 'Battery Level',
  L10n.lastStation: 'Last Station',
  L10n.scooterStatus: 'Status',
  L10n.scooterId: 'Scooter ID',
  L10n.firmwareVersion: 'Firmware',
  L10n.currentSpeed: 'Speed',
  L10n.riding: 'Riding',
  L10n.sos: 'Emergency SOS',

  // Wallet
  L10n.wallet: 'Wallet',
  L10n.addMoney: 'Add Money',
  L10n.transactions: 'Transactions',
  L10n.balance: 'Balance',
  L10n.topUp: 'Top Up',
  L10n.paymentMethods: 'Payment Methods',
  L10n.addPaymentMethod: 'Add New Payment Method',
  L10n.transactionHistory: 'Transaction History',

  // Profile
  L10n.profile: 'Profile',
  L10n.editProfile: 'Edit Profile',
  L10n.firstName: 'First Name',
  L10n.lastName: 'Last Name',
  L10n.email: 'Email',
  L10n.gender: 'Gender',
  L10n.verifyIdentity: 'Verify Identity',

  // Settings
  L10n.settings: 'Settings',
  L10n.language: 'Language',
  L10n.appearance: 'Appearance',
  L10n.darkMode: 'Dark Mode',
  L10n.lightMode: 'Light Mode',
  L10n.systemMode: 'System',
  L10n.langAndRegion: 'Language and Region',
  L10n.notifications: 'Notifications',
  L10n.pushNotifications: 'Push Notifications',
  L10n.emailNotifications: 'Email Notifications',
  L10n.about: 'About',
  L10n.appVersion: 'App Version',
  L10n.privacyPolicy: 'Privacy Policy',
  L10n.termsOfService: 'Terms of Service',
  L10n.helpAndSupport: 'Help & Support',
  L10n.serverUrl: 'Server URL',
  L10n.adminMode: 'Admin Mode',

  // Admin
  L10n.adminDashboard: 'Dashboard',
  L10n.adminSmsGateway: 'SMS Gateway',
  L10n.adminZones: 'Zones',
  L10n.adminIot: 'IoT Devices',
  L10n.adminCustomers: 'Customers',
  L10n.adminAuditLog: 'Audit Log',
  L10n.adminAnalytics: 'Analytics',
  L10n.totalTrips: 'Total Trips',
  L10n.totalRevenue: 'Total Revenue',
  L10n.activeScooters: 'Active Scooters',
  L10n.totalCustomers: 'Total Customers',

  // Ride history
  L10n.rideHistory: 'Ride History',
  L10n.totalTime: 'Total Time',
  L10n.totalSpent: 'Total Spent',
  L10n.filterBy: 'Filter by',
  L10n.completed: 'Completed',
  L10n.cancelled: 'Cancelled',
  L10n.ongoing: 'Ongoing',

  // Notifications
  L10n.all: 'All',
  L10n.unread: 'Unread',
  L10n.trip: 'Trip',
  L10n.promo: 'Promo',
  L10n.markAllRead: 'Mark all read',
  L10n.noNotifications: 'No notifications yet',
  L10n.allCaughtUp: 'You are all caught up',

  // Errors
  L10n.error: 'Error',
  L10n.errorGeneric: 'Something went wrong. Please try again.',
  L10n.errorNetwork: 'No internet connection. Please check your network.',
  L10n.errorAuth: 'Authentication failed. Please log in again.',
  L10n.errorNotFound: 'The requested resource was not found.',
  L10n.errorPermission: 'Permission denied. Please grant the required access.',
  L10n.errorLocationDenied: 'Location permission denied. Enable it in settings.',
  L10n.errorScooterUnavailable: 'This scooter is unavailable right now.',
  L10n.errorInsufficientBalance: 'Insufficient balance. Please top up your wallet.',
};

/// Russian translations.
const Map<String, String> _ru = <String, String>{
  // Common
  L10n.appName: 'Virent',
  L10n.ok: 'ОК',
  L10n.cancel: 'Отмена',
  L10n.confirm: 'Подтвердить',
  L10n.save: 'Сохранить',
  L10n.delete: 'Удалить',
  L10n.retry: 'Повторить',
  L10n.loading: 'Загрузка...',
  L10n.seeAll: 'Показать все',
  L10n.guest: 'Гость',
  L10n.account: 'Аккаунт',
  L10n.logout: 'Выйти',
  L10n.back: 'Назад',
  L10n.next: 'Далее',
  L10n.skip: 'Пропустить',
  L10n.search: 'Поиск',

  // Auth
  L10n.phoneNumber: 'Номер телефона',
  L10n.enterOtp: 'Введите код',
  L10n.verifyOtp: 'Подтвердить код',
  L10n.resendOtp: 'Отправить снова',
  L10n.otpSentTo: 'Код отправлен на',
  L10n.resendIn: 'Отправить через',
  L10n.seconds: 'сек',
  L10n.login: 'Войти',
  L10n.signup: 'Регистрация',
  L10n.welcomeBack: 'С возвращением',

  // Rides
  L10n.findNearby: 'Найти самокаты рядом',
  L10n.scanQr: 'Сканировать QR-код',
  L10n.startRide: 'Начать поездку',
  L10n.endRide: 'Завершить поездку',
  L10n.pauseRide: 'Пауза',
  L10n.resumeRide: 'Продолжить',
  L10n.searching: 'Поиск самокатов',
  L10n.rideInProgress: 'Поездка идёт',
  L10n.rideEnded: 'Поездка завершена',
  L10n.rideEndedSuccessfully: 'Ваша поездка успешно завершена.',
  L10n.failedToEndRide: 'Не удалось завершить поездку',
  L10n.noActiveRide: 'Нет активных поездок',
  L10n.noActiveRideHint: 'Сканируйте самокат, чтобы начать',
  L10n.timeElapsed: 'Прошло времени',
  L10n.duration: 'Длительность',
  L10n.distance: 'Расстояние',
  L10n.cost: 'Стоимость',
  L10n.estimatedCost: 'Ориентировочно',
  L10n.ratePerMin: 'сум/мин',
  L10n.batteryLevel: 'Заряд батареи',
  L10n.lastStation: 'Последняя станция',
  L10n.scooterStatus: 'Статус',
  L10n.scooterId: 'ID самоката',
  L10n.firmwareVersion: 'Прошивка',
  L10n.currentSpeed: 'Скорость',
  L10n.riding: 'В пути',
  L10n.sos: 'Экстренный SOS',

  // Wallet
  L10n.wallet: 'Кошелёк',
  L10n.addMoney: 'Пополнить',
  L10n.transactions: 'Транзакции',
  L10n.balance: 'Баланс',
  L10n.topUp: 'Пополнение',
  L10n.paymentMethods: 'Способы оплаты',
  L10n.addPaymentMethod: 'Добавить способ оплаты',
  L10n.transactionHistory: 'История транзакций',

  // Profile
  L10n.profile: 'Профиль',
  L10n.editProfile: 'Редактировать профиль',
  L10n.firstName: 'Имя',
  L10n.lastName: 'Фамилия',
  L10n.email: 'Эл. почта',
  L10n.gender: 'Пол',
  L10n.verifyIdentity: 'Подтвердить личность',

  // Settings
  L10n.settings: 'Настройки',
  L10n.language: 'Язык',
  L10n.appearance: 'Оформление',
  L10n.darkMode: 'Тёмная тема',
  L10n.lightMode: 'Светлая тема',
  L10n.systemMode: 'Системная',
  L10n.langAndRegion: 'Язык и регион',
  L10n.notifications: 'Уведомления',
  L10n.pushNotifications: 'Push-уведомления',
  L10n.emailNotifications: 'Email-уведомления',
  L10n.about: 'О приложении',
  L10n.appVersion: 'Версия приложения',
  L10n.privacyPolicy: 'Политика конфиденциальности',
  L10n.termsOfService: 'Условия использования',
  L10n.helpAndSupport: 'Помощь и поддержка',
  L10n.serverUrl: 'Адрес сервера',
  L10n.adminMode: 'Режим администратора',

  // Admin
  L10n.adminDashboard: 'Панель',
  L10n.adminSmsGateway: 'SMS-шлюз',
  L10n.adminZones: 'Зоны',
  L10n.adminIot: 'IoT-устройства',
  L10n.adminCustomers: 'Клиенты',
  L10n.adminAuditLog: 'Журнал аудита',
  L10n.adminAnalytics: 'Аналитика',
  L10n.totalTrips: 'Всего поездок',
  L10n.totalRevenue: 'Общая выручка',
  L10n.activeScooters: 'Активные самокаты',
  L10n.totalCustomers: 'Всего клиентов',

  // Ride history
  L10n.rideHistory: 'История поездок',
  L10n.totalTime: 'Общее время',
  L10n.totalSpent: 'Всего потрачено',
  L10n.filterBy: 'Фильтр',
  L10n.completed: 'Завершено',
  L10n.cancelled: 'Отменено',
  L10n.ongoing: 'Активна',

  // Notifications
  L10n.all: 'Все',
  L10n.unread: 'Непрочитанные',
  L10n.trip: 'Поездка',
  L10n.promo: 'Акции',
  L10n.markAllRead: 'Отметить все прочитанными',
  L10n.noNotifications: 'Уведомлений пока нет',
  L10n.allCaughtUp: 'Всё прочитано',

  // Errors
  L10n.error: 'Ошибка',
  L10n.errorGeneric: 'Что-то пошло не так. Попробуйте снова.',
  L10n.errorNetwork: 'Нет интернета. Проверьте подключение.',
  L10n.errorAuth: 'Ошибка авторизации. Войдите снова.',
  L10n.errorNotFound: 'Запрошенный ресурс не найден.',
  L10n.errorPermission: 'Доступ запрещён. Предоставьте разрешения.',
  L10n.errorLocationDenied: 'Геолокация отключена. Включите в настройках.',
  L10n.errorScooterUnavailable: 'Этот самокат сейчас недоступен.',
  L10n.errorInsufficientBalance: 'Недостаточно средств. Пополните кошелёк.',
};

/// Uzbek translations.
const Map<String, String> _uz = <String, String>{
  // Common
  L10n.appName: 'Virent',
  L10n.ok: 'OK',
  L10n.cancel: 'Bekor qilish',
  L10n.confirm: 'Tasdiqlash',
  L10n.save: 'Saqlash',
  L10n.delete: 'O‘chirish',
  L10n.retry: 'Qayta urinish',
  L10n.loading: 'Yuklanmoqda...',
  L10n.seeAll: 'Barchasini ko‘rish',
  L10n.guest: 'Mehmon',
  L10n.account: 'Hisob',
  L10n.logout: 'Chiqish',
  L10n.back: 'Orqaga',
  L10n.next: 'Keyingi',
  L10n.skip: 'O‘tkazib yuborish',
  L10n.search: 'Qidirish',

  // Auth
  L10n.phoneNumber: 'Telefon raqami',
  L10n.enterOtp: 'Kodni kiriting',
  L10n.verifyOtp: 'Kodni tasdiqlash',
  L10n.resendOtp: 'Kodni qayta yuborish',
  L10n.otpSentTo: 'Kod yuborildi:',
  L10n.resendIn: 'Qayta yuborish',
  L10n.seconds: 'soniya',
  L10n.login: 'Kirish',
  L10n.signup: "Ro'yxatdan o'tish",
  L10n.welcomeBack: 'Xush kelibsiz',

  // Rides
  L10n.findNearby: 'Yaqin atrofdagi samokatlar',
  L10n.scanQr: 'QR-kodni skanerlash',
  L10n.startRide: 'Sayohatni boshlash',
  L10n.endRide: 'Sayohatni tugatish',
  L10n.pauseRide: 'Pauza',
  L10n.resumeRide: 'Davom ettirish',
  L10n.searching: 'Samokatlar qidirilmoqda',
  L10n.rideInProgress: 'Sayohat davom etmoqda',
  L10n.rideEnded: 'Sayohat tugadi',
  L10n.rideEndedSuccessfully: 'Sayohatingiz muvaffaqiyatli tugatildi.',
  L10n.failedToEndRide: 'Sayohatni tugatib bo‘lmadi',
  L10n.noActiveRide: 'Faol sayohatlar yo‘q',
  L10n.noActiveRideHint: 'Boshlash uchun samokatni skanerlang',
  L10n.timeElapsed: 'O‘tgan vaqt',
  L10n.duration: 'Davomiyligi',
  L10n.distance: 'Masofa',
  L10n.cost: 'Narx',
  L10n.estimatedCost: 'Taxminiy narx',
  L10n.ratePerMin: "so'm/min",
  L10n.batteryLevel: 'Batareya darajasi',
  L10n.lastStation: 'Oxirgi stansiya',
  L10n.scooterStatus: 'Holat',
  L10n.scooterId: 'Samokat ID si',
  L10n.firmwareVersion: 'Proshivka',
  L10n.currentSpeed: 'Tezlik',
  L10n.riding: 'Yo‘lda',
  L10n.sos: 'Favqulodda SOS',

  // Wallet
  L10n.wallet: "Hamyon",
  L10n.addMoney: 'Pul qo‘shish',
  L10n.transactions: 'Operatsiyalar',
  L10n.balance: 'Balans',
  L10n.topUp: "To'ldirish",
  L10n.paymentMethods: "To'lov usullari",
  L10n.addPaymentMethod: "Yangi to'lov usulini qo'shish",
  L10n.transactionHistory: 'Operatsiyalar tarixi',

  // Profile
  L10n.profile: 'Profil',
  L10n.editProfile: 'Profilni tahrirlash',
  L10n.firstName: 'Ism',
  L10n.lastName: 'Familiya',
  L10n.email: 'Email',
  L10n.gender: 'Jins',
  L10n.verifyIdentity: 'Shaxsni tasdiqlash',

  // Settings
  L10n.settings: 'Sozlamalar',
  L10n.language: 'Til',
  L10n.appearance: 'Ko‘rinish',
  L10n.darkMode: 'Qorong‘i rejim',
  L10n.lightMode: 'Yorug‘ rejim',
  L10n.systemMode: 'Tizim',
  L10n.langAndRegion: 'Til va mintaqa',
  L10n.notifications: 'Bildirishnomalar',
  L10n.pushNotifications: 'Push-bildirishnomalar',
  L10n.emailNotifications: 'Email-bildirishnomalar',
  L10n.about: 'Dastur haqida',
  L10n.appVersion: 'Versiya',
  L10n.privacyPolicy: 'Maxfiylik siyosati',
  L10n.termsOfService: 'Foydalanish shartlari',
  L10n.helpAndSupport: 'Yordam va qo‘llab-quvvatlash',
  L10n.serverUrl: 'Server manzili',
  L10n.adminMode: 'Administrator rejimi',

  // Admin
  L10n.adminDashboard: 'Boshqaruv paneli',
  L10n.adminSmsGateway: 'SMS-shlyuz',
  L10n.adminZones: 'Zonalar',
  L10n.adminIot: 'IoT-qurilmalar',
  L10n.adminCustomers: 'Mijozlar',
  L10n.adminAuditLog: 'Audit jurnali',
  L10n.adminAnalytics: 'Analitika',
  L10n.totalTrips: "Jami sayohatlar",
  L10n.totalRevenue: "Jami daromad",
  L10n.activeScooters: 'Faol samokatlar',
  L10n.totalCustomers: 'Jami mijozlar',

  // Ride history
  L10n.rideHistory: 'Sayohatlar tarixi',
  L10n.totalTime: "Umumiy vaqt",
  L10n.totalSpent: "Jami sarflandi",
  L10n.filterBy: 'Filtrlash',
  L10n.completed: 'Yakunlandi',
  L10n.cancelled: 'Bekor qilindi',
  L10n.ongoing: 'Faol',

  // Notifications
  L10n.all: 'Barchasi',
  L10n.unread: "O'qilmagan",
  L10n.trip: 'Sayohat',
  L10n.promo: 'Aksiyalar',
  L10n.markAllRead: "Hammasini o'qilgan deb belgilash",
  L10n.noNotifications: 'Hozircha bildirishnomalar yo‘q',
  L10n.allCaughtUp: "Hammasi o'qildi",

  // Errors
  L10n.error: 'Xato',
  L10n.errorGeneric: 'Bir narsa noto‘g‘ri bajarildi. Qayta urinib ko‘ring.',
  L10n.errorNetwork: 'Internet yo‘q. Ulanishni tekshiring.',
  L10n.errorAuth: 'Avtorizatsiya xatosi. Qaytadan kiring.',
  L10n.errorNotFound: 'So‘ralgan resurs topilmadi.',
  L10n.errorPermission: 'Ruxsat berilmadi. Kerakli ruxsatlarni bering.',
  L10n.errorLocationDenied: 'Geolokatsiya o‘chirilgan. Sozlamalarda yoqing.',
  L10n.errorScooterUnavailable: 'Bu samokat hozir mavjud emas.',
  L10n.errorInsufficientBalance: "Balans yetarli emas. Hamyonni to'ldiring.",
};

/// Per-language catalogue.
const Map<String, Map<String, String>> _catalogues = <String, Map<String, String>>{
  'en': _en,
  'ru': _ru,
  'uz': _uz,
};

/// Hand-rolled [LocalizationsDelegate] for [AppLocalizations].
///
/// Constructed once and passed to `MaterialApp.localizationsDelegates`.
class AppLocalizations {
  /// Creates an [AppLocalizations] bound to [locale].
  const AppLocalizations(this.locale);

  /// Active locale. The catalogue is resolved from [locale.languageCode].
  final Locale locale;

  /// The [LocalizationsDelegate] used by `MaterialApp`.
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Lookup helper used by tests that construct an [AppLocalizations]
  /// directly (without a `Localizations` ancestor).
  static AppLocalizations of(Locale locale) => AppLocalizations(locale);

  /// Returns the translated string for [key], falling back to English
  /// and finally to [key] itself when neither the active language nor
  /// English has a value.
  String t(String key) {
    final lang = _catalogues[locale.languageCode] ?? _en;
    return lang[key] ?? _en[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      LocaleData.isSupported(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Riverpod provider exposing the active [AppLocalizations].
///
/// Reads the current locale from [localeProvider] and returns a fresh
/// [AppLocalizations] instance whenever the locale changes.
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale);
});
