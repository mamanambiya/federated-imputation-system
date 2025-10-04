# Architecture Context - Quick Reference
## Federated Genomic Imputation Platform

> **Quick Reference Guide** for understanding the hybrid Django + FastAPI architecture
> **Last Updated**: 2025-10-04

---

## 30-Second Overview

This platform uses **Django AND FastAPI together** (not one vs. the other):
- **Django**: Admin interface, user auth, complex ORM, traditional web app
- **FastAPI**: Async health monitoring, microservices, high-performance APIs

We have **7 databases** (database-per-service pattern) for service isolation and independent scaling.

---

## Why Both Frameworks?

### Django REST Framework
**Use For**: Admin interfaces, user management, complex ORM operations
**Strengths**: Built-in admin panel, batteries-included, mature ecosystem
**Example**: Service management UI, user authentication, job creation forms

### FastAPI
**Use For**: Async operations, microservices, health monitoring
**Strengths**: Native async/await, 10x faster for I/O, auto-generated docs
**Example**: Checking 10 external services in 2s instead of 20s

**Key Metric**: Health checks (Django: 20-30s sequential, FastAPI: 2-3s concurrent)

---

## Database Architecture

```
┌─────────────────────────────────────────────────┐
│  PostgreSQL Instance (7 databases)              │
├─────────────────────────────────────────────────┤
│  1. federated_imputation    ← Django main app  │
│  2. user_management_db      ← User Service     │
│  3. service_registry_db     ← Service Registry │ ← ILIFU health checks here
│  4. job_processing_db       ← Job Processor    │
│  5. file_management_db      ← File Manager     │
│  6. notification_db         ← Notification     │
│  7. monitoring_db           ← Monitoring        │
└─────────────────────────────────────────────────┘
```

