#!/bin/bash
set -e

echo "🔄 Database Restoration Script"
echo "=============================="

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    echo "Available backups:"
    ls -la ./backups/*.sql | tail -5
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "📁 Using backup file: $BACKUP_FILE"
echo "📊 Backup file size: $(du -h "$BACKUP_FILE" | cut -f1)"

echo "⏳ Stopping web services..."
sudo docker-compose stop web celery celery-beat

echo "🗑️ Dropping existing database..."
sudo docker-compose exec db dropdb -U postgres --if-exists federated_imputation

echo "🆕 Creating fresh database..."
sudo docker-compose exec db createdb -U postgres federated_imputation

echo "📥 Restoring database from backup..."
sudo docker-compose exec -T db psql -U postgres -d federated_imputation < "$BACKUP_FILE"

echo "🔧 Running Django migrations..."
sudo docker-compose exec web python manage.py migrate --noinput

echo "📊 Checking restored data..."
echo "Services count:"
sudo docker-compose exec db psql -U postgres -d federated_imputation -c "SELECT count(*) FROM imputation_imputationservice;"

echo "Reference panels count:"
sudo docker-compose exec db psql -U postgres -d federated_imputation -c "SELECT count(*) FROM imputation_referencepanel;"

echo "🚀 Restarting web services..."
sudo docker-compose up -d web celery celery-beat

echo "✅ Database restoration completed!"
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend: http://localhost:8000"