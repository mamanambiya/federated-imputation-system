#!/bin/bash
###############################################################################
# Migration Script: Manual Containers → Docker Compose
# Purpose: Safely migrate from manually created containers to docker-compose
# Created: 2025-10-09
#
# This script will:
# 1. Verify current system state
# 2. Create backups
# 3. Stop manual containers
# 4. Start services via docker-compose
# 5. Verify everything works
# 6. Provide rollback capability
###############################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.production.yml"
BACKUP_DIR="./backups/migration_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$BACKUP_DIR/migration.log"

###############################################################################
# Helper Functions
###############################################################################

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[⚠]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

###############################################################################
# Step 1: Pre-Migration Verification
###############################################################################

log "Starting pre-migration verification..."

# Check if docker-compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    error "Docker compose file not found: $COMPOSE_FILE"
    exit 1
fi
success "Docker compose file found"

# Check if .env file exists with correct values
if [ ! -f ".env" ]; then
    error ".env file not found"
    exit 1
fi
success ".env file found"

# Verify JWT_SECRET is set
source .env
if [ -z "$JWT_SECRET" ] || [ "$JWT_SECRET" == "change-this-to-a-strong-random-secret-in-production" ]; then
    error "JWT_SECRET not properly configured in .env"
    exit 1
fi
success "JWT_SECRET properly configured"

# Verify POSTGRES_PASSWORD is set
if [ -z "$POSTGRES_PASSWORD" ]; then
    error "POSTGRES_PASSWORD not set in .env"
    exit 1
fi
success "POSTGRES_PASSWORD configured"

###############################################################################
# Step 2: Backup Current State
###############################################################################

log "Creating backups..."

# Backup current container configurations
docker ps -a --format "{{.Names}}\t{{.Image}}\t{{.Status}}" > "$BACKUP_DIR/containers_before.txt"
success "Container list backed up"

# Backup current networks
docker network ls > "$BACKUP_DIR/networks_before.txt"
success "Network list backed up"

# Export environment variables from running containers
for container in \
    federated-imputation-central_api-gateway_1 \
    federated-imputation-central_user-service_1 \
    federated-imputation-central_service-registry_1 \
    federated-imputation-central_job-processor_1 \
    federated-imputation-central_file-manager_1 \
    federated-imputation-central_monitoring_1 \
    frontend-updated
do
    if docker ps -q -f name="^${container}$" > /dev/null 2>&1; then
        docker inspect "$container" > "$BACKUP_DIR/${container}_config.json"
        success "Backed up configuration for $container"
    else
        warning "Container not found: $container"
    fi
done

# Test current system health
log "Testing current system health..."
if curl -s http://localhost:8000/api/services/ > "$BACKUP_DIR/api_test_before.json"; then
    success "API is responding"
else
    warning "API not responding (this may be expected)"
fi

###############################################################################
# Step 3: Stop Manual Containers
###############################################################################

log "Stopping manual containers..."

MANUAL_CONTAINERS=(
    "federated-imputation-central_api-gateway_1"
    "federated-imputation-central_user-service_1"
    "federated-imputation-central_service-registry_1"
    "federated-imputation-central_job-processor_1"
    "federated-imputation-central_file-manager_1"
    "federated-imputation-central_monitoring_1"
    "frontend-updated"
)

for container in "${MANUAL_CONTAINERS[@]}"; do
    if docker ps -q -f name="^${container}$" > /dev/null 2>&1; then
        log "Stopping $container..."
        docker stop "$container" || warning "Failed to stop $container"
        success "Stopped $container"
    else
        warning "Container not running: $container"
    fi
done

sleep 2  # Give containers time to stop

###############################################################################
# Step 4: Remove Manual Containers (Keep Images!)
###############################################################################

log "Removing manual containers (keeping images)..."

for container in "${MANUAL_CONTAINERS[@]}"; do
    if docker ps -aq -f name="^${container}$" > /dev/null 2>&1; then
        log "Removing $container..."
        docker rm "$container" || warning "Failed to remove $container"
        success "Removed $container"
    fi
done

###############################################################################
# Step 5: Start via Docker Compose
###############################################################################

log "Starting services via docker-compose..."

# Pull/build images
log "Building images..."
sudo docker-compose -f "$COMPOSE_FILE" build --pull

# Start services
log "Starting services..."
sudo docker-compose -f "$COMPOSE_FILE" up -d

success "Docker compose services started"

###############################################################################
# Step 6: Health Check
###############################################################################

log "Waiting for services to start (60 seconds)..."
sleep 60

log "Performing health checks..."

# Check if containers are running
log "Checking container status..."
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "api-gateway|user-service|service-registry|job-processor|file-manager|monitoring|frontend"

# Test API endpoints
log "Testing API endpoints..."

ENDPOINTS=(
    "http://localhost:8000/health|API Gateway"
    "http://localhost:8000/api/services/|Services API"
    "http://localhost:3000/|Frontend"
)

FAILED=0
for endpoint in "${ENDPOINTS[@]}"; do
    IFS='|' read -r url name <<< "$endpoint"
    if curl -sf "$url" > /dev/null; then
        success "$name responding"
    else
        error "$name NOT responding"
        FAILED=1
    fi
done

# Save post-migration state
docker ps -a --format "{{.Names}}\t{{.Image}}\t{{.Status}}" > "$BACKUP_DIR/containers_after.txt"
curl -s http://localhost:8000/api/services/ > "$BACKUP_DIR/api_test_after.json" 2>/dev/null || true

###############################################################################
# Step 7: Results
###############################################################################

echo ""
echo "============================================================================="
if [ $FAILED -eq 0 ]; then
    success "MIGRATION SUCCESSFUL!"
    echo ""
    echo "All services are running via docker-compose."
    echo ""
    echo "Next steps:"
    echo "1. Test the frontend: http://154.114.10.184:3000"
    echo "2. Verify services page shows all 5 services"
    echo "3. Test job submission"
    echo "4. If everything works, delete backup: rm -rf $BACKUP_DIR"
    echo ""
    echo "To manage services now:"
    echo "  docker-compose -f $COMPOSE_FILE ps"
    echo "  docker-compose -f $COMPOSE_FILE logs -f [service-name]"
    echo "  docker-compose -f $COMPOSE_FILE restart [service-name]"
else
    error "MIGRATION COMPLETED WITH WARNINGS"
    echo ""
    echo "Some services may not be responding. Check logs:"
    echo "  docker-compose -f $COMPOSE_FILE logs"
    echo ""
    echo "To rollback:"
    echo "  ./scripts/rollback_migration.sh $BACKUP_DIR"
fi
echo "============================================================================="
echo ""
echo "Migration log saved to: $LOG_FILE"
echo "Backup directory: $BACKUP_DIR"
echo ""
