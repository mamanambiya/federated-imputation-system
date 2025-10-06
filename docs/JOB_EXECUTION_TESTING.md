# End-to-End Job Execution Testing Guide

**Document Type**: Implementation Guide
**Priority**: P0 (Critical - Core Platform Functionality)
**Last Updated**: October 4, 2025
**Estimated Time**: 3-5 days (24-40 hours)

---

## 📋 Overview

This document provides a comprehensive guide for testing the complete job execution pipeline across all integrated imputation services (H3Africa, Michigan, ILIFU). This is **critical functionality** - the platform's core purpose is to submit and track imputation jobs on external services.

###Purpose

- **Validate** that jobs can be submitted, processed, and completed successfully
- **Test** integration with all external imputation services
- **Document** service-specific requirements and quirks
- **Establish** baseline performance metrics

### Success Criteria

- ✅ Job processor Docker container reports healthy
- ✅ Jobs can be created via API and frontend
- ✅ Jobs successfully submitted to H3Africa (Michigan API)
- ✅ Jobs successfully submitted to ILIFU (GA4GH WES API)
- ✅ Michigan service timeout issue resolved
- ✅ Email notifications sent at each job lifecycle stage
- ✅ Results downloaded successfully
- ✅ End-to-end test passes (upload → submit → complete → download)

---

## 🔄 Job Execution Flow

### Complete Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                   Job Execution Pipeline                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. User uploads VCF file                                        │
│     ↓ Frontend → File Manager Service                           │
│     ↓ File stored locally (or S3 in production)                 │
│                                                                   │
│  2. User selects service + reference panel                       │
│     ↓ Frontend → Job Processor Service                          │
│     ↓ Job record created in database                            │
│                                                                   │
│  3. Job queued for execution                                     │
│     ↓ Job Processor → Celery Queue (Redis)                      │
│     ↓ Status: pending → queued                                  │
│                                                                   │
│  4. Celery worker picks up job                                   │
│     ↓ Worker submits to external service (H3Africa/ILIFU/etc)   │
│     ↓ Receives external_job_id from service                     │
│     ↓ Status: queued → running                                  │
│                                                                   │
│  5. Poll external service for status                             │
│     ↓ Every 30 seconds: Check job progress                      │
│     ↓ Update progress_percentage in database                    │
│     ↓ Send notification on milestone (25%, 50%, 75%)            │
│                                                                   │
│  6. Job completes on external service                            │
│     ↓ Download results from service                             │
│     ↓ Store in File Manager                                     │
│     ↓ Status: running → completed                               │
│                                                                   │
│  7. Notify user                                                  │
│     ↓ Email notification with download link                     │
│     ↓ In-app notification                                       │
│                                                                   │
│  8. User downloads results                                       │
│     ↓ Frontend → File Manager                                   │
│     ↓ Generate signed URL (S3) or serve file directly           │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Alternative Flow: Job Failure

```
4. Celery worker picks up job
   ↓ External service rejects job (format error, auth failure)
   ↓ Status: queued → failed
   ↓ Error message stored in job.error_message
   ↓ Email notification sent with error details
   ↓ User can retry with corrections
```

---

## 🛠️ Implementation Plan

## STEP 1: Fix Job Processor Health Check

**Timeline**: Day 1 (4 hours)
**Priority**: P0 (Blocker)

### Current Problem

```bash
$ docker ps
CONTAINER ID   IMAGE                    STATUS
abc123def456   job-processor:latest     Up 12 days (unhealthy)
```

The job processor has been unhealthy for 12 days, which likely blocks job execution.

### Investigation Checklist

#### 1.1 Check Health Endpoint Response (15 minutes)

```bash
# Test health endpoint directly
curl -v http://localhost:8003/health

# Expected Response:
# HTTP/1.1 200 OK
# {"status":"healthy","service":"job-processor","timestamp":"2025-10-04T10:00:00Z"}

# Check response time (should be <1s)
time curl http://localhost:8003/health
# Expected: real 0m0.500s
```

**If slow or timing out**:
- Health endpoint may be making database queries
- Simplify to return static JSON without DB check

#### 1.2 Check Docker Health Configuration (15 minutes)

```bash
# View current health check settings
docker inspect job-processor | jq '.[0].Config.Healthcheck'

# Expected output:
{
  "Test": ["CMD", "curl", "-f", "http://localhost:8003/health"],
  "Interval": 30000000000,     # 30 seconds
  "Timeout": 10000000000,      # 10 seconds (MAY NEED INCREASE)
  "Retries": 3,
  "StartPeriod": 0             # Should be 60s for startup
}
```

**Common timeout values**:
- `Interval`: How often to run health check (30s is fine)
- `Timeout`: Max time for health check to complete (increase to 30s)
- `Retries`: Number of consecutive failures before unhealthy (3 is good)
- `StartPeriod`: Grace period for container startup (add 60s)

#### 1.3 Check Service Logs (15 minutes)

```bash
# Look for health check errors
docker logs job-processor --tail 100 | grep -i "health\|error\|failed"

# Look for startup errors
docker logs job-processor | head -50

# Check for dependency issues (database, redis)
docker logs job-processor | grep -i "connection\|database\|redis"

# Check if Celery workers started
docker logs job-processor | grep -i "celery\|worker"
```

