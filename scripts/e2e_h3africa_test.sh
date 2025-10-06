#!/bin/bash
#
# End-to-End Test Script for H3Africa Job Execution
#
# This script tests the complete job execution pipeline:
# 1. Authentication
# 2. Job submission with file upload
# 3. Status monitoring
# 4. Result download
# 5. Validation
#
# Usage: bash scripts/e2e_h3africa_test.sh [OPTIONS]
#

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration - can be overridden by environment variables
TEST_USER="${TEST_USER:-test_user}"
TEST_PASSWORD="${TEST_PASSWORD:-test123}"
SERVICE_ID="${SERVICE_ID:-1}"
PANEL_ID="${PANEL_ID:-1}"
TEST_VCF="${TEST_VCF:-$HOME/test_data/test_small_1000var.vcf.gz}"
API_GATEWAY="${API_GATEWAY:-http://localhost:8000}"
JOB_PROCESSOR="${JOB_PROCESSOR:-http://localhost:8003}"
USER_SERVICE="${USER_SERVICE:-http://localhost:8001}"
MAX_WAIT_TIME=1800  # 30 minutes
POLL_INTERVAL=30    # 30 seconds

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            TEST_USER="$2"
            shift 2
            ;;
        --password)
            TEST_PASSWORD="$2"
            shift 2
            ;;
        --service-id)
            SERVICE_ID="$2"
            shift 2
            ;;
        --panel-id)
            PANEL_ID="$2"
            shift 2
            ;;
        --vcf-file)
            TEST_VCF="$2"
            shift 2
            ;;
        --timeout)
            MAX_WAIT_TIME="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --user USERNAME        Test user username (default: test_user)"
            echo "  --password PASS        Test user password (default: test123)"
            echo "  --service-id ID        H3Africa service ID (default: 1)"
            echo "  --panel-id ID          Reference panel ID (default: 1)"
            echo "  --vcf-file PATH        Path to test VCF file (default: ~/test_data/test_small_1000var.vcf.gz)"
            echo "  --timeout SECONDS      Max wait time for job completion (default: 1800)"
            echo "  --help                 Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Print header
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     H3Africa Job Execution - End-to-End Test           ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Configuration:"
echo "  User: $TEST_USER"
echo "  Service ID: $SERVICE_ID"
echo "  Panel ID: $PANEL_ID"
echo "  VCF File: $TEST_VCF"
echo "  Max Wait: $MAX_WAIT_TIME seconds"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if VCF file exists
if [ ! -f "$TEST_VCF" ]; then
    echo -e "${RED}✗${NC} Test VCF file not found: $TEST_VCF"
    echo "  Run: bash scripts/prepare_test_data.sh"
    exit 1
fi
echo -e "${GREEN}✓${NC} Test VCF file exists ($(du -h "$TEST_VCF" | cut -f1))"

# Check if services are running
if ! curl -s "$JOB_PROCESSOR/health" > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Job processor not accessible at $JOB_PROCESSOR"
    echo "  Check: docker ps | grep job-processor"
    exit 1
fi
echo -e "${GREEN}✓${NC} Job processor is running"

if ! curl -s "$USER_SERVICE/health" > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} User service not accessible at $USER_SERVICE"
    echo "  Check: docker ps | grep user-service"
    exit 1
fi
echo -e "${GREEN}✓${NC} User service is running"

echo ""

