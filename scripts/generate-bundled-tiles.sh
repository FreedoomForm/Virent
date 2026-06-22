#!/bin/bash
# generate-bundled-tiles.sh — Pre-bundle Tashkent map tiles in APK.
set -e
TILES_DIR="virent-dart/mobile/assets/tiles/tashkent"
MIN_ZOOM=12
MAX_ZOOM=14  # zooms 12-14 (~500 tiles, ~5MB) for APK size; 15-16 cached at runtime
NORTH=41.38; SOUTH=41.23; EAST=69.35; WEST=69.15

lon_to_x() { echo "scale=0; (($1 + 180) / 360 * (2 ^ $2)) / 1" | bc; }
lat_to_y() {
    local lat=$1 rad
    rad=$(echo "scale=10; $lat * 3.1415926 / 180" | bc -l)
    local v
    v=$(echo "scale=10; (1 - (l(s($rad)/c($rad) + 1/c($rad)) / 3.1415926)) / 2 * (2 ^ $2)" | bc -l 2>/dev/null)
    echo "${v%.*}"
}

echo "=== Virent Tile Bundler ==="
echo "Zooms: $MIN_ZOOM-$MAX_ZOOM"
total=0; done=0
for z in $(seq $MIN_ZOOM $MAX_ZOOM); do
    x1=$(lon_to_x $WEST $z); x2=$(lon_to_x $EAST $z)
    y1=$(lat_to_y $NORTH $z); y2=$(lat_to_y $SOUTH $z)
    total=$((total + (x2 - x1 + 1) * (y2 - y1 + 1)))
done
echo "Total: ~$total tiles"
for z in $(seq $MIN_ZOOM $MAX_ZOOM); do
    x1=$(lon_to_x $WEST $z); x2=$(lon_to_x $EAST $z)
    y1=$(lat_to_y $NORTH $z); y2=$(lat_to_y $SOUTH $z)
    for x in $(seq $x1 $x2); do
        for y in $(seq $y1 $y2); do
            d="$TILES_DIR/$z/$x"; mkdir -p "$d"; f="$d/$y.png"
            [ -s "$f" ] && { done=$((done+1)); continue; }
            for s in a b c; do
                curl -sfL --max-time 2 "https://${s}.tile.openstreetmap.org/${z}/${x}/${y}.png" -o "$f" 2>/dev/null && [ -s "$f" ] && break
            done
            [ -s "$f" ] && done=$((done+1)) || rm -f "$f"
            [ $((done % 50)) -eq 0 ] && echo "  $done/$total"
        done
    done
done
echo "Done: $done tiles, $(du -sh $TILES_DIR 2>/dev/null | cut -f1)"
