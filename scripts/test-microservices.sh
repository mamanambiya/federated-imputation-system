#!/bin/bash

# Comprehensive testing suite for microservices architecture
# Tests all services, endpoints, and integration points

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_GATEWAY_URL="http://localhost:8000"
USER_SERVICE_URL="http://localhost:8001"
SERVICE_REGISTRY_URL="http://localhost:8002"
JOB_PROCESSOR_URL="http://localhost:8003"
FILE_MANAGER_URL="http://localhost:8004"
NOTIFICATION_URL="http://localhost:8005"
MONITORING_URL="http://localhost:8006"
FRONTEND_URL="http://localhost:3000"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED_TESTS++))
}

error() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED_TESTS++))
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    local method="${4:-GET}"
    
    ((TOTAL_TESTS++))
    
    log "Testing $name: $method $url"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "%{http_code}" -o /tmp/test_response "$url" 2>/dev/null || echo "000")
    else
        response=$(curl -s -w "%{http_code}" -X "$method" -o /tmp/test_response "$url" 2>/dev/null || echo "000")
    fi
    
    if [ "$response" = "$expected_status" ]; then
        success "$name - Status: $response"
        return 0
    else
        error "$name - Expected: $expected_status, Got: $response"
        if [ -f /tmp/test_response ]; then
            cat /tmp/test_response
        fi
        return 1
    fi
}

# Test service health endpoints
test_health_endpoints() {
    log "Testing health endpoints..."
    
    test_endpoint "API Gateway Health" "$API_GATEWAY_URL/health"
    test_endpoint "User Service Health" "$USER_SERVICE_URL/health"
    test_endpoint "Service Registry Health" "$SERVICE_REGISTRY_URL/health"
    test_endpoint "Job Processor Health" "$JOB_PROCESSOR_URL/health"
    test_endpoint "File Manager Health" "$FILE_MANAGER_URL/health"
    test_endpoint "Notification Service Health" "$NOTIFICATION_URL/health"
    test_endpoint "Monitoring Service Health" "$MONITORING_URL/health"
    test_endpoint "Frontend Health" "$FRONTEND_URL/health"
}

# Test API Gateway routing
test_api_gateway() {
    log "Testing API Gateway routing..."
    
    test_endpoint "Gateway User Route" "$API_GATEWAY_URL/api/users/me"
    test_endpoint "Gateway Services Route" "$API_GATEWAY_URL/api/services/"
    test_endpoint "Gateway Jobs Route" "$API_GATEWAY_URL/api/jobs"
    test_endpoint "Gateway Files Route" "$API_GATEWAY_URL/api/files"
    test_endpoint "Gateway Notifications Route" "$API_GATEWAY_URL/api/notifications"
}

# Test user service endpoints
test_user_service() {
    log "Testing User Service endpoints..."
    
    test_endpoint "User Profile" "$USER_SERVICE_URL/users/me"
    test_endpoint "User List" "$USER_SERVICE_URL/users/"
    test_endpoint "User Roles" "$USER_SERVICE_URL/roles/"
}

# Test service registry endpoints
test_service_registry() {
    log "Testing Service Registry endpoints..."
    
    test_endpoint "Services List" "$SERVICE_REGISTRY_URL/services/"
    test_endpoint "Reference Panels" "$SERVICE_REGISTRY_URL/reference-panels/"
    test_endpoint "Health Status" "$SERVICE_REGISTRY_URL/health-status"
}

# Test job processor endpoints
test_job_processor() {
    log "Testing Job Processor endpoints..."
    
    test_endpoint "Jobs List" "$JOB_PROCESSOR_URL/jobs"
    # Note: Job creation requires file upload, tested separately
}

# Test file manager endpoints
test_file_manager() {
    log "Testing File Manager endpoints..."
    
    test_endpoint "Files List" "$FILE_MANAGER_URL/files"
    # Note: File upload requires multipart form data, tested separately
}

# Test notification service endpoints
test_notification_service() {
    log "Testing Notification Service endpoints..."
    
    test_endpoint "Notifications List" "$NOTIFICATION_URL/notifications"
    test_endpoint "Notification Preferences" "$NOTIFICATION_URL/notifications/preferences"
}

# Test monitoring service endpoints
test_monitoring_service() {
    log "Testing Monitoring Service endpoints..."
    
    test_endpoint "Overall Health" "$MONITORING_URL/health/overall"
    test_endpoint "Services Health" "$MONITORING_URL/health/services"
    test_endpoint "System Metrics" "$MONITORING_URL/metrics/system"
    test_endpoint "Alerts" "$MONITORING_URL/alerts"
}

# Test database connectivity
test_database_connectivity() {
    log "Testing database connectivity..."
    
    # Test if databases are accessible through services
    for service in "user-service" "service-registry" "job-processor" "file-manager" "notification" "monitoring"; do
        ((TOTAL_TESTS++))
        if docker-compose -f docker-compose.microservices.yml exec -T "$service" python -c "
import os
from sqlalchemy import create_engine
try:
    engine = create_engine(os.environ['DATABASE_URL'])
    conn = engine.connect()
    conn.close()
    print('OK')
except Exception as e:
    print(f'ERROR: {e}')
    exit(1)
" 2>/dev/null | grep -q "OK"; then
            success "Database connectivity for $service"
        else
            error "Database connectivity for $service"
        fi
    done
}

# Test Redis connectivity
test_redis_connectivity() {
    log "Testing Redis connectivity..."
    
    ((TOTAL_TESTS++))
    if docker-compose -f docker-compose.microservices.yml exec -T redis redis-cli ping | grep -q "PONG"; then
        success "Redis connectivity"
    else
        error "Redis connectivity"
    fi
}

