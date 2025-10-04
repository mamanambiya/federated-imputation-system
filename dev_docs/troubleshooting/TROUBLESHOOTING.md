# Troubleshooting Guide

This document covers common issues and their solutions for the Federated Genomic Imputation Platform.

## Table of Contents
- [Login Issues](#login-issues)
- [Service Health Status Issues](#service-health-status-issues)
- [Rate Limiting](#rate-limiting)
- [Container Health](#container-health)

---

## Login Issues

### Symptom: "Network connection error" on login page

**Root Cause**: API Gateway rate limiting has blocked your IP address.

**Solution**:
```bash
# Clear rate limit for specific IP
docker exec redis redis-cli DEL "rate_limit:YOUR_IP_ADDRESS"

# Example:
docker exec redis redis-cli DEL "rate_limit:105.242.149.5"
```

**Prevention**: The rate limit has been increased to 1000 requests/hour for development. If you still hit the limit:
```bash
# Check current rate limit count
docker exec redis redis-cli GET "rate_limit:YOUR_IP"

# Check time until reset
docker exec redis redis-cli TTL "rate_limit:YOUR_IP"
```

### Symptom: Login returns empty response or HTTP 500

**Root Cause**: API Gateway proxy issues with Content-Length headers or redirects.

**Verify Fix**:
```bash
# Test login endpoint directly
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"test_user","password":"test_password"}'

# Should return JWT token and user data
```

**If issue persists**:
1. Check api-gateway logs: `docker logs api-gateway --tail 50`
2. Verify user-service is running: `docker ps | grep user-service`
3. Test user-service directly: `docker exec api-gateway curl http://user-service:8001/health`

---

## Service Health Status Issues

### Symptom: All services showing "Unknown" status

**Root Cause**: Frontend doesn't recognize "timeout" status from backend.

**Fix Applied**: Frontend now maps "timeout" → "unhealthy" (displays as "Offline").

**Verify**:
```bash
# Check service health via API
curl http://localhost:8000/api/services/7/health/ | jq

# Should return: {"status": "healthy|unhealthy|timeout", ...}
```

### Symptom: H3Africa Imputation Service shows as "Offline"

**Root Causes**:
1. **Incorrect URL**: Old URL `https://h3africa.org/imputation` doesn't exist
2. **Correct URL**: `https://impute.afrigen-d.org/`
3. **Health Check Logic**: Michigan-type APIs return HTTP 401 for unauthenticated requests

**How to Verify Service is Actually Online**:
```bash
# Test the correct URL
curl -I https://impute.afrigen-d.org/api/

# Should return: HTTP/1.1 401 Unauthorized
# This means the service IS online and working correctly!
```

**Understanding Michigan-Style Health Checks**:
- Michigan Imputation Server and derivatives (H3Africa/AfriGen-D) require authentication
- HTTP 401 (Unauthorized) = **Service is HEALTHY** (actively rejecting unauthenticated requests)
- HTTP 404 (Not Found) = Service endpoint doesn't exist
- Timeout/Connection refused = Service is offline

**Update Service URL in Database**:
```bash
# Via PostgreSQL
docker exec -i postgres psql -U postgres -d service_registry_db << 'EOF'
UPDATE imputation_services
SET base_url = 'https://impute.afrigen-d.org/'
WHERE name = 'H3Africa Imputation Service';
EOF

# Then restart service-registry
docker restart service-registry
```

### Symptom: Service shows "Offline" but should be online

**Debugging Steps**:

1. **Check service type and health check URL**:
```bash
# Get service details
curl http://localhost:8000/api/services/ | jq '.[] | {name, api_type, base_url}'
```

2. **Test health check manually**:
```bash
# For Michigan-type services (api_type: "michigan")
curl -I https://service-url.com/api/
# Expect: 200 OK or 401 Unauthorized = healthy

# For GA4GH services (api_type: "ga4gh")
curl https://service-url.com/service-info
# Expect: 200 OK with JSON = healthy

# For DNAstack services (api_type: "dnastack")
curl https://service-url.com/
# Expect: 200 OK = healthy
```

3. **Check service-registry health check logic**:
```bash
# View recent health check logs
docker logs service-registry | grep "health_check\|HTTP Request" | tail -20
```

4. **Force health check**:
```bash
# Trigger immediate health check (bypasses cache)
curl "http://localhost:8000/api/services/7/health/?force=true"
```

---

## Rate Limiting

### Current Settings
- **Limit**: 1000 requests per hour (development)
- **Window**: 3600 seconds (1 hour)
- **Storage**: Redis key pattern `rate_limit:{IP_ADDRESS}`

### Check Rate Limit Status
```bash
# View all rate limit keys
docker exec redis redis-cli KEYS "rate_limit:*"

# Check specific IP
docker exec redis redis-cli GET "rate_limit:105.242.149.5"

# Check TTL (time to live)
docker exec redis redis-cli TTL "rate_limit:105.242.149.5"
```

### Clear All Rate Limits
```bash
# Clear all rate limit keys
docker exec redis redis-cli KEYS "rate_limit:*" | xargs docker exec redis redis-cli DEL
```

### Adjust Rate Limits

Edit `microservices/api-gateway/main.py`:
```python
async def is_allowed(self, key: str, limit: int = 1000, window: int = 3600):
    # limit: number of requests
    # window: time window in seconds
```

Then rebuild:
```bash
docker build -t federated-imputation-api-gateway:latest \
  -f microservices/api-gateway/Dockerfile \
  microservices/api-gateway/

docker restart api-gateway
```

---

## Container Health

### Check All Container Status
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Symptom: api-gateway shows as "unhealthy"

**Common Causes**:
1. **curl not installed** (health check fails)
2. **Service not responding** on port 8000
3. **Network connectivity issues**

**Fix**:
```bash
# Check health check command
docker inspect api-gateway | jq '.[0].Config.Healthcheck'

# Test health endpoint manually
docker exec api-gateway curl -f http://localhost:8000/health

# View health check logs
docker inspect api-gateway | jq '.[0].State.Health.Log[-1]'
```

**Rebuild with curl**:
```dockerfile
# In microservices/api-gateway/Dockerfile
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*
```

### Symptom: service-registry shows SQLAlchemy errors

**Error**: `Could not determine join condition between parent/child tables`

**Root Cause**: Missing ForeignKey constraint on ReferencePanel.service_id

**Fix Applied**: Added `ForeignKey("imputation_services.id")` to service_id column

**Verify**:
```bash
# Check for errors in logs
docker logs service-registry | grep -i "error\|sqlalchemy"

# Should start without errors
```

---

## Common Commands Reference

### Service Management
```bash
# View all services and their health status
curl http://localhost:8000/api/services/ | jq '.[] | {id, name, health_status}'

# Force health check for specific service
curl "http://localhost:8000/api/services/7/health/?force=true"

# Check service via service-registry directly
curl http://localhost:8002/services/7/health
```

### Database Queries
```bash
# List all services
docker exec -i postgres psql -U postgres -d service_registry_db -c \
  "SELECT id, name, api_type, base_url, health_status FROM imputation_services;"

# Update service URL
docker exec -i postgres psql -U postgres -d service_registry_db -c \
  "UPDATE imputation_services SET base_url='https://new-url.com/' WHERE id=7;"
```

### Container Management
```bash
# Restart specific service
docker restart api-gateway

# View logs
docker logs api-gateway --tail 50 --follow

# Execute command in container
docker exec api-gateway curl http://user-service:8001/health
```

### Redis Cache Management
```bash
# View all cache keys
docker exec redis redis-cli KEYS "*"

# Clear specific key
docker exec redis redis-cli DEL "key_name"

# View key value
docker exec redis redis-cli GET "key_name"

# View key TTL
docker exec redis redis-cli TTL "key_name"
```

---

## Getting Help

If you encounter issues not covered here:

1. **Check container logs**: `docker logs <container-name> --tail 100`
2. **Check container health**: `docker ps` and `docker inspect <container-name>`
3. **Test endpoints manually**: Use curl to test API endpoints directly
4. **Check network connectivity**: Ensure containers can communicate via Docker network
5. **Review recent commits**: `git log --oneline -10` for recent changes

For persistent issues, check:
- PostgreSQL connection and database status
- Redis connection and cache status
- Network configuration (microservices-network)
- Environment variables in containers