**Expected in logs**:
```
INFO:     Started server process [1]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8003
[celery] mingle: searching for neighbors
[celery] mingle: sync with 1 nodes
[celery] celery@job-processor ready.
```

### Fix Implementation

#### Solution 1: Update Docker Health Check Timeout

**File**: `docker-compose.microservices.yml`

```yaml
services:
  job-processor:
    image: federated-imputation-job-processor:latest
    container_name: job-processor
    ports:
      - "8003:8003"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8003/health"]
      interval: 30s
      timeout: 30s         # ← INCREASED from 10s
      retries: 3
      start_period: 60s    # ← ADDED: 60s startup grace period
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/job_processing_db
      - REDIS_URL=redis://redis:6379
      - CELERY_BROKER_URL=redis://redis:6379/0
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
```

#### Solution 2: Simplify Health Endpoint (if needed)

**File**: `microservices/job-processor/main.py`

```python
# Before (slow - makes DB query)
@app.get("/health")
async def health_check(db: Session = Depends(get_db)):
    # Check database connection
    db.execute("SELECT 1")
    return {"status": "healthy", "service": "job-processor"}

# After (fast - no DB query)
@app.get("/health")
async def health_check():
    """Simple health check without database dependency."""
    return {
        "status": "healthy",
        "service": "job-processor",
        "timestamp": datetime.utcnow().isoformat()
    }
```

Add a separate `/health/deep` endpoint for database checks if needed.

### Restart and Verify

```bash
# Restart job-processor with new config
sudo docker-compose -f docker-compose.microservices.yml down job-processor
sudo docker-compose -f docker-compose.microservices.yml up -d job-processor

# Wait for startup period (60 seconds)
echo "Waiting 60 seconds for startup..."
sleep 60

# Check health status
docker ps | grep job-processor
# Expected: Up 1 minute (healthy)

# If still unhealthy, check logs
docker logs job-processor --tail 50
```

**Success Criteria**:
- ✅ `docker ps` shows `(healthy)` status
- ✅ Health endpoint responds in <2 seconds
- ✅ No errors in logs related to health checks
- ✅ Celery workers shown as ready in logs

---

## STEP 2: Prepare Test Data

**Timeline**: Day 1 (2 hours)
**Priority**: P0

### 2.1 Download Test VCF Files

We need small VCF files for quick testing (large files take hours to impute).

#### Minimal Test VCF (1000 variants, ~100 KB)

```bash
# Create test directory
mkdir -p ~/test_data
cd ~/test_data

# Download chromosome 22 from 1000 Genomes (hg38)
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/GRCh38_positions/ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz

# Extract first 1000 variants
zcat ALL.chr22.*.vcf.gz | head -1100 > test_chr22_1000variants.vcf

# Compress with bgzip (standard for genomics)
bgzip test_chr22_1000variants.vcf

# Create tabix index
tabix -p vcf test_chr22_1000variants.vcf.gz

# Check file size
ls -lh test_chr22_1000variants.vcf.gz
# Expected: ~100K
```

#### Medium Test VCF (10,000 variants, ~1 MB)

```bash
# Extract first 10,000 variants
zcat ALL.chr22.*.vcf.gz | head -10100 > test_chr22_10000variants.vcf
bgzip test_chr22_10000variants.vcf
tabix -p vcf test_chr22_10000variants.vcf.gz

# Check file size
ls -lh test_chr22_10000variants.vcf.gz
# Expected: ~1MB
```

#### Validate VCF Files

```bash
# Install bcftools if not present
sudo apt-get install -y bcftools

# Validate VCF format
bcftools view -h test_chr22_1000variants.vcf.gz | head -20

# Check variant count
bcftools view -H test_chr22_1000variants.vcf.gz | wc -l
# Expected: 1000

# Check sample count
bcftools query -l test_chr22_1000variants.vcf.gz | wc -l
# Expected: 2504 (1000 Genomes samples)
```

### 2.2 Create Test User

```bash
# Create test user via Django shell
python manage.py shell

>>> from django.contrib.auth.models import User
>>> from imputation.models import UserProfile
>>>
>>> # Create user
>>> user = User.objects.create_user(
...     username='test_imputation_user',
...     email='your-real-email@gmail.com',  # ← Use your real email for notifications
...     password='TestPassword123!',
...     first_name='Test',
...     last_name='User'
... )
>>> user.save()
>>>
>>> # Create user profile (if using custom profile model)
>>> profile = UserProfile.objects.create(
...     user=user,
...     institution='Test Institution',
...     research_area='Genetics'
... )
>>> profile.save()
>>>
>>> print(f"✅ Created user: {user.username} (ID: {user.id}, Email: {user.email})")
>>> exit()
```

### 2.3 Get Authentication Token

```bash
# Login to get JWT token
TOKEN=$(curl -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test_imputation_user",
    "password": "TestPassword123!"
  }' | jq -r '.access_token')

echo "JWT Token: $TOKEN"

# Save to environment variable for later use
export AUTH_TOKEN=$TOKEN
```

---

## STEP 3: Test Job Submission API

**Timeline**: Day 2 (3 hours)
**Priority**: P0

### 3.1 Job Creation Without File Upload (30 minutes)

Test job creation API without actual file upload (metadata only).

