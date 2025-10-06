# Quick Start: H3Africa Job Execution

**Get a job running in 10 minutes!**

---

## Prerequisites ✅

1. **H3Africa Account**: Register at https://impute.afrigen-d.org/
2. **API Token**: Generate from Settings → API Tokens
3. **Services Running**: `docker-compose ps` (all services should be UP)

---

## Step-by-Step Guide

### 1. Prepare Test Data (2 minutes)

```bash
cd /home/ubuntu/federated-imputation-central
bash scripts/prepare_test_data.sh
```

**What it does:**
- Downloads 1000 Genomes chromosome 22 VCF
- Creates 3 test files (100, 1K, 10K variants)
- Validates VCF format

**Output:**
```
✓ Created: test_tiny_100var.vcf.gz (20K)
✓ Created: test_small_1000var.vcf.gz (200K)
✓ Created: test_medium_10kvar.vcf.gz (2M)
```

---

### 2. Setup H3Africa Service (1 minute)

```bash
python scripts/setup_h3africa_service.py --api-token YOUR_H3AFRICA_TOKEN
```

**Replace `YOUR_H3AFRICA_TOKEN`** with your actual token from https://impute.afrigen-d.org/

**What it does:**
- Registers H3Africa in Service Registry
- Creates 3 reference panels (H3Africa, 1000G African, AGVP)
- Runs health check

**Output:**
```
✅ Service created successfully - ID: 1
✅ Created panel: H3Africa Reference Panel
✅ Service is healthy - Response time: 177ms
```

---

### 3. Run End-to-End Test (5-10 minutes)

```bash
bash scripts/e2e_h3africa_test.sh
```

**What it does:**
1. Authenticates test user
2. Submits job with 1K variant VCF
3. Monitors status (pending → queued → running → completed)
4. Downloads results
5. Validates output

**Expected Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 1: Authentication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Authentication successful

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 2: Job Submission
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Job created successfully
  Job ID: 550e8400-e29b-41d4-a716-446655440000

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 3: Status Monitoring
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[00:00] ⏳ Pending (0%)
[00:30] 📋 Queued (0%)
[01:00] 🔄 Running (10%)
   External Job ID: job-20251004-abc123
[02:00] 🔄 Running (45%)
[05:30] 🔄 Running (75%)
[08:00] ✓ Completed (100%)
  Total execution time: 08:00

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 4: Results Download
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Results downloaded
  File: results_550e8400-e29b-41d4-a716-446655440000.zip
  Size: 1.5M

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 5: Results Validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ File is a valid ZIP archive
✓ Found VCF file: imputed.vcf.gz
✓ Valid VCF format
✓ Contains 1000 variants

════════════════════════════════════════════════
✓ END-TO-END TEST PASSED!
════════════════════════════════════════════════
```

---

## 🔐 Understanding Authentication

### Two-Layer Authentication Architecture

⚠️ **IMPORTANT**: Each user must have their own H3Africa account and API token.

The platform uses **two types of authentication**:

1. **Platform Authentication** - Login to our platform
   - Username: `test_user`, Password: `test123` (for our platform)
   - Returns: JWT token for API access
   - Purpose: Identifies who you are on our platform

2. **Service Credentials** - Your personal H3Africa account
   - **Required**: Each user needs their own H3Africa account
   - Obtained from: https://impute.afrigen-d.org/ → Settings → API Tokens
   - Configured in: Settings → Service Credentials (on our platform)
   - Purpose: Your personal credentials for job submission

### Complete Authentication Flow

```
┌──────────────────────────────────────────────────────┐
│                     User                              │
│  Platform: test_user/test123 (our platform)          │
│  H3Africa: personal API token (their account)        │
└──────────────┬───────────────────────────────────────┘
               │
               │ 1. Login to platform
               ↓
┌──────────────────────────────────────────────────────┐
│         User Service (Port 8001)                      │
│   ✓ Returns Platform JWT                              │
└──────────────┬───────────────────────────────────────┘
               │
               │ 2. Configure H3Africa credentials
               ↓
┌──────────────────────────────────────────────────────┐
│    POST /users/me/service-credentials                 │
│   ✓ User provides their H3Africa API token            │
│   ✓ Stored securely per user                          │
└──────────────┬───────────────────────────────────────┘
               │
               │ 3. Submit job
               ↓
┌──────────────────────────────────────────────────────┐
│         Job Processor (Port 8003)                     │
│   ✓ Validates JWT                                     │
│   ✓ Checks user has H3Africa credentials ✅           │
│   ✓ Creates job if valid                              │
└──────────────┬───────────────────────────────────────┘
               │
               │ 4. Worker fetches USER's credentials
               ↓
┌──────────────────────────────────────────────────────┐
│            Celery Worker                              │
│   1. Gets USER's H3Africa token ✅                    │
│   2. Submits with USER's credentials ✅               │
└──────────────┬───────────────────────────────────────┘
               │
               │ 5. Submit with user's token
               ↓
