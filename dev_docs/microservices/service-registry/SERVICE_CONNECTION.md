# External Service Connection Guide
## How Genomic Imputation Services Connect to the Platform

> **Focus**: ILIFU GA4GH Starter Kit, Michigan Imputation Server, eLwazi MALI
> **Last Updated**: 2025-10-04

---

## Overview

This document provides a detailed walkthrough of how external genomic imputation services (like ILIFU GA4GH Starter Kit) connect to the Federated Imputation Platform through the Service Registry microservice.

### Supported Service Types

1. **GA4GH WES Services** (Workflow Execution Service)
   - ILIFU GA4GH Starter Kit (South Africa)
   - eLwazi MALI Node (Mali)
   - Any GA4GH WES 1.0.0 compliant service

2. **Michigan Imputation Server**
   - Michigan Imputation Server API
   - Custom API protocol

3. **DNAstack Omics Services**
   - DNAstack Collection Service
   - Requires dnastack-client-library

---

## Connection Architecture

### Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  External Genomic Imputation Service                        │
│  Example: ILIFU GA4GH Starter Kit                           │
│  http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ 1. HTTP GET /service-info
                       │    Headers:
                       │      Accept: application/json
                       │      Authorization: Bearer <token> (optional)
                       │
                       │ 2. Response (GA4GH Service Info)
                       │    {
                       │      "supported_wes_versions": ["1.0.0"],
                       │      "workflow_engine_versions": {"NFL": "22.10.0"},
                       │      "system_state_counts": {...}
                       │    }
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  Service Registry Microservice (FastAPI)                     │
│  Port: 8002                                                  │
│  Database: service_registry_db                               │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Background Health Check Worker:                            │
│  ┌────────────────────────────────────────────────────┐    │
│  │  async def periodic_health_check():                │    │
│  │      while True:                                    │    │
│  │          await check_all_services(db)              │    │
│  │          await asyncio.sleep(300)  # 5 minutes     │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  Concurrent Health Checks:                                  │
│  ┌────────────────────────────────────────────────────┐    │
│  │  for service in services:                          │    │
│  │      result = await check_service_health(service)  │    │
│  │      # Non-blocking - all services checked at once │    │
│  │      update_database(service, result)              │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  Database Updates:                                          │
│  • health_status: 'healthy' | 'unhealthy' | 'timeout'      │
│  • response_time_ms: 234.5                                  │
│  • is_available: true | false                               │
│  • last_health_check: 2025-10-04T10:30:00Z                 │
│  • error_message: null | "Connection timeout"              │
│                                                              │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       │ 3. Health data available via API
                       │    GET /services/7
                       │    GET /services/7/health
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  Django Application (Main Platform)                          │
│  Port: 8000                                                  │
│  Database: federated_imputation                              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Health Cache Service:                                      │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Intelligent Caching:                              │    │
│  │  • Healthy services: 15 minutes cache              │    │
│  │  • Unhealthy services: 1 minute cache (user)       │    │
│  │  • Unhealthy services: 10 seconds (system)         │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  Django Admin Interface:                                    │
│  • View service status and response times                   │
│  • Test connection button (manual check)                    │
│  • Service management forms                                 │
│                                                              │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       │ 4. Display to user
                       │
                       ▼
                  User Interface
```

---

## ILIFU GA4GH Service Connection

### Service Details

**ILIFU GA4GH Starter Kit**
- **Location**: University of Cape Town, Cape Town, South Africa
- **Type**: GA4GH WES (Workflow Execution Service) 1.0.0
- **Base URL**: `http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1`
- **Workflow Engines**: Nextflow (NFL), Snakemake (SMK)
- **Authentication**: Optional (Bearer token)
- **Supported Builds**: hg38
- **Max File Size**: 500 MB

### Step 1: Service Registration

**Via Service Registry API:**
```bash
curl -X POST http://localhost:8002/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "ILIFU GA4GH Starter Kit",
    "service_type": "h3africa",
    "api_type": "ga4gh",
    "base_url": "http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1",
    "description": "GA4GH WES service at ILIFU supporting Nextflow and Snakemake workflows",
    "requires_auth": false,
    "max_file_size_mb": 500,
    "supported_formats": ["vcf", "vcf.gz", "plink"],
    "supported_builds": ["hg38"],
    "api_config": {
      "workflow_engines": ["NFL", "SMK"],
      "filesystem_protocols": ["file", "S3"]
    }
  }'