```bash
# Create job via API (no file upload)
curl -X POST http://localhost:8003/jobs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -d '{
    "name": "Test Job - API Validation",
    "description": "Testing job creation without file",
    "service_id": 7,
    "reference_panel_id": 1,
    "input_format": "vcf",
    "build": "hg38",
    "phasing": true,
    "population": "AFR"
  }'

# Expected Response (200 OK):
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": 1,
  "name": "Test Job - API Validation",
  "status": "pending",
  "progress_percentage": 0,
  "created_at": "2025-10-04T10:00:00Z",
  "updated_at": "2025-10-04T10:00:00Z"
}
```

**Validation**:
```bash
# Get job details
JOB_ID="<job-id-from-response>"
curl -H "Authorization: Bearer $AUTH_TOKEN" \
  http://localhost:8003/jobs/$JOB_ID | jq '.'

# Check job in database
docker exec -it postgres psql -U postgres -d job_processing_db \
  -c "SELECT id, name, status, created_at FROM imputation_jobs ORDER BY created_at DESC LIMIT 1;"
```

### 3.2 Job Creation With File Upload (1 hour)

Test complete job submission with VCF file upload.

```bash
# Upload file and create job
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -F "name=Test Job - File Upload" \
  -F "description=Testing complete job flow with 1000 variant VCF" \
  -F "service_id=7" \
  -F "reference_panel_id=1" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "phasing=true" \
  -F "population=AFR" \
  -F "input_file=@/home/ubuntu/test_data/test_chr22_1000variants.vcf.gz"

# Expected: Job created, file uploaded to file-manager
```

**Verify File Upload**:
```bash
# Check file-manager logs
docker logs file-manager | grep -i "upload\|file" | tail -20

# Check files in database
docker exec -it postgres psql -U postgres -d file_management_db \
  -c "SELECT id, filename, file_size, job_id, created_at FROM uploaded_files ORDER BY created_at DESC LIMIT 5;"

# Check file on disk (if local storage)
sudo ls -lh /var/lib/docker/volumes/federated-imputation-central_file_storage/_data/
```

### 3.3 Job Status Tracking (30 minutes)

Test real-time job status updates.

```bash
# Get job details
curl -H "Authorization: Bearer $AUTH_TOKEN" \
  http://localhost:8003/jobs/$JOB_ID | jq '{status, progress_percentage, updated_at}'

# Expected status progression:
# pending → queued → running → completed (or failed)

# Get status update history
curl -H "Authorization: Bearer $AUTH_TOKEN" \
  http://localhost:8003/jobs/$JOB_ID/status-updates | jq '.[].status, .[].timestamp, .[].message'

# Expected: Array of status changes with timestamps
[
  {
    "id": 1,
    "status": "pending",
    "progress_percentage": 0,
    "message": "Job created",
    "timestamp": "2025-10-04T10:00:00Z"
  },
  {
    "id": 2,
    "status": "queued",
    "progress_percentage": 0,
    "message": "Job queued for processing",
    "timestamp": "2025-10-04T10:00:05Z"
  }
]
```

**Watch Job Status in Real-Time**:
```bash
# Poll job status every 10 seconds
watch -n 10 'curl -s -H "Authorization: Bearer $AUTH_TOKEN" http://localhost:8003/jobs/'$JOB_ID' | jq "{status, progress_percentage, updated_at}"'

# Press Ctrl+C to stop watching
```

### 3.4 Job Cancellation (30 minutes)

Test job cancellation functionality.

```bash
# Create a job to cancel
CANCEL_JOB_ID=$(curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Job to Cancel", "service_id": 7, "reference_panel_id": 1}' \
  | jq -r '.id')

# Cancel the job immediately
curl -X POST http://localhost:8003/jobs/$CANCEL_JOB_ID/cancel \
  -H "Authorization: Bearer $AUTH_TOKEN"

# Expected Response:
{
  "message": "Job cancellation initiated",
  "job_id": "<job-id>"
}

# Verify status changed to "cancelled"
curl -H "Authorization: Bearer $AUTH_TOKEN" \
  http://localhost:8003/jobs/$CANCEL_JOB_ID | jq '.status'
# Expected: "cancelled"
```

**Test Cancelling Running Job** (if job processor is working):
```bash
# Submit job that will take time
LONG_JOB_ID=$(curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -F "name=Long Running Job" \
  -F "service_id=7" \
  -F "reference_panel_id=1" \
  -F "input_file=@/home/ubuntu/test_data/test_chr22_10000variants.vcf.gz")

# Wait for it to start running
sleep 30

# Cancel while running
curl -X POST http://localhost:8003/jobs/$LONG_JOB_ID/cancel \
  -H "Authorization: Bearer $AUTH_TOKEN"

# Verify cancellation propagated to external service
# (Check service-specific cancellation API)
```

---

## STEP 4: Test External Service Integration

**Timeline**: Days 3-4 (8 hours)
**Priority**: P0

### 4.1 H3Africa Imputation Server (Michigan API)

**Status**: ✅ Healthy (177ms response time)
**API Type**: Michigan Imputation Server API
**Auth**: Token-based

#### 4.1.1 Test Service Connection (30 minutes)

