# Service Response Display Fix

**Date:** October 9, 2025
**Status:** ✅ Complete
**Issue:** Raw API Response section in Job Details showing stale data

## Problem Description

The Raw API Response section in the Job Details page was only showing the initial job submission response, not the latest API response when jobs completed or failed. This meant users couldn't see important completion metadata like result file information, final status messages, or error details.

### Root Cause

The `update_job_status_sync()` function in the job-processor worker only updated basic status fields (status, progress, error_message) but never updated the `service_response` field with the latest API response from the external imputation server.

**Flow Before Fix:**
```
1. Job submitted → service_response = submission response
2. Job running → service_response unchanged
3. Job completed → service_response still has submission response ❌
4. Frontend displays → Shows old submission data ❌
```

## Solution Implementation

### Backend Changes

**File:** `microservices/job-processor/worker.py`

#### 1. Updated `update_job_status_sync` Function (Line 675)

**Before:**
```python
def update_job_status_sync(job_id: str, status: str, progress: int = None,
                          message: str = None, error: str = None):
    """Update job status synchronously."""
    # ... only updates status, progress, error_message
```

**After:**
```python
def update_job_status_sync(job_id: str, status: str, progress: int = None,
                          message: str = None, error: str = None,
                          service_response: Dict[str, Any] = None):
    """Update job status synchronously."""
    db = SessionLocal()
    try:
        job = db.query(ImputationJob).filter(ImputationJob.id == job_id).first()
        if job:
            job.status = status
            if progress is not None:
                job.progress_percentage = progress
            if message:
                job.error_message = message if status == 'failed' else None
            if error:
                job.error_message = error
            if service_response is not None:
                job.service_response = service_response  # ← NEW
            job.updated_at = datetime.utcnow()
            # ...
```

**Key Change:** Added `service_response` parameter and storage logic.

#### 2. Updated Job Monitoring Calls (Lines 839-845)

**Completed Jobs:**
```python
update_job_status_sync(
    job_id, 'completed', 100, "Job completed successfully",
    service_response=status_result.get('service_response')  # ← NEW
)
```

**Failed Jobs:**
```python
update_job_status_sync(
    job_id, 'failed', progress, f"Job failed: {message}",
    service_response=status_result.get('service_response')  # ← NEW
)
```

**Cancelled Jobs:**
```python
update_job_status_sync(
    job_id, 'cancelled', progress, "Job was cancelled",
    service_response=status_result.get('service_response')  # ← NEW
)
```

### How It Works

The external service client fetches job status periodically and returns a comprehensive response:

```python
status_result = client.check_job_status(service_info, job.external_job_id, job.user_id)

# status_result structure:
{
    'status': 'completed',  # Internal status
    'progress': 100,
    'message': 'Job completed successfully',
    'service_response': {    # ← Full external API response
        'id': '1fcdeadb-...',
        'state': 4,  # Michigan API state
        'executionDate': '2025-10-08 23:15:32',
        'outputParams': [
            {
                'description': 'Output Files',
                'download': True,
                'files': [
                    {'name': 'chr_20.zip', 'size': '51.0 MB', 'hash': '...'},
                    {'name': 'qc_report.txt', 'size': '753 B', 'hash': '...'},
                    # ... more files
                ]
            }
        ],
        # ... other Michigan API fields
    }
}
```

When the job status changes (completed/failed/cancelled), the full `service_response` is now stored in the database.

## Frontend Display

The frontend already had the UI to display `service_response`:

**File:** `frontend/src/pages/JobDetails.tsx` (Lines 882-890)

```typescript
<pre style={{
  margin: 0,
  fontFamily: 'monospace',
  fontSize: '0.875rem',
  whiteSpace: 'pre-wrap',
  wordBreak: 'break-word'
}}>
  {job.service_response && Object.keys(job.service_response).length > 0
    ? JSON.stringify(job.service_response, null, 2)
    : JSON.stringify({
        status: 'No response',
        message: 'Job failed before receiving API response',
        external_job_id: job.external_job_id || null
      }, null, 2)
  }
</pre>
```

**No frontend changes needed!** The fix is entirely backend.

## Benefits

### 1. Complete Job Information
Users can now see the full external API response including:
- Execution timestamps
- Result file metadata (before download)
- QC statistics
- Processing steps
- Error details (for failed jobs)

### 2. Better Debugging
When jobs fail, the `service_response` contains:
- Detailed error messages from external service
- State information
- Processing logs
- Validation errors

