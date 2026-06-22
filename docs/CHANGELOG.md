# API Changelog

All notable changes to the Virent API.

## [1.1.0] — 2026-06-18

### Architecture change — stack consolidation
The Virent stack now ships as **four components only**:

| Component | Role |
|-----------|------|
| iOS app | End-user client |
| Android app | End-user client |
| **Windows desktop app** | Server installer + **all admin functions** |
| REST API | Backend for all clients |

**Removed:**
- `frontend/admin-dashboard` — superseded by the Windows desktop app (every admin function ported 1:1)
- `frontend/webb-client` — superseded by the iOS + Android apps

**Why:** with the admin and webb websites gone, only **two** places can produce runtime errors — the Windows app and the REST API. This dramatically narrows the search space when something goes wrong.

### Windows desktop app — admin functions ported 1:1
- New sidebar with 16 tabs (Dashboard, Server, Scooters, Trips, Customers, Cities, Zones, Map, Analytics, AuditLog, Prepaid, Juicers, IoT, Support, Settings, Logs)
- Each admin tab uses a native Win32 ListView (report mode, full-row select, double buffer, gridlines)
- Per-tab search box that filters rows client-side on every keystroke
- Per-tab Refresh / Add New / Export CSV action buttons
- Built-in `JsonValue` parser (no third-party JSON library needed)
- API client extended with wrappers for: `/trips`, `/users`, `/cities/overview`, `/audit-log`, `/prepaids`, `/juicers`, `/support/admin/list`, `/stats`, `/iot/command/send`
- Data cached per tab for 30 s (manual Refresh forces re-fetch)
- Dashboard URL panel updated — only REST API + iOS + Android endpoints now shown

## [1.0.0] — 2026-06-17

### Added
- **Auth**: email/password login, phone+SMS OTP login (auto-register), Google OAuth, refresh tokens (30d) with rotation, forgot/reset password, change password, accept terms, logout-all, 2FA TOTP (RFC 6238), session listing
- **Trips**: reserve (10min TTL) → start → end → cancel → refund, cost calculation with zone-based pricing, fare estimator, auto-expire stale reservations, auto-flag long trips
- **View API (BFF)**: dashboard aggregation (3 sections, cached), trip-detail aggregation (4 sections, cross-section deps)
- **Discovery**: nearest scooters (haversine), available in city, QR code resolver
- **Payments**: Click + Payme initialization + webhooks with signature verification, transaction history, admin balance adjustment
- **Support**: tickets (breakdown/billing/account/other), messages, admin reply, auto-scooter-maintenance on breakdown
- **Promocodes**: 6 types (first_ride, any_ride, free_minutes, cashback, referral_inviter, referral_invitee), per-user limits, referral auto-generation
- **Notifications**: push (FCM/APNs/web), device registration, broadcast, SMS (Eskiz/PlayMobile), email (5 templates)
- **Juicers**: register, available tasks, claim → pickup → charge → return + payment
- **Mechanics**: register, assign, start → complete/escalate, parts inventory, restock
- **Geofencing**: real-time zone detection, speed limits (10km/h parking, 25km/h street), auto-violation notifications (cron)
- **IoT**: ESP32 telemetry, events (lock/unlock/low_battery/alarm/fall), command polling
- **Admin**: stats overview, revenue/trips time series, fleet utilization, audit log, full-text search, CSV export (trips/transactions/users/scooters)
- **System**: health check, Prometheus metrics, system info
- **WebSocket**: real-time updates (admin:dashboard, admin:trips, admin:scooters, user:<id>, public:announcements)
- **Security**: Helmet, compression, 4 rate limiters (global/auth/OTP/mutation), per-user rate limiting, idempotency keys, input validation, MongoDB sanitize, bcrypt, JWT, audit log (append-only, TTL 1yr)
- **DB**: 28 indexes (TTL + performance), access patterns documented (YAML), cursor pagination, resource budgets
- **Auto-maintenance**: cron job auto-schedules maintenance based on mileage/cycles/battery health

### Architecture
- Modular Monolith + Clean Architecture (17 domain modules)
- Request Tree executor for View API (parallel execution, caching, partial responses)
- WebSocket server with JWT auth and channel-based pub/sub
- Design System v2.0 (Frontend + Backend + Database)
- i18n (RU/UZ/EN)

### Tests
- 75 tests (unit + integration + contract)
- Trip entity (13), Auth entity (15), Scooter entity (11), Validation (21), Controller contract (9), TOTP (6), Repository integration (9)
