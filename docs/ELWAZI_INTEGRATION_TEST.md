# Elwazi Pilot Integration Testing

## Overview

This document describes the integration testing approach based on the [Elwazi pilot node testing pattern](https://github.com/elwazi/elwazi-pilot-node-install/blob/main/resources/south-africa/orchestrator/elwazi-pilot-node-tests.ipynb).

The Elwazi notebook demonstrates a **federated scatter-gather workflow** that is conceptually identical to our federated imputation platform:

1. **Discovery**: Query services to find available computational nodes
2. **Scatter**: Distribute jobs to nodes based on data locality and capabilities
3. **Execute**: Run workflows on distributed nodes using GA4GH standards
4. **Gather**: Collect results from multiple nodes and aggregate

## Test Files

### 1. Python Test Script
**Location**: [`tests/test_federated_workflow.py`](../tests/test_federated_workflow.py)

A standalone Python script that tests all platform endpoints:

```bash
# Run the test
python3 tests/test_federated_workflow.py
```

**Tests performed**:
- ✅ Authentication (JWT token-based)
- ✅ Service Discovery (finding distributed nodes)
- ✅ Reference Panel Management
- ✅ Dashboard Statistics
- ✅ Scatter-Gather Pattern (grouping services by capability)

### 2. Jupyter Notebook
**Location**: [`tests/federated_imputation_test.ipynb`](../tests/federated_imputation_test.ipynb)

An interactive notebook for exploratory testing and demonstrations.

```bash
# Launch Jupyter
jupyter notebook tests/federated_imputation_test.ipynb
```

## Architecture Comparison

### Elwazi Pattern
```
┌─────────────────────────────────────────────────────┐
│ Central Orchestrator (Data Connect + WES Registry) │
└────────────────┬────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
   ┌────▼────┐       ┌───▼────┐
   │ Node 1  │       │ Node 2 │
   │ (Mali)  │       │(Uganda)│
   │ DRS+WES │       │DRS+WES │
   └────┬────┘       └───┬────┘
        │                │
     Execute          Execute
     flagstat         flagstat
        │                │
        └────────┬───────┘
                 │
            Gather Results
                 │
         Run MultiQC on Central
```

### Our Federated Imputation Platform
```
┌──────────────────────────────────────────────────┐
│ Central Orchestrator (Service Registry + Jobs)  │
└────────────────┬─────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
   ┌────▼────┐       ┌───▼────┐
   │Service 1│       │Service2│
   │ (Mali)  │       │(S.Africa)
   │H3Africa │       │1000G   │
   └────┬────┘       └───┬────┘
        │                │
     Execute          Execute
     Imputation       Imputation
        │                │
        └────────┬───────┘
                 │
         Gather Results
                 │
          User Downloads
```

## Key Similarities

### 1. Service Discovery
**Elwazi**: Query Data Connect to find DRS objects across nodes
```python
# Query for African population samples
q = "SELECT cram_drs_id FROM genome_ilifu WHERE super_population_id='AFR'"
results = data_connect.query(q)
```

**Our Platform**: Query Service Registry to find imputation services
```python
# Get services grouped by reference panel
services = api.get_services(reference_panel='h3africa_v6')
healthy_services = [s for s in services if s['is_available']]
```

### 2. Scatter-Gather Execution
**Elwazi**: Launch flagstat on each node, gather results
```python
for drs_server in drs_servers:
    # Scatter: Launch workflow on each node
    run_id = wes_client.run_workflow(
        workflow_url="https://github.com/grbot/flagstat",
        drs_objects=drs_servers[drs_server]['drs_ids']
    )

# Gather: Combine results with MultiQC
multiqc_run = wes_client.run_workflow(
    workflow_url="https://github.com/grbot/multiqc",
    input_files=all_flagstat_results
)
```

**Our Platform**: Submit imputation job, system handles distribution
```python
# User submits job
job = api.create_job(
    input_file=vcf_file,
    reference_panel='h3africa_v6',
    chromosome='22'
)

# System automatically:
# 1. Finds available services with h3africa_v6 panel
# 2. Distributes work (scatter)
# 3. Monitors execution
# 4. Collects results (gather)
```

### 3. GA4GH Standards Alignment
Both platforms leverage GA4GH standards:

| Standard | Elwazi | Our Platform |
|----------|--------|--------------|
| **WES** (Workflow Execution) | ✅ For running flagstat/MultiQC | ✅ For running imputation workflows |
| **DRS** (Data Repository) | ✅ For accessing genomic files | ⏳ Planned for reference panels |
| **TES** (Task Execution) | ⏳ Future | ⏳ Planned |
| **Data Connect** | ✅ For querying samples | ⏳ Planned for dataset discovery |

## Test Results

### Current System Status

```
============================================================
FEDERATED IMPUTATION PLATFORM - INTEGRATION TEST
============================================================

1. Testing Authentication...
   ✓ Login successful! Token: eyJhbGciOiJIUzI1NiIsInR5cCI6Ik...

2. Testing Service Discovery...
   ✓ Found 5 services (2 available)
     ✓ H3Africa Imputation Service (healthy)
        URL: https://impute.afrigen-d.org/
        Location: Cape Town, South Africa
     ✓ ILIFU GA4GH Starter Kit (healthy)
        URL: http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1
        Location: Cape Town, South Africa

3. Testing Reference Panels...
   ✓ Found 3 reference panels
     - 1kg_p3 (hg19)
     - 1000genomes_phase3 (hg19)
     - h3africa_v6 (hg38)

4. Testing Dashboard Stats...
   ✓ Dashboard Statistics:
     Total Jobs: 0
     Completed: 0
     Failed: 0
     Running: 0
     Available Services: 2

5. Testing Scatter-Gather Pattern...
   ✓ Services grouped by reference panel capabilities

============================================================
TEST SUMMARY
============================================================
✓ PASS - Authentication
✓ PASS - Service Discovery
✓ PASS - Reference Panels
✓ PASS - Dashboard Stats
✓ PASS - Scatter-Gather Pattern

5/5 tests passed
```

## Lessons from Elwazi

### 1. Polling Pattern for Async Jobs
Elwazi uses a polling loop to monitor job status:
```python
while monitor_run_response.json()["state"] != "COMPLETE":
    print("Current job status: " + monitor_run_response.json()["state"])
    time.sleep(5)
    monitor_run_response = requests.request(http_method, request_url)
```

**Applied to our platform**: Job monitoring endpoint with status updates

### 2. Service Health Monitoring
Elwazi checks WES/DRS service-info endpoints before launching jobs:
```python
wes_service_info_resp = requests.get(f"{wes_base_url}/service-info")
```

**Applied to our platform**: Regular health checks stored in service registry

### 3. Geographic Distribution
Elwazi demonstrates true federated execution across countries (South Africa, Mali, Uganda).

**Our platform**: Supports distributed services but needs more geographic nodes deployed

### 4. DRS for Data Locality
Elwazi uses DRS URIs to ensure data doesn't move unnecessarily:
```python
input_file = "drs://osdp.ace.ac.ug:5000/6fa43c7de04b60c1a73a42aa2efc977d"
```

**Recommendation**: Implement DRS for reference panel access to avoid data transfer

## Running End-to-End Tests

### Prerequisites
```bash
# Ensure backend is running
docker-compose up -d

# Create test user (if needed)
curl -X POST http://154.114.10.123:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "testuser@example.com",
    "password": "testpass123",
    "first_name": "Test",
    "last_name": "User"
  }'
```

### Run Tests
```bash
# Quick test
python3 tests/test_federated_workflow.py

# Interactive testing
jupyter notebook tests/federated_imputation_test.ipynb

# Test with actual imputation job (requires VCF file)
python3 tests/test_federated_workflow.py --with-job-execution
```

## Future Enhancements

Based on Elwazi's pattern, we should add:

1. **Data Connect Integration** - Query available datasets across nodes
2. **DRS Support** - Reference panels as DRS objects
3. **Workflow Provenance** - Track data lineage like WES run logs
4. **Multi-Node Execution** - True parallel execution across geographic nodes
5. **Result Aggregation** - Combine results from multiple nodes intelligently

## References

- [Elwazi Pilot Node Tests](https://github.com/elwazi/elwazi-pilot-node-install/blob/main/resources/south-africa/orchestrator/elwazi-pilot-node-tests.ipynb)
- [GA4GH WES Specification](https://github.com/ga4gh/workflow-execution-service-schemas)
- [GA4GH DRS Specification](https://github.com/ga4gh/data-repository-service-schemas)
- [GA4GH Data Connect](https://github.com/ga4gh-discovery/data-connect)

## Conclusion

The Elwazi pilot demonstrates a proven pattern for federated genomic analysis that aligns perfectly with our platform's architecture. Their approach validates our design choices and provides a roadmap for future enhancements, particularly around GA4GH standards integration and true multi-node distributed execution.

**Key Takeaway**: Both platforms solve the same problem—bringing computation to data rather than moving sensitive genomic data across networks—using similar federated scatter-gather patterns and GA4GH standards.