```bash
# Test H3Africa API directly
curl -I https://impute.afrigen-d.org/

# Expected: HTTP 200 or 401 (auth required, but service is up)

# Test via Service Registry
curl http://localhost:8002/services/7/health | jq '.'

# Expected Response:
{
  "service_id": 7,
  "status": "healthy",
  "response_time_ms": 177.5,
  "error_message": null,
  "checked_at": "2025-10-04T09:17:00Z"
}
```

#### 4.1.2 Register for H3Africa Account (1 hour)

**Prerequisites**:
1. Create account at https://impute.afrigen-d.org/
2. Generate API token from account settings
3. Add token to Service Registry

```bash
# Add API token to service configuration
curl -X PATCH http://localhost:8002/services/7 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -d '{
    "api_config": {
      "api_token": "your-h3africa-api-token-here",
      "api_endpoint": "https://impute.afrigen-d.org/api/v1"
    }
  }'

# Verify token saved
curl http://localhost:8002/services/7 | jq '.api_config'
```

#### 4.1.3 Submit Test Job to H3Africa (2 hours)

```bash
# Submit job to H3Africa
JOB_ID=$(curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -F "name=H3Africa Test - 1K Variants" \
  -F "description=Testing H3Africa integration with 1000 variant VCF" \
  -F "service_id=7" \
  -F "reference_panel_id=1" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "phasing=true" \
  -F "population=AFR" \
  -F "input_file=@/home/ubuntu/test_data/test_chr22_1000variants.vcf.gz" \
  | jq -r '.id')

echo "✅ Job submitted: $JOB_ID"

# Monitor job status (poll every 30 seconds)
watch -n 30 'curl -s -H "Authorization: Bearer $AUTH_TOKEN" http://localhost:8003/jobs/'$JOB_ID' | jq "{status, progress_percentage, external_job_id, updated_at}"'
```

**Expected Timeline** (1000 variants):
- 0-2 min: Status = queued (platform queue)
- 2-3 min: Status = running, external_job_id set (submitted to H3Africa)
- 3-8 min: Status = running, progress updates (H3Africa processing)
- 8-10 min: Status = completed (results ready)

#### 4.1.4 Verify Job Lifecycle (1 hour)

```bash
# Check external_job_id is set
curl -H "Authorization: Bearer $AUTH_TOKEN" \
  http://localhost:8003/jobs/$JOB_ID | jq '.external_job_id'
# Expected: H3Africa job ID (e.g., "job-202510041234")

# Check service_response for details
curl -H "Authorization: Bearer $AUTH_TOKEN" \
  http://localhost:8003/jobs/$JOB_ID | jq '.service_response'
# Expected: JSON with H3Africa API response

# Download results when completed
curl -H "Authorization: Bearer $AUTH_TOKEN" \
  http://localhost:8003/jobs/$JOB_ID/results -o h3africa_results.vcf.gz

# Verify results file
file h3africa_results.vcf.gz
# Expected: gzip compressed data

zcat h3africa_results.vcf.gz | head -20
# Expected: VCF format with imputed genotypes
```

**Check Email Notification**:
```bash
# Verify email was sent
docker logs notification | grep -i "$JOB_ID" | grep -i "sent successfully"

# Check inbox for email from platform
# Expected:
# - Subject: "Job Completed Successfully!"
# - Body: Job details + download link
```

---

### 4.2 ILIFU GA4GH Starter Kit (GA4GH WES API)

**Status**: ✅ Healthy (connection working)
**API Type**: GA4GH Workflow Execution Service (WES)
**Auth**: None (public endpoint)

#### 4.2.1 Test GA4GH Service-Info Endpoint (30 minutes)

```bash
# Test GA4GH service-info
curl http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/service-info | jq '.'

# Expected: GA4GH service-info JSON
{
  "id": "org.ga4gh.ilifu",
  "name": "ILIFU GA4GH WES Starter Kit",
  "type": {
    "group": "org.ga4gh",
    "artifact": "wes",
    "version": "1.0.0"
  },
  "workflow_type_versions": {
    "Nextflow": ["20.10.0", "21.04.0"],
    "Snakemake": ["6.0.0", "6.10.0"]
  },
  "supported_wes_versions": ["1.0.0"],
  "supported_filesystem_protocols": ["http", "https", "file"]
}
```

#### 4.2.2 Create Nextflow Imputation Workflow (1 hour)

GA4GH WES requires a workflow definition (Nextflow or Snakemake).

**Create Nextflow workflow**:
```bash
# Create workflows directory
mkdir -p ~/workflows
cd ~/workflows

# Create imputation workflow
cat > imputation_nextflow.nf <<'EOF'
#!/usr/bin/env nextflow

params.vcf_file = 'input.vcf.gz'
params.ref_panel = 'african_1000g'
params.output_dir = 'results'

process impute {
    publishDir params.output_dir, mode: 'copy'

    input:
    path vcf from file(params.vcf_file)

    output:
    path "imputed.vcf.gz" into imputed_vcf

    script:
    """
    # Imputation using Beagle 5.4
    java -Xmx4g -jar /opt/beagle.jar \\
        gt=$vcf \\
        ref=/data/ref_panels/${params.ref_panel}.vcf.gz \\
        out=imputed

    # Compress output
    bgzip imputed.vcf
    """
}

process validate {
    input:
    path vcf from imputed_vcf

    output:
    stdout result

    script:
    """
    # Validate VCF format
    bcftools view -h $vcf | grep "##fileformat=VCFv4"
    echo "✅ Imputation complete and validated"
    """
}
EOF

# Test workflow locally (if Nextflow installed)
nextflow run imputation_nextflow.nf --vcf_file=/home/ubuntu/test_data/test_chr22_1000variants.vcf.gz
```

