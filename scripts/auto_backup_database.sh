#!/bin/bash
#
# Automated Database Backup Script
# Prevents data loss by creating backups before any destructive operations
#
# Usage: Run this automatically via cron or before docker operations
#

set -e

BACKUP_DIR="/home/ubuntu/federated-imputation-central/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PREFIX="auto_backup_${TIMESTAMP}"

echo "🔒 Starting automatic database backup at $(date)"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# 1. Backup PostgreSQL Volume (CRITICAL - Contains all data)
echo "📦 Backing up PostgreSQL volume..."
sudo docker run --rm \
  -v federated-imputation-central_postgres_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf "/backup/${BACKUP_PREFIX}_postgres.tar.gz" -C /data .

POSTGRES_SIZE=$(du -h "$BACKUP_DIR/${BACKUP_PREFIX}_postgres.tar.gz" | cut -f1)
echo "✓ PostgreSQL volume backed up: $POSTGRES_SIZE"

# 2. Backup Redis Volume (Optional but recommended)
echo "📦 Backing up Redis volume..."
sudo docker run --rm \
  -v federated-imputation-central_redis_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf "/backup/${BACKUP_PREFIX}_redis.tar.gz" -C /data . 2>/dev/null || echo "⚠️  Redis backup skipped (volume may not exist)"

# 3. Create SQL dumps for extra safety
echo "📦 Creating SQL dumps..."
if sudo docker ps --format '{{.Names}}' | grep -q postgres; then
    # Dump all databases
    sudo docker exec federated-imputation-central_postgres_1 pg_dumpall -U postgres | gzip > "$BACKUP_DIR/${BACKUP_PREFIX}_all_databases.sql.gz" 2>/dev/null || echo "⚠️  SQL dump failed"
fi

# 4. Record system state
echo "📝 Recording system state..."
cat > "$BACKUP_DIR/${BACKUP_PREFIX}_state.txt" << EOF
Backup Created: $(date)
Hostname: $(hostname)
Docker Containers:
$(sudo docker ps --format 'table {{.Names}}\t{{.Status}}')

Docker Volumes:
$(sudo docker volume ls | grep federated)

Git Status:
$(cd /home/ubuntu/federated-imputation-central && git status --short 2>/dev/null || echo "Not a git repository")
EOF

# 5. Clean up old backups (keep last 30 days)
echo "🧹 Cleaning up old backups..."
find "$BACKUP_DIR" -name "auto_backup_*" -type f -mtime +30 -delete 2>/dev/null || true

# 6. Verify backups
echo "✓ Verifying backups..."
if [ ! -f "$BACKUP_DIR/${BACKUP_PREFIX}_postgres.tar.gz" ]; then
    echo "❌ ERROR: PostgreSQL backup verification failed!"
    exit 1
fi

TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo ""
echo "✅ Backup completed successfully!"
echo "📊 Backup Summary:"
echo "   - PostgreSQL Volume: $POSTGRES_SIZE"
echo "   - Location: $BACKUP_DIR"
echo "   - Total Backup Size: $TOTAL_SIZE"
echo "   - Backups are kept for 30 days"
echo ""
echo "To restore this backup:"
echo "   ./scripts/restore_backup.sh ${BACKUP_PREFIX}"
