#!/bin/bash

# Post-Change Validation Script for Federated Genomic Imputation Platform
# This script validates the system after changes to ensure everything is working correctly
#
# For comprehensive testing, use: ./dev_docs/scripts/run_comprehensive_tests.sh
# For backup management, use: ./dev_docs/scripts/backup_system.sh

echo "🧪 POST-CHANGE VALIDATION STARTED"
echo "=================================="
echo "Timestamp: $(date)"
echo ""

# Function to check service health
check_service_health() {
    local service=$1
    echo "🔍 Checking $service health..."
    
    if sudo docker-compose ps $service | grep -q "Up"; then
        echo "✅ $service: Running"
        return 0
    else
        echo "❌ $service: Not running"
        return 1
    fi
}

# Function to test API endpoints
test_api_endpoint() {
    local endpoint=$1
    local expected_status=$2
    local description=$3
    
    echo "🌐 Testing $description ($endpoint)..."
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000$endpoint")
    
    if [ "$response" = "$expected_status" ]; then
        echo "✅ $description: HTTP $response (Expected: $expected_status)"
        return 0
    else
        echo "❌ $description: HTTP $response (Expected: $expected_status)"
        return 1
    fi
}

# Function to test authenticated endpoints
test_auth_endpoint() {
    local endpoint=$1
    local expected_status=$2
    local description=$3
    
    echo "🔐 Testing authenticated $description ($endpoint)..."
    
    # Login and get session (only get HTTP status code)
    login_response=$(curl -c /tmp/test_session.txt -s -o /dev/null -X POST \
        -H "Content-Type: application/json" \
        -d '{"username":"test_user","password":"test_password"}' \
        -w "%{http_code}" \
        "http://localhost:8000/api/auth/login/")
    
    if [ "$login_response" = "200" ]; then
        # Test the actual endpoint
        response=$(curl -b /tmp/test_session.txt -s -o /dev/null -w "%{http_code}" "http://localhost:8000$endpoint")
        
        if [ "$response" = "$expected_status" ]; then
            echo "✅ $description: HTTP $response (Expected: $expected_status)"
            rm -f /tmp/test_session.txt
            return 0
        else
            echo "❌ $description: HTTP $response (Expected: $expected_status)"
            rm -f /tmp/test_session.txt
            return 1
        fi
    else
        echo "❌ $description: Login failed (HTTP $login_response)"
        rm -f /tmp/test_session.txt
        return 1
    fi
}

# Initialize counters
total_tests=0
passed_tests=0
failed_tests=0

# 1. Container Health Checks
echo "📦 CONTAINER HEALTH CHECKS"
echo "=========================="

services=("web" "db" "redis" "frontend")
for service in "${services[@]}"; do
    total_tests=$((total_tests + 1))
    if check_service_health "$service"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
done
echo ""

# 2. Database Connection Test
echo "🗄️  DATABASE CONNECTION TEST"
echo "============================"
total_tests=$((total_tests + 1))
echo "🔍 Testing database connection..."

