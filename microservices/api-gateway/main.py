"""
API Gateway Service for Federated Genomic Imputation Platform
Provides unified access point for all microservices with authentication, routing, and rate limiting.
"""

import os
import asyncio
import logging
from typing import Dict, Any, Optional
from datetime import datetime, timedelta

import httpx
import redis
from fastapi import FastAPI, Request, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import JSONResponse
import jwt
from pydantic import BaseModel
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
REDIS_URL = os.getenv('REDIS_URL', 'redis://redis:6379')
JWT_SECRET = os.getenv('JWT_SECRET', 'your-secret-key-change-in-production')
JWT_ALGORITHM = 'HS256'

# Service endpoints
SERVICES = {
    'user-service': os.getenv('USER_SERVICE_URL', 'http://user-service:8001'),
    'service-registry': os.getenv('SERVICE_REGISTRY_URL', 'http://service-registry:8002'),
    'job-processor': os.getenv('JOB_PROCESSOR_URL', 'http://job-processor:8003'),
    'file-manager': os.getenv('FILE_MANAGER_URL', 'http://file-manager:8004'),
    'notification': os.getenv('NOTIFICATION_URL', 'http://notification:8005'),
    'monitoring': os.getenv('MONITORING_URL', 'http://monitoring:8006'),
}

# Initialize FastAPI app
app = FastAPI(
    title="Federated Genomic Imputation API Gateway",
    description="Unified API gateway for microservices architecture",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Initialize Redis for rate limiting and caching
redis_client = redis.Redis.from_url(REDIS_URL, decode_responses=True)

# Security
security = HTTPBearer(auto_error=False)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://frontend:3000", "http://154.114.10.123:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Trusted host middleware
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["localhost", "127.0.0.1", "api-gateway", "*.local", "154.114.10.123"]
)

# Models
class HealthResponse(BaseModel):
    status: str
    timestamp: datetime
    services: Dict[str, str]

class RateLimitInfo(BaseModel):
    limit: int
    remaining: int
    reset_time: datetime

# Rate limiting
class RateLimiter:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
    
    async def is_allowed(self, key: str, limit: int = 1000, window: int = 3600) -> tuple[bool, RateLimitInfo]:
        """Check if request is within rate limit.

        Development setting: 1000 requests per hour to avoid lockouts during testing.
        Production should use lower limits (e.g., 100-200).
        """
        try:
            current = self.redis.get(key)
            if current is None:
                # First request in window
                self.redis.setex(key, window, 1)
                return True, RateLimitInfo(
                    limit=limit,
                    remaining=limit - 1,
                    reset_time=datetime.utcnow() + timedelta(seconds=window)
                )
            
            current_count = int(current)
            if current_count >= limit:
                ttl = self.redis.ttl(key)
                return False, RateLimitInfo(
                    limit=limit,
                    remaining=0,
                    reset_time=datetime.utcnow() + timedelta(seconds=ttl)
                )
            
            # Increment counter
            self.redis.incr(key)
            ttl = self.redis.ttl(key)
            return True, RateLimitInfo(
                limit=limit,
                remaining=limit - current_count - 1,
                reset_time=datetime.utcnow() + timedelta(seconds=ttl)
            )
        except Exception as e:
            logger.error(f"Rate limiting error: {e}")
            # Allow request if rate limiting fails
            return True, RateLimitInfo(limit=limit, remaining=limit, reset_time=datetime.utcnow())

rate_limiter = RateLimiter(redis_client)

# Authentication
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Optional[Dict[str, Any]]:
    """Extract and validate JWT token."""
    if not credentials:
        return None
    
    try:
        payload = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# Service proxy
class ServiceProxy:
    def __init__(self):
        # Don't follow redirects to preserve multipart form data
        self.client = httpx.AsyncClient(timeout=30.0, follow_redirects=False)
    
    async def forward_request(
        self,
        service_name: str,
        path: str,
        method: str,
        headers: Dict[str, str],
        params: Dict[str, Any] = None,
        json_data: Dict[str, Any] = None,
        files: Dict[str, Any] = None
    ) -> httpx.Response:
        """Forward request to appropriate microservice."""
        if service_name not in SERVICES:
            raise HTTPException(status_code=404, detail=f"Service {service_name} not found")

        service_url = SERVICES[service_name]
        # Strip trailing slash from path to avoid FastAPI redirects
        clean_path = path.rstrip('/') if path != '/' else '/'
        url = f"{service_url}{clean_path}"
        logger.warning(f"🔍 FORWARD: original_path='{path}', clean_path='{clean_path}', url='{url}'")
        
        # Remove problematic headers that cause conflicts
        headers_to_remove = {'host', 'content-length', 'transfer-encoding'}
        headers = {k: v for k, v in headers.items() if k.lower() not in headers_to_remove}
        
        try:
            # When files are present, use 'data' for form fields instead of 'json'
            if files:
                response = await self.client.request(
                    method=method,
                    url=url,
                    headers=headers,
                    params=params,
                    data=json_data,  # Use 'data' for form fields when uploading files
                    files=files,
                    follow_redirects=False  # Don't follow redirects to preserve form data
                )
            else:
                response = await self.client.request(
                    method=method,
                    url=url,
                    headers=headers,
                    params=params,
                    json=json_data,
                    files=files,
                    follow_redirects=False
                )
            return response
        except httpx.RequestError as e:
            logger.error(f"Service {service_name} request failed: {e}")
            raise HTTPException(status_code=503, detail=f"Service {service_name} unavailable")

