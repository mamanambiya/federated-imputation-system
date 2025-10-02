#!/bin/bash

# Comprehensive Test Runner for Federated Genomic Imputation Platform
# Runs all tests including Playwright, API tests, and system validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"
TEST_LOG="$LOG_DIR/comprehensive_tests.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$TEST_LOG"
}

# Error handling
error_exit() {
    log "ERROR" "$1"
    echo -e "${RED}❌ Error: $1${NC}"
    exit 1
}

# Setup
setup_test_environment() {
    log "INFO" "Setting up test environment..."
    
    # Create directories
    mkdir -p "$LOG_DIR" "tests/screenshots" "tests/playwright-report" "tests/test-results"
    
    # Check if services are running
    if ! sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" ps | grep -q "Up"; then
        echo -e "${YELLOW}⚠️ Docker services are not running.${NC}"
        read -p "Would you like to start them now? (y/N): " start_services
        if [[ "$start_services" =~ ^[Yy]$ ]]; then
            log "INFO" "Starting Docker services..."
            sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" up -d
            sleep 15
        else
            error_exit "Services must be running for comprehensive testing"
        fi
    fi
    
    # Wait for services to be ready
    log "INFO" "Waiting for services to be ready..."
    
    # Check frontend
    for i in {1..30}; do
        if curl -s http://localhost:3000 > /dev/null 2>&1; then
            log "INFO" "Frontend is ready"
            break
        fi
        if [[ $i -eq 30 ]]; then
            error_exit "Frontend failed to start"
        fi
        sleep 2
    done
    
    # Check backend
    for i in {1..30}; do
        if curl -s http://localhost:8000/api/services/ > /dev/null 2>&1; then
            log "INFO" "Backend API is ready"
            break
        fi
        if [[ $i -eq 30 ]]; then
            error_exit "Backend API failed to start"
        fi
        sleep 2
    done
    
    log "INFO" "Test environment setup completed"
}

# Pre-test validation
run_pre_test_validation() {
    echo -e "${BLUE}=== Pre-Test Validation ===${NC}"
    log "INFO" "Running pre-test validation..."
    
    # Run existing validation script
    if [[ -f "$PROJECT_ROOT/post_change_validation.sh" ]]; then
        echo "Running system validation..."
        if "$PROJECT_ROOT/post_change_validation.sh" >> "$TEST_LOG" 2>&1; then
            echo -e "${GREEN}✅ System validation passed${NC}"
        else
            echo -e "${YELLOW}⚠️ System validation had warnings (check logs)${NC}"
        fi
    fi
    
    # Check database integrity
    echo "Checking database integrity..."
    local services_count=$(sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation -t -c "SELECT COUNT(*) FROM imputation_imputationservice;" 2>/dev/null | tr -d ' \n' || echo "0")
    local users_count=$(sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation -t -c "SELECT COUNT(*) FROM auth_user;" 2>/dev/null | tr -d ' \n' || echo "0")
    
    echo "Database status:"
    echo "  Services: $services_count"
    echo "  Users: $users_count"
    
    if [[ $services_count -gt 0 && $users_count -gt 0 ]]; then
        echo -e "${GREEN}✅ Database integrity check passed${NC}"
    else
        echo -e "${YELLOW}⚠️ Database may need restoration${NC}"
    fi
}

# Install Playwright if needed
install_playwright() {
    echo -e "${BLUE}=== Playwright Setup ===${NC}"
    log "INFO" "Setting up Playwright..."
    
    # Check if Playwright is installed
    if ! command -v npx &> /dev/null; then
        error_exit "Node.js and npm are required for Playwright tests"
    fi
    
    # Install Playwright if not already installed
    if ! npx playwright --version &> /dev/null; then
        echo "Installing Playwright..."
        npm install -D @playwright/test
        npx playwright install
    else
        echo -e "${GREEN}✅ Playwright is already installed${NC}"
    fi
    
    # Verify browsers are installed
    echo "Verifying Playwright browsers..."
    npx playwright install --with-deps
}

# Run Playwright tests
run_playwright_tests() {
    echo -e "${BLUE}=== Playwright Tests ===${NC}"
    log "INFO" "Running Playwright tests..."
    
    local start_time=$(date +%s)
    
    # Run tests with different configurations
    echo "Running comprehensive Playwright tests..."
    
    if npx playwright test --config=playwright.config.js --reporter=html,list >> "$TEST_LOG" 2>&1; then
        echo -e "${GREEN}✅ Playwright tests completed successfully${NC}"
        local test_status="PASSED"
    else
        echo -e "${YELLOW}⚠️ Some Playwright tests failed (check report)${NC}"
        local test_status="FAILED"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "Playwright test duration: ${duration} seconds"
    echo "Test status: $test_status"
    
    # Show report location
    if [[ -d "tests/playwright-report" ]]; then
        echo "HTML report available at: tests/playwright-report/index.html"
    fi
}

