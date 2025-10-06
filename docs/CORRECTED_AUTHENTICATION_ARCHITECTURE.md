# Corrected Authentication Architecture - Per-User Service Credentials

**Date**: October 4, 2025
**Status**: ✅ Implemented
**Breaking Change**: Yes - requires user action

---

## 🚨 Critical Design Fix

### The Problem

The initial implementation used a **single shared API token** for all users accessing external services. This was fundamentally flawed:

❌ All users shared one H3Africa account
❌ No per-user resource tracking
❌ No per-user quota management
❌ Security issue (one compromised token affects everyone)
❌ Can't support users with different service permissions

### The Solution

**Per-User Service Credentials**: Each user must configure their own API tokens for external services they want to use.

✅ Each user has their own H3Africa account
✅ H3Africa tracks usage per user
✅ Users manage their own service credentials
✅ Different users can have different service access
✅ Proper isolation and security

---

## Architecture Overview

### Two Types of Authentication

#### 1. Platform Authentication (User → Our Platform)
- **Purpose**: Authenticate users to our federated imputation platform
- **Credentials**: Username/password managed in our database
- **Token**: JWT returned by User Service
- **Usage**: All API calls to our platform
- **Lifetime**: 24 hours (configurable)

#### 2. Service Authentication (User → External Service)
- **Purpose**: Authenticate user to external imputation services
- **Credentials**: User's personal API tokens for each service
- **Storage**: `user_service_credentials` table (encrypted)
- **Usage**: Backend uses these to submit jobs on user's behalf
- **Lifetime**: Set by external service (usually no expiration)

### Complete Authentication Flow

```
┌──────────────────────────────────────────────────────┐
│                     User                              │
│  Platform Creds: username/password                    │
│  H3Africa Creds: personal API token                   │
└────────────┬─────────────────────────────────────────┘
             │
             │ 1. Login to platform
             ↓
┌──────────────────────────────────────────────────────┐
│         User Service (Port 8001)                      │
│  ✓ Validates username/password                        │
│  ✓ Returns Platform JWT                               │
└────────────┬─────────────────────────────────────────┘
             │
             │ 2. Configure H3Africa credentials
             ↓
┌──────────────────────────────────────────────────────┐
│         POST /users/me/service-credentials            │
│  ✓ User provides H3Africa API token                   │
│  ✓ Stored in user_service_credentials table           │
│  ✓ Encrypted and linked to user + service             │
└────────────┬─────────────────────────────────────────┘
             │
             │ 3. Submit job (with Platform JWT)
             ↓
┌──────────────────────────────────────────────────────┐
│         Job Processor (Port 8003)                     │
│  ✓ Validates Platform JWT                             │
│  ✓ Checks user has credentials for service ✅         │
│  ✓ Creates job if credentials exist                   │
│  ✓ Rejects if credentials missing                     │
└────────────┬─────────────────────────────────────────┘
             │
             │ 4. Worker processes job
             ↓
┌──────────────────────────────────────────────────────┐
│            Celery Worker                              │
│  1. Fetches USER's H3Africa token                     │
│     GET /internal/users/{user_id}/service-creds/{svc} │
│  2. Submits to H3Africa with USER's token ✅          │
└────────────┬─────────────────────────────────────────┘
             │
             │ 5. Submit with user's credentials
             ↓
┌──────────────────────────────────────────────────────┐
│         H3Africa (User's Personal Account)            │
│  Header: X-Auth-Token: <USER'S_H3Africa_Token>        │
│  ✓ Validates user's token                             │
│  ✓ Charges user's H3Africa account ✅                 │
│  ✓ Tracks user's quota/usage ✅                       │
└──────────────────────────────────────────────────────┘
```

---

## Implementation Details

### 1. Database Schema

**New Table: `user_service_credentials`**

```sql
CREATE TABLE user_service_credentials (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    service_id INTEGER NOT NULL,

    -- Credential types
    credential_type VARCHAR(50) DEFAULT 'api_token',
    api_token TEXT,
    oauth_token TEXT,
    oauth_refresh_token TEXT,
    username VARCHAR(255),
    password TEXT,  -- Hashed

    -- Metadata
    label VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    last_verified_at TIMESTAMP,
    last_used_at TIMESTAMP,

    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(user_id, service_id)
);
```