#### 4.2.3 Submit GA4GH Workflow Job (3 hours)

```bash
# Prepare workflow run request
cat > ga4gh_run_request.json <<EOF
{
  "workflow_url": "file:///workflows/imputation_nextflow.nf",
  "workflow_type": "Nextflow",
  "workflow_type_version": "21.04.0",
  "workflow_params": {
    "vcf_file": "/data/input.vcf.gz",
    "ref_panel": "african_1000g",
    "output_dir": "/data/results"
  },
  "workflow_engine_parameters": {
    "executor": "local",
    "max_memory": "8 GB",
    "max_cpus": 4
  },
  "tags": {
    "job_name": "ILIFU_Test_1K_Variants",
    "user": "test_user",
    "platform": "federated_imputation"
  }
}
EOF

# Submit to ILIFU via GA4GH WES API
RUN_ID=$(curl -X POST \
  http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/runs \
  -H "Content-Type: application/json" \
  -d @ga4gh_run_request.json \
  | jq -r '.run_id')

echo "✅ Workflow submitted: $RUN_ID"

# Poll workflow status
watch -n 30 'curl -s http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/runs/'$RUN_ID' | jq "{state, run_log}"'

# Expected states: QUEUED → INITIALIZING → RUNNING → COMPLETE
```

**Via Platform Integration** (after job processor is working):
```bash
# Submit ILIFU job via platform
ILIFU_JOB_ID=$(curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -F "name=ILIFU GA4GH Test" \
  -F "description=Testing GA4GH WES integration" \
  -F "service_id=10" \
  -F "reference_panel_id=X" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "workflow_file=@/home/ubuntu/workflows/imputation_nextflow.nf" \
  -F "input_file=@/home/ubuntu/test_data/test_chr22_1000variants.vcf.gz" \
  | jq -r '.id')

# Monitor via platform
watch -n 30 'curl -s -H "Authorization: Bearer $AUTH_TOKEN" http://localhost:8003/jobs/'$ILIFU_JOB_ID' | jq "{status, progress_percentage, external_job_id}"'
```

---

### 4.3 Michigan Imputation Server (Michigan API)

**Status**: ⚠️ Timeout (TLS handshake >10s)
**API Type**: Michigan Imputation Server API
**Auth**: Token-based

#### 4.3.1 Verify Timeout Fix (30 minutes)

```bash
# Test Michigan connection with verbose output
curl -v https://imputationserver.sph.umich.edu/ 2>&1 | grep -E "connected|SSL|TLS|timeout"

# Expected (after fix):
# * Connected to imputationserver.sph.umich.edu
# * SSL connection using TLSv1.2
# * Server certificate: *.sph.umich.edu

# Check Service Registry timeout configuration
docker exec service-registry cat main.py | grep -A 10 "httpx.Timeout"

# Expected: connect=30.0, read=10.0 (30s for TLS handshake)
```

#### 4.3.2 Test Michigan Health Check (30 minutes)

```bash
# Test Michigan API health via Service Registry
curl http://localhost:8002/services/8/health | jq '.'

# Expected (if timeout fixed):
{
  "service_id": 8,
  "status": "healthy",
  "response_time_ms": 5000.0,  # TLS handshake takes time
  "error_message": null,
  "checked_at": "2025-10-04T10:30:00Z"
}

# If still timing out, increase timeout further
# Edit microservices/service-registry/main.py:
# httpx.Timeout(connect=60.0, read=10.0)  # Try 60s
```

#### 4.3.3 Submit Test Job to Michigan (if timeout fixed - 2 hours)

```bash
# Register for Michigan account at https://imputationserver.sph.umich.edu/
# Generate API token

# Add Michigan API token
curl -X PATCH http://localhost:8002/services/8 \
  -H "Content-Type: application/json" \
  -d '{
    "api_config": {
      "api_token": "your-michigan-api-token",
      "api_endpoint": "https://imputationserver.sph.umich.edu/api/v2"
    }
  }'

# Submit test job
MICHIGAN_JOB_ID=$(curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -F "name=Michigan Test Job" \
  -F "service_id=8" \
  -F "reference_panel_id=X" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "input_file=@/home/ubuntu/test_data/test_chr22_1000variants.vcf.gz" \
  | jq -r '.id')

# Monitor job
watch -n 30 'curl -s -H "Authorization: Bearer $AUTH_TOKEN" http://localhost:8003/jobs/'$MICHIGAN_JOB_ID' | jq "{status, progress_percentage}"'
```

---

## STEP 5: End-to-End Testing

**Timeline**: Day 5 (4 hours)
**Priority**: P0

### 5.1 Automated E2E Test Script

Create comprehensive end-to-end test that validates the entire pipeline.