proxy = ServiceProxy()

# Middleware for rate limiting and authentication
@app.middleware("http")
async def rate_limit_and_auth_middleware(request: Request, call_next):
    """Apply rate limiting and authentication to all requests."""
    
    # Skip rate limiting for health checks
    if request.url.path in ["/health", "/docs", "/redoc", "/openapi.json"]:
        return await call_next(request)
    
    # Rate limiting
    client_ip = request.client.host
    rate_limit_key = f"rate_limit:{client_ip}"
    
    allowed, rate_info = await rate_limiter.is_allowed(rate_limit_key)
    if not allowed:
        return JSONResponse(
            status_code=429,
            content={"detail": "Rate limit exceeded"},
            headers={
                "X-RateLimit-Limit": str(rate_info.limit),
                "X-RateLimit-Remaining": str(rate_info.remaining),
                "X-RateLimit-Reset": rate_info.reset_time.isoformat(),
            }
        )
    
    # Add rate limit headers to response
    response = await call_next(request)
    response.headers["X-RateLimit-Limit"] = str(rate_info.limit)
    response.headers["X-RateLimit-Remaining"] = str(rate_info.remaining)
    response.headers["X-RateLimit-Reset"] = rate_info.reset_time.isoformat()
    
    return response

# Health check endpoint
@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Check health of API gateway and all services."""
    service_health = {}
    
    for service_name, service_url in SERVICES.items():
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(f"{service_url}/health")
                service_health[service_name] = "healthy" if response.status_code == 200 else "unhealthy"
        except Exception:
            service_health[service_name] = "unreachable"
    
    overall_status = "healthy" if all(status == "healthy" for status in service_health.values()) else "degraded"
    
    return HealthResponse(
        status=overall_status,
        timestamp=datetime.utcnow(),
        services=service_health
    )

# Route definitions with service mapping
ROUTE_MAPPING = {
    # User Management Service
    "/api/auth/": "user-service",
    "/api/users/": "user-service",
    "/api/permissions/": "user-service",
    "/api/groups/": "user-service",
    
    # Service Registry
    "/api/services/": "service-registry",
    "/api/reference-panels/": "service-registry",
    
    # Job Processing
    "/api/jobs/": "job-processor",
    "/api/status-updates/": "job-processor",
    "/api/templates/": "job-processor",
    "/api/scheduled/": "job-processor",
    
    # File Management
    "/api/files/": "file-manager",
    "/api/result-files/": "file-manager",
    
    # Notifications
    "/api/notifications/": "notification",
    
    # Monitoring
    "/api/monitoring/": "monitoring",
    "/api/dashboard/": "monitoring",
}

def get_service_for_path(path: str) -> str:
    """Determine which service should handle the request based on path."""
    for route_prefix, service_name in ROUTE_MAPPING.items():
        if path.startswith(route_prefix):
            return service_name
    
    # Default to monitoring service for unknown paths
    return "monitoring"

# Generic proxy endpoint
@app.api_route("/api/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def proxy_to_service(
    request: Request,
    path: str,
    user: Optional[Dict[str, Any]] = Depends(get_current_user)
):
    """Proxy requests to appropriate microservice."""
    
    # Determine target service
    full_path = f"/api/{path}"
    service_name = get_service_for_path(full_path)
    
    # Prepare request data
    headers = dict(request.headers)
    
    # Add user context to headers if authenticated
    if user:
        headers["X-User-ID"] = str(user.get("user_id", ""))
        headers["X-User-Email"] = user.get("email", "")
        headers["X-User-Roles"] = ",".join(user.get("roles", []))
    
    # Get request body and files
    json_data = None
    files = None
    
    if request.method in ["POST", "PUT", "PATCH"]:
        content_type = request.headers.get("content-type", "")
        if "application/json" in content_type:
            json_data = await request.json()
        elif "multipart/form-data" in content_type:
            form = await request.form()
            # Separate files from form fields
            files = {}
            json_data = {}
            for key, value in form.items():
                if hasattr(value, 'file'):
                    # This is a file upload
                    files[key] = (value.filename, await value.read(), value.content_type)
                else:
                    # This is a regular form field
                    json_data[key] = value
    
    # Forward request to service
    # Strip trailing slash from path to avoid FastAPI redirects that lose form data
    forward_path = f"/{path}".rstrip('/') if path else '/'
    logger.warning(f"🔍 PROXY: path='{path}', forward_path='{forward_path}', full_path='{full_path}'")
    response = await proxy.forward_request(
        service_name=service_name,
        path=forward_path,  # Remove /api prefix and trailing slash
        method=request.method,
        headers=headers,
        params=dict(request.query_params),
        json_data=json_data,
        files=files
    )
    
    # Return response (remove content-length to avoid conflicts)
    response_headers = {k: v for k, v in dict(response.headers).items()
                       if k.lower() not in {'content-length', 'transfer-encoding'}}

    return JSONResponse(
        status_code=response.status_code,
        content=response.json() if response.headers.get("content-type", "").startswith("application/json") else response.text,
        headers=response_headers
    )

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
