# Michigan Imputation Server API - Job Submission Template

**Last Updated**: October 7, 2025
**API Version**: v2
**Service Type**: Cloudgene-based (Michigan Imputation Server, H3Africa)

## Overview

The Michigan Imputation Server uses a Cloudgene-based API that requires multipart/form-data submission with user-specific authentication tokens.

## Authentication

### User API Token Required

- **Header**: `X-Auth-Token`
- **Value**: User's personal Michigan/H3Africa API token
- **Obtained from**: User must configure in Settings → Service Credentials
- **Critical**: Jobs will fail without valid user token

```http
X-Auth-Token: {user_api_token}
```

## API Endpoint

### Job Submission

```
POST {base_url}/api/v2/jobs/submit/imputationserver2
```

**Examples:**

- H3Africa: `https://impute.afrigen-d.org/api/v2/jobs/submit/imputationserver2`
- Michigan: `https://imputationserver.sph.umich.edu/api/v2/jobs/submit/imputationserver2`

## Request Format

### Content-Type

```
multipart/form-data
```

### Form Fields

| Field | Type | Required | Description | Example Values |
|-------|------|----------|-------------|----------------|
| `files` | File | ✅ Yes | VCF file (gzipped) | `input.vcf.gz` |
| `refpanel` | String | ✅ Yes | Reference panel Cloudgene app ID | `apps@h3africa-v6hc-s@1.0.0` |
| `build` | String | ✅ Yes | Genome build | `hg19`, `hg38` |
| `phasing` | String | ✅ Yes | Phasing method | `eagle`, `no_phasing` |
| `population` | String | ✅ Yes | Population for phasing | `mixed`, `eur`, `afr`, `amr`, `eas`, `sas` |
| `mode` | String | ✅ Yes | Imputation mode | `imputation` |

## Field Details

### 1. files

**Purpose**: VCF input file containing genotype data

**Format**:

- File extension: `.vcf.gz` (gzipped VCF)
- MIME type: `application/gzip`
- Filename: Any valid name (e.g., `input.vcf.gz`)

**Code Example:**

```python
files = {
    'files': ('input.vcf.gz', file_content, 'application/gzip')
}
```

### 2. refpanel

**Purpose**: Specifies which reference panel to use for imputation

**Format**: Cloudgene app ID

- Pattern: `apps@{panel-name}@{version}`
- Must match exactly what the service expects

**Valid Values:**

#### H3Africa Panels

```yaml
H3AFRICA v6:
  refpanel: "apps@h3africa-v6hc-s@1.0.0"
  description: "African-specific, 4,447 samples, 130M variants"
  best_for: "African populations"
```

#### Michigan Panels (examples)

```yaml
1000 Genomes Phase 3 v5:
  refpanel: "1000g-phase3-v5"
  description: "Multi-ethnic, 2,504 samples, 81M variants"
  best_for: "Global populations, chr X"

HRC r1.1 2016:
  refpanel: "hrc-r1.1-2016"
  description: "Haplotype Reference Consortium"
  best_for: "European populations"

CAAPA:
  refpanel: "caapa"
  description: "African American panel"
  best_for: "African American studies"
```

**Critical Note**: The panel identifier MUST match the service's Cloudgene configuration. Use the `slug` field from the reference_panels table.

### 3. build

**Purpose**: Genome assembly version

**Valid Values:**

- `hg19` - GRCh37 (older)
- `hg38` - GRCh38 (current, recommended)

**Selection Criteria:**

- Use the same build as your input VCF file
- Most modern datasets use `hg38`
- Mismatched builds will cause imputation errors

### 4. phasing

**Purpose**: Pre-imputation phasing method

**Valid Values:**

- `eagle` - Perform phasing using Eagle algorithm (recommended)
- `no_phasing` - Skip phasing (use if data is already phased)

**Mapping from Boolean:**

```python
phasing_value = 'eagle' if job_data.get('phasing', True) else 'no_phasing'
```

**Recommendation**: Use `eagle` unless your VCF is already phased and you're certain of phase quality.

