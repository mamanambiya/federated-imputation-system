#!/bin/bash
set -e

echo "🚀 Starting federated imputation system..."

# Create logs directory
mkdir -p /app/logs

# Wait for database to be ready
echo "⏳ Waiting for database connection..."
python manage.py wait_for_db --timeout=60

# Run database migrations
echo "🔧 Running database migrations..."
python manage.py migrate --noinput

# Collect static files (if needed)
echo "📁 Collecting static files..."
python manage.py collectstatic --noinput --clear || echo "Static files collection skipped"

# Create superuser if it doesn't exist (for development)
echo "👤 Ensuring admin user exists..."
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('✅ Admin user created: admin/admin123')
else:
    print('✅ Admin user already exists')
EOF

# Start the application
echo "🌟 Starting Django development server..."
exec python manage.py runserver 0.0.0.0:8000 