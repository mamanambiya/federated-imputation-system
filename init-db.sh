#!/bin/bash
set -e

echo "🔧 Initializing federated_imputation database..."

# Create the database if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    SELECT 'CREATE DATABASE federated_imputation'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'federated_imputation')\gexec
EOSQL

echo "✅ Database federated_imputation is ready!"

# Grant permissions
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname=federated_imputation <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE federated_imputation TO $POSTGRES_USER;
EOSQL

echo "✅ Database permissions granted!" 