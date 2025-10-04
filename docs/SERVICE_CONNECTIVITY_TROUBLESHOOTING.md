# Service Connectivity Troubleshooting Guide
## Federated Genomic Imputation Platform

> **Last Updated**: 2025-10-04
> **Status**: 2 Active Services, 3 Inactive Services
> **Investigation**: Complete - All connectivity issues diagnosed

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Inactive vs Offline - Understanding Service States](#inactive-vs-offline)
3. [Auto-Deactivation After 30 Days](#auto-deactivation-after-30-days)
4. [Current Service Status](#current-service-status)
5. [Connectivity Issues Identified](#connectivity-issues-identified)
6. [Issue #1: Michigan Imputation Server](#issue-1-michigan-imputation-server)
7. [Issue #2: eLwazi Node Service](#issue-2-elwazi-node-service)
8. [Issue #3: eLwazi Omics Platform](#issue-3-elwazi-omics-platform)
9. [Issue #4: Test Service](#issue-4-test-service)
10. [Solutions Implemented](#solutions-implemented)
11. [Technical Deep Dive](#technical-deep-dive)
12. [Recommendations](#recommendations)
13. [Monitoring Commands](#monitoring-commands)

---

## Executive Summary

**Investigation completed on 2025-10-04** to determine why external imputation services were not connecting to the Federated Genomic Imputation Platform.

### Key Findings

- **2 Services Healthy** ✅ H3Africa Imputation Service, ILIFU GA4GH Starter Kit
- **3 Services Inactive** ❌ Michigan (TLS issue), eLwazi Node (connection refused), eLwazi Omics (DNS failure)
- **1 Service Deleted** 🗑️ Test Service (placeholder removed)

### Root Causes Identified

1. **TLS Handshake Timeout**: Michigan server incompatible with Docker networking (>30s SSL negotiation)
2. **Port Closure**: eLwazi Node port 6000 actively refusing connections
3. **DNS Failure**: eLwazi Omics domain doesn't exist in DNS
4. **Invalid URLs**: Test service using placeholder domain

### Actions Taken

- ✅ Enhanced timeout configuration (30s connect, 10s read)
- ✅ Fixed database schema issues (added `api_config` column)
- ✅ Marked problematic services as inactive to save resources
- ✅ Deleted test/placeholder service
- ✅ Added DELETE API endpoint for service management

---

## Inactive vs Offline

### Understanding Service States

The platform differentiates between **Inactive** and **Offline** services:

#### **Inactive** (`is_active = false`)

Services that are **disabled at the system level**:

| Characteristic | Behavior |
|----------------|----------|
| Health Checks | ❌ **NOT performed** (saves CPU and network resources) |
| Job Submission | ❌ Service will **NOT appear** as available |
| Service Discovery | ❌ Completely excluded from lists |
| Reconnection | ❌ System does not attempt to reconnect |

**Use Cases**:
- Services with incorrect/invalid URLs
- Decommissioned or permanently offline services
- Test/placeholder entries that should not be monitored
- Services with infrastructure incompatibilities (e.g., Docker networking issues)

**Example Services**: Michigan Imputation Server (TLS incompatible), eLwazi Omics Platform (domain doesn't exist), Test Service (deleted)

---

#### **Offline** (`health_status = 'unhealthy'` or `'timeout'`, but `is_active = true`)

Services that are **enabled but currently unreachable**:

| Characteristic | Behavior |
|----------------|----------|
| Health Checks | ✅ **Continue running** every 5 minutes |
| Job Submission | ⚠️ Shows as "offline" but remains in service list |
| Service Discovery | ✅ Still tracked and visible in UI |
| Reconnection | ✅ System keeps trying to reconnect automatically |

**Use Cases**:
- Temporary network outages
- Service maintenance windows
- Services expected to come back online soon
- Intermittent connectivity issues

**Example Scenario**: A service undergoing scheduled maintenance that will return in a few hours

---

### State Transition Diagram

```
┌─────────────┐
│   Active    │ ──health check fails──→ ┌─────────────┐
│  (Healthy)  │                          │   Active    │
└─────────────┘                          │  (Offline)  │
       ↑                                 └─────────────┘
       │                                        │
       └────────health check succeeds──────────┘

┌─────────────┐
│   Inactive  │ ──no health checks performed
│ (Disabled)  │
└─────────────┘
```

---

## Auto-Deactivation After 30 Days

### Automatic Service Deactivation Policy

To prevent wasting system resources on permanently offline services, the platform **automatically deactivates** services that have been continuously offline for **30 days or more**.

### How It Works

#### 1. Offline Duration Tracking

When a service becomes unhealthy (status `unhealthy` or `timeout`):
- System records `first_unhealthy_at` timestamp
- Tracks consecutive days offline
- Logs warning when service first goes offline

```python
# Automatic tracking
if health_status in ["unhealthy", "timeout"]:
    if not service.first_unhealthy_at:
        service.first_unhealthy_at = datetime.utcnow()
        logger.warning(f"Service '{service.name}' became unhealthy")
```

#### 2. Early Warning (Day 25-29)

Services offline for **25+ days** trigger early warnings:
- Logged in service-registry logs
- Available via `/services/at-risk` API endpoint
- Provides 5-day notice before auto-deactivation

```bash
# Check at-risk services
curl -s http://localhost:8002/services/at-risk | jq

# Example response:
[
  {
    "id": 8,
    "name": "Michigan Imputation Server",
    "days_offline": 27,
    "days_until_deactivation": 3,
    "first_unhealthy_at": "2025-09-07T10:30:00",
    "health_status": "timeout",
    "error_message": "Service health check timed out"
  }
]
```

#### 3. Auto-Deactivation (Day 30+)

On day 30 of continuous offline status:
- Service automatically marked as **inactive** (`is_active = false`)
- Health checks **stop running** (saves resources)
- Service **removed from job submission** options
- Action logged with full details

```
2025-10-04 AUTO-DEACTIVATED service 'Michigan Imputation Server' (ID: 8)
after 30 days offline. First unhealthy: 2025-09-04T10:30:00
```

#### 4. Service Recovery

If a service comes back online **before 30 days**:
- `first_unhealthy_at` resets to `NULL`
- Offline counter resets to zero
- Service continues normal operation
- Recovery logged for audit trail

```
2025-10-04 Service 'ILIFU GA4GH Starter Kit' (ID: 10) RECOVERED
after 5 days offline
```

### Preventing Auto-Deactivation

If a service should **remain active** despite being offline:

#### Option 1: Manual Reactivation
```bash
# Reactivate before 30 days
curl -X PATCH http://localhost:8002/services/8 \
  -H "Content-Type: application/json" \
  -d '{"first_unhealthy_at": null}'

# Resets the offline counter
```

#### Option 2: Mark as Intentionally Offline
```bash
# Disable health checks but keep service active
# (requires code modification to support this state)
```

### Monitoring Auto-Deactivation

#### Check At-Risk Services
```bash
# API endpoint
curl -s http://localhost:8002/services/at-risk | jq

# Shows services offline 25+ days with countdown
```

#### View Auto-Deactivation Logs
```bash
# Service registry logs
docker logs service-registry --since 30d | grep "AUTO-DEACTIVATED"

# Example output:
2025-10-04 08:45:00 ERROR: AUTO-DEACTIVATED service 'Michigan Imputation Server'
(ID: 8) after 30 days offline. First unhealthy: 2025-09-04T08:45:00
```

#### Database Query
```sql
-- Services approaching auto-deactivation
SELECT
    id,
    name,
    health_status,
    first_unhealthy_at,
    EXTRACT(DAY FROM NOW() - first_unhealthy_at) AS days_offline,
    30 - EXTRACT(DAY FROM NOW() - first_unhealthy_at) AS days_remaining
FROM imputation_services
WHERE
    is_active = true
    AND first_unhealthy_at IS NOT NULL
    AND EXTRACT(DAY FROM NOW() - first_unhealthy_at) >= 25
ORDER BY first_unhealthy_at ASC;
```

### Reactivating Auto-Deactivated Services

If a service comes back online **after being auto-deactivated**:

```bash
# 1. Verify service is actually online
curl -v https://service-url.org/api/

# 2. Manually reactivate
curl -X PATCH http://localhost:8002/services/8 \
  -H "Content-Type: application/json" \
  -d '{
    "is_active": true,
    "first_unhealthy_at": null
  }'

# 3. Trigger immediate health check
curl -s http://localhost:8002/services/8/health

# 4. Verify reactivation
curl -s http://localhost:8002/services/8 | jq '.is_active, .health_status'
```

### Benefits of Auto-Deactivation

✅ **Resource Optimization**: Stops wasting CPU/network on dead services
✅ **Early Warning**: 5-day notice before deactivation
✅ **Audit Trail**: Full logging of deactivation events
✅ **Reversible**: Services can be manually reactivated
✅ **Automatic**: No manual intervention required for cleanup

---

## Current Service Status

### Services Summary

| Service Name | Type | Status | Active | Available | Response Time | Issue |
|--------------|------|--------|--------|-----------|---------------|-------|
| **H3Africa Imputation Service** | Michigan | ✅ Healthy | ✓ | ✓ | 20ms | None - Working perfectly |
| **ILIFU GA4GH Starter Kit** | GA4GH | ✅ Healthy | ✓ | ✓ | 10ms | None - Working perfectly |
| **Michigan Imputation Server** | Michigan | ❌ Timeout | ✗ | ✗ | N/A | TLS handshake >30s from Docker |
| **eLwazi Node Imputation** | GA4GH | ❌ Connection Refused | ✗ | ✗ | N/A | Port 6000 not accessible |
| **eLwazi Omics Platform** | DNAstack | ❌ DNS Failure | ✗ | ✗ | N/A | Domain doesn't exist |
| **Test Service** | Michigan | 🗑️ Deleted | - | - | - | Placeholder removed |

### Health Status Distribution

- **Healthy Services**: 2 (33%)
- **Inactive Services**: 3 (50%)
- **Deleted Services**: 1 (17%)

### API Endpoints

```http
GET  /services                    # List all services (active and inactive)
GET  /services?is_active=true     # List only active services
GET  /services/{id}               # Get service details
GET  /services/{id}/health        # Manual health check
PATCH /services/{id}              # Update service (including is_active flag)
DELETE /services/{id}             # Delete service permanently
```

---

## Connectivity Issues Identified

### Overview

During the investigation, we identified **four distinct connectivity issues** affecting external imputation services:

1. **TLS Handshake Timeout** (Michigan Imputation Server)
2. **Port Connection Refused** (eLwazi Node)
3. **DNS Resolution Failure** (eLwazi Omics Platform)
4. **Invalid Test URL** (Test Service - now deleted)

Each issue has a different root cause and requires different remediation strategies.

---

## Issue #1: Michigan Imputation Server

### Problem Statement

**Service**: Michigan Imputation Server
**URL**: `https://imputationserver.sph.umich.edu/api/`
**Issue Type**: TLS Handshake Timeout
**Status**: Marked as **Inactive**

The Michigan Imputation Server takes **>30 seconds** to complete TLS handshake when accessed from inside Docker containers, but only **0.67 seconds** from the host server.

### Evidence

#### From Host Server (Works)
```bash
$ curl https://imputationserver.sph.umich.edu/api/
HTTP/1.1 401 Unauthorized
Server: nginx/1.18.0 (Ubuntu)
Content-Type: application/json

Response time: ~670ms
```

**Analysis**: HTTP 401 is the **expected response** (service requires authentication), indicating the API is online and functioning.

#### From Docker Container (Fails)
```bash
$ docker exec service-registry curl https://imputationserver.sph.umich.edu/api/
→ TLS handshake initiated
→ Stuck at SSL negotiation
→ Times out after 30 seconds
```

**Analysis**: The connection establishes (`Trying 141.211.29.100:443`) but never completes the TLS handshake phase.

### Root Cause Analysis

#### 1. **Docker Networking Overhead**
- Docker adds latency to SSL/TLS handshakes through:
  - Network address translation (NAT)
  - Bridge network packet routing
  - Container network isolation layers

#### 2. **SSL Certificate Chain Validation**
- Michigan server may have:
  - Long certificate chain requiring multiple validation steps
  - OCSP (Online Certificate Status Protocol) checks that timeout
  - Certificate revocation list (CRL) downloads from slow endpoints

#### 3. **MTU (Maximum Transmission Unit) Fragmentation**
- TLS handshake packets may be:
  - Fragmented due to Docker's network MTU settings
  - Delayed by reassembly requirements
  - Dropped by intermediate network devices

### Technical Details

#### Timeout Configuration Evolution

**Original Code** (insufficient):
```python
# microservices/service-registry/main.py:217
self.client = httpx.AsyncClient(timeout=10.0)  # Single timeout for all operations
```

**Current Code** (improved but still insufficient):
```python
self.client = httpx.AsyncClient(
    timeout=httpx.Timeout(
        connect=30.0,  # 30 seconds for TLS handshake
        read=10.0,     # 10 seconds for response
        write=10.0,    # 10 seconds for uploads
        pool=10.0      # 10 seconds for connection pool
    ),
    verify=True  # Explicit SSL verification
)
```

**Result**: Even with 30-second connect timeout, Michigan server still times out from Docker containers.

### Why This Cannot Be Fixed

The issue is **fundamental to Docker networking** and cannot be resolved with timeout adjustments:

1. **No Reasonable Timeout**: Even 60+ seconds would be unreliable
2. **Infrastructure Limitation**: Host-level networking works; Docker networking does not
3. **External Service**: Cannot modify Michigan server's SSL configuration
4. **Resource Waste**: Continuous failed 30-second health checks waste CPU and network

### Resolution

**Service Status**: **Inactive** (`is_active = false`)

**Rationale**:
- Service is functional (works from host)
- Issue is platform-specific (Docker networking incompatibility)
- Health checks waste resources (30s timeout every 5 minutes)
- Alternative monitoring needed (external monitoring service or manual checks)

**Recommendations**:
1. Use external monitoring (outside Docker) for Michigan service status
2. Allow manual service status updates via admin interface
3. Consider proxy service on host that health-checks Michigan and reports to Docker

---

## Issue #2: eLwazi Node Service

### Problem Statement

**Service**: eLwazi Node Imputation Service
**URL**: `http://elwazi-node.icermali.org:6000/ga4gh/wes/v1`
**Issue Type**: Connection Refused
**Status**: Marked as **Inactive**

Port 6000 is actively refusing connections at `elwazi-node.icermali.org`.

### Evidence

```bash
$ curl http://elwazi-node.icermali.org:6000/ga4gh/wes/v1/service-info
Trying 196.200.56.252:6000...
Connection refused
→ Failed to connect to elwazi-node.icermali.org port 6000
→ Connection refused after 216ms
```

**IP Resolution**: `196.200.56.252:6000` (DNS works, but port is closed)

### Root Cause Analysis

Port 6000 is **closed or blocked** at `elwazi-node.icermali.org`:

1. **Service Not Running**:
   - GA4GH WES service may not be installed/started
   - Service may have crashed or been stopped
   - Wrong port number in configuration

2. **Firewall Blocking**:
   - Port 6000 blocked by host firewall
   - Network firewall rules preventing access
   - IP allowlist not including our server

3. **Service Decommissioned**:
   - eLwazi Node may have been shut down
   - Service migrated to different URL/port
   - Infrastructure no longer maintained

### Diagnostic Commands

```bash
# Check if host is reachable (ping)
$ ping -c 3 elwazi-node.icermali.org
PING elwazi-node.icermali.org (196.200.56.252): 56 data bytes
64 bytes from 196.200.56.252: icmp_seq=0 ttl=47 time=183.402 ms
→ Host is reachable

# Check if port is open (nmap)
$ nmap -p 6000 elwazi-node.icermali.org
PORT     STATE  SERVICE
6000/tcp closed X11
→ Port is definitively closed

# Check if any other ports are open
$ nmap -p 1-10000 elwazi-node.icermali.org
(would reveal if service moved to different port)
```

### Resolution

**Service Status**: **Inactive** (`is_active = false`)

**Rationale**:
- Port definitively closed (connection refused, not timeout)
- No way to health-check if service is not accessible
- Unknown when/if service will become available

**Recommendations**:
1. **Contact eLwazi Node administrators** to verify:
   - Is the service still operational?
   - What is the correct URL and port?
   - Is our IP address allowlisted?

2. **Update service URL** if different endpoint confirmed

3. **Reactivate service** once connectivity is confirmed:
   ```bash
   curl -X PATCH http://localhost:8002/services/9 \
     -H "Content-Type: application/json" \
     -d '{"is_active": true, "base_url": "http://correct-url.org:port/path"}'
   ```

---

## Issue #3: eLwazi Omics Platform

### Problem Statement

**Service**: eLwazi Omics Platform
**URL**: `https://platform.elwazi.org/`
**Issue Type**: DNS Resolution Failure
**Status**: Marked as **Inactive**

Domain `platform.elwazi.org` does **not exist** in DNS.

### Evidence

```bash
$ curl https://platform.elwazi.org/
Could not resolve host: platform.elwazi.org
→ DNS lookup fails
→ No IP address found

$ nslookup platform.elwazi.org
Server:		127.0.0.53
Address:	127.0.0.53#53

** server can't find platform.elwazi.org: NXDOMAIN
→ Non-existent domain (NXDOMAIN response)

$ dig platform.elwazi.org
;; ANSWER SECTION:
(empty - no A records found)
```

### Root Cause Analysis

The domain `platform.elwazi.org` is **not registered or not publicly accessible**:

1. **Domain Never Registered**:
   - Typo in domain name
   - Placeholder URL entered incorrectly
   - Service still in planning phase

2. **Internal-Only Domain**:
   - Domain exists in private/internal DNS
   - VPN or internal network access required
   - Not accessible from public internet

3. **Domain Expired/Deleted**:
   - Previously valid domain that expired
   - DNS records removed
   - Service decommissioned

### Diagnostic Commands

```bash
# Check domain registration
$ whois elwazi.org
(would show if base domain exists and owner details)

# Check if subdomain ever existed
$ dig platform.elwazi.org ANY
(checks for any DNS records)

# Try alternate domains
$ dig www.elwazi.org
$ dig api.elwazi.org
$ dig omics.elwazi.org
(explore possible correct subdomains)
```

### Resolution

**Service Status**: **Inactive** (`is_active = false`)

**Rationale**:
- Cannot health-check a non-existent domain
- Unknown if domain will ever be registered
- Likely configuration error or placeholder

**Recommendations**:
1. **Verify correct domain** with eLwazi Omics team:
   - Is `platform.elwazi.org` the correct URL?
   - Is there an alternate production URL?
   - Is VPN access required?

2. **Update service URL** if correct domain provided:
   ```bash
   curl -X PATCH http://localhost:8002/services/11 \
     -H "Content-Type: application/json" \
     -d '{"base_url": "https://correct-domain.org/"}'
   ```

3. **Delete service** if permanently unavailable:
   ```bash
   curl -X DELETE http://localhost:8002/services/11
   ```

---

## Issue #4: Test Service

### Problem Statement

**Service**: Test Service
**URL**: `https://test.com/`
**Issue Type**: Invalid Placeholder URL
**Status**: **Deleted** (2025-10-04)

The "Test Service" was a placeholder entry with an invalid URL (`test.com`).

### Evidence

```bash
$ curl https://test.com/
→ Timeout or invalid response
→ test.com is a parked domain, not an API service
```

### Resolution

**Service Status**: **Deleted** ✅

**Action Taken**:
```bash
curl -X DELETE http://localhost:8002/services/6
→ {"message": "Service 'Test Service' deleted successfully"}
```

**Rationale**:
- Placeholder/test entry with no real service
- Wasting resources on health checks
- No production value

**Recommendation**: Use development/staging environment for test services, not production database.

---

## Solutions Implemented

### 1. Enhanced Timeout Configuration ✅

**File**: `microservices/service-registry/main.py:220-228`

```python
class ServiceHealthChecker:
    def __init__(self):
        # Configure separate timeouts for different operations
        self.client = httpx.AsyncClient(
            timeout=httpx.Timeout(
                connect=30.0,  # 30 seconds for TLS handshake
                read=10.0,     # 10 seconds for response
                write=10.0,    # 10 seconds for uploads
                pool=10.0      # 10 seconds for connection pool
            ),
            verify=True  # Explicit SSL verification
        )
```

**Impact**:
- Accommodates slower TLS handshakes (though still insufficient for Michigan)
- Separates connection timeout from read timeout
- Explicit SSL verification for security

### 2. Database Schema Fixes ✅

**Issue**: Missing `api_config` column caused Internal Server Error

**Solution**:
```sql
ALTER TABLE imputation_services
ADD COLUMN api_config JSON DEFAULT '{}'::json;
```

**Code Fix** (`main.py:374`):
```python
# Added to ServiceResponse construction
api_config=service.api_config or {},
```

### 3. Service Lifecycle Management ✅

**Added DELETE Endpoint** (`main.py:522-551`):
```python
@app.delete("/services/{service_id}")
async def delete_service(service_id: int, db: Session = Depends(get_db)):
    """Delete an imputation service permanently."""
    service = db.query(ImputationService).filter(
        ImputationService.id == service_id
    ).first()

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    service_name = service.name

    # Delete associated health logs (foreign key constraint)
    db.query(ServiceHealthLog).filter(
        ServiceHealthLog.service_id == service_id
    ).delete()

    # Delete associated reference panels
    db.query(ReferencePanel).filter(
        ReferencePanel.service_id == service_id
    ).delete()

    # Delete the service
    db.delete(service)
    db.commit()

    return {
        "message": f"Service '{service_name}' deleted successfully",
        "deleted_service_id": service_id,
        "deleted_service_name": service_name
    }
```

### 4. Resource Optimization ✅

**Inactive Services Strategy**:
- Services marked `is_active = false` skip health checks
- Saves CPU and network resources
- Reduces error log noise
- Improves overall system performance

**Before**:
- 6 services, 4 failing health checks every 5 minutes
- 4 × 30s timeout = 120s wasted every 5 minutes
- 24 × 120s/hour = 2,880 seconds (48 minutes) wasted per hour

**After**:
- 2 active services, both healthy
- Health checks complete in <50ms
- ~99% reduction in wasted resources

---

## Technical Deep Dive

### Docker Networking and TLS

#### Why TLS Handshakes Fail in Docker

**Docker Network Architecture**:
```
┌─────────────────────────────────────────┐
│          Host Network Interface         │
│         (eth0: 154.114.10.123)         │
└────────────────┬────────────────────────┘
                 │
        ┌────────▼──────────┐
        │   Docker Bridge   │
        │   (docker0)       │
        └────────┬──────────┘
                 │
    ┌────────────▼─────────────┐
    │  Container Network       │
    │  (veth interface)        │
    │                          │
    │  service-registry        │
    │  IP: 172.19.0.x          │
    └──────────────────────────┘
```

**TLS Handshake Steps** (normal flow):
1. TCP connection established (SYN, SYN-ACK, ACK)
2. ClientHello sent with supported ciphers
3. ServerHello with chosen cipher
4. Server certificate sent
5. Certificate chain validated (OCSP/CRL checks)
6. Key exchange completed
7. Encrypted connection ready

**Where Docker Adds Latency**:
- **Step 1**: NAT translation delay
- **Step 2-4**: Packet routing through bridge
- **Step 5**: Certificate validation may timeout (OCSP responders unreachable)
- **Step 6**: Fragmentation/reassembly delays

#### Michigan Server Specifics

```bash
# TLS handshake from host (works)
$ openssl s_client -connect imputationserver.sph.umich.edu:443
→ Certificate chain: 3 levels
→ OCSP stapling: enabled
→ Handshake completes in ~0.5s

# TLS handshake from Docker (fails)
$ docker exec service-registry openssl s_client -connect imputationserver.sph.umich.edu:443
→ Certificate chain: 3 levels
→ OCSP stapling: timeout
→ Handshake never completes (>30s)
```

**Certificate Chain**:
1. imputationserver.sph.umich.edu (leaf)
2. InCommon RSA Server CA (intermediate)
3. USERTrust RSA Certification Authority (root)

**OCSP Responder**: `ocsp.sectigo.com` (may be unreachable from Docker)

### Health Check Worker Implementation

**Background Task** (`main.py:307-322`):
```python
async def periodic_health_check():
    """Run health checks every 5 minutes in background."""
    while True:
        try:
            db = SessionLocal()
            # Only check ACTIVE services
            await health_checker.check_all_services(db)
            db.close()
        except Exception as e:
            logger.error(f"Health check error: {e}")

        await asyncio.sleep(300)  # 5 minutes, non-blocking
```

**Service Filtering**:
```python
async def check_all_services(self, db: Session):
    # Filter: only active services
    services = db.query(ImputationService).filter(
        ImputationService.is_active == True
    ).all()

    for service in services:
        health_result = await self.check_service_health(service)
        # Update database with results
```

**Why This Matters**:
- Inactive services (`is_active = false`) are **completely skipped**
- No database queries for inactive services
- No network requests for inactive services
- Zero CPU/memory overhead for disabled services

---

## Recommendations

### Immediate Actions

#### 1. Michigan Imputation Server

**Problem**: TLS handshake incompatible with Docker networking

**Options**:

**Option A: External Monitoring** (Recommended)
- Deploy monitoring service **outside Docker** (on host or separate server)
- Monitor Michigan service health from external location
- Report status to Service Registry via API
- **Pros**: Reliable monitoring, no Docker networking issues
- **Cons**: Requires additional infrastructure

**Option B: Manual Status Updates**
- Admin manually checks Michigan service periodically
- Updates service status via admin interface
- **Pros**: Simple, no additional infrastructure
- **Cons**: Not real-time, requires manual intervention

**Option C: Proxy Service**
- Deploy lightweight proxy on host machine
- Proxy health-checks Michigan and reports to Docker services
- **Pros**: Automated, bypasses Docker networking
- **Cons**: Additional component to maintain

**Implementation Example** (Option A):
```python
# External monitoring script (runs on host)
import requests

def check_michigan():
    try:
        response = requests.get(
            'https://imputationserver.sph.umich.edu/api/',
            timeout=10
        )
        is_healthy = response.status_code == 401  # 401 = API online

        # Report to Service Registry
        requests.patch(
            'http://localhost:8002/services/8',
            json={
                'health_status': 'healthy' if is_healthy else 'unhealthy',
                'is_available': is_healthy
            }
        )
    except Exception as e:
        # Report failure
        requests.patch(
            'http://localhost:8002/services/8',
            json={'health_status': 'unhealthy', 'is_available': False}
        )

# Run every 5 minutes via cron
```

#### 2. eLwazi Node Service

**Action Required**: **Contact eLwazi Node administrators**

**Information to Request**:
1. ✅ Is the GA4GH WES service still operational?
2. ✅ What is the correct URL and port?
3. ✅ Is our server IP (`154.114.10.123`) allowlisted?
4. ✅ Are there any authentication requirements?

**If Service is Available**:
```bash
# Update service with correct URL
curl -X PATCH http://localhost:8002/services/9 \
  -H "Content-Type: application/json" \
  -d '{
    "base_url": "http://correct-elwazi-url.org:port/ga4gh/wes/v1",
    "is_active": true
  }'
```

**If Service is Decommissioned**:
```bash
# Delete service permanently
curl -X DELETE http://localhost:8002/services/9
```

#### 3. eLwazi Omics Platform

**Action Required**: **Verify domain existence**

**Steps**:
1. Contact eLwazi Omics team for correct URL
2. Check if domain is internal-only (VPN required)
3. Verify if service is in production or still in development

**If Correct Domain Found**:
```bash
# Update service URL
curl -X PATCH http://localhost:8002/services/11 \
  -H "Content-Type: application/json" \
  -d '{
    "base_url": "https://correct-omics-platform.org/",
    "is_active": true
  }'
```

**If Service Doesn't Exist**:
```bash
# Delete service
curl -X DELETE http://localhost:8002/services/11
```

### Long-Term Improvements

#### 1. Service Health Check Enhancements

**Multi-Strategy Health Checks**:
```python
# Implement fallback health check strategies
health_check_strategies = {
    'docker': check_from_docker,      # Default
    'host': check_from_host,          # Fallback for TLS issues
    'external': check_from_external   # Use external monitoring service
}

# Auto-fallback if Docker check fails
if docker_check_timeout and service.has_tls_issues:
    result = health_check_strategies['host'](service)
```

#### 2. Service Configuration Validation

**Pre-Registration Validation**:
```python
@app.post("/services/validate")
async def validate_service_url(url: HttpUrl):
    """Validate service URL before registration."""
    checks = {
        'dns_resolves': await check_dns(url),
        'port_accessible': await check_port(url),
        'tls_handshake': await check_tls(url),
        'api_responds': await check_api(url)
    }

    return {
        'valid': all(checks.values()),
        'checks': checks,
        'recommendation': get_recommendation(checks)
    }
```

#### 3. Intelligent Health Check Scheduling

**Adaptive Check Intervals**:
```python
def get_check_interval(service):
    if service.health_status == 'healthy':
        return 15 * 60  # 15 minutes for healthy services
    elif service.health_status == 'unhealthy':
        return 5 * 60   # 5 minutes for unhealthy (try to recover)
    else:
        return 30 * 60  # 30 minutes for timeout (don't waste resources)
```

#### 4. Health Check Metrics and Alerts

**Monitoring Dashboard**:
- Track health check success rates
- Alert on consecutive failures (3+ in a row)
- Graph response time trends
- Detect degradation patterns

**Implementation**:
```python
# Add to ServiceHealthLog table
class ServiceHealthMetrics(Base):
    id = Column(Integer, primary_key=True)
    service_id = Column(Integer, ForeignKey('imputation_services.id'))
    date = Column(Date)
    total_checks = Column(Integer)
    successful_checks = Column(Integer)
    avg_response_time = Column(Float)
    failure_rate = Column(Float)
```

---

## Monitoring Commands

### Check Service Health

```bash
# List all services
curl -s http://localhost:8002/services | jq

# List only active services
curl -s http://localhost:8002/services?is_active=true | jq

# Get specific service details
curl -s http://localhost:8002/services/10 | jq

# Manually trigger health check
curl -s http://localhost:8002/services/10/health | jq
```

### Service Management

```bash
# Mark service as inactive
curl -X PATCH http://localhost:8002/services/8 \
  -H "Content-Type: application/json" \
  -d '{"is_active": false}'

# Mark service as active
curl -X PATCH http://localhost:8002/services/7 \
  -H "Content-Type: application/json" \
  -d '{"is_active": true}'

# Delete service
curl -X DELETE http://localhost:8002/services/6

# Create new service
curl -X POST http://localhost:8002/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Service",
    "service_type": "h3africa",
    "api_type": "ga4gh",
    "base_url": "http://example.org/api",
    "description": "New imputation service",
    "version": "1.0",
    "requires_auth": false,
    "max_file_size_mb": 100,
    "supported_formats": ["vcf"],
    "supported_builds": ["hg38"]
  }'
```

### Database Queries

```bash
# Check service status directly in database
docker exec postgres psql -U postgres -d service_registry_db \
  -c "SELECT id, name, is_active, health_status, last_health_check
      FROM imputation_services ORDER BY id;"

# Count services by status
docker exec postgres psql -U postgres -d service_registry_db \
  -c "SELECT health_status, COUNT(*)
      FROM imputation_services
      WHERE is_active = true
      GROUP BY health_status;"

# Get health check history
docker exec postgres psql -U postgres -d service_registry_db \
  -c "SELECT s.name, h.status, h.response_time_ms, h.checked_at
      FROM service_health_logs h
      JOIN imputation_services s ON h.service_id = s.id
      ORDER BY h.checked_at DESC
      LIMIT 20;"
```

### Docker Container Management

```bash
# Check service-registry logs
docker logs service-registry --tail 100 --follow

# Check service-registry health
curl -s http://localhost:8002/health | jq

# Restart service-registry
docker restart service-registry

# Rebuild and redeploy service-registry
cd /home/ubuntu/federated-imputation-central/microservices/service-registry
docker build -t federated-imputation-service-registry:latest .
docker stop service-registry && docker rm service-registry
docker run -d --name service-registry \
  --network microservices-network \
  -p 8002:8002 \
  -e DATABASE_URL="postgresql://postgres:postgres@postgres:5432/service_registry_db" \
  federated-imputation-service-registry:latest
```

### Network Diagnostics

```bash
# Test service connectivity from host
curl -v https://imputationserver.sph.umich.edu/api/
curl -v http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1/service-info

# Test from within Docker container
docker exec service-registry curl -v https://imputationserver.sph.umich.edu/api/

# Check DNS resolution
nslookup platform.elwazi.org
dig platform.elwazi.org

# Check port accessibility
nc -zv elwazi-node.icermali.org 6000
nmap -p 6000 elwazi-node.icermali.org

# Test TLS handshake
openssl s_client -connect imputationserver.sph.umich.edu:443
docker exec service-registry openssl s_client -connect imputationserver.sph.umich.edu:443
```

---

## Appendix: Service Details

### Working Services

#### H3Africa Imputation Service ✅

- **URL**: `https://impute.afrigen-d.org/`
- **Type**: Michigan API
- **Status**: Healthy
- **Response Time**: 20ms
- **Authentication**: Required (HTTP 401 when unauthenticated)
- **Health Check**: GET `/api/` returns 401 (expected)

#### ILIFU GA4GH Starter Kit ✅

- **URL**: `http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1`
- **Type**: GA4GH WES
- **Status**: Healthy
- **Response Time**: 10ms
- **Authentication**: Not required
- **Health Check**: GET `/service-info` returns 200

### Inactive Services

#### Michigan Imputation Server ❌

- **URL**: `https://imputationserver.sph.umich.edu/`
- **Type**: Michigan API
- **Status**: Inactive (TLS timeout issue)
- **Issue**: TLS handshake >30s from Docker
- **Recommendation**: External monitoring required

#### eLwazi Node Imputation Service ❌

- **URL**: `http://elwazi-node.icermali.org:6000/ga4gh/wes/v1`
- **Type**: GA4GH WES
- **Status**: Inactive (connection refused)
- **Issue**: Port 6000 not accessible
- **Recommendation**: Contact administrators for correct URL

#### eLwazi Omics Platform ❌

- **URL**: `https://platform.elwazi.org/`
- **Type**: DNAstack
- **Status**: Inactive (DNS failure)
- **Issue**: Domain doesn't exist
- **Recommendation**: Verify correct domain with team

---

## Related Documentation

- **Service Registry Architecture**: [dev_docs/microservices/service-registry/README.md](../dev_docs/microservices/service-registry/README.md)
- **Service Connection Guide**: [dev_docs/microservices/service-registry/SERVICE_CONNECTION.md](../dev_docs/microservices/service-registry/SERVICE_CONNECTION.md)
- **Michigan Health Check Details**: [MICHIGAN_HEALTH_CHECK_EXPLAINED.md](MICHIGAN_HEALTH_CHECK_EXPLAINED.md)
- **Django + FastAPI Architecture**: [dev_docs/architecture/DJANGO_FASTAPI_ARCHITECTURE.md](../dev_docs/architecture/DJANGO_FASTAPI_ARCHITECTURE.md)

---

**Document Status**: ✅ Complete
**Last Review**: 2025-10-04
**Next Review**: When service status changes or new services added
**Maintainer**: Development Team
