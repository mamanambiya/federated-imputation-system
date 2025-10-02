#!/bin/bash

# Deployment script for microservices architecture
# Handles building, deploying, and validating the entire system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.microservices.yml"
PROJECT_NAME="federated-imputation"
ENVIRONMENT="${1:-development}"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed"
        exit 1
    fi
    success "Docker is available"
    
    # Check Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1; then
        error "Docker Compose is not installed"
        exit 1
    fi
    success "Docker Compose is available"
    
    # Check if compose file exists
    if [ ! -f "$COMPOSE_FILE" ]; then
        error "Compose file $COMPOSE_FILE not found"
        exit 1
    fi
    success "Compose file found"
    
    # Check available disk space (need at least 5GB)
    available_space=$(df . | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt 5242880 ]; then  # 5GB in KB
        warning "Low disk space. At least 5GB recommended for deployment"
    else
        success "Sufficient disk space available"
    fi
    
    # Check available memory (need at least 4GB)
    available_memory=$(free -m | awk 'NR==2{print $7}')
    if [ "$available_memory" -lt 4096 ]; then
        warning "Low available memory. At least 4GB recommended"
    else
        success "Sufficient memory available"
    fi
}

# Setup environment
setup_environment() {
    log "Setting up environment for $ENVIRONMENT..."
    
    # Create environment file if it doesn't exist
    if [ ! -f ".env.microservices" ]; then
        log "Creating environment configuration..."
        cat > .env.microservices << EOF
# Environment Configuration
ENVIRONMENT=$ENVIRONMENT

# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=federated_imputation

# Redis Configuration
REDIS_PASSWORD=

# SMTP Configuration (optional)
SMTP_HOST=localhost
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
SMTP_FROM_EMAIL=noreply@federated-imputation.org

# Security
JWT_SECRET_KEY=$(openssl rand -hex 32)
API_RATE_LIMIT=100

# Monitoring
ENABLE_METRICS=true
ENABLE_LOGGING=true

# File Storage
MAX_FILE_SIZE_MB=500
STORAGE_RETENTION_DAYS=30
EOF
        success "Environment file created"
    else
        success "Environment file already exists"
    fi
    
    # Set environment variables
    export COMPOSE_PROJECT_NAME="$PROJECT_NAME"
    export COMPOSE_FILE="$COMPOSE_FILE"
}

# Build services
build_services() {
    log "Building microservices..."
    
    # Build all services
    docker-compose -f "$COMPOSE_FILE" build --parallel
    success "All services built successfully"
}

# Deploy infrastructure
deploy_infrastructure() {
    log "Deploying infrastructure services..."
    
    # Start databases and Redis first
    docker-compose -f "$COMPOSE_FILE" up -d postgres redis
    
    # Wait for databases to be ready
    log "Waiting for databases to be ready..."
    sleep 30
    
    # Check database health
    for i in {1..30}; do
        if docker-compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
            success "PostgreSQL is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            error "PostgreSQL failed to start"
            exit 1
        fi
        sleep 2
    done
    
    # Check Redis health
    for i in {1..30}; do
        if docker-compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping | grep -q "PONG"; then
            success "Redis is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            error "Redis failed to start"
            exit 1
        fi
        sleep 2
    done
}

# Deploy core services
deploy_core_services() {
    log "Deploying core microservices..."
    
    # Start core services in order
    docker-compose -f "$COMPOSE_FILE" up -d user-service service-registry
    
    # Wait for core services
    sleep 20
    
    # Verify core services
    for service in user-service service-registry; do
        for i in {1..30}; do
            if curl -f "http://localhost:$(docker-compose -f "$COMPOSE_FILE" port "$service" 8001 | cut -d: -f2)/health" >/dev/null 2>&1 || \
               curl -f "http://localhost:$(docker-compose -f "$COMPOSE_FILE" port "$service" 8002 | cut -d: -f2)/health" >/dev/null 2>&1; then
                success "$service is ready"
                break
            fi
            if [ $i -eq 30 ]; then
                error "$service failed to start"
                exit 1
            fi
            sleep 2
        done
    done
}

# Deploy application services
deploy_application_services() {
    log "Deploying application services..."
    
    # Start application services
    docker-compose -f "$COMPOSE_FILE" up -d job-processor file-manager notification monitoring
    
    # Wait for application services
    sleep 30
    
    # Verify application services
    for service in job-processor file-manager notification monitoring; do
        port=""
        case $service in
            job-processor) port="8003" ;;
            file-manager) port="8004" ;;
            notification) port="8005" ;;
            monitoring) port="8006" ;;
        esac
        
        for i in {1..30}; do
            if curl -f "http://localhost:$port/health" >/dev/null 2>&1; then
                success "$service is ready"
                break
            fi
            if [ $i -eq 30 ]; then
                error "$service failed to start"
                exit 1
            fi
            sleep 2
        done
    done
}

# Deploy gateway and frontend
deploy_gateway_frontend() {
    log "Deploying API Gateway and Frontend..."
    
    # Start API Gateway
    docker-compose -f "$COMPOSE_FILE" up -d api-gateway
    
    # Wait for API Gateway
    sleep 15
    
    # Verify API Gateway
    for i in {1..30}; do
        if curl -f "http://localhost:8000/health" >/dev/null 2>&1; then
            success "API Gateway is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            error "API Gateway failed to start"
            exit 1
        fi
        sleep 2
    done
    
    # Start Frontend
    docker-compose -f "$COMPOSE_FILE" up -d frontend
    
    # Wait for Frontend
    sleep 20
    
    # Verify Frontend
    for i in {1..30}; do
        if curl -f "http://localhost:3000/health" >/dev/null 2>&1; then
            success "Frontend is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            error "Frontend failed to start"
            exit 1
        fi
        sleep 2
    done
}

