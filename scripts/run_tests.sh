#!/bin/bash
#
# Comprehensive test runner for Federated Genomic Imputation Platform
# Runs backend tests, frontend tests, and generates coverage reports
#

set -e  # Exit on error

echo "🧪 =========================================="
echo "   Testing Suite for Federated Imputation"
echo "   =========================================="
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if services are running
print_status "$BLUE" "📋 Checking service status..."
if ! docker ps | grep -q postgres; then
    print_status "$YELLOW" "⚠️  Database not running. Starting services..."
    docker-compose up -d db redis
    sleep 5
fi

# ============================================
# Backend Tests (Django/Python)
# ============================================
print_status "$BLUE" "\n🐍 Running Backend Tests..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Install test dependencies if not already installed
if ! python -c "import pytest" 2>/dev/null; then
    print_status "$YELLOW" "📦 Installing test dependencies..."
    pip install -q pytest pytest-django pytest-cov factory-boy faker freezegun
fi

# Run backend tests with coverage
print_status "$BLUE" "Running pytest with coverage..."
if pytest imputation/tests/ --cov=imputation --cov-report=html --cov-report=term-missing -v; then
    print_status "$GREEN" "✅ Backend tests passed!"
    BACKEND_STATUS=0
else
    print_status "$RED" "❌ Backend tests failed!"
    BACKEND_STATUS=1
fi

# Display coverage summary
echo
print_status "$BLUE" "📊 Coverage Report:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f htmlcov/index.html ]; then
    print_status "$GREEN" "✅ HTML coverage report: htmlcov/index.html"
fi

# ============================================
# Frontend Tests (React/JavaScript)
# ============================================
print_status "$BLUE" "\n⚛️  Running Frontend Tests..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd frontend

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    print_status "$YELLOW" "📦 Installing frontend dependencies..."
    npm install
fi

# Run frontend tests
if [ -d "src/__tests__" ] && [ "$(ls -A src/__tests__)" ]; then
    print_status "$BLUE" "Running Jest tests..."
    if npm test -- --coverage --watchAll=false; then
        print_status "$GREEN" "✅ Frontend tests passed!"
        FRONTEND_STATUS=0
    else
        print_status "$RED" "❌ Frontend tests failed!"
        FRONTEND_STATUS=1
    fi
else
    print_status "$YELLOW" "⚠️  No frontend tests found (src/__tests__ is empty)"
    FRONTEND_STATUS=0
fi

cd ..

# ============================================
# Test Summary
# ============================================
echo
print_status "$BLUE" "📊 Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $BACKEND_STATUS -eq 0 ]; then
    print_status "$GREEN" "✅ Backend Tests: PASSED"
else
    print_status "$RED" "❌ Backend Tests: FAILED"
fi

if [ $FRONTEND_STATUS -eq 0 ]; then
    print_status "$GREEN" "✅ Frontend Tests: PASSED"
else
    print_status "$RED" "❌ Frontend Tests: FAILED"
fi

echo
if [ $BACKEND_STATUS -eq 0 ] && [ $FRONTEND_STATUS -eq 0 ]; then
    print_status "$GREEN" "🎉 All tests passed!"
    exit 0
else
    print_status "$RED" "❌ Some tests failed. Please review the output above."
    exit 1
fi
