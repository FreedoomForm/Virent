# Virent — Standalone Backend

Dart / shelf reimplementation of the Virent backend. Same API surface as
the embedded server bundled inside the Flutter desktop app, packaged as a
single AOT-compiled binary suitable for VPS deployment.

Use this when you want to run the backend on a real server (DigitalOcean,
Hetzner, AWS, ...) instead of relying on a desktop PC. Mobile apps then
point at the VPS URL.

## When to use this vs. the embedded server

| Deployment                              | Use                                     |
|-----------------------------------------|-----------------------------------------|
| Single PC, mobile apps on same WiFi     | Embedded server inside the desktop app  |
| Single PC, mobile apps anywhere         | Embedded server + `start-tunnel.sh`     |
| 24/7 fleet, multiple admins, autoscale  | **This standalone backend on a VPS**    |

The standalone backend shares the same in-memory datastore shape as the
embedded server; swapping the two only changes the base URL the mobile
app points at.

## Prerequisites

- Dart 3.6+ (`dart --version`).
- Docker 24+ for the container build.

## Run locally

```bash
cd backend
dart pub get
dart run bin/server.dart
```

The server listens on `0.0.0.0:8443` by default. Override with the `PORT`
environment variable:

```bash
PORT=9000 dart run bin/server.dart
```

Smoke test:

```bash
curl http://localhost:8443/health
curl 'http://localhost:8443/scooters/nearby?lat=41.3111&lng=69.2406'
```

## Build a Docker image

```bash
docker build -t virent-backend .
docker run --rm -p 8443:8443 --name virent-backend virent-backend
```

The image is a slim Debian bookworm-slim runtime containing a single
AOT-compiled binary. It exposes port 8443 and ships a `HEALTHCHECK` that
polls `/health` every 30 seconds.

### Production deployment

```bash
docker run -d \
  -p 127.0.0.1:8443:8443 \
  -e JWT_SECRET=$(openssl rand -hex 32) \
  --name virent-backend \
  --restart unless-stopped \
  virent-backend
```

Put it behind a reverse proxy (Caddy / nginx / Cloudflare Tunnel) that
terminates TLS. Mobile apps then talk to `https://api.your-domain.com`.

### Multi-stage build

The `Dockerfile` already uses a multi-stage build: the first stage
compiles the binary inside the official `dart:3.6` image, the second
stage copies only the resulting binary into `debian:bookworm-slim`. The
final image is roughly 150 MB.

## API surface

Mirrors the embedded server in
`mobile/lib/core/backend/embedded_server.dart`. Key endpoints:

| Method | Path                                | Purpose                          |
|--------|-------------------------------------|----------------------------------|
| GET    | `/health`                           | Liveness probe                   |
| POST   | `/auth/phone/send-code`             | Send OTP                         |
| POST   | `/auth/phone/verify`                | Verify OTP, returns token + user |
| GET    | `/scooters/nearby?lat&lng`          | Nearby scooters sorted by distance |
| POST   | `/trips/start`                      | Begin a ride                     |
| POST   | `/trips/end`                        | End a ride, compute cost         |
| GET    | `/trips/history`                    | User's past trips                |
| GET    | `/wallet`                           | Balance + transactions           |
| POST   | `/wallet/topup`                     | Add credit                       |
| GET    | `/admin/stats`                      | Dashboard headline numbers       |
| POST   | `/admin/notifications/send`         | Compose + dispatch push          |
| POST   | `/admin/prepaids/bulk`              | Generate prepaid codes           |
| GET    | `/admin/audit-log?actor&action`     | Filtered audit trail             |
| POST   | `/admin/users/<id>/block`           | Block a customer                 |
| POST   | `/admin/trips/<id>/refund`          | Refund a trip                    |
| GET    | `/sms/pending`                      | SMS gateway queue                |
| POST   | `/iot/telemetry`                    | Scooter pushes GPS / battery     |
| GET    | `/iot/command?scooter_mac=...`      | Scooter polls for commands       |
| POST   | `/iot/command/send`                 | Admin queues a command           |

Full list: see the route registration calls at the top of
`bin/server.dart`.

## Environment variables

| Variable     | Default | Purpose                                          |
|--------------|---------|--------------------------------------------------|
| `PORT`       | `8443`  | Port the shelf server binds to                   |
| `JWT_SECRET` | `dev`   | Secret used to sign scooter IoT command tokens   |

## Project layout

```
backend/
  bin/server.dart        # entry point — assembles the router + serves
  lib/routes/
    all_routes.dart      # route registration (auth, scooters, trips, ...)
    auth.dart
    scooters.dart
    trips.dart
    users.dart
    wallet.dart
  pubspec.yaml
  Dockerfile
```

## Notes for agents

- The standalone backend is intentionally lightweight: in-memory
  datastore, no external database. For production swap the `DataService`
  class for a Mongo / Postgres adapter — the API surface stays identical.
- Keep `bin/server.dart` and `mobile/lib/core/backend/embedded_server.dart`
  in sync when adding endpoints.
