# Admin Service Setup Guide

## Overview
The Federated Imputation System now supports admin configuration of imputation services with two API types:
- **Michigan Imputation Server API**
- **GA4GH Service Info API**

## Accessing the Admin Interface

1. Navigate to `/admin/` and login with admin credentials
2. Go to **Imputation > Imputation services**
3. Click **"Add Service (Setup Wizard)"** to add a new service

## Service Setup Features

### 1. Basic Information
- **Name**: Display name for the service
- **Service Type**: Choose between H3Africa or Michigan
- **API Type**: Select the API protocol:
  - **Michigan Imputation Server API**: Standard Michigan server protocol
  - **GA4GH Service Info**: GA4GH standardized API
- **API URL**: The base URL of the imputation service
- **Description**: Optional description of the service

### 2. API Configuration
- **API Key**: Authentication key (stored securely)
- **API Key Required**: Whether authentication is required
- **API Config**: Additional JSON configuration for API-specific settings

### 3. Service Limits
- **Max File Size (MB)**: Maximum upload file size
- **Supported Formats**: JSON array of supported file formats (e.g., ["vcf", "vcf.gz"])

### 4. Test Connection
Click the **"Test Connection"** button to verify:
- API endpoint is reachable
- Authentication works (if required)
- Service information can be retrieved

## API Type Details

### Michigan Imputation Server API
- Standard API used by Michigan Imputation Server
- Authentication via `X-Auth-Token` header
- Endpoints:
  - `/api/v2/server` - Server information
  - `/api/v2/jobs` - Job management
  - `/api/v2/panels` - Reference panels

### GA4GH Service Info API (WES)
- Follows GA4GH WES (Workflow Execution Service) specifications
- Authentication via `Bearer` token (optional)
- Standard endpoints:
  - `/service-info` - Service metadata and capabilities
  - `/runs` - Submit and list workflow runs
  - `/runs/{run_id}` - Get run details
  - `/runs/{run_id}/status` - Get run status
  - `/runs/{run_id}/cancel` - Cancel a run
- Supports workflow engines like Nextflow (NFL) and Snakemake (SMK)
- Examples:
  - http://elwazi-node.icermali.org:6000/ga4gh/wes/v1
  - http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1

## Managing Services

### Edit Service
1. Click on a service name in the list
2. Use the standard Django admin interface or
3. Click "Setup Wizard" for the enhanced interface

### Sync Reference Panels
1. Select one or more services
2. Choose "Sync reference panels" from the Actions dropdown
3. The system will fetch available panels from the service

### View Reference Panels
Click the panel count link (e.g., "5 panels") to see all panels for a service

## Example Configurations

### Michigan Server Example
```json
{
  "name": "Michigan Imputation Server",
  "service_type": "michigan",
  "api_type": "michigan",
  "api_url": "https://imputationserver.sph.umich.edu",
  "api_key": "your-api-key-here",
  "supported_formats": ["vcf", "vcf.gz"],
  "max_file_size_mb": 200
}
```

### GA4GH WES Service Example
```json
{
  "name": "H3Africa Imputation Service",
  "service_type": "h3africa",
  "api_type": "ga4gh",
  "api_url": "http://elwazi-node.icermali.org:6000/ga4gh/wes/v1",
  "api_key": "",
  "supported_formats": ["vcf", "vcf.gz", "plink"],
  "max_file_size_mb": 100,
  "api_config": {
    "workflow_id": "imputation-nf",
    "workflow_engine": "NFL",
    "workflow_params": {
      "reference_panel": "african_panel_hg38",
      "imputation_method": "minimac4"
    }
  }
}
```

### Real GA4GH WES Response Example
Based on the [elwazi-node service](http://elwazi-node.icermali.org:6000/ga4gh/wes/v1/service-info), a GA4GH WES service provides:
- Workflow engine versions (e.g., Nextflow 22.10.0, Snakemake 6.10.0)
- Supported WES API versions
- System state counts (running, completed, failed jobs)
- Supported filesystem protocols (file, S3)
- Default workflow parameters

## Security Notes

- API keys are stored encrypted in the database
- Test connections are made server-side to protect credentials
- Admin access is required to manage services
- Service configuration changes are logged

## Quick Setup

### Using Example Services
To quickly set up the example GA4GH services, run:
```bash
docker-compose exec web python manage.py setup_example_services
```

This will create:
- **eLwazi Node Imputation Service** - http://elwazi-node.icermali.org:6000/ga4gh/wes/v1
- **ILIFU GA4GH Starter Kit** - http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1

Each service will have example Nextflow and Snakemake workflow panels configured.

## Troubleshooting

### Connection Test Fails
1. Verify the API URL is correct and accessible
2. Check if API key is required and provided
3. Ensure the server allows connections from your IP
4. Check the API type matches the server's protocol

### Reference Panels Not Syncing
1. Verify the service is active
2. Check API credentials are correct
3. Ensure the API type is correctly configured
4. Review server logs for detailed error messages 