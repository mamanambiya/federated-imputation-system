#!/bin/bash
#
# Database Restoration Script
# Safely restores database from backups
#
# Usage: ./restore_backup.sh <backup_prefix>
# Example: ./restore_backup.sh auto_backup_20251007_205900
#

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_prefix>"
    echo ""
    echo "Available backups:"
    ls -1 /home/ubuntu/federated-imputation-central/backups/*_postgres.tar.gz 2>/dev/null | \
        xargs -n1 basename | \
        sed 's/_postgres.tar.gz//' | \
        sort -r | \
        head -10
    exit 1
fi

BACKUP_PREFIX="$1"
BACKUP_DIR="/home/ubuntu/federated-imputation-central/backups"
BACKUP_FILE="$BACKUP_DIR/${BACKUP_PREFIX}_postgres.tar.gz"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "🔄 Database Restoration Process"
echo "================================"
echo "Backup: $BACKUP_PREFIX"
echo "File: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
echo ""

# Safety check
read -p "⚠️  This will REPLACE the current database. Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Restoration cancelled."
    exit 0
fi

# 1. Create safety backup of current state
echo "📦 Creating safety backup of current state..."
SAFETY_BACKUP="current_before_restore_$(date +%Y%m%d_%H%M%S)"
sudo docker run --rm \
  -v federated-imputation-central_postgres_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf "/backup/${SAFETY_BACKUP}_postgres.tar.gz" -C /data .
echo "✓ Safety backup created: ${SAFETY_BACKUP}_postgres.tar.gz"

# 2. Stop PostgreSQL
echo "⏸️  Stopping PostgreSQL..."
sudo docker-compose -f /home/ubuntu/federated-imputation-central/docker-compose.microservices.yml stop postgres 2>/dev/null || \
    sudo docker stop federated-imputation-central_postgres_1 2>/dev/null || true

# 3. Clear current volume
echo "🗑️  Clearing current database..."
sudo docker run --rm \
  -v federated-imputation-central_postgres_data:/data \
  alpine sh -c "rm -rf /data/*"

# 4. Restore from backup
echo "📥 Restoring database from backup..."
sudo docker run --rm \
  -v federated-imputation-central_postgres_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar xzf "/backup/${BACKUP_PREFIX}_postgres.tar.gz" -C /data

# 5. Fix directory structure if needed
echo "🔧 Fixing directory structure..."
sudo docker run --rm \
  -v federated-imputation-central_postgres_data:/volume \
  alpine sh -c "if [ -d /volume/data ]; then mv /volume/data/* /volume/ && rm -rf /volume/data; fi"

# 6. Restart PostgreSQL
echo "▶️  Starting PostgreSQL..."
sudo docker-compose -f /home/ubuntu/federated-imputation-central/docker-compose.microservices.yml start postgres 2>/dev/null || \
    sudo docker start federated-imputation-central_postgres_1

sleep 10

# 7. Verify restoration
echo "✓ Verifying restoration..."
DATABASE_COUNT=$(sudo docker exec federated-imputation-central_postgres_1 psql -U postgres -c "\l" 2>/dev/null | grep -c "postgres" || echo "0")

if [ "$DATABASE_COUNT" -gt 0 ]; then
    echo ""
    echo "✅ Database restored successfully!"
    echo ""
    echo "📊 Restored Databases:"
    sudo docker exec federated-imputation-central_postgres_1 psql -U postgres -c "\l" 2>/dev/null | grep -E "Name|-----|federated"
else
    echo "❌ Verification failed. Database may not be ready yet."
    echo "Wait a few moments and check manually with: docker logs federated-imputation-central_postgres_1"
fi

echo ""
echo "Safety backup of previous state saved as: ${SAFETY_BACKUP}_postgres.tar.gz"
