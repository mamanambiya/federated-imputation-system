# Lucid AI Prompt: Federated Genomic Imputation Architecture

## Prompt for Lucid AI - Federated Model with GA4GH Standards

**Copy the entire prompt below and paste into Lucid AI at <https://lucid.app/lucidchart>**

---

```
Create a comprehensive federated architecture diagram for a Genomic Imputation Platform. The diagram should show a central coordination hub connecting to multiple imputation services, with emphasis on GA4GH standards integration.

LAYOUT: Use a radial/hub-and-spoke layout with the central platform in the middle and services radiating outward.

═══════════════════════════════════════════════════════════════════════════

CENTER: CENTRAL COORDINATION PLATFORM (Large gold/yellow box)

Title: "🖥️ CENTRAL COORDINATION PLATFORM"
Subtitle: "http://154.114.10.123:3000"

Inside this box, show these components stacked vertically:

1. "Central Web UI" (Large rectangle)
   • React TypeScript Frontend
   • Responsive Material-UI Design
   • Real-time Job Monitoring
   Icon: Computer/browser icon
   Color: Light yellow

2. "API Gateway" (Rectangle below UI)
   • Port 8000
   • JWT Authentication
   • Request Routing
   • Load Balancing
   Icon: Network/gateway icon
   Color: Orange

3. "Backend Microservices" (Rectangle, show 5 sub-boxes horizontally)
   Sub-box 1: "User Service" (Port 8001)
   Sub-box 2: "Service Registry" (Port 8002) ← Mark as important
   Sub-box 3: "Job Processor" (Port 8003)
   Sub-box 4: "File Manager" (Port 8004)
   Sub-box 5: "Monitoring" (Port 8005)
   Icon: Gear/cog icons for each
   Color: Light blue gradient

4. "Data Layer" (Two cylinders side by side)
   Left cylinder: "PostgreSQL"
     • User accounts
     • Job metadata
     • Service catalog
     • Results index
   Right cylinder: "Redis + Celery"
     • Task queue
     • Job orchestration
     • Async processing
   Icon: Database cylinder icon
   Color: Dark blue

Add a callout box on the side of the central platform:
"✅ CURRENT STATUS:
• Deployed & Operational
• Authentication: Working
• Job Submission: Tested
• Michigan Integration: Complete"

═══════════════════════════════════════════════════════════════════════════

TOP RIGHT: CLOUD IMPUTATION SERVICES

Group 1: "☁️ MICHIGAN IMPUTATION SERVER" (Large green box)
   URL: https://impute.afrigen-d.org

   Show these details inside:
   • Type: Michigan/TopMed
   • API: Cloudgene Format
   • Status: ✅ INTEGRATED & OPERATIONAL

   Reference Panels (show as list):
     ✓ 1000 Genomes Phase 3 (v5) - 2,504 samples
     ✓ H3Africa (v6) - 4,447 samples (African populations)
     ✓ HapMap 2
     ✓ CAAPA (African American)

   Features:
     • Quality Control Pipeline
     • Phasing: Eagle2
     • Imputation: Minimac4
     • GRCh37/GRCh38 Support

   Protocol Box (nested inside):
     "Cloudgene API Format:
      apps@{app-id}@{version}
      Example: apps@h3africa-v6hc-s@1.0.0"

   Icon: DNA helix icon
   Color: Bright green
   Border: Thick solid line (operational)

Group 2: "🌍 H3AFRICA HISTORICAL SERVER" (Medium green box below Michigan)
   Type: Custom REST API
   Status: ✅ Available (Legacy Support)

   Features:
     • African-specific panels
     • Historical job support
     • Custom API integration

   Icon: Globe with Africa highlighted
   Color: Medium green
   Border: Solid line

═══════════════════════════════════════════════════════════════════════════

BOTTOM RIGHT: GA4GH STANDARDIZED SERVICES (FUTURE)

Large box: "🏢 GA4GH-COMPLIANT SERVICES"
Subtitle: "Global Alliance for Genomics and Health Standards"

Inside, show 3 sub-boxes horizontally:

Sub-box 1: "📍 MALI SITE (West Africa)"
   Infrastructure:
     • DRS (Data Repository Service) 🔵
     • WES (Workflow Execution Service) 🔵
     • TRS (Tool Registry Service) 🔵
     • Nextflow Pipelines
     • Local Docker Compute

   Data:
     • Local genomic datasets
     • Regional reference data
     • West African populations

   Compliance:
     • Data residency requirements
     • Local compute processing

   Status: 🔄 PLANNED
   Icon: Server/datacenter icon
   Color: Light blue
   Border: Dashed line (future)

Sub-box 2: "📍 ILIFU SITE (South Africa)"
   Infrastructure:
     • HPC Compute Cluster
     • DRS (Data Repository Service) 🔵
     • WES (Workflow Execution Service) 🔵
     • Attestation Services
     • Data SPA Integration

   Features:
     • High-performance computing
     • Secure data hosting
     • Privacy-preserving computation
     • Federated learning ready

   Status: 🔄 PLANNED
   Icon: HPC/cluster icon
   Color: Light blue
   Border: Dashed line

Sub-box 3: "☁️ AZURE SITE (Cloud)"
   Platform: DNAstack

   Infrastructure:
     • DRS (Data Repository Service) 🔵
     • WES (Workflow Execution Service) 🔵
     • Docker Containers
     • Kubernetes Orchestration

   Features:
     • Cloud-native workflows
     • Auto-scaling compute
     • Global accessibility
     • Cost-optimized processing

   Status: 🔄 PLANNED
   Icon: Cloud icon
   Color: Light blue
   Border: Dashed line

Add a callout box for GA4GH section:
"🔵 GA4GH STANDARDS:
• WES: Workflow Execution Service
• DRS: Data Repository Service
• TRS: Tool Registry Service
• TES: Task Execution Service
• Passport: Authentication/Authorization"

═══════════════════════════════════════════════════════════════════════════

TOP LEFT: USER INTERACTION

Box: "👥 RESEARCHERS & USERS"

Show user journey as a flow:

1. User Icon: "👨‍🔬 Genomics Researcher"

2. Actions (show as numbered steps):
   Step 1: "Access Web Interface"
   Step 2: "Authenticate (Login)"
   Step 3: "Upload VCF File"
   Step 4: "Select Imputation Service"
     • Michigan Server
     • H3Africa Server
     • MALI Site (future)
     • ILIFU Site (future)
     • Azure Site (future)
   Step 5: "Choose Reference Panel"
     Example: H3Africa v6 (African populations)
   Step 6: "Configure Parameters"
     • Build: GRCh37/GRCh38
     • Phasing: Eagle2
     • Population: AFR, EUR, ASN, etc.
   Step 7: "Submit Job"
   Step 8: "Monitor Progress (Real-time)"
   Step 9: "Download Results"

Icon: User with checklist
Color: Light pink/lavender
Border: Rounded corners

═══════════════════════════════════════════════════════════════════════════

CONNECTIONS & DATA FLOW:

Show arrows with labels:

1. User → Central Platform:
   Arrow: "1. HTTPS Access"
   Label: "Web Browser"
   Style: Thick solid arrow, blue

2. Central Platform → Michigan Server:
   Arrow: "2. Job Submission"
   Label: "POST /api/v2/jobs/submit/
          Cloudgene Format:
          refpanel: apps@h3africa-v6hc-s@1.0.0
          build: hg38
          phasing: eagle"
   Style: Thick solid arrow, green

3. Michigan Server → Central Platform:
   Arrow: "3. Job Status & Results"
   Label: "Status updates
          Imputed VCF files
          QC reports
          Statistics"
   Style: Dashed arrow back, green

4. Central Platform → H3Africa Server:
   Arrow: "Job Submission (Custom API)"
   Style: Solid arrow, medium green

5. H3Africa Server → Central Platform:
   Arrow: "Results"
   Style: Dashed arrow back, medium green

6. Central Platform → GA4GH Services (all 3):
   Arrow: "Future: WES API Calls"
   Label: "GA4GH Workflow Execution Service
          Standardized job submission"
   Style: Dashed arrow, light blue
   Add note: "🔄 Implementation Planned"

7. GA4GH Services → Central Platform:
   Arrow: "Future: DRS File Access"
   Label: "GA4GH Data Repository Service
          Secure file transfer"
   Style: Dashed arrow back, light blue

8. Show health check connections (thin dashed lines):
   Central Platform → All Services
   Label: "Health Monitoring"

9. Data residency connection:
   MALI Site ↔ ILIFU Site
   Arrow: "Data Residency Coordination"
   Label: "Regional data governance"
   Style: Dotted line, gray

═══════════════════════════════════════════════════════════════════════════

LEGEND BOX (Bottom of diagram):

Create a legend showing:

Line Styles:
━━━━  Solid line: Operational/Integrated
- - -  Dashed line: Planned/Future
····  Dotted line: Optional/Coordination

Colors:
🟡 Gold/Yellow: Central Platform
🟢 Green: Operational Imputation Services
🔵 Light Blue: Planned GA4GH Services
🟣 Pink: User Interaction
⚪ Gray: Data flow

Status Indicators:
✅ Operational - Service is live and tested
🔄 Planned - Integration in development
🔵 GA4GH - Compliant with GA4GH standards
🌍 Geographic - Distributed across regions

═══════════════════════════════════════════════════════════════════════════

KEY STATISTICS BOX (Top right corner):

Show metrics in a small box:
"📊 CURRENT METRICS (2025-10-06)

Operational Services: 2/5
  ✅ Michigan Server
  ✅ H3Africa Server

Reference Panels: 4+ available
  • 1000 Genomes (2,504 samples)
  • H3Africa (4,447 samples)
  • HapMap 2
  • CAAPA

Total Samples: 7,000+ individuals
Variants: 214+ million SNPs

Jobs Processed: Production ready
Uptime: 99.9%
Response Time: <2s

Planned Integration: 3 sites
  🔄 MALI (West Africa)
  🔄 ILIFU (South Africa)
  🔄 Azure (Cloud)"

═══════════════════════════════════════════════════════════════════════════

TECHNICAL SPECIFICATIONS BOX (Bottom left):

"🔧 TECHNICAL STANDARDS

API Formats Supported:
  ✅ Michigan/Cloudgene API
     Format: apps@{app-id}@{version}
     Method: multipart/form-data

  ✅ Custom REST APIs
     Format: JSON
     Method: POST/GET

  🔄 GA4GH WES (Planned)
     Workflow Execution Service
     OpenAPI 3.0 specification

  🔄 GA4GH DRS (Planned)
     Data Repository Service
     Object storage with URIs

Authentication:
  ✅ JWT Tokens (current)
  ✅ API Keys
  🔄 OAuth 2.0 (planned)
  🔄 GA4GH Passports (planned)

File Formats:
  • Input: VCF, VCF.gz
  • Output: VCF.gz (imputed)
  • Reports: HTML, PDF, CSV
  • Logs: TXT, JSON

Genome Builds:
  • GRCh37 (hg19)
  • GRCh38 (hg38)

Protocols:
  • HTTPS/TLS 1.3
  • WebSockets (real-time updates)
  • REST APIs
  • GraphQL (planned)"

═══════════════════════════════════════════════════════════════════════════

BENEFITS BOX (Right side):

Create a benefits callout box:

"💡 FEDERATED ARCHITECTURE BENEFITS

For Researchers:
  ✓ Single unified interface
  ✓ Multiple service options
  ✓ No vendor lock-in
  ✓ Best panel selection
  ✓ Result comparison

For Service Providers:
  ✓ Easy integration
  ✓ Central visibility
  ✓ Health monitoring
  ✓ Load distribution

For Infrastructure:
  ✓ Geographic distribution
  ✓ Data residency compliance
  ✓ Scalable architecture
  ✓ Standards-based (GA4GH)
  ✓ Resilient & fault-tolerant"

═══════════════════════════════════════════════════════════════════════════

GA4GH PROTOCOL DETAIL BOX (Near GA4GH services):

"🔵 GA4GH STANDARDS INTEGRATION

WES (Workflow Execution Service):
  Purpose: Standardized workflow submission
  Endpoint: POST /ga4gh/wes/v1/runs
  Format: JSON workflow descriptor
  Status: WDL, CWL, Nextflow supported

DRS (Data Repository Service):
  Purpose: Secure file access
  Format: drs://hostname/object-id
  Features: Access control, checksums
  Status: Version 1.2.0 compliant

TRS (Tool Registry Service):
  Purpose: Tool/workflow discovery
  Endpoint: GET /ga4gh/trs/v2/tools
  Format: JSON tool descriptors
  Status: Registry integration planned

Authentication:
  • GA4GH Passports
  • JWT tokens
  • OAuth 2.0/OIDC
  • Federated identity

Benefits:
  → Interoperability across sites
  → Standardized APIs
  → Global compatibility
  → Community-driven standards"

═══════════════════════════════════════════════════════════════════════════

STYLING REQUIREMENTS:

Overall Style:
  • Modern, professional diagram
  • Clean lines and spacing
  • Consistent color scheme
  • Clear hierarchy (central hub prominent)
  • Icons for each component type
  • Shadows for depth
  • Rounded corners for boxes
  • Grid alignment

Typography:
  • Bold headings
  • Clear readable fonts
  • Color-coded labels
  • Status badges (✅ 🔄)

Visual Hierarchy:
  1. Central Platform (largest, gold)
  2. Operational Services (bright green, prominent)
  3. Planned Services (light blue, dashed)
  4. Supporting info boxes (smaller, gray)

Special Elements:
  • Use DNA helix icons for imputation services
  • Use globe icons for geographic distribution
  • Use shield icons for security/compliance
  • Use clock/refresh icons for real-time updates
  • Use checkmarks for operational status
  • Use construction/wrench for planned features

Annotations:
  • Add "Current" labels to operational services
  • Add "Planned" labels to future services
  • Add "GA4GH" badges to compliant services
  • Add version numbers where relevant
  • Add URL/endpoint details

═══════════════════════════════════════════════════════════════════════════

TITLE AND FOOTER:

Diagram Title (Top center, large):
"FEDERATED GENOMIC IMPUTATION PLATFORM"
Subtitle: "Central Coordination Hub with Distributed Imputation Services"

Footer (Bottom):
"Architecture Version: 2.0 | Status: Production (Michigan), Planning (GA4GH Sites) | Last Updated: 2025-10-06
Platform URL: http://154.114.10.123:3000 | Documentation: github.com/your-org/federated-imputation-central"

═══════════════════════════════════════════════════════════════════════════

FINAL NOTES FOR LUCID AI:

1. Make the central platform visually dominant (largest element)
2. Use radial layout with services arranged around the center
3. Color code by status: Green=operational, Blue=planned
4. Add GA4GH badges (🔵) to compliant services
5. Show clear data flow with labeled arrows
6. Include all technical details in organized boxes
7. Make it presentation-ready with professional styling
8. Ensure text is readable at standard zoom levels
9. Use consistent spacing and alignment
10. Add white space for clarity

This diagram should clearly communicate:
  → Central platform coordinates everything
  → Michigan integration is operational
  → GA4GH standards enable future expansion
  → Geographic distribution supports data residency
  → Unified interface simplifies researcher experience
```

