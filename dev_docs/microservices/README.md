# Microservices Documentation
## Federated Genomic Imputation Platform

> **Architecture**: 7 Independent Microservices + API Gateway
> **Framework**: FastAPI (Python 3.11+)
> **Database Pattern**: Database-per-service
> **Last Updated**: 2025-10-04

---

## Overview

The platform uses a microservices architecture with 7 specialized services, each responsible for a specific domain of functionality. Each service is built with FastAPI for high performance and native async support.

### Microservices Map

| Port | Service | Status | Documentation |
|------|---------|--------|---------------|
| 8000 | [API Gateway](./api-gateway/) | ⚠️ Planned | Request routing, auth, rate limiting |
| 8001 | [User Service](./user-service/) | 🏗️ Building | User auth, profiles, permissions |
| 8002 | [**Service Registry**](./service-registry/) | ✅ **Production** | **External service management, health monitoring** |
| 8003 | [Job Processor](./job-processor/) | 🏗️ Building | Job lifecycle, execution, status tracking |
| 8004 | [File Manager](./file-manager/) | 🏗️ Building | File upload, storage, download |
| 8005 | [Notification](./notification/) | 🏗️ Building | Alerts, emails, real-time notifications |
| 8006 | [Monitoring](./monitoring/) | 🏗️ Building | System metrics, health aggregation |

---

## Quick Links

### Service Registry (Complete Documentation ✅)
**The star of the show** - manages external genomic services and performs async health monitoring.

- **[Service Registry README](./service-registry/README.md)** - Complete service documentation
  - Why FastAPI? (10x faster health checks)
  - Database schema and API endpoints
  - Background health check worker
  - Monitoring and troubleshooting

- **[Service Connection Guide](./service-registry/SERVICE_CONNECTION.md)** - Deep dive into external service integration
  - ILIFU GA4GH Starter Kit connection flow
  - Michigan Imputation Server integration
  - eLwazi MALI Node setup
  - Error handling and caching strategies

---

## Architecture Principles

### Database-per-Service

Each microservice has its own database for complete isolation:

```
PostgreSQL Instance (7 databases)
├── federated_imputation    (Django main app)
├── user_management_db      (User Service)
├── service_registry_db     (Service Registry) ← External services here
├── job_processing_db       (Job Processor)
├── file_management_db      (File Manager)
├── notification_db         (Notification)
└── monitoring_db           (Monitoring)
```

**Benefits:**
- ✅ Service independence
- ✅ Separate scaling
- ✅ Fault isolation
- ✅ Technology flexibility

### Async-First Design

All microservices use FastAPI's native async/await for non-blocking operations:

```python
# Example: Concurrent health checks in Service Registry
async def check_all_services():
    tasks = [check_service(s) for s in services]
    results = await asyncio.gather(*tasks)  # All at once!
```

**Performance Impact:**
- Django (sync): 10 services × 10s = 100+ seconds
- FastAPI (async): 10 services in ~10 seconds

### Lightweight & Fast

| Metric | Per Service | 6 Services Total |
|--------|-------------|------------------|
| Memory | 50-100 MB | ~300 MB |
| Startup | <1 second | <6 seconds |
| Dependencies | Minimal | FastAPI + SQLAlchemy |

**vs. Django monolith**: 75% less memory (300 MB vs 1.2 GB)

---

## Service Descriptions

### API Gateway (Port 8000) ⚠️ Planned

**Purpose**: Unified entry point for all client requests

**Responsibilities:**
- Request routing to appropriate microservices
- Authentication and authorization (JWT)
- Rate limiting (Redis-backed)
- CORS handling
- Load balancing

**Status**: Architectural planning phase
**Expected**: Q2 2026

---

### User Service (Port 8001) 🏗️ Building

**Purpose**: User management and authentication

**Responsibilities:**
- User registration and login
- JWT token management
- User profiles and roles
- Service-specific permissions
- Audit logging for user actions

**Database**: `user_management_db`
**Tables**: users, roles, permissions, audit_logs

**Status**: Core implementation in progress
**Expected**: Q1 2026

---

### Service Registry (Port 8002) ✅ Production

**Purpose**: External genomic service management and health monitoring

**Responsibilities:**
- Register and manage external imputation services (ILIFU, Michigan, etc.)
- Async health checks every 5 minutes
- Concurrent checking of multiple services
- Reference panel management
- Service discovery for other microservices

