# SparkRentals Database

## Approach

> **Access-pattern-first DB design with domain data tree, strict constraints,
> query budgets, read models and migration discipline.**

Per Database Design System v1.0, the database is designed as:
1. Domain model → tables
2. Request tree → access patterns
3. Access patterns → indexes
4. Heavy screens → read models

## Current implementation

SparkRentals currently uses **MongoDB 7.0** as the primary datastore.

The SQL schema in `migrations/202606170001_create_core_tables.sql` is a
reference implementation showing the intended normalized write-model with
strict constraints (PK, FK, NOT NULL, UNIQUE, CHECK, DEFAULT).

When migrating to PostgreSQL, that file is the source of truth.

## Directory structure

```
db/
├── README.md                              ← this file
├── migrations/
│   └── 202606170001_create_core_tables.sql  ← full schema (SQL reference)
├── access-patterns/                       ← per constitution §13
│   ├── trips.getActiveByUser.yaml
│   ├── trips.listByUser.yaml
│   ├── scooters.findNearestAvailable.yaml
│   ├── scooters.listAvailable.yaml
│   ├── transactions.aggregateRevenue.yaml
│   ├── users.findByEmail.yaml
│   ├── support_tickets.listByUser.yaml
│   ├── otp_codes.createAndSend.yaml
│   └── audit_log.append.yaml
├── schema/                                ← schema diagrams (TODO)
├── seeds/                                 ← dev/test seed data
└── docs/                                  ← design docs (TODO)
    ├── data-model.md
    ├── lifecycle.md
    ├── retention.md
    └── backup-restore.md
```

## Collections (MongoDB) / Tables (SQL)

| Collection/Table      | Domain Owner         | D-Priority | Description                       |
|-----------------------|----------------------|------------|-----------------------------------|
| users                 | modules/users        | D0         | User accounts                     |
| cities                | modules/cities       | D1         | Service cities with zones         |
| city_zones            | modules/cities       | D1         | Parking/charging/no-parking zones |
| scooters              | modules/scooters     | D0/D1      | Scooter fleet                     |
| trips                 | modules/trips        | D0/D1      | Rental sessions                   |
| transactions          | modules/transactions | D1/D2      | Payment history                   |
| promocodes            | modules/promocodes   | D2         | Promo codes                       |
| promocode_usages      | modules/promocodes   | D3         | Usage tracking                    |
| support_tickets       | modules/support      | D1/D2      | Support tickets                   |
| support_ticket_messages | modules/support    | D2         | Ticket messages                   |
| notifications         | modules/notifications| D2         | User notifications                |
| device_tokens         | modules/notifications| D2         | Push device tokens                |
| juicers               | modules/juicers      | D2         | Charger team members              |
| juicer_tasks          | modules/juicers      | D2         | Scooter charging tasks            |
| mechanics             | modules/mechanics    | D2         | Maintenance team members          |
| maintenance_requests  | modules/mechanics    | D2         | Repair requests                   |
| parts_inventory       | modules/mechanics    | D2         | Spare parts stock                 |
| scooter_commands      | modules/iot          | D3         | Pending IoT commands              |
| uploads               | modules/uploads      | D3         | File metadata                     |
| user_settings         | modules/users        | D2         | Per-user preferences              |
| refresh_tokens        | modules/auth         | D0         | JWT refresh tokens                |
| otp_codes             | modules/auth         | D0         | SMS OTP codes (TTL 10min)         |
| audit_events          | shared/audit         | D3         | Audit log (TTL 1 year)            |
| outbox_events         | shared/outbox        | D3         | Outbox for event publishing       |

## Indexes

All indexes are documented in `access-patterns/*.yaml` files. Summary:

- **TTL indexes** (auto-expire): otp_codes (10min), audit_events (1yr), notifications (90d), scooter_commands (7d)
- **Unique indexes**: users.email, users.phone, scooters.mac_address, scooters.imei, promocodes.code, refresh_tokens.token_hash
- **Performance indexes**: 28 indexes total — see `src/shared/db_indexes.js` for the MongoDB index creation code

## Resource budgets

Per constitution §26:

| Operation                     | Budget          |
|-------------------------------|-----------------|
| Primary key lookup            | 1-10ms          |
| Indexed list query            | 30-80ms         |
| Complex read query            | 100-200ms       |
| Slow query threshold          | 100-200ms       |
| Max rows returned (list)      | 100             |
| Default list limit            | 25-50           |
| HTTP request DB queries (max) | 5-10            |
| Transaction duration          | <100-300ms      |

## Lifecycle

Per constitution §23:

| Data type          | Hot          | Warm             | Cold              |
|--------------------|--------------|------------------|-------------------|
| Active trips       | 30 days      | 90 days archive  | 1 year            |
| Transactions       | 90 days      | 1 year           | 7 years (legal)   |
| Notifications      | 30 days      | 90 days          | delete after 90d  |
| Audit log          | 90 days      | 1 year           | delete after 1yr  |
| OTP codes          | 10 min       | —                | delete after TTL  |
| Scooter telemetry  | 7 days       | 30 days          | aggregate + delete|

## Backup strategy

Per constitution §35:

```yaml
rpo: 15 minutes       # max acceptable data loss
rto: 2 hours          # recovery time objective
retention:
  daily: 14 days
  weekly: 8 weeks
  monthly: 12 months
restore_test: monthly
```

For MongoDB:
- Use `mongodump` with `--oplog` for point-in-time backups
- Store backups in encrypted object storage (S3/R2)
- Test restore monthly to a separate cluster

## Security

Per constitution §34:
- Application connects with `app_rw` role (least privilege)
- Migration user is separate, only used during deploys
- Sensitive data (passwords, tokens) stored hashed
- PII never logged
- Audit log is append-only (no UPDATE/DELETE)
