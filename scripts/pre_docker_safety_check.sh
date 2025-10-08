#!/bin/bash
#
# Pre-Docker Safety Check
# Run this before docker-compose operations to prevent data loss
#
# Add to your workflow:
#   ./scripts/pre_docker_safety_check.sh && docker-compose up -d
#

set -e

BACKUP_DIR="/home/ubuntu/federated-imputation-central/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🛡️  Pre-Docker Safety Check"
echo "=========================="

# Check if PostgreSQL volume exists and has data
if sudo docker volume inspect federated-imputation-central_postgres_data &>/dev/null; then
    VOLUME_SIZE=$(sudo docker run --rm -v federated-imputation-central_postgres_data:/data alpine du -sh /data 2>/dev/null | cut -f1)

    if [ "$VOLUME_SIZE" != "0" ] && [ "$VOLUME_SIZE" != "" ]; then
        echo "⚠️  Existing database detected (Size: $VOLUME_SIZE)"
        echo ""
        echo "🔒 Creating automatic backup before proceeding..."

        # Run automatic backup
        /home/ubuntu/federated-imputation-central/scripts/auto_backup_database.sh

        echo ""
        echo "✅ Backup completed. Safe to proceed with Docker operations."
    else
        echo "✓ No existing data detected. Safe to proceed."
    fi
else
    echo "✓ No existing volume. This is a fresh installation."
fi

echo ""
echo "Last 5 backups:"
ls -lth "$BACKUP_DIR"/*_postgres.tar.gz 2>/dev/null | head -5 | awk '{print "  -", $9, "("$5")"}'
echo ""
