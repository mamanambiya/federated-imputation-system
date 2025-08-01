#!/bin/bash

set -e

echo "Bootstrapping Federated Imputation System..."

# Wait for database to be ready
echo "Waiting for database to be ready..."
until sudo docker-compose exec -T db psql -U postgres -d federated_imputation -c '\q' 2>/dev/null; do
    echo "Database is unavailable - sleeping"
    sleep 1
done

echo "Database is ready!"

# Create database if it doesn't exist
sudo docker-compose exec -T db psql -U postgres -c "CREATE DATABASE federated_imputation;" 2>/dev/null || echo "Database already exists"

echo "Running Django setup in minimal Python container..."

# Create a temporary Django container to run migrations
sudo docker run --rm \
    --network federated-imputation-central_default \
    -e DB_NAME=federated_imputation \
    -e DB_USER=postgres \
    -e DB_PASSWORD=postgres \
    -e DB_HOST=federated-imputation-central_db_1 \
    -e DB_PORT=5432 \
    -e SECRET_KEY=django-insecure-dev-key \
    -e DEBUG=1 \
    -v $(pwd):/app \
    -w /app \
    python:3.11-slim bash -c "
        pip install django psycopg2-binary python-decouple &&
        python manage.py migrate &&
        echo 'from django.contrib.auth.models import User; User.objects.create_superuser(\"admin\", \"admin@example.com\", \"admin\")' | python manage.py shell
    "

echo "Bootstrap complete!" 