### 3. Audit Trail
Complete API responses are stored for:
- Troubleshooting
- Support requests
- Compliance/auditing
- Historical analysis

## Example Response Data

### Completed Job Response
```json
{
  "id": "1fcdeadb-0600-4c34-9390-07e10d43684b",
  "state": 4,
  "name": "test_job_final",
  "createdOn": 1728428736000,
  "executionDate": "2025-10-08 23:15:32",
  "outputParams": [
    {
      "description": "Output Files",
      "download": true,
      "files": [
        {
          "name": "chr_20.zip",
          "path": "chr_20.zip",
          "size": "51.0 MB",
          "hash": "da81..."
        },
        {
          "name": "qc_report.txt",
          "path": "qc_report.txt",
          "size": "753 B",
          "hash": "ab12..."
        },
        {
          "name": "quality-control.html",
          "path": "quality-control.html",
          "size": "1.0 MB",
          "hash": "cd34..."
        }
      ]
    }
  ],
  "positionInQueue": 0,
  "running": false,
  "complete": true
}
```

### Failed Job Response
```json
{
  "id": "abc123...",
  "state": 5,
  "name": "failed_job",
  "error": "Validation failed: Input VCF file has mismatched chromosomes",
  "executionDate": "2025-10-09 01:30:15",
  "running": false,
  "complete": false,
  "failed": true
}
```

## Testing

### Test Scenario 1: Completed Job
1. Submit a job with valid VCF file
2. Wait for completion
3. View Job Details page → Raw API Response section
4. **Expected:** See full Michigan API response with:
   - `outputParams` containing result files
   - `executionDate` showing completion time
   - `state: 4` (completed status)

### Test Scenario 2: Failed Job
1. Submit a job with invalid data
2. Wait for failure
3. View Job Details page → Raw API Response section
4. **Expected:** See failure details:
   - `error` message explaining why it failed
   - `state: 5` (failed status)
   - No `outputParams` (no results)

### Test Scenario 3: Database Verification
```sql
-- Check service_response for a completed job
SELECT id, status, service_response::json->'executionDate' as completion_date
FROM imputation_jobs
WHERE id = '1fcdeadb-0600-4c34-9390-07e10d43684b';
```

**Expected:** Non-null `service_response` with completion metadata.

## Deployment

### 1. Rebuild Job Processor
```bash
cd microservices/job-processor
sudo docker build --no-cache -t federated-imputation-job-processor:latest .
```

**Result:** New image `a772b145ee74` created with service_response storage.

### 2. Restart Container
```bash
sudo docker rm federated-imputation-central_job-processor_1
sudo docker run -d \
  --name federated-imputation-central_job-processor_1 \
  --network federated-imputation-central_default \
  -e DATABASE_URL="postgresql://postgres:...@db:5432/federated_imputation" \
  -e CELERY_BROKER_URL="redis://redis:6379/0" \
  -e FILE_MANAGER_URL="http://file-manager:8081" \
  federated-imputation-job-processor:latest \
  celery -A worker worker --loglevel=info
```

**Status:** Container `5e89b268961f` running with new code.

## Impact on Existing Jobs

### Jobs Submitted Before Fix
- Still have `service_response` from submission
- Will **NOT** be automatically updated
- Users see submission response only

### Jobs Submitted After Fix
- Will have `service_response` updated on:
  - Completion
  - Failure
  - Cancellation
- Users see latest API response ✅

### Recommendation
For important historical jobs, consider manual backfill:
```python
# Fetch latest response from external service
status = client.check_job_status(service_info, external_job_id, user_id)

# Update database
job.service_response = status['service_response']
db.commit()
```

## Related Files

1. **microservices/job-processor/worker.py** - Core fix implementation
2. **frontend/src/pages/JobDetails.tsx** - Display logic (unchanged)
3. **frontend/src/contexts/ApiContext.tsx** - TypeScript interface (unchanged)

## Related Documentation

- [FRONTEND_INTEGRATION_COMPLETE.md](./FRONTEND_INTEGRATION_COMPLETE.md) - Frontend result files integration
- [RESULTS_LINK_STORAGE_SUCCESS.md](./RESULTS_LINK_STORAGE_SUCCESS.md) - Backend result link storage

---

**Completion Date:** October 9, 2025
**Deployed:** ✅ Yes (Container: 5e89b268961f)
**Testing Status:** Ready for verification with new jobs
**Impact:** New jobs will show latest API response; existing jobs unchanged
