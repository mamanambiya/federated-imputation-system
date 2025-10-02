#!/bin/bash
#
# Setup automated backup cron jobs
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup_automation.sh"

echo "📅 Setting up automated backup cron jobs..."

# Check if backup script exists
if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "❌ Backup script not found: $BACKUP_SCRIPT"
    exit 1
fi

# Make backup script executable
chmod +x "$BACKUP_SCRIPT"

# Create cron job (daily at 2 AM)
CRON_JOB="0 2 * * * $BACKUP_SCRIPT >> /home/ubuntu/federated-imputation-central/backups/logs/cron.log 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$BACKUP_SCRIPT"; then
    echo "⚠️  Backup cron job already exists"
else
    # Add cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ Backup cron job added successfully"
fi

echo "
📋 Cron job details:
   Schedule: Daily at 2:00 AM
   Script: $BACKUP_SCRIPT
   Logs: /home/ubuntu/federated-imputation-central/backups/logs/cron.log

To view cron jobs:
   crontab -l

To remove cron job:
   crontab -e
"