# Step 1: Authenticate
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Step 1: Authentication${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

AUTH_RESPONSE=$(curl -s -X POST "$USER_SERVICE/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASSWORD\"}")

AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.access_token')

if [ -z "$AUTH_TOKEN" ] || [ "$AUTH_TOKEN" == "null" ]; then
    echo -e "${RED}✗ Authentication failed${NC}"
    echo "Response: $AUTH_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Authentication successful${NC}"
echo "  Token: ${AUTH_TOKEN:0:20}..."
echo ""

# Step 2: Submit job
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Step 2: Job Submission${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
JOB_NAME="E2E Test - H3Africa - $TIMESTAMP"

echo "Submitting job..."
echo "  Name: $JOB_NAME"
echo "  Service ID: $SERVICE_ID"
echo "  Panel ID: $PANEL_ID"
echo "  File: $(basename "$TEST_VCF")"

JOB_RESPONSE=$(curl -s -X POST "$JOB_PROCESSOR/jobs" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -F "name=$JOB_NAME" \
    -F "description=Automated E2E test for H3Africa integration" \
    -F "service_id=$SERVICE_ID" \
    -F "reference_panel_id=$PANEL_ID" \
    -F "input_format=vcf" \
    -F "build=hg38" \
    -F "phasing=true" \
    -F "population=AFR" \
    -F "input_file=@$TEST_VCF")

JOB_ID=$(echo "$JOB_RESPONSE" | jq -r '.id')

if [ -z "$JOB_ID" ] || [ "$JOB_ID" == "null" ]; then
    echo -e "${RED}✗ Job creation failed${NC}"
    echo "Response: $JOB_RESPONSE" | jq '.'
    exit 1
fi

echo -e "${GREEN}✓ Job created successfully${NC}"
echo "  Job ID: $JOB_ID"
echo "  Status: pending"
echo ""

# Step 3: Monitor job status
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Step 3: Status Monitoring${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Monitoring job status (timeout: $MAX_WAIT_TIME seconds)..."
echo "Poll interval: $POLL_INTERVAL seconds"
echo ""

ELAPSED=0
START_TIME=$(date +%s)
LAST_STATUS=""
LAST_PROGRESS=0

while [ $ELAPSED -lt $MAX_WAIT_TIME ]; do
    # Get job status
    JOB_STATUS_RESPONSE=$(curl -s -H "Authorization: Bearer $AUTH_TOKEN" \
        "$JOB_PROCESSOR/jobs/$JOB_ID")

    STATUS=$(echo "$JOB_STATUS_RESPONSE" | jq -r '.status')
    PROGRESS=$(echo "$JOB_STATUS_RESPONSE" | jq -r '.progress_percentage')
    EXTERNAL_JOB_ID=$(echo "$JOB_STATUS_RESPONSE" | jq -r '.external_job_id')

    # Calculate elapsed time
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    ELAPSED_MIN=$((ELAPSED / 60))
    ELAPSED_SEC=$((ELAPSED % 60))

    # Print status update if changed
    if [ "$STATUS" != "$LAST_STATUS" ] || [ "$PROGRESS" != "$LAST_PROGRESS" ]; then
        printf "[%02d:%02d] " "$ELAPSED_MIN" "$ELAPSED_SEC"

        case $STATUS in
            "pending")
                echo -e "${YELLOW}⏳ Pending${NC} ($PROGRESS%)"
                ;;
            "queued")
                echo -e "${BLUE}📋 Queued${NC} ($PROGRESS%)"
                ;;
            "running")
                echo -e "${BLUE}🔄 Running${NC} ($PROGRESS%)"
                if [ "$EXTERNAL_JOB_ID" != "null" ] && [ -n "$EXTERNAL_JOB_ID" ]; then
                    echo "   External Job ID: $EXTERNAL_JOB_ID"
                fi
                ;;
            "completed")
                echo -e "${GREEN}✓ Completed${NC} (100%)"
                break
                ;;
            "failed")
                echo -e "${RED}✗ Failed${NC}"
                ERROR_MSG=$(echo "$JOB_STATUS_RESPONSE" | jq -r '.error_message')
                echo "   Error: $ERROR_MSG"
                exit 1
                ;;
            "cancelled")
                echo -e "${RED}✗ Cancelled${NC}"
                exit 1
                ;;
            *)
                echo -e "${YELLOW}? Unknown status: $STATUS${NC}"
                ;;
        esac

        LAST_STATUS="$STATUS"
        LAST_PROGRESS="$PROGRESS"
    fi

    # Check if completed
    if [ "$STATUS" == "completed" ]; then
        echo -e "${GREEN}✓ Job completed successfully!${NC}"
        printf "  Total execution time: %02d:%02d\n" "$ELAPSED_MIN" "$ELAPSED_SEC"
        break
    elif [ "$STATUS" == "failed" ] || [ "$STATUS" == "cancelled" ]; then
        break
    fi

    # Wait before next poll
    sleep $POLL_INTERVAL
    ELAPSED=$((CURRENT_TIME - START_TIME + POLL_INTERVAL))
