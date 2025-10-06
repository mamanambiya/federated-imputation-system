# Microservices Architecture Design
## Federated Genomic Imputation Platform

## 🎯 Overview

This document outlines the transformation of the monolithic Django application into a microservices architecture while preserving all existing functionality, UX enhancements, and maintaining backwards compatibility.

## 🏗️ Current Monolithic Structure Analysis

### **Current Django App Structure:**
```
federated-imputation-central/
├── federated_imputation/          # Django project settings
├── imputation/                    # Main Django app (MONOLITH)
│   ├── models.py                  # All business logic models
│   ├── views.py                   # All API endpoints
│   ├── serializers.py             # All data serialization
│   ├── tasks.py                   # Celery async tasks
│   ├── services/                  # External service integrations
│   ├── monitoring.py              # System monitoring
│   └── job_management.py          # Job processing logic
├── frontend/                      # React TypeScript frontend
└── docker-compose.yml             # Container orchestration
```

### **Business Domains Identified:**
1. **User Management** - Authentication, authorization, profiles, roles
2. **Service Registry** - External service management, health checks
3. **Job Processing** - Job lifecycle, status tracking, execution
4. **File Management** - Upload, storage, download, result files
5. **Notification System** - Real-time notifications, alerts
6. **Monitoring & Analytics** - System metrics, dashboard data
7. **API Gateway** - Request routing, authentication, rate limiting

## 🎯 Microservices Decomposition

### **Service 1: API Gateway Service**
**Port:** 8000 (External facing)
**Responsibilities:**
- Unified client access point
- Request routing to appropriate microservices
- Authentication and authorization
- Rate limiting and request validation
- CORS handling
- Load balancing

**Technology Stack:**
- **Framework:** FastAPI (Python) or Kong/Nginx
- **Database:** Redis (for rate limiting, sessions)
- **Authentication:** JWT tokens, session management

### **Service 2: User Management Service**
**Port:** 8001
**Responsibilities:**
- User authentication and authorization
- User profiles and role management
- Service access permissions
- Audit logging for user actions

**Data Models:**
- User, UserProfile, UserRole
- ServicePermission, ServiceUserGroup
- AuditLog (user-related)

**API Endpoints:**
- `/auth/login`, `/auth/logout`, `/auth/user`
- `/users/`, `/users/{id}/`, `/users/{id}/roles/`
- `/permissions/`, `/groups/`

### **Service 3: Service Registry Service**
**Port:** 8002
**Responsibilities:**
- External imputation service management
- Service health monitoring and status
- Reference panel management
- Service discovery and configuration

**Data Models:**
- ImputationService, ReferencePanel
- ServiceConfiguration, UserServiceAccess

**API Endpoints:**
- `/services/`, `/services/{id}/health/`
- `/reference-panels/`, `/services/{id}/panels/`
- `/services/{id}/sync/`

### **Service 4: Job Processing Service**
**Port:** 8003
**Responsibilities:**
- Job lifecycle management
- Job submission and execution
- Status tracking and updates
- Job templates and batch operations

**Data Models:**
- ImputationJob, JobStatusUpdate
- JobTemplate, JobBatch, ScheduledJob

**API Endpoints:**
- `/jobs/`, `/jobs/{id}/`, `/jobs/{id}/status/`
- `/jobs/{id}/cancel/`, `/jobs/batch/`
- `/templates/`, `/scheduled/`

### **Service 5: File Management Service**
**Port:** 8004
**Responsibilities:**
- File upload and storage
- Result file management
- File download and access control
- File metadata and checksums

**Data Models:**
- ResultFile, FileMetadata

**API Endpoints:**
- `/files/upload/`, `/files/{id}/download/`
- `/files/{id}/`, `/jobs/{job_id}/files/`

### **Service 6: Notification Service**
**Port:** 8005
**Responsibilities:**
- Real-time notifications
- Email and system alerts
- Notification preferences
- Event-driven messaging

**API Endpoints:**
- `/notifications/`, `/notifications/preferences/`
- WebSocket endpoints for real-time updates

### **Service 7: Monitoring & Analytics Service**
**Port:** 8006
**Responsibilities:**
- System metrics collection
- Dashboard data aggregation
- Performance monitoring
- Health checks coordination

**API Endpoints:**
- `/monitoring/metrics/`, `/monitoring/health/`
- `/dashboard/stats/`, `/analytics/`

### **Service 8: Frontend Service**
**Port:** 3000
**Responsibilities:**
- React application serving
- Static asset management
- Client-side routing
- UX component library

