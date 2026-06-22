#!/usr/bin/env bash
# MongoDB backup script
#
# Per Database Design System §35: backup without restore-test is hope, not a system.
# Run daily via cron: 0 2 * * * /path/to/backup-mongodb.sh
#
# Restore test: should be done monthly to a separate cluster.

set -e

# Config
BACKUP_DIR="${BACKUP_DIR:-/backups/mongodb}"
DB_NAME="${DB_NAME:-spark-rentals}"
MONGO_HOST="${MONGO_HOST:-localhost:27017}"
MONGO_USER="${MONGO_USER:-sparkrentals}"
MONGO_PASS="${MONGO_PASS:-changeme}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}"

echo "=== MongoDB Backup ==="
echo "  DB: $DB_NAME"
echo "  Host: $MONGO_HOST"
echo "  Path: $BACKUP_PATH"
echo "  Timestamp: $TIMESTAMP"
echo ""

# Create backup dir
mkdir -p "$BACKUP_DIR"

# Run mongodump
echo "Running mongodump..."
if [ -n "$MONGO_USER" ]; then
    mongodump \
        --host "$MONGO_HOST" \
        --db "$DB_NAME" \
        --username "$MONGO_USER" \
        --password "$MONGO_PASS" \
        --authenticationDatabase admin \
        --out "$BACKUP_PATH" \
        --oplog
else
    mongodump \
        --host "$MONGO_HOST" \
        --db "$DB_NAME" \
        --out "$BACKUP_PATH" \
        --oplog
fi

# Compress
echo "Compressing..."
ARCHIVE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.tar.gz"
tar -czf "$ARCHIVE" -C "$BACKUP_PATH" .

# Remove uncompressed
rm -rf "$BACKUP_PATH"

# Show result
SIZE=$(du -h "$ARCHIVE" | cut -f1)
echo "✓ Backup created: $ARCHIVE ($SIZE)"

# Cleanup old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "${DB_NAME}_*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "✓ Cleanup complete"

# List recent backups
echo ""
echo "Recent backups:"
ls -lh "$BACKUP_DIR"/${DB_NAME}_*.tar.gz 2>/dev/null | tail -5

echo ""
echo "=== Backup complete ==="
