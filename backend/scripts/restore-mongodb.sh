#!/usr/bin/env bash
# MongoDB restore script
#
# Per Database Design System §35: backup without restore-test is hope, not a system.
# Test restore monthly to a separate cluster.
#
# Usage: ./restore-mongodb.sh /path/to/backup.tar.gz

set -e

ARCHIVE="${1:-}"
if [ -z "$ARCHIVE" ]; then
    echo "Usage: $0 <backup-archive.tar.gz>"
    echo ""
    echo "Available backups:"
    ls -lh /backups/mongodb/*.tar.gz 2>/dev/null || echo "  No backups found in /backups/mongodb/"
    exit 1
fi

if [ ! -f "$ARCHIVE" ]; then
    echo "ERROR: File not found: $ARCHIVE"
    exit 1
fi

# Config
DB_NAME="${DB_NAME:-spark-rentals}"
MONGO_HOST="${MONGO_HOST:-localhost:27017}"
MONGO_USER="${MONGO_USER:-sparkrentals}"
MONGO_PASS="${MONGO_PASS:-changeme}"
TEMP_DIR=$(mktemp -d)

echo "=== MongoDB Restore ==="
echo "  Archive: $ARCHIVE"
echo "  DB: $DB_NAME"
echo "  Host: $MONGO_HOST"
echo "  Temp: $TEMP_DIR"
echo ""

# Confirm
read -p "This will OVERWRITE existing data in '$DB_NAME'. Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Extract
echo "Extracting archive..."
tar -xzf "$ARCHIVE" -C "$TEMP_DIR"

# Find dump dir
DUMP_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d | tail -1)
echo "Dump directory: $DUMP_DIR"

# Restore
echo "Restoring..."
if [ -n "$MONGO_USER" ]; then
    mongorestore \
        --host "$MONGO_HOST" \
        --db "$DB_NAME" \
        --username "$MONGO_USER" \
        --password "$MONGO_PASS" \
        --authenticationDatabase admin \
        --drop \
        "$DUMP_DIR/$DB_NAME"
else
    mongorestore \
        --host "$MONGO_HOST" \
        --db "$DB_NAME" \
        --drop \
        "$DUMP_DIR/$DB_NAME"
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Restore complete"
echo ""
echo "Verify by running:"
echo "  mongosh $MONGO_HOST/$DB_NAME --eval 'db.users.countDocuments()'"
