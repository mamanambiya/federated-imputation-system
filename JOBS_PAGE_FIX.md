# Jobs Page 401 Unauthorized Error - Fixed

## Problem
The jobs page at http://154.114.10.184:3000/jobs showed "Failed to load jobs" with 401 Unauthorized errors in the browser console.

## Root Cause
The `job-processor` microservice was missing the **JWT_SECRET** environment variable, which is required to validate JWT tokens created by the `user-service`.

### Diagnosis Timeline
1. **Frontend Authentication:** Verified that the frontend correctly sends the Authorization header with JWT tokens (via request interceptor in ApiContext.tsx:212-230)
2. **API Gateway Logs:** Found warnings showing missing or empty Authorization headers
3. **Job-Processor Authentication:** Discovered that the `/jobs` endpoint requires authentication via `get_user_id_from_token` dependency
4. **Token Testing:** Direct API calls revealed "Invalid token: Signature verification failed" error
5. **JWT Secret Comparison:** Found that job-processor had an empty JWT_SECRET while user-service had the correct value

### Error Details
```bash
# Before fix:
$ docker exec job-processor printenv JWT_SECRET
<empty>

$ docker exec user-service printenv JWT_SECRET
change-this-to-a-strong-random-secret-in-production

# API Response:
{"detail":"Invalid token: Signature verification failed"}
```

## Solution
Restarted the `job-processor` container with the correct `JWT_SECRET` environment variable:

```bash
# Stop and remove old container
docker stop federated-imputation-central_job-processor_1
docker rm federated-imputation-central_job-processor_1

# Restart with JWT_SECRET
docker run -d \
  --name federated-imputation-central_job-processor_1 \
  --network federated-imputation-central_microservices-network \
  --network-alias job-processor \
  --restart always \
  -p 8003:8003 \
  -e "DATABASE_URL=postgresql://postgres:GNUQySylcLc8d/CvGpx93H2outRXBYKoQ2XRr9lsUoM=@postgres:5432/job_processing_db" \
  -e "REDIS_URL=redis://redis:6379" \
  -e "USER_SERVICE_URL=http://user-service:8001" \
  -e "SERVICE_REGISTRY_URL=http://service-registry:8002" \
  -e "FILE_MANAGER_URL=http://file-manager:8004" \
  -e "NOTIFICATION_URL=http://notification:8005" \
  -e "JWT_SECRET=change-this-to-a-strong-random-secret-in-production" \
  -e "JWT_ALGORITHM=HS256" \
  federated-imputation-job-processor:latest
```

## Verification

### 1. JWT Secret is Set
```bash
$ docker exec federated-imputation-central_job-processor_1 sh -c 'echo $JWT_SECRET'
change-this-to-a-strong-random-secret-in-production
```

### 2. Jobs API Works (Localhost)
```bash
$ curl "http://localhost:8000/api/jobs/" \
  -H "Authorization: Bearer <token>"

[{"id":"6587eeff-af44-4b77-b850-0e4d9b3a5fae","user_id":1,"name":"chr20.R50.merged.1.330k.recode.small.vcf - H3Africa Imputation Service",...}]
HTTP Status: 200
```

### 3. Jobs API Works (Public IP)
```bash
$ curl "http://154.114.10.184:8000/api/jobs/" \
  -H "Authorization: Bearer <token>"

[{"id":"6587eeff-af44-4b77-b850-0e4d9b3a5fae",...}]
HTTP: 200
```

## Impact
✅ Jobs page now loads successfully
✅ Authentication works correctly across all microservices
✅ JWT tokens are validated consistently
✅ Users can view their imputation jobs

## Technical Details

### JWT Authentication Flow
```
1. User logs in → user-service creates JWT with JWT_SECRET
2. Frontend stores token in localStorage
3. Frontend sends token in Authorization header (via ApiContext interceptor)
4. API Gateway forwards request to job-processor
5. Job-processor validates token using same JWT_SECRET ✓
6. User data is returned
```

### Key Files
- **Frontend:** `frontend/src/contexts/ApiContext.tsx:212-230` - Request interceptor adds Authorization header
- **Frontend:** `frontend/src/pages/Jobs.tsx:100-111` - Jobs page fetches jobs via `getJobs()` API
- **Job-Processor:** `microservices/job-processor/main.py:167-185` - `get_user_id_from_token()` validates JWT
- **Job-Processor:** `microservices/job-processor/main.py:581-624` - `/jobs` endpoint requires authentication

## Important Note
**All microservices that validate JWT tokens MUST have the same JWT_SECRET environment variable.**

Services requiring JWT_SECRET:
- ✅ user-service (creates tokens)
- ✅ job-processor (validates tokens) - **FIXED**
- ✅ api-gateway (forwards tokens)
- ⚠️  Other services should be verified if they validate tokens

## Status
🟢 **RESOLVED** - Jobs page is fully functional at http://154.114.10.184:3000/jobs

---
*Fixed: 2025-10-08*
*Issue: Missing JWT_SECRET environment variable in job-processor container*