### 5. population

**Purpose**: Population ancestry for phasing algorithm optimization

**Valid Values:**

| Code | Population | Description |
|------|------------|-------------|
| `mixed` | Mixed/Unknown | **Default** - Use when uncertain |
| `eur` | European | European ancestry |
| `afr` | African | African ancestry |
| `amr` | American | Admixed American (Latino/Hispanic) |
| `eas` | East Asian | East Asian ancestry |
| `sas` | South Asian | South Asian ancestry |

**Default Behavior:**

```python
population = job_data.get('population') or 'mixed'  # Never send null/empty
```

**Critical**: Never send `null` or empty string - defaults to `'mixed'` to prevent API errors.

### 6. mode

**Purpose**: Job type selection

**Valid Values:**

- `imputation` - Standard imputation (most common)
- `qconly` - Quality control only (no imputation)
- `phasing` - Phasing only (no imputation)

**Standard Use**: Always use `imputation` for full imputation pipeline.

## Complete Code Example

### Python Implementation (from worker.py lines 105-151)

```python
async def submit_michigan_job(service_info, job_data, user_api_token):
    """Submit job to Michigan/H3Africa Imputation Server."""

    # 1. API Endpoint
    base_url = service_info['base_url'].rstrip('/')
    submit_url = f"{base_url}/api/v2/jobs/submit/imputationserver2"

    # 2. Download input file
    file_response = await httpx_client.get(job_data['input_file_url'])
    file_content = file_response.content

    # 3. Get reference panel Cloudgene ID
    panel_response = await httpx_client.get(
        f"{SERVICE_REGISTRY_URL}/panels/{job_data['reference_panel']}"
    )
    panel_info = panel_response.json()
    panel_identifier = panel_info.get('slug')  # e.g., "apps@h3africa-v6hc-s@1.0.0"

    # 4. Prepare multipart form data
    files = {
        'files': ('input.vcf.gz', file_content, 'application/gzip')
    }

    data = {
        'refpanel': panel_identifier,
        'build': job_data['build'],  # 'hg19' or 'hg38'
        'phasing': 'eagle' if job_data.get('phasing', True) else 'no_phasing',
        'population': job_data.get('population') or 'mixed',
        'mode': 'imputation'
    }

    # 5. Authentication header
    headers = {
        'X-Auth-Token': user_api_token
    }

    # 6. Submit job
    response = await httpx_client.post(
        submit_url,
        files=files,
        data=data,
        headers=headers,
        timeout=httpx.Timeout(connect=60.0, read=300.0, write=60.0, pool=30.0)
    )
    response.raise_for_status()

    # 7. Extract job ID from response
    result = response.json()
    external_job_id = result.get('id') or result.get('jobId')

    return {
        'external_job_id': external_job_id,
        'status': 'submitted',
        'service_response': result
    }
```

### cURL Example

```bash
curl -X POST "https://impute.afrigen-d.org/api/v2/jobs/submit/imputationserver2" \
  -H "X-Auth-Token: YOUR_API_TOKEN_HERE" \
  -F "files=@/path/to/input.vcf.gz" \
  -F "refpanel=apps@h3africa-v6hc-s@1.0.0" \
  -F "build=hg38" \
  -F "phasing=eagle" \
  -F "population=afr" \
  -F "mode=imputation"
```

## Response Format

### Successful Submission

```json
{
  "id": "job-20251007-abc123",
  "message": "Job submitted successfully",
  "success": true
}
```

### Error Response

```json
{
  "success": false,
  "message": "Invalid reference panel",
  "error": "Panel 'invalid-panel' not found"
}
```

## Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Job submitted | Track with job ID |
| 401 | Invalid/missing token | User needs to add API token in Settings |
| 400 | Invalid parameters | Check refpanel, build, population values |
| 413 | File too large | Split VCF or use smaller regions |
| 500 | Server error | Retry or contact service admin |

## Job Status Checking

### Endpoint

```
GET {base_url}/api/v2/jobs/{job_id}
```

