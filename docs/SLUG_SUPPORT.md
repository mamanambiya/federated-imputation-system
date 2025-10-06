# Slug Support - Human-Readable Identifiers

**Status**: ✅ Implemented
**Version**: 2.1
**Date**: October 4, 2025

---

## Overview

The Federated Genomic Imputation Platform now supports **human-readable slugs** as an alternative to numeric IDs for services and reference panels. This makes the API more user-friendly and self-documenting.

### What are Slugs?

Slugs are URL-safe, human-readable identifiers that describe what they represent:

**Before (numeric IDs only):**
```bash
service_id=1
reference_panel_id=3
```

**After (slugs supported):**
```bash
service_id=h3africa-ilifu
reference_panel_id=h3africa-v6
```

---

## Benefits

### 1. **Self-Documenting Code**
```bash
# Clear what service is being used
-F "service_id=h3africa-ilifu"

# vs unclear numeric ID
-F "service_id=1"
```

### 2. **Easier to Remember**
- `michigan-imputation-server` is easier to remember than "ID 2"
- `h3africa-v6` clearly indicates the panel version

### 3. **Migration-Friendly**
- Numeric IDs can change when databases are rebuilt
- Slugs remain constant across environments

### 4. **Better Error Messages**
```bash
# Clear error message
Error: Service 'h3africa-ilifu' not found

# vs generic error
Error: Service with ID 1 not found
```

---

## Implementation

### Database Schema

**Services Table:**
```sql
imputation_services
├── id (integer, primary key)
├── name (string)
├── slug (string, unique, indexed)  ← New field
├── service_type (string)
└── ...
```

**Reference Panels Table:**
```sql
reference_panels
├── id (integer, primary key)
├── name (string)
├── slug (string, unique, indexed)  ← New field
├── service_id (integer)
└── ...
```

### Slug Generation Rules

Slugs are automatically generated from names if not provided:

| Name | Generated Slug |
|------|----------------|
| `H3Africa ILIFU` | `h3africa-ilifu` |
| `Michigan Imputation Server` | `michigan-imputation-server` |
| `H3Africa v6` | `h3africa-v6` |
| `TOPMed R2` | `topmed-r2` |

**Rules:**
1. Convert to lowercase
2. Replace spaces/underscores with hyphens
3. Remove non-alphanumeric characters (except hyphens)
4. Remove consecutive hyphens
5. Trim leading/trailing hyphens

---

## API Usage

### Creating a Service with Custom Slug

```bash
curl -X POST http://localhost:8002/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "H3Africa ILIFU",
    "slug": "h3africa-ilifu",  ← Custom slug
    "service_type": "h3africa",
    "api_type": "michigan",
    "base_url": "https://impute.afrigen-d.org/api/v2"
  }'
```

### Creating a Service with Auto-Generated Slug

```bash
curl -X POST http://localhost:8002/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Michigan Imputation Server",
    # slug will be auto-generated as "michigan-imputation-server"
    "service_type": "michigan",
    "api_type": "michigan",
    "base_url": "https://imputationserver.sph.umich.edu/api/v2"
  }'
```

### Querying Services by Slug

```bash
# Get service by numeric ID
curl http://localhost:8002/services/1

# Get service by slug ✨
curl http://localhost:8002/services/h3africa-ilifu
```

### Submitting Jobs with Slugs

```bash
# Using numeric IDs (still supported)
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "service_id=1" \
  -F "reference_panel_id=3" \
  -F "input_file=@test.vcf.gz"

# Using slugs (new! ✨)
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "service_id=h3africa-ilifu" \
  -F "reference_panel_id=h3africa-v6" \
  -F "input_file=@test.vcf.gz"
```

---

## Backward Compatibility

✅ **Fully backward compatible** - numeric IDs still work everywhere:

```bash
# All of these work:
service_id=1                    # Numeric ID
service_id="1"                  # Numeric ID as string
service_id=h3africa-ilifu       # Slug
```

The system automatically detects whether an identifier is:
- Numeric → Lookup by ID
- Non-numeric → Lookup by slug

---

## Common Service Slugs

### Imputation Services

| Service Name | Slug | Service Type |
|--------------|------|--------------|
| H3Africa ILIFU | `h3africa-ilifu` | h3africa |
| Michigan Imputation Server | `michigan-imputation-server` | michigan |
| TOPMed Imputation Server | `topmed-imputation-server` | topmed |

### Reference Panels

| Panel Name | Slug | Population |
|------------|------|------------|
| H3Africa Reference Panel v6 | `h3africa-v6` | AFR |
| CAAPA | `caapa` | AFR/AMR |
| TOPMed Reference Panel R2 | `topmed-r2` | Multi |
| 1000 Genomes Phase 3 | `1000g-phase3` | Multi |

---

## Error Handling

### Service Not Found