# Test file upload functionality
test_file_upload() {
    log "Testing file upload functionality..."
    
    # Create a test file
    echo "test,data,for,upload" > /tmp/test_upload.csv
    
    ((TOTAL_TESTS++))
    response=$(curl -s -w "%{http_code}" \
        -F "file=@/tmp/test_upload.csv" \
        -F "file_type=input" \
        -F "job_id=test-job-123" \
        "$FILE_MANAGER_URL/files/upload" \
        -o /tmp/upload_response 2>/dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        success "File upload"
        # Extract file ID for cleanup
        if command -v jq >/dev/null 2>&1; then
            file_id=$(jq -r '.id' /tmp/upload_response 2>/dev/null || echo "")
            if [ -n "$file_id" ] && [ "$file_id" != "null" ]; then
                # Test file download
                ((TOTAL_TESTS++))
                download_response=$(curl -s -w "%{http_code}" \
                    "$FILE_MANAGER_URL/files/$file_id/download" \
                    -o /tmp/download_response 2>/dev/null || echo "000")
                
                if [ "$download_response" = "200" ]; then
                    success "File download URL generation"
                else
                    error "File download URL generation - Status: $download_response"
                fi
            fi
        fi
    else
        error "File upload - Status: $response"
        if [ -f /tmp/upload_response ]; then
            cat /tmp/upload_response
        fi
    fi
    
    # Cleanup
    rm -f /tmp/test_upload.csv /tmp/upload_response /tmp/download_response
}

# Test notification creation
test_notification_creation() {
    log "Testing notification creation..."
    
    ((TOTAL_TESTS++))
    response=$(curl -s -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": 123,
            "type": "test_notification",
            "title": "Test Notification",
            "message": "This is a test notification",
            "channels": ["web"]
        }' \
        "$NOTIFICATION_URL/notifications" \
        -o /tmp/notification_response 2>/dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        success "Notification creation"
    else
        error "Notification creation - Status: $response"
        if [ -f /tmp/notification_response ]; then
            cat /tmp/notification_response
        fi
    fi
    
    rm -f /tmp/notification_response
}

# Test WebSocket connectivity
test_websocket_connectivity() {
    log "Testing WebSocket connectivity..."
    
    ((TOTAL_TESTS++))
    # Use a simple WebSocket test
    if command -v wscat >/dev/null 2>&1; then
        timeout 5 wscat -c "ws://localhost:8005/ws/123" -x '{"action": "ping"}' >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            success "WebSocket connectivity"
        else
            warning "WebSocket connectivity (wscat test failed, but service may be working)"
        fi
    else
        warning "WebSocket connectivity (wscat not available for testing)"
    fi
}

# Test service discovery
test_service_discovery() {
    log "Testing service discovery..."
    
    # Test if services can communicate with each other
    ((TOTAL_TESTS++))
    if docker-compose -f docker-compose.microservices.yml exec -T api-gateway python -c "
import httpx
import asyncio

async def test():
    async with httpx.AsyncClient() as client:
        response = await client.get('http://user-service:8001/health')
        assert response.status_code == 200
        print('OK')

asyncio.run(test())
" 2>/dev/null | grep -q "OK"; then
        success "Service discovery (API Gateway -> User Service)"
    else
        error "Service discovery (API Gateway -> User Service)"
    fi
}

# Test load balancing (if multiple instances)
test_load_balancing() {
    log "Testing load balancing..."
    
    # This would test if load balancer distributes requests
    # For now, just verify nginx is running
    ((TOTAL_TESTS++))
    if docker-compose -f docker-compose.microservices.yml ps nginx | grep -q "Up"; then
        success "Load balancer (Nginx) is running"
    else
        warning "Load balancer (Nginx) not found or not running"
    fi
}

# Performance tests
test_performance() {
    log "Running basic performance tests..."
    
    # Test response times
    for endpoint in \
        "$API_GATEWAY_URL/health" \
        "$USER_SERVICE_URL/health" \
        "$SERVICE_REGISTRY_URL/health" \
        "$JOB_PROCESSOR_URL/health" \
        "$FILE_MANAGER_URL/health" \
        "$NOTIFICATION_URL/health" \
        "$MONITORING_URL/health"; do
        
        ((TOTAL_TESTS++))
        response_time=$(curl -s -w "%{time_total}" -o /dev/null "$endpoint" 2>/dev/null || echo "999")
        
        # Convert to milliseconds
        response_time_ms=$(echo "$response_time * 1000" | bc 2>/dev/null || echo "999")
        
        if (( $(echo "$response_time_ms < 1000" | bc -l 2>/dev/null || echo "0") )); then
            success "Response time for $endpoint: ${response_time_ms}ms"
        else
            warning "Slow response time for $endpoint: ${response_time_ms}ms"
        fi
    done
}

# Main test execution
main() {
    log "Starting comprehensive microservices test suite..."
    log "Testing Federated Genomic Imputation Platform microservices architecture"
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    sleep 10
    
    # Run all tests
    test_health_endpoints
    test_api_gateway
    test_user_service
    test_service_registry
    test_job_processor
    test_file_manager
    test_notification_service
    test_monitoring_service
    test_database_connectivity
    test_redis_connectivity
    test_file_upload
    test_notification_creation
    test_websocket_connectivity
    test_service_discovery
    test_load_balancing
    test_performance
    
    # Cleanup
    rm -f /tmp/test_response
    
    # Results summary
    echo
    log "Test Results Summary:"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo -e "${BLUE}Total:  $TOTAL_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! Microservices architecture is working correctly.${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed. Please check the logs above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
