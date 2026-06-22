# SparkRentals Backend — Module Architecture

This document describes the modular monolith architecture per Backend Design System v1.0.

## Structure

```
src/
├── modules/                  # Domain modules (one per business area)
│   ├── trips/
│   │   ├── api/              # HTTP layer
│   │   ├── application/      # Use cases
│   │   ├── domain/           # Business rules (no HTTP/DB)
│   │   ├── infrastructure/   # DB/repo implementations
│   │   ├── contracts/        # DTOs
│   │   ├── tests/            # Module tests
│   │   └── README.md         # Module documentation (per §27)
│   ├── auth/
│   ├── users/
│   ├── scooters/
│   ├── cities/
│   ├── transactions/
│   ├── promocodes/
│   ├── support/
│   ├── notifications/
│   ├── juicers/
│   ├── mechanics/
│   ├── geofencing/
│   ├── uploads/
│   ├── iot/
│   ├── discovery/
│   ├── stats/
│   └── system/
│
├── views/                    # View API (BFF) per constitution §1.4, §6
│   ├── dashboard.view.js     # Aggregates admin dashboard data
│   ├── trip-detail.view.js   # Aggregates trip detail page data
│   ├── executor.js           # Request tree executor with caching
│   └── routes.js
│
├── shared/                   # Cross-cutting concerns
│   ├── errors.js             # Centralized error system
│   ├── logger.js             # Structured JSON logger
│   ├── db.js                 # MongoDB connection pool
│   ├── cache.js              # LRU cache with TTL
│   ├── http.js               # Pagination, response formatters, requestId
│   ├── validation.js         # Input validation helpers
│   ├── permissions.js        # Centralized authorization policies
│   └── auth-middleware.js    # Auth bridge to legacy v1
│
└── contracts/
    ├── openapi.yaml          # OpenAPI spec (TODO)
    └── views/                # View contracts (per §6.1)
```

## Layer rules (per constitution §12)

### API layer
**Can:** validate request, parse params, call use case, format response
**Cannot:** business logic, SQL queries, complex calculations

### Application layer
**Can:** orchestrate use cases, start transactions, call repositories,
       call policies, publish events
**Cannot:** HTTP-specific code

### Domain layer
**Can:** business rules, entities, value objects, domain events, policies,
       domain errors
**Cannot:** HTTP, database, Redis, framework imports

### Infrastructure layer
**Can:** SQL, ORM, Redis, external API, message broker, file storage
**Cannot:** business rules

## Module dependencies

Modules can depend on other modules' **application layer only** (never infrastructure).
This is enforced by convention (not yet by linting).

```
trips → scooters (status update)
trips → cities (tariff lookup)
trips → users (balance update)
trips → transactions (payment record)
trips → notifications (push alerts)
```

## Conventions

### Naming (per §23)
- Routes: kebab-case (`/trips-v2`, `/user-settings`)
- JSON: camelCase (`firstName, createdAt, ownerId`)
- DB columns: snake_case (`created_at, owner_id`)
- Error codes: UPPER_SNAKE (`TRIP_NOT_FOUND, VALIDATION_FAILED`)
- Events: past tense (`trip.ended, user.registered`)

### Response format (per §8)
```json
// Single item
{ "data": {...}, "meta": { "requestId": "req_..." } }

// List
{ "data": [...], "meta": {
    "requestId": "req_...",
    "page": { "limit": 25, "offset": 0, "total": 100, "hasMore": true }
}}

// Error
{ "error": {
    "code": "TRIP_NOT_FOUND",
    "message": "Trip not found: abc123",
    "details": { "tripId": "abc123" },
    "requestId": "req_..."
}}
```

### Request IDs
Every response has `X-Request-Id` header. Use for log correlation.

### Caching (per §15)
- L0: request memoization (not implemented)
- L1: application memory (LruCache in `shared/cache.js`)
- L2: Redis (not implemented — would need separate module)
- L3: HTTP cache headers (TODO)
- L4: precomputed read models (TODO for heavy views)

Cache rules:
- No cache without TTL
- No cache without owner (namespace)
- No cache without invalidation strategy
- Private cache keys include user/tenant scope

## Migration path from legacy v1/

The legacy `v1/` directory still contains the original routes from SparkRentals.
New modular routes are mounted alongside at:
- `/v1/trips-v2/*` (modular) coexists with `/v1/trips/*` (legacy)
- `/v1/views/*` (new — View API)

Once all endpoints are migrated, the legacy `v1/` will be deprecated and removed.
