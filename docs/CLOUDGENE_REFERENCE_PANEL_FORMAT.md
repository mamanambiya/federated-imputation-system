# Cloudgene Reference Panel Format

## Overview

Michigan Imputation Server and derived platforms (like H3Africa Imputation Server at Afrigen) use the **Cloudgene** workflow framework. This document explains the critical reference panel naming convention required for successful job submission.

## The Problem

During testing, all API job submissions were failing validation with no execution steps, while web interface submissions succeeded. The root cause was **incorrect reference panel parameter format**.

### What Didn't Work ❌

```python
# WRONG - Using database IDs or incorrect format
data = {
    'refpanel': '1',  # Database ID
    'refpanel': 'h3africa',  # Simple name
    'refpanel': 'apps@imputationserver2@resources@v6hc-s-b38',  # Wrong Cloudgene format
}
```

### What Works ✅

```python
# CORRECT - Cloudgene application reference format
data = {
    'refpanel': 'apps@h3africa-v6hc-s@1.0.0',  # Proper Cloudgene format
}
```

## Cloudgene Application Reference Format

### Format Specification

```
apps@{app-id}@{version}
```

**Components:**
- `apps@` - Fixed prefix indicating Cloudgene application
- `{app-id}` - Application identifier from Cloudgene YAML config
- `{version}` - Application version (typically semantic versioning)

### Real-World Examples

| Reference Panel | Cloudgene Format | Description |
|----------------|------------------|-------------|
| H3Africa v6 | `apps@h3africa-v6hc-s@1.0.0` | African populations panel |
| 1000 Genomes Phase 3 | `apps@1000g-phase-3-v5@1.0.0` | All populations, Phase 3 |
| HapMap 2 | `apps@hapmap-2@1.0.0` | HapMap Phase 2 reference |
| TOPMed r2 | `apps@topmed-r2@1.0.0` | TOPMed freeze 8 reference |

## Implementation in Platform

### 1. Database Model

The `ReferencePanel` model stores the Cloudgene format in the `name` field:

```python
# imputation/models.py
class ReferencePanel(models.Model):
    service = models.ForeignKey(ImputationService, on_delete=models.CASCADE)
    name = models.CharField(max_length=200)  # Must contain Cloudgene format!
    panel_id = models.CharField(max_length=100)  # Service-specific panel ID
    # ... other fields
```

**Critical:** For Michigan/Cloudgene services, the `name` field must contain the full Cloudgene format (`apps@{app-id}@{version}`), not a human-readable name.

### 2. Job Processor Worker

The worker fetches panel details and uses the `name` field for Michigan API submissions:

```python
# microservices/job-processor/worker.py
async with httpx.AsyncClient() as panel_client:
    panel_response = await panel_client.get(
        f"{SERVICE_REGISTRY_URL}/panels/{job_data['reference_panel']}"
    )
    panel_info = panel_response.json()

panel_identifier = panel_info.get('name')  # Cloudgene format

data = {
    'refpanel': panel_identifier,  # apps@h3africa-v6hc-s@1.0.0
    'build': job_data['build'],
    'phasing': 'eagle',
    # ... other parameters
}
```

### 3. Service Setup Script

When creating H3Africa service panels, use the correct format:

```python
# scripts/setup_h3africa_service.py
panels = [
    {
        "service_id": service_id,
        "name": "apps@h3africa-v6hc-s@1.0.0",  # REQUIRED format
        "display_name": "H3Africa Reference Panel (v6)",
        "description": "African populations reference panel",
        "population": "AFR",
        "build": "hg38",
        "is_available": True
    }
]
```

## How to Find Cloudgene App IDs

### Method 1: Inspect Successful Web Submissions

1. Submit job through web interface: https://impute.afrigen-d.org/
2. View job details after submission
3. Look for "Reference Panel" field in job summary
4. Copy the exact format (e.g., `apps@h3africa-v6hc-s@1.0.0`)

### Method 2: Check Cloudgene Application YAML

Cloudgene applications are defined in YAML files. Example:

```yaml
# cloudgene.yaml
id: h3africa-v6hc-s
version: 1.0.0
name: H3Africa v6 High Coverage Reference Panel
description: African-specific imputation panel

# Reference format becomes: apps@h3africa-v6hc-s@1.0.0
```

