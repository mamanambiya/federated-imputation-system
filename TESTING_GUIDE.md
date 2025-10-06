# Testing Guide - Job Submission Fix

**Date:** 2025-10-06
**Status:** ✅ Ready for Testing

---

## Login Credentials

**Admin Account:**
- **Username:** `admin`
- **Password:** `IZTs:%$jS^@b2`
- **URL:** http://154.114.10.123:3000/login

**Authentication Status:**
- ✅ API authentication working
- ✅ Web interface authentication working
- ✅ JWT tokens being issued correctly

---

## How to Test Job Submission

### Option 1: Web Browser (Recommended)

1. **Open the application:**
   ```
   http://154.114.10.123:3000
   ```

2. **Log in** (if not already logged in):
   - Username: `admin`
   - Password: `admin123`

3. **Navigate to Job Submission:**
   - Click "New Job" in the left sidebar
   - Or go directly to: http://154.114.10.123:3000/jobs/new

4. **Complete the 4-step wizard:**

   **Step 1: Upload File**
   - Drag & drop or click to select a VCF file
   - Test file available at: `/home/ubuntu/federated-imputation-central/sample_data/testdata_chr22_48513151_50509881_phased.vcf.gz`

   **Step 2: Select Service & Panel**
   - Click "Add Service"
   - Select an available imputation service
   - Choose a reference panel
   - Accept terms and conditions
   - Click "Add Service"

   **Step 3: Configure Job**
   - Enter a job name (e.g., "Test Job")
   - Select input format: VCF
   - Choose genome build: hg38
   - Enable phasing (recommended)

   **Step 4: Review & Submit**
   - Review all settings
   - Click "Submit Job"

5. **Expected Result:**
   - ✅ Job submits successfully (no "Failed to submit job" error)
   - ✅ Redirects to job detail page
   - The actual job execution depends on service availability

### Option 2: API Testing (Command Line)

```bash
# Get a fresh authentication token
TOKEN=$(curl -X POST http://154.114.10.123:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "IZTs:%$jS^@b2"}' \
  -s | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

# Submit a test job
curl -X POST http://154.114.10.123:8000/api/jobs/ \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=API_Test_Job" \
  -F "service_id=1" \
  -F "reference_panel_id=1" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "phasing=true" \
  -F "input_file=@/home/ubuntu/federated-imputation-central/sample_data/testdata_chr22_48513151_50509881_phased.vcf.gz"
```

**Expected Response (Success):**
```json
{
  "id": "...",
  "name": "API_Test_Job",
  "status": "pending",
  ...
}
```

**OR (if services not configured):**
```json
{
  "detail": "Service '1' not found. Please check the service ID or slug."
}
```
Note: This error means form data was received successfully - just the service lookup failed.

**What you should NOT see anymore:**
```json
{
  "detail": [
    {"type": "missing", "loc": ["body", "name"], "msg": "Field required"},
    ...
  ]
}
```

---

## Verification Checklist

### ✅ Pre-Flight Checks

```bash
# 1. Check API Gateway health
curl -s http://154.114.10.123:8000/health | python3 -m json.tool

# Expected: status: "healthy" with all services healthy

# 2. Check Job Processor health
curl -s http://154.114.10.123:8003/health | python3 -m json.tool

# Expected: {"status": "healthy", ...}

# 3. Verify no 307 redirects in logs
sudo docker logs api-gateway 2>&1 | grep "307" | tail -5

# Expected: No recent 307 Temporary Redirect messages

# 4. Verify path stripping is working
sudo docker logs api-gateway 2>&1 | grep "clean_path='/jobs'" | tail -1

# Expected: Shows clean_path without trailing slash
```

### ✅ Success Indicators

**In Browser:**
- No "Failed to submit job. Please try again." error
- Successfully navigates to job detail page after submission
- Job appears in Jobs list

**In API:**
- Response includes job object (not "Field required" errors)
- HTTP status 200 or 201 (or 404 if service not found, which is OK)

**In Logs:**
```bash
sudo docker logs api-gateway 2>&1 | tail -20
```
Should show:
- `POST http://job-processor:8003/jobs` (without trailing slash)
- `clean_path='/jobs'` in WARNING logs
- No `307 Temporary Redirect` messages

---

## Troubleshooting

### Issue: "Failed to submit job"

**Check 1: Verify containers are running latest images**
```bash
# Check API gateway image
sudo docker inspect api-gateway | grep Image

# Should show recent image ID (not 3 days old)

# If old image, recreate container:
sudo docker stop api-gateway
sudo docker rm api-gateway
sudo docker run -d \
  --name api-gateway \
  --network microservices-network \
  -p 8000:8000 \
  -e REDIS_URL=redis://redis:6379 \
  federated-imputation-api-gateway:latest
```

**Check 2: Verify logs for errors**
```bash
sudo docker logs api-gateway 2>&1 | grep -i error | tail -10
sudo docker logs job-processor 2>&1 | grep -i error | tail -10
```

### Issue: "Service not found"

This is actually **expected** if the service registry doesn't have active services configured. The important thing is that you're getting this error instead of "Field required" - it means the form data is being received!

To configure services, you'd need to:
1. Register imputation services via the Services page
2. Add reference panels for those services
3. Ensure services are marked as active and healthy

### Issue: Cannot log in

**Verify credentials:**
```bash
# Test login via API
curl -X POST http://154.114.10.123:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "IZTs:%$jS^@b2"}' \
  -s | python3 -m json.tool
```

If this works but browser doesn't:
- Clear browser cache and cookies
- Try incognito/private window
- Check browser console for errors (F12)

---

## What Was Fixed

The job submission was failing because:

1. **FastAPI's trailing slash redirect** - API called `/jobs/` but endpoint was `/jobs`, causing 307 redirect
2. **Form data loss during redirect** - HTTP clients drop request bodies when following redirects (security feature)
3. **Incorrect form handling** - API gateway was passing file objects instead of reading file contents

**Solutions implemented:**
- ✅ Strip trailing slashes in API gateway before forwarding (`path.rstrip('/')`)
- ✅ Read file contents with `await value.read()` instead of passing file objects
- ✅ Use `data` parameter (not `json`) for multipart form requests
- ✅ Set `follow_redirects=False` to prevent automatic redirect following
- ✅ Add both `/jobs` and `/jobs/` endpoints to job processor

---

## Files Modified

1. `microservices/api-gateway/main.py` - Form data handling and path stripping
2. `microservices/job-processor/main.py` - Endpoint configuration
3. Frontend - No changes needed (was already correct)

**Full details:** See [JOB_SUBMISSION_FIX_COMPLETE.md](JOB_SUBMISSION_FIX_COMPLETE.md)

---

## Next Steps

1. ✅ Job submission form works correctly
2. ⏭️ Configure imputation services in the service registry
3. ⏭️ Add reference panels for each service
4. ⏭️ Test end-to-end job execution
5. ⏭️ Monitor job processing through the dashboard

---

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs: `sudo docker logs api-gateway` and `sudo docker logs job-processor`
3. Verify all containers are running: `sudo docker ps`
4. Check the detailed fix documentation: `JOB_SUBMISSION_FIX_COMPLETE.md`