**Database**: `service_registry_db`
**Tables**: imputation_services, reference_panels, service_health_logs

**Status**: ✅ Production - fully documented
**Documentation**: [Complete README](./service-registry/README.md)

**Key Features:**
- 10x faster health checks (async vs sync)
- Intelligent caching (15min/1min/10s)
- Concurrent external service monitoring
- GA4GH WES, Michigan, DNAstack support

---

### Job Processor (Port 8003) 🏗️ Building

**Purpose**: Imputation job lifecycle management

**Responsibilities:**
- Job submission to external services
- Status tracking and updates
- Job templates and batch operations
- Scheduled job execution
- Job cancellation and cleanup

**Database**: `job_processing_db`
**Tables**: jobs, job_status, job_templates, scheduled_jobs

**Integrations:**
- Service Registry (get service info)
- File Manager (access input files)
- Notification (job status updates)

**Status**: Core implementation
**Expected**: Q1 2026

---

### File Manager (Port 8004) 🏗️ Building

**Purpose**: File upload, storage, and management

**Responsibilities:**
- File upload with validation
- Secure file storage
- File download and access control
- Result file management
- File metadata and checksums

**Database**: `file_management_db`
**Tables**: files, file_metadata, checksums

**Storage**: Local filesystem (future: S3-compatible)

**Status**: Basic implementation
**Expected**: Q1 2026

---

### Notification (Port 8005) 🏗️ Building

**Purpose**: Real-time notifications and alerts

**Responsibilities:**
- Email notifications (job completion, errors)
- Real-time WebSocket updates
- SMS alerts (future)
- Notification preferences
- Event-driven messaging

**Database**: `notification_db`
**Tables**: notifications, preferences, templates

**Technologies**:
- FastAPI WebSockets
- SMTP for email
- Redis pub/sub

**Status**: Planning phase
**Expected**: Q2 2026

---

### Monitoring (Port 8006) 🏗️ Building

**Purpose**: System-wide metrics and health aggregation

**Responsibilities:**
- Dashboard data aggregation
- Performance metrics collection
- Health check coordination
- Analytics and reporting
- System alerts

**Database**: `monitoring_db`
**Tables**: metrics, health_status, alerts

**Integrations**:
- All microservices (health data)
- Service Registry (service health)
- Prometheus/Grafana (future)

**Status**: Basic health aggregation
**Expected**: Q2 2026

---

## Inter-Service Communication

### Service Discovery

Microservices communicate via HTTP APIs using environment variables:

```yaml
# docker-compose.microservices.yml
environment:
  - SERVICE_REGISTRY_URL=http://service-registry:8002
  - USER_SERVICE_URL=http://user-service:8001
  - JOB_PROCESSOR_URL=http://job-processor:8003
  - FILE_MANAGER_URL=http://file-manager:8004
```

### Example Integration

**Job Processor queries Service Registry:**

```python
# job-processor/main.py
SERVICE_REGISTRY_URL = os.getenv('SERVICE_REGISTRY_URL', 'http://service-registry:8002')

async def get_service_info(service_id: int):
    """Get external service details from Service Registry."""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{SERVICE_REGISTRY_URL}/services/{service_id}")
        return response.json()
```

### Message Patterns

**Synchronous** (HTTP REST):
- Request/response for immediate data
- Example: Get user info, check service health

**Asynchronous** (Planned - Redis/RabbitMQ):
- Event-driven messaging
- Example: Job completed → Notify user
- Example: File uploaded → Process job

---

## Development

### Running Individual Services

Each microservice can run independently:

```bash
# Navigate to service directory
cd microservices/service-registry

# Install dependencies
pip install -r requirements.txt

# Set environment
export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/service_registry_db

# Run service
uvicorn main:app --reload --port 8002
```

### Running All Microservices

```bash
# Using docker-compose
docker-compose -f docker-compose.microservices.yml up -d

# Check health
curl http://localhost:8002/health  # Service Registry
curl http://localhost:8001/health  # User Service
# etc.
```

### Accessing API Documentation

FastAPI auto-generates interactive API docs:

- **Service Registry**: http://localhost:8002/docs
- **User Service**: http://localhost:8001/docs
- **Job Processor**: http://localhost:8003/docs
- etc.

