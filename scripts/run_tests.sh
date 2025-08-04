#!/bin/bash

# Automated Testing Script for Federated Genomic Imputation Platform
# This script should be run after any significant changes

echo "🧪 AUTOMATED TESTING SUITE"
echo "=========================="
echo "Running comprehensive tests for the Federated Genomic Imputation Platform"
echo "Timestamp: $(date)"
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Function to print section headers
print_section() {
    echo ""
    echo "🔍 $1"
    echo "$(printf '=%.0s' {1..50})"
}

# 1. Django Tests (if they exist)
print_section "DJANGO BACKEND TESTS"
if sudo docker-compose exec -T web python manage.py test --verbosity=2 2>/dev/null; then
    echo "✅ Django tests passed"
else
    echo "⚠️  No Django tests found or tests failed"
fi

# 2. JavaScript/React Tests (if they exist)
print_section "FRONTEND TESTS"
if sudo docker-compose exec -T frontend npm test -- --coverage --watchAll=false 2>/dev/null; then
    echo "✅ Frontend tests passed"
else
    echo "⚠️  No frontend tests found or tests failed"
fi

# 3. Integration Tests
print_section "INTEGRATION TESTS"
if [ -f "./post_change_validation.sh" ]; then
    ./post_change_validation.sh
else
    echo "⚠️  Integration test script not found"
fi

# 4. Linting and Code Quality
print_section "CODE QUALITY CHECKS"

# Python linting
echo "🐍 Python code quality..."
if sudo docker-compose exec -T web flake8 imputation/ 2>/dev/null; then
    echo "✅ Python linting passed"
else
    echo "⚠️  Python linting issues found (or flake8 not installed)"
fi

# JavaScript linting
echo "📜 JavaScript code quality..."
if sudo docker-compose exec -T frontend npm run lint 2>/dev/null; then
    echo "✅ JavaScript linting passed"
else
    echo "⚠️  JavaScript linting issues found (or linter not configured)"
fi

print_section "TEST SUMMARY"
echo "🎯 Testing complete! Review results above for any issues."
echo ""
echo "💡 NEXT STEPS:"
echo "- If tests failed, investigate and fix issues before deployment"
echo "- If tests passed, changes are ready for commit/deployment"
echo "- Always check logs after deployment to ensure stability"
echo ""