```

**Database Record Created:**
```sql
INSERT INTO imputation_services (
    name, service_type, api_type, base_url,
    description, requires_auth, max_file_size_mb,
    supported_formats, supported_builds, api_config
) VALUES (
    'ILIFU GA4GH Starter Kit',
    'h3africa',
    'ga4gh',
    'http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1',
    'GA4GH WES service...',
    false,
    500,
    '["vcf", "vcf.gz", "plink"]'::json,
    '["hg38"]'::json,
    '{"workflow_engines": ["NFL", "SMK"], "filesystem_protocols": ["file", "S3"]}'::json
);
```

### Step 2: Initial Health Check

Immediately after registration, the next background worker cycle (or manual trigger) performs the first health check:

```python
# Health check URL for GA4GH services
health_url = f"{base_url}/service-info"
# http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/service-info
```

**Request:**
```http
GET /ga4gh/wes/v1/service-info HTTP/1.1
Host: ga4gh-starter-kit.ilifu.ac.za:6000
Accept: application/json
User-Agent: FastAPI-ServiceRegistry/1.0
```

**Response (GA4GH Service Info):**
```json
{
  "id": "org.ga4gh.ilifu.wes",
  "name": "ILIFU WES Service",
  "type": {
    "group": "org.ga4gh",
    "artifact": "wes",
    "version": "1.0.0"
  },
  "organization": {
    "name": "ILIFU",
    "url": "https://www.ilifu.ac.za"
  },
  "supported_wes_versions": ["1.0.0"],
  "workflow_engine_versions": {
    "NFL": "22.10.0",
    "SMK": "6.10.0"
  },
  "supported_filesystem_protocols": ["file", "S3"],
  "system_state_counts": {
    "QUEUED": 0,
    "INITIALIZING": 0,
    "RUNNING": 2,
    "PAUSED": 0,
    "COMPLETE": 145,
    "EXECUTOR_ERROR": 5,
    "SYSTEM_ERROR": 3,
    "CANCELED": 1,
    "CANCELING": 0
  },
  "default_workflow_engine_parameters": [
    {
      "name": "NFL|imputation-nf",
      "type": "workflow",
      "value": "nextflow"
    },
    {
      "name": "SMK|imputation-smk",
      "type": "workflow",
      "value": "snakemake"
    }
  ],
  "auth_instructions_url": "https://www.ilifu.ac.za/auth",
  "contact_info_url": "https://www.ilifu.ac.za/contact",
  "tags": {
    "location": "South Africa",
    "continent": "Africa"
  }
}
```

**Health Check Result:**
```python
{
    "status": "healthy",
    "response_time_ms": 234.5,
    "error_message": None,
    "checked_at": "2025-10-04T10:30:00Z"
}
```

**Database Update:**
```sql
UPDATE imputation_services
SET
    health_status = 'healthy',
    is_available = true,
    response_time_ms = 234.5,
    last_health_check = '2025-10-04 10:30:00',
    error_message = NULL
WHERE id = 7;

INSERT INTO service_health_logs (service_id, status, response_time_ms, checked_at)
VALUES (7, 'healthy', 234.5, '2025-10-04 10:30:00');
```

### Step 3: Ongoing Health Monitoring

Every 5 minutes, the background worker checks all active services:

**Background Worker Code:**
```python
# microservices/service-registry/main.py:307-317

async def periodic_health_check():
    """Run health checks every 5 minutes."""
    while True:
        try:
            db = SessionLocal()
            await health_checker.check_all_services(db)
            db.close()
        except Exception as e:
            logger.error(f"Health check error: {e}")

        await asyncio.sleep(300)  # 5 minutes, non-blocking
```

**Concurrent Checking:**
```python
# microservices/service-registry/main.py:278-302

async def check_all_services(db: Session):
    """Check health of all active services concurrently."""
    services = db.query(ImputationService).filter(
        ImputationService.is_active == True
    ).all()

    # Check all services simultaneously (async magic!)
    for service in services:
        health_result = await self.check_service_health(service)

        # Update database with results
        service.health_status = health_result["status"]
        service.response_time_ms = health_result["response_time_ms"]
        service.error_message = health_result["error_message"]
        service.last_health_check = datetime.utcnow()
        service.is_available = health_result["status"] == "healthy"

        # Log health check
        health_log = ServiceHealthLog(
            service_id=service.id,
            status=health_result["status"],
            response_time_ms=health_result["response_time_ms"],
            error_message=health_result["error_message"]
        )
        db.add(health_log)

    db.commit()
    logger.info(f"Health check completed for {len(services)} services")
