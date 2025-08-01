# Service Detail Page Documentation

## Overview
A comprehensive Service Detail Page has been added to the admin interface that displays all available information about imputation services, especially rich metadata from GA4GH WES services.

## Accessing the Detail Page

### From Service List
1. Go to Admin → Imputation → Imputation services
2. Click "View Details" button in the service row
3. Or click on the service name link

### Direct URL
`/admin/imputation/imputationservice/<service_id>/detail/`

## Page Sections

### 1. Action Buttons
- **Edit Service**: Standard Django admin edit
- **Setup Wizard**: Enhanced service configuration
- **Sync Panels**: Fetch reference panels from service
- **Refresh Info**: Update cached service information

### 2. Basic Information
Displays core service configuration:
- Service Type (H3Africa/Michigan)
- API Type (Michigan/GA4GH)
- Status (Active/Inactive)
- API URL with direct link
- Maximum file size
- Supported formats
- Description

### 3. GA4GH WES Service Information
For GA4GH services, displays comprehensive metadata:

#### Service Metadata
- WES API versions supported
- Contact information with clickable links
- Authentication documentation URL
- Cache status (shows how old the cached data is)

#### Workflow Engines
- Available engines (Nextflow, Snakemake)
- Version numbers for each engine

#### System State
- Visual job state breakdown showing:
  - QUEUED, INITIALIZING, RUNNING jobs
  - COMPLETE, CANCELED jobs
  - EXECUTOR_ERROR, SYSTEM_ERROR counts
- Total job count
- Highlighted states with active jobs

#### Storage Protocols
- Supported protocols (file, S3)
- Visual checkmarks for each protocol

#### Workflow Parameters
- Grouped by engine (NFL, SMK)
- Shows parameter name, type, and default value
- Scrollable list for many parameters
- Parameter count in header

#### Service Tags
- Key-value pairs from service metadata
- Displayed in grid format

### 4. Reference Panels
Lists all configured panels with:
- Panel name and ID
- Population and build information
- Sample counts
- Descriptions
- Link to sync if no panels exist

### 5. Advanced Configuration
- **API Configuration**: Full JSON configuration
- **Raw Service Info**: Complete service-info response
- Scrollable JSON viewers with syntax highlighting

## Features

### Data Caching
- Service info is cached for 1 hour
- Cache age displayed in real-time
- Manual refresh available

### Visual Design
- Clean card-based layout
- Responsive grid system
- Color-coded job states
- Professional styling matching Django admin

### Information Hierarchy
- Most important info at top
- Technical details in collapsible sections
- Raw data at bottom for developers

## Example Views

### GA4GH Service Details
Shows:
- Workflow engines: NFL 22.10.0, SMK 6.10.0
- Job states: EXECUTOR_ERROR: 6, INITIALIZING: 2
- Parameters: NFL (8), SMK (7)
- Protocols: file, S3
- Tags and metadata

### Michigan Service Details
Shows:
- Basic configuration
- Reference panels
- API configuration

## Benefits

1. **Complete Visibility**: See all service information in one place
2. **Real-time Status**: Current job counts and system state
3. **Configuration Reference**: All parameters and settings visible
4. **Debugging Aid**: Raw JSON for troubleshooting
5. **Quick Actions**: Easy access to edit, sync, and refresh

## Technical Implementation

### Backend
- `ServiceDetailView` class in `admin_views.py`
- `get_service_info()` method on model for caching
- Intelligent parameter extraction and grouping

### Frontend
- Custom Django admin template
- CSS grid layout for responsive design
- JavaScript-free implementation

### URLs
- `/admin/imputation/imputationservice/<id>/detail/` - Detail view
- `/admin/imputation/imputationservice/<id>/refresh/` - Force refresh

## Future Enhancements

1. **Live Updates**: WebSocket for real-time job counts
2. **Parameter Forms**: Edit workflow parameters inline
3. **Job History**: Graph of job states over time
4. **Service Health**: Uptime and response time monitoring
5. **Export Options**: Download service config as JSON/YAML 