---

## Monitoring Microservices

### Health Checks

```bash
# Check all services
for port in 8001 8002 8003 8004 8005 8006; do
  echo "Checking port $port..."
  curl -s http://localhost:$port/health | jq .status
done
```

### Docker Status

```bash
# View running services
docker ps --filter "name=microservices"

# View logs
docker logs service-registry -f
docker logs user-service -f
```

### Database Connections

```bash
# List databases
docker-compose exec postgres psql -U postgres -l

# Connect to Service Registry database
docker-compose exec postgres psql -U postgres -d service_registry_db
```

---

## Troubleshooting

### Service Won't Start

**Check logs:**
```bash
docker logs service-registry 2>&1 | grep -i error
```

**Common issues:**
- Database connection failure (check DATABASE_URL)
- Port already in use (check `docker ps`)
- Missing dependencies (rebuild image)

### Service Unhealthy

**Check health endpoint:**
```bash
curl http://localhost:8002/health
```

**Check database connection:**
```bash
docker-compose exec service-registry python -c "from main import engine; engine.connect()"
```

### Inter-Service Communication Issues

**Test connectivity:**
```bash
# From one service to another
docker-compose exec service-registry curl http://user-service:8001/health
```

**Check DNS resolution:**
```bash
docker-compose exec service-registry ping user-service
```

---

## Migration Status

### Current State (October 2025)

| Service | Status | Completion |
|---------|--------|------------|
| Service Registry | ✅ Production | 100% |
| User Service | 🏗️ Core features | 60% |
| Job Processor | 🏗️ Basic implementation | 40% |
| File Manager | 🏗️ Basic implementation | 40% |
| Notification | ⚠️ Planning | 20% |
| Monitoring | ⚠️ Planning | 30% |
| API Gateway | ⚠️ Design phase | 10% |

### Roadmap

**Q4 2025:**
- ✅ Service Registry production
- 🎯 User Service core features
- 🎯 Job Processor MVP

**Q1 2026:**
- User Service production
- Job Processor production
- File Manager production

**Q2 2026:**
- Notification service
- Monitoring service
- API Gateway alpha

**Q3 2026:**
- Full microservices production
- Django app becomes thin client
- Event-driven architecture

---

## Contributing

### Adding a New Microservice

1. Create service directory:
   ```bash
   mkdir microservices/my-service
   cd microservices/my-service
   ```

2. Create basic structure:
   ```
   my-service/
   ├── main.py          # FastAPI application
   ├── models.py        # SQLAlchemy models
   ├── schemas.py       # Pydantic schemas
   ├── Dockerfile       # Container definition
   ├── requirements.txt # Dependencies
   └── README.md        # Documentation
   ```

3. Implement service:
   - Follow existing patterns (see Service Registry)
   - Use async/await for I/O operations
   - Include health check endpoint
   - Add API documentation

4. Add to docker-compose:
   ```yaml
   my-service:
     build: ./microservices/my-service
     ports:
       - "800X:800X"
     environment:
       - DATABASE_URL=postgresql://...
   ```

5. Document service:
   - Create comprehensive README
   - Document API endpoints
   - Add troubleshooting guide
   - Update this index

---

## Resources

### Documentation

- [Service Registry (Complete)](./service-registry/README.md)
- [Service Connection Guide](./service-registry/SERVICE_CONNECTION.md)
- [Architecture Overview](../architecture/DJANGO_FASTAPI_ARCHITECTURE.md)
- [Quick Reference](../architecture/ARCHITECTURE_CONTEXT.md)

### Code Templates

- [FastAPI Service Template](./service-registry/main.py) - Use Service Registry as reference
- [Database Models](./service-registry/main.py#L35-L94)
- [API Endpoints](./service-registry/main.py#L324-L621)
- [Background Workers](./service-registry/main.py#L307-L322)

### External Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Async](https://docs.sqlalchemy.org/en/14/orm/extensions/asyncio.html)
- [Microservices Patterns](https://microservices.io/patterns/)
- [Docker Compose](https://docs.docker.com/compose/)

---

**Last Updated**: 2025-10-04
**Status**: Living Document
**Maintainer**: Platform Team

For detailed documentation of each service, click on the service name in the table above or browse the individual service directories.
