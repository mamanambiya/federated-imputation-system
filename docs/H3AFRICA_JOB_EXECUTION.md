# H3Africa Job Execution - Complete Integration Guide

**Last Updated**: October 4, 2025
**Service Type**: MICHIGAN (H3Africa Imputation Server)
**API Version**: Michigan Imputation Server API v2

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Service Setup](#service-setup)
4. [API Endpoints](#api-endpoints)
5. [Job Lifecycle](#job-lifecycle)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)
8. [API Reference](#api-reference)

---

## Overview

This document provides complete instructions for implementing and testing job execution with the **H3Africa Imputation Server** using the platform's job processing capabilities.

### Architecture Flow

```
User → Frontend → API Gateway → Job Processor → H3Africa API
                                      ↓
                              File Manager (storage)
                                      ↓
                              Notification (email/web)
```

### Authentication Architecture

The platform implements a **two-layer authentication** system:

**Layer 1: Platform User Authentication**
- Users authenticate to **our platform** (not H3Africa)
- Credentials: `test_user` / `test123` (configured in our database)
- Returns: JWT token for API access
- Usage: All requests to our platform endpoints

**Layer 2: Service Authentication**
- Our backend authenticates to H3Africa
- Token: H3Africa API token (from https://impute.afrigen-d.org/)
- Stored: Service Registry database (`api_config.api_token`)
- Usage: Backend-to-H3Africa communication

**Complete Authentication Flow:**

```
┌──────────────────────────────────────────────────────┐
│            User (Browser/CLI)                        │
│   Credentials: test_user / test123                   │
└──────────────┬───────────────────────────────────────┘
               │
               │ 1. Login to OUR platform
               ↓
┌──────────────────────────────────────────────────────┐
│      Our Platform - User Service (Port 8001)         │
│   ✓ Validates credentials in our database            │
│   ✓ Returns JWT: eyJhbG...                           │
└──────────────┬───────────────────────────────────────┘
               │
               │ 2. Submit job with Platform JWT
               ↓
┌──────────────────────────────────────────────────────┐
│    Our Platform - Job Processor (Port 8003)          │
│   ✓ Validates user's JWT                             │
│   ✓ Creates job record for this user                 │
│   ✓ Queues job for Celery worker                     │
└──────────────┬───────────────────────────────────────┘
               │
               │ 3. Backend processes job asynchronously
               ↓
┌──────────────────────────────────────────────────────┐
│       Our Platform - Celery Worker (Backend)         │
│   1. Retrieves H3Africa token from Service Registry   │
│   2. Downloads input file from File Manager           │
│   3. Submits to H3Africa using H3Africa token        │
└──────────────┬───────────────────────────────────────┘
               │
               │ 4. External API call with H3Africa auth
               ↓
┌──────────────────────────────────────────────────────┐
│         H3Africa Imputation Service                  │
│         https://impute.afrigen-d.org                 │
│   Header: X-Auth-Token: <H3Africa_API_Token>         │
│   ✓ Validates H3Africa token                         │
│   ✓ Processes imputation job                         │
│   ✓ Returns external_job_id                          │
│   ✓ Provides results when complete                   │
└──────────────────────────────────────────────────────┘
```

**Key Benefits:**
- ✅ Users don't need H3Africa accounts
- ✅ Single authentication point (our platform)
- ✅ Centralized service credential management
- ✅ One H3Africa token serves all platform users
- ✅ Better security (users never see H3Africa token)

### Key Features

✅ **Asynchronous job processing** with Celery workers
✅ **Real-time status tracking** with progress updates
✅ **Automatic result retrieval** from external service
✅ **Email notifications** at each lifecycle stage
✅ **Comprehensive error handling** with retry logic
✅ **File management** for inputs and outputs

---

## Prerequisites

### 1. H3Africa Account Setup

1. **Register** at [https://impute.afrigen-d.org/](https://impute.afrigen-d.org/)
2. **Navigate** to Settings → API Tokens
3. **Generate** new API token
4. **Save** token securely (shown only once)

### 2. System Requirements

- Docker and docker-compose
- Python 3.10+
- bcftools (for VCF validation)
- At least 2GB free disk space

### 3. Test Data

Run the test data preparation script:

```bash
bash scripts/prepare_test_data.sh
```

This creates:
- `test_tiny_100var.vcf.gz` - 100 variants (~20KB) - Quick tests
- `test_small_1000var.vcf.gz` - 1K variants (~200KB) - Standard tests
- `test_medium_10kvar.vcf.gz` - 10K variants (~2MB) - Realistic tests

---

## Service Setup

### Step 1: Register H3Africa Service

```bash
python scripts/setup_h3africa_service.py --api-token YOUR_H3AFRICA_TOKEN
```

This script:
1. Creates H3Africa service entry in Service Registry
2. Adds reference panels (H3Africa, 1000G African, AGVP)
3. Runs health check to verify connectivity

**Expected Output:**
```
✅ Service created successfully - ID: 1
   Name: H3Africa Imputation Server
   Type: michigan
   URL: https://impute.afrigen-d.org

✅ Created panel: H3Africa Reference Panel (h3africa)
✅ Created panel: 1000 Genomes - African Subset (1000g_afr)
✅ Created panel: African Genome Variation Project (agvp)

✅ Service is healthy - Response time: 177.5ms
```

### Step 2: Verify Service Registration

**Option A: Via API**
```bash
curl http://localhost:8002/services/1 | jq '.'
```

**Option B: Via Django Admin**
1. Navigate to http://localhost:8000/admin/
2. Go to Imputation Services
3. Verify H3Africa service is listed and active

---

## API Endpoints

### Job Management Endpoints

#### 1. Create Job (with file upload)

**POST** `/jobs`

**Request:**
```bash
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=My Imputation Job" \
  -F "description=Test job for H3Africa" \
  -F "service_id=1" \
  -F "reference_panel_id=1" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "phasing=true" \
  -F "population=AFR" \
  -F "input_file=@~/test_data/test_small_1000var.vcf.gz"
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": 1,
  "name": "My Imputation Job",
  "status": "queued",
  "progress_percentage": 0,
  "service_id": 1,
  "reference_panel_id": 1,
  "input_format": "vcf",
  "build": "hg38",
  "phasing": true,
  "population": "AFR",
  "input_file_name": "test_small_1000var.vcf.gz",
  "created_at": "2025-10-04T10:00:00Z",
  "updated_at": "2025-10-04T10:00:00Z"
}
```

#### 2. Get Job Status

**GET** `/jobs/{job_id}`

**Request:**
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs/550e8400-e29b-41d4-a716-446655440000 | jq '.'
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "running",
  "progress_percentage": 45,
  "external_job_id": "job-20251004-abc123",
  "started_at": "2025-10-04T10:00:30Z",
  "execution_time_seconds": 120,
  ...
}
```

#### 3. Monitor Job Status History

**GET** `/jobs/{job_id}/status-updates`

**Request:**
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs/550e8400-e29b-41d4-a716-446655440000/status-updates | jq '.'
```

**Response:**
```json
[
  {
    "id": 4,
    "job_id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "running",
    "progress_percentage": 45,
    "message": "Job in progress: running",
    "timestamp": "2025-10-04T10:02:30Z"
  },
  {
    "id": 3,
    "job_id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "running",
    "progress_percentage": 10,
    "message": "Job submitted to external service",
    "timestamp": "2025-10-04T10:00:35Z"
  },
  ...
]
```

#### 4. List All Jobs

**GET** `/jobs?status={status}&service_id={service_id}`

**Request:**
```bash
# All jobs
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs | jq '.'

# Filter by status
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs?status=completed | jq '.'

# Filter by service
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs?service_id=1 | jq '.'
```

#### 5. Download Results

**GET** `/jobs/{job_id}/results`

**Request:**
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs/550e8400-e29b-41d4-a716-446655440000/results \
  -o results.zip
```

**Response (JSON):**
```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "job_name": "My Imputation Job",
  "file_id": 123,
  "filename": "results.zip",
  "file_size": 1548576,
  "download_url": "http://localhost:8004/files/123/download",
  "created_at": "2025-10-04T10:10:00Z",
  "message": "Results ready for download"
}
```

#### 6. Cancel Job

**POST** `/jobs/{job_id}/cancel`

**Request:**
```bash
curl -X POST -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs/550e8400-e29b-41d4-a716-446655440000/cancel
```

**Response:**
```json
{
  "message": "Job cancellation initiated",
  "job_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

## Job Lifecycle

### Status Flow

```
pending → queued → running → completed
                     ↓
                   failed
                     ↓
                 cancelled
```

### Status Descriptions

| Status | Description | Actions |
|--------|-------------|---------|
| **pending** | Job created, waiting to be queued | None |
| **queued** | Queued for processing by Celery worker | Wait |
| **running** | Submitted to H3Africa, processing | Monitor progress |
| **completed** | Job finished, results available | Download results |
| **failed** | Job failed with error | Check error_message |
| **cancelled** | User cancelled the job | None |

### Progress Tracking

Progress percentage is calculated as:

- **0-10%**: Job submission to external service
- **10-90%**: External service processing (interpolated from service status)
- **90-100%**: Results download and storage

### Notifications

Email notifications are sent at:

1. **Job Queued** - Confirmation of submission
2. **Job Running** - External processing started
3. **Job Completed** - Results ready with download link
4. **Job Failed** - Error details and retry suggestions

---

## Testing

### Quick Test (2-5 minutes)

```bash
# 1. Setup service
python scripts/setup_h3africa_service.py --api-token YOUR_TOKEN

# 2. Prepare test data
bash scripts/prepare_test_data.sh

# 3. Run E2E test
bash scripts/e2e_h3africa_test.sh
```

### Manual Testing Steps

#### 1. Create Test User

```python
python manage.py shell

from django.contrib.auth.models import User
user = User.objects.create_user(
    username='test_user',
    email='your.email@example.com',
    password='test123'
)
user.save()
```

#### 2. Get Authentication Token

```bash
TOKEN=$(curl -s -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test_user","password":"test123"}' \
  | jq -r '.access_token')

echo "Token: $TOKEN"
```

#### 3. Submit Test Job

```bash
JOB_ID=$(curl -s -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=Test Job - $(date +%Y%m%d_%H%M%S)" \
  -F "service_id=1" \
  -F "reference_panel_id=1" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "phasing=true" \
  -F "population=AFR" \
  -F "input_file=@$HOME/test_data/test_small_1000var.vcf.gz" \
  | jq -r '.id')

echo "Job ID: $JOB_ID"
```

#### 4. Monitor Status (Auto-refresh)

```bash
watch -n 10 "curl -s -H 'Authorization: Bearer $TOKEN' \
  http://localhost:8003/jobs/$JOB_ID | jq '{status, progress_percentage, external_job_id, updated_at}'"
```

#### 5. Download Results (when completed)

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs/$JOB_ID/results \
  -o results_$JOB_ID.zip

# Verify results
unzip -l results_$JOB_ID.zip
```

### Expected Timeline

| Test File | Variants | Expected Time | Use Case |
|-----------|----------|---------------|----------|
| test_tiny_100var.vcf.gz | 100 | 2-5 min | Quick API validation |
| test_small_1000var.vcf.gz | 1,000 | 5-10 min | Standard E2E test |
| test_medium_10kvar.vcf.gz | 10,000 | 15-30 min | Realistic test |

---

## Troubleshooting

### Issue 1: Job Stuck in "Pending"

**Symptoms:**
- Job created but status remains "pending"
- No progress after several minutes

**Diagnosis:**
```bash
# Check job processor health
docker ps | grep job-processor

# Check Celery worker
docker logs job-processor | grep -i celery

# Check Redis
docker exec job-processor redis-cli ping
```

**Solution:**
```bash
# Restart job processor
docker-compose restart job-processor

# Verify worker is running
docker logs job-processor | tail -20
```

### Issue 2: Authentication Error (401)

**Symptoms:**
- `HTTP 401: Unauthorized` error
- Job submission fails immediately

**Diagnosis:**
```bash
# Verify API token is configured
curl http://localhost:8002/services/1 | jq '.api_config'

# Test token directly with H3Africa
curl -H "X-Auth-Token: YOUR_TOKEN" \
  https://impute.afrigen-d.org/api/v2/jobs
```

**Solution:**
1. Regenerate API token from H3Africa portal
2. Update service configuration:
```bash
curl -X PATCH http://localhost:8002/services/1 \
  -H "Content-Type: application/json" \
  -d '{"api_config": {"api_token": "NEW_TOKEN"}}'
```

### Issue 3: Results Download Fails

**Symptoms:**
- Job shows "completed" but results unavailable
- `404 Not Found` error

**Diagnosis:**
```bash
# Check job details
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs/$JOB_ID | jq '{status, results_file_id}'

# Check file manager
docker logs file-manager | grep -i "upload\|error"
```

**Solution:**
1. Verify job status is truly "completed"
2. Check file-manager service is running
3. Verify disk space: `df -h`

### Issue 4: Slow Response from H3Africa

**Symptoms:**
- Timeout errors during submission
- Health checks failing

**Solution:**
```bash
# Already configured - Michigan API has 30s connect timeout
# Check implementation in worker.py:109

# Verify from host
time curl -I https://impute.afrigen-d.org/

# If slow, this is expected (African server from outside Africa)
```

---

## API Reference

### Michigan API Integration Details

The platform implements the **Michigan Imputation Server API v2** specification. H3Africa uses this same API standard.

#### Authentication

```python
headers = {
    'X-Auth-Token': 'your_api_token_here'
}
```

#### Job Submission Parameters

| Parameter | Type | Required | Description | Values |
|-----------|------|----------|-------------|--------|
| `input-files` | file | Yes | VCF file (bgzipped) | .vcf.gz |
| `refpanel` | string | Yes | Reference panel ID | h3africa, 1000g_afr, agvp |
| `build` | string | Yes | Genome build | hg19, hg38 |
| `phasing` | string | Yes | Phasing method | eagle, shapeit, no_phasing |
| `population` | string | No | Population code | AFR, EUR, AMR, EAS, SAS, mixed |
| `mode` | string | Yes | Job mode | imputation |

#### Status Mapping

| Michigan Status | Platform Status | Description |
|----------------|----------------|-------------|
| waiting | queued | Job in queue |
| running | running | Processing |
| success | completed | Finished successfully |
| complete | completed | Alternative completion status |
| error | failed | Failed with error |
| canceled | cancelled | User cancelled |

---

## Best Practices

### 1. File Preparation

✅ **DO:**
- Use bgzipped VCF files (`.vcf.gz`)
- Validate VCF before upload: `bcftools view -h file.vcf.gz`
- Keep test files small (<1MB) for faster iteration
- Use chromosome 22 for small test datasets

❌ **DON'T:**
- Upload uncompressed VCF files
- Submit files >100MB to H3Africa
- Mix genome builds (use consistent hg19 or hg38)

### 2. Error Handling

```bash
# Always check job status before downloading
STATUS=$(curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs/$JOB_ID | jq -r '.status')

if [ "$STATUS" == "completed" ]; then
    # Download results
    curl -H "Authorization: Bearer $TOKEN" \
      http://localhost:8003/jobs/$JOB_ID/results -o results.zip
elif [ "$STATUS" == "failed" ]; then
    # Get error details
    curl -H "Authorization: Bearer $TOKEN" \
      http://localhost:8003/jobs/$JOB_ID | jq '.error_message'
fi
```

### 3. Monitoring

```bash
# Watch logs in real-time
docker logs -f job-processor

# Filter for specific job
docker logs job-processor | grep "$JOB_ID"

# Check all job statuses
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs | jq '.[] | {id, name, status, progress_percentage}'
```

---

## Next Steps

1. ✅ **Production Setup**
   - Configure SMTP for email notifications
   - Set up cloud storage (S3) for file management
   - Enable SSL/TLS for API endpoints

2. ✅ **Monitoring**
   - Deploy Prometheus + Grafana
   - Configure alerts for job failures
   - Track success rates per service

3. ✅ **Scaling**
   - Add more Celery workers
   - Implement job queue prioritization
   - Add rate limiting per user

---

## Support

- **Documentation**: [docs/README.md](README.md)
- **API Issues**: Check `docker logs job-processor`
- **H3Africa Support**: https://impute.afrigen-d.org/support
- **Platform Issues**: GitHub Issues

---

**Document Version**: 1.0
**Last Updated**: October 4, 2025
**Author**: Platform Development Team
