-- =============================================================
-- Migration: 202606170001_create_core_tables.sql
-- =============================================================
-- Creates the core SparkRentals schema with strict constraints.
-- Per constitution §5, §9, §11: every table has PK, FK, NOT NULL,
-- UNIQUE, CHECK, DEFAULT, created_at/updated_at.
-- =============================================================

-- Notes:
-- This is a SQL reference schema. The current implementation uses MongoDB,
-- but this migration documents the intended normalized write-model.
-- When migrating to PostgreSQL, this file is the source of truth.

-- =============================================================
-- ENUM types (use TEXT + CHECK for migration safety per §8)
-- =============================================================

-- user_role: user | admin | juicer | mechanic | support
-- user_status: active | blocked | deleted
-- scooter_status: available | reserved | in_use | charging_needed | charging | maintenance | retired
-- trip_status: reserved | active | ended | cancelled | expired
-- txn_type: topup_click | topup_payme | topup_card | trip_payment | refund | bonus | penalty | juicer_payout
-- txn_status: pending | preparing | completed | failed | cancelled
-- ticket_status: open | in_progress | resolved | closed
-- ticket_type: breakdown | billing | account | other

-- =============================================================
-- organizations (multi-tenant root, optional)
-- =============================================================

CREATE TABLE IF NOT EXISTS organizations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active', 'suspended', 'deleted')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================
-- users
-- =============================================================

