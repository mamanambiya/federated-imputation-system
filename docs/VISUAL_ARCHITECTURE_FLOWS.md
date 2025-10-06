# Visual Architecture Flows - Complete Reference

**Comprehensive visual diagrams for the Federated Imputation Platform**

---

## 📋 Table of Contents

1. [Authentication Flow](#authentication-flow)
2. [Job Submission Flow](#job-submission-flow)
3. [Job Processing Flow](#job-processing-flow)
4. [Credential Management Flow](#credential-management-flow)
5. [Error Handling Flow](#error-handling-flow)
6. [Complete System Architecture](#complete-system-architecture)

---

## 1. Authentication Flow

### Platform User Authentication

```
┌─────────────────────────────────────────────────────────────┐
│                        User                                  │
│   Action: Login to federated imputation platform            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ POST /api/auth/login
                     │ Body: {username, password}
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              User Service (Port 8001)                        │
│                                                               │
│  1. Receive login request                                    │
│  2. Query database: SELECT * FROM users WHERE username=?     │
│  3. Verify password: bcrypt.verify(input, stored_hash)       │
│  4. Generate JWT token                                       │
│     - Payload: {user_id, username, exp}                      │
│     - Sign with JWT_SECRET                                   │
│  5. Update last_login timestamp                              │
│                                                               │
│  Response: {                                                 │
│    access_token: "eyJhbGc...",                               │
│    token_type: "bearer",                                     │
│    expires_in: 86400,                                        │
│    user: {...}                                               │
│  }                                                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Return JWT token
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                        User                                  │
│   Stores: localStorage.setItem('token', jwt)                │
│   Uses: Authorization: Bearer {jwt} in all API calls        │
└─────────────────────────────────────────────────────────────┘
```

### Service Credential Configuration

```
┌─────────────────────────────────────────────────────────────┐
│                        User                                  │
│   Has: Platform JWT token                                    │
│   Needs: Configure H3Africa credentials                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ 1. Get H3Africa API Token
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              External Service (H3Africa)                     │
│           https://impute.afrigen-d.org                       │
│                                                               │
│  User Actions:                                               │
│  1. Register account                                         │
│  2. Navigate to Settings → API Tokens                        │
│  3. Click "Generate New Token"                               │
│  4. Copy token (shown once!)                                 │
│                                                               │
│  Returns: "h3a_abc123def456..."                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ 2. Configure in Platform
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                        User                                  │
│   POST /users/me/service-credentials                         │
│   Headers: Authorization: Bearer {platform_jwt}              │
│   Body: {                                                    │
│     service_id: 1,                                           │
│     api_token: "h3a_abc123def456...",                        │
│     label: "My H3Africa Account"                             │
│   }                                                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              User Service (Port 8001)                        │
│                                                               │
│  1. Validate JWT token                                       │
│  2. Extract user_id from token                               │
│  3. Check existing credential:                               │
│     SELECT * FROM user_service_credentials                   │
│     WHERE user_id=? AND service_id=?                         │
│                                                               │
│  4. If exists: UPDATE                                        │
│     If new: INSERT                                           │
│                                                               │
│  5. Store encrypted:                                         │
│     INSERT INTO user_service_credentials (                   │
│       user_id, service_id, api_token,                        │
│       credential_type, is_active, created_at                 │
│     ) VALUES (?, ?, ?, 'api_token', true, NOW())             │
│                                                               │
│  6. Create audit log                                         │
│                                                               │
│  Response: {                                                 │
│    id: 42,                                                   │
│    service_id: 1,                                            │
│    is_verified: false,                                       │
│    has_api_token: true                                       │
│  }                                                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ 3. Credential stored successfully
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                        User                                  │
│   Status: Ready to submit jobs ✅                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Job Submission Flow

### Complete Job Submission Sequence

```
┌─────────────────────────────────────────────────────────────┐
│                        User                                  │
│   Has: Platform JWT + Configured H3Africa credentials       │
│   Action: Submit imputation job                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ POST /jobs (multipart/form-data)
                     │ Headers: Authorization: Bearer {jwt}
                     │ Form Data:
                     │   - name: "My Job"
                     │   - service_id: 1
                     │   - reference_panel_id: 1
                     │   - input_file: test.vcf.gz
                     │   - build: hg38
                     ↓
┌─────────────────────────────────────────────────────────────┐
│           Job Processor Service (Port 8003)                  │
│                                                               │
│  STEP 1: Validate JWT                                        │
│  ────────────────────────                                    │
│  - Decode JWT token                                          │
│  - Verify signature                                          │
│  - Check expiration                                          │
│  - Extract user_id                                           │
│                                                               │
│  STEP 2: Validate Credentials ✅ CRITICAL                    │
│  ─────────────────────────────────────────                   │
│  GET http://user-service:8001/internal/users/{user_id}/     │
│      service-credentials/{service_id}                        │
│                                                               │
│  If no credentials:                                          │
│    → Return 400 Bad Request                                  │
│    → Message: "Configure your API credentials in Settings"   │
│    → STOP processing                                         │
│                                                               │
│  If credentials exist:                                       │
│    → Continue to next step                                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Credentials validated ✅
                     ↓
┌─────────────────────────────────────────────────────────────┐
│           Job Processor Service (Port 8003)                  │
│                                                               │
│  STEP 3: Create Job Record                                   │
│  ──────────────────────────                                  │
│  INSERT INTO imputation_jobs (                               │
│    user_id, name, service_id, reference_panel_id,            │
│    input_format, build, phasing, status                      │
│  ) VALUES (                                                   │
│    {user_id}, 'My Job', 1, 1,                                │
│    'vcf', 'hg38', true, 'pending'                            │
│  )                                                            │
│  RETURNING id → job_id: uuid                                 │
│                                                               │
│  STEP 4: Upload File to File Manager                         │
│  ────────────────────────────────────────                    │
│  POST http://file-manager:8004/files/upload                  │
│  - Multipart: file data                                      │
│  - Metadata: {job_id, file_type: 'input'}                    │
│  - Returns: {file_id, file_url}                              │
│                                                               │
│  STEP 5: Update Job with File Info                           │
│  ───────────────────────────────────                         │
│  UPDATE imputation_jobs                                      │
│  SET input_file_id = {file_id}                               │
│  WHERE id = {job_id}                                         │
│                                                               │
│  STEP 6: Queue for Processing                                │
│  ─────────────────────────────                               │
│  celery.send_task('worker.process_job', args=[job_id])       │
│  → Job queued in Redis                                       │
│                                                               │
│  STEP 7: Update Status                                       │
│  ──────────────────────                                      │
│  UPDATE imputation_jobs                                      │
│  SET status = 'queued'                                       │
│  WHERE id = {job_id}                                         │
│                                                               │
│  Response: {                                                 │
│    id: job_id,                                               │
│    status: "queued",                                         │
│    progress_percentage: 0,                                   │
│    created_at: "2025-10-04T10:00:00Z"                        │
│  }                                                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Job created and queued
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   Redis Queue                                │
│   Queue: celery                                              │
│   Task: worker.process_job(job_id)                           │
│   Status: Waiting for worker...                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Worker picks up task
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   Celery Worker                              │
│   Status: Processing job_id                                  │
│   → See "Job Processing Flow" below                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Job Processing Flow

### Worker Job Execution (Detailed)

```
┌─────────────────────────────────────────────────────────────┐
│              Celery Worker (Background)                      │
│   Task: process_job(job_id)                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ PHASE 1: INITIALIZATION
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Load Job Details                                   │
│  ─────────────────────────                                  │
│  SELECT * FROM imputation_jobs WHERE id = {job_id}          │
│  Extract: user_id, service_id, reference_panel_id,          │
│           input_file_id, build, phasing, population         │
│                                                               │
│  Step 2: Update Status → Running                            │
│  ────────────────────────────────                           │
│  UPDATE imputation_jobs                                      │
│  SET status = 'running',                                     │
│      started_at = NOW(),                                     │
│      progress_percentage = 0                                 │
│  WHERE id = {job_id}                                         │
│                                                               │
│  INSERT INTO job_status_updates (                            │
│    job_id, status, message                                   │
│  ) VALUES (                                                   │
│    {job_id}, 'running', 'Job processing started'            │
│  )                                                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ PHASE 2: GATHER RESOURCES
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 3: Get Service Information                            │
│  ────────────────────────────────                           │
│  GET http://service-registry:8002/services/{service_id}     │
│                                                               │
│  Returns: {                                                  │
│    id: 1,                                                    │
│    name: "H3Africa",                                         │
│    api_type: "michigan",                                     │
│    base_url: "https://impute.afrigen-d.org",                │
│    supported_builds: ["hg19", "hg38"]                        │
│  }                                                            │
│                                                               │
│  Step 4: Get Input File URL                                 │
│  ───────────────────────────                                │
│  GET http://file-manager:8004/files/{input_file_id}/        │
│      download                                                │
│                                                               │
│  Returns: {                                                  │
│    download_url: "http://file-manager:8004/files/           │
│                   download/{signed_token}"                   │
│  }                                                            │
│                                                               │
│  Step 5: Fetch USER's Credentials ✅ CRITICAL               │
│  ─────────────────────────────────────────────              │
│  GET http://user-service:8001/internal/users/{user_id}/     │
│      service-credentials/{service_id}                        │
│                                                               │
│  If no credentials:                                          │
│    → Update job: status = 'failed'                           │
│    → Error: "No credentials configured"                      │
│    → STOP processing                                         │
│                                                               │
│  Returns: {                                                  │
│    has_credential: true,                                     │
│    api_token: "h3a_abc123...",  ← USER'S TOKEN              │
│    is_verified: true                                         │
│  }                                                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ PHASE 3: EXTERNAL SUBMISSION
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 6: Download Input File                                │
│  ────────────────────────────                               │
│  GET {download_url}                                          │
│  → Receive file content (bytes)                              │
│  → File size: e.g., 2.5 MB                                   │
│                                                               │
│  Step 7: Submit to H3Africa ✅ WITH USER'S TOKEN            │
│  ─────────────────────────────────────────────              │
│  POST https://impute.afrigen-d.org/api/v2/jobs/submit       │
│                                                               │
│  Headers:                                                    │
│    X-Auth-Token: {user's_api_token}  ← USER'S CREDENTIALS   │
│    Content-Type: multipart/form-data                         │
│                                                               │
│  Form Data:                                                  │
│    input-files: (file_content, filename.vcf.gz)              │
│    refpanel: "h3africa"                                      │
│    build: "hg38"                                             │
│    phasing: "eagle"                                          │
│    population: "AFR"                                         │
│    mode: "imputation"                                        │
│                                                               │
│  Response: {                                                 │
│    id: "job-20251004-xyz789",  ← External job ID             │
│    status: "waiting",                                        │
│    message: "Job queued successfully"                        │
│  }                                                            │
│                                                               │
│  Step 8: Save External Job ID                               │
│  ─────────────────────────────                              │
│  UPDATE imputation_jobs                                      │
│  SET external_job_id = "job-20251004-xyz789",                │
│      progress_percentage = 10                                │
│  WHERE id = {job_id}                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ PHASE 4: MONITOR PROGRESS
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 9: Poll H3Africa Status (every 30 seconds)            │
│  ────────────────────────────────────────────────           │
│  Loop: max_checks = 720 (6 hours timeout)                   │
│                                                               │
│  Every 30 seconds:                                           │
│    GET https://impute.afrigen-d.org/api/v2/jobs/             │
│        {external_job_id}/status                              │
│    Headers: X-Auth-Token: {user's_api_token}                │
│                                                               │
│    Response: {                                               │
│      state: "running",  // waiting → running → success      │
│      progress: 75,                                           │
│      message: "Phasing chromosomes..."                       │
│    }                                                          │
│                                                               │
│    Map status:                                               │
│      waiting  → queued                                       │
│      running  → running                                      │
│      success  → completed                                    │
│      error    → failed                                       │
│                                                               │
│    Update our database:                                      │
│      UPDATE imputation_jobs                                  │
│      SET status = {mapped_status},                           │
│          progress_percentage = {calculated}                  │
│                                                               │
│    If status = 'success': Break loop and proceed             │
│    If status = 'error': Break loop and mark failed           │
│    Otherwise: Continue polling                               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ PHASE 5: RETRIEVE RESULTS
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 10: Download Results from H3Africa                    │
│  ─────────────────────────────────────────                  │
│  GET https://impute.afrigen-d.org/api/v2/jobs/               │
│      {external_job_id}/results                               │
│  Headers: X-Auth-Token: {user's_api_token}                  │
│                                                               │
│  Response: ZIP file containing:                              │
│    - imputed.vcf.gz (imputed genotypes)                      │
│    - imputed.vcf.gz.tbi (index)                              │
│    - statistics.txt (QC metrics)                             │
│    - log.txt (processing log)                                │
│                                                               │
│  File size: e.g., 15 MB                                      │
│                                                               │
│  Step 11: Upload Results to File Manager                    │
│  ────────────────────────────────────────                   │
│  POST http://file-manager:8004/files/upload                  │
│  Files: {file: (results.zip, result_bytes)}                  │
│  Data: {job_id, file_type: 'output'}                         │
│                                                               │
│  Response: {                                                 │
│    id: {results_file_id},                                    │
│    filename: "results.zip",                                  │
│    file_size: 15728640                                       │
│  }                                                            │
│                                                               │
│  Step 12: Update Job with Results                           │
│  ──────────────────────────────────                         │
│  UPDATE imputation_jobs                                      │
│  SET results_file_id = {results_file_id},                    │
│      status = 'completed',                                   │
│      progress_percentage = 100,                              │
│      completed_at = NOW()                                    │
│  WHERE id = {job_id}                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ PHASE 6: NOTIFICATION
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 13: Send Completion Notification                      │
│  ───────────────────────────────────────                    │
│  POST http://notification:8005/notifications                 │
│  Body: {                                                     │
│    user_id: {user_id},                                       │
│    type: "job_completed",                                    │
│    title: "Job Completed",                                   │
│    message: "Your job 'My Job' completed successfully",      │
│    data: {job_id, job_name, results_url},                    │
│    channels: ["web", "email"]                                │
│  }                                                            │
│                                                               │
│  → Email sent to user                                        │
│  → Web notification created                                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ✅ JOB COMPLETE
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   Final State                                │
│                                                               │
│  Database:                                                   │
│    - Job status: completed                                   │
│    - Progress: 100%                                          │
│    - Results file: stored in file-manager                    │
│    - Execution time: tracked                                 │
│                                                               │
│  User notified via:                                          │
│    - Email ✅                                                │
│    - Web notification ✅                                     │
│                                                               │
│  User can now:                                               │
│    - Download results                                        │
│    - View QC statistics                                      │
│    - Submit new jobs                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Credential Management Flow

### Adding Service Credentials

```
USER JOURNEY: First-Time Credential Setup
═══════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────┐
│  Step 1: User Realizes Need for Credentials                 │
│  ────────────────────────────────────────────               │
│  Scenario A: During job submission                          │
│    → Tries to submit job                                     │
│    → Gets 400 error: "No credentials configured"            │
│    → Directed to Settings → Service Credentials             │
│                                                               │
│  Scenario B: Proactive setup                                │
│    → Navigates to Settings                                   │
│    → Sees "Service Credentials" section                      │
│    → Clicks "Add Credentials"                                │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 2: Get H3Africa Account & Token                       │
│  ──────────────────────────────────────                     │
│  1. Visit https://impute.afrigen-d.org/                      │
│  2. Click "Register" or "Sign In"                            │
│  3. Complete registration form                               │
│  4. Verify email                                             │
│  5. Login to H3Africa                                        │
│  6. Navigate: Settings → API Tokens                          │
│  7. Click "Generate New Token"                               │
│  8. Copy token: "h3a_1a2b3c4d5e6f..."                        │
│     ⚠️  Token shown only once!                               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 3: Return to Platform and Configure                   │
│  ──────────────────────────────────────────                 │
│  Frontend UI (React):                                        │
│  ┌─────────────────────────────────────────┐                │
│  │  Add Service Credentials                │                │
│  │                                          │                │
│  │  Service: [H3Africa ▼]                  │                │
│  │  Label: [My H3Africa Account___]        │                │
│  │  API Token: [••••••••••••••••••]        │                │
│  │                                          │                │
│  │  [Test Connection] [Save Credentials]   │                │
│  └─────────────────────────────────────────┘                │
│                                                               │
│  On "Save Credentials" click:                                │
│    → Validates token format                                  │
│    → Shows loading spinner                                   │
│    → Makes API call                                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ POST /users/me/service-credentials
                     │ Headers: Authorization: Bearer {jwt}
                     │ Body: {service_id, api_token, label}
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              User Service (Port 8001)                        │
│                                                               │
│  Validation:                                                 │
│  ──────────                                                  │
│  1. JWT valid? → Extract user_id                             │
│  2. Service exists? → Query service_registry                 │
│  3. Token format valid? → Regex check                        │
│                                                               │
│  Storage:                                                    │
│  ────────                                                    │
│  1. Check existing:                                          │
│     SELECT * FROM user_service_credentials                   │
│     WHERE user_id={user_id} AND service_id={service_id}      │
│                                                               │
│  2. If exists:                                               │
│     UPDATE user_service_credentials                          │
│     SET api_token={token}, updated_at=NOW(),                 │
│         is_verified=false  ← Reset verification              │
│                                                               │
│  3. If new:                                                  │
│     INSERT INTO user_service_credentials (                   │
│       user_id, service_id, api_token,                        │
│       credential_type, label, is_active                      │
│     ) VALUES ({user_id}, {service_id}, {token},              │
│               'api_token', {label}, true)                    │
│                                                               │
│  4. Audit log:                                               │
│     INSERT INTO audit_logs (                                 │
│       user_id, action, resource_type,                        │
│       details, timestamp                                     │
│     ) VALUES ({user_id}, 'create_credential',                │
│               'service_credential',                          │
│               'Service: H3Africa', NOW())                    │
│                                                               │
│  Response: {                                                 │
│    id: 42,                                                   │
│    service_id: 1,                                            │
│    label: "My H3Africa Account",                             │
│    is_verified: false,                                       │
│    has_api_token: true,                                      │
│    created_at: "2025-10-04T10:30:00Z"                        │
│  }                                                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Success response
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   Frontend UI                                │
│  ┌─────────────────────────────────────────┐                │
│  │  ✅ Credentials Saved Successfully!      │                │
│  │                                          │                │
│  │  Service: H3Africa                       │                │
│  │  Label: My H3Africa Account              │                │
│  │  Status: ⚠️  Unverified                  │                │
│  │                                          │                │
│  │  [Test Connection Now]                   │                │
│  └─────────────────────────────────────────┘                │
│                                                               │
│  User can now:                                               │
│  - Submit jobs ✅                                            │
│  - Test credentials (optional)                               │
│  - View/edit/delete credentials                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Error Handling Flow

### Missing Credentials Error

```
ERROR SCENARIO: User tries to submit job without credentials
═══════════════════════════════════════════════════════════════

User                Job Processor           User Service
  │                       │                       │
  │ POST /jobs            │                       │
  │ service_id=1          │                       │
  │──────────────────────>│                       │
  │                       │                       │
  │                       │ Check credentials     │
  │                       │ GET /internal/users/  │
  │                       │ {user_id}/service-    │
  │                       │ credentials/{svc_id}  │
  │                       │──────────────────────>│
  │                       │                       │
  │                       │ {has_credential:false}│
  │                       │<──────────────────────│
  │                       │                       │
  │ 400 Bad Request       │                       │
  │<──────────────────────│                       │
  │ {                     │                       │
  │   error: "No creds",  │                       │
  │   message: "You must  │                       │
  │     configure...",    │                       │
  │   action: "Go to      │                       │
  │     Settings...",     │                       │
  │   service_id: 1       │                       │
  │ }                     │                       │
  │                       │                       │
  ↓                       │                       │

┌─────────────────────────────────────────┐
│  Frontend Shows User-Friendly Error:    │
│  ┌─────────────────────────────────┐    │
│  │  ⚠️  Setup Required              │    │
│  │                                  │    │
│  │  You need to configure your      │    │
│  │  H3Africa API credentials        │    │
│  │  before submitting jobs.         │    │
│  │                                  │    │
│  │  [Configure Credentials]         │    │
│  └─────────────────────────────────┘    │
│                                          │
│  On click → Redirects to:                │
│  /settings/service-credentials           │
└──────────────────────────────────────────┘
```

### Invalid Credentials Error

```
ERROR SCENARIO: User's H3Africa token is invalid/expired
═══════════════════════════════════════════════════════

Worker                  H3Africa              Job Database
  │                         │                       │
  │ POST /api/v2/jobs/      │                       │
  │ submit                  │                       │
  │ X-Auth-Token: {token}   │                       │
  │────────────────────────>│                       │
  │                         │                       │
  │ 401 Unauthorized        │                       │
  │ {error: "Invalid token"}│                       │
  │<────────────────────────│                       │
  │                         │                       │
  │ Update job: failed      │                       │
  │─────────────────────────────────────────────────>│
  │ SET status='failed'     │                       │
  │ SET error_message=      │                       │
  │   "H3Africa auth failed"│                       │
  │                         │                       │
  ↓                         │                       │

User receives notification:
┌─────────────────────────────────────────┐
│  ❌ Job Failed                           │
│                                          │
│  Your job failed due to authentication   │
│  error with H3Africa.                    │
│                                          │
│  Error: Invalid API token                │
│                                          │
│  Action: Please update your credentials  │
│  at Settings → Service Credentials       │
│                                          │
│  [Update Credentials]                    │
└──────────────────────────────────────────┘
```

---

## 6. Complete System Architecture

### High-Level Component Diagram

```
                        FEDERATED IMPUTATION PLATFORM
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│                          FRONTEND LAYER                                  │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    React Application (Port 3000)                  │   │
│  │                                                                    │   │
│  │  Pages:                         Components:                       │   │
│  │  - Dashboard                    - ServiceCredentials              │   │
│  │  - Jobs                         - JobSubmission                   │   │
│  │  - Services                     - JobMonitor                      │   │
│  │  - Settings                     - ResultsDownload                 │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────┬───────────────────────────────────────────┘
                               │ HTTPS/REST API
                               ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                       API GATEWAY (Port 8000)                            │
│  - Request routing                                                       │
│  - JWT validation                                                        │
│  - Rate limiting                                                         │
│  - CORS handling                                                         │
└─┬─────────┬────────────┬──────────────┬───────────────┬─────────────────┘
  │         │            │              │               │
  │         │            │              │               │
  ↓         ↓            ↓              ↓               ↓

┌─────────────────────────────────────────────────────────────────────────┐
│                         MICROSERVICES LAYER                              │
│                                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │
│  │ User Service │  │   Service    │  │     Job      │  │    File    │  │
│  │  (Port 8001) │  │   Registry   │  │  Processor   │  │  Manager   │  │
│  │              │  │  (Port 8002) │  │  (Port 8003) │  │(Port 8004) │  │
│  │ - Auth       │  │              │  │              │  │            │  │
│  │ - Users      │  │ - Services   │  │ - Jobs       │  │ - Upload   │  │
│  │ - Profiles   │  │ - Panels     │  │ - Status     │  │ - Download │  │
│  │ - Credentials│  │ - Health     │  │ - Workers    │  │ - Storage  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │
│                                                                           │
│  ┌──────────────┐  ┌──────────────┐                                     │
│  │Notification  │  │  Monitoring  │                                     │
│  │  (Port 8005) │  │  (Port 8006) │                                     │
│  │              │  │              │                                     │
│  │ - Email      │  │ - Metrics    │                                     │
│  │ - Web alerts │  │ - Logs       │                                     │
│  │ - SMS (TODO) │  │ - Health     │                                     │
│  └──────────────┘  └──────────────┘                                     │
└─────────────────────────────────────────────────────────────────────────┘
                               │
                               ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                        INFRASTRUCTURE LAYER                              │
│                                                                           │
│  ┌──────────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │    PostgreSQL        │  │      Redis       │  │     Celery       │  │
│  │    (Port 5432)       │  │   (Port 6379)    │  │    Workers       │  │
│  │                      │  │                  │  │                  │  │
│  │ Databases:           │  │ - Job queue      │  │ - process_job    │  │
│  │ - user_management_db │  │ - Cache          │  │ - cancel_job     │  │
│  │ - service_registry_db│  │ - Sessions       │  │ - monitor_job    │  │
│  │ - job_processing_db  │  │                  │  │                  │  │
│  │ - file_management_db │  │                  │  │                  │  │
│  └──────────────────────┘  └──────────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                               │
                               ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                      EXTERNAL SERVICES                                   │
│                                                                           │
│  ┌──────────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │    H3Africa          │  │     Michigan     │  │     ILIFU        │  │
│  │  Imputation Server   │  │  Imputation Srv  │  │   GA4GH WES      │  │
│  │                      │  │                  │  │                  │  │
│  │ API: Michigan v2     │  │ API: Michigan v2 │  │ API: GA4GH WES   │  │
│  │ Auth: X-Auth-Token   │  │ Auth: X-Auth-Token│  │ Auth: Bearer    │  │
│  │ URL: impute.afrigen  │  │ URL: imputations-│  │ URL: ga4gh-start │  │
│  │      -d.org          │  │      erver.sph...│  │      er-kit...   │  │
│  └──────────────────────┘  └──────────────────┘  └──────────────────┘  │
│                                                                           │
│  ✅ Per-User Authentication: Each user uses their own credentials        │
└─────────────────────────────────────────────────────────────────────────┘
```

### Data Flow: Complete Request Cycle

```
COMPLETE REQUEST CYCLE: Job Submission to Results Download
═══════════════════════════════════════════════════════════════════════════

1. USER AUTHENTICATION
   User → Frontend → User Service
   - Login with username/password
   - Receive JWT token
   - Store in localStorage

2. CREDENTIAL CONFIGURATION (One-time)
   User → Frontend → User Service → Database
   - User provides H3Africa API token
   - Stored in user_service_credentials table
   - Linked to user_id + service_id

3. JOB SUBMISSION
   User → Frontend → Job Processor → User Service (validate creds)
   - Check user has credentials ✅
   - Create job record
   - Upload file to File Manager
   - Queue job in Redis

4. JOB PROCESSING
   Celery Worker → User Service → File Manager → H3Africa
   - Fetch user's credentials ✅
   - Download input file
   - Submit to H3Africa with user's token ✅
   - Poll status every 30s
   - Download results when complete
   - Upload results to File Manager

5. NOTIFICATION
   Worker → Notification Service → User
   - Email notification sent
   - Web notification created
   - User alerted of completion

6. RESULTS DOWNLOAD
   User → Frontend → Job Processor → File Manager
   - Request results URL
   - Download ZIP file
   - Extract imputed genotypes
```

---

## Summary

This document provides comprehensive visual flows for:

✅ **Authentication**: Platform login + service credentials
✅ **Job Submission**: Complete validation and queueing flow
✅ **Job Processing**: Detailed worker execution with per-user credentials
✅ **Credential Management**: User journey for setup
✅ **Error Handling**: Common failure scenarios and resolution
✅ **System Architecture**: High-level component diagram

**Key Design Principle**: Per-user service credentials ensure proper resource tracking, security isolation, and compliance with external service terms.

---

**Last Updated**: October 4, 2025
**Status**: Production Architecture