## 🔄 Inter-Service Communication

### **Communication Patterns:**

1. **Synchronous Communication (REST APIs):**
   - API Gateway ↔ All Services
   - Frontend ↔ API Gateway
   - Service Registry ↔ External Services

2. **Asynchronous Communication (Message Queue):**
   - Job Processing → Notification Service (job status updates)
   - File Management → Job Processing (file processing complete)
   - User Management → Audit Service (user actions)

3. **Event Streaming:**
   - Real-time job status updates
   - System health events
   - User activity tracking

### **Communication Flow Diagram:**

```
┌──────────┐
│ Frontend │
└────┬─────┘
     │ HTTP/REST
     ↓
┌─────────────┐
│ API Gateway │
└─────┬───────┘
      │
      ├─────→ [User Service]      ──→ PostgreSQL (user_db)
      │                            ↓
      ├─────→ [Service Registry]  ──→ PostgreSQL (service_db)
      │       │                    ↓
      │       └──→ External APIs (Health Checks)
      │
      ├─────→ [Job Processor]     ──→ PostgreSQL (job_db)
      │       │                    │
      │       ├──→ Celery Queue ───┤
      │       │                    ↓
      │       └──→ Worker Pool ────→ External Services (H3Africa, etc)
      │
      ├─────→ [File Manager]      ──→ PostgreSQL (file_db)
      │       │                    ↓
      │       └──→ S3/Local Storage
      │
      ├─────→ [Notification]      ──→ PostgreSQL (notif_db)
      │       │                    │
      │       └──→ WebSocket ──────→ Frontend (Real-time)
      │
      └─────→ [Monitoring]        ──→ InfluxDB (metrics)
              │                    ↓
              └──→ Prometheus/Grafana

Message Queue (Redis/RabbitMQ):
  job.status.updated  ────→  Notification Service
  file.upload.done    ────→  Job Processor
  service.health      ────→  Monitoring
```

### **Message Queue Architecture:**
```
Redis Streams / RabbitMQ
├── job.status.updated
├── file.upload.completed
├── service.health.changed
├── user.action.logged
└── notification.send
```

## 🛡️ Security Architecture

### **Authentication Flow:**

```
┌──────┐                                      ┌────────────────┐
│ User │                                      │  User Service  │
└──┬───┘                                      └────────┬───────┘
   │                                                   │
   │ 1. POST /auth/login                              │
   │    {username, password}                          │
   ├──────────────────────────────────────────────────→
   │                                                   │
   │                          2. Validate credentials │
   │                             Check password hash  │
   │                                                   │
   │ 3. Return JWT Token                              │
   │    {access_token, refresh_token}                 │
   │←──────────────────────────────────────────────────
   │
   │ 4. API Request with token                 ┌─────────────┐
   │    Authorization: Bearer <JWT>            │ API Gateway │
   ├──────────────────────────────────────────→└──────┬──────┘
   │                                                   │
   │                                    5. Validate JWT
   │                                       Decode & verify
   │                                                   │
   │                                    6. Route to service
   │                                       with user context
   │                                                   ↓
   │                                          [Microservice]
   │                                                   │
   │ 7. Response                                       │
   │←──────────────────────────────────────────────────

Service-to-Service Authentication:
  [Service A] ──→ Internal Token ──→ [Service B]
             (or mTLS certificates)
```

### **Authorization:**
- Role-based access control (RBAC)
- Service-level permissions
- Resource-level access control

### **Security Measures:**
- TLS/SSL for all communications
- API rate limiting
- Input validation and sanitization
- Secrets management with environment variables

## 💾 Data Management Strategy

### **Database-per-Service Pattern:**
```
├── api_gateway_db (Redis)
├── user_management_db (PostgreSQL)
├── service_registry_db (PostgreSQL)
├── job_processing_db (PostgreSQL)
├── file_management_db (PostgreSQL)
├── notification_db (PostgreSQL)
└── monitoring_db (PostgreSQL + InfluxDB)
```

### **Data Consistency:**
- **Eventual Consistency:** For non-critical data
- **Saga Pattern:** For distributed transactions
- **Event Sourcing:** For audit trails and job history

### **Shared Data Handling:**
- User ID references across services
- Service ID references for jobs and files
- Event-driven data synchronization

## 🐳 Container Architecture