### Method 3: API Endpoint (if available)

Some Cloudgene servers expose application listings:

```bash
curl https://impute.afrigen-d.org/api/v2/server/applications
```

## Validation Results

After implementing the correct format, job submissions succeeded:

```json
{
  "job_id": "job-20251005-162345-508",
  "status": "SUCCESS",
  "quality_metrics": {
    "reference_overlap": "94.84%",
    "execution_time": "5m 16s"
  },
  "pipeline_steps": {
    "validation": "PASSED",
    "qc": "PASSED",
    "phasing": "COMPLETED (4/4 chunks)",
    "imputation": "COMPLETED (4/4 chunks)",
    "export": "COMPLETED"
  }
}
```

## Best Practices

### ✅ DO

- **Always use the Cloudgene `apps@` format** for Michigan/Cloudgene services
- **Verify format** by testing with web interface first
- **Document panel formats** when adding new reference panels
- **Use `display_name` field** for human-readable panel names
- **Store Cloudgene format in `name` field** for programmatic access

### ❌ DON'T

- Don't use database IDs as reference panel parameters
- Don't use simple names like "h3africa" without the `apps@` prefix
- Don't guess the format - verify with successful web submissions
- Don't mix up `panel_id` and `name` fields

## Service-Specific Formats

### Michigan Imputation Server (imputationserver.sph.umich.edu)

Uses Cloudgene format:
```
apps@{app-id}@{version}
```

### H3Africa Imputation Server (impute.afrigen-d.org)

Uses Cloudgene format (Michigan fork):
```
apps@h3africa-v6hc-s@1.0.0
```

### TOPMed Imputation Server

Uses Cloudgene format:
```
apps@topmed-r2@1.0.0
```

### GA4GH WES Services

May use different formats. Check service documentation:
```python
# GA4GH typically uses workflow IDs
workflow_params = {
    'reference_panel': 'panel_uuid_or_identifier',
    # Format varies by implementation
}
```

## Troubleshooting

### Problem: Job fails immediately without running

**Symptom:**
```json
{
  "status": "failed",
  "error": "Invalid reference panel"
}
```

**Solution:** Check that `refpanel` parameter uses Cloudgene `apps@` format.

### Problem: Reference panel not found

**Symptom:**
```json
{
  "status": "failed",
  "error": "Reference panel 'apps@xyz@1.0.0' not available"
}
```

**Solution:**
1. Verify panel is available on the server
2. Check for typos in app-id or version
3. Confirm panel supports your genome build (hg19/hg38)

### Problem: Database has wrong panel names

**Symptom:** Panel names like "h3africa" or "1000g" without `apps@` prefix

**Solution:**
1. Update panel names in database:
```sql
UPDATE reference_panels
SET name = 'apps@h3africa-v6hc-s@1.0.0'
WHERE name = 'h3africa';
```

2. Or re-run setup script:
```bash
python scripts/setup_h3africa_service.py --api-token YOUR_TOKEN
```

## Testing Checklist

When adding new Michigan/Cloudgene reference panels:

- [ ] Verify Cloudgene format from web interface
- [ ] Update `name` field with `apps@{app-id}@{version}`
- [ ] Set `display_name` for UI presentation
- [ ] Test job submission via API
- [ ] Verify job passes validation phase
- [ ] Confirm job executes successfully
- [ ] Check quality metrics (reference overlap > 90%)

## Related Documentation

- [PRODUCTION_JOB_SUCCESS.md](PRODUCTION_JOB_SUCCESS.md) - Successful job execution details
- [AFRIGEN_API_INTEGRATION_RESULTS.md](AFRIGEN_API_INTEGRATION_RESULTS.md) - API testing results
- [H3AFRICA_JOB_EXECUTION.md](H3AFRICA_JOB_EXECUTION.md) - H3Africa-specific job execution guide

## References

- Michigan Imputation Server: https://imputationserver.sph.umich.edu/
- Cloudgene Framework: https://cloudgene.io/
- H3Africa Consortium: https://h3africa.org/
- Afrigen Imputation Server: https://impute.afrigen-d.org/

---

**Last Updated:** 2025-10-05
**Status:** Production-validated ✅