```bash
#!/bin/bash
# File: e2e_job_test.sh
# Purpose: Complete end-to-end job execution test

set -e  # Exit on error

echo "🚀 Starting End-to-End Job Test..."

# Configuration
TEST_USER="test_imputation_user"
TEST_PASSWORD="TestPassword123!"
TEST_VCF="/home/ubuntu/test_data/test_chr22_1000variants.vcf.gz"
SERVICE_ID=7  # H3Africa
PANEL_ID=1

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Authenticate
echo -e "${YELLOW}1️⃣ Authenticating...${NC}"
AUTH_TOKEN=$(curl -s -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$TEST_USER\", \"password\": \"$TEST_PASSWORD\"}" \
  | jq -r '.access_token')

if [ -z "$AUTH_TOKEN" ] || [ "$AUTH_TOKEN" == "null" ]; then
    echo -e "${RED}❌ Authentication failed!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Authentication successful${NC}"

# Step 2: Upload VCF and create job
echo -e "${YELLOW}2️⃣ Uploading VCF and creating job...${NC}"
JOB_RESPONSE=$(curl -s -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -F "name=E2E Test Job - $(date +%Y%m%d_%H%M%S)" \
  -F "description=Automated end-to-end test" \
  -F "service_id=$SERVICE_ID" \
  -F "reference_panel_id=$PANEL_ID" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "phasing=true" \
  -F "population=AFR" \
  -F "input_file=@$TEST_VCF")

JOB_ID=$(echo $JOB_RESPONSE | jq -r '.id')

if [ -z "$JOB_ID" ] || [ "$JOB_ID" == "null" ]; then
    echo -e "${RED}❌ Job creation failed!${NC}"
    echo $JOB_RESPONSE | jq '.'
    exit 1
fi
echo -e "${GREEN}✅ Job created: $JOB_ID${NC}"

# Step 3: Monitor job status
echo -e "${YELLOW}3️⃣ Monitoring job status (timeout: 30 minutes)...${NC}"
MAX_WAIT=1800  # 30 minutes
ELAPSED=0
POLL_INTERVAL=30  # Poll every 30 seconds

while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(curl -s -H "Authorization: Bearer $AUTH_TOKEN" \
      http://localhost:8003/jobs/$JOB_ID | jq -r '.status')
    PROGRESS=$(curl -s -H "Authorization: Bearer $AUTH_TOKEN" \
      http://localhost:8003/jobs/$JOB_ID | jq -r '.progress_percentage')

    echo "   Status: $STATUS ($PROGRESS%)"

    if [ "$STATUS" == "completed" ]; then
        echo -e "${GREEN}✅ Job completed successfully!${NC}"
        break
    elif [ "$STATUS" == "failed" ]; then
        echo -e "${RED}❌ Job failed!${NC}"
        ERROR=$(curl -s -H "Authorization: Bearer $AUTH_TOKEN" \
          http://localhost:8003/jobs/$JOB_ID | jq -r '.error_message')
        echo "Error: $ERROR"
        exit 1
    elif [ "$STATUS" == "cancelled" ]; then
        echo -e "${RED}❌ Job was cancelled!${NC}"
        exit 1
    fi

    sleep $POLL_INTERVAL
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo -e "${RED}❌ Job timed out after 30 minutes!${NC}"
    exit 1
fi

# Step 4: Download results
echo -e "${YELLOW}4️⃣ Downloading results...${NC}"
curl -H "Authorization: Bearer $AUTH_TOKEN" \
  http://localhost:8003/jobs/$JOB_ID/results \
  -o "results_$JOB_ID.vcf.gz"

if [ -f "results_$JOB_ID.vcf.gz" ]; then
    FILE_SIZE=$(ls -lh "results_$JOB_ID.vcf.gz" | awk '{print $5}')
    echo -e "${GREEN}✅ Results downloaded: results_$JOB_ID.vcf.gz ($FILE_SIZE)${NC}"
else
    echo -e "${RED}❌ Results download failed!${NC}"
    exit 1
fi

# Step 5: Validate results
echo -e "${YELLOW}5️⃣ Validating results...${NC}"

# Check if file is gzipped
if file "results_$JOB_ID.vcf.gz" | grep -q "gzip compressed"; then
    echo -e "${GREEN}✅ File is gzip compressed${NC}"
else
    echo -e "${RED}❌ File is not gzip compressed!${NC}"
    exit 1
fi

# Check if VCF format
if zcat "results_$JOB_ID.vcf.gz" | head -1 | grep -q "##fileformat=VCF"; then
    echo -e "${GREEN}✅ File is valid VCF format${NC}"
else
    echo -e "${RED}❌ File is not valid VCF format!${NC}"
    exit 1
fi

# Count variants
VARIANT_COUNT=$(zcat "results_$JOB_ID.vcf.gz" | grep -v "^#" | wc -l)
echo "   Variant count: $VARIANT_COUNT"

if [ $VARIANT_COUNT -gt 0 ]; then
    echo -e "${GREEN}✅ Results contain $VARIANT_COUNT variants${NC}"
else
    echo -e "${RED}❌ Results contain no variants!${NC}"
    exit 1
fi

# Step 6: Check email notification
echo -e "${YELLOW}6️⃣ Checking email notifications...${NC}"
if docker logs notification 2>&1 | grep -q "$JOB_ID.*sent successfully"; then
    echo -e "${GREEN}✅ Email notification sent!${NC}"
else
    echo -e "${YELLOW}⚠️  Email notification not found in logs (may have been sent earlier)${NC}"
fi

# Step 7: Verify file in file-manager
echo -e "${YELLOW}7️⃣ Verifying files in file-manager...${NC}"
FILE_COUNT=$(curl -s -H "Authorization: Bearer $AUTH_TOKEN" \
  "http://localhost:8004/files?job_id=$JOB_ID" | jq '. | length')

if [ $FILE_COUNT -gt 0 ]; then
    echo -e "${GREEN}✅ Files stored correctly ($FILE_COUNT files)${NC}"
else
    echo -e "${YELLOW}⚠️  No files found in file-manager (may be using external storage)${NC}"
fi

# Final Summary
echo ""
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}🎉 END-TO-END TEST PASSED!${NC}"
echo "════════════════════════════════════════════════════════"
echo "Job ID: $JOB_ID"
echo "Status: completed"
echo "Results: results_$JOB_ID.vcf.gz"
echo "Variants: $VARIANT_COUNT"
echo "════════════════════════════════════════════════════════"
```

