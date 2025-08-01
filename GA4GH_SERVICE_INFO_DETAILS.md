# GA4GH WES Service Info - Comprehensive Data Extraction

## Overview
The GA4GH WES service-info endpoint provides extensive metadata about the workflow execution service. Our implementation now extracts and utilizes all available information.

## Data Extracted from Service Info

### 1. **Basic Service Information**
- **WES API Version**: Supported versions (e.g., "1.0.0")
- **Authentication Instructions**: URL for auth documentation
- **Contact Information**: Email or URL for support
- **Service Tags**: Key-value pairs for service metadata

### 2. **Workflow Engine Details**
- **Engine Types**: Nextflow (NFL), Snakemake (SMK)
- **Engine Versions**: Specific versions (e.g., "22.10.0")
- **Workflow Type Versions**: Supported workflow definition versions

### 3. **System State Information**
- **Total Jobs**: Sum of all jobs in the system
- **Job States**: Detailed breakdown by state:
  - `QUEUED`: Jobs waiting to start
  - `INITIALIZING`: Jobs being prepared
  - `RUNNING`: Active jobs
  - `PAUSED`: Suspended jobs
  - `COMPLETE`: Successfully finished jobs
  - `EXECUTOR_ERROR`: Jobs failed during execution
  - `SYSTEM_ERROR`: Jobs failed due to system issues
  - `CANCELED`: User-canceled jobs
  - `CANCELING`: Jobs being canceled

### 4. **Workflow Parameters**
Each workflow engine has configurable parameters:

#### Nextflow (NFL) Parameters:
- `accounting-name`: HPC accounting name
- `job-name`: Job identifier
- `group`: User group
- `queue`: HPC queue name
- `trace`: Enable execution trace (default: true)
- `timeline`: Generate timeline report (default: true)
- `graph`: Generate workflow graph (default: true)
- `report`: Generate execution report (default: true)

#### Snakemake (SMK) Parameters:
- `engine-environment`: Execution environment
- `max-memory`: Memory limit (default: 100m)
- `max-runtime`: Time limit (default: 05:00)
- `accounting-name`: HPC accounting
- `job-name`: Job identifier
- `group`: User group
- `queue`: HPC queue

### 5. **Storage Protocol Support**
- **file**: Local filesystem
- **S3**: Amazon S3 compatible storage

## Implementation Features

### Enhanced Test Connection
When testing a GA4GH service connection, the system now displays:
- Service type and WES version
- All workflow engines with versions
- Total jobs and state breakdown
- Number of configurable parameters per engine
- Supported storage protocols
- Service tags
- Authentication requirements

### Intelligent Panel Creation
For GA4GH services, "reference panels" are created as workflows:
- One panel per workflow engine version
- Description includes parameter count
- Population marked as "Configurable"
- Supports both hg38 and hg19 builds

### Service Info Caching
- Full service-info response is cached in `api_config`
- Cache expires after 1 hour
- Reduces API calls for frequently accessed services
- Stored with timestamp for freshness checking

## Example Service Info Response

### eLwazi Node Service
```json
{
  "supported_wes_versions": ["1.0.0"],
  "workflow_engine_versions": {
    "NFL": "22.10.0",
    "SMK": "6.10.0"
  },
  "system_state_counts": {
    "EXECUTOR_ERROR": 6,
    "COMPLETE": 0,
    "RUNNING": 0
  },
  "supported_filesystem_protocols": ["file", "S3"],
  "tags": {
    "tag1": "value1",
    "tag2": "value2"
  },
  "default_workflow_engine_parameters": [
    // 8 Nextflow parameters
    // 7 Snakemake parameters
  ]
}
```

## Usage in Admin Interface

### Service Setup
1. Enter GA4GH WES URL
2. Click "Test Connection"
3. View comprehensive service information:
   - Workflow engines available
   - Current job statistics
   - Parameter counts
   - Storage options

### Reference Panel Sync
1. Select service and sync panels
2. System creates workflow-based panels:
   - NFL 22.10.0 Imputation Workflow (8 parameters)
   - SMK 6.10.0 Imputation Workflow (7 parameters)

### Advanced Configuration
The full service-info response is stored in `api_config['_service_info']` for:
- Custom workflow parameter extraction
- Advanced service monitoring
- Integration with workflow submission

## Benefits

1. **Complete Information**: Extracts all available metadata
2. **Smart Defaults**: Uses service info to configure panels
3. **Performance**: Caches responses to reduce API calls
4. **Flexibility**: Stores full response for custom processing
5. **User-Friendly**: Presents complex data in readable format

## Future Enhancements

1. **Parameter Templates**: Pre-fill workflow parameters based on defaults
2. **Job Monitoring**: Use system state for real-time monitoring
3. **Storage Integration**: Auto-configure S3 based on protocol support
4. **Workflow Discovery**: List available workflows from service
5. **Dynamic Forms**: Generate submission forms from parameters 