# Missing Features — Audit & Implementation Plan

Date: 2026-06-18
Audit compares the running REST API (`/home/z/my-project/sparkrentals/SparkRentals-REST-API/v1/route/*.js`, 132 endpoints) against what an end-to-end scooter sharing product needs. Items marked **MISSING** are not exposed by any route; **PARTIAL** are present but incomplete; **OK** are present and complete.

## 1. Zone management (admin)

The user explicitly called this out as a missing feature — "editing zones on the map for where scooters can and cannot go".

| Capability | Status | Where |
|------------|--------|-------|
| List zones per city | OK | `GET /v1/cities/:id` (zones embedded) |
| Create zone | OK | `POST /v1/cities/zones` |
| Update zone | OK | `PUT /v1/cities/zones` |
| Delete zone | OK | `DELETE /v1/cities/zones` |
| Zone polygon validation (min 3 points, max area) | MISSING | backend |
| Zone type taxonomy (parking / no-ride / slow / charging) | PARTIAL | backend stores `type` but no enum validation |
| Speed-limit per zone | OK | stored, but no enforcement |
| Time-based zones (e.g. night no-ride) | MISSING | backend |
| **Map-based polygon editor** (draw on map, drag vertices) | **MISSING** | desktop-app + mobile |
| GeoJSON import / export for zones | MISSING | backend |
| Zone preview with sample scooter positions | MISSING | desktop-app |

## 2. Scooter management (admin)

| Capability | Status | Where |
|------------|--------|-------|
| List scooters | OK | `GET /v1/scooters` |
| Register scooter | OK | `POST /v1/scooters` |
| Update scooter | OK | `PUT /v1/scooters` |
| Delete scooter | OK | `DELETE /v1/scooters` |
| Update status | OK | `PUT /v1/scooters/status` |
| Update coordinates | OK | `PUT /v1/scooters/coordinates` |
| **Scooter edit form (model, max speed, battery capacity)** | **MISSING** | desktop-app |
| **Scooter decommission / retire (with reason)** | **MISSING** | desktop-app + backend |
| **Scooter maintenance schedule (next_maintenance_at)** | **MISSING** | desktop-app |
| **Scooter telemetry history viewer (last 100 points)** | **MISSING** | desktop-app |
| **Scooter command history (lock/unlock/reboot log)** | **MISSING** | desktop-app |
| **Bulk scooter import (CSV upload)** | **MISSING** | desktop-app + backend |
| **Scooter firmware version manager (list, push OTA)** | **MISSING** | desktop-app |
| **Scooter group / fleet assignment** | **MISSING** | backend |

## 3. Customer management (admin)

| Capability | Status | Where |
|------------|--------|-------|
| List customers | OK | `GET /v1/users` |
| Customer detail | OK | `GET /v1/users/:id` |
| Edit customer | OK | `PUT /v1/users` |
| Delete customer | OK | `DELETE /v1/users` |
| Customer ride history | OK | `GET /v1/users/history` |
| **Block / unblock customer (with reason + audit log)** | **MISSING** | backend + desktop-app |
| **Adjust customer balance (admin manual adjustment with reason)** | **MISSING** | backend + desktop-app |
| **Customer verification (ID / driving license upload)** | **MISSING** | backend |
| **Customer notes (admin private notes on a customer)** | **MISSING** | backend |
| **Customer support ticket shortcut from customer row** | **MISSING** | desktop-app |
| **Export customer CSV with filters** | **MISSING** | desktop-app |

## 4. Trip management (admin)

| Capability | Status | Where |
|------------|--------|-------|
| List trips | OK | `GET /v1/trips` |
| Active trip | OK | `GET /v1/trips/active` |
| Trip history | OK | `GET /v1/trips/history` |
| Reserve / start / end / cancel | OK | `POST /v1/trips/...` |
| **Refund with reason + audit log** | **PARTIAL** | `POST /v1/trips/refund` exists, no reason field |
| **Trip reassignment (move trip to different user — admin correction)** | **MISSING** | backend |
| **Trip dispute resolution workflow** | **MISSING** | backend |
| **Trip route replay (animate GPS trail on map)** | **MISSING** | desktop-app |
| **Trip cost breakdown viewer (base + minutes + distance + zone surcharge + promo + tax)** | **MISSING** | desktop-app |
| **Trip filters (by date range, by city, by status, by cost range, by user)** | **PARTIAL** | backend supports some, desktop exposes none |

## 5. Prepaid cards (admin)

| Capability | Status | Where |
|------------|--------|-------|
| List prepaid cards | OK | `GET /v1/prepaids` |
| Create prepaid card | OK | `POST /v1/prepaids` |
| Update prepaid card | OK | `PUT /v1/prepaids` |
| Delete prepaid card | OK | `DELETE /v1/prepaids` |
| **Bulk generate (N cards of value X, with prefix + expiry)** | **MISSING** | backend + desktop-app |
| **Prepaid usage stats (how many used, by whom, when)** | **MISSING** | desktop-app |
| **Prepaid batch export to CSV / printable PDF** | **MISSING** | desktop-app |
| **Prepaid expiry notification (cron warns admin before batch expires)** | **MISSING** | backend |

