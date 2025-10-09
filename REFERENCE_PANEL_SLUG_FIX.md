# Reference Panel Slug Fix - October 9, 2025

## Problem Statement

Jobs were failing when submitted to the H3Africa/Michigan Imputation Server with the error:
```
Application H3AFRICA v6 is not installed or wrong permissions
```

### Failed Jobs
- `job-20251008-204131-199`
- `job-20251008-205019-206`
- `job-20251008-205309-207`
- `job-20251008-205528-208`
- `job-20251009-022848-786`

All jobs were sending `refpanel: "H3AFRICA v6"` when the Michigan API expected the Cloudgene application format `refpanel: "apps@h3africa-v6hc-s@1.0.0"`.

## Root Cause Analysis

### Issue 1: Docker Image Code Drift

The Celery worker Docker container was running **stale code** that didn't match the source files:

**Container Code (OLD):**
```python
# Line 124 in container
panel_identifier = panel_info.get('name')  # Use panel name
```

**Source Code (UPDATED):**
```python
# Line 124 in microservices/job-processor/worker.py
panel_identifier = panel_info.get('slug') or panel_info.get('name')  # Use slug first, fallback to name
```

**Why This Happened:**
- Source file was updated but Docker image wasn't rebuilt
- Docker cache prevented new code from being included during builds
- Running container continued using old code from cached layers

### Issue 2: Database Mismatch

The Celery worker was configured to use `job_processing_db` but the job-processor API writes jobs to `federated_imputation` database.

**Worker Configuration (WRONG):**
```bash
DATABASE_URL=postgresql://postgres:password@db:5432/job_processing_db
```

**Job-Processor Configuration (CORRECT):**
```bash
DATABASE_URL=postgresql://postgres:password@db:5432/federated_imputation
```

## Solution Implemented

### Step 1: Rebuild Worker Docker Image

Rebuilt the worker image with `--no-cache` flag to force inclusion of updated code:

```bash
docker build --no-cache \
  -f /home/ubuntu/federated-imputation-central/microservices/job-processor/Dockerfile.worker \
  -t federated-imputation-job-processor-worker:latest \
  /home/ubuntu/federated-imputation-central/microservices/job-processor
```

### Step 2: Fix Database Configuration

Recreated worker container with correct database URL:

```bash
docker run -d --name federated-imputation-central_celery-worker_1 \
  --network federated-imputation-central_default \
  --restart unless-stopped \
  -e DATABASE_URL="postgresql://postgres:PASSWORD@db:5432/federated_imputation" \
  -e REDIS_URL="redis://redis:6379" \
  -e JWT_SECRET="federated-imputation-jwt-secret-5edd167ef67e06d41d18fa3979efee2f" \
  -e SERVICE_REGISTRY_URL="http://service-registry:8002" \
  federated-imputation-job-processor-worker:latest

docker network connect federated-imputation-central_microservices-network \
  federated-imputation-central_celery-worker_1
```

### Step 3: Verify Fix

Submitted test job `test_slug_fix_final` (ID: `604ed7ca-ef79-42e9-a1b0-8e77d34da00c`):

**Worker Logs (SUCCESS):**
```
[2025-10-09 02:52:41] Michigan API: Using reference panel 'apps@h3africa-v6hc-s@1.0.0' (from panel ID: 37)
[2025-10-09 02:52:41] Michigan API: Full parameters - {
  'refpanel': 'apps@h3africa-v6hc-s@1.0.0',
  'build': 'hg38',
  'phasing': 'eagle',
  'population': 'mixed',
  'mode': 'imputation'
}
[2025-10-09 02:52:42] Michigan API: Job submitted successfully - External Job ID: job-20251009-025241-973
```

**Job Status:**
- Status: `running`
- External Job ID: `job-20251009-025241-973`
- Error Message: *(none)*

## Technical Details

### Reference Panel Mapping