```bash
$ curl http://localhost:8002/services/invalid-slug
{
  "detail": "Service 'invalid-slug' not found. Please check the service ID or slug."
}
```

### Duplicate Slug

```bash
$ curl -X POST http://localhost:8002/services \
  -d '{"name": "Test", "slug": "h3africa-ilifu", ...}'
{
  "detail": "Service with slug 'h3africa-ilifu' already exists"
}
```

---

## Migration Guide

### For Existing Databases

If you have existing services without slugs, run this migration:

```sql
-- Auto-generate slugs for existing services
UPDATE imputation_services
SET slug = lower(
  regexp_replace(
    regexp_replace(name, '[^a-zA-Z0-9\\s-]', '', 'g'),
    '[\\s_]+', '-', 'g'
  )
)
WHERE slug IS NULL;

-- Auto-generate slugs for existing reference panels
UPDATE reference_panels
SET slug = lower(
  regexp_replace(
    regexp_replace(name, '[^a-zA-Z0-9\\s-]', '', 'g'),
    '[\\s_]+', '-', 'g'
  )
)
WHERE slug IS NULL;
```

### For Frontend Applications

**Option 1: Use Slugs Everywhere (Recommended)**
```javascript
// Before
const serviceId = 1;

// After
const serviceId = 'h3africa-ilifu';
```

**Option 2: Support Both**
```javascript
function submitJob(serviceIdentifier) {
  // Works with both numeric ID or slug
  const response = await fetch(`/api/jobs`, {
    method: 'POST',
    body: formData.append('service_id', serviceIdentifier)
  });
}
```

---

## Best Practices

### 1. **Use Slugs in Documentation**
```bash
# ✅ Good - Clear what service is used
service_id=h3africa-ilifu

# ❌ Less clear - Requires looking up what ID 1 is
service_id=1
```

### 2. **Use Short, Descriptive Slugs**
```bash
# ✅ Good slugs
h3africa-ilifu
michigan-imputation-server
topmed-r2

# ❌ Too long
h3africa-imputation-server-hosted-by-ilifu-cape-town

# ❌ Too cryptic
h3a-imp-srv
```

### 3. **Include Version in Panel Slugs**
```bash
# ✅ Good - Version is clear
h3africa-v6
topmed-r2

# ❌ Missing version
h3africa
topmed
```

### 4. **Maintain Consistency**
```bash
# ✅ Consistent naming pattern
h3africa-v6
h3africa-v7
h3africa-v8

# ❌ Inconsistent
h3africa-version-6
h3africa-v7
h3africa_8
```

---

## API Endpoints Summary

### Services

| Endpoint | ID Support | Slug Support |
|----------|------------|--------------|
| `POST /services` | Create with auto-generated or custom slug | ✅ |
| `GET /services` | Returns all services with slugs | ✅ |
| `GET /services/{identifier}` | ✅ Numeric ID | ✅ Slug |
| `PATCH /services/{identifier}` | ✅ Numeric ID | ✅ Slug |
| `DELETE /services/{identifier}` | ✅ Numeric ID | ✅ Slug |

### Reference Panels

| Endpoint | ID Support | Slug Support |
|----------|------------|--------------|
| `GET /reference-panels` | Returns all panels with slugs | ✅ |
| Job submission | ✅ Numeric ID | ✅ Slug |

### Jobs

| Parameter | Numeric ID | Slug |
|-----------|------------|------|
| `service_id` | ✅ | ✅ |
| `reference_panel_id` | ✅ | ✅ |

---

## Technical Details

### Slug Resolution Logic

```python
def get_service_by_id_or_slug(db: Session, identifier: str):
    """
    Lookup service by either numeric ID or slug.
    Supports both: service_id=1 and service_id='h3africa-ilifu'
    """
    # Try numeric ID first
    if identifier.isdigit():
        return db.query(ImputationService).filter(
            ImputationService.id == int(identifier)
        ).first()

    # Otherwise, lookup by slug
    return db.query(ImputationService).filter(
        ImputationService.slug == identifier
    ).first()
```

### Performance

- **Indexed Fields**: Both `id` and `slug` columns are indexed
- **Query Performance**: No performance difference between ID and slug lookups
- **Database Impact**: Minimal - adds one indexed string column per table

---

## Summary

✅ **Implemented**: Full slug support for services and reference panels
✅ **Backward Compatible**: Numeric IDs still work everywhere
✅ **Auto-Generated**: Slugs created automatically if not provided
✅ **User-Friendly**: More readable and self-documenting
✅ **Production Ready**: Tested and deployed

**Example Usage:**
```bash
# Old way (still works)
curl -F "service_id=1" -F "reference_panel_id=3" ...

# New way (more readable)
curl -F "service_id=h3africa-ilifu" -F "reference_panel_id=h3africa-v6" ...
```

Both approaches are fully supported! 🎉
