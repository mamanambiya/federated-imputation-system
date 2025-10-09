#!/bin/bash
###############################################################################
# Rollback Script: Docker Compose → Manual Containers
# Purpose: Restore manual containers if migration fails
# Created: 2025-10-09
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${YELLOW}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

BACKUP_DIR=${1:-"./backups/migration_latest"}

if [ ! -d "$BACKUP_DIR" ]; then
    error "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

log "Rolling back from: $BACKUP_DIR"

# Stop docker-compose services
log "Stopping docker-compose services..."
sudo docker-compose -f docker-compose.production.yml down || true
success "Docker compose services stopped"

# Restart manual containers using their backed-up configurations
log "Restarting manual containers..."

# Read JWT_SECRET from .env
source .env

# Recreate containers
log "Recreating API Gateway..."
docker run -d --name federated-imputation-central_api-gateway_1 \
  --network federated-imputation-central_microservices-network \
  -p 8000:8000 \
  -e REDIS_URL="redis://redis:6379" \
  -e JWT_SECRET="$JWT_SECRET" \
  -e JWT_ALGORITHM="HS256" \
  -e USER_SERVICE_URL="http://user-service:8001" \
  -e SERVICE_REGISTRY_URL="http://service-registry:8002" \
  -e JOB_PROCESSOR_URL="http://job-processor:8003" \
  -e FILE_MANAGER_URL="http://file-manager:8004" \
  -e MONITORING_URL="http://monitoring:8006" \
  --restart unless-stopped \
  federated-imputation-api-gateway:latest

log "Recreating User Service..."
docker run -d --name federated-imputation-central_user-service_1 \
  --network federated-imputation-central_default \
  -e DATABASE_URL="postgresql://postgres:$POSTGRES_PASSWORD@db:5432/user_management_db" \
  -e JWT_SECRET="$JWT_SECRET" \
  -e JWT_ALGORITHM="HS256" \
  --restart unless-stopped \
  federated-imputation-central_user-service:latest

docker network connect --alias user-service \
  federated-imputation-central_microservices-network \
  federated-imputation-central_user-service_1

log "Recreating Service Registry..."
docker run -d --name federated-imputation-central_service-registry_1 \
  --network federated-imputation-central_default \
  -e DATABASE_URL="postgresql://postgres:$POSTGRES_PASSWORD@db:5432/service_registry_db" \
  --restart unless-stopped \
  federated-imputation-service-registry:latest

docker network connect --alias service-registry \
  federated-imputation-central_microservices-network \
  federated-imputation-central_service-registry_1

log "Recreating Job Processor..."
docker run -d --name federated-imputation-central_job-processor_1 \
  --network federated-imputation-central_default \
  -p 8003:8003 \
  -e DATABASE_URL="postgresql://postgres:$POSTGRES_PASSWORD@db:5432/federated_imputation" \
  -e REDIS_URL="redis://redis:6379" \
  -e USER_SERVICE_URL="http://user-service:8001" \
  -e SERVICE_REGISTRY_URL="http://service-registry:8002" \
  -e FILE_MANAGER_URL="http://file-manager:8004" \
  -e JWT_SECRET="$JWT_SECRET" \
  -e JWT_ALGORITHM="HS256" \
  --restart unless-stopped \
  federated-imputation-job-processor:latest

docker network connect --alias job-processor \
  federated-imputation-central_microservices-network \
  federated-imputation-central_job-processor_1

log "Recreating File Manager..."
docker run -d --name federated-imputation-central_file-manager_1 \
  --network federated-imputation-central_default \
  -e DATABASE_URL="postgresql://postgres:$POSTGRES_PASSWORD@db:5432/file_management_db" \
  -v /home/ubuntu/federated-imputation-central/microservices/file-manager/uploads:/app/uploads \
  --restart unless-stopped \
  federated-imputation-file-manager:latest

docker network connect --alias file-manager \
  federated-imputation-central_microservices-network \
  federated-imputation-central_file-manager_1

log "Recreating Monitoring..."
docker run -d --name federated-imputation-central_monitoring_1 \
  --network federated-imputation-central_default \
  -e DATABASE_URL="postgresql://postgres:$POSTGRES_PASSWORD@db:5432/federated_imputation" \
  -e JOB_PROCESSOR_URL="http://job-processor:8003" \
  -e SERVICE_REGISTRY_URL="http://service-registry:8002" \
  --restart unless-stopped \
  federated-imputation-monitoring:latest

docker network connect --alias monitoring \
  federated-imputation-central_microservices-network \
  federated-imputation-central_monitoring_1

log "Recreating Frontend..."
docker run -d --name frontend-updated \
  -p 3000:80 \
  -v /home/ubuntu/federated-imputation-central/frontend/build:/usr/share/nginx/html:ro \
  -v /home/ubuntu/federated-imputation-central/frontend/nginx-react.conf:/etc/nginx/conf.d/default.conf:ro \
  --restart unless-stopped \
  nginx:alpine

success "All containers recreated"

log "Waiting for services to start (30 seconds)..."
sleep 30

log "Testing services..."
if curl -sf http://localhost:8000/api/services/ > /dev/null; then
    success "API responding - rollback successful"
else
    error "API not responding - check logs"
fi

echo ""
echo "Rollback complete. Check service status with:"
echo "  docker ps"
echo "  curl http://localhost:8000/api/services/"