The service-registry database (`service_registry_db.reference_panels`) stores panel metadata with a `slug` field containing the Cloudgene application format:

```sql
SELECT id, name, slug, service_id FROM reference_panels WHERE id = 37;

 id |     name      |            slug            | service_id
----+---------------+----------------------------+------------
 37 | H3AFRICA v6   | apps@h3africa-v6hc-s@1.0.0 |          1
```

### Code Logic

The updated `worker.py` (line 114-135) now:

1. Fetches reference panel details from service-registry API: `GET /panels/{panel_id}`
2. Extracts the `slug` field (Cloudgene format) with fallback to `name`
3. Sends correct identifier to Michigan API

```python
# Fetch reference panel details
panel_response = panel_client.get(
    f"{SERVICE_REGISTRY_URL}/panels/{job_data['reference_panel']}"
)
panel_info = panel_response.json()

# Use slug (Cloudgene format) with fallback to name
panel_identifier = panel_info.get('slug') or panel_info.get('name')

# Submit to Michigan API
data = {
    'refpanel': panel_identifier,  # Now sends: "apps@h3africa-v6hc-s@1.0.0"
    'build': job_data['build'],
    'phasing': 'eagle' if job_data.get('phasing', True) else 'no_phasing',
    'population': job_data.get('population') or 'mixed',
    'mode': 'imputation'
}
```

## Prevention Measures

### 1. Always Rebuild Images After Code Changes

When modifying worker code, **always rebuild the Docker image**:

```bash
cd microservices/job-processor
docker build --no-cache -f Dockerfile.worker -t federated-imputation-job-processor-worker:latest .
```

### 2. Verify Container Code Matches Source

After deployment, verify the container is running the latest code:

```bash
docker exec federated-imputation-central_celery-worker_1 grep "panel_identifier" /app/worker.py
```

### 3. Database Configuration Consistency

Ensure all services use consistent database names. Document in `.env` file which database each service uses:

```bash
# Job Processor & Worker
JOB_PROCESSOR_DB=federated_imputation

# Service Registry
SERVICE_REGISTRY_DB=service_registry_db

# User Service
USER_SERVICE_DB=user_management_db
```

## Files Modified

- `microservices/job-processor/worker.py` - Updated panel identifier logic (line 124)
- Docker image: `federated-imputation-job-processor-worker:latest` - Rebuilt with updated code
- Container: `federated-imputation-central_celery-worker_1` - Recreated with correct DATABASE_URL

## Backups Created

Post-fix database backups stored in `backups/2025-10-09/`:
- `federated_imputation_post_slug_fix.sql.gz` (39K)
- `job_processing_db_post_slug_fix.sql.gz` (5.6K)
- `service_registry_db_post_slug_fix.sql.gz` (12K)

## Verification Checklist

- [x] Worker Docker image rebuilt with `--no-cache`
- [x] Worker container recreated with correct DATABASE_URL
- [x] Worker connected to both networks (default + microservices-network)
- [x] Test job submitted successfully
- [x] Correct slug sent to Michigan API (`apps@h3africa-v6hc-s@1.0.0`)
- [x] Job accepted by external server (status: running)
- [x] No error messages in job record
- [x] Database backups created

## Impact

**Before Fix:**
- 100% job failure rate with H3Africa panel
- Error: "Application H3AFRICA v6 is not installed"

**After Fix:**
- Jobs successfully submitted with correct Cloudgene app format
- External server accepts jobs (status: running)
- No application name errors

## Related Documentation

- Michigan Imputation Server API: https://imputationserver.readthedocs.io/
- Cloudgene Application Format: `apps@{app-id}@{version}`
- H3Africa Panel ID: `h3africa-v6hc-s`
- Full Cloudgene ID: `apps@h3africa-v6hc-s@1.0.0`

---

**Fixed By:** Claude Code
**Date:** October 9, 2025
**Session:** Post-reboot recovery continuation