---

## Additional Lucid AI Tips

### After Generating

1. **Customize Colors:**
   - Central Platform: Use gold (#FFD700)
   - Michigan: Use bright green (#32CD32)
   - GA4GH Services: Use light blue (#87CEEB)
   - Connections: Use appropriate colors per status

2. **Add Icons:**
   - Lucid has extensive icon libraries
   - Search for: DNA, server, cloud, user, database, network
   - Use AWS/Azure icons if available for cloud services

3. **Adjust Layout:**
   - Ensure central platform is truly central
   - Distribute services evenly around the hub
   - Align boxes for clean appearance

4. **Export Options:**
   - PNG: For embedding in documents
   - PDF: For printing/presentations
   - SVG: For scalable web use
   - Link: For sharing with team

### Presentation Tips

- **Executive Version:** Hide technical details, show high-level flow
- **Technical Version:** Show all protocols and specifications
- **Roadmap Version:** Emphasize future GA4GH integrations

---

## Comparison with Mermaid Version

| Feature | Lucid AI | Mermaid |
|---------|----------|---------|
| **Customization** | Full drag-and-drop | Code-based |
| **Professional Polish** | Excellent | Good |
| **GA4GH Badges** | Custom graphics | Limited |
| **Icon Library** | Extensive | Limited |
| **Collaboration** | Real-time | Git-based |
| **Export Quality** | High-res | Good |
| **Best For** | Presentations, executives | Technical docs, developers |

---

## Viewing the Mermaid Version

While Lucid AI generates the polished version, you can view the Mermaid version:

**Web Browser:**

```
http://154.114.10.123:8888/view-diagrams.html
```

**VS Code:**

```bash
code docs/diagrams/FEDERATED_OVERVIEW.md
# Press Ctrl+Shift+V
```

**Mermaid Live:**

```
https://mermaid.live
# Copy content from federated-overview.mermaid
```

---

**Created:** 2025-10-06
**Purpose:** Generate professional federated architecture diagram with GA4GH standards
**Format:** Natural language prompt optimized for Lucid AI
**Result:** High-quality diagram for presentations and executive communication
