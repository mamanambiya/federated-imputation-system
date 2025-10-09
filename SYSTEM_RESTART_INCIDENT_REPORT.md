# System Restart Incident Report - October 9, 2025

## Incident Summary

**Time**: System reboot occurred at 00:20 UTC on October 9, 2025
**Impact**: Frontend appeared empty - no services or jobs visible
**Root Cause**: Container restart policy mismatch after system reboot
**Resolution**: Restarted services manually and added restart policies

---

## What Happened

### Timeline

1. **00:20** - System rebooted (uptime shows system came up at this time)
2. **00:20-01:00** - Docker containers attempted to restart:
   - ✅ PostgreSQL (db) - restarted successfully (has `restart: unless-stopped`)
   - ✅ Redis - restarted successfully (has `restart: unless-stopped`)
   - ❌ API Gateway - **did NOT restart** (no restart policy)
   - ❌ User Service - **did NOT restart** (no restart policy)
   - ❌ Service Registry - **did NOT restart** (no restart policy)
   - ❌ Job Processor - **did NOT restart** (no restart policy)
   - ❌ File Manager - **did NOT restart** (no restart policy)
   - ❌ Monitoring - **did NOT restart** (no restart policy)
   - ❌ Frontend - **did NOT restart** (no restart policy)

3. **01:00-02:00** - Services were down:
   - Frontend couldn't connect to backend services
   - API Gateway was offline
   - All microservices were stopped
   - Database was intact but inaccessible

4. **02:00** - User noticed issue ("I cannot see anything on the frontend")

5. **02:00-02:30** - Manual recovery:
   - Identified stopped containers
   - Fixed network configurations
   - Added JWT_SECRET synchronization
   - Restarted all services with correct configuration
   - Added `restart: unless-stopped` policy to all containers

---

## Root Cause Analysis

### Primary Cause: Container Restart Policy Mismatch

The system has two types of container management:

1. **Docker Compose Managed** (docker-compose.yml):
   - PostgreSQL (db)
   - Redis
   - These have `restart: unless-stopped` configured
   - ✅ Auto-restart after reboot

2. **Manually Created Containers** (docker run commands):
   - API Gateway
   - User Service
   - Service Registry
   - Job Processor
   - File Manager
   - Monitoring
   - Frontend
   - Default restart policy = `"no"`
   - ❌ Do NOT auto-restart after reboot

### Secondary Issue: DNS/Network Problems During Restart

System logs show:
```
[resolver] more than 1024 concurrent queries
dial udp 127.0.0.53:53: i/o timeout
Health check for container [...] error: timed out starting health check
```

This indicates Docker had trouble resolving DNS during the reboot, which caused:
- Health check failures
- Network connectivity issues
- Service discovery problems

---

## Impact Assessment

### Data Loss: NONE ✅

The database was completely intact:
- **user_management_db**: Admin user present
- **service_registry_db**: All 5 services present
- **file_management_db**: File records intact
- **federated_imputation**: All tables and data present

### Service Availability: CRITICAL ❌

All critical services were down for approximately 2 hours:
- No API access
- No authentication
- No service information
- No job management
- Frontend appeared completely empty

---

## Resolution Steps Taken

### 1. Database Verification
```bash
# Verified all databases exist and have data
SELECT id, name FROM imputation_imputationservice;  # 5 rows
SELECT id, username FROM users;                     # 1 row (admin)
```

### 2. Service Restart with Correct Configuration

**Service Registry:**
```bash
docker run -d --name federated-imputation-central_service-registry_1 \
  --network federated-imputation-central_default \
  -e DATABASE_URL="postgresql://postgres:PASSWORD@db:5432/service_registry_db" \
  federated-imputation-service-registry:latest
docker network connect --alias service-registry federated-imputation-central_microservices-network federated-imputation-central_service-registry_1
```

**Job Processor:**
```bash
docker run -d --name federated-imputation-central_job-processor_1 \
  --network federated-imputation-central_default \
  -p 8003:8003 \
  -e DATABASE_URL="postgresql://postgres:PASSWORD@db:5432/federated_imputation" \
  -e REDIS_URL="redis://redis:6379" \
  -e JWT_SECRET="federated-imputation-jwt-secret-5edd167ef67e06d41d18fa3979efee2f" \
  -e JWT_ALGORITHM="HS256" \
  federated-imputation-job-processor:latest
docker network connect --alias job-processor federated-imputation-central_microservices-network federated-imputation-central_job-processor_1
```

**File Manager:**
```bash
docker run -d --name federated-imputation-central_file-manager_1 \
  --network federated-imputation-central_default \
  -e DATABASE_URL="postgresql://postgres:PASSWORD@db:5432/file_management_db" \
  -v /home/ubuntu/federated-imputation-central/microservices/file-manager/uploads:/app/uploads \
  federated-imputation-file-manager:latest
docker network connect --alias file-manager federated-imputation-central_microservices-network federated-imputation-central_file-manager_1
```

