# Docker Healthcheck Fix for Job Processor

**Date:** 2025-10-06
**Issue:** Job processor showing as "unhealthy" in Docker despite service responding correctly
**Status:** ✅ Fixed

---

## Problem

The job-processor container was showing as "unhealthy" in `docker ps` output:

```bash
$ docker ps | grep job-processor
job-processor    Up 10 minutes (unhealthy)   0.0.0.0:8003->8003/tcp
```

However, the actual service was responding correctly to health checks:

```bash
$ curl http://154.114.10.123:8003/health
{"status":"healthy","service":"job-processor","timestamp":"2025-10-06T19:38:35.924578"}
```

---

## Root Cause

The Docker healthcheck was configured to use `curl`:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8003/health"]
```

The Python base image (`python:3.11-slim`) doesn't include `curl` by default, causing the healthcheck command to fail:

```
/bin/sh: 1: curl: not found
ExitCode: 1
```

---

## Solution

### Option 1: Python-based Healthcheck (Implemented ✅)

Changed the healthcheck to use Python's built-in `urllib.request`:

```bash
docker run -d \
  --name job-processor \
  --network microservices-network \
  -p 8003:8003 \
  --health-cmd='python3 -c "import urllib.request; urllib.request.urlopen(\"http://localhost:8003/health\").read()"' \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  federated-imputation-job-processor:latest
```

### Option 2: Install curl in Dockerfile (Alternative)

Add to `microservices/job-processor/Dockerfile`:

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

**Why Option 1 is Better:**
- No additional package dependencies
- Smaller image size
- Uses built-in Python libraries
- Faster healthcheck execution

---

## docker-compose.yml Update

Updated `docker-compose.microservices.yml` to use Python-based healthcheck:

```yaml
job-processor:
  build:
    context: ./microservices/job-processor
  healthcheck:
    test: ["CMD", "python3", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8003/health').read()"]
    interval: 30s
    timeout: 10s
    retries: 3
```

---

## Verification

### Before Fix:
```bash
$ docker inspect job-processor --format='{{json .State.Health.Status}}'
"unhealthy"

$ docker inspect job-processor --format='{{json .State.Health.Log}}'
[{"ExitCode":1,"Output":"/bin/sh: 1: curl: not found\n"}]
```

### After Fix:
```bash
$ docker ps | grep job-processor
job-processor    Up 56 seconds (healthy)   0.0.0.0:8003->8003/tcp

$ docker inspect job-processor --format='{{json .State.Health.Status}}'
"healthy"

$ docker inspect job-processor --format='{{json .State.Health.Log}}'
[{"ExitCode":0,"Output":""}]
```

---

## Container Recreation Command

Full command to recreate job-processor with correct healthcheck:

```bash
# Stop and remove old container
docker rm -f job-processor

# Create with Python-based healthcheck
docker run -d \
  --name job-processor \
  --network microservices-network \
  -p 8003:8003 \
  -e DATABASE_URL=postgresql://postgres:postgres@postgres:5432/job_processing_db \
  -e REDIS_URL=redis://redis:6379 \
  -e USER_SERVICE_URL=http://user-service:8001 \
  -e SERVICE_REGISTRY_URL=http://service-registry:8002 \
  -e FILE_MANAGER_URL=http://file-manager:8004 \
  -e NOTIFICATION_URL=http://notification:8005 \
  --health-cmd='python3 -c "import urllib.request; urllib.request.urlopen(\"http://localhost:8003/health\").read()"' \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  federated-imputation-job-processor:latest
```

---

## Impact

### Before:
- ❌ Docker status showed "unhealthy"
- ❌ False alerts in monitoring
- ✅ Service actually working correctly

### After:
- ✅ Docker status shows "healthy"
- ✅ Accurate health monitoring
- ✅ Service working correctly

---

## Lessons Learned

1. **Base Image Selection:** Python slim images don't include common utilities like `curl`
2. **Healthcheck Design:** Use built-in language features when possible
3. **Image Size:** Avoid installing unnecessary packages just for healthchecks
4. **Monitoring:** Distinguish between infrastructure checks (Docker) and application checks (HTTP)

---

## Related Files

- [docker-compose.microservices.yml](docker-compose.microservices.yml) - Updated healthcheck config
- [microservices/job-processor/Dockerfile](microservices/job-processor/Dockerfile) - Container definition
- [SYSTEM_STATUS_REPORT.md](SYSTEM_STATUS_REPORT.md) - System health documentation

---

**Fixed By:** Claude Code
**Issue Type:** Configuration
**Priority:** Low (cosmetic only)
**Resolution Time:** 15 minutes