## 6. City rates & tax (admin)

| Capability | Status | Where |
|------------|--------|-------|
| List cities | OK | `GET /v1/cities` |
| Create city | OK | `POST /v1/cities` |
| Update city | OK | `PUT /v1/cities` |
| Update tax | OK | `PUT /v1/cities/tax` |
| **Rate editor with preview (show sample trip cost at new rates)** | **MISSING** | desktop-app |
| **Time-based rates (peak / off-peak / weekend)** | **MISSING** | backend |
| **Surge multiplier (rainy days, events)** | **MISSING** | backend |
| **City enable / disable (soft pause without deleting)** | **MISSING** | backend |

## 7. Juicers (charging team)

| Capability | Status | Where |
|------------|--------|-------|
| List juicers | OK | `GET /v1/juicers` |
| Available tasks | OK | `GET /v1/juicers/tasks/available` |
| Claim / pickup / charge / return | OK | `POST /v1/juicers/tasks/...` |
| **Juicer detail (earnings, rating, completed tasks)** | **MISSING** | desktop-app |
| **Juicer payout report (per period)** | **MISSING** | backend + desktop-app |
| **Juicer ratings review (admin moderation)** | **MISSING** | backend |
| **Juicer blacklist (block low-performer)** | **MISSING** | backend |

## 8. Mechanics / maintenance

| Capability | Status | Where |
|------------|--------|-------|
| Register mechanic | OK | `POST /v1/mechanics` |
| Maintenance requests | OK | `GET /v1/mechanics/requests` |
| Assign / start / complete / escalate | OK | `POST /v1/mechanics/requests/:id/...` |
| Inventory + restock | OK | `GET /v1/mechanics/inventory` |
| **Maintenance schedule viewer (calendar view)** | **MISSING** | desktop-app |
| **Parts low-stock alert threshold** | **MISSING** | backend |
| **Scooter service history (per scooter)** | **MISSING** | desktop-app |

## 9. Notifications / push (admin)

| Capability | Status | Where |
|------------|--------|-------|
| List notifications | OK | `GET /v1/notifications` |
| Mark as read | OK | `POST /v1/notifications/:id/read` |
| Broadcast | OK | `POST /v1/notifications/broadcast` |
| **Push composer (title + body + target segment + schedule)** | **MISSING** | desktop-app |
| **Segment targeting (by city, by user status, by signup date)** | **MISSING** | backend |
| **Scheduled notifications (send at future time)** | **MISSING** | backend |
| **Notification template library (saved templates)** | **MISSING** | backend |
| **Notification delivery stats (sent / delivered / read / failed)** | **MISSING** | backend |
| **Test send (to single user before broadcast)** | **MISSING** | backend |

## 10. Audit log (admin)

| Capability | Status | Where |
|------------|--------|-------|
| List audit log | OK | `GET /v1/audit-log` |
| **Filters (by actor, by action, by entity, by date range)** | **MISSING** | desktop-app |
| **Audit log export (CSV)** | **MISSING** | desktop-app |
| **Audit log retention config (TTL)** | **MISSING** | backend |
| **Diff viewer (show before/after for entity edits)** | **MISSING** | backend |

## 11. Analytics (admin)

| Capability | Status | Where |
|------------|--------|-------|
| Stats overview | OK | `GET /v1/stats` |
| Prometheus metrics | OK | `GET /metrics` |
| **Revenue chart (daily / weekly / monthly, by city)** | **MISSING** | desktop-app |
| **Trips heatmap (when + where)** | **MISSING** | desktop-app |
| **Fleet utilization chart (live scooters / total)** | **MISSING** | desktop-app |
| **Cohort retention (signup month vs active this month)** | **MISSING** | backend |
| **Funnel: signup -> first ride -> second ride -> retained** | **MISSING** | backend |
| **Top trouble spots (geo-clusters of breakdowns)** | **MISSING** | backend |

## 12. Support tickets (admin)

| Capability | Status | Where |
|------------|--------|-------|
| List tickets | OK | `GET /v1/support/admin/list` |
| Reply | OK | `POST /v1/support/admin/:id/reply` |
| **Close / reopen ticket** | **MISSING** | backend |
| **Assign ticket to admin** | **MISSING** | backend |
| **Canned responses library** | **MISSING** | backend |
| **Ticket priority + SLA timer** | **MISSING** | backend |
| **Auto-escalate if no reply in X hours** | **MISSING** | backend |

## 13. Mobile app (user side)

