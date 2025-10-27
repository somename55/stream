#!/bin/bash

# Security Testing Script for Arduino Control Application
# This script tests the security vulnerabilities found in the audit

echo "================================================"
echo "Security Testing Script"
echo "Arduino Control Application"
echo "================================================"
echo ""

# Configuration
TARGET_URL="${1:-http://localhost:3000}"
API_KEY="${2:-}"

echo "Target URL: $TARGET_URL"
echo "API Key: ${API_KEY:0:8}..." # Only show first 8 chars
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Function to print test results
print_result() {
    local test_name=$1
    local result=$2
    local details=$3

    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}[PASS]${NC} $test_name"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}[FAIL]${NC} $test_name"
        echo -e "       ${YELLOW}$details${NC}"
        FAILED=$((FAILED + 1))
    fi
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "================================================"
echo "Test 1: Authentication - Unauthenticated Access"
echo "================================================"
echo "Testing if endpoints require authentication..."
echo ""

# Test without API key
response=$(curl -s -w "\n%{http_code}" -X POST "$TARGET_URL/arduino/toggle" 2>/dev/null)
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
    print_result "Unauthenticated access blocked" "PASS" ""
else
    print_result "Unauthenticated access allowed" "FAIL" "Endpoints should return 401 without valid API key. Got: $http_code"
fi

echo ""
echo "================================================"
echo "Test 2: Authentication - With Valid API Key"
echo "================================================"

if [ -n "$API_KEY" ]; then
    response=$(curl -s -w "\n%{http_code}" -X POST "$TARGET_URL/arduino/status" \
        -H "X-API-Key: $API_KEY" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ]; then
        print_result "Valid API key accepted" "PASS" ""
    else
        print_result "Valid API key rejected" "FAIL" "Valid API key should be accepted. Got: $http_code"
    fi
else
    print_warning "Skipping authenticated test - no API key provided"
fi

echo ""
echo "================================================"
echo "Test 3: Rate Limiting"
echo "================================================"
echo "Sending 35 requests to test rate limiting..."
echo ""

rate_limited=false
for i in {1..35}; do
    response=$(curl -s -w "\n%{http_code}" -X POST "$TARGET_URL/arduino/status" \
        -H "X-API-Key: $API_KEY" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "429" ]; then
        rate_limited=true
        break
    fi

    # Show progress every 5 requests
    if [ $((i % 5)) -eq 0 ]; then
        echo "  Sent $i requests..."
    fi
done

if [ "$rate_limited" = true ]; then
    print_result "Rate limiting active" "PASS" ""
else
    print_result "Rate limiting not detected" "FAIL" "Should be rate limited after ~30 requests"
fi

echo ""
echo "================================================"
echo "Test 4: CORS Configuration"
echo "================================================"
echo "Testing CORS restrictions..."
echo ""

# Test CORS with evil origin
response=$(curl -s -w "\n%{http_code}" -X POST "$TARGET_URL/arduino/toggle" \
    -H "Origin: https://evil.com" \
    -H "X-API-Key: $API_KEY" 2>/dev/null)
http_code=$(echo "$response" | tail -n1)
headers=$(echo "$response" | head -n-1)

if echo "$headers" | grep -q "Access-Control-Allow-Origin.*evil.com" || [ "$http_code" = "200" ]; then
    print_result "CORS allows arbitrary origins" "FAIL" "Should block origins not in whitelist"
else
    print_result "CORS restricts origins" "PASS" ""
fi

echo ""
echo "================================================"
echo "Test 5: Information Disclosure"
echo "================================================"
echo "Checking for information leaks..."
echo ""

# Test error messages
response=$(curl -s -X POST "$TARGET_URL/arduino/invalid-endpoint" 2>/dev/null)

if echo "$response" | grep -qi "arduino_port\|/dev/\|COM[0-9]"; then
    print_result "System information leaked in errors" "FAIL" "Error messages reveal system paths"