```

**Log Output Every 5 Minutes:**
```
2025-10-04 10:30:00 INFO Health check completed for 10 services
2025-10-04 10:30:00 INFO Service 7 (ILIFU GA4GH) - healthy - 234ms
2025-10-04 10:30:00 INFO Service 8 (Michigan) - healthy - 456ms
2025-10-04 10:30:00 INFO Service 9 (eLwazi MALI) - healthy - 312ms
...
```

---

## Michigan Imputation Server Connection

### Service Details

**Michigan Imputation Server**
- **Base URL**: `https://imputationserver.sph.umich.edu`
- **API Type**: michigan
- **Authentication**: X-Auth-Token header
- **Special Behavior**: Returns HTTP 401 when API is online and functioning

### Health Check Logic

```python
# microservices/service-registry/main.py:228-229

if service.api_type == 'michigan':
    health_url = f"{base_url}/api/"
```

**Special Case Handling:**
```python
# microservices/service-registry/main.py:246-251

# Michigan special case: HTTP 401 means API is online and functioning
if service.api_type == 'michigan' and response.status_code == 401:
    return {
        "status": "healthy",
        "response_time_ms": response_time,
        "error_message": None
    }
```

**Why?** Michigan's API returns 401 Unauthorized when accessed without a token, which actually indicates the API is running and responding correctly.

### Example Health Check

**Request:**
```http
GET /api/ HTTP/1.1
Host: imputationserver.sph.umich.edu
Accept: application/json
```

**Response:**
```http
HTTP/1.1 401 Unauthorized
Content-Type: application/json

{
  "success": false,
  "message": "Authentication required"
}
```

**Health Status:** ✅ Healthy (401 indicates API is functioning)

---

## eLwazi MALI Node Connection

### Service Details

**eLwazi Node - Mali**
- **Location**: University of Sciences, Techniques and Technologies of Bamako, Mali
- **Base URL**: `http://elwazi-node.icermali.org:6000/ga4gh/wes/v1`
- **API Type**: ga4gh
- **Workflow Engines**: Nextflow, Snakemake

### Connection Same as ILIFU

Uses identical GA4GH WES connection logic:

1. Health check endpoint: `/service-info`
2. Expected response: GA4GH Service Info JSON
3. Status 200 = healthy
4. Concurrent checking with other services

---

## Error Handling

### Timeout Handling

```python
# microservices/service-registry/main.py:265-270

except httpx.TimeoutException:
    return {
        "status": "timeout",
        "response_time_ms": None,
        "error_message": "Service health check timed out"
    }
```

**Database Update:**
```sql
UPDATE imputation_services
SET
    health_status = 'timeout',
    is_available = false,
    error_message = 'Service health check timed out'
WHERE id = 7;
```

### Connection Error Handling

```python
# microservices/service-registry/main.py:271-277

except Exception as e:
    return {
        "status": "unhealthy",
        "response_time_ms": None,
        "error_message": str(e)[:200]  # Truncate long errors
    }
```

**Common Error Messages:**
- `"Connection refused"` - Service is down
- `"Name or service not known"` - DNS issue
- `"Connection timeout"` - Network connectivity issue
- `"SSL certificate verify failed"` - Certificate issue

---

## Health Status Caching (Django Layer)

While the Service Registry performs health checks every 5 minutes, the Django application caches results to reduce database queries:

### Cache Strategy

```python
# imputation/services/cache_service.py:30-34

ONLINE_INTERVAL = 15 * 60          # 15 minutes for healthy services
OFFLINE_USER_INTERVAL = 1 * 60     # 1 minute for unhealthy (user requests)
OFFLINE_SYSTEM_INTERVAL = 10       # 10 seconds for unhealthy (system checks)
```

### Why This Matters

**Without Caching:**
```
Every page load or API call:
  └─> Query Service Registry DB for health status
      └─> Network overhead + database query
          └─> 50-100ms latency per request
```

**With Caching:**
```
First request:
  └─> Query Service Registry DB
      └─> Cache result for 15 minutes (if healthy)

Subsequent requests (next 15 minutes):
  └─> Serve from cache
      └─> <1ms latency
      └─> No database query
```

