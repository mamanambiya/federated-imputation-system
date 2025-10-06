# Architecture Fix Summary - Per-User Service Credentials

**Date**: October 4, 2025
**Issue**: Critical design flaw in authentication architecture
**Status**: ✅ Fixed and Implemented
**Breaking Change**: Yes

---

## 🚨 The Problem Identified

The initial job execution implementation had a **fundamental design flaw**:

### What Was Wrong
```python
# WRONG: All users shared one API token
api_token = service_info.get('api_config', {}).get('api_token')
# Everyone used the same H3Africa account
```

**Critical Issues:**
- ❌ All users shared a single H3Africa account
- ❌ No per-user resource tracking or quotas
- ❌ Security vulnerability (one compromised token affects everyone)
- ❌ Violates service terms of use
- ❌ Impossible to track individual usage
- ❌ Cannot support different user permissions

---

## ✅ The Solution Implemented

### Correct Architecture: Per-User Service Credentials

```python
# CORRECT: Each user has their own credentials
user_cred = await get_user_service_credential(user_id, service_id)
api_token = user_cred['api_token']  # User's personal token
# Each user uses their own H3Africa account
```

### Visual Comparison: Wrong vs Correct

```
❌ WRONG APPROACH (Shared Token):
┌──────┐  ┌──────┐  ┌──────┐
│User 1│  │User 2│  │User 3│
└──┬───┘  └──┬───┘  └──┬───┘
   │         │         │
   └────┬────┴────┬────┘
        │         │
        ↓         ↓
   ┌────────────────────┐
   │    Job Processor   │
   │ (Shared API Token) │
   └─────────┬──────────┘
             │
             ↓ Same token for all users
   ┌─────────────────────┐
   │  H3Africa Service   │
   │  (One Account for   │
   │   ALL users) 🚨      │
   └─────────────────────┘

   Problems:
   • One account for everyone
   • No per-user quotas
   • Security risk
   • No usage tracking


✅ CORRECT APPROACH (Per-User Credentials):
┌──────┐  ┌──────┐  ┌──────┐
│User 1│  │User 2│  │User 3│
└──┬───┘  └──┬───┘  └──┬───┘
   │         │         │
   │         │         │
   ↓         ↓         ↓
┌────┐    ┌────┐    ┌────┐
│Cred│    │Cred│    │Cred│  ← Stored per user
│ 1  │    │ 2  │    │ 3  │
└─┬──┘    └─┬──┘    └─┬──┘
  │         │         │
  └────┬────┴────┬────┘
       ↓         ↓
  ┌────────────────────┐
  │   Job Processor    │
  │ Fetches USER cred  │
  └─────────┬──────────┘
            │
            ↓ User's own token
  ┌─────────────────────┐
  │  H3Africa Service   │
  │  • User 1's Account │
  │  • User 2's Account │
  │  • User 3's Account │
  └─────────────────────┘

  Benefits:
  ✅ Each user has own account
  ✅ Per-user quotas enforced
  ✅ Better security
  ✅ Accurate usage tracking
```

**Benefits:**
- ✅ Each user has their own H3Africa account
- ✅ Proper per-user resource tracking and quotas
- ✅ Better security and isolation
- ✅ Compliant with service terms
- ✅ Accurate usage tracking
- ✅ Flexible user permissions

---

## 📊 What Was Changed

### 1. Database Schema (User Service)

**New Table Added:**
```sql
CREATE TABLE user_service_credentials (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,

    credential_type VARCHAR(50) DEFAULT 'api_token',
    api_token TEXT,  -- User's personal token

    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    last_used_at TIMESTAMP,

    UNIQUE(user_id, service_id)
);
```

**File**: `microservices/user-service/main.py`
- Added `UserServiceCredential` model (lines 100-139)
- Supports multiple auth types (API token, OAuth, Basic Auth)
- Tracks verification status and usage

### 2. Credential Management API (User Service)

**New Endpoints Added:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/users/me/service-credentials` | Add/update user's credentials |
| GET | `/users/me/service-credentials` | List user's credentials |
| GET | `/users/me/service-credentials/{service_id}` | Get specific credential |
| DELETE | `/users/me/service-credentials/{service_id}` | Remove credential |
| GET | `/internal/users/{user_id}/service-credentials/{service_id}` | Internal: fetch actual credentials |

**File**: `microservices/user-service/main.py` (lines 513-730)

### 3. Worker Updated (Job Processor)

**Changes in `_submit_michigan_job()`:**

```python
# Before (WRONG):
api_token = service_info.get('api_config', {}).get('api_token')

# After (CORRECT):
user_id = job_data.get('user_id')
service_id = service_info.get('id')

# Fetch user's personal credentials
cred_response = await self.client.get(
    f"{USER_SERVICE_URL}/internal/users/{user_id}/service-credentials/{service_id}"
)
user_cred = cred_response.json()

if not user_cred.get('has_credential'):
    return {'error': 'No credentials configured', 'status': 'failed'}

