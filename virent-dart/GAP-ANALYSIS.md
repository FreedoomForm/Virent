# Gap Analysis — Virent Dart vs BarqScoot vs Old Stack

## BarqScoot features we're missing (126 files → we have 10)

### Critical (must have for MVP):
1. **Auth flow** — phone input → OTP send → OTP verify (pinput widget)
2. **Active ride screen** — timer, live map, end ride button, scooter info card
3. **QR scanner** — camera overlay, torch toggle, manual entry fallback
4. **Welcome/onboarding** — first-run screen
5. **Theme toggle** — dark/light persisted to SharedPreferences

### Important:
6. **Ride history with stats** — total trips, total spent, cards
7. **Ride payment screen** — cost breakdown after ride ends
8. **Wallet** — balance card + payment methods (Click/Payme)
9. **Profile** — user provider with stats
10. **Drawer** — hamburger menu with navigation
11. **Notifications** — modal with filter tabs
12. **Search modal** — search for scooters
13. **Location permission handler** — request GPS permission
14. **Promo code** — validate and apply

### Nice to have:
15. **i18n** — multi-language (en/ar)
16. **Loading dialog** — reusable spinner
17. **Error views** — standardized error display

## Old stack features we haven't ported to Dart

### Admin (was in C++ desktop / web-ui):
1. **Zone editor** — interactive polygon drawing on map
2. **Customer block/unblock** — with reason + audit log
3. **Trip refund** — with reason, can't exceed cost
4. **Bulk prepaid generator** — N cards with prefix/amount/expiry
5. **Push notification composer** — segment targeting
6. **Scooter detail** — telemetry + command history
7. **Audit log** — filtered by actor/action/entity/date
8. **Analytics** — revenue + utilization bar charts
9. **IoT command center** — lock/unlock/alarm/reboot buttons
10. **APK download** — progress bar, GitHub Releases
11. **Docker management** — start/stop/restart containers
12. **Server tab** — container status, DB backup/restore

### Backend (was in Node.js):
13. **User block/unblock endpoints**
14. **Balance adjustment**
15. **Trip refund**
16. **Bulk prepaid**
17. **Notification send + stats**
18. **Scooter retire**
19. **Scooter telemetry/commands**
20. **Support ticket close/reopen/assign**
21. **Audit log filters**
22. **IoT command queue** (POST /iot/command/send, GET /iot/command)
23. **Scooter telemetry** (POST /iot/telemetry, POST /iot/event)

## New features requested

1. **Global server** — deploy to cloud VPS, not just local
2. **Admin SMS gateway** — admin phone sends OTP via SIM card
   - Admin selects SIM card (dual-SIM support)
   - Regular user registration triggers SMS from admin's phone
   - Uses Android SmsManager API