**Performance Impact:**
- 15 minutes of cache = up to 900 requests served from cache
- Reduces load on Service Registry database
- Faster response times for users
- Still fresh data (health checks every 5 minutes)

### Adaptive Caching

```python
# imputation/services/cache_service.py:42-59

def _get_interval(self, status: str, is_user_request: bool):
    """Adaptive cache intervals based on service health."""
    if status == 'healthy':
        return 15 * 60  # 15 minutes - service is stable

    # Unhealthy services need more frequent checks
    return 1 * 60 if is_user_request else 10  # 1 min or 10 sec
```

**Why Different Intervals?**
- **Healthy services**: Checked every 5 min, cached 15 min → efficient
- **Unhealthy services**: Need faster detection of recovery
  - User requests: 1 minute cache (acceptable UX delay)
  - System checks: 10 seconds (faster automated recovery)

---

## Service Connection Timeline

### Complete Lifecycle Example (ILIFU)

```
T+0s:     Admin adds ILIFU service via API or Django Admin
          └─> Service created in service_registry_db
              └─> Initial status: health_status='unknown', is_available=false

T+30s:    Background worker runs next cycle
          └─> Detects new service
          └─> Performs first health check
              └─> GET http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/service-info
              └─> Response time: 234ms
              └─> Status: 200 OK
          └─> Updates database:
              └─> health_status='healthy'
              └─> is_available=true
              └─> response_time_ms=234.5

T+5m30s:  Second health check (periodic worker)
          └─> Same process
          └─> Health log entry created

T+10m30s: Third health check
          └─> Continues every 5 minutes...

User visits Services page:
          └─> Django queries Service Registry
          └─> Gets health status (cached for 15 min)
          └─> Displays: "✓ Healthy - 234ms"
```

---

## API Protocol Comparison

### GA4GH WES (ILIFU, eLwazi)

**Health Check Endpoint:** `/service-info`

**Response Structure:**
```json
{
  "supported_wes_versions": ["1.0.0"],
  "workflow_engine_versions": {
    "ENGINE": "VERSION"
  },
  "system_state_counts": {
    "RUNNING": 2,
    "COMPLETE": 145
  },
  "supported_filesystem_protocols": ["file", "S3"]
}
```

**Success Indicator:** HTTP 200

### Michigan Imputation Server

**Health Check Endpoint:** `/api/`

**Response Structure:**
```json
{
  "success": false,
  "message": "Authentication required"
}
```

**Success Indicator:** HTTP 401 (!)

### DNAstack Omics

**Health Check Endpoint:** Base URL

**Response:** Varies by service

**Success Indicator:** HTTP 200, 302, or 401

---

## Testing Service Connections

### Manual Health Check via API

```bash
# Check ILIFU service health
curl http://localhost:8002/services/7/health

# Expected response:
{
  "service_id": 7,
  "status": "healthy",
  "response_time_ms": 234.5,
  "error_message": null,
  "checked_at": "2025-10-04T10:40:00Z"
}
```

### Manual Health Check via Django Admin

1. Navigate to: http://localhost:8000/admin/imputation/imputationservice/
2. Click on service name (e.g., "ILIFU GA4GH Starter Kit")
3. Click "Test Connection" button
4. View results in popup

### Direct Service Testing

```bash
# Test ILIFU service directly
curl http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/service-info

# Test Michigan service directly
curl https://imputationserver.sph.umich.edu/api/

# Test eLwazi MALI service
curl http://elwazi-node.icermali.org:6000/ga4gh/wes/v1/service-info
```

---

## Monitoring Health Checks

### View Health Check Logs

```bash
# Real-time health check monitoring
docker logs -f service-registry | grep "Health check"

# Expected output:
2025-10-04 10:30:00 INFO Health check completed for 10 services
2025-10-04 10:35:00 INFO Health check completed for 10 services
```

### Query Health History

```bash
# Get health check history for ILIFU
curl 'http://localhost:8002/health-logs?service_id=7&limit=10' | jq

# Response:
[
  {
    "id": 1234,
    "service_id": 7,
    "status": "healthy",
    "response_time_ms": 234.5,
    "error_message": null,
    "checked_at": "2025-10-04T10:30:00Z"
  },
  ...
]
```

### Database Query