api_token = user_cred.get('api_token')  # User's personal token
```

**Files Modified:**
- `microservices/job-processor/worker.py` (lines 28, 59-95, 557)
- Added USER_SERVICE_URL configuration
- Updated job_data to include user_id
- Fetches per-user credentials before job submission

### 4. Job Submission Validation (Job Processor)

**Pre-Submission Check Added:**

```python
# In create_job() endpoint
# CRITICAL: Validate user has credentials for selected service
cred_response = await client.get(
    f"{USER_SERVICE_URL}/internal/users/{user_id}/service-credentials/{service_id}"
)

if not cred_response.json().get('has_credential'):
    raise HTTPException(
        status_code=400,
        detail="You must configure your API credentials for this service"
    )
```

**File**: `microservices/job-processor/main.py` (lines 31, 356-385)
- Validates credentials exist before job creation
- Returns helpful error message with action steps
- Prevents job submission without credentials

### 5. Documentation Updates

**New Documents:**
1. **[CORRECTED_AUTHENTICATION_ARCHITECTURE.md](CORRECTED_AUTHENTICATION_ARCHITECTURE.md)**
   - Complete explanation of per-user credentials
   - Architecture diagrams
   - Migration guide
   - Testing instructions

2. **[ARCHITECTURE_FIX_SUMMARY.md](ARCHITECTURE_FIX_SUMMARY.md)** (this file)
   - Summary of changes
   - Implementation details
   - User workflow

**Updated Documents:**
1. **[QUICKSTART_JOB_EXECUTION.md](QUICKSTART_JOB_EXECUTION.md)**
   - Corrected authentication flow
   - Added credential configuration steps
   - Updated prerequisites

2. **[H3AFRICA_JOB_EXECUTION.md](H3AFRICA_JOB_EXECUTION.md)**
   - Added per-user credential section
   - Updated authentication architecture
   - Corrected workflow diagrams

---

## 🔄 User Workflow (Corrected)

### Visual Flow: Complete User Journey

```
┌─────────────────────────────────────────────────────────────────┐
│                    STEP 1: Platform Registration                │
└─────────────────────────────────────────────────────────────────┘
         User  ──→  POST /auth/register  ──→  User Service
                     {username, password}      Creates account
                                                     ↓
                                              Platform Account ✅

┌─────────────────────────────────────────────────────────────────┐
│                  STEP 2: Get H3Africa Account                   │
└─────────────────────────────────────────────────────────────────┘
         User  ──→  https://impute.afrigen-d.org/
                     1. Register
                     2. Settings → API Tokens
                     3. Generate Token
                     4. Copy Token
                                                     ↓
                                         User has H3Africa Token ✅

┌─────────────────────────────────────────────────────────────────┐
│              STEP 3: Configure Credentials on Platform          │
└─────────────────────────────────────────────────────────────────┘
         User  ──→  POST /users/me/service-credentials
                     Authorization: Bearer <Platform_JWT>
                     {
                       service_id: 1,
                       api_token: "USER_H3AFRICA_TOKEN"
                     }
                                                     ↓
                                    User Service Credential Stored ✅
                                    (user_id=X, service_id=1)

┌─────────────────────────────────────────────────────────────────┐
│                      STEP 4: Submit Job                         │
└─────────────────────────────────────────────────────────────────┘
    User ──→ POST /jobs ──→ Job Processor
            (Platform JWT)      ↓
                         1. Validate Platform JWT ✅
                         2. Check user has credentials for service ✅
                            GET /internal/users/{user_id}/service-creds/{svc}
                         3. Create job if credentials exist ✅
                                ↓
                         Celery Queue
                                ↓
                         Worker picks up job
                                ↓
                         1. Fetch user's H3Africa token ✅
                            GET /internal/users/{user_id}/service-creds/{svc}
                         2. Submit to H3Africa with USER's token ✅
                            X-Auth-Token: USER_H3AFRICA_TOKEN
                                ↓
                         H3Africa Imputation Service
                            • Uses user's personal account ✅
                            • Charges user's quota ✅
                            • Tracks user's usage ✅
```

### Command Examples

#### Step 1: Register on Platform
```bash
curl -X POST http://localhost:8001/api/auth/register \
  -d '{"username":"researcher1","password":"secure_pass",...}'
```

#### Step 2: Get H3Africa Account
1. Go to https://impute.afrigen-d.org/
2. Register for H3Africa account
3. Navigate to Settings → API Tokens
4. Generate API token
5. Copy token (shown once)

#### Step 3: Configure Credentials on Platform
```bash
# Login to platform
TOKEN=$(curl -s -X POST http://localhost:8001/api/auth/login \
  -d '{"username":"researcher1","password":"secure_pass"}' \
  | jq -r '.access_token')

# Add H3Africa credentials
curl -X POST http://localhost:8001/users/me/service-credentials \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "service_id": 1,
    "api_token": "USER_H3AFRICA_TOKEN",
    "label": "My H3Africa"
  }'
