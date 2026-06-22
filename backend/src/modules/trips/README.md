# Trips Module

## Domain
The Trip entity represents a single scooter rental session, from reservation through
active ride to completion (or cancellation/expiration).

## Lifecycle
```
reserved → active → ended
   ↓        ↓
cancelled  cancelled
   ↓
expired (auto, after 10 min)
```

## API endpoints
- `POST /v1/trips-v2:reserve` — reserve a scooter for 10 minutes
- `POST /v1/trips-v2:start` — start active ride from reservation
- `POST /v1/trips-v2:end` — end ride, calculate cost, deduct balance
- `POST /v1/trips-v2:cancel` — cancel reservation or active trip
- `GET /v1/trips-v2/active` — get user's current active/reserved trip
- `GET /v1/trips-v2/history` — paginated trip history (cursor-based)
- `GET /v1/trips-v2` (admin) — list all trips with filters
- `POST /v1/trips-v2:refund` (admin) — refund a trip

## Architecture (per Backend Design System v1.0)
```
api/                  — HTTP layer (controllers, routes)
  trip.controller.js  — request validation, response formatting
  trip.routes.js      — route definitions with auth middleware
application/          — use case orchestration
  trip.service.js     — reserveScooter, startTrip, endTrip, etc.
domain/               — business rules (no HTTP, no DB)
  trip.entity.js      — Trip class, TRIP_STATUSES, TRIP_TRANSITIONS,
                        calculateCost() pure function
infrastructure/       — DB access
  trip.repository.js  — MongoDB queries, no business logic
contracts/            — DTOs
  trip.dto.js         — toListItem, toDetail, toAdminDetail, toSummary
```

## Access patterns (per Database Design System v1.0)
- `trips.getById` — pk_trips_id, D0, p95 30ms
- `trips.getActiveByUser` — idx_trips_user_status, D0, p95 30ms, cache 5s
- `trips.listByUser` — idx_trips_user_created, D1, p95 80ms, cursor pagination
- `trips.listAll` — idx_trips_status_created, D3 (admin), p95 150ms
- `trips.findStaleReservations` — idx_trips_status_reservation_expires, cron
- `trips.findLongActive` — idx_trips_active_start, cron

## Resource budgets
- Reserve: P95 200ms, max 3 DB queries
- Start: P95 200ms, max 3 DB queries
- End: P95 400ms, max 6 DB queries (includes transaction + push notif)
- Cancel: P95 200ms, max 2 DB queries
- History list: P95 80ms, max 2 DB queries (list + count)

## Events published (via outbox)
- `trip.reserved` — scooter marked as reserved
- `trip.started` — ride started
- `trip.ended` — ride ended, payment captured
- `trip.cancelled` — user/system cancelled
- `trip.expired` — reservation expired (cron)

## Dependencies
- scooters module (repository for status updates)
- cities module (repository for tariff lookup)
- users module (repository for balance update)
- transactions module (repository for payment record)
- notifications module (for low-battery / zone-violation alerts)

## Permissions
- `trip.readOwn` — user can read their own trip
- `trip.cancelOwn` — user can cancel their own trip
- `trip.endOwn` — user can end their own trip
- `admin.refundTrip` — admin can refund any trip

## Tests
- `tests/trip.entity.test.js` — domain rules (calculateCost, transitions)
- `tests/trip.service.test.js` — use case integration
- `tests/trip.controller.test.js` — HTTP contract tests
- `tests/trip.repository.test.js` — DB integration
