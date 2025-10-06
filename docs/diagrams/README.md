# Architecture Diagrams

This folder contains visual architecture diagrams for the Federated Genomic Imputation Platform.

## 📁 Diagram Files

**✨ New: Mermaid Diagrams Available (2025-10-06)**

```
diagrams/
├── README.md                           # This file
├── architecture-overview.mermaid       # ✅ Complete system architecture
├── job-submission-flow.mermaid         # ✅ Job submission sequence
├── authentication-flow.mermaid         # ✅ Login/JWT flow
├── michigan-api-integration.mermaid    # ✅ Michigan API + Cloudgene format
├── deployment-status.mermaid           # ✅ Current deployment status
├── architecture-overview.png           # High-level system view
├── microservices-detail.png            # Detailed microservices
├── service-discovery.png               # Service ranking algorithm
├── database-schema.png                 # ER diagram
└── federated-topology.png              # Geographic distribution
```

## 🎨 How to Create Diagrams

### Method 1: Mermaid (Version Controlled)

Source files are in parent `docs/` folder:

- [ARCHITECTURE_DIAGRAM.md](../ARCHITECTURE_DIAGRAM.md) - Full technical diagrams
- [SIMPLE_ARCHITECTURE.md](../SIMPLE_ARCHITECTURE.md) - Simplified view

**Export to PNG:**

1. Copy mermaid code
2. Go to <https://mermaid.live>
3. Paste code
4. Actions → Export → PNG
5. Save to this folder

### Method 2: MCP Diagram Tools (AI-Generated)

We have two MCP servers installed for creating diagrams with Claude Code:

**✅ Excalidraw MCP** - Hand-drawn style

- Quick sketches
- Whiteboard aesthetics
- No browser extension needed

**✅ Draw.io MCP** - Professional diagrams

- Enterprise quality
- Shape libraries (AWS, Azure, etc.)
- Requires browser extension

See [MCP_DIAGRAM_SETUP.md](../MCP_DIAGRAM_SETUP.md) for configuration.

### Method 3: Manual Tools

**Online Tools:**

- Excalidraw: <https://excalidraw.com>
- draw.io: <https://app.diagrams.net>
- Mermaid Live: <https://mermaid.live>

**Desktop Tools:**

- draw.io Desktop
- Lucidchart
- Microsoft Visio

## 🎯 Diagram Standards

### File Naming

- Use lowercase with hyphens: `service-registry-flow.png`
- Include diagram type: `architecture-`, `sequence-`, `er-`, `flow-`
- Version if needed: `architecture-v2.png`

### Color Coding

Follow these colors for consistency:

| Component Type | Color | Hex Code |
|----------------|-------|----------|
| Cloud Services | Blue | `#1E90FF` |
| On-Premises | Green | `#32CD32` |
| Central System | Gold | `#FFD700` |
| External APIs | Red | `#FF6347` |
| Databases | Purple | `#9370DB` |
| Frontend | Light Blue | `#61dafb` |
| Gateway | Dark Red | `#ff6b6b` |
| Microservices | Blue | `#4dabf7` |
| Workers | Yellow | `#ffd43b` |

### Export Settings

- **Format:** PNG for docs, SVG for scaling
- **Resolution:** 2x or 3x for presentations
- **Background:** White (check "Include background" when exporting)
- **Size:** Max 2000px width for web display

## 📊 Existing Diagrams

### ✨ NEW: Architecture Overview (Mermaid)

**File:** [architecture-overview.mermaid](architecture-overview.mermaid)
**Format:** Mermaid Graph
**Last Updated:** 2025-10-06

**Shows:**
- Complete microservices architecture
- All 5 microservices (User, Service Registry, Job Processor, File Manager, Monitoring)
- API Gateway routing
- Data layer (PostgreSQL, Redis)
- External services (Michigan API, H3Africa API)
- Celery worker integration
- File storage layer

**Features:**
- Color-coded components by type
- Request flow arrows
- Health check connections
- Database relationships

**Use Cases:**
- System overview for new developers
- Architecture presentations
- Technical documentation
- Deployment planning

### ✨ NEW: Job Submission Flow (Mermaid)

**File:** [job-submission-flow.mermaid](job-submission-flow.mermaid)
**Format:** Mermaid Sequence Diagram
**Last Updated:** 2025-10-06

**Shows:**
- 6-phase job submission workflow
- Authentication phase
- Service discovery phase
- Job submission with correct field names
- Worker processing with Cloudgene format
- Status monitoring loop
- Job completion and results

**Critical Details:**
- Field validation: `service_id`, `reference_panel_id` ✅
- Panel endpoint: Returns Cloudgene format
- Michigan API submission parameters
- Real-time status updates

**Use Cases:**
- Understanding job lifecycle
- Debugging submission issues
- API integration documentation
- Developer onboarding

### ✨ NEW: Authentication Flow (Mermaid)

**File:** [authentication-flow.mermaid](authentication-flow.mermaid)
**Format:** Mermaid Sequence Diagram
**Last Updated:** 2025-10-06

**Shows:**
- Login phase with JWT generation
- Authenticated request validation
- Token refresh mechanism
- Logout flow

**Current Credentials:**
- Username: `admin`
- Password: `admin123`
- JWT expiration: 24 hours