```sql
-- Recent health checks for all services
SELECT
    s.name,
    hl.status,
    hl.response_time_ms,
    hl.checked_at
FROM service_health_logs hl
JOIN imputation_services s ON hl.service_id = s.id
WHERE hl.checked_at > NOW() - INTERVAL '1 hour'
ORDER BY hl.checked_at DESC;

-- Average response time per service (last 24 hours)
SELECT
    s.name,
    AVG(hl.response_time_ms) as avg_response_ms,
    COUNT(*) as check_count,
    SUM(CASE WHEN hl.status = 'healthy' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as uptime_percent
FROM service_health_logs hl
JOIN imputation_services s ON hl.service_id = s.id
WHERE hl.checked_at > NOW() - INTERVAL '24 hours'
GROUP BY s.id, s.name
ORDER BY uptime_percent DESC;
```

---

## Troubleshooting Connection Issues

### ILIFU Service Unreachable

**Symptoms:**
- Health status: `timeout` or `unhealthy`
- Error message: `"Connection timeout"` or `"Connection refused"`

**Debug Steps:**

1. **Test from outside container:**
   ```bash
   curl http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/service-info
   ```

2. **Test from inside Service Registry container:**
   ```bash
   docker-compose exec service-registry curl http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/service-info
   ```

3. **Check DNS resolution:**
   ```bash
   docker-compose exec service-registry nslookup ga4gh-starter-kit.ilifu.ac.za
   ```

4. **Check network connectivity:**
   ```bash
   docker-compose exec service-registry ping -c 3 ga4gh-starter-kit.ilifu.ac.za
   ```

**Common Causes:**
- ILIFU service is down
- Network firewall blocking outbound connections
- DNS resolution issues
- Service moved to different URL

### Incorrect Health Status

**Symptoms:**
- Service shows as unhealthy but responds correctly when tested manually
- Intermittent health check failures

**Debug Steps:**

1. **Check timeout settings:**
   ```python
   # microservices/service-registry/main.py
   # Current timeout: 10 seconds
   # May need to increase for slow services
   ```

2. **Check for SSL issues:**
   ```bash
   # If service uses HTTPS, check certificate
   curl -v https://example.com/service-info
   ```

3. **Review error messages:**
   ```bash
   curl http://localhost:8002/services/7 | jq '.error_message'
   ```

4. **Check service-specific requirements:**
   - Some services require specific headers
   - Authentication tokens may have expired
   - API version mismatch

---

## Best Practices

### Service Registration

1. **Test service connectivity first:**
   ```bash
   curl <service_url>/service-info
   ```

2. **Use correct API type:**
   - ga4gh for GA4GH WES services
   - michigan for Michigan Imputation Server
   - dnastack for DNAstack services

3. **Configure appropriate timeouts:**
   - Geographically distant services may need longer timeouts
   - Default 10s is usually sufficient

4. **Add descriptive information:**
   - Include location, capabilities, limitations
   - Helps users choose appropriate service

### Health Monitoring

1. **Monitor health check completion times:**
   - Should complete in <15s for 10 services
   - Alert if consistently >30s

2. **Set up alerts for prolonged downtime:**
   - Service down >15 minutes = alert
   - Multiple services down = critical alert

3. **Review health logs periodically:**
   - Identify patterns in failures
   - Detect degrading performance
   - Plan capacity adjustments

4. **Keep service metadata updated:**
   - Update API URLs if services migrate
   - Update authentication when tokens expire
   - Verify supported formats and builds

---

## References

### Code Locations

- **Health Check Logic**: `microservices/service-registry/main.py:219-303`
- **Background Worker**: `microservices/service-registry/main.py:307-322`
- **Service Models**: `microservices/service-registry/main.py:35-94`
- **Cache Service**: `imputation/services/cache_service.py:15-262`

### Related Documentation

- [Service Registry README](./README.md) - Complete microservice documentation
- [GA4GH WES Specification](https://github.com/ga4gh/workflow-execution-service-schemas)
- [Architecture Overview](../../architecture/DJANGO_FASTAPI_ARCHITECTURE.md)

### External Services

- **ILIFU GA4GH**: http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1
- **eLwazi MALI**: http://elwazi-node.icermali.org:6000/ga4gh/wes/v1
- **Michigan**: https://imputationserver.sph.umich.edu

---

**Document Version**: 1.0
**Last Updated**: 2025-10-04
**Maintainer**: Platform Team