### Authentication

Same `X-Auth-Token` header required for status checks.

### Response Structure

```json
{
  "id": "job-20251007-abc123",
  "state": 2,
  "positionInQueue": 0,
  "steps": [
    {
      "name": "Input Validation",
      "logMessages": [
        {
          "type": 1,
          "message": "Processing chromosome 22",
          "time": 1696723890000
        }
      ]
    }
  ]
}
```

### State Codes

| Code | Status | Internal Mapping | Progress |
|------|--------|------------------|----------|
| 1 | Waiting | `queued` | 5% |
| 2 | Running | `running` | 10-90% |
| 3 | Success (exportable) | `completed` | 100% |
| 4 | Success (complete) | `completed` | 100% |
| 5 | Failed | `failed` | Variable |
| 6 | Cancelled | `cancelled` | Variable |
| 7 | Deleted | `cancelled` | Variable |

## Common Errors and Solutions

### Error: "No credentials configured"

**Cause**: User hasn't added their Michigan API token
**Solution**: User must go to Settings → Service Credentials and add their token

### Error: "Invalid reference panel"

**Cause**: Wrong panel identifier format or panel doesn't exist
**Solution**: Use exact Cloudgene app ID from service (e.g., `apps@h3africa-v6hc-s@1.0.0`)

### Error: "Population parameter required"

**Cause**: Sending `null` or empty string for population
**Solution**: Always default to `'mixed'` if not specified

### Error: HTTP 401 on status check

**Cause**: Missing or expired API token
**Solution**: Ensure `X-Auth-Token` header is included in ALL requests

## Reference Panel Configuration

### Database Schema

```sql
-- reference_panels table
CREATE TABLE reference_panels (
    id SERIAL PRIMARY KEY,
    service_id INTEGER REFERENCES imputation_services(id),
    name VARCHAR(255),           -- Display name: "H3AFRICA v6"
    slug VARCHAR(255) UNIQUE,    -- Cloudgene ID: "apps@h3africa-v6hc-s@1.0.0"
    display_name VARCHAR(255),
    population VARCHAR(100),
    build VARCHAR(10),
    samples_count INTEGER,
    variants_count BIGINT,
    -- ... other fields
);
```

### Critical Field: `slug`

The `slug` field MUST contain the exact Cloudgene app identifier:

- ✅ Correct: `apps@h3africa-v6hc-s@1.0.0`
- ❌ Wrong: `h3africa-v6` (human-readable name)
- ❌ Wrong: `apps/h3africa/v6` (wrong separator)

## Testing

### Test Submission Script

Location: [scripts/test_michigan_submission.py](../../scripts/test_michigan_submission.py)

```bash
# Test job submission
python scripts/test_michigan_submission.py \
  --service-url "https://impute.afrigen-d.org" \
  --api-token "YOUR_TOKEN" \
  --vcf-file "sample_data/test.vcf.gz" \
  --panel "apps@h3africa-v6hc-s@1.0.0" \
  --build "hg38"
```

## Best Practices

1. **Always validate user has credentials** before job submission
2. **Use exact panel slug** from database - never hard-code panel IDs
3. **Default population to 'mixed'** to avoid API errors
4. **Include timeout handling** - file uploads can take 5+ minutes
5. **Log all submission parameters** for debugging failed jobs
6. **Store external_job_id** immediately after successful submission
7. **Check status with authentication** - Michigan requires tokens for all endpoints

## Related Documentation

- [JOBS_NOW_WORKING.md](../../JOBS_NOW_WORKING.md) - Job submission verification
- [JOB_SUBMISSION_FIX.md](../../JOB_SUBMISSION_FIX.md) - Population parameter fix
- [H3AFRICA_PANELS_UPDATE.md](../../H3AFRICA_PANELS_UPDATE.md) - Reference panel configuration
- [worker.py](../../microservices/job-processor/worker.py) - Full implementation

---

**Implementation Reference**: Lines 59-182 in [microservices/job-processor/worker.py](../../microservices/job-processor/worker.py:59-182)