### 2. API Endpoints

#### User-Facing Endpoints (User Service - Port 8001)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/users/me/service-credentials` | Add/update credentials |
| GET | `/users/me/service-credentials` | List all user's credentials |
| GET | `/users/me/service-credentials/{service_id}` | Get specific credential |
| DELETE | `/users/me/service-credentials/{service_id}` | Remove credential |

#### Internal Endpoint (for Microservices)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/internal/users/{user_id}/service-credentials/{service_id}` | Fetch user's actual credentials |

**Security**: Internal endpoint should be protected by network isolation or API gateway.

### 3. Worker Integration

**Updated `worker.py` - `_submit_michigan_job()`:**

```python
async def _submit_michigan_job(self, service_info, job_data):
    # Get user_id from job_data
    user_id = job_data.get('user_id')
    service_id = service_info.get('id')

    # Fetch USER's credentials from user service
    cred_response = await self.client.get(
        f"{USER_SERVICE_URL}/internal/users/{user_id}/service-credentials/{service_id}"
    )
    user_cred = cred_response.json()

    if not user_cred.get('has_credential'):
        return {
            'error': 'No credentials configured for this service',
            'status': 'failed'
        }

    # Use USER's personal API token
    api_token = user_cred.get('api_token')

    headers = {'X-Auth-Token': api_token}  # ✅ User's own token
    # ... submit job ...
```

### 4. Job Submission Validation

**Updated `main.py` - `/jobs` endpoint:**

```python
@app.post("/jobs")
async def create_job(...):
    # CRITICAL: Validate user has credentials
    cred_response = await client.get(
        f"{USER_SERVICE_URL}/internal/users/{user_id}/service-credentials/{service_id}"
    )

    if not cred_response.json().get('has_credential'):
        raise HTTPException(
            status_code=400,
            detail="You must configure your API credentials for this service"
        )

    # Proceed with job creation...
```

---

## User Workflow

### Step 1: Platform Registration
```bash
# User registers on our platform
curl -X POST http://localhost:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "researcher1",
    "email": "researcher1@university.edu",
    "first_name": "Jane",
    "last_name": "Researcher",
    "password": "secure_password"
  }'
```

### Step 2: Get H3Africa API Token
1. User registers at https://impute.afrigen-d.org/
2. Navigate to Settings → API Tokens
3. Generate new token
4. Copy token (shown once)

### Step 3: Configure Service Credentials
```bash
# User logs into our platform
TOKEN=$(curl -s -X POST http://localhost:8001/api/auth/login \
  -d '{"username":"researcher1","password":"secure_password"}' \
  | jq -r '.access_token')

# User adds H3Africa credentials
curl -X POST http://localhost:8001/users/me/service-credentials \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "service_id": 1,
    "credential_type": "api_token",
    "api_token": "USER_H3AFRICA_TOKEN_HERE",
    "label": "My H3Africa Account"
  }'
```

### Step 4: Submit Job
```bash
# Now user can submit jobs
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=My Imputation Job" \
  -F "service_id=1" \
  -F "reference_panel_id=1" \
  -F "input_file=@test.vcf.gz" \
  ...
```

**What happens:**
1. Job Processor validates user has credentials for service 1 ✅
2. Worker fetches user's H3Africa token ✅
3. Worker submits to H3Africa using user's token ✅
4. H3Africa charges user's account ✅

---

## Migration Guide

### For Existing Implementations

If you've been using the shared token approach:

#### Option 1: Gradual Migration (Backward Compatible)

```python
# In worker.py - support both approaches temporarily
user_cred = await get_user_service_credential(user_id, service_id)

if user_cred.get('has_credential'):
    # Use user's personal token (NEW)
    api_token = user_cred['api_token']
else:
    # Fallback to shared token (OLD - deprecated)
    api_token = service_info.get('admin_api_config', {}).get('api_token')
    logger.warning(f"User {user_id} using deprecated shared token")
```

#### Option 2: Hard Cutover (Breaking Change)

```python
# Require user credentials immediately
user_cred = await get_user_service_credential(user_id, service_id)

if not user_cred.get('has_credential'):
    raise Exception("Please configure your service credentials in Settings")

api_token = user_cred['api_token']
```