**Features:**
- Password validation with bcrypt
- Redis session caching
- PostgreSQL user lookup
- Token expiration handling

**Use Cases:**
- Security audit
- Authentication troubleshooting
- Frontend integration
- Session management

### ✨ NEW: Michigan API Integration (Mermaid)

**File:** [michigan-api-integration.mermaid](michigan-api-integration.mermaid)
**Format:** Mermaid Graph
**Last Updated:** 2025-10-06

**Shows:**
- Complete Michigan imputation workflow
- Frontend form submission (NewJob.tsx)
- Job processor validation
- Service registry panel lookup
- Cloudgene format extraction
- Michigan API submission
- Status monitoring and results

**Critical Fixes Highlighted:**
- Frontend field names: `service_id`, `reference_panel_id` ✅
- Panel database format: `apps@h3africa-v6hc-s@1.0.0` ✅
- Worker panel fetch logic ✅

**Use Cases:**
- Michigan service integration
- Cloudgene format documentation
- Debugging API submissions
- Understanding data flow

### ✨ NEW: Deployment Status (Mermaid)

**File:** [deployment-status.mermaid](deployment-status.mermaid)
**Format:** Mermaid Graph
**Last Updated:** 2025-10-06 13:03 UTC

**Shows:**
- Current deployment status (all services)
- Resolved issues with timestamps
- Service health indicators
- Database connections
- Testing readiness checklist

**Status:** ✅ ALL OPERATIONAL
- Frontend: Up and compiled successfully
- Authentication: Working (admin/admin123)
- All microservices: Healthy
- Job submission: Ready for testing

**Use Cases:**
- Deployment verification
- System health check
- Issue tracking
- Production readiness

### High-Level Architecture

**Source:** [SIMPLE_ARCHITECTURE.md](../SIMPLE_ARCHITECTURE.md)
**Shows:**

- Federated topology (Azure, Mali, ILIFU)
- Central UI coordination
- External APIs
- Data flow

**Use Cases:**

- Presentations
- Executive summaries
- Quick reference

### Technical Architecture

**Source:** [ARCHITECTURE_DIAGRAM.md](../ARCHITECTURE_DIAGRAM.md)
**Shows:**

- All 8 microservices
- Database architecture
- API Gateway routing
- Async workers
- Service discovery

**Use Cases:**

- Development documentation
- Technical reviews
- System design discussions

### Job Submission Flow

**Source:** [ARCHITECTURE_DIAGRAM.md](../ARCHITECTURE_DIAGRAM.md) - Sequence Diagram
**Shows:**

- 26-step job submission process
- Service interactions
- Credential validation
- Real-time updates

**Use Cases:**

- Developer onboarding
- Debugging workflows
- API documentation

### Database Schema

**Source:** [ARCHITECTURE_DIAGRAM.md](../ARCHITECTURE_DIAGRAM.md) - ER Diagram
**Shows:**

- 8 database entities
- Relationships and foreign keys
- Key fields and constraints

**Use Cases:**

- Database design
- Migration planning
- Data modeling

## 🔄 Updating Diagrams

### When to Update

- Architecture changes (new services, removed components)
- New features added
- Workflow modifications
- Database schema updates

### Update Process

1. **Update Source:** Edit mermaid code in `.md` files
2. **Export New Version:** Re-generate PNG/SVG
3. **Replace File:** Overwrite old diagram in this folder
4. **Update Docs:** Reference new diagram in documentation
5. **Commit:** Git commit with descriptive message

```bash
# Example workflow
git add docs/diagrams/architecture-overview.png
git add docs/ARCHITECTURE_DIAGRAM.md
git commit -m "docs: Update architecture diagram with new monitoring service"
git push
```

## 🌐 Viewing Diagrams

### In GitHub

Diagrams automatically display in GitHub when:

- PNG/SVG files are linked in markdown
- Mermaid code is in `.md` files

### In VS Code

Install extensions:

- "Markdown Preview Enhanced" - View diagrams
- "Markdown Preview Mermaid Support" - Render mermaid
- "Draw.io Integration" - Edit `.drawio` files

### In Documentation Sites

If deploying docs to a site (like GitHub Pages):

- Reference diagrams using relative paths
- Use SVG for better scaling
- Provide alt text for accessibility

## 📝 Credits

Diagrams created using:

- **Mermaid.js** - Code-based diagrams
- **Excalidraw** - Hand-drawn style
- **draw.io** - Professional diagrams
- **MCP Diagram Servers** - AI-assisted generation

## 🤝 Contributing

When adding new diagrams:

1. **Follow Standards:** Use naming conventions and color coding
2. **Add Source:** Include mermaid/source code if applicable
3. **Update README:** Document what the diagram shows
4. **Optimize Size:** Compress PNGs, use SVG when possible
5. **Add Alt Text:** When embedding in markdown

## 📚 Additional Resources

- [Diagram Tools Guide](../DIAGRAM_TOOLS_GUIDE.md) - Comprehensive tool comparison
- [MCP Setup Guide](../MCP_DIAGRAM_SETUP.md) - AI-assisted diagram creation
- [Mermaid Documentation](https://mermaid.js.org) - Syntax reference
- [Excalidraw Libraries](https://libraries.excalidraw.com) - Shape collections
- [draw.io Shapes](https://www.diagrams.net/blog/shapes) - Icon libraries