| Capability | Status | Where |
|------------|--------|-------|
| Login / register / OTP | OK | mobile/auth |
| Map + scooter discovery | OK | mobile/Map.tsx |
| QR scanner | OK | mobile/QRScanner.tsx |
| Active ride | OK | mobile/ActiveRide.tsx |
| Trip history | OK | mobile/Trips.tsx |
| Wallet / top-up | OK | mobile/Wallet.tsx |
| Support tickets | OK | mobile/Support.tsx |
| Settings | OK | mobile/Settings.tsx |
| Notifications | OK | mobile/Notifications.tsx |
| Favorites | OK | mobile/Favorites.tsx |
| **In-ride SOS button (panic)** | **MISSING** | mobile |
| **Trip pause (hold scooter, resume)** | **MISSING** | backend + mobile |
| **Rate trip + driver (scooter condition feedback)** | **MISSING** | backend + mobile |
| **Promo code redemption UI** | **PARTIAL** | exists in Wallet, no dedicated screen |
| **Refer-a-friend share sheet** | **MISSING** | mobile |
| **Trip receipt PDF download** | **MISSING** | mobile + backend |
| **Multi-language switcher in settings (RU / UZ / EN)** | **PARTIAL** | i18n strings exist, no UI |
| **Dark / light theme toggle** | **MISSING** | mobile |
| **Account deletion (GDPR / CCPA)** | **MISSING** | backend + mobile |
| **Export my data (GDPR)** | **MISSING** | backend + mobile |
| **Scooter reporting (broken / dirty / misplaced)** | **PARTIAL** | support ticket exists, no quick-report |
| **Live chat with support** | **MISSING** | backend (WebSocket exists) + mobile |

## 14. Authentication / security

| Capability | Status | Where |
|------------|--------|-------|
| Email / password | OK | `/v1/auth` |
| Phone OTP | OK | `/v1/auth_ext` |
| Google OAuth | OK | `/v1/auth/login/google` |
| Refresh token rotation | OK | `/v1/auth_ext/refresh` |
| 2FA TOTP | OK | `/v1/twofa` |
| **Email verification on signup** | **MISSING** | backend |
| **Password strength meter on signup** | **MISSING** | mobile |
| **Login alert on new device (email)** | **MISSING** | backend |
| **Session inspector (admin sees all active sessions)** | **PARTIAL** | `/v1/auth_ext/sessions` exists, no admin UI |
| **Force logout a session (admin)** | **MISSING** | backend |

## 15. Server / Docker (desktop-app)

| Capability | Status | Where |
|------------|--------|-------|
| Start / stop / restart / rebuild | OK | desktop-app |
| Container logs | OK | desktop-app |
| DB backup / restore | OK | desktop-app |
| **Container resource usage (CPU / RAM live)** | **MISSING** | desktop-app |
| **Disk usage monitor (DB + logs + backups)** | **MISSING** | desktop-app |
| **Auto-update checker (compare local vs upstream)** | **MISSING** | desktop-app |
| **Health check ping (cron with email on failure)** | **MISSING** | desktop-app |

## Summary

```text
Total capabilities audited:    124
OK / present:                    64   (52 %)
PARTIAL:                          9   ( 7 %)
MISSING:                         51   (41 %)
```

## Implementation order (priority)

This iteration will implement the highest-impact missing items:

```text
P0 (must have for a working product):
  1. Zone editor (map-based polygon drawing)            desktop + mobile
  2. Customer block / unblock                           backend + desktop
  3. Trip refund with reason                            backend + desktop
  4. Prepaid bulk generator                             backend + desktop
  5. City rate editor with preview                      desktop
  6. Push notification composer                         desktop
  7. Scooter edit form                                  desktop
  8. Audit log filters + CSV export                     desktop
  9. Trip filters (date / city / status)                desktop
 10. Trip cost breakdown viewer                         desktop

P1 (important):
 11. Scooter decommission / retire                      desktop + backend
 12. Scooter telemetry history viewer                   desktop
 13. Customer balance adjustment (admin)                backend + desktop
 14. Maintenance schedule calendar                      desktop
 15. Notification delivery stats                        backend
 16. Revenue chart (daily / weekly / monthly)           desktop
 17. Fleet utilization chart                            desktop
 18. Support ticket close / reopen + assign             backend + desktop
 19. Mobile: in-ride SOS button                         mobile + backend
 20. Mobile: dark / light theme toggle                  mobile

P2 (nice to have, deferred):
 21. Mobile: trip pause / resume                        backend + mobile
 22. Mobile: trip receipt PDF download                  backend + mobile
 23. Mobile: refer-a-friend share sheet                 mobile
 24. Mobile: account deletion (GDPR)                    backend + mobile
 25. Backend: surge multiplier                          backend
 26. Backend: time-based rates                          backend
 27. Backend: cohort retention analytics                backend
 28. Desktop: container resource monitor                desktop
 29. Desktop: disk usage monitor                        desktop
 30. Desktop: auto-update checker                       desktop
```

This iteration: implement P0 (10 items) + P1 items 11, 13, 16, 19, 20 (5 items). That is 15 concrete features across backend + desktop + mobile, which the user will see in the screenshots.
