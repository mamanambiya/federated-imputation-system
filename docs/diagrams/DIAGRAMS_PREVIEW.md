# Architecture Diagrams - Preview

**Open this file in VS Code and press `Ctrl+Shift+V` to preview all diagrams!**

---

## 1. Architecture Overview

Complete system architecture with all microservices, data layers, and external APIs.

```mermaid
graph TB
    subgraph "Client Layer"
        Browser["🌐 Web Browser<br/>React Frontend<br/>Port 3000"]
    end

    subgraph "Gateway Layer"
        Gateway["⚡ API Gateway<br/>FastAPI<br/>Port 8000<br/><br/>- Request Routing<br/>- Authentication<br/>- Rate Limiting"]
    end

    subgraph "Microservices Layer"
        UserService["👤 User Service<br/>Port 8001<br/><br/>- Authentication<br/>- User Management<br/>- Permissions"]

        ServiceRegistry["📋 Service Registry<br/>Port 8002<br/><br/>- Service Discovery<br/>- Health Checks<br/>- Panel Management"]

        JobProcessor["⚙️ Job Processor<br/>Port 8003<br/><br/>- Job Creation<br/>- Status Tracking<br/>- Queue Management"]

        FileManager["📁 File Manager<br/>Port 8004<br/><br/>- File Upload<br/>- Storage<br/>- Downloads"]

        Monitoring["📊 Monitoring<br/>Port 8005<br/><br/>- System Metrics<br/>- Dashboard Stats<br/>- Health Aggregation"]
    end

    subgraph "Worker Layer"
        CeleryWorker["🔄 Celery Worker<br/><br/>- Job Processing<br/>- Michigan API Calls<br/>- Result Retrieval"]
    end

    subgraph "Data Layer"
        PostgreSQL[("🗄️ PostgreSQL<br/>Port 5432<br/><br/>- user_db<br/>- service_registry_db<br/>- job_processing_db<br/>- file_management_db")]

        Redis[("⚡ Redis<br/>Port 6379<br/><br/>- Task Queue<br/>- Cache<br/>- Sessions")]
    end

    subgraph "External Services"
        MichiganAPI["🧬 Michigan Imputation<br/>Server<br/><br/>Afrigen-D / TopMed<br/>Cloudgene API"]

        H3AfricaAPI["🌍 H3Africa<br/>Imputation Server<br/><br/>Custom API"]
    end

    subgraph "Storage"
        FileStorage["💾 File Storage<br/><br/>- Input VCF Files<br/>- Result Files<br/>- Temporary Files"]
    end

    Browser -->|"HTTP/HTTPS<br/>Port 3000"| Gateway
    Gateway -->|"/api/auth/*"| UserService
    Gateway -->|"/api/services/*"| ServiceRegistry
    Gateway -->|"/api/jobs/*"| JobProcessor
    Gateway -->|"/api/files/*"| FileManager
    Gateway -->|"/api/dashboard/*"| Monitoring

    UserService -->|SQL| PostgreSQL
    ServiceRegistry -->|SQL| PostgreSQL
    JobProcessor -->|SQL| PostgreSQL
    FileManager -->|SQL| PostgreSQL
    Monitoring -->|SQL| PostgreSQL

    JobProcessor -->|"Enqueue Task"| Redis
    Redis -->|"Task Queue"| CeleryWorker

    CeleryWorker -->|"Get Job Details"| JobProcessor
    CeleryWorker -->|"Get Panel Info"| ServiceRegistry
    CeleryWorker -->|"Store Files"| FileStorage
    CeleryWorker -->|"Update Status"| JobProcessor

    CeleryWorker -->|"Submit Job<br/>refpanel: apps@{id}@{ver}"| MichiganAPI
    CeleryWorker -->|"Submit Job"| H3AfricaAPI

    FileManager -->|"Read/Write"| FileStorage

    Monitoring -.->|"Health Checks"| UserService
    Monitoring -.->|"Health Checks"| ServiceRegistry
    Monitoring -.->|"Health Checks"| JobProcessor
    Monitoring -.->|"Health Checks"| FileManager

    ServiceRegistry -.->|"Health Check"| MichiganAPI
    ServiceRegistry -.->|"Health Check"| H3AfricaAPI
    ServiceRegistry -.->|"Sync Panels"| MichiganAPI

    style Browser fill:#e1f5ff
    style Gateway fill:#fff3e0
    style UserService fill:#f3e5f5
    style ServiceRegistry fill:#e8f5e9
    style JobProcessor fill:#fff9c4
    style FileManager fill:#fce4ec
    style Monitoring fill:#e0f2f1
    style CeleryWorker fill:#ffe0b2
    style PostgreSQL fill:#e3f2fd
    style Redis fill:#ffebee
    style MichiganAPI fill:#f1f8e9
    style H3AfricaAPI fill:#f1f8e9
    style FileStorage fill:#fafafa
```