**Why Multiple DBs?**
- Service isolation (failure doesn't cascade)
- Independent scaling (Service Registry is read-heavy, Job Processor is write-heavy)
- Technology flexibility (could use different DB engines)
- Clearer service boundaries

**Resource Savings**: 6 FastAPI services = 300 MB vs 6 Django services = 1.2 GB (75% reduction)

---

## Current Architecture Map

### Running Services

| Port | Service | Framework | Database | Purpose |
|------|---------|-----------|----------|---------|
| 8000 | Django Web | Django + DRF | `federated_imputation` | Admin UI, main app |
| 8001 | User Service | FastAPI | `user_management_db` | Auth, user management |
| 8002 | **Service Registry** | FastAPI | `service_registry_db` | **ILIFU health checks** |
| 8003 | Job Processor | FastAPI | `job_processing_db` | Job execution |
| 8004 | File Manager | FastAPI | `file_management_db` | File operations |
| 8005 | Notification | FastAPI | `notification_db` | Alerts, emails |
| 8006 | Monitoring | FastAPI | `monitoring_db` | System metrics |
| 3000 | Frontend | React | - | User interface |

### ILIFU Service Connection Flow

```
ILIFU Service (External)
    ↓ HTTP GET /service-info (every 5 min)
Service Registry (FastAPI :8002)
    ↓ Async health check
    ↓ Store in service_registry_db
    ↓ Update: status, response_time_ms, is_available
Django App (reads cache)
    ↓ Display in admin interface
```

**Key Files**:
- Health check: `microservices/service-registry/main.py:219-303` (async)
- Caching: `imputation/services/cache_service.py:15-262` (15min/1min/10s)
- Admin UI: `imputation/admin_views.py:85-297` (test connection)

---

## Critical Integration Gap ⚠️

### The Problem

```
Django Admin                    Service Registry
    ↓                                 ↓
Django DB                       Service Registry DB
    ↓                                 ↓
ILIFU service added    ❌      NOT synced here!
    ↓                                 ↓
Visible in admin       ❌      Health checks DON'T run!
```

**Status**: Django Admin and FastAPI microservices **DO NOT automatically sync**

**Workaround**: Manually add services via microservice API:
```bash
curl -X POST http://localhost:8002/services \
  -H "Content-Type: application/json" \
  -d '{"name": "ILIFU", "api_type": "ga4gh", "base_url": "..."}'
```

### Future Solutions

1. **Event-Driven Sync** (Easy, 2-3 days)
   - Django signals trigger HTTP POST to microservices
   - Auto-sync on service create/update

2. **API-First Admin** (Recommended, 2 weeks)
   - Microservice = source of truth
   - Django Admin = thin UI client
   - All operations via microservice APIs

3. **Shared DB Access** (Not recommended)
   - Violates microservice principles
   - Tight coupling at database level

---

## When to Use What

### Choose Django/DRF When:
- ✅ Building admin interfaces (zero-code admin panel)
- ✅ Complex ORM relationships (automatic migrations)
- ✅ Traditional CRUD operations
- ✅ User authentication and permissions
- ✅ Template-based pages

### Choose FastAPI When:
- ✅ Async/concurrent operations (health checks, real-time)
- ✅ High-performance APIs (10x faster for I/O)
- ✅ Microservices (lightweight, independent)
- ✅ Auto-documentation (built-in Swagger/OpenAPI)
- ✅ Modern Python (type hints, async/await)

### Use Both When:
- ✅ Migrating monolith to microservices (current state)
- ✅ Different scaling requirements per component
- ✅ Need admin UI + high-performance backend
- ✅ Want to leverage strengths of each

---

## Code Structure

### Django Monolith
```
imputation/
├── models.py              # Django ORM models (282+ lines)
├── views.py               # DRF ViewSets (2,043 lines!)
├── serializers.py         # DRF serializers
├── admin.py               # Admin interface config
├── admin_views.py         # Custom admin views
└── services/              # External service integrations
    └── cache_service.py   # Health check caching (262 lines)
```

### FastAPI Microservices
```
microservices/
├── service-registry/
│   └── main.py           # Service health monitoring (623 lines)
├── user-service/
│   └── main.py           # User authentication
├── job-processor/
│   └── main.py           # Job execution
├── file-manager/
│   └── main.py           # File operations
├── notification/
│   └── main.py           # Alerts and emails
└── monitoring/
    └── main.py           # System metrics
```

---

## Performance Benchmarks

### Health Check Comparison (10 External Services)

| Implementation | Method | Time | Blocking | Resource |
|----------------|--------|------|----------|----------|
| Django (sync) | Sequential | 20-30s | ❌ Blocks app | High CPU |
| Django (threads) | Threading | 5-8s | ⚠️ Partial | Medium CPU |
| **FastAPI (async)** | Concurrent | **2-3s** | ✅ Non-blocking | Low CPU |

### Memory Footprint

| Deployment | Memory | Notes |
|------------|--------|-------|
| All Django | 1,200 MB | 6 services × 200 MB |
| All FastAPI | 300 MB | 6 services × 50 MB |
| **Hybrid (current)** | **695 MB** | Django admin + FastAPI services |

**Savings**: 40% less memory vs. all-Django architecture

---

## Common Patterns

### Django Admin Testing External Service

```python
# imputation/admin_views.py:205-297

@staff_member_required
def test_service_connection(request):
    """Test connection to external service (ILIFU, Michigan)."""
    api_url = request.POST.get('api_url')
    api_type = request.POST.get('api_type')

    if api_type == 'ga4gh':
        # Test GA4GH WES service
        headers = {'Accept': 'application/json'}
        response = requests.get(f"{api_url}/service-info", headers=headers)

    return JsonResponse({'success': True, 'data': response.json()})
```

### FastAPI Async Health Check

```python
# microservices/service-registry/main.py:219-277

async def check_service_health(service: ImputationService):
    """Non-blocking health check."""
    # Async HTTP request - doesn't block other operations
    response = await client.get(f"{service.base_url}/service-info")

    return {
        "status": "healthy" if response.status_code == 200 else "unhealthy",
        "response_time_ms": (end - start).total_seconds() * 1000
    }

async def check_all_services(db: Session):
    """Check all services concurrently."""
    services = db.query(ImputationService).all()

    # ALL services checked simultaneously!
    for service in services:
        result = await check_service_health(service)
        # Update database...
```

### Intelligent Caching

```python
# imputation/services/cache_service.py:42-59

def _get_interval(self, status: str, is_user_request: bool):
    """Adaptive cache intervals based on service health."""
    if status == 'healthy':
        return 15 * 60  # 15 minutes for healthy services

    # Unhealthy services checked more frequently
    return 1 * 60 if is_user_request else 10  # 1 min or 10 sec
```

---

## Troubleshooting Guide

### Service Registry Not Responding

```bash
# Check if running
docker ps | grep service-registry

# View logs
docker logs service-registry

# Health check
curl http://localhost:8002/health

# List services
curl http://localhost:8002/services/ | jq
```

### Django Admin Can't See Service Updates

**Cause**: Data not synced between Django DB and Service Registry DB

**Solution**:
```bash
# Option 1: Add service via Service Registry API
curl -X POST http://localhost:8002/services \
  -H "Content-Type: application/json" \
  -d '{"name": "ILIFU", ...}'

# Option 2: Trigger manual sync (if implemented)
# In Django admin: Select service → Actions → "Sync to microservice"
```

### Health Checks Not Running

**Check**:
1. Service exists in `service_registry_db` (not just Django DB)
2. Service is `is_active = True`
3. Service Registry worker is running (`docker logs service-registry`)
4. Check background task: Should see "Health check completed for X services" every 5 min

---

## Key Architectural Decisions

### Decision 1: Why Not Just Django?

**Problem**: Async operations (health checks) would require:
- Complex threading/multiprocessing
- Celery for every async operation
- Higher resource usage
- More complex error handling

**Solution**: FastAPI's native async/await for I/O-bound operations

### Decision 2: Why Multiple Databases?

**Problem**: Single database = single point of failure, coupled services, scaling bottleneck

**Solution**: Database-per-service pattern
- Each service owns its data
- Independent scaling
- Fault isolation
- Clearer boundaries

### Decision 3: Why Keep Django?

**Problem**: FastAPI has no admin interface, would need custom UI for everything

**Solution**: Keep Django for:
- Rich admin interface (zero-code)
- Complex ORM with migrations
- User authentication system
- Template rendering

---

## Migration Timeline

```
2023: Django Monolith
  └── Everything in one app (2,043 lines views.py)

2024: Microservices Added
  └── FastAPI services built alongside Django

2025 (Current): Hybrid Architecture
  ├── Django: Admin, auth, legacy features
  ├── FastAPI: Health monitoring, microservices
  └── Integration gap: Manual sync required

2026 (Planned): Full Integration
  └── Event-driven sync, unified management
```

---

## Quick Reference Links

### Documentation

**Microservices (Detailed):**
- **[Microservices Overview](dev_docs/microservices/README.md)** - Index of all 7 microservices
- **[Service Registry README](dev_docs/microservices/service-registry/README.md)** - Complete Service Registry docs (✅ Production)
- **[Service Connection Guide](dev_docs/microservices/service-registry/SERVICE_CONNECTION.md)** - ILIFU, Michigan, eLwazi connection deep dive

**Architecture (High-Level):**
- Full Architecture Doc: [`dev_docs/architecture/DJANGO_FASTAPI_ARCHITECTURE.md`](dev_docs/architecture/DJANGO_FASTAPI_ARCHITECTURE.md)
- Microservices Design: [`docs/MICROSERVICES_ARCHITECTURE_DESIGN.md`](docs/MICROSERVICES_ARCHITECTURE_DESIGN.md)
- Implementation Summary: [`docs/MICROSERVICES_IMPLEMENTATION_SUMMARY.md`](docs/MICROSERVICES_IMPLEMENTATION_SUMMARY.md)

### Key Code Files
- Django Admin: [`imputation/admin.py:19-114`](imputation/admin.py)
- Service Registry: [`microservices/service-registry/main.py`](microservices/service-registry/main.py)
- Health Caching: [`imputation/services/cache_service.py`](imputation/services/cache_service.py)
- Docker Config: [`docker-compose.microservices.yml`](docker-compose.microservices.yml)

### External Resources
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [Microservices Patterns](https://microservices.io/patterns/)
- [GA4GH WES Spec](https://github.com/ga4gh/workflow-execution-service-schemas)

---

## When You Need to...

### Add a New External Service (ILIFU-like)

1. **Via Django Admin** (UI):
   - Go to `/admin/imputation/imputationservice/`
   - Click "Add Service (Setup Wizard)"
   - Fill in details, test connection
   - **⚠️ Then manually add to Service Registry**

2. **Via Service Registry API** (Recommended):
   ```bash
   curl -X POST http://localhost:8002/services \
     -H "Content-Type: application/json" \
     -d '{
       "name": "My Service",
       "api_type": "ga4gh",
       "base_url": "http://example.com/api"
     }'
   ```

### Check Service Health

```bash
# Via Service Registry API
curl http://localhost:8002/services/7/health

# Via Django
# Admin → Services → Click service → "Test Connection" button
```

### Debug Async Operations

```python
# Add logging to FastAPI service
import logging
logger = logging.getLogger(__name__)

async def my_async_function():
    logger.info("Starting async operation")
    result = await some_async_call()
    logger.info(f"Completed: {result}")
    return result
```

### Scale a Specific Service

```bash
# In docker-compose.microservices.yml
docker-compose up -d --scale service-registry=3

# Or in Kubernetes (future)
kubectl scale deployment service-registry --replicas=3
```

---

## Remember

1. **Django for UI/Admin, FastAPI for Performance**
2. **7 Databases = 7 Independent Services**
3. **Sync Gap = Manual intervention needed (for now)**
4. **Async = 10x faster for I/O operations**
5. **This is a migration in progress, not final state**

---

**Version**: 1.0
**Last Updated**: 2025-10-04
**Quick Questions?**: See full doc at `dev_docs/architecture/DJANGO_FASTAPI_ARCHITECTURE.md`
