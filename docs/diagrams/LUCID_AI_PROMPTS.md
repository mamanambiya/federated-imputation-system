# Lucid AI Diagram Generation Prompts

Prompts optimized for creating professional architecture diagrams using Lucid AI (LucidChart's AI diagram generator).

**Platform:** https://lucid.app/lucidchart (requires account)

---

## How to Use These Prompts

1. **Sign in to Lucid AI:**
   - Go to https://lucid.app/lucidchart
   - Create account or sign in
   - Click "Create New" → "Lucidchart"

2. **Use AI Diagram Generator:**
   - Look for "Generate with AI" or "Lucid AI" button
   - Copy and paste one of the prompts below
   - Click "Generate"
   - Lucid AI will create a professional diagram

3. **Customize:**
   - Edit shapes, colors, labels
   - Export as PNG, PDF, or SVG
   - Share via link

---

## Prompt 1: System Architecture Overview

**Purpose:** Complete microservices architecture diagram

**Copy this prompt:**

```
Create a layered architecture diagram for a Federated Genomic Imputation Platform with the following structure:

CLIENT LAYER:
- Web Browser (React Frontend on Port 3000)

GATEWAY LAYER:
- API Gateway (FastAPI on Port 8000) with these responsibilities:
  * Request Routing
  * Authentication
  * Rate Limiting

MICROSERVICES LAYER (show 5 services horizontally):
1. User Service (Port 8001): Authentication, User Management, Permissions
2. Service Registry (Port 8002): Service Discovery, Health Checks, Panel Management
3. Job Processor (Port 8003): Job Creation, Status Tracking, Queue Management
4. File Manager (Port 8004): File Upload, Storage, Downloads
5. Monitoring (Port 8005): System Metrics, Dashboard Stats, Health Aggregation

WORKER LAYER:
- Celery Worker: Job Processing, Michigan API Calls, Result Retrieval

DATA LAYER (show side by side):
- PostgreSQL (Port 5432) with 4 databases: user_db, service_registry_db, job_processing_db, file_management_db
- Redis (Port 6379): Task Queue, Cache, Sessions

EXTERNAL SERVICES:
- Michigan Imputation Server (Afrigen-D/TopMed with Cloudgene API)
- H3Africa Imputation Server (Custom API)

STORAGE:
- File Storage: Input VCF Files, Result Files, Temporary Files

CONNECTIONS (show with arrows):
- Browser connects to API Gateway via HTTP/HTTPS
- API Gateway routes to all microservices (/api/auth/ to User Service, /api/services/ to Service Registry, /api/jobs/ to Job Processor, /api/files/ to File Manager, /api/dashboard/ to Monitoring)
- All microservices connect to PostgreSQL via SQL
- Job Processor enqueues tasks to Redis
- Redis provides task queue to Celery Worker
- Celery Worker interacts with: Job Processor (get details, update status), Service Registry (get panel info), File Storage (store files)
- Celery Worker submits jobs to Michigan API and H3Africa API
- File Manager reads/writes to File Storage
- Monitoring service performs health checks on all microservices (show as dashed lines)
- Service Registry performs health checks on external APIs (show as dashed lines)

Color scheme: Use modern, professional colors. Make Client Layer light blue, Gateway orange, Microservices different pastel colors, Data Layer darker blue/red, External Services green.

Style: Clean, modern architecture diagram with clear labels and organized layout.
```

---

## Prompt 2: Job Submission Flow (Sequence Diagram)

**Purpose:** Step-by-step job submission workflow

**Copy this prompt:**

```
Create a detailed sequence diagram showing job submission flow for a genomic imputation platform. Show time flowing top to bottom with these participants (left to right):

PARTICIPANTS:
1. User (represented by user icon)
2. Frontend (React App)
3. API Gateway (Port 8000)
4. User Service (Port 8001)
5. Job Processor (Port 8003)
6. Service Registry (Port 8002)
7. Database (PostgreSQL)
8. Redis (Task Queue)
9. Celery Worker
10. Michigan API (External)

PHASE 1 - AUTHENTICATION (light blue background):
1. User navigates to /jobs/new
2. Frontend → API Gateway: GET /api/auth/user/
3. API Gateway → User Service: GET /auth/user/
4. User Service → Database: Query user_db
5. Database returns user data
6. User Service returns authenticated user
7. Frontend shows job form to user

PHASE 2 - SERVICE DISCOVERY (light green background):
1. User loads service options
2. Frontend → API Gateway: GET /api/services/discover/
3. API Gateway → Service Registry: GET /services/discover/
4. Service Registry → Database: Query service_registry_db
5. Database returns available services
6. Service Registry returns H3Africa Service (ID: 7)
7. Frontend → API Gateway: GET /api/services/7/panels/
8. API Gateway → Service Registry: GET /services/7/panels/
9. Service Registry → Database: Query reference_panels
10. Database returns panel: apps@h3africa-v6hc-s@1.0.0 (ID: 2)
11. Frontend shows service and panel options

PHASE 3 - JOB SUBMISSION (light yellow background):
1. User uploads VCF file and selects service/panel
2. Frontend → API Gateway: POST /api/jobs/ with FormData (service_id: 7, reference_panel_id: 2, input_file)
3. API Gateway → Job Processor: POST /jobs/
4. Job Processor → Database: INSERT INTO imputation_jobs
5. Database returns job ID
6. Job Processor → Redis: Enqueue task(job_id)
7. Redis confirms task queued
8. Job Processor returns 200 OK with job details
9. Frontend redirects user to job details page

PHASE 4 - WORKER PROCESSING (light orange background):
1. Redis → Celery Worker: Dequeue task(job_id)
2. Celery Worker → Job Processor: GET /jobs/{job_id}
3. Job Processor → Database: Query job details
4. Database returns job data
5. Celery Worker → Service Registry: GET /panels/2 (fetch Cloudgene format)
6. Service Registry → Database: Query reference_panel
7. Database returns panel name: apps@h3africa-v6hc-s@1.0.0
8. Service Registry returns panel info
9. Celery Worker builds Michigan API parameters with refpanel: apps@h3africa-v6hc-s@1.0.0
10. Celery Worker → Michigan API: POST /api/v2/jobs/submit/ (multipart/form-data with Cloudgene format panel)
11. Michigan API validates and queues job
12. Michigan API returns external_job_id
13. Celery Worker → Job Processor: PATCH /jobs/{id}/status/ (status: 'queued', external_job_id)
14. Job Processor → Database: UPDATE job status
15. Database confirms update

Add note boxes:
- After Phase 3: "✅ Fixed field names: service_id and reference_panel_id (previously caused HTTP 422 errors)"
- After Step 9 in Phase 4: "✅ Cloudgene format: apps@{app-id}@{version} (required by Michigan API)"

Use professional sequence diagram styling with clear participant labels, time-ordered messages, and color-coded phases.
```

---

## Prompt 3: Authentication Flow

**Purpose:** Login and JWT authentication workflow

**Copy this prompt:**

```
Create a sequence diagram showing authentication flow for a web application. Show these participants:

PARTICIPANTS:
1. User (with icon)
2. Frontend (React App)
3. API Gateway (Port 8000)
4. User Service (Port 8001)
5. PostgreSQL Database (user_db)
6. Redis (Session Store)

PHASE 1 - LOGIN (light blue background box):
Title: "Login Phase"
1. User navigates to http://154.114.10.123:3000
2. Frontend displays login form
3. User enters credentials: username "admin", password "admin123"
4. Frontend → API Gateway: POST /api/auth/login/ with JSON {"username":"admin", "password":"admin123"}
5. API Gateway → User Service: POST /auth/login/ (forwards credentials)
   Add note: "Gateway handles 307 redirect automatically"
6. User Service → PostgreSQL: SELECT * FROM users WHERE username='admin'
7. PostgreSQL returns user record with hashed_password
8. User Service verifies password using bcrypt
   Add note: "pwd_context.verify(password, hash)"
9. IF password valid:
   a. User Service generates JWT token
      Add note: "JWT payload: user_id: 2, username: admin, email: admin@example.com, roles: [], exp: 24h from now"
   b. User Service → PostgreSQL: UPDATE users SET last_login = now() WHERE id = 2
   c. PostgreSQL confirms update
   d. User Service → Redis: SETEX session:{token} 86400 {user_data}
   e. Redis confirms session stored
   f. User Service → API Gateway: 200 OK with {"access_token": "eyJhbGci...", "user": {...}}
   g. API Gateway → Frontend: Token + user data
   h. Frontend stores token in localStorage
   i. Frontend redirects user to dashboard
10. IF password invalid:
   a. User Service → API Gateway: 401 Unauthorized {"detail": "Invalid credentials"}
   b. API Gateway → Frontend: 401 error
   c. Frontend shows error message to user

PHASE 2 - AUTHENTICATED REQUEST (light green background box):
Title: "Authenticated Request Phase"
1. User navigates to /jobs/new
2. Frontend gets token from localStorage
3. Frontend → API Gateway: GET /api/jobs/ with Header "Authorization: Bearer {token}"
4. API Gateway extracts JWT token
5. API Gateway → User Service: GET /auth/user/ with Header "Authorization: Bearer {token}"
6. User Service verifies JWT signature
7. User Service checks token expiration
8. IF token valid:
   a. User Service → Redis: GET session:{token}
   b. IF session exists in Redis:
      - Redis returns session data
      - User Service → API Gateway: 200 OK + User data (from cache)
   c. IF session not in Redis:
      - User Service → PostgreSQL: SELECT * FROM users WHERE id = {user_id}
      - PostgreSQL returns user data
      - User Service → Redis: SETEX session:{token} 86400 {user_data}
      - User Service → API Gateway: 200 OK + User data
   d. API Gateway → Frontend: User authenticated
   e. Frontend shows protected content to user
9. IF token invalid/expired:
   a. User Service → API Gateway: 403 Forbidden {"detail": "Invalid or expired token"}
   b. API Gateway → Frontend: 403 error
   c. Frontend clears localStorage
   d. Frontend redirects to login page

PHASE 3 - LOGOUT (light orange background box):
Title: "Logout Phase"
1. User clicks logout button
2. Frontend → API Gateway: POST /api/auth/logout/ with Header "Authorization: Bearer {token}"
3. API Gateway → User Service: POST /auth/logout/
4. User Service → Redis: DEL session:{token}
5. Redis confirms session deleted
6. User Service → PostgreSQL: UPDATE users SET last_login = now() WHERE id = {user_id}
7. User Service → API Gateway: 200 OK {"message": "Logged out"}
8. API Gateway → Frontend: Success
9. Frontend clears localStorage
10. Frontend redirects to login page

Add a note box at bottom:
"Current Credentials:
Username: admin
Password: admin123
Email: admin@example.com
Role: Superuser
Password Hash: $2b$12$PoAwZYURX/BoI0x6DKeKGO56CVEWmE1/JIUfcnTT/bdHXNJ757.oC
JWT Expiration: 24 hours
Status: ✅ Fixed 2025-10-06"

Use professional sequence diagram style with clear swimlanes, color-coded phases, and decision branches.
```

---

## Prompt 4: Michigan API Integration Flowchart

**Purpose:** Detailed Michigan imputation workflow

**Copy this prompt:**

```
Create a horizontal flowchart showing Michigan API integration workflow. Use swimlanes for different system components:

SWIMLANE 1 - FRONTEND:
- Start: User Form (show form icon)
- User fills: service_id, reference_panel_id, uploads VCF file
  Add callout: "✅ Fixed: Using service_id and reference_panel_id (not 'service' and 'reference_panel')"

SWIMLANE 2 - API GATEWAY:
- Receives POST /api/jobs/
- Routes to Job Processor
- Returns response to frontend

SWIMLANE 3 - JOB PROCESSOR:
- Validate Form Fields
  Add decision diamond: "Fields valid?"
  - Yes path continues
  - No path returns 422 error
  Add callout: "Expects: service_id (str), reference_panel_id (str), input_file (UploadFile)"
- Create Job Record in database
- Enqueue Celery Task
- Return job ID to gateway

SWIMLANE 4 - SERVICE REGISTRY:
- Receives GET /panels/{id} request from worker
- Query Database for panel
- Return Panel Data
  Add callout: "✅ Panel format: apps@h3africa-v6hc-s@1.0.0 (Cloudgene format stored in DB)"

SWIMLANE 5 - CELERY WORKER:
- Dequeue Task
- Fetch Job Details from Job Processor
- Query Service Registry: GET /panels/2
- Receive panel data
- Extract Cloudgene Format from panel 'name' field
  Add callout: "✅ Worker extracts: panel_info['name'] → 'apps@h3africa-v6hc-s@1.0.0'"
- Build Michigan API Parameters:
  Show box with:
  ```
  data = {
    'input-format': 'vcf',
    'refpanel': 'apps@h3africa-v6hc-s@1.0.0',  ← Cloudgene format!
    'build': 'hg38',
    'phasing': 'eagle',
    'population': 'mixed',
    'mode': 'imputation'
  }
  ```
- Submit to Michigan API

SWIMLANE 6 - MICHIGAN API (EXTERNAL):
- Receive POST request
- Validate Cloudgene Format
  Add decision diamond: "Format valid?"
  - Yes: "Format: apps@{app-id}@{version} ✅"
  - No: "Rejects: Database IDs, plain names ❌"
- Queue Job for Processing
- Return external_job_id

SWIMLANE 7 - STATUS UPDATE:
- Worker receives job ID from Michigan
- Update Job Status in database
- Status: 'queued', external_job_id stored
- Monitor job progress (shown with loop back arrow)
- When complete: Retrieve results
- Final status: 'completed'
- End

Add 3 prominent callout boxes on the side:
1. "⚠️ CRITICAL FIX #1: Frontend Field Names"
   "Lines: NewJob.tsx:286-287"
   "Before: formData.append('service', ...)"
   "After: formData.append('service_id', ...) ✅"
   "Previously caused HTTP 422 errors"

2. "⚠️ CRITICAL FIX #2: Panel Database Format"
   "Table: service_registry_db.reference_panels"
   "ID: 2"
   "Name: apps@h3africa-v6hc-s@1.0.0 ✅"
   "Must be Cloudgene format"

3. "⚠️ CRITICAL FIX #3: Worker Panel Fetch"
   "File: worker.py lines 109-131"
   "Fetches panel from Service Registry"
   "Extracts 'name' field (Cloudgene format)"
   "Passes correct format to Michigan API ✅"

Use professional flowchart style with:
- Clear swimlanes with labels
- Rounded rectangles for processes
- Diamonds for decisions
- Cylinders for databases
- Callout boxes for important notes
- Color coding: Green for fixed/correct, Yellow for validation points, Red for errors
- Arrows showing data flow direction
```

---

## Prompt 5: Deployment Status Dashboard

**Purpose:** Current system status visualization

**Copy this prompt:**

```
Create a modern system status dashboard diagram showing deployment status as of 2025-10-06. Use a grid/card layout:

HEADER SECTION (top, full width):
Large banner: "🎯 SYSTEM STATUS: ✅ ALL OPERATIONAL"
Subtitle: "Last Updated: 2025-10-06 13:03 UTC"
Background: Green gradient

ROW 1 - FRONTEND & GATEWAY:
Card 1: "🌐 Frontend (Port 3000)"
- Status: ✅ Up 2 minutes
- Build ID: daa8ad97ea2c
- Image: federated-imputation-frontend:latest
- TypeScript: ✅ Compiled successfully (0 errors)
- React: ✅ Serving
- URL: http://154.114.10.123:3000
- Critical Fixes Applied:
  * Field names: service_id ✅
  * Field names: reference_panel_id ✅
  * Type definitions updated ✅
Background: Light blue

Card 2: "⚡ API Gateway (Port 8000)"
- Status: ✅ Up 3 days (healthy)
- Routes configured:
  * /api/auth/* → user-service ✅
  * /api/services/* → service-registry ✅
  * /api/jobs/* → job-processor ✅
  * /api/dashboard/* → monitoring ✅
- Features: JWT validation, CORS, Rate limiting ✅
Background: Orange

ROW 2 - MICROSERVICES:
Card 3: "👤 User Service (Port 8001)"
- Status: ✅ Up 3 minutes (healthy)
- Database: user_db ✅
- Authentication: ✅ Working
- Admin Credentials:
  * Username: admin ✅
  * Password: admin123 ✅
  * Role: Superuser ✅
Background: Purple

Card 4: "📋 Service Registry (Port 8002)"
- Status: ✅ Up 15 hours (healthy)
- Database: service_registry_db ✅
- Panels configured:
  * ID 1: apps@1000g-phase-3-v5@1.0.0 ✅
  * ID 2: apps@h3africa-v6hc-s@1.0.0 ✅
- Michigan Service: ID 7 ✅
Background: Green

Card 5: "⚙️ Job Processor (Port 8003)"
- Status: ✅ Up 15 hours (running)
- Database: job_processing_db ✅
- Field Validation:
  * service_id: str ✅
  * reference_panel_id: str ✅
- Michigan Integration: ✅ Ready
- Cloudgene Support: ✅ Deployed
Background: Yellow

ROW 3 - WORKER & DATA:
Card 6: "🔄 Celery Worker"
- Status: ✅ Running
- File: worker.py
- Michigan API Logic: Lines 109-131 ✅
- Cloudgene Format Handling: ✅
- Panel Fetch: GET /panels/{id} ✅
Background: Orange

Card 7: "🗄️ PostgreSQL"
- Status: ✅ Running
- Databases:
  * user_db ✅
  * service_registry_db ✅
  * job_processing_db ✅
  * file_management_db ✅
- Admin user: ID 2 ✅
- Michigan service: ID 7 ✅
- Reference panels: 2 configured ✅
Background: Blue

Card 8: "⚡ Redis"
- Status: ✅ Running (Port 6379)
- Task Queue: ✅ Active
- Session Storage: ✅ Active
- Cache: ✅ Active
Background: Red

ROW 4 - EXTERNAL SERVICES:
Card 9: "🧬 Michigan API"
- Endpoint: https://impute.afrigen-d.org
- Status: ✅ Accessible
- Format: Cloudgene (apps@{app-id}@{version})
- Validation: ✅ Working
- Integration: ✅ Ready
Background: Light green

ROW 5 - ISSUES RESOLVED (3 columns):
Card 10: "Issue #1: Frontend TypeScript Errors"
- Problem: ❌ 20+ compilation errors
- Root Cause: Outdated container source
- Solution: ✅ Rebuilt Docker image
- Status: ✅ RESOLVED
- Build: daa8ad97ea2c
- Errors: 0 ✅
Background: Light green with green checkmark

Card 11: "Issue #2: Authentication 403 Errors"
- Problem: ❌ Login failed
- Root Cause: Unknown password hash
- Solution: ✅ Reset admin password
- Status: ✅ RESOLVED
- Password: admin123 ✅
- Login: ✅ Working
Background: Light green with green checkmark

Card 12: "Issue #3: Job Submission HTTP 422"
- Problem: ❌ Field name mismatch
- Root Cause: 'service' vs 'service_id'
- Solution: ✅ Updated NewJob.tsx:286-287
- Status: ✅ RESOLVED
- Fields: service_id, reference_panel_id ✅
Background: Light green with green checkmark

ROW 6 - TESTING READINESS (3 columns):
Card 13: "Test 1: Login"
- URL: http://154.114.10.123:3000
- Credentials: admin / admin123
- Expected: Successful login
- Status: ✅ READY FOR TESTING
Background: Purple

Card 14: "Test 2: Job Submission"
- URL: /jobs/new
- Service: H3Africa (ID: 7)
- Panel: apps@h3africa-v6hc-s@1.0.0
- Expected: No 422 errors
- Status: ✅ READY FOR TESTING
Background: Purple

Card 15: "Test 3: Michigan API"
- Monitor: docker logs job-processor
- Expected: "Using reference panel 'apps@h3africa-v6hc-s@1.0.0'"
- Status: ✅ READY FOR TESTING
Background: Purple

FOOTER SECTION:
"📊 Deployment Time: ~5 minutes | Total Issues Fixed: 3 | Last Updated: 2025-10-06 13:03 UTC"

Use modern dashboard style with:
- Clean card layouts with shadows
- Status indicators (✅ for success, ❌ for errors)
- Color-coded backgrounds
- Clear labels and hierarchical information
- Professional typography
- Plenty of whitespace
```

---

## Prompt 6: Simplified Overview (Optional)

**Purpose:** High-level system overview for presentations

**Copy this prompt:**

```
Create a simple, clean architecture diagram for a Federated Genomic Imputation Platform. Use minimal text and focus on visual clarity.

Show 4 main layers stacked vertically:

LAYER 1 (Top): USER INTERFACE
- Single box: "Web Application (React)"
- Icon: Browser/computer icon
- Color: Light blue

LAYER 2: API & ROUTING
- Single box: "API Gateway"
- Icon: Network/gateway icon
- Color: Orange
- Arrow down from Layer 1

LAYER 3: MICROSERVICES (show 5 boxes horizontally)
- Box 1: "User Service" (with user icon)
- Box 2: "Service Registry" (with list icon)
- Box 3: "Job Processor" (with gear icon)
- Box 4: "File Manager" (with folder icon)
- Box 5: "Monitoring" (with chart icon)
- Color: Different pastel colors for each
- Arrows from Layer 2 to each service

LAYER 4: DATA & EXTERNAL (show 2 sections side by side)
Left Section: "Data Storage"
- PostgreSQL (database icon)
- Redis (cache icon)
- File Storage (storage icon)
- Color: Blue gradient

Right Section: "External APIs"
- Michigan Imputation (DNA icon)
- H3Africa Service (globe icon)
- Color: Green gradient

CONNECTIONS:
- Show "Celery Worker" as a separate component between Layer 3 and Layer 4
- Worker connects to: Job Processor, Service Registry, External APIs
- All microservices connect to Data Storage
- Use simple arrows, no text on arrows

Style:
- Modern, flat design
- Minimal text (just component names)
- Icons for each component
- Clean, professional look
- Suitable for presentations
- White or light gray background
```

---

## Tips for Best Results with Lucid AI

### Do's:
✅ Be specific about layout (horizontal, vertical, swimlanes)
✅ Specify colors and styling preferences
✅ Include exact text for labels and callouts
✅ Define relationships clearly (arrows, connections)
✅ Specify diagram type (flowchart, sequence, architecture)
✅ Use structured format (layers, phases, swimlanes)

### Don'ts:
❌ Don't use overly technical jargon without context
❌ Don't omit important connections
❌ Don't forget to specify visual style
❌ Don't make prompts too short (be detailed!)

### Pro Tips:
💡 Start with diagram type: "Create a [sequence diagram/flowchart/architecture diagram]"
💡 Use numbered lists for clarity
💡 Specify background colors for phases/sections
💡 Include callout boxes for important notes
💡 Mention specific styling: "modern", "professional", "clean"
💡 Ask for icons where appropriate

---

## Alternative: Use With Other AI Tools

These prompts also work well with:

### Claude Code (with Mermaid)
- Already have Mermaid diagrams in `docs/diagrams/*.mermaid`
- View at http://154.114.10.123:8888/view-diagrams.html

### ChatGPT with DALL-E
- Can generate diagram images (not as structured)
- Better for conceptual diagrams

### Excalidraw
- For hand-drawn style diagrams
- Can paste Mermaid code

### draw.io
- For maximum customization
- Manual but very precise

---

## Comparison: Lucid AI vs Mermaid

| Feature | Lucid AI | Mermaid |
|---------|----------|---------|
| **Ease of Use** | Natural language prompt | Code-based syntax |
| **Visual Quality** | Professional, polished | Clean, developer-focused |
| **Customization** | Drag-and-drop editing | Code editing |
| **Collaboration** | Real-time collaboration | Git-based collaboration |
| **Export** | PNG, PDF, SVG, Visio | PNG, SVG, PDF (via CLI) |
| **Version Control** | Cloud-based versions | Git commits |
| **Cost** | Free tier limited | Completely free |
| **Learning Curve** | Very low (natural language) | Low-medium (syntax) |
| **Best For** | Business presentations | Technical documentation |

---

## Documentation References

- **Lucid AI Guide:** https://lucid.co/product/lucid-ai
- **LucidChart Tutorials:** https://www.lucidchart.com/pages/tutorials
- **Our Mermaid Diagrams:** [DIAGRAMS_PREVIEW.md](DIAGRAMS_PREVIEW.md)
- **How to View:** [HOW_TO_VIEW.md](HOW_TO_VIEW.md)
- **Complete Guide:** [DIAGRAMS_CREATED_2025-10-06.md](../../DIAGRAMS_CREATED_2025-10-06.md)

---

**Created:** 2025-10-06
**Purpose:** Generate professional architecture diagrams using Lucid AI
**Format:** Natural language prompts optimized for AI diagram generation