---

## 2. Job Submission Flow

Complete job submission workflow from user login to Michigan API submission.

**Key Details:** Shows correct field names (`service_id`, `reference_panel_id`) and Cloudgene format handling.

```mermaid
sequenceDiagram
    participant User as 👤 User
    participant Frontend as 🌐 Frontend
    participant Gateway as ⚡ Gateway
    participant UserSvc as 👤 User Service
    participant JobProc as ⚙️ Job Processor
    participant SvcReg as 📋 Service Registry
    participant Worker as 🔄 Worker
    participant Michigan as 🧬 Michigan API

    Note over User,Michigan: Job Submission with Cloudgene Format

    rect rgb(240, 248, 255)
        Note over User,UserSvc: 1. Authentication
        User->>Frontend: Navigate to /jobs/new
        Frontend->>Gateway: GET /api/auth/user/
        Gateway->>UserSvc: GET /auth/user/
        UserSvc-->>Frontend: User authenticated
    end

    rect rgb(245, 255, 245)
        Note over User,SvcReg: 2. Service Discovery
        Frontend->>Gateway: GET /api/services/discover/
        Gateway->>SvcReg: GET /services/discover/
        SvcReg-->>Frontend: H3Africa Service (ID: 7)

        Frontend->>Gateway: GET /api/services/7/panels/
        Gateway->>SvcReg: GET /services/7/panels/
        Note right of SvcReg: Panel: apps@h3africa-v6hc-s@1.0.0
        SvcReg-->>Frontend: Reference panels
    end

    rect rgb(255, 255, 240)
        Note over User,JobProc: 3. Job Submission
        User->>Frontend: Upload VCF + Select Service/Panel
        Note right of Frontend: service_id: 7<br/>reference_panel_id: 2
        Frontend->>Gateway: POST /api/jobs/ (FormData)
        Gateway->>JobProc: POST /jobs/
        JobProc-->>Frontend: Job created ✅
    end

    rect rgb(255, 245, 240)
        Note over Worker,Michigan: 4. Worker Processing
        Worker->>SvcReg: GET /panels/2
        Note right of Worker: Fetch Cloudgene format
        SvcReg-->>Worker: apps@h3africa-v6hc-s@1.0.0

        Worker->>Michigan: POST with refpanel
        Note right of Michigan: Cloudgene format validated
        Michigan-->>Worker: Job submitted
        Worker->>JobProc: Update status = 'queued'
    end
```

---

## 3. Authentication Flow

Login workflow with JWT generation and session management.

**Credentials:** admin / admin123 (Fixed 2025-10-06)

```mermaid
sequenceDiagram
    participant User as 👤 User
    participant Frontend as 🌐 Frontend
    participant Gateway as ⚡ Gateway
    participant UserSvc as 👤 User Service
    participant DB as 🗄️ PostgreSQL
    participant Redis as ⚡ Redis

    Note over User,Redis: Authentication Flow - Fixed 2025-10-06

    rect rgb(240, 248, 255)
        Note over User,DB: Login Phase
        User->>Frontend: Enter admin / admin123
        Frontend->>Gateway: POST /api/auth/login/
        Gateway->>UserSvc: POST /auth/login/

        UserSvc->>DB: SELECT * FROM users<br/>WHERE username='admin'
        DB-->>UserSvc: User record with hash

        UserSvc->>UserSvc: Verify password (bcrypt)
        Note right of UserSvc: Hash: $2b$12$PoAwZYURX...

        UserSvc->>UserSvc: Generate JWT token
        Note right of UserSvc: JWT payload:<br/>user_id: 2<br/>username: admin<br/>exp: 24h

        UserSvc->>Redis: Store session
        UserSvc-->>Gateway: Token + user data
        Gateway-->>Frontend: 200 OK
        Frontend-->>User: Redirect to dashboard ✅
    end

    rect rgb(245, 255, 245)
        Note over User,Redis: Authenticated Request
        User->>Frontend: Navigate to /jobs/new
        Frontend->>Gateway: GET /api/jobs/<br/>Authorization: Bearer {token}

        Gateway->>UserSvc: Validate token
        UserSvc->>UserSvc: Verify JWT signature
        UserSvc->>Redis: Check session
        Redis-->>UserSvc: Session data

        UserSvc-->>Gateway: User authenticated
        Gateway-->>Frontend: Protected content
        Frontend-->>User: Show job form
    end

    rect rgb(255, 245, 240)
        Note over User,Redis: Logout Phase
        User->>Frontend: Click logout
        Frontend->>Gateway: POST /api/auth/logout/
        Gateway->>UserSvc: POST /auth/logout/

        UserSvc->>Redis: DEL session:{token}
        UserSvc-->>Gateway: 200 OK
        Gateway-->>Frontend: Logged out
        Frontend->>Frontend: Clear localStorage
        Frontend-->>User: Redirect to login
    end
```