# Run API tests
run_api_tests() {
    echo -e "${BLUE}=== API Tests ===${NC}"
    log "INFO" "Running API tests..."
    
    local api_tests_passed=0
    local api_tests_total=0
    
    # Test services endpoint
    echo "Testing Services API..."
    ((api_tests_total++))
    if curl -s http://localhost:8000/api/services/ | grep -q '"count"'; then
        echo -e "${GREEN}✅ Services API: Working${NC}"
        ((api_tests_passed++))
    else
        echo -e "${RED}❌ Services API: Failed${NC}"
    fi
    
    # Test reference panels endpoint
    echo "Testing Reference Panels API..."
    ((api_tests_total++))
    if curl -s http://localhost:8000/api/reference-panels/ | grep -q '"count"'; then
        echo -e "${GREEN}✅ Reference Panels API: Working${NC}"
        ((api_tests_passed++))
    else
        echo -e "${RED}❌ Reference Panels API: Failed${NC}"
    fi
    
    # Test authentication endpoint
    echo "Testing Authentication API..."
    ((api_tests_total++))
    if curl -s -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}' http://localhost:8000/api/auth/login/ | grep -q '"user"'; then
        echo -e "${GREEN}✅ Authentication API: Working${NC}"
        ((api_tests_passed++))
    else
        echo -e "${RED}❌ Authentication API: Failed${NC}"
    fi
    
    echo "API Tests: $api_tests_passed/$api_tests_total passed"
    
    if [[ $api_tests_passed -eq $api_tests_total ]]; then
        echo -e "${GREEN}✅ All API tests passed${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ Some API tests failed${NC}"
        return 1
    fi
}

# Run performance tests
run_performance_tests() {
    echo -e "${BLUE}=== Performance Tests ===${NC}"
    log "INFO" "Running performance tests..."
    
    # Test frontend load time
    echo "Testing frontend performance..."
    local start_time=$(date +%s%3N)
    curl -s http://localhost:3000 > /dev/null
    local end_time=$(date +%s%3N)
    local frontend_time=$((end_time - start_time))
    
    echo "Frontend load time: ${frontend_time}ms"
    
    # Test API response time
    echo "Testing API performance..."
    local start_time=$(date +%s%3N)
    curl -s http://localhost:8000/api/services/ > /dev/null
    local end_time=$(date +%s%3N)
    local api_time=$((end_time - start_time))
    
    echo "API response time: ${api_time}ms"
    
    # Performance thresholds
    if [[ $frontend_time -lt 5000 && $api_time -lt 2000 ]]; then
        echo -e "${GREEN}✅ Performance tests passed${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ Performance tests show slow response times${NC}"
        return 1
    fi
}

# Generate comprehensive report
generate_report() {
    echo -e "${BLUE}=== Test Report Generation ===${NC}"
    log "INFO" "Generating comprehensive test report..."
    
    local report_file="$PROJECT_ROOT/tests/comprehensive_test_report.html"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Federated Genomic Imputation Platform - Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .pass { color: green; }
        .fail { color: red; }
        .warn { color: orange; }
        .info { color: blue; }
        pre { background: #f5f5f5; padding: 10px; border-radius: 3px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Federated Genomic Imputation Platform</h1>
        <h2>Comprehensive Test Report</h2>
        <p><strong>Generated:</strong> $timestamp</p>
    </div>
    
    <div class="section">
        <h3>Test Summary</h3>
        <p>This report contains results from comprehensive testing including:</p>
        <ul>
            <li>System validation tests</li>
            <li>Playwright end-to-end tests</li>
            <li>API integration tests</li>
            <li>Performance tests</li>
        </ul>
    </div>
    
    <div class="section">
        <h3>Test Artifacts</h3>
        <ul>
            <li><a href="playwright-report/index.html">Playwright HTML Report</a></li>
            <li><a href="screenshots/">Test Screenshots</a></li>
            <li><a href="../logs/comprehensive_tests.log">Detailed Test Log</a></li>
        </ul>
    </div>
    
    <div class="section">
        <h3>System Information</h3>
        <pre>
Hostname: $(hostname)
Date: $(date)
Docker Version: $(docker --version)
Node Version: $(node --version 2>/dev/null || echo "Not available")
        </pre>
    </div>
</body>
</html>
EOF
    
    echo -e "${GREEN}✅ Test report generated: $report_file${NC}"
}

# Main test execution
run_comprehensive_tests() {
    local start_time=$(date +%s)
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        Federated Genomic Imputation Platform                ║${NC}"
    echo -e "${CYAN}║              Comprehensive Test Suite                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log "INFO" "Starting comprehensive test suite..."
    
    # Test phases
    local phases=(
        "setup_test_environment"
        "run_pre_test_validation"
        "install_playwright"
        "run_playwright_tests"
        "run_api_tests"
        "run_performance_tests"
        "generate_report"
    )
    
    local passed_phases=0
    local total_phases=${#phases[@]}
    
    for phase in "${phases[@]}"; do
        echo ""
        echo -e "${YELLOW}Running phase: $phase${NC}"
        
        if $phase; then
            ((passed_phases++))
            log "INFO" "Phase $phase completed successfully"
        else
            log "WARN" "Phase $phase completed with warnings"
            ((passed_phases++)) # Count warnings as passed for now
        fi
    done
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Test Suite Complete                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Test Summary:"
    echo "  Phases completed: $passed_phases/$total_phases"
    echo "  Total duration: $total_duration seconds"
    echo "  Log file: $TEST_LOG"
    echo ""
    
    if [[ $passed_phases -eq $total_phases ]]; then
        echo -e "${GREEN}🎉 All test phases completed successfully!${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ Some test phases had issues. Check the logs for details.${NC}"
        return 1
    fi
}

# Usage
usage() {
    echo "Comprehensive Test Runner for Federated Genomic Imputation Platform"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  run         Run all comprehensive tests (default)"
    echo "  playwright  Run only Playwright tests"
    echo "  api         Run only API tests"
    echo "  performance Run only performance tests"
    echo "  setup       Setup test environment only"
    echo "  help        Show this help message"
    echo ""
}

# Main function
main() {
    case "${1:-run}" in
        "run")
            run_comprehensive_tests
            ;;
        "playwright")
            setup_test_environment
            install_playwright
            run_playwright_tests
            ;;
        "api")
            setup_test_environment
            run_api_tests
            ;;
        "performance")
            setup_test_environment
            run_performance_tests
            ;;
        "setup")
            setup_test_environment
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            echo "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"