┌──────────────────────────────────────────────────────┐
│         H3Africa (USER's Account)                     │
│   Header: X-Auth-Token: <USER's_Token> ✅             │
│   ✓ Charges USER's H3Africa account ✅                │
│   ✓ Tracks USER's quota ✅                            │
└──────────────────────────────────────────────────────┘
```

**Key Insight:** Each user manages their own H3Africa credentials. Jobs run under each user's H3Africa account with proper resource tracking.

---

## Manual Job Submission

### Prerequisites
1. ✅ H3Africa account at https://impute.afrigen-d.org/
2. ✅ H3Africa API token generated
3. ✅ Platform account created

### 1. Get Authentication Token (Platform JWT)

```bash
# Authenticate to OUR platform
TOKEN=$(curl -s -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test_user","password":"test123"}' \
  | jq -r '.access_token')

echo "Token: $TOKEN"
```

### 2. Configure H3Africa Credentials

```bash
# Add your H3Africa API token
curl -X POST http://localhost:8001/users/me/service-credentials \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "service_id": 1,
    "credential_type": "api_token",
    "api_token": "YOUR_H3AFRICA_API_TOKEN_HERE",
    "label": "My H3Africa Account"
  }'

# Verify credentials configured
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8001/users/me/service-credentials
```

### 2. Submit Job

**You can use either numeric IDs or human-readable slugs:**

```bash
# Option A: Using numeric IDs (traditional)
JOB_ID=$(curl -s -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=My First H3Africa Job" \
  -F "description=Testing imputation" \
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

```bash
# Option B: Using slugs (more user-friendly! ✨)
JOB_ID=$(curl -s -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=My First H3Africa Job" \
  -F "description=Testing imputation" \
  -F "service_id=h3africa-ilifu" \
  -F "reference_panel_id=h3africa-v6" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "phasing=true" \
  -F "population=AFR" \
  -F "input_file=@$HOME/test_data/test_small_1000var.vcf.gz" \
  | jq -r '.id')

echo "Job ID: $JOB_ID"
```

**Available Service Slugs:**
- `h3africa-ilifu` - H3Africa Imputation Server
- `michigan-imputation-server` - Michigan Imputation Server
- `topmed-imputation-server` - TOPMed Imputation Server

**Available Reference Panel Slugs:**
- `h3africa-v6` - H3Africa Reference Panel v6
- `caapa` - CAAPA Reference Panel
- `topmed-r2` - TOPMed Reference Panel R2

### 3. Monitor Status

```bash
# One-time check
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs/$JOB_ID | jq '{status, progress_percentage}'

# Auto-refresh (updates every 10 seconds)
watch -n 10 "curl -s -H 'Authorization: Bearer $TOKEN' \
  http://localhost:8003/jobs/$JOB_ID | jq '{status, progress_percentage, external_job_id}'"
```

### 4. Download Results (when status = completed)

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs/$JOB_ID/results \
  -o results.zip

# Extract and view
unzip -l results.zip
```

---

## API Endpoints Reference

### Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/jobs` | Create new job with file upload |
| GET | `/jobs` | List all jobs (with filters) |
| GET | `/jobs/{id}` | Get job status and details |
| GET | `/jobs/{id}/status-updates` | Get status history |
| GET | `/jobs/{id}/results` | Download results |
| POST | `/jobs/{id}/cancel` | Cancel running job |

### Example: List All Jobs

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs | jq '.[] | {id, name, status, progress_percentage}'
```

### Example: Filter by Status

```bash
# Only completed jobs
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs?status=completed | jq '.'

# Only running jobs
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs?status=running | jq '.'
```

---

## Monitoring & Debugging

### View Job Processor Logs

```bash
# Real-time logs
docker logs -f job-processor

# Last 100 lines
docker logs job-processor --tail 100

# Filter for specific job
docker logs job-processor | grep "550e8400-e29b-41d4-a716-446655440000"
```

### Check Service Health

```bash
# Job Processor
curl http://localhost:8003/health | jq '.'

# Service Registry
curl http://localhost:8002/health | jq '.'

# H3Africa Service Status
curl http://localhost:8002/services/1 | jq '{name, health_status, response_time_ms}'
```

### Common Issues

**Job stuck in "pending":**
```bash
# Check Celery worker
docker logs job-processor | grep -i celery

# Restart if needed
docker-compose restart job-processor
```

**Authentication error:**
```bash
# Verify API token
curl http://localhost:8002/services/1 | jq '.api_config.api_token'

# Re-run setup with new token
python scripts/setup_h3africa_service.py --api-token NEW_TOKEN
```

**Results not available:**
```bash
# Check file manager
docker logs file-manager | grep -i upload

# Verify job completed
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8003/jobs/$JOB_ID | jq '{status, results_file_id}'
```

---

## Next Steps

### 1. Production Setup

- [ ] Configure SMTP for email notifications
- [ ] Set up S3/cloud storage for files
- [ ] Enable SSL/TLS certificates
- [ ] Configure rate limiting

See: [docs/ROADMAP_UPDATED_2025.md](ROADMAP_UPDATED_2025.md)

### 2. Add More Services

- [ ] Michigan Imputation Server (https://imputationserver.sph.umich.edu/)
- [ ] ILIFU GA4GH (http://ga4gh-starter-kit.ilifu.ac.za:6000)
- [ ] Custom imputation services

### 3. Advanced Features

- [ ] Implement job templates
- [ ] Add workflow orchestration
- [ ] Create AI service recommendations
- [ ] Build analytics dashboard

---

## Documentation

- **Complete Integration Guide**: [H3AFRICA_JOB_EXECUTION.md](H3AFRICA_JOB_EXECUTION.md)
- **Roadmap**: [ROADMAP_UPDATED_2025.md](ROADMAP_UPDATED_2025.md)
- **Architecture**: [ARCHITECTURE_STATUS.md](ARCHITECTURE_STATUS.md)

---

## Support

**Issues?** Check the logs:
```bash
# All services
docker-compose logs

# Specific service
docker logs job-processor
docker logs file-manager
docker logs notification
```

**Still stuck?**
- Review documentation: [docs/](.)
- Check GitHub issues
- Contact H3Africa support: https://impute.afrigen-d.org/support

---

**Last Updated**: October 4, 2025
**Version**: 1.0