# Deploy workers
deploy_workers() {
    log "Deploying background workers..."
    
    # Start Celery workers
    docker-compose -f "$COMPOSE_FILE" up -d celery-worker
    
    success "Background workers deployed"
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring infrastructure..."
    
    # Start monitoring stack if available
    if docker-compose -f "$COMPOSE_FILE" config --services | grep -q "prometheus"; then
        docker-compose -f "$COMPOSE_FILE" up -d prometheus grafana
        success "Monitoring stack deployed"
    else
        warning "Monitoring stack not configured in compose file"
    fi
}

# Initialize data
initialize_data() {
    log "Initializing system data..."
    
    # Create default admin user
    docker-compose -f "$COMPOSE_FILE" exec -T user-service python -c "
from main import SessionLocal, User, UserRole
from sqlalchemy.orm import Session
import hashlib

db = SessionLocal()

# Check if admin user exists
admin = db.query(User).filter(User.username == 'admin').first()
if not admin:
    # Create admin user
    admin = User(
        username='admin',
        email='admin@federated-imputation.org',
        password_hash=hashlib.sha256('admin123'.encode()).hexdigest(),
        is_active=True,
        is_admin=True
    )
    db.add(admin)
    db.commit()
    print('Admin user created')
else:
    print('Admin user already exists')

db.close()
" 2>/dev/null || warning "Failed to create admin user"
    
    # Initialize reference panels
    docker-compose -f "$COMPOSE_FILE" exec -T service-registry python -c "
from main import SessionLocal, ReferencePanel
from datetime import datetime

db = SessionLocal()

# Check if reference panels exist
if db.query(ReferencePanel).count() == 0:
    # Create default reference panels
    panels = [
        ReferencePanel(
            name='1000 Genomes Phase 3',
            description='1000 Genomes Project Phase 3 reference panel',
            build='hg38',
            population='ALL',
            sample_count=2504,
            variant_count=84700000,
            is_public=True,
            created_at=datetime.utcnow()
        ),
        ReferencePanel(
            name='TOPMed Freeze 8',
            description='TOPMed Freeze 8 reference panel',
            build='hg38',
            population='ALL',
            sample_count=97256,
            variant_count=308107085,
            is_public=True,
            created_at=datetime.utcnow()
        )
    ]
    
    for panel in panels:
        db.add(panel)
    
    db.commit()
    print('Reference panels created')
else:
    print('Reference panels already exist')

db.close()
" 2>/dev/null || warning "Failed to initialize reference panels"
    
    success "System data initialized"
}

# Validate deployment
validate_deployment() {
    log "Validating deployment..."
    
    # Run comprehensive tests
    if [ -f "scripts/test-microservices.sh" ]; then
        chmod +x scripts/test-microservices.sh
        if ./scripts/test-microservices.sh; then
            success "All validation tests passed"
        else
            error "Some validation tests failed"
            return 1
        fi
    else
        warning "Test script not found, skipping validation"
    fi
}

# Show deployment status
show_status() {
    log "Deployment Status:"
    
    echo
    echo "🌐 Service URLs:"
    echo "  Frontend:        http://localhost:3000"
    echo "  API Gateway:     http://localhost:8000"
    echo "  User Service:    http://localhost:8001"
    echo "  Service Registry: http://localhost:8002"
    echo "  Job Processor:   http://localhost:8003"
    echo "  File Manager:    http://localhost:8004"
    echo "  Notification:    http://localhost:8005"
    echo "  Monitoring:      http://localhost:8006"
    
    echo
    echo "📊 System Status:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    echo
    echo "💾 Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    
    echo
    echo "🔐 Default Credentials:"
    echo "  Username: admin"
    echo "  Password: admin123"
    echo "  (Please change these in production!)"
}

# Cleanup function
cleanup() {
    if [ "$?" -ne 0 ]; then
        error "Deployment failed. Cleaning up..."
        docker-compose -f "$COMPOSE_FILE" down
    fi
}

# Main deployment function
main() {
    log "Starting microservices deployment for $ENVIRONMENT environment..."
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Run deployment steps
    check_prerequisites
    setup_environment
    build_services
    deploy_infrastructure
    deploy_core_services
    deploy_application_services
    deploy_gateway_frontend
    deploy_workers
    setup_monitoring
    initialize_data
    
    # Validate deployment
    if validate_deployment; then
        success "🎉 Microservices deployment completed successfully!"
        show_status
    else
        error "❌ Deployment validation failed"
        exit 1
    fi
    
    # Remove trap
    trap - EXIT
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "status")
        show_status
        ;;
    "test")
        validate_deployment
        ;;
    "cleanup")
        log "Cleaning up deployment..."
        docker-compose -f "$COMPOSE_FILE" down -v
        docker system prune -f
        success "Cleanup completed"
        ;;
    *)
        echo "Usage: $0 [deploy|status|test|cleanup] [environment]"
        echo "  deploy   - Deploy the microservices (default)"
        echo "  status   - Show deployment status"
        echo "  test     - Run validation tests"
        echo "  cleanup  - Clean up deployment"
        exit 1
        ;;
esac
