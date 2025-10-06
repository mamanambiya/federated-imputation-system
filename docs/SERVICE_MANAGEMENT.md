# Service Management Guide

## Overview

The Federated Genomic Imputation Platform is a **dynamic system** with no hardcoded services. Administrators must register imputation services through the API or web interface.

### Service Management Flow

```
┌────────────────────────────────────────────────────────────────┐
│                     SERVICE LIFECYCLE                          │
└────────────────────────────────────────────────────────────────┘

1. SERVICE REGISTRATION
   ┌───────────┐
   │   Admin   │
   └─────┬─────┘
         │
         │ POST /api/services/
         │ {name, base_url, api_type, ...}
         ↓
   ┌─────────────────┐
   │ Service Registry│
   │   Port 8002     │
   └────────┬────────┘
            │
            ↓
   [PostgreSQL service_db]
   Service Created ✅

2. HEALTH MONITORING (Automated - Every 5 min)
   ┌─────────────────┐
   │ Service Registry│
   │  Health Check   │
   └────────┬────────┘
            │
            │ GET {base_url}/health
            ↓
   ┌──────────────────┐
   │ External Service │
   │  (H3Africa, etc) │
   └────────┬─────────┘
            │
            ↓
   Update service status
   • healthy ✅
   • unhealthy ❌
   • timeout ⏱️

3. USER CONSUMPTION
   ┌──────┐
   │ User │
   └──┬───┘
      │
      │ 1. View available services
      ↓
   GET /api/services/
   Returns: Active + Healthy services
      │
      │ 2. Submit job to selected service
      ↓
   POST /api/jobs/
   {service_id, input_file, ...}
      │
      ↓
   Worker submits to external service
   using user's credentials
```

## Current State

- **Registered Services**: 0
- **Dashboard Shows**: 0 Available Services
- **Services Page**: Empty state
- **New Job Page**: No services available for selection

## How to Add Imputation Services

### Option 1: Using the API (Programmatic)

```bash
# Authentication
TOKEN="your-jwt-token-here"
BASE_URL="http://154.114.10.123:8000/api"

# Create a service
curl -X POST "$BASE_URL/services/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Michigan Imputation Server",
    "service_type": "michigan",
    "api_type": "michigan",
    "base_url": "https://imputationserver.sph.umich.edu/api/v2",
    "description": "The Michigan Imputation Server provides free genotype imputation.",
    "version": "2.0",
    "requires_auth": true,
    "auth_type": "token",
    "max_file_size_mb": 500,
    "supported_formats": ["vcf", "vcf.gz"],
    "supported_builds": ["hg19", "hg38"],
    "is_active": true,
    "is_available": true
  }'
```

### Option 2: Using the Web Interface (Planned)

A service management UI will be added in future releases to allow:
- Adding new services through a form
- Editing existing service configurations
- Testing service connectivity
- Enabling/disabling services

## Service Types

The platform supports multiple imputation service types:

### API Type Architecture

```
┌─────────────────────────────────────────────────────────────┐
│               FEDERATED IMPUTATION PLATFORM                 │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │           Service Registry (Port 8002)              │  │
│  │  • Discovers services                                │  │
│  │  • Tracks health                                     │  │
│  │  • Routes requests                                   │  │
│  └──────┬──────────────┬──────────────┬────────────────┘  │
│         │              │              │                    │
└─────────┼──────────────┼──────────────┼────────────────────┘
          │              │              │
          ↓              ↓              ↓
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │ MICHIGAN │   │  GA4GH   │   │ DNASTACK │
    │   API    │   │   WES    │   │  OMICS   │
    └──────────┘   └──────────┘   └──────────┘
          │              │              │
          ↓              ↓              ↓
    ┌──────────────────────────────────────────┐
    │        EXTERNAL SERVICES                 │
    ├──────────────────────────────────────────┤
    │  • Michigan Imputation Server            │
    │  • H3Africa (uses Michigan API)          │
    │  • TOPMed (uses Michigan API)            │
    │  • Any GA4GH WES compatible service      │
    │  • DNAstack Workbench                    │
    └──────────────────────────────────────────┘
```