```

#### Step 4: Submit Jobs
```bash
# Now jobs use user's H3Africa account
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "service_id=1" \
  -F "input_file=@test.vcf.gz" \
  ...
```

**What Happens:**
1. ✅ Job Processor validates user has credentials for service
2. ✅ Worker fetches user's H3Africa token
3. ✅ Submits to H3Africa using user's personal token
4. ✅ H3Africa charges user's account (not shared account)
5. ✅ Proper resource tracking and quotas per user

---

## 🔧 Implementation Checklist

### Backend Changes
- [x] Add `UserServiceCredential` model to user-service
- [x] Create credential management endpoints
- [x] Add internal credential fetch endpoint
- [x] Update worker to use per-user credentials
- [x] Add credential validation to job submission
- [x] Include user_id in job_data

### API Endpoints
- [x] `POST /users/me/service-credentials`
- [x] `GET /users/me/service-credentials`
- [x] `GET /users/me/service-credentials/{service_id}`
- [x] `DELETE /users/me/service-credentials/{service_id}`
- [x] `GET /internal/users/{user_id}/service-credentials/{service_id}`

### Documentation
- [x] Create corrected architecture guide
- [x] Update quick start guide
- [x] Update H3Africa integration guide
- [x] Create migration guide
- [x] Update authentication flow diagrams

### Testing (TODO)
- [ ] Test user credential creation
- [ ] Test job submission with valid credentials
- [ ] Test job rejection without credentials
- [ ] Test worker credential fetch
- [ ] Test per-user H3Africa submission
- [ ] Verify resource tracking per user

---

## 🚀 Migration Path

### For New Implementations
✅ Use per-user credentials from day 1 (already implemented)

### For Existing Implementations

**Option 1: Gradual Migration**
```python
# Support both temporarily
if user has personal credentials:
    use user's token
else:
    use shared token (deprecated, with warning)
```

**Option 2: Hard Cutover** (Recommended)
```python
# Require user credentials immediately
if not user has credentials:
    raise "Please configure your credentials"
```

**Admin Token Repurpose:**
- Service Registry tokens → Health checks only
- NOT for job submission
- Admin operations only

---

## 📈 Impact Assessment

### Security
- ✅ **Improved**: No shared credentials
- ✅ **Isolated**: Per-user token compromise
- ✅ **Auditable**: Clear ownership of actions

### Resource Management
- ✅ **Tracked**: Per-user quotas enforced
- ✅ **Fair**: No single user can exhaust shared quota
- ✅ **Scalable**: Users upgrade their own accounts

### Compliance
- ✅ **TOS Compliant**: Meets service provider terms
- ✅ **Auditable**: Complete per-user audit trail
- ✅ **Accountable**: Clear resource ownership

### User Experience
- ⚠️ **One-time Setup**: Users must configure credentials once
- ✅ **Self-Service**: Users manage their own tokens
- ✅ **Transparent**: Clear error messages guide users

---

## 🎯 Key Takeaways

### What Changed
1. **Database**: Added `user_service_credentials` table
2. **API**: 5 new endpoints for credential management
3. **Worker**: Fetches per-user credentials
4. **Validation**: Checks credentials before job submission
5. **Docs**: Complete rewrite of auth architecture

### Why It Matters
- **Correct Design**: Federated systems need per-user credentials
- **Resource Tracking**: External services track usage per account
- **Security**: Proper isolation between users
- **Compliance**: Meets service provider requirements

### User Impact
- **One-Time Setup**: Users add H3Africa token once
- **Better Tracking**: Users see their own usage/costs
- **More Control**: Users manage their own service access

---

## 📝 Files Modified

### Core Implementation
1. **microservices/user-service/main.py**
   - Lines 100-139: UserServiceCredential model
   - Lines 225-263: Pydantic models
   - Lines 513-730: Credential management endpoints

2. **microservices/job-processor/worker.py**
   - Line 28: Added USER_SERVICE_URL
   - Lines 59-95: Updated `_submit_michigan_job()`
   - Line 557: Added user_id to job_data

3. **microservices/job-processor/main.py**
   - Line 31: Added USER_SERVICE_URL
   - Lines 356-385: Added credential validation

### Documentation
1. **docs/CORRECTED_AUTHENTICATION_ARCHITECTURE.md** (new)
2. **docs/ARCHITECTURE_FIX_SUMMARY.md** (new)
3. **docs/QUICKSTART_JOB_EXECUTION.md** (updated)
4. **docs/H3AFRICA_JOB_EXECUTION.md** (updated)

---

## ✅ Summary

**Problem**: Shared service credentials (insecure, non-scalable, violates TOS)
**Solution**: Per-user service credentials (secure, scalable, compliant)
**Status**: Fully implemented and documented
**Next Steps**: Test and deploy

This is the **correct architecture** for a federated genomic imputation platform.

---

**Last Updated**: October 4, 2025
**Version**: 2.0
**Breaking Change**: Yes - users must configure credentials