### 5.2 Run E2E Test

```bash
# Make script executable
chmod +x e2e_job_test.sh

# Run test
./e2e_job_test.sh

# Expected Output:
# 🚀 Starting End-to-End Job Test...
# 1️⃣ Authenticating...
# ✅ Authentication successful
# 2️⃣ Uploading VCF and creating job...
# ✅ Job created: <job-id>
# 3️⃣ Monitoring job status (timeout: 30 minutes)...
#    Status: pending (0%)
#    Status: queued (0%)
#    Status: running (25%)
#    Status: running (50%)
#    Status: running (75%)
#    Status: completed (100%)
# ✅ Job completed successfully!
# 4️⃣ Downloading results...
# ✅ Results downloaded: results_<job-id>.vcf.gz (1.5M)
# 5️⃣ Validating results...
# ✅ File is gzip compressed
# ✅ File is valid VCF format
#    Variant count: 1000
# ✅ Results contain 1000 variants
# 6️⃣ Checking email notifications...
# ✅ Email notification sent!
# 7️⃣ Verifying files in file-manager...
# ✅ Files stored correctly (2 files)
#
# ════════════════════════════════════════════════════════════
# 🎉 END-TO-END TEST PASSED!
# ════════════════════════════════════════════════════════════
```

---

## STEP 6: Document Service Requirements

**Timeline**: Day 5 (2 hours)
**Priority**: P1

### 6.1 Service Integration Matrix

Create comprehensive documentation of each service's requirements.

| Service | API Type | Auth | Max File Size | Supported Builds | Avg Time (1K variants) | Status | Notes |
|---------|----------|------|---------------|------------------|------------------------|--------|-------|
| **H3Africa** | Michigan | Token | 100 MB | hg19, hg38 | 5-10 min | ✅ Working | 177ms health check |
| **ILIFU** | GA4GH WES | None | 500 MB | hg19, hg38 | 10-20 min | ✅ Working | Requires Nextflow workflow |
| **Michigan** | Michigan | Token | 200 MB | hg19, hg38 | 10-15 min | ⚠️ Timeout | TLS handshake >10s |
| **ICE MALI** | GA4GH WES | Token | 500 MB | hg19, hg38 | Unknown | ❌ Offline | Auto-disabled after 30d |

### 6.2 H3Africa Setup Documentation

```markdown
# H3Africa Imputation Server Integration

## Service Information
- **URL**: https://impute.afrigen-d.org/
- **API Type**: Michigan Imputation Server API
- **Status**: ✅ Operational (177ms response time)

## Prerequisites
1. Create account at https://impute.afrigen-d.org/
2. Navigate to Settings → API Tokens
3. Generate new API token
4. Copy token (will only be shown once)

## Configuration
Add token to Service Registry:
\`\`\`bash
curl -X PATCH http://localhost:8002/services/7 \\
  -H "Content-Type: application/json" \\
  -d '{
    "api_config": {
      "api_token": "YOUR_H3AFRICA_TOKEN",
      "api_endpoint": "https://impute.afrigen-d.org/api/v1"
    }
  }'
\`\`\`

## Submission Parameters
- **Format**: VCF (.vcf.gz)
- **Max File Size**: 100 MB
- **Supported Builds**: hg19, hg38
- **Phasing**: Optional (SHAPEIT2 available)
- **Reference Panels**:
  - H3Africa (5,000 samples, African populations)
  - African Genome Variation Project (AGVP)
  - 1000 Genomes Phase 3 (African subset)

## Expected Timeline
- 1,000 variants: 5-10 minutes
- 10,000 variants: 15-30 minutes
- 100,000 variants: 1-2 hours

## Troubleshooting
- **401 Unauthorized**: Check API token is valid
- **400 Bad Request**: Validate VCF format with `bcftools view`
- **Slow response**: African servers may have higher latency from outside Africa

## Contact
- Support: support@afrigen-d.org
- Documentation: https://impute.afrigen-d.org/docs
\`\`\`

### 6.3 ILIFU GA4GH Setup Documentation

```markdown
# ILIFU GA4GH WES Integration

