#!/bin/bash

# Ensure Database Script - Automatically restore database if missing
# This script checks if the federated_imputation database exists and restores it if missing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_FILE="$PROJECT_ROOT/backups/federated_imputation_5_services_with_institutions_20250804_133932.sql"

echo "🔍 Checking database status..."

# Function to check if database exists
check_database() {
    sudo docker-compose exec -T db psql -U postgres -lqt | cut -d \| -f 1 | grep -qw federated_imputation
}

# Function to restore database
restore_database() {
    echo "📦 Database 'federated_imputation' not found. Restoring from backup..."

    # Create database if it doesn't exist
    sudo docker-compose exec -T db psql -U postgres -c "CREATE DATABASE federated_imputation;" 2>/dev/null || true

    # Clear existing data and restore
    echo "🗑️  Clearing existing data..."
    sudo docker-compose exec -T db psql -U postgres -d federated_imputation -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" 2>/dev/null || true

    echo "📥 Restoring from backup: $BACKUP_FILE"
    if [ -f "$BACKUP_FILE" ]; then
        sudo docker-compose exec -T db psql -U postgres -d federated_imputation < "$BACKUP_FILE"
        echo "✅ Database restored successfully!"
    else
        echo "❌ Backup file not found: $BACKUP_FILE"
        exit 1
    fi
}

# Function to verify database content
verify_database() {
    echo "🔍 Verifying database content..."
    SERVICE_COUNT=$(sudo docker-compose exec -T db psql -U postgres -d federated_imputation -c "SELECT COUNT(*) FROM imputation_imputationservice;" -t | tr -d ' ')

    if [ "$SERVICE_COUNT" -ge 5 ]; then
        echo "✅ Database verification passed: $SERVICE_COUNT services found"
        return 0
    else
        echo "⚠️  Database verification failed: only $SERVICE_COUNT services found"
        return 1
    fi
}

# Main logic
cd "$PROJECT_ROOT"

if check_database; then
    echo "✅ Database 'federated_imputation' exists"
    
    # Verify content
    if verify_database; then
        echo "✅ Database is healthy"
        exit 0
    else
        echo "⚠️  Database exists but appears empty or corrupted"
        restore_database
        verify_database
    fi
else
    echo "❌ Database 'federated_imputation' does not exist"
    restore_database
    verify_database
fi

echo "🎉 Database check complete!"
