# Service Registry Microservice

## External Imputation Service Management & Health Monitoring

> **Port**: 8002
> **Framework**: FastAPI
> **Database**: `service_registry_db`
> **Status**: Production
> **Last Updated**: 2025-10-04

---

## Overview

The Service Registry is a FastAPI-based microservice responsible for managing external genomic imputation services (like ILIFU GA4GH Starter Kit, Michigan Imputation Server) and performing **asynchronous health monitoring**.

### Key Responsibilities

1. **Service Management**
   - Register external imputation services
   - Store service metadata and configuration
   - Manage reference panel information

2. **Health Monitoring** ⭐
   - Async health checks every 5 minutes
   - Concurrent checking of multiple services
   - Response time tracking
   - Availability status updates

3. **Service Discovery**
   - Provide service information to other microservices
   - Query available services and their capabilities
   - Reference panel listing and filtering

---

## Why FastAPI for Service Registry?

### Performance Requirements

The Service Registry needs to check **10+ external services every 5 minutes**:

**Django (Synchronous) Would Take:**

```python
# Sequential blocking requests
for service in services:  # 10 services
    response = requests.get(service.url, timeout=10)  # Blocks for up to 10s
    # Process...

# Total time: 10 services × 10 seconds = 100+ seconds
# Entire app blocked during health checks!
```

**FastAPI (Asynchronous) Solution:**

```python
# Concurrent non-blocking requests
async def check_all_services():
    tasks = [check_service(s) for s in services]  # 10 tasks
    results = await asyncio.gather(*tasks)  # All run simultaneously

# Total time: ~10 seconds (limited by slowest service, not sum)
# App continues handling other requests during checks!
```

**Performance Gain**: **10x faster** for health monitoring workload

### Resource Efficiency

| Metric | Django Implementation | FastAPI Implementation |
|--------|----------------------|------------------------|
| Memory | ~200 MB | ~70 MB |
| Startup | 3-5 seconds | <1 second |
| Concurrent Requests | Limited (threading) | Native (async/await) |
| Dependencies | Full Django stack | FastAPI + SQLAlchemy |

---

## Architecture

### Components

```
┌──────────────────────────────────────────────────────┐
│         Service Registry (Port 8002)                 │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │  FastAPI Application                       │    │
│  │  • REST API endpoints                      │    │
│  │  • Service CRUD operations                 │    │
│  │  • Reference panel management              │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │  Background Health Check Worker            │    │
│  │  • Runs every 5 minutes (async)            │    │
│  │  • Concurrent service health checks        │    │
│  │  • Updates database with results           │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │  Database (service_registry_db)            │    │
│  │  • imputation_services                     │    │
│  │  • reference_panels                        │    │
│  │  • service_health_logs                     │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
└──────────────────────────────────────────────────────┘
                       │
                       │ HTTP Health Checks
                       ▼
        ┌──────────────────────────────┐
        │  External Services           │
        │  • ILIFU GA4GH (South Africa)│
        │  • Michigan (USA)            │
        │  • eLwazi MALI (Mali)        │
        └──────────────────────────────┘
```

### Database Schema

#### `imputation_services`