done

# Check for timeout
if [ $ELAPSED -ge $MAX_WAIT_TIME ]; then
    echo -e "${RED}✗ Job timed out after $MAX_WAIT_TIME seconds${NC}"
    echo "  Current status: $STATUS ($PROGRESS%)"
    exit 1
fi

echo ""

# Step 4: Download results
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Step 4: Results Download${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

RESULTS_FILE="results_${JOB_ID}.zip"

echo "Downloading results..."
RESULTS_RESPONSE=$(curl -s -H "Authorization: Bearer $AUTH_TOKEN" \
    "$JOB_PROCESSOR/jobs/$JOB_ID/results")

DOWNLOAD_URL=$(echo "$RESULTS_RESPONSE" | jq -r '.download_url')

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
    echo -e "${RED}✗ Failed to get download URL${NC}"
    echo "Response: $RESULTS_RESPONSE" | jq '.'
    exit 1
fi

# Download the actual results file
curl -s -H "Authorization: Bearer $AUTH_TOKEN" \
    "$DOWNLOAD_URL" -o "$RESULTS_FILE"

if [ -f "$RESULTS_FILE" ]; then
    FILE_SIZE=$(du -h "$RESULTS_FILE" | cut -f1)
    echo -e "${GREEN}✓ Results downloaded${NC}"
    echo "  File: $RESULTS_FILE"
    echo "  Size: $FILE_SIZE"
else
    echo -e "${RED}✗ Results download failed${NC}"
    exit 1
fi

echo ""

# Step 5: Validate results
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Step 5: Results Validation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check file type
if file "$RESULTS_FILE" | grep -q "Zip archive"; then
    echo -e "${GREEN}✓${NC} File is a valid ZIP archive"

    # List contents
    echo ""
    echo "ZIP contents:"
    unzip -l "$RESULTS_FILE" | head -20

    # Extract and validate VCF if present
    if unzip -l "$RESULTS_FILE" | grep -q "\.vcf\.gz$"; then
        echo ""
        echo "Extracting VCF files..."
        unzip -o "$RESULTS_FILE" "*.vcf.gz" -d "$(dirname "$RESULTS_FILE")" 2>/dev/null || true

        # Find extracted VCF
        RESULT_VCF=$(find "$(dirname "$RESULTS_FILE")" -name "*.vcf.gz" -type f | head -1)

        if [ -n "$RESULT_VCF" ] && [ -f "$RESULT_VCF" ]; then
            echo -e "${GREEN}✓${NC} Found VCF file: $(basename "$RESULT_VCF")"

            # Validate VCF format
            if zcat "$RESULT_VCF" | head -1 | grep -q "^##fileformat=VCF"; then
                echo -e "${GREEN}✓${NC} Valid VCF format"

                # Count variants
                VARIANT_COUNT=$(zcat "$RESULT_VCF" | grep -v "^#" | wc -l)
                echo -e "${GREEN}✓${NC} Contains $VARIANT_COUNT variants"
            else
                echo -e "${YELLOW}⚠${NC} VCF format could not be verified"
            fi
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} File is not a ZIP archive (may be different format)"
fi

echo ""

# Step 6: Check email notification (optional)
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Step 6: Email Notification Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if notification service sent email
if docker logs notification 2>&1 | grep -q "$JOB_ID.*sent successfully"; then
    echo -e "${GREEN}✓${NC} Email notification sent successfully"
elif docker logs notification 2>&1 | grep -q "$JOB_ID"; then
    echo -e "${YELLOW}⚠${NC} Email notification logged but status unknown"
else
    echo -e "${YELLOW}⚠${NC} Email notification not found in logs"
    echo "  (May have been sent earlier or SMTP not configured)"
fi

echo ""

# Final summary
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ END-TO-END TEST PASSED!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo "📊 Test Summary:"
echo "   Job ID: $JOB_ID"
echo "   Status: completed"
echo "   Execution Time: ${ELAPSED_MIN}m ${ELAPSED_SEC}s"
echo "   Results File: $RESULTS_FILE"
echo "   File Size: $FILE_SIZE"
echo ""
echo "🔍 For detailed logs:"
echo "   docker logs job-processor | grep '$JOB_ID'"
echo ""