---

## 4. Michigan API Integration

Complete Michigan imputation workflow with Cloudgene format validation.

**Critical:** Panel format must be `apps@{app-id}@{version}`

```mermaid
graph LR
    A[👤 User Form] -->|service_id, reference_panel_id| B[⚙️ Job Processor]
    B -->|Validate Fields ✅| C[💾 Create Job Record]
    C -->|Enqueue Task| D[🔄 Celery Worker]
    D -->|GET /panels/2| E[📋 Service Registry]
    E -->|Return Panel Data| F[🔍 Extract Cloudgene Format]
    F -->|apps@h3africa-v6hc-s@1.0.0| G[🔧 Build API Params]
    G -->|POST refpanel| H[🧬 Michigan API]
    H -->|Validate Format ✅| I[⏳ Queue Job]
    I -->|Return Job ID| J[📊 Update Status]

    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    style E fill:#c8e6c9,stroke:#4caf50,stroke-width:2px
    style F fill:#fff9c4,stroke:#fbc02d,stroke-width:2px
    style H fill:#f1f8e9,stroke:#689f38,stroke-width:2px
```

**Critical Fixes:**
- ✅ Fix #1: Frontend field names → `service_id`, `reference_panel_id` (NewJob.tsx:286-287)
- ✅ Fix #2: Panel database stores Cloudgene format → `apps@h3africa-v6hc-s@1.0.0`
- ✅ Fix #3: Worker extracts panel name from Service Registry

---

## Viewing Options

### Option 1: VS Code Preview (This File!)
```bash
code docs/diagrams/DIAGRAMS_PREVIEW.md
# Press Ctrl+Shift+V to preview with rendered diagrams
```

### Option 2: Web Browser (Best!)
```bash
# Access at:
http://154.114.10.123:8888/view-diagrams.html
```

### Option 3: Mermaid Live Editor
```bash
# Copy diagram code and paste at:
https://mermaid.live
```

---

## System Status Summary

**As of 2025-10-06 13:03 UTC:**

✅ **Frontend:** Up, compiled successfully (Port 3000)
✅ **API Gateway:** Healthy (Port 8000)
✅ **User Service:** Healthy, authentication working (Port 8001)
✅ **Service Registry:** Healthy, 2 panels configured (Port 8002)
✅ **Job Processor:** Running, Michigan integration ready (Port 8003)
✅ **PostgreSQL:** 4 databases operational
✅ **Redis:** Task queue & sessions active

**Issues Resolved:**
- ✅ Frontend TypeScript errors (0 compilation errors)
- ✅ Authentication 403 errors (admin/admin123 working)
- ✅ Job submission HTTP 422 errors (field names fixed)

**Ready for Testing:**
- Login: http://154.114.10.123:3000 (admin/admin123)
- Job Submission: http://154.114.10.123:3000/jobs/new
- Michigan API: Cloudgene format support deployed

---

**Documentation:**
- [FIXES_COMPLETED_2025-10-06.md](../../FIXES_COMPLETED_2025-10-06.md)
- [DEPLOYMENT_STATUS_2025-10-06.md](../../DEPLOYMENT_STATUS_2025-10-06.md)
- [HOW_TO_VIEW.md](HOW_TO_VIEW.md)
- [DIAGRAMS_CREATED_2025-10-06.md](../../DIAGRAMS_CREATED_2025-10-06.md)