CREATE TABLE IF NOT EXISTS users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID REFERENCES organizations(id),

    email               TEXT UNIQUE,
    phone               TEXT UNIQUE,
    password_hash       TEXT,                        -- null for SMS-only users
    google_id           TEXT UNIQUE,

    first_name          TEXT NOT NULL DEFAULT '',
    last_name           TEXT NOT NULL DEFAULT '',
    balance_cents       BIGINT NOT NULL DEFAULT 0,    -- money in cents per §8
    currency            CHAR(3) NOT NULL DEFAULT 'UZS',

    role                TEXT NOT NULL DEFAULT 'user'
                        CHECK (role IN ('user', 'admin', 'juicer', 'mechanic', 'support')),
    status              TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'blocked', 'deleted')),

    phone_verified      BOOLEAN NOT NULL DEFAULT false,
    phone_verified_at   TIMESTAMPTZ,
    accepted_terms_at   TIMESTAMPTZ,
    terms_version       TEXT,
    last_login_at       TIMESTAMPTZ,
    password_changed_at TIMESTAMPTZ,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_phone ON users (phone) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_role_status ON users (role, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_last_login ON users (last_login_at DESC);

-- =============================================================
-- cities
-- =============================================================

CREATE TABLE IF NOT EXISTS cities (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id             UUID REFERENCES organizations(id),

    name                        TEXT NOT NULL,
    fixed_rate_cents            BIGINT NOT NULL DEFAULT 0,
    time_rate_cents             BIGINT NOT NULL DEFAULT 0,
    parking_zone_rate_cents     BIGINT NOT NULL DEFAULT 0,
    bonus_parking_rate_cents    BIGINT NOT NULL DEFAULT 0,
    no_parking_rate_cents       BIGINT NOT NULL DEFAULT 0,
    no_parking_to_valid_cents   BIGINT NOT NULL DEFAULT 0,
    charging_zone_rate_cents    BIGINT NOT NULL DEFAULT 0,

    -- outer city boundary (PostGIS polygon, or JSONB for MongoDB compat)
    outer_boundary              JSONB,

    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at                  TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_cities_org ON cities (organization_id) WHERE deleted_at IS NULL;

-- =============================================================
-- zones (parking / no_parking / bonus_parking / charging)
-- =============================================================

CREATE TABLE IF NOT EXISTS city_zones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    city_id         UUID NOT NULL REFERENCES cities(id),
    type            TEXT NOT NULL
                    CHECK (type IN ('parking', 'bonus_parking', 'no_parking', 'charging')),
    name            TEXT,
    coordinates     JSONB NOT NULL,       -- { longitude, latitude } center point
    polygon         JSONB NOT NULL,       -- [{ longitude, latitude }, ...]
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_zones_city ON city_zones (city_id);
CREATE INDEX IF NOT EXISTS idx_zones_type ON city_zones (type);

-- =============================================================
-- scooters
-- =============================================================

CREATE TABLE IF NOT EXISTS scooters (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id             UUID REFERENCES organizations(id),
    owner_city_id               UUID NOT NULL REFERENCES cities(id),

    name                        TEXT NOT NULL,
    serial_number               TEXT UNIQUE,
    mac_address                 TEXT UNIQUE,
    imei                        TEXT UNIQUE,
    sim_number                  TEXT,

    model                       TEXT NOT NULL DEFAULT 'unknown',
    manufacturer                TEXT NOT NULL DEFAULT 'unknown',
    firmware_version            TEXT NOT NULL DEFAULT '1.0.0',
    hardware_version            TEXT NOT NULL DEFAULT '1.0',

    status                      TEXT NOT NULL DEFAULT 'available'
                                CHECK (status IN ('available', 'reserved', 'in_use',
                                                  'charging_needed', 'charging',
                                                  'maintenance', 'retired')),

    coordinates                 JSONB,        -- { longitude, latitude }
    battery                     NUMERIC(5,2) NOT NULL DEFAULT 100
                                CHECK (battery >= 0 AND battery <= 100),
    battery_capacity_wh         NUMERIC(6,2) NOT NULL DEFAULT 280,
    battery_cycles              INTEGER NOT NULL DEFAULT 0,
    battery_health_percent      INTEGER NOT NULL DEFAULT 100
                                CHECK (battery_health_percent >= 0 AND battery_health_percent <= 100),
    last_battery_health_check   TIMESTAMPTZ,

    max_speed_kmh               INTEGER NOT NULL DEFAULT 25,
    total_distance_km           NUMERIC(10,2) NOT NULL DEFAULT 0,
    total_rides                 INTEGER NOT NULL DEFAULT 0,

    purchase_date               DATE,
    purchase_price_cents        BIGINT,

    last_maintenance_at         TIMESTAMPTZ,
    last_maintenance_note       TEXT,
    next_maintenance_at         TIMESTAMPTZ,
    retired_at                  TIMESTAMPTZ,
    retired_reason              TEXT,

    iot_secret_hash             TEXT,            -- for ESP32 authentication
    last_seen                   TIMESTAMPTZ,

    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at                  TIMESTAMPTZ
);

-- Access pattern indexes (per constitution §11)
CREATE INDEX IF NOT EXISTS idx_scooters_status_battery
    ON scooters (status, battery) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_scooters_city_status
    ON scooters (owner_city_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_scooters_mac
    ON scooters (mac_address) WHERE mac_address IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_scooters_status_lowbattery
    ON scooters (status, battery) WHERE status = 'available' AND battery < 20;

-- =============================================================
-- trips
-- =============================================================

CREATE TABLE IF NOT EXISTS trips (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id         UUID REFERENCES organizations(id),
    user_id                 UUID NOT NULL REFERENCES users(id),
    scooter_id              UUID NOT NULL REFERENCES scooters(id),
    city_id                 UUID NOT NULL REFERENCES cities(id),

    status                  TEXT NOT NULL DEFAULT 'reserved'
                            CHECK (status IN ('reserved', 'active', 'ended',
                                              'cancelled', 'expired')),

    start_time              TIMESTAMPTZ,
    end_time                TIMESTAMPTZ,
    reservation_time        TIMESTAMPTZ NOT NULL DEFAULT now(),
    reservation_expires     TIMESTAMPTZ NOT NULL,

    start_coordinates       JSONB,
    end_coordinates         JSONB,
    start_battery           NUMERIC(5,2),
    end_battery             NUMERIC(5,2),

    distance_km             NUMERIC(10,2) NOT NULL DEFAULT 0,
    duration_min            INTEGER NOT NULL DEFAULT 0,
    cost_cents              BIGINT NOT NULL DEFAULT 0,
    cost_breakdown          JSONB NOT NULL DEFAULT '{}',
    photo_url               TEXT,
    end_zone_type           TEXT
                            CHECK (end_zone_type IS NULL OR end_zone_type IN
                                   ('parking', 'bonus_parking', 'no_parking', 'charging', 'street')),

    refund_amount_cents     BIGINT NOT NULL DEFAULT 0,
    refund_reason           TEXT,

    auto_end_flagged        BOOLEAN NOT NULL DEFAULT false,
    outside_city_warned     BOOLEAN NOT NULL DEFAULT false,
    no_parking_warned       BOOLEAN NOT NULL DEFAULT false,

    cancelled_at            TIMESTAMPTZ,
    cancelled_reason        TEXT,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Per constitution §11: index follows access pattern
CREATE INDEX IF NOT EXISTS idx_trips_user_status
    ON trips (user_id, status);
CREATE INDEX IF NOT EXISTS idx_trips_user_created
    ON trips (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trips_scooter_status
    ON trips (scooter_id, status);
CREATE INDEX IF NOT EXISTS idx_trips_status_reservation_expires
    ON trips (status, reservation_expires)
    WHERE status = 'reserved';
CREATE INDEX IF NOT EXISTS idx_trips_active_start
    ON trips (start_time)
    WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_trips_status_created
    ON trips (status, created_at DESC);

-- =============================================================
-- transactions
-- =============================================================

CREATE TABLE IF NOT EXISTS transactions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID REFERENCES organizations(id),
    user_id             UUID REFERENCES users(id),
    trip_id             UUID REFERENCES trips(id),
    juicer_id           UUID REFERENCES users(id),

    type                TEXT NOT NULL
                        CHECK (type IN ('topup_click', 'topup_payme', 'topup_card',
                                        'trip_payment', 'refund', 'bonus', 'penalty',
                                        'juicer_payout')),
    amount_cents        BIGINT NOT NULL,        -- positive for topup, negative for spend
    balance_after_cents BIGINT,
    currency            CHAR(3) NOT NULL DEFAULT 'UZS',
    method              TEXT NOT NULL DEFAULT 'balance'
                        CHECK (method IN ('balance', 'external', 'card')),
    provider            TEXT NOT NULL DEFAULT 'internal'
                        CHECK (provider IN ('internal', 'click', 'payme', 'card')),
    provider_txn_id     TEXT,

    status              TEXT NOT NULL DEFAULT 'completed'
                        CHECK (status IN ('pending', 'preparing', 'completed',
                                          'failed', 'cancelled')),

    description         TEXT NOT NULL DEFAULT '',
    error_code          TEXT,
    error_message       TEXT,

    completed_at        TIMESTAMPTZ,
    cancelled_at        TIMESTAMPTZ,
    cancel_reason       TEXT,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_txn_user_created
    ON transactions (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_txn_type_status
    ON transactions (type, status);
CREATE INDEX IF NOT EXISTS idx_txn_provider_txn
    ON transactions (provider, provider_txn_id) WHERE provider_txn_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_txn_trip
    ON transactions (trip_id) WHERE trip_id IS NOT NULL;

-- =============================================================
-- promocodes
-- =============================================================

CREATE TABLE IF NOT EXISTS promocodes (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID REFERENCES organizations(id),

    code                TEXT NOT NULL UNIQUE,
    type                TEXT NOT NULL
                        CHECK (type IN ('first_ride', 'any_ride', 'free_minutes',
                                        'cashback', 'referral_inviter', 'referral_invitee')),
    value               NUMERIC(12,2) NOT NULL,    -- amount or percent (0-1)
    max_uses            INTEGER NOT NULL DEFAULT 0,  -- 0 = unlimited
    used_count          INTEGER NOT NULL DEFAULT 0,
    per_user_limit      INTEGER NOT NULL DEFAULT 1,

    valid_from          TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until         TIMESTAMPTZ,
    min_ride_cost_cents BIGINT NOT NULL DEFAULT 0,
    max_discount_cents  BIGINT NOT NULL DEFAULT 0,

    status              TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'disabled', 'expired')),

    referrer_user_id    UUID REFERENCES users(id),  -- for referral codes

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    disabled_at         TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_promocodes_status_valid
    ON promocodes (status, valid_until) WHERE status = 'active';

CREATE TABLE IF NOT EXISTS promocode_usages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promocode_id    UUID NOT NULL REFERENCES promocodes(id),
    user_id         UUID NOT NULL REFERENCES users(id),
    trip_id         UUID REFERENCES trips(id),
    used_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (promocode_id, user_id, trip_id)
);

CREATE INDEX IF NOT EXISTS idx_promo_usage_user
    ON promocode_usages (user_id);

-- =============================================================
-- support_tickets
-- =============================================================

CREATE TABLE IF NOT EXISTS support_tickets (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID REFERENCES organizations(id),
    user_id             UUID NOT NULL REFERENCES users(id),
    scooter_id          UUID REFERENCES scooters(id),
    trip_id             UUID REFERENCES trips(id),

    type                TEXT NOT NULL
                        CHECK (type IN ('breakdown', 'billing', 'account', 'other')),
    subject             TEXT NOT NULL,
    status              TEXT NOT NULL DEFAULT 'open'
                        CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority            TEXT NOT NULL DEFAULT 'normal'
                        CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    problem_category    TEXT
                        CHECK (problem_category IS NULL OR problem_category IN
                               ('wheel', 'brake', 'battery', 'lock', 'display',
                                'throttle', 'frame', 'lighting', 'other')),
    photo_url           TEXT,

    assigned_to         UUID REFERENCES users(id),
    resolved_at         TIMESTAMPTZ,
    resolution_note     TEXT,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tickets_user_created
    ON support_tickets (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tickets_status_priority
    ON support_tickets (status, priority);

CREATE TABLE IF NOT EXISTS support_ticket_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id       UUID NOT NULL REFERENCES support_tickets(id),
    author_type     TEXT NOT NULL CHECK (author_type IN ('user', 'admin')),
    author_user_id  UUID NOT NULL REFERENCES users(id),
    message         TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ticket_messages_ticket
    ON support_ticket_messages (ticket_id, created_at);

-- =============================================================
-- audit_log (append-only per §20)
-- =============================================================

CREATE TABLE IF NOT EXISTS audit_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id),
    actor_user_id   UUID REFERENCES users(id),
    actor_role      TEXT NOT NULL,
    actor_email     TEXT,
    action          TEXT NOT NULL,        -- e.g. 'scooter.create'
    target_type     TEXT NOT NULL,        -- 'scooter', 'user', 'trip'
    target_id       TEXT,
    before          JSONB,
    after           JSONB,
    ip_address      TEXT,
    user_agent      TEXT,
    metadata        JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    retention_expires TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '365 days')
);

-- Per constitution §20: audit log is append-only — no UPDATE/DELETE
-- Per constitution §24: partition by month for large audit tables
CREATE INDEX IF NOT EXISTS idx_audit_actor_time
    ON audit_events (actor_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_action_time
    ON audit_events (action, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_target
    ON audit_events (target_type, target_id);

-- =============================================================
-- outbox_events (per §19 — for reliable event publishing)
-- =============================================================

CREATE TABLE IF NOT EXISTS outbox_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type      TEXT NOT NULL,            -- e.g. 'trip.ended'
    aggregate_type  TEXT NOT NULL,            -- 'trip', 'scooter', 'user'
    aggregate_id    UUID NOT NULL,
    payload         JSONB NOT NULL,
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'published', 'failed')),
    attempts        INTEGER NOT NULL DEFAULT 0,
    last_error      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    published_at    TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_outbox_pending
    ON outbox_events (created_at) WHERE status = 'pending';

-- =============================================================
-- refresh_tokens
-- =============================================================

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    token_hash      TEXT NOT NULL UNIQUE,
    revoked         BOOLEAN NOT NULL DEFAULT false,
    revoke_reason   TEXT,
    ip_address      TEXT,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at      TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_refresh_user_active
    ON refresh_tokens (user_id, revoked) WHERE revoked = false;
CREATE INDEX IF NOT EXISTS idx_refresh_expires
    ON refresh_tokens (expires_at) WHERE revoked = false;

-- =============================================================
-- otp_codes (TTL 10 min)
-- =============================================================

CREATE TABLE IF NOT EXISTS otp_codes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone           TEXT NOT NULL,
    purpose         TEXT NOT NULL
                    CHECK (purpose IN ('login', 'password_reset', 'phone_verify')),
    code_hash       TEXT NOT NULL,
    used            BOOLEAN NOT NULL DEFAULT false,
    attempts        INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ NOT NULL,
    verified_at     TIMESTAMPTZ,
    blocked_at      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_otp_phone_purpose_active
    ON otp_codes (phone, purpose, used, expires_at)
    WHERE used = false;

-- =============================================================
-- notifications
-- =============================================================

CREATE TABLE IF NOT EXISTS notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    type            TEXT NOT NULL DEFAULT 'general',
    data            JSONB NOT NULL DEFAULT '{}',
    read_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notif_user_unread
    ON notifications (user_id, created_at DESC) WHERE read_at IS NULL;

CREATE TABLE IF NOT EXISTS device_tokens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    platform        TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    token           TEXT NOT NULL,
    active          BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at    TIMESTAMPTZ,
    unregistered_at TIMESTAMPTZ,
    UNIQUE (user_id, platform, token)
);

CREATE INDEX IF NOT EXISTS idx_devices_user_active
    ON device_tokens (user_id, active) WHERE active = true;

-- =============================================================
-- juicers + juicer_tasks
-- =============================================================

CREATE TABLE IF NOT EXISTS juicers (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                     UUID UNIQUE REFERENCES users(id),
    phone                       TEXT NOT NULL UNIQUE,
    first_name                  TEXT NOT NULL,
    last_name                   TEXT NOT NULL,
    pay_rate_cents              BIGINT NOT NULL DEFAULT 500000,
    status                      TEXT NOT NULL DEFAULT 'active'
                                CHECK (status IN ('active', 'suspended')),
    total_earned_cents          BIGINT NOT NULL DEFAULT 0,
    total_scooters_charged      INTEGER NOT NULL DEFAULT 0,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS juicer_tasks (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    juicer_id           UUID NOT NULL REFERENCES juicers(id),
    scooter_id          UUID NOT NULL REFERENCES scooters(id),
    status              TEXT NOT NULL DEFAULT 'assigned'
                        CHECK (status IN ('assigned', 'picked_up', 'charged',
                                          'returned', 'cancelled')),
    pay_amount_cents    BIGINT NOT NULL,
    paid                BOOLEAN NOT NULL DEFAULT false,
    pickup_coordinates  JSONB,
    return_coordinates  JSONB,
    assigned_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    picked_up_at        TIMESTAMPTZ,
    charged_at          TIMESTAMPTZ,
    returned_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_juicer_tasks_juicer_status
    ON juicer_tasks (juicer_id, status);
CREATE INDEX IF NOT EXISTS idx_juicer_tasks_scooter
    ON juicer_tasks (scooter_id, status) WHERE status IN ('assigned', 'picked_up');

-- =============================================================
-- mechanics + maintenance_requests
-- =============================================================

CREATE TABLE IF NOT EXISTS mechanics (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID UNIQUE REFERENCES users(id),
    phone               TEXT NOT NULL UNIQUE,
    first_name          TEXT NOT NULL,
    last_name           TEXT NOT NULL,
    specialization      TEXT NOT NULL DEFAULT 'general',
    status              TEXT NOT NULL DEFAULT 'active',
    total_repairs       INTEGER NOT NULL DEFAULT 0,
    current_assignments INTEGER NOT NULL DEFAULT 0,
    parts_used_total    INTEGER NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS maintenance_requests (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scooter_id          UUID NOT NULL REFERENCES scooters(id),
    mechanic_id         UUID REFERENCES mechanics(id),
    reason              TEXT NOT NULL,
    priority            TEXT NOT NULL DEFAULT 'normal'
                        CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    status              TEXT NOT NULL DEFAULT 'open'
                        CHECK (status IN ('open', 'assigned', 'in_progress',
                                          'completed', 'escalated', 'cancelled')),
    created_by_admin    BOOLEAN NOT NULL DEFAULT false,
    assigned_at         TIMESTAMPTZ,
    work_started_at     TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    resolution_note     TEXT,
    needed_parts        JSONB NOT NULL DEFAULT '[]',
    parts_used          JSONB NOT NULL DEFAULT '[]',
    completion_photo_url TEXT,
    escalated_at        TIMESTAMPTZ,
    escalate_reason    TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_maint_scooter_status
    ON maintenance_requests (scooter_id, status);
CREATE INDEX IF NOT EXISTS idx_maint_mechanic_status
    ON maintenance_requests (mechanic_id, status) WHERE mechanic_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_maint_status_created
    ON maintenance_requests (status, created_at DESC);

CREATE TABLE IF NOT EXISTS parts_inventory (
    part            TEXT PRIMARY KEY
                    CHECK (part IN ('front_wheel', 'rear_wheel', 'brake_pad',
                                    'brake_cable', 'battery_pack', 'display_unit',
                                    'throttle', 'controller', 'frame_part',
                                    'headlight', 'taillight', 'lock_mechanism',
                                    'tire', 'inner_tube', 'screw_set', 'other')),
    quantity        INTEGER NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================
-- scooter_commands (IoT polling)
-- =============================================================

CREATE TABLE IF NOT EXISTS scooter_commands (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scooter_mac     TEXT NOT NULL,
    command         TEXT NOT NULL
                    CHECK (command IN ('lock', 'unlock', 'alarm_on', 'alarm_off',
                                       'led_on', 'led_off', 'update_firmware',
                                       'reboot', 'locate')),
    params          JSONB NOT NULL DEFAULT '{}',
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'delivered', 'acked', 'failed', 'expired')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    delivered_at    TIMESTAMPTZ,
    ack_at          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_scooter_cmd_pending
    ON scooter_commands (scooter_mac, status, created_at) WHERE status = 'pending';

-- =============================================================
-- uploads (file metadata)
-- =============================================================

CREATE TABLE IF NOT EXISTS uploads (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id),
    filename        TEXT NOT NULL,
    original_name   TEXT,
    mime_type       TEXT NOT NULL,
    size_bytes      BIGINT NOT NULL,
    storage_key     TEXT NOT NULL,
    public_url      TEXT NOT NULL,
    purpose         TEXT NOT NULL DEFAULT 'general',
    checksum        TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_uploads_user_created
    ON uploads (user_id, created_at DESC);

-- =============================================================
-- user_settings
-- =============================================================

CREATE TABLE IF NOT EXISTS user_settings (
    user_id                 UUID PRIMARY KEY REFERENCES users(id),
    language                TEXT NOT NULL DEFAULT 'ru',
    theme                   TEXT NOT NULL DEFAULT 'light'
                            CHECK (theme IN ('light', 'dark', 'system')),
    push_ride_end_reminders BOOLEAN NOT NULL DEFAULT true,
    push_low_battery        BOOLEAN NOT NULL DEFAULT true,
    push_promos             BOOLEAN NOT NULL DEFAULT true,
    default_city_id         UUID REFERENCES cities(id),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================
-- update_updated_at triggers
-- =============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY[
        'organizations', 'users', 'cities', 'scooters', 'trips', 'transactions',
        'promocodes', 'support_tickets', 'juicers', 'juicer_tasks',
        'mechanics', 'maintenance_requests', 'parts_inventory', 'user_settings'
    ])
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_%s_updated ON %s;', t, t);
        EXECUTE format('CREATE TRIGGER trg_%s_updated BEFORE UPDATE ON %s
                        FOR EACH ROW EXECUTE FUNCTION update_updated_at();', t, t);
    END LOOP;
END $$;

-- =============================================================
-- Done. Verify schema.
-- =============================================================
SELECT 'Schema created successfully' as status;