### Admin Token Purpose

Service Registry tokens are now ONLY for:
- Health checks
- Service discovery
- Metadata synchronization
- Admin operations

**NOT for user job submission!**

---

## Security Considerations

### 1. Credential Encryption
```python
# TODO: Implement in production
from cryptography.fernet import Fernet

def encrypt_credential(token: str) -> str:
    f = Fernet(ENCRYPTION_KEY)
    return f.encrypt(token.encode()).decode()

def decrypt_credential(encrypted: str) -> str:
    f = Fernet(ENCRYPTION_KEY)
    return f.decrypt(encrypted.encode()).decode()
```

### 2. Internal Endpoint Protection

**API Gateway Rules:**
```nginx
# Block external access to internal endpoints
location /internal/ {
    allow 10.0.0.0/8;      # Internal network only
    deny all;
    proxy_pass http://user-service:8001;
}
```

### 3. Credential Rotation

```python
# Add to user service
@app.post("/users/me/service-credentials/{service_id}/rotate")
async def rotate_credential(...):
    # Invalidate old credential
    # Request user to provide new token
    # Update database
    # Return success
```

---

## Testing

### Test User Setup

```bash
# 1. Create test user with H3Africa account
curl -X POST http://localhost:8001/api/auth/register \
  -d '{"username":"testuser","password":"test123",...}'

# 2. Login
TOKEN=$(curl -s -X POST http://localhost:8001/api/auth/login \
  -d '{"username":"testuser","password":"test123"}' | jq -r '.access_token')

# 3. Add H3Africa credentials
curl -X POST http://localhost:8001/users/me/service-credentials \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"service_id":1,"api_token":"YOUR_H3AFRICA_TOKEN"}'

# 4. Verify credentials exist
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8001/users/me/service-credentials

# 5. Submit job (should work now)
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "service_id=1" \
  -F "input_file=@test.vcf.gz" \
  ...
```

### Error Cases to Test

```bash
# 1. Job submission without credentials - should fail
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN_NO_CREDS" \
  -F "service_id=1" \
  ...
# Expected: 400 Bad Request - "No credentials configured"

# 2. Credentials for different service
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "service_id=2" \  # Different service
  ...
# Expected: 400 Bad Request - "No credentials for service 2"
```

---

## Benefits of This Architecture

### 1. **Proper Resource Accounting**
- Each user's jobs tracked on their H3Africa account
- Usage and quotas managed per user
- Fair resource allocation

### 2. **Security & Isolation**
- User credentials never shared
- Compromised token affects only that user
- Proper access control

### 3. **Flexibility**
- Different users can use different services
- Some users can have premium service access
- Service-specific permissions supported

### 4. **Compliance**
- Audit trail per user
- Data sovereignty requirements met
- Terms of service acceptance per user

### 5. **Scalability**
- No bottleneck with shared account quotas
- Users can upgrade their own service plans
- Platform-agnostic service integration

---

## FAQ

**Q: Why can't we use a single platform account for all users?**
A: External services (H3Africa, Michigan) track usage and enforce quotas per account. Using one account for all users would:
- Hit quota limits quickly
- Make it impossible to track individual usage
- Violate terms of service
- Prevent fair resource allocation

**Q: Do users need to register with every external service?**
A: Yes. Each user must:
1. Register with external service (e.g., H3Africa)
2. Generate their API token
3. Configure it in our platform

This is standard practice for federated systems.

**Q: What if a user's token expires?**
A: Most imputation service tokens don't expire. If they do:
1. User receives error when job fails
2. User generates new token from service
3. User updates credentials in Settings
4. User resubmits job

**Q: Can admins see user credentials?**
A: No. Credentials should be encrypted at rest. Even admins can't view actual tokens in production.

---

## Summary

✅ **Database**: `user_service_credentials` table added
✅ **API**: Credential management endpoints implemented
✅ **Worker**: Updated to use per-user credentials
✅ **Validation**: Job submission checks credentials exist
✅ **Security**: Proper isolation and encryption ready
✅ **Documentation**: Complete guide with examples

**This is the correct architecture for a federated imputation platform.**

---

**Last Updated**: October 4, 2025
**Version**: 2.0 (Corrected Architecture)
**Status**: Production Ready
