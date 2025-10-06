# Federated Genomic Imputation Platform Documentation

This directory contains comprehensive documentation for the Federated Genomic Imputation Platform.

## 📚 Documentation Index

### Setup and Installation
- **[SETUP.md](./SETUP.md)** - Complete setup and installation guide for the federated imputation system
- **[IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)** - Complete implementation guide for rebuilding the system from scratch

### Roadmap and Architecture
- **[ROADMAP.md](./ROADMAP.md)** - High-level roadmap overview (Phase 1-4 summary)
- **[ROADMAP_UPDATED_2025.md](./ROADMAP_UPDATED_2025.md)** - ⭐ **Comprehensive roadmap with detailed tasks, timelines, and implementation plans** (Start here for planning!)
- **[ARCHITECTURE_STATUS.md](./ARCHITECTURE_STATUS.md)** - Current system architecture status report (October 2025 snapshot)

### Feature Guides
- **[MULTI_SERVICE_FEATURE.md](./MULTI_SERVICE_FEATURE.md)** - Multi-service selection functionality for job submission
- **[SERVICE_MODAL_IMPLEMENTATION.md](./SERVICE_MODAL_IMPLEMENTATION.md)** - Service selection modal dialog implementation details
- **[SERVICE_DETAIL_PAGE.md](./SERVICE_DETAIL_PAGE.md)** - User-facing service detail page documentation
- **[SERVICES_CONSOLIDATION.md](./SERVICES_CONSOLIDATION.md)** - Service consolidation and reference panel management

### Admin and Configuration
- **[ADMIN_SERVICE_SETUP.md](./ADMIN_SERVICE_SETUP.md)** - Admin interface for setting up and configuring imputation services

### API Integration Guides
- **[MICHIGAN_SERVICE_IMPLEMENTATION.md](./MICHIGAN_SERVICE_IMPLEMENTATION.md)** - ⚠️ **Michigan/Cloudgene service implementation guide (REQUIRED for job submissions)**
- **[GA4GH_IMPLEMENTATION_SUMMARY.md](./GA4GH_IMPLEMENTATION_SUMMARY.md)** - GA4GH WES API integration overview
- **[GA4GH_SERVICE_INFO_DETAILS.md](./GA4GH_SERVICE_INFO_DETAILS.md)** - Detailed GA4GH service-info endpoint implementation
- **[DNASTACK_INTEGRATION.md](./DNASTACK_INTEGRATION.md)** - DNASTACK Omics API integration guide

### Job Execution & Testing
- **[QUICKSTART_JOB_EXECUTION.md](./QUICKSTART_JOB_EXECUTION.md)** - ⭐ **Quick start guide - Get a job running in 10 minutes!**
- **[H3AFRICA_JOB_EXECUTION.md](./H3AFRICA_JOB_EXECUTION.md)** - Complete H3Africa job execution integration guide
- **[CLOUDGENE_REFERENCE_PANEL_FORMAT.md](./CLOUDGENE_REFERENCE_PANEL_FORMAT.md)** - ⚠️ **CRITICAL: Reference panel naming format for Michigan/Cloudgene servers**
- **[IMPLEMENTATION_SUMMARY_JOB_EXECUTION.md](./IMPLEMENTATION_SUMMARY_JOB_EXECUTION.md)** - Job execution implementation summary
- **[JOB_EXECUTION_TESTING.md](./JOB_EXECUTION_TESTING.md)** - Detailed testing guide for job execution pipeline

## 🏗️ Architecture Overview

**Current Architecture**: Hybrid Django + FastAPI Microservices (October 2025)
- **7 FastAPI Microservices**: User, Service Registry, Job Processor, File Manager, Notification, Monitoring, API Gateway
- **Database-per-Service Pattern**: 7 PostgreSQL databases for service isolation
- **Performance**: 10x faster async operations (FastAPI vs Django)
- **Efficiency**: 75% less memory than all-Django (300MB vs 1.2GB)

### System Architecture Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (React)                          │
│                        Port 3000                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                      API GATEWAY (FastAPI)                       │
│                         Port 8000                                │
│  • Authentication       • Request Routing      • Rate Limiting   │
└──┬────────┬─────────┬─────────┬──────────┬──────────┬──────────┘
   │        │         │         │          │          │
   ↓        ↓         ↓         ↓          ↓          ↓
┌─────┐ ┌─────┐ ┌──────────┐ ┌──────┐ ┌──────┐ ┌──────────┐
│User │ │Svc  │ │   Job    │ │File  │ │Notif │ │Monitoring│
│8001 │ │Reg  │ │Processor │ │Mgr   │ │8005  │ │  8006    │
│     │ │8002 │ │   8003   │ │8004  │ │      │ │          │
└─────┘ └─────┘ └──────────┘ └──────┘ └──────┘ └──────────┘
   │        │         │           │        │          │
   ↓        ↓         ↓           ↓        ↓          ↓
┌─────────────────────────────────────────────────────────┐
│          PostgreSQL (Database-per-Service)              │
│  user_db | service_db | job_db | file_db | ...         │
└─────────────────────────────────────────────────────────┘
```

The system supports three main API types:

1. **Michigan Imputation Server API** - Traditional imputation service protocol
2. **GA4GH WES (Workflow Execution Service)** - Standardized workflow execution
3. **DNASTACK Omics API** - Genomic data platform integration

**For complete architecture details, see [ARCHITECTURE_STATUS.md](./ARCHITECTURE_STATUS.md)**
**For visual flows, see [VISUAL_ARCHITECTURE_FLOWS.md](./VISUAL_ARCHITECTURE_FLOWS.md)**

## 🔗 Quick Links

- [Main README](../README.md) - Project overview and quick start
- [Frontend Documentation](../frontend/README.md) - React frontend specifics
- [Backend API](../imputation/) - Django backend implementation

## 📖 Reading Order

### For New Developers
1. **[SETUP.md](./SETUP.md)** - Get the system running locally
2. **[ARCHITECTURE_STATUS.md](./ARCHITECTURE_STATUS.md)** - Understand current system architecture and status
3. **[ROADMAP_UPDATED_2025.md](./ROADMAP_UPDATED_2025.md)** - Understand project vision, priorities, and tasks
4. **[GA4GH_IMPLEMENTATION_SUMMARY.md](./GA4GH_IMPLEMENTATION_SUMMARY.md)** - API integration details
5. **[ADMIN_SERVICE_SETUP.md](./ADMIN_SERVICE_SETUP.md)** - Learn service configuration
6. **[MULTI_SERVICE_FEATURE.md](./MULTI_SERVICE_FEATURE.md)** - Understand user workflows

### For Project Planning / Product Management
1. **[ROADMAP.md](./ROADMAP.md)** - High-level roadmap overview
2. **[ROADMAP_UPDATED_2025.md](./ROADMAP_UPDATED_2025.md)** - Detailed roadmap with tasks, timelines, resource requirements
3. **[ARCHITECTURE_STATUS.md](./ARCHITECTURE_STATUS.md)** - Current system health and technical debt

### For System Rebuilding
1. **[IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)** - Step-by-step rebuild guide from scratch

## 🆘 Support

For questions about the documentation or system:
- Check the main [README.md](../README.md) for contact information
- Review the specific feature documentation for detailed implementation notes
- Refer to the admin setup guide for configuration issues 