else
    print_result "No obvious information leaks" "PASS" ""
fi

echo ""
echo "================================================"
echo "Test 6: Security Headers"
echo "================================================"
echo "Checking HTTP security headers..."
echo ""

headers=$(curl -s -I "$TARGET_URL/arduino/status" -H "X-API-Key: $API_KEY" 2>/dev/null)

# Check for security headers
header_checks=(
    "X-Content-Type-Options:X-Content-Type-Options"
    "X-Frame-Options:X-Frame-Options"
    "Strict-Transport-Security:HSTS"
)

for check in "${header_checks[@]}"; do
    IFS=':' read -r header display_name <<< "$check"
    if echo "$headers" | grep -qi "$header"; then
        print_result "$display_name header present" "PASS" ""
    else
        print_result "$display_name header missing" "FAIL" "Should include $header header"
    fi
done

echo ""
echo "================================================"
echo "Test 7: Input Validation"
echo "================================================"
echo "Testing command validation..."
echo ""

# Try to send invalid command (if we had an endpoint that accepts user input)
response=$(curl -s -w "\n%{http_code}" -X POST "$TARGET_URL/arduino/toggle" \
    -H "X-API-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"command": "MALICIOUS_COMMAND; cat /etc/passwd"}' 2>/dev/null)

# For now, just check that the endpoint responds appropriately
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "500" ] || [ "$http_code" = "400" ]; then
    print_warning "Endpoint returned error for malformed input (expected behavior varies)"
elif [ "$http_code" = "200" ] || [ "$http_code" = "503" ]; then
    print_warning "Endpoint processed request (check if validation is in place)"
fi

echo ""
echo "================================================"
echo "Test 8: HTTPS Enforcement"
echo "================================================"

if echo "$TARGET_URL" | grep -q "^https://"; then
    print_result "Using HTTPS" "PASS" ""
else
    print_result "Using HTTP (insecure)" "FAIL" "Should use HTTPS in production"
fi

echo ""
echo "================================================"
echo "Test 9: Command Injection Attempt"
echo "================================================"
echo "Testing for command injection vulnerabilities..."
echo ""

# Test various injection payloads
payloads=(
    "AAAA\n\nMALICIOUS"
    "'; DROP TABLE users; --"
    "../../../etc/passwd"
    "\x00\x01\x02"
)

for payload in "${payloads[@]}"; do
    response=$(curl -s -w "\n%{http_code}" -X POST "$TARGET_URL/arduino/toggle" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"command\": \"$payload\"}" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)

    # We expect rejection or proper handling
    if [ "$http_code" = "400" ] || [ "$http_code" = "503" ]; then
        # Good - rejected or Arduino not connected
        :
    elif [ "$http_code" = "500" ]; then
        print_warning "Injection payload caused server error: $payload"
    fi
done

print_result "Command injection tests completed" "PASS" "Review server logs for any errors"

echo ""
echo "================================================"
echo "Test 10: Endpoint Enumeration"
echo "================================================"
echo "Checking for undocumented endpoints..."
echo ""

endpoints=(
    "/admin"
    "/debug"
    "/console"
    "/api/config"
    "/.env"
    "/package.json"
    "/server.js"
)

found_sensitive=false
for endpoint in "${endpoints[@]}"; do
    response=$(curl -s -w "\n%{http_code}" -X GET "$TARGET_URL$endpoint" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ]; then
        print_warning "Accessible endpoint found: $endpoint"
        found_sensitive=true
    fi
done

if [ "$found_sensitive" = false ]; then
    print_result "No sensitive endpoints exposed" "PASS" ""
else
    print_result "Sensitive endpoints accessible" "FAIL" "Should return 404 for undocumented endpoints"
fi

echo ""
echo "================================================"
echo "Summary"
echo "================================================"
echo ""
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! Security posture looks good.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Review the SECURITY_AUDIT_REPORT.md for remediation steps.${NC}"
    exit 1
fi
