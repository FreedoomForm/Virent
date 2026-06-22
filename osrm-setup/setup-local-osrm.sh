#!/bin/bash
# setup-local-osrm.sh — Local OSRM routing server for Virent.
# Runs on the same PC as the Virent Windows app.
# Zero external services — all routing is local.
#
# Usage: bash setup-local-osrm.sh
# After setup: OSRM runs on http://localhost:5000

set -e

OSRM_DIR="${HOME}/virent-osrm"
OSM_FILE="${OSRM_DIR}/tashkent.osm.pbf"
OSRM_FILE="${OSRM_DIR}/tashkent.osrm"

echo "=== Virent Local OSRM Setup ==="
echo ""

# 1. Install Docker if missing
if ! command -v docker &> /dev/null; then
    echo "[1/5] Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "Docker installed. Log out and back in, then re-run this script."
    exit 0
fi
echo "[1/5] Docker ✓"

# 2. Create directory
mkdir -p "${OSRM_DIR}"
echo "[2/5] Directory: ${OSRM_DIR}"

# 3. Download Tashkent OSM data (if not present)
if [ ! -f "${OSM_FILE}" ]; then
    echo "[3/5] Downloading Tashkent map data (~30 MB)..."
    # Download Uzbekistan extract from Geofabrik, then filter to Tashkent
    # For now, download Tashkent city via Overpass API
    wget -O "${OSM_FILE}" \
        "https://overpass-api.de/api/map?bbox=69.15,41.23,69.35,41.38" \
        || {
        echo "Overpass download failed. Download manually:"
        echo "  1. Go to https://download.geofabrik.de/asia/uzbekistan.html"
        echo "  2. Download uzbekistan-latest.osm.pbf"
        echo "  3. Save to: ${OSM_FILE}"
        echo "  4. Re-run this script"
        exit 1
    }
    echo "Map data downloaded."
else
    echo "[3/5] Map data already present ✓"
fi

# 4. Extract + partition (one-time, ~2 minutes)
if [ ! -f "${OSRM_FILE}" ]; then
    echo "[4/5] Processing OSM data with OSRM (2-3 minutes)..."
    
    echo "  → Extracting road network..."
    docker run --rm -v "${OSRM_DIR}:/data" \
        ghcr.io/project-osrm/osrm-backend \
        osrm-extract -p /opt/car.lua /data/tashkent.osm.pbf || {
        echo "Extraction failed. The OSM file may be invalid."
        exit 1
    }
    
    echo "  → Partitioning graph..."
    docker run --rm -v "${OSRM_DIR}:/data" \
        ghcr.io/project-osrm/osrm-backend \
        osrm-partition /data/tashkent.osrm
    
    echo "  → Customizing weights..."
    docker run --rm -v "${OSRM_DIR}:/data" \
        ghcr.io/project-osrm/osrm-backend \
        osrm-customize /data/tashkent.osrm
    
    echo "Processing complete ✓"
else
    echo "[4/5] OSRM data already processed ✓"
fi

# 5. Start OSRM server
echo "[5/5] Starting OSRM server on port 5000..."

# Stop any existing container
docker rm -f virent-osrm 2>/dev/null || true

docker run -d --name virent-osrm \
    --restart unless-stopped \
    -p 5000:5000 \
    -v "${OSRM_DIR}:/data" \
    ghcr.io/project-osrm/osrm-backend \
    osrm-routed --algorithm mld --max-matching-size 1000 /data/tashkent.osrm

echo ""
echo "=== Done! ==="
echo "OSRM running at: http://localhost:5000"
echo ""
echo "Test: curl 'http://localhost:5000/route/v1/driving/69.2406,41.3111;69.2797,41.3267?overview=full'"
echo ""
echo "Stop: docker stop virent-osrm"
echo "Start: docker start virent-osrm"
echo "Logs: docker logs virent-osrm"