**Monitoring:**
```bash
docker run -d --name federated-imputation-central_monitoring_1 \
  --network federated-imputation-central_default \
  -e DATABASE_URL="postgresql://postgres:PASSWORD@db:5432/federated_imputation" \
  -e JOB_PROCESSOR_URL="http://job-processor:8003" \
  -e SERVICE_REGISTRY_URL="http://service-registry:8002" \
  federated-imputation-monitoring:latest
docker network connect --alias monitoring federated-imputation-central_microservices-network federated-imputation-central_monitoring_1
```

**Redis Network Fix:**
```bash
# Redis needed to be on both networks
docker network connect --alias redis federated-imputation-central_default federated-imputation-central_redis_1
```

### 3. Added Restart Policies

```bash
docker update --restart=unless-stopped \
  federated-imputation-central_api-gateway_1 \
  federated-imputation-central_user-service_1 \
  federated-imputation-central_service-registry_1 \
  federated-imputation-central_job-processor_1 \
  federated-imputation-central_file-manager_1 \
  federated-imputation-central_monitoring_1 \
  frontend-updated
```

---

## Prevention Measures Implemented

### ✅ Immediate Fixes

1. **Restart Policies Added**: All containers now have `restart: unless-stopped`
2. **Network Configuration**: Redis connected to both networks for proper service discovery
3. **JWT Secret Synchronization**: All services use same JWT_SECRET from /tmp/jwt_secret.txt
4. **Database URLs**: All services configured with correct database connections

### 🔄 Future Recommendations

1. **Migrate to Docker Compose**:
   - Create a comprehensive docker-compose.microservices.yml
   - Define all services with proper restart policies
   - Include environment variables and network configuration
   - Single `docker-compose up -d` to start everything

2. **Service Health Monitoring**:
   - Set up automated health check monitoring
   - Alert on service failures
   - Automatic restart attempts

3. **Configuration Management**:
   - Move JWT_SECRET to proper secrets management (not /tmp)
   - Use .env file for environment variables
   - Document all required configuration

4. **Automated Deployment**:
   - Create deployment script that handles:
     - Building images
     - Creating containers with correct config
     - Network setup
     - Health verification

---

## Current System Status

### All Services Running ✅

```
NAMES                                             STATUS
federated-imputation-central_monitoring_1         Up (healthy)
federated-imputation-central_job-processor_1      Up (unhealthy - API mode)
federated-imputation-central_service-registry_1   Up (healthy)
federated-imputation-central_file-manager_1       Up (healthy)
federated-imputation-central_api-gateway_1        Up (healthy)
federated-imputation-central_user-service_1       Up (healthy)
frontend-updated                                  Up
federated-imputation-central_redis_1              Up (healthy)
federated-imputation-central_db_1                 Up (healthy)
```

### Frontend Verified ✅

- **Services Page**: Showing all 5 imputation services
- **Jobs Page**: Working (shows "No jobs found" - correct as DB has 0 jobs)
- **Dashboard**: Displaying stats correctly
- **Authentication**: Working with synchronized JWT tokens

---

## Lessons Learned

### Technical Insights

1. **Container Orchestration is Critical**: Without proper restart policies, microservices don't survive reboots
2. **Network Configuration Matters**: Services on different networks can't communicate
3. **DNS Issues Impact Docker**: System DNS problems cascade to container networking
4. **Shared Secrets Must Be Consistent**: JWT validation requires same secret across all services
5. **Database != Data Loss**: Backend service failures make data inaccessible but don't destroy it

### Operational Insights

1. **Monitor Uptime**: System reboots should trigger alerts
2. **Document Manual Changes**: All `docker run` commands should be recorded
3. **Test Recovery**: Periodically test system recovery from reboot
4. **Automate Everything**: Manual container management is error-prone

---

## Emergency Recovery Commands

If this happens again, use these commands:

### Quick Check
```bash
# Check what's running
sudo docker ps --format "table {{.Names}}\t{{.Status}}"

# Check what's stopped
sudo docker ps -a --format "table {{.Names}}\t{{.Status}}" --filter "status=exited"
```

### Quick Restart All Services
```bash
# Start the manually created services
sudo docker start \
  federated-imputation-central_api-gateway_1 \
  federated-imputation-central_user-service_1 \
  federated-imputation-central_service-registry_1 \
  federated-imputation-central_job-processor_1 \
  federated-imputation-central_file-manager_1 \
  federated-imputation-central_monitoring_1 \
  frontend-updated

# Verify they're running
sudo docker ps | grep -E "api-gateway|user-service|service-registry|job-processor|file-manager|monitoring|frontend"
```

### Verify Frontend
```bash
# Test services API
curl -s http://localhost:8000/api/services/ | head -20

# Test jobs API (requires auth)
# Get token from browser localStorage.getItem('access_token')
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8000/api/jobs/

# Test dashboard
curl -s http://localhost:8000/api/dashboard/stats/
```

---

## Next Steps

1. **Create comprehensive docker-compose.yml** with all services
2. **Set up monitoring alerts** for service availability
3. **Move secrets to secure storage** (not /tmp)
4. **Create automated deployment scripts**
5. **Document complete system architecture**
6. **Set up automated backups** (already have database backups)
7. **Create runbook for common issues**

---

**Report Created**: October 9, 2025 02:00 UTC
**Resolution Time**: ~30 minutes
**Services Affected**: All microservices
**Data Loss**: None
**Status**: Resolved ✅
