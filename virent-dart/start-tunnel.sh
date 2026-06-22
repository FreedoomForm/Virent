#!/usr/bin/env bash
# ============================================================
# Virent Cloudflare Tunnel — makes your PC a global server
# ============================================================
#
# No VPS needed. Your PC becomes accessible from anywhere via a free
# Cloudflare Tunnel URL like:
#   https://virent-abc123.trycloudflare.com
#
# Prerequisites:
#   1. The Virent desktop app must be running (embedded server on :8443)
#   2. cloudflared installed (downloaded automatically on first run)
#
# Usage:
#   bash start-tunnel.sh          # start tunnel (prints public URL)
#   bash start-tunnel.sh --stop   # stop tunnel
#   bash start-tunnel.sh --status # check tunnel status
#
# Mobile apps connect to the printed URL from anywhere in the world.
# ============================================================

set -e

PORT="${VIRENT_PORT:-8443}"
TUNNEL_NAME="virent"

# Detect OS to pick the right cloudflared binary.
OS="$(uname -s)"
case "$OS" in
    MINGW*|MSYS*|CYGWIN*|Windows*)
        CLOUDFLARED="cloudflared.exe"
        DOWNLOAD_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
        STOP_CMD='taskkill //F //IM cloudflared.exe 2>/dev/null || true'
        ;;
    Darwin)
        CLOUDFLARED="cloudflared"
        DOWNLOAD_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz"
        STOP_CMD='pkill -f "cloudflared tunnel" 2>/dev/null || true'
        ;;
    Linux)
        CLOUDFLARED="cloudflared"
        DOWNLOAD_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
        STOP_CMD='pkill -f "cloudflared tunnel" 2>/dev/null || true'
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# === Check if Virent server is running ===
echo "Checking if Virent server is running on port $PORT..."
if ! curl -fsS "http://localhost:$PORT/health" > /dev/null 2>&1; then
    echo "ERROR: Virent server is not reachable on port $PORT."
    echo "       Start the Virent desktop app first (or set VIRENT_PORT)."
    exit 1
fi
echo "OK - Virent server is running."

# === Handle --status ===
if [ "$1" = "--status" ]; then
    if pgrep -f "cloudflared tunnel" > /dev/null 2>&1; then
        echo "Tunnel is running."
        exit 0
    fi
    echo "Tunnel is not running."
    exit 1
fi

# === Handle --stop ===
if [ "$1" = "--stop" ]; then
    echo "Stopping tunnel..."
    eval "$STOP_CMD"
    echo "Tunnel stopped."
    exit 0
fi

# === Download cloudflared if not present ===
if [ ! -f "$CLOUDFLARED" ] && ! command -v "$CLOUDFLARED" > /dev/null 2>&1; then
    echo "Downloading cloudflared..."
    case "$OS" in
        MINGW*|MSYS*|CYGWIN*|Windows*)
            curl -fsSL "$DOWNLOAD_URL" -o "$CLOUDFLARED"
            chmod +x "$CLOUDFLARED"
            ;;
        Darwin)
            curl -fsSL "$DOWNLOAD_URL" -o cloudflared.tgz
            tar -xzf cloudflared.tgz
            rm -f cloudflared.tgz
            chmod +x "$CLOUDFLARED"
            ;;
        Linux)
            curl -fsSL "$DOWNLOAD_URL" -o "$CLOUDFLARED"
            chmod +x "$CLOUDFLARED"
            ;;
    esac
fi

# Use the local copy if present, otherwise rely on PATH.
if [ -f "$CLOUDFLARED" ]; then
    BIN="./$CLOUDFLARED"
else
    BIN="$CLOUDFLARED"
fi

# === Start tunnel ===
echo ""
echo "========================================================="
echo "  Starting Cloudflare Tunnel..."
echo "  Your PC will be accessible from anywhere in the world."
echo ""
echo "  Share the printed URL with mobile app users."
echo "  In the app: Settings -> Server URL -> paste the URL"
echo "========================================================="
echo ""

# Quick tunnel (no account needed, random URL).
"$BIN" tunnel --url "http://localhost:$PORT" --protocol http2 2>&1 \
    | while read -r line; do
        echo "$line"
        # Extract the public URL from cloudflared output.
        if echo "$line" | grep -q "trycloudflare.com"; then
            URL=$(echo "$line" | grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' | head -n1)
            if [ -n "$URL" ]; then
                echo ""
                echo "========================================================="
                echo "  YOUR PUBLIC SERVER URL:"
                echo "  $URL"
                echo ""
                echo "  Mobile apps: Settings -> Server URL -> $URL"
                echo "  This URL works from anywhere in the world."
                echo "  Keep this terminal open to maintain the tunnel."
                echo "========================================================="
            fi
        fi
    done