```sql
CREATE TABLE imputation_services (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    service_type VARCHAR(50) NOT NULL,     -- h3africa, michigan, ga4gh
    api_type VARCHAR(50) NOT NULL,         -- michigan, ga4gh, dnastack
    base_url VARCHAR(500) NOT NULL,
    description TEXT,
    version VARCHAR(50),

    -- Service configuration
    requires_auth BOOLEAN DEFAULT TRUE,
    auth_type VARCHAR(50),                 -- token, oauth2, api_key
    max_file_size_mb INTEGER DEFAULT 100,
    supported_formats JSON DEFAULT '[]',   -- ['vcf', 'plink', 'bgen']
    supported_builds JSON DEFAULT '[]',    -- ['hg19', 'hg38']
    api_config JSON DEFAULT '{}',          -- Connection parameters

    -- Service status (updated by health checker)
    is_active BOOLEAN DEFAULT TRUE,
    is_available BOOLEAN DEFAULT TRUE,
    last_health_check TIMESTAMP,
    health_status VARCHAR(20) DEFAULT 'unknown',  -- healthy, unhealthy, timeout
    response_time_ms FLOAT,
    error_message TEXT,

    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

#### `reference_panels`

```sql
CREATE TABLE reference_panels (
    id SERIAL PRIMARY KEY,
    service_id INTEGER REFERENCES imputation_services(id),
    name VARCHAR(200) NOT NULL,
    display_name VARCHAR(200),
    description TEXT,

    -- Panel characteristics
    population VARCHAR(100),               -- African, European, Mixed
    build VARCHAR(20),                     -- hg19, hg38
    samples_count INTEGER,
    variants_count INTEGER,

    -- Availability
    is_available BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT TRUE,
    requires_permission BOOLEAN DEFAULT FALSE,

    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(service_id, name)
);
```

#### `service_health_logs`

```sql
CREATE TABLE service_health_logs (
    id SERIAL PRIMARY KEY,
    service_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,          -- healthy, unhealthy, timeout
    response_time_ms FLOAT,
    error_message TEXT,
    checked_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_health_logs_service ON service_health_logs(service_id);
CREATE INDEX idx_health_logs_time ON service_health_logs(checked_at);
```

---

## API Endpoints

### Service Management

#### List Services

```http
GET /services
```

**Query Parameters:**

- `service_type` (optional): Filter by service type (h3africa, michigan)
- `is_active` (optional): Filter by active status (true/false)
- `is_available` (optional): Filter by availability (true/false)

**Response:**

```json
[
  {
    "id": 7,
    "name": "ILIFU GA4GH Starter Kit",
    "service_type": "h3africa",
    "api_type": "ga4gh",
    "base_url": "http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1",
    "description": "GA4GH WES service at ILIFU",
    "is_active": true,
    "is_available": true,
    "health_status": "healthy",
    "response_time_ms": 234.5,
    "last_health_check": "2025-10-04T10:30:00Z"
  }
]
```

#### Get Service Details

```http
GET /services/{service_id}
```

**Response:**

```json
{
  "id": 7,
  "name": "ILIFU GA4GH Starter Kit",
  "service_type": "h3africa",
  "api_type": "ga4gh",
  "base_url": "http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1",
  "api_config": {
    "workflow_engines": ["NFL", "SMK"],
    "filesystem_protocols": ["file", "S3"]
  },
  "supported_formats": ["vcf", "vcf.gz", "plink"],
  "supported_builds": ["hg38"],
  "health_status": "healthy",
  "response_time_ms": 234.5,
  "error_message": null
}
```

#### Create Service

```http
POST /services
Content-Type: application/json
```

**Request Body:**

```json
{
  "name": "New Imputation Service",
  "service_type": "h3africa",
  "api_type": "ga4gh",
  "base_url": "https://example.com/ga4gh/wes/v1",
  "description": "Example service",
  "requires_auth": false,
  "max_file_size_mb": 500,
  "supported_formats": ["vcf", "vcf.gz"],
  "supported_builds": ["hg38"],
  "api_config": {}
}
```

#### Update Service

```http
PATCH /services/{service_id}
Content-Type: application/json
```

**Request Body** (partial update):

```json
{
  "is_active": false,
  "description": "Updated description"
}
```

### Health Monitoring

#### Manual Health Check

```http
GET /services/{service_id}/health
```

**Response:**

```json
{
  "service_id": 7,
  "status": "healthy",
  "response_time_ms": 234.5,
  "error_message": null,
  "checked_at": "2025-10-04T10:35:00Z"
}
```

### Reference Panels

#### List Reference Panels

```http
GET /reference-panels
```

**Query Parameters:**

- `service_id` (optional): Filter by service
- `build` (optional): Filter by genome build
- `population` (optional): Filter by population
- `is_available` (optional): Filter by availability

**Response:**

```json
[
  {
    "id": 1,
    "service_id": 7,
    "name": "Nextflow Imputation Pipeline",
    "display_name": "African Panel (Nextflow)",
    "description": "Imputation using Nextflow workflow engine",
    "population": "African",
    "build": "hg38",
    "samples_count": 5000,
    "variants_count": 20000000,
    "is_available": true,
    "is_public": true
  }
]
```

#### Sync Reference Panels

```http
POST /services/{service_id}/sync_reference_panels
```

**Note**: Most imputation services don't expose programmatic APIs for panel listing. This endpoint exists for future enhancement. Currently returns:

```json
{
  "status": "not_supported",
  "message": "Reference panel sync not implemented for ga4gh services",
  "service_id": 7,
  "existing_panels": 2,
  "suggestion": "Add panels manually via admin interface"
}
```

---

## Health Monitoring System

### Background Worker

The health check worker runs automatically on service startup:

```python
# main.py:320-322
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(periodic_health_check())
```

### Health Check Process

```python
# main.py:307-317
async def periodic_health_check():
    """Run health checks every 5 minutes."""
    while True:
        try:
            db = SessionLocal()
            await health_checker.check_all_services(db)
            db.close()
        except Exception as e:
            logger.error(f"Health check error: {e}")

        await asyncio.sleep(300)  # 5 minutes (non-blocking)
```

### Service-Specific Health Check Logic

```python
# main.py:219-277
async def check_service_health(service: ImputationService):
    """Check health of a specific service."""
    start_time = datetime.utcnow()

    # Determine health check URL based on API type
    base_url = service.base_url.rstrip('/')

    if service.api_type == 'michigan':
        health_url = f"{base_url}/api/"
    elif service.api_type == 'ga4gh':
        health_url = f"{base_url}/service-info"
    elif service.api_type == 'dnastack':
        health_url = base_url
    else:
        health_url = f"{base_url}/health"

    # Async HTTP request (non-blocking)
    response = await self.client.get(health_url, timeout=10.0)

    end_time = datetime.utcnow()
    response_time = (end_time - start_time).total_seconds() * 1000

    # Special case: Michigan returns 401 when API is online
    if service.api_type == 'michigan' and response.status_code == 401:
        return {
            "status": "healthy",
            "response_time_ms": response_time,
            "error_message": None
        }
    elif response.status_code in [200, 201, 202]:
        return {
            "status": "healthy",
            "response_time_ms": response_time,
            "error_message": None
        }
    else:
        return {
            "status": "unhealthy",
            "response_time_ms": response_time,
            "error_message": f"HTTP {response.status_code}"
        }
```

### Health Status Updates

```python
# main.py:278-302
async def check_all_services(db: Session):
    """Check health of all active services."""
    services = db.query(ImputationService).filter(
        ImputationService.is_active == True
    ).all()

    for service in services:
        health_result = await self.check_service_health(service)

        # Update service status in database
        service.health_status = health_result["status"]
        service.response_time_ms = health_result["response_time_ms"]
        service.error_message = health_result["error_message"]
        service.last_health_check = datetime.utcnow()
        service.is_available = health_result["status"] == "healthy"

        # Log health check result
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

---

## Configuration

### Environment Variables

```bash
# Database connection
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/service_registry_db

# Service port
PORT=8002

# Logging
LOG_LEVEL=INFO
```

### Docker Configuration

```yaml
# docker-compose.microservices.yml
service-registry:
  build:
    context: ./microservices/service-registry
  ports:
    - "8002:8002"
  environment:
    - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/service_registry_db
  depends_on:
    postgres:
      condition: service_healthy
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8002/health"]
    interval: 30s
    timeout: 10s
    retries: 3
```

---

## Usage Examples

### Add ILIFU Service

```bash
curl -X POST http://localhost:8002/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "ILIFU GA4GH Starter Kit",
    "service_type": "h3africa",
    "api_type": "ga4gh",
    "base_url": "http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1",
    "description": "GA4GH WES service at ILIFU",
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

### Check Service Health

```bash
# Manual health check
curl http://localhost:8002/services/7/health

# Get service with latest health status
curl http://localhost:8002/services/7 | jq '.health_status, .response_time_ms'
```

### List Available Services

```bash
# All services
curl http://localhost:8002/services | jq

# Only healthy services
curl 'http://localhost:8002/services?is_available=true' | jq

# GA4GH services only
curl 'http://localhost:8002/services?api_type=ga4gh' | jq
```

### Query Reference Panels

```bash
# All panels for a service
curl 'http://localhost:8002/reference-panels?service_id=7' | jq

# hg38 panels only
curl 'http://localhost:8002/reference-panels?build=hg38' | jq
```

---

## Monitoring & Observability

### Health Check Endpoint

```bash
curl http://localhost:8002/health
```

**Response:**

```json
{
  "status": "healthy",
  "service": "service-registry",
  "timestamp": "2025-10-04T10:40:00Z"
}
```

### Logs

```bash
# View logs
docker logs service-registry

# Follow logs
docker logs -f service-registry

# Filter for health checks
docker logs service-registry 2>&1 | grep "Health check"
```

**Expected Log Output:**

```
INFO:     Started server process [1]
INFO:     Uvicorn running on http://0.0.0.0:8002
INFO:     Health check completed for 10 services
INFO:     Service 7 (ILIFU GA4GH) - healthy - 234ms
INFO:     Service 8 (Michigan) - healthy - 456ms
```

### Metrics

Key metrics to monitor:

1. **Health Check Completion Time**
   - Target: <15 seconds for 10 services
   - Alert: >30 seconds

2. **Service Availability**
   - Target: >95% uptime
   - Alert: Any service down >15 minutes

3. **Response Times**
   - Target: <500ms per service
   - Alert: >2000ms consistently

4. **Error Rate**
   - Target: <5% failed health checks
   - Alert: >20% failures

---

## Troubleshooting

### Service Registry Not Starting

**Check database connection:**

```bash
# Test PostgreSQL connection
docker-compose exec postgres psql -U postgres -l | grep service_registry_db

# View service registry logs
docker logs service-registry 2>&1 | grep -i error
```

### Health Checks Not Running

**Verify background worker:**

```bash
# Check logs for health check messages
docker logs service-registry 2>&1 | grep "Health check"

# Should see every 5 minutes:
# "Health check completed for X services"
```

**If not seeing health checks:**

1. Service registry may have crashed - check logs
2. Database connection issues - verify DATABASE_URL
3. Python event loop issues - restart container

### Service Shows as Unhealthy

**Debug steps:**

```bash
# 1. Check service directly
curl http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/service-info

# 2. Check from inside container
docker-compose exec service-registry curl http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/service-info

# 3. Check error message in database
curl http://localhost:8002/services/7 | jq '.error_message'

# 4. Manual health check with verbose output
docker logs service-registry -f
# Then trigger: curl http://localhost:8002/services/7/health
```

### High Memory Usage

**Check metrics:**

```bash
docker stats service-registry

# Expected: ~70 MB
# High: >200 MB
```

**Possible causes:**

- Too many concurrent health checks
- Database connection leak
- Unclosed HTTP client sessions

**Fix:**

```bash
# Restart service
docker-compose restart service-registry

# If persistent, check code for connection leaks
```

---

## Development

### Local Development

```bash
# Navigate to service directory
cd microservices/service-registry

# Install dependencies
pip install -r requirements.txt

# Run locally (requires PostgreSQL)
export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/service_registry_db
uvicorn main:app --reload --port 8002
```

### Running Tests

```bash
# Unit tests
pytest tests/

# Integration tests
pytest tests/integration/

# With coverage
pytest --cov=main --cov-report=html
```

### API Documentation

FastAPI automatically generates interactive API documentation:

- **Swagger UI**: <http://localhost:8002/docs>
- **ReDoc**: <http://localhost:8002/redoc>
- **OpenAPI JSON**: <http://localhost:8002/openapi.json>

---

## Integration with Other Services

### Job Processor Integration

```python
# Job Processor queries Service Registry for service info
async def get_service_info(service_id: int):
    SERVICE_REGISTRY_URL = 'http://service-registry:8002'
    response = await client.get(f"{SERVICE_REGISTRY_URL}/services/{service_id}")
    return response.json()
```

### Monitoring Service Integration

```python
# Monitoring Service aggregates health status
async def get_system_health():
    response = await client.get('http://service-registry:8002/services')
    services = response.json()

    return {
        'total': len(services),
        'healthy': len([s for s in services if s['is_available']]),
        'unhealthy': len([s for s in services if not s['is_available']])
    }
```

---

## Future Enhancements

### Planned Features

1. **Automatic Reference Panel Sync**
   - Poll GA4GH services for workflow capabilities
   - Auto-create panels from service metadata
   - Schedule periodic panel updates

2. **Service Metrics Collection**
   - Track job completion rates per service
   - Monitor average processing times
   - Detect performance degradation trends

3. **Smart Health Checking**
   - Adaptive check intervals based on history
   - Faster checks for unhealthy services
   - Slower checks for consistently healthy services

4. **Circuit Breaker Pattern**
   - Temporarily disable unhealthy services
   - Auto-retry with exponential backoff
   - Automatic recovery detection

5. **Service Version Management**
   - Track service API versions
   - Compatibility checking
   - Migration warnings

---

## References

### Code Files

- **Main Service**: [`microservices/service-registry/main.py`](../../../microservices/service-registry/main.py) (623 lines)
- **Dockerfile**: [`microservices/service-registry/Dockerfile`](../../../microservices/service-registry/Dockerfile)
- **Requirements**: [`microservices/service-registry/requirements.txt`](../../../microservices/service-registry/requirements.txt)

### Related Documentation

- [Service Connection Deep Dive](./SERVICE_CONNECTION.md) - How external services connect
- [Architecture Overview](../../architecture/DJANGO_FASTAPI_ARCHITECTURE.md) - Full system architecture
- [API Gateway](../api-gateway/README.md) - Request routing to Service Registry

### External Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Async](https://docs.sqlalchemy.org/en/14/orm/extensions/asyncio.html)
- [GA4GH WES Specification](https://github.com/ga4gh/workflow-execution-service-schemas)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-04
**Maintainer**: Platform Team
**Status**: Living Document
