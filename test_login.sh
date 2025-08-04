#!/bin/bash

# 🔐 Login Testing Script
# This script tests the complete authentication flow to help diagnose any login issues

echo "🔍 Login Issue Diagnostic Script"
echo "================================="
echo ""

# Configuration
API_BASE="http://154.114.10.123:8000"
FRONTEND_ORIGIN="http://154.114.10.123:3000"
TEST_USER="test_user"
TEST_PASS="test_password"

echo "📊 1. Testing API connectivity..."
echo "   API Base: $API_BASE"
echo "   Frontend Origin: $FRONTEND_ORIGIN"
echo ""

# Test basic API connectivity
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE/api/services/")
if [ "$API_HEALTH" = "200" ]; then
    echo "   ✅ API is accessible (HTTP $API_HEALTH)"
else
    echo "   ❌ API is not accessible (HTTP $API_HEALTH)"
    exit 1
fi

echo ""
echo "🔐 2. Testing authentication endpoints..."

# Test login endpoint (should return 405 for GET)
LOGIN_GET=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE/api/auth/login/")
if [ "$LOGIN_GET" = "405" ]; then
    echo "   ✅ Login endpoint exists (HTTP $LOGIN_GET for GET - expected)"
else
    echo "   ⚠️  Login endpoint response: HTTP $LOGIN_GET"
fi

# Test user info endpoint (should return 401 without auth)
USER_INFO_UNAUTH=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE/api/auth/user/")
if [ "$USER_INFO_UNAUTH" = "401" ]; then
    echo "   ✅ User info endpoint properly protected (HTTP $USER_INFO_UNAUTH)"
else
    echo "   ⚠️  User info endpoint unexpected response: HTTP $USER_INFO_UNAUTH"
fi

echo ""
echo "🧪 3. Testing complete login flow..."

# Create a temporary cookie jar
COOKIE_JAR=$(mktemp)
echo "   Cookie jar: $COOKIE_JAR"

# Perform login
echo "   Attempting login with $TEST_USER..."
LOGIN_RESPONSE=$(curl -s -c "$COOKIE_JAR" -X POST \
    -H "Content-Type: application/json" \
    -H "Origin: $FRONTEND_ORIGIN" \
    -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASS\"}" \
    "$API_BASE/api/auth/login/")

# Check login response
if echo "$LOGIN_RESPONSE" | grep -q "Login successful"; then
    echo "   ✅ Login successful"
    echo "   Response: $LOGIN_RESPONSE"
else
    echo "   ❌ Login failed"
    echo "   Response: $LOGIN_RESPONSE"
    rm -f "$COOKIE_JAR"
    exit 1
fi

echo ""
echo "🍪 4. Testing session persistence..."

# Test user info with session cookie
USER_INFO_RESPONSE=$(curl -s -b "$COOKIE_JAR" \
    -H "Origin: $FRONTEND_ORIGIN" \
    "$API_BASE/api/auth/user/")

if echo "$USER_INFO_RESPONSE" | grep -q "\"username\":\"$TEST_USER\""; then
    echo "   ✅ Session persistence working"
    echo "   User info: $USER_INFO_RESPONSE"
else
    echo "   ❌ Session persistence failed"
    echo "   Response: $USER_INFO_RESPONSE"
fi

echo ""
echo "🔍 5. Checking session cookies..."

if [ -f "$COOKIE_JAR" ]; then
    echo "   Session cookies saved:"
    cat "$COOKIE_JAR" | grep -v "^#" | while read line; do
        if [ ! -z "$line" ]; then
            echo "   📄 $line"
        fi
    done
else
    echo "   ❌ No session cookies found"
fi

echo ""
echo "🚪 6. Testing logout..."

# Test logout
LOGOUT_RESPONSE=$(curl -s -b "$COOKIE_JAR" -X POST \
    -H "Content-Type: application/json" \
    -H "Origin: $FRONTEND_ORIGIN" \
    "$API_BASE/api/auth/logout/")

if echo "$LOGOUT_RESPONSE" | grep -q "Logout successful"; then
    echo "   ✅ Logout successful"
else
    echo "   ⚠️  Logout response: $LOGOUT_RESPONSE"
fi

# Verify logout by checking user info again
USER_INFO_AFTER_LOGOUT=$(curl -s -o /dev/null -w "%{http_code}" -b "$COOKIE_JAR" \
    "$API_BASE/api/auth/user/")

if [ "$USER_INFO_AFTER_LOGOUT" = "401" ]; then
    echo "   ✅ Session properly cleared after logout"
else
    echo "   ⚠️  Session might still be active after logout (HTTP $USER_INFO_AFTER_LOGOUT)"
fi

echo ""
echo "📊 7. System status check..."

# Check Docker services
echo "   Docker services:"
sudo docker-compose ps | grep -E "(web_1|frontend_1|db_1)" | while read line; do
    if echo "$line" | grep -q "Up"; then
        SERVICE=$(echo "$line" | awk '{print $1}' | sed 's/.*_//' | sed 's/_1//')
        echo "   ✅ $SERVICE service running"
    else
        echo "   ❌ Service issue: $line"
    fi
done

# Check user count
USER_COUNT=$(sudo docker-compose exec -T web python manage.py shell -c "from django.contrib.auth.models import User; print(User.objects.count())" 2>/dev/null | tail -1)
echo "   👥 Total users in database: $USER_COUNT"

# Check session count
SESSION_COUNT=$(sudo docker-compose exec -T web python manage.py shell -c "from django.contrib.sessions.models import Session; print(Session.objects.count())" 2>/dev/null | tail -1)
echo "   🍪 Active sessions: $SESSION_COUNT"

# Cleanup
rm -f "$COOKIE_JAR"

echo ""
echo "🎯 Test Summary:"
echo "   If all tests show ✅, the login system is working correctly."
echo "   If you see ❌ or ⚠️, check the LOGIN_TROUBLESHOOTING.md guide."
echo ""
echo "💡 For frontend testing:"
echo "   1. Open browser dev tools"
echo "   2. Go to http://154.114.10.123:3000"
echo "   3. Try login with $TEST_USER / $TEST_PASS"
echo "   4. Check Console and Network tabs for errors"
echo ""
echo "✅ Login diagnostic complete!"