### Michigan API Format
- **Type**: `michigan`, `h3africa`, `topmed`
- **API Type**: `michigan`
- Used by: Michigan Imputation Server, H3Africa, TOPMed, etc.

### GA4GH Format
- **Type**: `ga4gh`
- **API Type**: `ga4gh`
- Standards-compliant genomics API

### DNAStack Format
- **Type**: `dnastack`
- **API Type**: `dnastack`
- Cloud-native genomics platform

## Required Service Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Human-readable service name |
| `service_type` | string | Yes | Service category (michigan, h3africa, ga4gh, etc.) |
| `api_type` | string | Yes | API protocol (michigan, ga4gh, dnastack) |
| `base_url` | URL | Yes | Service API endpoint |
| `description` | string | No | Service description for users |
| `version` | string | No | API version |
| `requires_auth` | boolean | No | Whether authentication is required (default: true) |
| `auth_type` | string | No | Authentication method (token, oauth2, api_key) |
| `max_file_size_mb` | integer | No | Maximum upload size in MB (default: 100) |
| `supported_formats` | array | No | Supported file formats (vcf, plink, bgen, etc.) |
| `supported_builds` | array | No | Supported genome builds (hg19, hg38, etc.) |
| `is_active` | boolean | No | Whether service is active (default: true) |

## Service Management Operations

### List All Services
```bash
GET /api/services/
```

### Get Service Details
```bash
GET /api/services/{service_id}
```

### Update Service
```bash
PATCH /api/services/{service_id}
```

### Delete Service
```bash
DELETE /api/services/{service_id}
```

### Health Check
The system automatically performs health checks on registered services every 5 minutes. Health status is visible in:
- Service details page
- Dashboard statistics
- Service list with status indicators

## Popular Imputation Services

Here are some commonly used genomic imputation services you may want to register:

### 1. Michigan Imputation Server
- **URL**: https://imputationserver.sph.umich.edu/api/v2
- **Type**: michigan
- **Access**: Free with registration
- **Speciality**: Large reference panels, widely used

### 2. H3Africa Imputation Server
- **URL**: https://imputation.h3abionet.org/api/v2
- **Type**: h3africa
- **Access**: Free with registration
- **Speciality**: African ancestry populations

### 3. TOPMed Imputation Server
- **URL**: https://imputation.biodatacatalyst.nhlbi.nih.gov/api/v2
- **Type**: topmed
- **Access**: Free with NIH registration
- **Speciality**: Deep WGS coverage, diverse populations

## Security Considerations

1. **No Default Services**: The system ships with no registered services for security
2. **Admin Control**: Only authenticated administrators can register services
3. **URL Validation**: Service URLs are validated before registration
4. **Health Monitoring**: Services are continuously monitored for availability
5. **Access Control**: Future releases will support per-service user permissions

## Troubleshooting

### "No services available"
- **Cause**: No services have been registered yet
- **Solution**: Register at least one imputation service using the API

### "Service unhealthy"
- **Cause**: Service URL is unreachable or returns errors
- **Solution**: Verify the service URL and check network connectivity

### "Service timeout"
- **Cause**: Service is slow or not responding
- **Solution**: Increase timeout or check service status

## Next Steps

1. **Register Your First Service**: Use the API example above to add an imputation service
2. **Verify Registration**: Check the Services page to see your registered service
3. **Test Connectivity**: The system will automatically perform health checks
4. **Create Jobs**: Once services are registered, users can create imputation jobs

## Support

For questions or issues with service management:
- Check the system logs: `docker logs service-registry`
- Review API documentation: `/docs/API_DOCUMENTATION.md`
- Contact your system administrator
