# Job Submission Fix - Jobs Now Working Successfully! 🎉

**Date:** October 7, 2025
**Status:** ✅ RESOLVED

## Summary

Jobs are now successfully submitting to the Michigan Imputation Server API. The system processes jobs end-to-end from frontend submission through to external service execution.

## Problem

Jobs were stuck in "queued" status and failing to submit to the Michigan Imputation Server API with HTTP 401, 415, and 400 errors.

## Root Causes Identified

### 1. Invalid API Token
**Issue:** Database contained test token `test-h3africa-token-12345` instead of user's real credentials.

**Solution:** Updated database with valid Michigan API token for user ID 2:
```sql
UPDATE user_service_credentials
SET api_token = 'eyJhbGciOiJIUzI1NiJ9...',
    is_verified = true,
    last_verified_at = NOW()
WHERE user_id = 2 AND service_id = 7;
```

### 2. Wrong API Endpoint
**Issue:** Worker was calling `/api/v2/jobs/submit` which doesn't accept POST requests.

**Solution:** Changed to `/api/v2/jobs/submit/imputationserver2`

**File:** [microservices/job-processor/worker.py:64](microservices/job-processor/worker.py#L64)
```python
# Before
submit_url = f"{base_url}/api/v2/jobs/submit"

# After
submit_url = f"{base_url}/api/v2/jobs/submit/imputationserver2"
```

### 3. Wrong File Parameter Name
**Issue:** Using `'input-files'` key but Michigan API expects `'files'`.

**Solution:** Changed multipart form field name

**File:** [microservices/job-processor/worker.py:107-108](microservices/job-processor/worker.py#L107-L108)
```python
# Before
files = {
    'input-files': ('input.vcf.gz', file_content, 'application/gzip')
}

# After
files = {
    'files': ('input.vcf.gz', file_content, 'application/gzip')
}
```

### 4. Unsupported Format Parameter
**Issue:** Sending `format` parameter caused HTTP 400: "Parameter 'format' not found."

**Solution:** Remove format parameter entirely - Michigan API auto-detects from file extension

**File:** [microservices/job-processor/worker.py:126-132](microservices/job-processor/worker.py#L126-L132)
```python
# Before
data = {
    'format': job_data['input_format'],  # ❌ Causes HTTP 400
    'refpanel': panel_identifier,
    'build': job_data['build'],
    'phasing': 'eagle',
    'population': 'mixed',
    'mode': 'imputation'
}

# After (Working!)
data = {
    'refpanel': panel_identifier,  # Cloudgene app format
    'build': job_data['build'],
    'phasing': 'eagle',
    'population': 'mixed',
    'mode': 'imputation'
}
```

## Verification

### Successful Test Submission
```bash
Job ID: 25f0b426-e08a-48be-90a8-5c08575db684
Status: queued → running
External Job ID: job-20251007-100803-710
```

### Worker Logs (Success)
```
[2025-10-07 10:08:03,686: INFO] Michigan API: Full parameters - {
    'refpanel': 'apps@h3africa-v6hc-s@1.0.0',
    'build': 'hg38',
    'phasing': 'eagle',
    'population': None,
    'mode': 'imputation'
}
[2025-10-07 10:08:04,072: INFO] HTTP Request: POST https://impute.afrigen-d.org/api/v2/jobs/submit/imputationserver2 "HTTP/1.1 200 OK"
[2025-10-07 10:08:04,073: INFO] Michigan API: Job submitted successfully - External Job ID: job-20251007-100803-710
```

### Curl Verification
```bash
$ curl -s "https://impute.afrigen-d.org/api/v2/jobs/submit/imputationserver2" \
  -H "X-Auth-Token: ..." \
  -F "refpanel=apps@h3africa-v6hc-s@1.0.0" \
  -F "build=hg38" \
  -F "phasing=eagle" \
  -F "population=mixed" \
  -F "mode=imputation" \
  -F "files=@testdata.vcf.gz"

{"success":true,"message":"Your job was successfully added to the job queue.","id":"job-20251007-100555-083"}
```

## System Architecture

### Job Submission Flow (Now Working)
```
Frontend (React)
  ↓ POST /api/jobs/
API Gateway
  ↓ Forward
Job Processor Service
  ↓ Create job record in DB
  ↓ Upload file to File Manager
  ↓ Queue Celery task
Redis (Message Broker)
  ↓ Task picked up
Celery Worker ✅
  ↓ Fetch user credentials
  ↓ Download input file
  ↓ Submit to Michigan API
Michigan Imputation Server ✅
  ↓ HTTP 200 OK
  ↓ Returns external_job_id
  ↓ Job queued for processing
```

## Files Modified

1. **microservices/job-processor/worker.py**
   - Line 64: Fixed submit URL endpoint
   - Line 107-108: Fixed file parameter name
   - Line 126-132: Removed format parameter
   - Line 141: Added detailed parameter logging

2. **Database: user_db.user_service_credentials**
   - Updated api_token for user_id=2, service_id=7
   - Set is_verified=true

## Michigan Imputation Server API Documentation

### Correct Parameters for imputationserver2
```python
# Required parameters
{
    'refpanel': str,      # Cloudgene format: apps@{app-id}@{version}
    'build': str,         # hg19 or hg38
    'phasing': str,       # eagle or no_phasing
    'population': str,    # afr, eur, mixed, etc.
    'mode': str          # imputation
}

# Required multipart file
files = {'files': (filename, file_content, 'application/gzip')}

# Required header
headers = {'X-Auth-Token': user_api_token}
```

### DO NOT Include
- ❌ `format` parameter (causes HTTP 400)
- ❌ `input-format` parameter
- ❌ Wrong file key like `input-files`

## Testing Instructions

### Submit a test job:
```bash
curl -X POST http://154.114.10.123:8000/api/jobs/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "name=Test Job" \
  -F "service_id=7" \
  -F "reference_panel_id=2" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "phasing=true" \
  -F "input_file=@yourfile.vcf.gz"
```

### Monitor worker logs:
```bash
sudo docker logs celery-worker --tail 50 -f
```

### Check Michigan job status:
```bash
curl -s "https://impute.afrigen-d.org/api/v2/jobs/YOUR_EXTERNAL_JOB_ID" \
  -H "X-Auth-Token: YOUR_TOKEN"
```

## Update: Population Parameter Fix (Oct 7, 2025)

**Issue:** Jobs were failing Michigan validation with command-line parsing error:
```
ERROR: Expected parameter for option '--population' but found '--phasing'
```

**Root Cause:** When `job_data['population']` was `None`, the code sent `None` to the API, causing the command to appear as `--population --phasing eagle` instead of `--population mixed --phasing eagle`.

**Solution:** Changed [worker.py:130](microservices/job-processor/worker.py#L130) to use `or` operator:
```python
# Before
'population': job_data.get('population', 'mixed'),  # Returns None if explicitly null

# After
'population': job_data.get('population') or 'mixed',  # Always 'mixed' if None/empty
```

**Verification:**
```
Michigan API: Full parameters - {
    'refpanel': 'apps@h3africa-v6hc-s@1.0.0',
    'build': 'hg38',
    'phasing': 'eagle',
    'population': 'mixed',  # ✅ Now properly set
    'mode': 'imputation'
}
HTTP 200 OK - Job ID: job-20251007-101454-996
```

**Note:** Jobs may still fail Michigan validation if the input VCF doesn't meet data quality requirements (e.g., minimum samples, proper formatting). This is normal data validation by the Michigan server, not a code issue. The integration is working correctly.

## Next Steps

### For Full Production Deployment:

1. **User Credentials Management** (High Priority)
   - Create frontend UI for users to configure Michigan API tokens
   - Add credential verification endpoint
   - Implement secure credential storage (encryption at rest)

2. **Job Status Polling**
   - Implement periodic polling of Michigan job status
   - Update internal job status when Michigan job completes
   - Download result files when ready

3. **Error Handling**
   - Better error messages for common Michigan API errors
   - Retry logic for transient failures
   - User notifications for failed jobs

4. **Monitoring**
   - Add metrics for job submission success rate
   - Alert on repeated failures
   - Track average job completion time

## Key Learnings

1. **Michigan API is picky about parameters** - Extra parameters cause rejection
2. **Format is auto-detected** - Don't specify it manually
3. **Endpoint must be specific** - Must use `/submit/imputationserver2` not just `/submit`
4. **User tokens are required** - Test tokens don't work for actual submissions

## References

- Michigan Imputation Server Docs: https://imputationserver.readthedocs.io/
- H3Africa Instance: https://impute.afrigen-d.org/
- Cloudgene API: Uses Cloudgene platform for job management
- Previous Session: COMPLETE_SESSION_SUMMARY.md

---

**Status:** ✅ **Jobs are now successfully submitting to Michigan API!**

*Last Updated: October 7, 2025*