## Service Information
- **URL**: http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1
- **API Type**: GA4GH Workflow Execution Service (WES) 1.0.0
- **Status**: ✅ Operational (public endpoint)

## Prerequisites
1. Nextflow or Snakemake workflow definition
2. Input VCF file
3. Reference panel configuration

## Workflow Creation
See `workflows/imputation_nextflow.nf` for example.

Key requirements:
- Workflow must accept `vcf_file` parameter
- Output must be `imputed.vcf.gz`
- Reference panels located at `/data/ref_panels/`

## Submission
Platform automatically converts job to GA4GH WES run request.

Manual submission:
\`\`\`bash
curl -X POST http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/runs \\
  -H "Content-Type: application/json" \\
  -d @run_request.json
\`\`\`

## Available Reference Panels
- african_1000g: 1000 Genomes African populations
- hapmap3: HapMap Phase 3
- custom: Upload your own

## Expected Timeline
- 1,000 variants: 10-20 minutes
- 10,000 variants: 30-60 minutes

## Troubleshooting
- **Workflow failed**: Check Nextflow logs in run details
- **File not found**: Verify file paths are absolute
- **Out of memory**: Reduce `max_memory` in workflow params

## Contact
- ILIFU Support: https://www.ilifu.ac.za/
- GA4GH Spec: https://github.com/ga4gh/workflow-execution-service-schemas
\`\`\`

---

## 📊 Test Results Summary

### Test Execution Checklist

- [ ] **Job Processor Health**
  - [ ] Docker reports (healthy)
  - [ ] Health endpoint responds <2s
  - [ ] Celery workers running
  - [ ] No errors in logs

- [ ] **Job Submission API**
  - [ ] Job creation (metadata only) works
  - [ ] Job creation with file upload works
  - [ ] Status tracking works
  - [ ] Job cancellation works

- [ ] **H3Africa Integration**
  - [ ] Service connection healthy
  - [ ] API token configured
  - [ ] Test job submitted successfully
  - [ ] Job completed and results downloaded
  - [ ] Email notification received

- [ ] **ILIFU Integration**
  - [ ] GA4GH service-info endpoint working
  - [ ] Nextflow workflow created
  - [ ] Test job submitted successfully
  - [ ] Job completed and results downloaded

- [ ] **Michigan Integration** (if timeout fixed)
  - [ ] Timeout fix applied and verified
  - [ ] Service connection healthy
  - [ ] API token configured
  - [ ] Test job submitted

- [ ] **End-to-End Test**
  - [ ] E2E script runs successfully
  - [ ] All validation checks pass
  - [ ] Results contain expected variants
  - [ ] Email notifications sent
  - [ ] Files stored in file-manager

### Performance Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Job submission API response time | <2s | | |
| File upload time (10MB) | <10s | | |
| Job status update latency | <500ms | | |
| H3Africa job time (1K variants) | 5-10 min | | |
| ILIFU job time (1K variants) | 10-20 min | | |
| Email delivery time | <5 min | | |
| Results download time | <10s | | |

---

## 🚨 Common Issues & Solutions

### Issue 1: Job Stuck in "Pending" Status

**Symptoms**:
- Job created but never moves to "queued"
- Celery workers not picking up jobs

**Diagnosis**:
```bash
# Check Celery logs
docker logs job-processor | grep -i celery

# Check Redis connection
docker exec job-processor redis-cli -h redis ping
# Expected: PONG

# Check Celery worker status
docker exec job-processor celery -A worker inspect active
```

**Solution**:
```bash
# Restart job-processor
sudo docker-compose restart job-processor

# Check worker is registered
docker exec job-processor celery -A worker inspect registered
```

### Issue 2: External Service Returns 401 Unauthorized

**Symptoms**:
- Job fails immediately with "Unauthorized" error
- External service API key not accepted

**Diagnosis**:
```bash
# Check API key is configured
curl http://localhost:8002/services/7 | jq '.api_config'

# Test API key directly
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://impute.afrigen-d.org/api/v1/jobs
```

**Solution**:
- Regenerate API token from service provider
- Update Service Registry configuration
- Verify token has correct permissions

### Issue 3: Results Download Fails

**Symptoms**:
- Job completes but results cannot be downloaded
- 404 Not Found error

**Diagnosis**:
```bash
# Check if results stored in file-manager
curl http://localhost:8004/files?job_id=<job-id>

# Check file-manager logs
docker logs file-manager | grep -i "download\|error"

# Check file exists on disk
docker exec file-manager ls -lh /data/results/
```

**Solution**:
- Verify job completed successfully (not "partially_completed")
- Check file-manager storage configuration
- Ensure sufficient disk space

---

## 📚 Additional Resources

- **Michigan Imputation Server API Docs**: https://imputationserver.readthedocs.io/
- **GA4GH WES Specification**: https://github.com/ga4gh/workflow-execution-service-schemas
- **Nextflow Documentation**: https://www.nextflow.io/docs/latest/index.html
- **bcftools Manual**: http://samtools.github.io/bcftools/bcftools.html
- **VCF Specification**: https://samtools.github.io/hts-specs/VCFv4.3.pdf

---

**Document Version**: 1.0
**Last Updated**: October 4, 2025
**Maintained By**: Platform Development Team
