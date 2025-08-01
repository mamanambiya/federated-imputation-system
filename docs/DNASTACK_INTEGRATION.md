# DNASTACK API Integration

## Overview
DNASTACK is now supported as a third API type alongside Michigan and GA4GH. This integration enables connection to DNASTACK Omics platforms for genomic data access and imputation services.

## API Types Available
1. **Michigan Imputation Server API** - Traditional imputation server API
2. **GA4GH Service Info** - Workflow Execution Service (WES) standard
3. **DNASTACK Omics API** - Cloud-native genomic data platform

## DNASTACK Features

### Connection Testing
- Simple HTTP connectivity check to verify endpoint accessibility
- Detects authentication requirements (401 status)
- Extracts domain for factory pattern usage
- Returns installation instructions for client library

### Service Configuration
When setting up a DNASTACK service:
- **API URL**: The base URL of the DNASTACK platform (e.g., `https://elwazi.omics.ai`)
- **API Type**: Select "DNASTACK Omics API"
- **Authentication**: May require Bearer token in API Key field

### Reference Panels
DNASTACK services can have custom reference panels that represent:
- DataConnect datasets
- African genomic variation databases
- Population-specific reference panels

## Setup Example

### Quick Setup
```bash
# Run the example setup command
docker-compose exec web python manage.py setup_dnastack_example
```

This creates:
- eLwazi Omics Platform service
- Two African-specific reference panels

### Manual Setup
1. Go to Admin → Imputation → Imputation services
2. Click "Add Service (Setup Wizard)"
3. Fill in:
   - Name: Your DNASTACK service name
   - Service Type: H3Africa (or appropriate type)
   - API Type: DNASTACK Omics API
   - API URL: https://your-domain.omics.ai
   - API Key: Your bearer token (if required)
4. Click "Test Connection"
5. Save the service
6. Sync panels to populate reference datasets

## Using DNASTACK Client Library

### Installation
```bash
pip3 install -U dnastack-client-library
```

### Basic Usage
```python
from dnastack import use
from dnastack import DataConnectClient

# Initialize factory with your domain
factory = use('elwazi.omics.ai')

# Get specific data connect client
data_connect_client = factory.get('data-connect-elwazi-catalogue-katherine')

# Query genomic data
result_iterator = data_connect_client.query("""
    SELECT * 
    FROM collections.elwazi_catalogue_katherine.elwazi_agvd_allele_frequencies_sample
    LIMIT 10
""")

# Process results
for row in result_iterator:
    print(row)
```

## API Configuration Storage
The system stores DNASTACK-specific configuration in the `api_config` JSON field:
- `dnastack_factory`: Domain for factory initialization
- `data_connect_endpoints`: Available DataConnect endpoints
- `install_command`: Client library installation command
- `usage_example`: Code example for using the service

## Testing Connection
The connection test for DNASTACK:
1. Sends HTTP GET request to the API URL
2. Accepts status codes: 200 (OK), 302 (Redirect), 401 (Auth Required)
3. Extracts domain for factory pattern
4. Returns service information and usage instructions

## Future Enhancements
1. **DataConnect Integration**: Direct querying of genomic datasets
2. **Dataset Discovery**: Automatic detection of available datasets
3. **Schema Inspection**: View table schemas and available columns
4. **Query Builder**: Visual interface for building DataConnect queries
5. **Result Caching**: Cache query results for performance

## Example Services
- **eLwazi Omics Platform**: African genomic data platform
- **Custom DNASTACK Instance**: Your organization's DNASTACK deployment

## Security Notes
- API keys/tokens are stored encrypted in the database
- HTTPS is enforced for all DNASTACK connections
- Authentication tokens should have minimal required permissions

## Troubleshooting

### Connection Failed
- Verify the API URL is correct and accessible
- Check if authentication is required
- Ensure network connectivity to the DNASTACK platform

### Authentication Issues
- Verify your API key/bearer token is correct
- Check token expiration
- Ensure token has required permissions

### Client Library Issues
- Update to latest version: `pip3 install -U dnastack-client-library`
- Check Python version compatibility (3.7+)
- Verify network access for package installation 