### **Updated Docker Compose Structure:**
```yaml
version: '3.8'
services:
  # Infrastructure
  postgres:          # Shared PostgreSQL cluster
  redis:             # Message queue and caching
  nginx:             # Load balancer
  
  # Microservices
  api-gateway:       # Port 8000
  user-service:      # Port 8001
  service-registry:  # Port 8002
  job-processor:     # Port 8003
  file-manager:      # Port 8004
  notification:      # Port 8005
  monitoring:        # Port 8006
  frontend:          # Port 3000
  
  # Workers
  celery-worker:     # Async task processing
  celery-beat:       # Scheduled tasks
```

## 🔄 Migration Strategy

### **Phase 1: Preparation (Week 1)**
1. Create microservice project structure
2. Set up shared infrastructure (databases, message queue)
3. Implement API Gateway with routing to monolith
4. Create service interfaces and contracts

### **Phase 2: Service Extraction (Weeks 2-4)**
1. Extract User Management Service
2. Extract Service Registry Service
3. Extract File Management Service
4. Update API Gateway routing

### **Phase 3: Core Services (Weeks 5-7)**
1. Extract Job Processing Service
2. Extract Notification Service
3. Extract Monitoring Service
4. Implement inter-service communication

### **Phase 4: Testing & Optimization (Week 8)**
1. End-to-end testing
2. Performance optimization
3. Security validation
4. Documentation updates

### **Phase 5: Deployment (Week 9)**
1. Production deployment
2. Monitoring setup
3. Rollback procedures
4. Team training

## 🎨 UX Pattern Preservation

### **Shared UI Components:**
- Notification system components preserved across all services
- Loading states and skeleton loaders maintained
- Accessibility helpers available to all frontend components
- Consistent error handling and user feedback

### **Frontend Architecture:**
```
frontend/
├── src/
│   ├── components/
│   │   ├── Common/           # Shared UX components
│   │   │   ├── NotificationSystem.tsx
│   │   │   ├── LoadingComponents.tsx
│   │   │   └── AccessibilityHelpers.tsx
│   │   ├── Services/         # Service-specific components
│   │   ├── Jobs/             # Job-specific components
│   │   └── Users/            # User-specific components
│   ├── contexts/
│   │   ├── ApiContext.tsx    # Updated for microservices
│   │   ├── AuthContext.tsx   # Preserved
│   │   └── NotificationContext.tsx
│   └── services/
│       ├── apiGateway.ts     # Centralized API calls
│       ├── userService.ts    # User-related APIs
│       ├── jobService.ts     # Job-related APIs
│       └── fileService.ts    # File-related APIs
```

## 📊 Monitoring & Observability

### **Health Checks:**
- Individual service health endpoints
- Aggregated health status via Monitoring Service
- Dependency health tracking

### **Metrics Collection:**
- Service-level metrics (response time, error rate)
- Business metrics (job completion rate, user activity)
- Infrastructure metrics (CPU, memory, disk)

### **Logging Strategy:**
- Centralized logging with correlation IDs
- Structured logging (JSON format)
- Log aggregation and analysis

### **Alerting:**
- Service down alerts
- Performance degradation alerts
- Business metric alerts (high failure rate)

## 🚀 Deployment Strategy

### **Container Orchestration:**
- Docker Compose for development
- Kubernetes for production (future)
- Health checks and auto-restart policies

### **Load Balancing:**
- Nginx for external load balancing
- Round-robin for service discovery
- Circuit breakers for resilience

### **Scaling Strategy:**
- Horizontal scaling for stateless services
- Database connection pooling
- Caching strategies (Redis)

## 📈 Benefits of Microservices Architecture

### **Technical Benefits:**
- **Scalability:** Scale individual services based on demand
- **Resilience:** Failure isolation and graceful degradation
- **Technology Diversity:** Use best tools for each service
- **Development Velocity:** Independent development and deployment

### **Business Benefits:**
- **Faster Feature Delivery:** Parallel development teams
- **Better Resource Utilization:** Optimize each service independently
- **Improved Maintainability:** Smaller, focused codebases
- **Enhanced Security:** Service-level security boundaries

## 🎯 Success Metrics

### **Performance Metrics:**
- API response times < 200ms (95th percentile)
- Service availability > 99.9%
- Job processing throughput maintained or improved

### **Development Metrics:**
- Deployment frequency increased
- Lead time for changes reduced
- Mean time to recovery improved

### **User Experience Metrics:**
- All existing functionality preserved
- UX enhancements maintained across services
- User satisfaction scores maintained or improved

This microservices architecture provides a robust, scalable foundation for the Federated Genomic Imputation Platform while preserving all existing functionality and UX enhancements.