db_test=$(sudo docker-compose exec -T web python manage.py shell -c "
from django.db import connection
try:
    with connection.cursor() as cursor:
        cursor.execute('SELECT 1')
        print('✅ Database connection: OK')
except Exception as e:
    print(f'❌ Database connection: {e}')
    exit(1)
" 2>/dev/null)

if echo "$db_test" | grep -q "✅"; then
    echo "$db_test"
    passed_tests=$((passed_tests + 1))
else
    echo "❌ Database connection: Failed"
    failed_tests=$((failed_tests + 1))
fi
echo ""

# 3. API Endpoint Tests
echo "🌐 API ENDPOINT TESTS"
echo "===================="

# Public endpoints
endpoints=(
    "/api/services/|200|Public Services API"
    "/api/reference-panels/|200|Reference Panels API"
    "/|200|Frontend Landing Page"
)

for endpoint_info in "${endpoints[@]}"; do
    IFS='|' read -r endpoint status description <<< "$endpoint_info"
    total_tests=$((total_tests + 1))
    if test_api_endpoint "$endpoint" "$status" "$description"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
done

# Authenticated endpoints (using test_user credentials - researcher role)
auth_endpoints=(
    "/api/profiles/|200|User Profiles API"
    "/api/roles/|403|User Roles API (restricted)"
    "/api/audit-logs/|403|Audit Logs API (restricted)"
)

for endpoint_info in "${auth_endpoints[@]}"; do
    IFS='|' read -r endpoint status description <<< "$endpoint_info"
    total_tests=$((total_tests + 1))
    if test_auth_endpoint "$endpoint" "$status" "$description"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
done
echo ""

# 4. Frontend Tests
echo "🖥️  FRONTEND TESTS"
echo "================="
total_tests=$((total_tests + 1))
echo "🔍 Testing frontend accessibility..."

frontend_response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000")
if [ "$frontend_response" = "200" ]; then
    echo "✅ Frontend: Accessible (HTTP $frontend_response)"
    passed_tests=$((passed_tests + 1))
else
    echo "❌ Frontend: Not accessible (HTTP $frontend_response)"
    failed_tests=$((failed_tests + 1))
fi
echo ""

# 5. Log Analysis
echo "📋 LOG ANALYSIS"
echo "==============="
echo "🔍 Checking for recent errors in logs..."

# Check backend logs for errors
backend_errors=$(sudo docker-compose logs web --tail=50 2>/dev/null | grep -i error | wc -l)
echo "📊 Backend errors in last 50 log entries: $backend_errors"

# Check frontend logs for errors
frontend_errors=$(sudo docker-compose logs frontend --tail=50 2>/dev/null | grep -i error | wc -l)
echo "📊 Frontend errors in last 50 log entries: $frontend_errors"

echo ""

# 6. Data Integrity Check
echo "💾 DATA INTEGRITY CHECK"
echo "======================"
total_tests=$((total_tests + 1))
echo "🔍 Checking data integrity..."

data_check=$(sudo docker-compose exec -T web python manage.py shell -c "
from imputation.models import ImputationService, UserProfile, UserRole
services_count = ImputationService.objects.count()
users_count = UserProfile.objects.count()
roles_count = UserRole.objects.count()
print(f'Services: {services_count}, Users: {users_count}, Roles: {roles_count}')
if services_count >= 5 and users_count >= 2 and roles_count >= 5:
    print('✅ Data integrity: OK')
else:
    print('❌ Data integrity: Missing data')
    exit(1)
" 2>/dev/null)

if echo "$data_check" | grep -q "✅"; then
    echo "$data_check"
    passed_tests=$((passed_tests + 1))
else
    echo "❌ Data integrity: Failed"
    echo "$data_check"
    failed_tests=$((failed_tests + 1))
fi
echo ""

# 7. UserManagement API Structure Test (Recent Change)
echo "👥 USER MANAGEMENT API STRUCTURE TEST"
echo "====================================="
total_tests=$((total_tests + 1))
echo "🔍 Testing UserManagement API structure after recent changes..."

api_structure_test=$(curl -c /tmp/test_session.txt -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"username":"test_user","password":"test_password"}' \
    "http://localhost:8000/api/auth/login/" > /dev/null 2>&1 && \
curl -b /tmp/test_session.txt -s "http://localhost:8000/api/profiles/" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if 'results' in data and data['results']:
        profile = data['results'][0]
        has_user = 'user' in profile
        has_username = has_user and 'username' in profile['user']
        has_org = 'organization' in profile
        has_dept = 'department' in profile
        
        if has_user and has_username and has_org and has_dept:
            print('✅ UserManagement API structure: Correct')
            print(f'  - User field: {has_user}')
            print(f'  - Username field: {has_username}')
            print(f'  - Organization field: {has_org}')
            print(f'  - Department field: {has_dept}')
        else:
            print('❌ UserManagement API structure: Missing fields')
            print(f'  - User field: {has_user}')
            print(f'  - Username field: {has_username}')
            print(f'  - Organization field: {has_org}')
            print(f'  - Department field: {has_dept}')
            exit(1)
    else:
        print('❌ UserManagement API structure: No data returned')
        exit(1)
except Exception as e:
    print(f'❌ UserManagement API structure: Error - {e}')
    exit(1)
" 2>/dev/null)

rm -f /tmp/test_session.txt

if echo "$api_structure_test" | grep -q "✅"; then
    echo "$api_structure_test"
    passed_tests=$((passed_tests + 1))
else
    echo "$api_structure_test"
    failed_tests=$((failed_tests + 1))
fi
echo ""

# Summary
echo "📊 VALIDATION SUMMARY"
echo "===================="
echo "Total Tests: $total_tests"
echo "Passed: $passed_tests ✅"
echo "Failed: $failed_tests ❌"
echo ""

if [ $failed_tests -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED! System is stable after changes."
    exit 0
else
    echo "⚠️  $failed_tests TEST(S) FAILED! Please investigate and fix issues."
    exit 1
fi