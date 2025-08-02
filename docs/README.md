# Federated Genomic Imputation Platform Documentation

This directory contains comprehensive documentation for the Federated Genomic Imputation Platform.

## 📚 Documentation Index

### Setup and Installation
- **[SETUP.md](./SETUP.md)** - Complete setup and installation guide for the federated imputation system
- **[IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)** - Complete implementation guide for rebuilding the system from scratch
- **[ROADMAP.md](./ROADMAP.md)** - Development roadmap and future planning

### Feature Guides
- **[MULTI_SERVICE_FEATURE.md](./MULTI_SERVICE_FEATURE.md)** - Multi-service selection functionality for job submission
- **[SERVICE_MODAL_IMPLEMENTATION.md](./SERVICE_MODAL_IMPLEMENTATION.md)** - Service selection modal dialog implementation details
- **[SERVICE_DETAIL_PAGE.md](./SERVICE_DETAIL_PAGE.md)** - User-facing service detail page documentation
- **[SERVICES_CONSOLIDATION.md](./SERVICES_CONSOLIDATION.md)** - Service consolidation and reference panel management

### Admin and Configuration
- **[ADMIN_SERVICE_SETUP.md](./ADMIN_SERVICE_SETUP.md)** - Admin interface for setting up and configuring imputation services

### API Integration Guides
- **[GA4GH_IMPLEMENTATION_SUMMARY.md](./GA4GH_IMPLEMENTATION_SUMMARY.md)** - GA4GH WES API integration overview
- **[GA4GH_SERVICE_INFO_DETAILS.md](./GA4GH_SERVICE_INFO_DETAILS.md)** - Detailed GA4GH service-info endpoint implementation
- **[DNASTACK_INTEGRATION.md](./DNASTACK_INTEGRATION.md)** - DNASTACK Omics API integration guide

## 🏗️ Architecture Overview

The system supports three main API types:

1. **Michigan Imputation Server API** - Traditional imputation service protocol
2. **GA4GH WES (Workflow Execution Service)** - Standardized workflow execution 
3. **DNASTACK Omics API** - Genomic data platform integration

## 🔗 Quick Links

- [Main README](../README.md) - Project overview and quick start
- [Frontend Documentation](../frontend/README.md) - React frontend specifics
- [Backend API](../imputation/) - Django backend implementation

## 📖 Reading Order

For new developers, we recommend reading the documentation in this order:

1. [SETUP.md](./SETUP.md) - Get the system running
2. [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) - Complete development guide for building from scratch
3. [ROADMAP.md](./ROADMAP.md) - Understand the project vision and future plans
4. [GA4GH_IMPLEMENTATION_SUMMARY.md](./GA4GH_IMPLEMENTATION_SUMMARY.md) - Understand the architecture
5. [ADMIN_SERVICE_SETUP.md](./ADMIN_SERVICE_SETUP.md) - Learn service configuration
6. [MULTI_SERVICE_FEATURE.md](./MULTI_SERVICE_FEATURE.md) - Understand user workflows
7. [SERVICE_DETAIL_PAGE.md](./SERVICE_DETAIL_PAGE.md) - User interface details

## 🆘 Support

For questions about the documentation or system:
- Check the main [README.md](../README.md) for contact information
- Review the specific feature documentation for detailed implementation notes
- Refer to the admin setup guide for configuration issues 