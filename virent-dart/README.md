# Virent Dart — Full Flutter Rewrite

> One language (Dart) for everything. Backend embedded in the Windows app.

## Architecture

```
┌──────────────────────────────────────────┐
│     Virent Desktop App (.exe)            │
│                                          │
│  ┌──────────┐    ┌──────────────────┐   │
│  │ Flutter   │    │ Embedded Server  │   │
│  │ UI (admin)│───▶│ shelf :8443      │   │
│  └──────────┘    └────────┬─────────┘   │
│                            │             │
└────────────────────────────┼─────────────┘
                             │
                   ┌─────────┴─────────┐
                   │  WiFi / LAN       │
                   └─────────┬─────────┘
                             │
             ┌───────────────┼───────────────┐
             │               │               │
        ┌────┴────┐   ┌─────┴───┐   ┌──────┴────┐
        │ Android  │   │ iOS     │   │ Browser   │
        │ app      │   │ app     │   │ (admin)   │
        └──────────┘   └─────────┘   └───────────┘
```

The Windows .exe includes both the Flutter UI and the shelf HTTP server
in a single binary. No separate backend to install or start.

Mobile apps connect to `http://<PC_IP>:8443` over WiFi.

## Structure

```
virent-dart/
├── mobile/                        Flutter app (mobile + desktop — same codebase)
│   ├── lib/
│   │   ├── main.dart              Starts embedded server on desktop, skips on mobile
│   │   ├── app_router.dart        go_router navigation
│   │   ├── core/
│   │   │   ├── backend/
│   │   │   │   └── embedded_server.dart    shelf server with all REST endpoints
│   │   │   ├── configs/
│   │   │   │   ├── theme/                  BarqScoot design system
│   │   │   │   │   ├── app_colors.dart     #3489FF primary
│   │   │   │   │   ├── app_theme.dart      Plus Jakarta Sans, light/dark
│   │   │   │   │   └── app_styles.dart     16px radius, card decorations
│   │   │   │   └── services/
│   │   │   │       └── api_client.dart     HTTP client (localhost on desktop, PC IP on mobile)
│   │   │   └── ...
│   │   └── features/
│   │       ├── home/              Map + scooter markers + bottom sheet
│   │       ├── trips/             Trip history
│   │       ├── wallet/            Balance + top-up
│   │       └── profile/           Settings
│   └── pubspec.yaml               shelf + shelf_router + cors_headers (embedded backend deps)
│
├── backend/                       Standalone backend (optional — for reference)
│   └── bin/server.dart            Same code as embedded_server.dart, runs standalone
│
└── README.md
```

## How the embedded server works

1. On desktop (Windows/macOS/Linux):
   - `main.dart` calls `EmbeddedServer.start()` on app launch
   - shelf server listens on `0.0.0.0:8443` (all network interfaces)
   - Flutter UI connects to `localhost:8443` for admin operations
   - Mobile apps on the same WiFi connect to `<PC_IP>:8443`
   - Server stops automatically when the app closes

2. On mobile (iOS/Android):
   - `main.dart` skips server start (detected via `Platform.isWindows`)
   - App connects to the desktop PC's IP address (user-configurable in Settings)
   - Default for Android emulator: `http://10.0.2.2:8443`

## API endpoints (served by embedded server)

```
GET  /health                       — health check
POST /auth/phone/send-code         — send OTP (printed to console log)
POST /auth/phone/verify            — verify OTP, return JWT + user
GET  /scooters/nearby?lat=&lng=    — list nearby scooters with distance
GET  /scooters/:id                 — scooter detail
POST /trips/start                  — start a ride
POST /trips/end                    — end a ride (auto-calculate cost)
GET  /trips                        — trip history
GET  /users/me                     — current user profile
GET  /wallet                       — balance + transactions
POST /wallet/topup                 — top up balance

GET  /admin/stats                  — dashboard stats (scooters/users/trips/revenue)
GET  /admin/scooters               — all scooters for admin view
```

## Build

```bash
# Android APK (client only)
cd virent-dart/mobile
flutter build apk --release

# Windows .exe (server + UI in one binary)
flutter build windows --release

# Standalone backend (optional — for testing without Flutter)
cd virent-dart/backend
dart run bin/server.dart
```

## Design system

Ported from BarqScoot (github.com/RishiAhuja/BarqScoot):
- Primary: #3489FF (teal-blue)
- Light theme by default
- Plus Jakarta Sans (via google_fonts)
- 16px card radius, 12px button radius
- Material Icons only (no emoji)
- Riverpod for state management
- go_router for navigation
