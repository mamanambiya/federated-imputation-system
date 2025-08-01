# Multi-Service Selection Feature

## Overview
The Federated Imputation System now supports selecting multiple imputation services for a single job submission. This allows users to run the same analysis across different services (H3Africa and Michigan) simultaneously.

## Key Changes

### Frontend Updates

1. **Service Selection (NewJob.tsx)**
   - Changed from single Select dropdown to multiple Checkbox selection
   - Users can now select one or more services
   - Each selected service shows its available reference panels

2. **Data Structure**
   - `jobData.service` → `jobData.services[]` (array of service IDs)
   - `jobData.reference_panel` → `jobData.reference_panels{}` (map of serviceId to panelId)

3. **Reference Panel Selection**
   - Shows a separate panel selection dropdown for each selected service
   - Each service displays its own reference panels
   - Validation ensures all selected services have panels chosen

4. **Job Submission**
   - Creates one job per selected service
   - Automatically appends service name to job name for clarity
   - Uses Promise.all to submit jobs in parallel
   - Navigates to the first job's detail page after submission

5. **Review Step**
   - Updated to show all selected services and their panels
   - Clear bullet-point list of service-panel combinations

## How to Use

1. Navigate to "New Job" (/jobs/new)
2. Upload your VCF/PLINK/BGEN file
3. Select one or more imputation services using checkboxes
4. For each selected service, choose a reference panel
5. Configure job parameters (name, format, build, etc.)
6. Review and submit

## Benefits

- **Comparison**: Easy comparison of results from different services
- **Redundancy**: If one service fails, others may still complete
- **Efficiency**: Submit once, run on multiple services
- **Flexibility**: Choose different reference panels for each service

## Technical Details

- Frontend validates that all selected services have panels
- Each job is submitted independently to maintain backend compatibility
- No backend changes required - uses existing single-service job model
- Jobs are named with service suffix for easy identification

## Future Enhancements

- Group view for related jobs
- Comparison tools for results from different services
- Batch status updates for multi-service submissions 