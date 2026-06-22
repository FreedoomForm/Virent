# Virent Dart Backend — Docker image for cloud deployment
#
# Builds a single AOT-compiled Dart binary (`virent-backend`) and ships it
# in a slim Debian runtime image. The binary embeds the in-memory datastore
# (no external database required for the dev / small-fleet deployment).
#
# Build:
#   docker build -t virent-backend ./backend
#
# Run (local):
#   docker run --rm -p 8443:8443 --name virent-backend virent-backend
#
# Run (production, behind Cloudflare Tunnel / nginx):
#   docker run -d -p 127.0.0.1:8443:8443 \
#     -e JWT_SECRET=$(openssl rand -hex 32) \
#     --name virent-backend --restart unless-stopped \
#     virent-backend
#
# Health check:
#   curl http://localhost:8443/health
#
# Mobile apps connect to: http://<server-host>:8443

# ---------- build stage ----------
FROM dart:3.6 AS build
WORKDIR /app

# Cache pub get across image builds.
COPY pubspec.* ./
RUN dart pub get

# Compile a self-contained native binary.
COPY . .
RUN dart compile exe bin/server.dart -o virent-backend

# ---------- runtime stage ----------
FROM debian:bookworm-slim
LABEL org.opencontainers.image.title="virent-backend"
LABEL org.opencontainers.image.description="Virent scooter-sharing backend (Dart / shelf)"
LABEL org.opencontainers.image.source="https://github.com/freedoomform/sparkrentals-monorepo"

# ca-certificates is needed for any outbound HTTPS (push notifications,
# Cloudflare tunnel callbacks, etc.) and curl is kept for the HEALTHCHECK.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/virent-backend /usr/local/bin/virent-backend

# Default port the shelf server binds to. Override with `docker run -e PORT=...`.
ENV PORT=8443
EXPOSE 8443

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -fsS http://localhost:${PORT}/health || exit 1

CMD ["virent-backend"]
