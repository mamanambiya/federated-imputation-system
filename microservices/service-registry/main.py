"""
Service Registry Service for Federated Genomic Imputation Platform
Manages external imputation services, health monitoring, and reference panels.
"""

import os
import logging
import asyncio
import math
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any, Tuple

import httpx
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, Text, Float, JSON, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
from sqlalchemy.dialects.postgresql import UUID
from pydantic import BaseModel, HttpUrl
import uuid
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@postgres:5432/service_registry_db')

# Database setup
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Models
class ImputationService(Base):
    __tablename__ = "imputation_services"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False, index=True)
    slug = Column(String(100), unique=True, index=True)  # User-friendly identifier (e.g., 'h3africa-ilifu')
    service_type = Column(String(50), nullable=False)  # h3africa, michigan, ga4gh, dnastack
    api_type = Column(String(50), nullable=False)  # michigan, ga4gh, dnastack
    base_url = Column(String(500), nullable=False)
    description = Column(Text)
    version = Column(String(50))
    
    # Service configuration
    requires_auth = Column(Boolean, default=True)
    auth_type = Column(String(50))  # token, oauth2, api_key
    max_file_size_mb = Column(Integer, default=100)
    supported_formats = Column(JSON, default=list)  # ['vcf', 'plink', 'bgen']
    supported_builds = Column(JSON, default=list)  # ['hg19', 'hg38']
    api_config = Column(JSON, default=dict)  # Stores connection parameters (API keys, tokens, headers)
    
    # Service status
    is_active = Column(Boolean, default=True)
    is_available = Column(Boolean, default=True)
    last_health_check = Column(DateTime)
    health_status = Column(String(20), default='unknown')  # healthy, unhealthy, unknown
    response_time_ms = Column(Float)
    error_message = Column(Text)
    first_unhealthy_at = Column(DateTime)  # Track when service first became unhealthy for auto-deactivation

    # Resources (assume max available if not reported by service)
    cpu_available = Column(Integer)
    cpu_total = Column(Integer)
    memory_available_gb = Column(Float)
    memory_total_gb = Column(Float)
    storage_available_gb = Column(Float)
    storage_total_gb = Column(Float)
    queue_capacity = Column(Integer)
    queue_current = Column(Integer, default=0)

    # Location (manually captured if not available from service)
    location_country = Column(String(100))
    location_city = Column(String(100))
    location_datacenter = Column(String(200))
    location_latitude = Column(Float)
    location_longitude = Column(Float)

    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    reference_panels = relationship("ReferencePanel", back_populates="service")

class ReferencePanel(Base):
    __tablename__ = "reference_panels"

    id = Column(Integer, primary_key=True, index=True)
    service_id = Column(Integer, ForeignKey("imputation_services.id"), nullable=False, index=True)
    name = Column(String(200), nullable=False)
    slug = Column(String(100), unique=True, index=True)  # User-friendly identifier (e.g., 'h3africa-v6')
    display_name = Column(String(200))
    description = Column(Text)
    
    # Panel characteristics
    population = Column(String(100))
    build = Column(String(20))  # hg19, hg38
    samples_count = Column(Integer)
    variants_count = Column(Integer)
    
    # Availability
    is_available = Column(Boolean, default=True)
    is_public = Column(Boolean, default=True)
    requires_permission = Column(Boolean, default=False)
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    service = relationship("ImputationService", back_populates="reference_panels")

class ServiceHealthLog(Base):
    __tablename__ = "service_health_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    service_id = Column(Integer, nullable=False, index=True)
    status = Column(String(20), nullable=False)  # healthy, unhealthy, timeout
    response_time_ms = Column(Float)
    error_message = Column(Text)
    checked_at = Column(DateTime, default=datetime.utcnow, index=True)

# Create tables
Base.metadata.create_all(bind=engine)

# FastAPI app
app = FastAPI(
    title="Service Registry Service",
    description="External service management and health monitoring",
    version="1.0.0"
)

# Configure CORS to allow frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://154.114.10.123:3000",
        "http://154.114.10.123",
        "*"  # Allow all origins for development
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency to get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Utility functions
def generate_slug(name: str) -> str:
    """
    Generate a URL-safe slug from a name.
    Examples:
        'H3Africa ILIFU' -> 'h3africa-ilifu'
        'Michigan Imputation Server' -> 'michigan-imputation-server'
        'H3Africa v6' -> 'h3africa-v6'
    """
    import re
    # Convert to lowercase
    slug = name.lower()
    # Replace spaces and underscores with hyphens
    slug = re.sub(r'[\s_]+', '-', slug)
    # Remove any characters that aren't alphanumeric or hyphens
    slug = re.sub(r'[^a-z0-9\-]', '', slug)
    # Remove multiple consecutive hyphens
    slug = re.sub(r'-+', '-', slug)
    # Remove leading/trailing hyphens
    slug = slug.strip('-')
    return slug

def get_service_by_id_or_slug(db: Session, identifier: str) -> Optional[ImputationService]:
    """
    Lookup service by either numeric ID or slug.
    Supports both: service_id=1 and service_id='h3africa-ilifu'
    """
    # Try numeric ID first
    if identifier.isdigit():
        return db.query(ImputationService).filter(ImputationService.id == int(identifier)).first()
    # Otherwise, lookup by slug
    return db.query(ImputationService).filter(ImputationService.slug == identifier).first()

def get_panel_by_id_or_slug(db: Session, identifier: str) -> Optional[ReferencePanel]:
    """
    Lookup reference panel by either numeric ID or slug.
    Supports both: reference_panel_id=1 and reference_panel_id='h3africa-v6'
    """
    # Try numeric ID first
    if identifier.isdigit():
        return db.query(ReferencePanel).filter(ReferencePanel.id == int(identifier)).first()
    # Otherwise, lookup by slug
    return db.query(ReferencePanel).filter(ReferencePanel.slug == identifier).first()

def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance between two points on Earth using Haversine formula.

    Args:
        lat1, lon1: Latitude and longitude of first point (in decimal degrees)
        lat2, lon2: Latitude and longitude of second point (in decimal degrees)

    Returns:
        Distance in kilometers

    Example:
        >>> calculate_distance(-33.9249, 18.4241, 42.2808, -83.7430)
        13089.47  # Cape Town to Ann Arbor
    """
    # Convert decimal degrees to radians
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)

    # Haversine formula
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    a = math.sin(dlat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))

    # Earth's radius in kilometers
    radius_km = 6371.0

    return c * radius_km

def calculate_service_score(
    service: ImputationService,
    user_lat: Optional[float] = None,
    user_lon: Optional[float] = None,
    min_cpu: Optional[int] = None,
    min_memory_gb: Optional[float] = None,
    min_storage_gb: Optional[float] = None
) -> Dict[str, Any]:
    """
    Calculate a suitability score for a service based on multiple criteria.

    Scoring factors (ONLINE SERVICES ALWAYS RANK FIRST):
    - Health/Availability (60 pts): healthy+online=60, timeout=25, unhealthy=10, inactive=0
    - Distance (20 pts): closer is better (if coordinates provided)
    - Response time (10 pts): faster is better (only for healthy services)
    - Resources (10 pts): meets requirements or assumed available (null)

    Online services score 60-100, offline services max at 45, ensuring online always ranks higher.

    Returns:
        Dict with score (0-100), distance_km, and score breakdown
    """
    score = 100.0
    breakdown = {}
    distance_km = None

    # 1. Health and availability (60 points) - MUST be online to rank high
    # Healthy services: 60 points (ensures they ALWAYS rank above offline)
    # Timeout services: 25 points (offline, but responsive)
    # Unhealthy services: 10 points (offline, not responsive)
    # Inactive services: 0 points (disabled)
    if not service.is_active:
        health_score = 0.0
    elif service.health_status == "healthy" and service.is_available:
        health_score = 60.0  # Online services get baseline 60 points
    elif service.health_status == "timeout":
        health_score = 25.0  # Offline but reachable
    elif service.health_status == "unhealthy":
        health_score = 10.0  # Offline and unreachable
    else:
        health_score = 0.0

    breakdown["health"] = health_score
    score = health_score

    # 2. Distance score (20 points) - closer is better
    if user_lat and user_lon and service.location_latitude and service.location_longitude:
        distance_km = calculate_distance(
            user_lat, user_lon,
            service.location_latitude, service.location_longitude
        )
        # Exponential decay: 0km=20pts, 5000km=10pts, 10000km=5pts
        distance_score = 20 * math.exp(-distance_km / 7500)
        breakdown["distance"] = distance_score
        score += distance_score
    else:
        breakdown["distance"] = 0.0

    # 3. Response time score (10 points) - faster is better (only for healthy services)
    if service.response_time_ms and service.health_status == "healthy":
        # 0ms=10pts, 100ms=9pts, 500ms=5pts, 1000ms=2.5pts
        response_score = 10 * math.exp(-service.response_time_ms / 500)
        breakdown["response_time"] = response_score
        score += response_score
    else:
        breakdown["response_time"] = 0.0

    # 4. Resource availability score (10 points)
    resource_score = 0.0

    # CPU check (3.3 points)
    if min_cpu:
        if service.cpu_available is None or service.cpu_total is None:
            # Assume available (per user requirement)
            resource_score += 3.3
        elif service.cpu_available >= min_cpu:
            resource_score += 3.3
        else:
            resource_score += 1.0  # Has some, but not enough
    else:
        resource_score += 3.3  # No requirement

    # Memory check (3.3 points)
    if min_memory_gb:
        if service.memory_available_gb is None or service.memory_total_gb is None:
            # Assume available
            resource_score += 3.3
        elif service.memory_available_gb >= min_memory_gb:
            resource_score += 3.3
        else:
            resource_score += 1.0
    else:
        resource_score += 3.3

    # Storage check (3.4 points)
    if min_storage_gb:
        if service.storage_available_gb is None or service.storage_total_gb is None:
            # Assume available
            resource_score += 3.4
        elif service.storage_available_gb >= min_storage_gb:
            resource_score += 3.4
        else:
            resource_score += 1.0
    else:
        resource_score += 3.4

    breakdown["resources"] = resource_score
    score += resource_score

    return {
        "score": round(score, 2),
        "distance_km": round(distance_km, 2) if distance_km else None,
        "breakdown": breakdown
    }

# Pydantic models
class ServiceCreate(BaseModel):
    name: str
    slug: Optional[str] = None  # Auto-generated from name if not provided
    service_type: str
    api_type: str
    base_url: HttpUrl
    description: Optional[str] = None
    version: Optional[str] = None
    requires_auth: bool = True
    auth_type: Optional[str] = None
    max_file_size_mb: int = 100
    supported_formats: List[str] = []
    supported_builds: List[str] = []
    api_config: Optional[Dict[str, Any]] = {}

    # Location information
    location_country: Optional[str] = None
    location_city: Optional[str] = None
    location_datacenter: Optional[str] = None
    location_latitude: Optional[float] = None
    location_longitude: Optional[float] = None

    # Resource capacity
    cpu_total: Optional[int] = None
    memory_total_gb: Optional[float] = None
    storage_total_gb: Optional[float] = None
    queue_capacity: Optional[int] = None

class ServiceUpdate(BaseModel):
    """Model for partial service updates (PATCH)"""
    name: Optional[str] = None
    service_type: Optional[str] = None
    api_type: Optional[str] = None
    base_url: Optional[HttpUrl] = None
    description: Optional[str] = None
    version: Optional[str] = None
    requires_auth: Optional[bool] = None
    auth_type: Optional[str] = None
    max_file_size_mb: Optional[int] = None
    supported_formats: Optional[List[str]] = None
    supported_builds: Optional[List[str]] = None
    api_config: Optional[Dict[str, Any]] = None
    is_active: Optional[bool] = None

    # Location information
    location_country: Optional[str] = None
    location_city: Optional[str] = None
    location_datacenter: Optional[str] = None
    location_latitude: Optional[float] = None
    location_longitude: Optional[float] = None

    # Resource capacity
    cpu_total: Optional[int] = None
    memory_total_gb: Optional[float] = None
    storage_total_gb: Optional[float] = None
    queue_capacity: Optional[int] = None

class ServiceResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: int
    name: str
    slug: str
    service_type: str
    api_type: str
    base_url: str
    description: Optional[str]
    version: Optional[str]
    requires_auth: bool
    auth_type: Optional[str]
    max_file_size_mb: int
    supported_formats: List[str]
    supported_builds: List[str]
    api_config: Optional[Dict[str, Any]]
    is_active: bool
    is_available: bool
    last_health_check: Optional[datetime]
    health_status: str
    response_time_ms: Optional[float]
    error_message: Optional[str]
    created_at: datetime
    updated_at: datetime

    # Resources (None means not reported, assume max available)
    cpu_available: Optional[int] = None
    cpu_total: Optional[int] = None
    memory_available_gb: Optional[float] = None
    memory_total_gb: Optional[float] = None
    storage_available_gb: Optional[float] = None
    storage_total_gb: Optional[float] = None
    queue_capacity: Optional[int] = None
    queue_current: Optional[int] = 0

    # Location
    location_country: Optional[str] = None
    location_city: Optional[str] = None
    location_datacenter: Optional[str] = None
    location_coordinates: Optional[Dict[str, float]] = None  # {"lat": 0.0, "lon": 0.0}

class ReferencePanelCreate(BaseModel):
    service_id: int
    name: str
    slug: Optional[str] = None  # Auto-generated from name if not provided
    display_name: Optional[str] = None
    description: Optional[str] = None
    population: Optional[str] = None
    build: Optional[str] = None
    samples_count: Optional[int] = None
    variants_count: Optional[int] = None
    is_available: bool = True
    is_public: bool = True
    requires_permission: bool = False

class ReferencePanelResponse(BaseModel):
    id: int
    service_id: int
    name: str
    slug: str
    display_name: Optional[str]
    description: Optional[str]
    population: Optional[str]
    build: Optional[str]
    samples_count: Optional[int]
    variants_count: Optional[int]
    is_available: bool
    is_public: bool
    requires_permission: bool
    created_at: datetime
    updated_at: datetime

class HealthCheckResponse(BaseModel):
    service_id: int
    status: str
    response_time_ms: Optional[float]
    error_message: Optional[str]
    checked_at: datetime

class ServiceDiscoveryResponse(BaseModel):
    """Extended service response with discovery metadata."""
    service: ServiceResponse
    discovery_metadata: Dict[str, Any]  # Contains score, distance_km, breakdown

# Service health checker
class ServiceHealthChecker:
    def __init__(self):
        # Configure separate timeouts for different operations
        # connect=30s: TLS handshake can be slow from Docker containers
        # read=10s: Actual response should be quick
        self.client = httpx.AsyncClient(
            timeout=httpx.Timeout(
                connect=30.0,  # 30 seconds for TLS handshake (Michigan needs this)
                read=10.0,     # 10 seconds for response
                write=10.0,    # 10 seconds for uploads
                pool=10.0      # 10 seconds for connection pool
            ),
            verify=True  # Explicit SSL verification
        )
    
    async def check_service_health(self, service: ImputationService) -> Dict[str, Any]:
        """Check health of a specific service and attempt to detect resources."""
        start_time = datetime.utcnow()

        try:
            # Determine the appropriate health check URL based on service type
            base_url = service.base_url.rstrip('/')

            if service.api_type == 'michigan':
                # Michigan Imputation Server - use /api/ endpoint
                health_url = f"{base_url}/api/"
            elif service.api_type == 'ga4gh':
                # GA4GH services have a service-info endpoint
                health_url = f"{base_url}/service-info"
            elif service.api_type == 'dnastack':
                # DNAstack - check root URL
                health_url = base_url
            else:
                # Default: try /health endpoint
                health_url = f"{base_url}/health"

            # Use client-level timeout configuration (30s connect, 10s read)
            response = await self.client.get(health_url)

            end_time = datetime.utcnow()
            response_time = (end_time - start_time).total_seconds() * 1000

            # Try to extract resource information from response (if available)
            resources = None
            if response.status_code in [200, 201, 202]:
                try:
                    data = response.json()
                    resources = self._extract_resources(data, service.api_type)
                except Exception as e:
                    logger.debug(f"Could not extract resources from {service.name}: {e}")

            # Michigan special case: HTTP 401 means API is online and functioning
            if service.api_type == 'michigan' and response.status_code == 401:
                return {
                    "status": "healthy",
                    "response_time_ms": response_time,
                    "error_message": None,
                    "resources": resources
                }
            elif response.status_code in [200, 201, 202]:
                return {
                    "status": "healthy",
                    "response_time_ms": response_time,
                    "error_message": None,
                    "resources": resources
                }
            else:
                return {
                    "status": "unhealthy",
                    "response_time_ms": response_time,
                    "error_message": f"HTTP {response.status_code}: {response.text[:200]}",
                    "resources": None
                }
        
        except httpx.TimeoutException:
            return {
                "status": "timeout",
                "response_time_ms": None,
                "error_message": "Service health check timed out",
                "resources": None
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "response_time_ms": None,
                "error_message": str(e)[:200],
                "resources": None
            }

    def _extract_resources(self, data: dict, api_type: str) -> Optional[Dict[str, Any]]:
        """
        Attempt to extract resource information from API response.
        Returns dict with resource info if found, None otherwise.
        """
        resources = {}

        try:
            # GA4GH service-info may contain resource information
            if api_type == 'ga4gh':
                # Try common GA4GH patterns
                if 'resources' in data:
                    res = data['resources']
                    if 'cpu' in res:
                        resources['cpu_total'] = res['cpu'].get('total')
                        resources['cpu_available'] = res['cpu'].get('available')
                    if 'memory' in res:
                        resources['memory_total_gb'] = res['memory'].get('total_gb')
                        resources['memory_available_gb'] = res['memory'].get('available_gb')
                    if 'storage' in res:
                        resources['storage_total_gb'] = res['storage'].get('total_gb')
                        resources['storage_available_gb'] = res['storage'].get('available_gb')
                    if 'queue' in res:
                        resources['queue_capacity'] = res['queue'].get('capacity')
                        resources['queue_current'] = res['queue'].get('current', 0)

            # Michigan Imputation Server may have status endpoint with queue info
            elif api_type == 'michigan':
                if 'queue' in data:
                    resources['queue_capacity'] = data['queue'].get('capacity')
                    resources['queue_current'] = data['queue'].get('size', 0)

            # Generic patterns that might work for any service
            if 'system' in data:
                sys = data['system']
                if 'cpu_count' in sys:
                    resources['cpu_total'] = sys['cpu_count']
                if 'memory_gb' in sys:
                    resources['memory_total_gb'] = sys['memory_gb']

            return resources if resources else None

        except Exception as e:
            logger.debug(f"Error extracting resources: {e}")
            return None
    
    async def check_all_services(self, db: Session):
        """Check health of all active services and auto-deactivate if offline >30 days."""
        services = db.query(ImputationService).filter(ImputationService.is_active == True).all()

        for service in services:
            health_result = await self.check_service_health(service)

            # Update service health status
            service.health_status = health_result["status"]
            service.response_time_ms = health_result["response_time_ms"]
            service.error_message = health_result["error_message"]
            service.last_health_check = datetime.utcnow()

            # Update resources from health check if available
            # If no resources detected, assume max resources available (as per user requirement)
            if health_result.get("resources"):
                resources = health_result["resources"]
                if "cpu_total" in resources:
                    service.cpu_total = resources["cpu_total"]
                    service.cpu_available = resources.get("cpu_available", resources["cpu_total"])
                if "memory_total_gb" in resources:
                    service.memory_total_gb = resources["memory_total_gb"]
                    service.memory_available_gb = resources.get("memory_available_gb", resources["memory_total_gb"])
                if "storage_total_gb" in resources:
                    service.storage_total_gb = resources["storage_total_gb"]
                    service.storage_available_gb = resources.get("storage_available_gb", resources["storage_total_gb"])
                if "queue_capacity" in resources:
                    service.queue_capacity = resources["queue_capacity"]
                    service.queue_current = resources.get("queue_current", 0)
            elif service.health_status == "healthy" and service.cpu_total is None:
                # Healthy service but no resource info - assume max resources available
                # This is a safe assumption: if service doesn't report, assume it has capacity
                service.cpu_available = service.cpu_total  # Keep as None if not set
                service.memory_available_gb = service.memory_total_gb
                service.storage_available_gb = service.storage_total_gb

            # Auto-deactivation logic: track offline duration and deactivate if >30 days
            if health_result["status"] in ["unhealthy", "timeout"]:
                # Track when service first became unhealthy
                if not service.first_unhealthy_at:
                    service.first_unhealthy_at = datetime.utcnow()
                    logger.warning(f"Service '{service.name}' (ID: {service.id}) became unhealthy")

                # Check if unhealthy for more than 30 days
                days_unhealthy = (datetime.utcnow() - service.first_unhealthy_at).days
                if days_unhealthy >= 30:
                    service.is_active = False
                    service.is_available = False
                    logger.error(
                        f"AUTO-DEACTIVATED service '{service.name}' (ID: {service.id}) "
                        f"after {days_unhealthy} days offline. First unhealthy: {service.first_unhealthy_at}"
                    )
                else:
                    service.is_available = False
                    # Log warning for services approaching 30-day threshold
                    if days_unhealthy >= 25:
                        days_remaining = 30 - days_unhealthy
                        logger.warning(
                            f"Service '{service.name}' (ID: {service.id}) will be auto-deactivated "
                            f"in {days_remaining} days if it remains offline"
                        )
            else:
                # Service recovered - reset unhealthy tracking
                if service.first_unhealthy_at:
                    days_was_unhealthy = (datetime.utcnow() - service.first_unhealthy_at).days
                    logger.info(
                        f"Service '{service.name}' (ID: {service.id}) RECOVERED "
                        f"after {days_was_unhealthy} days offline"
                    )
                    service.first_unhealthy_at = None
                service.is_available = True

            # Log health check result
            health_log = ServiceHealthLog(
                service_id=service.id,
                status=health_result["status"],
                response_time_ms=health_result["response_time_ms"],
                error_message=health_result["error_message"]
            )
            db.add(health_log)

        db.commit()
        logger.info(f"Health check completed for {len(services)} services")

health_checker = ServiceHealthChecker()

# Background task for periodic health checks
async def periodic_health_check():
    """Run health checks every 15 minutes."""
    while True:
        try:
            db = SessionLocal()
            logger.info("Starting periodic health check...")
            await health_checker.check_all_services(db)
            db.close()
            logger.info("Periodic health check completed successfully")
        except Exception as e:
            logger.error(f"Health check error: {e}")

        await asyncio.sleep(900)  # 15 minutes (900 seconds)

# Start background task
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(periodic_health_check())

# Helper function to build ServiceResponse with resources and location
def build_service_response(service: ImputationService) -> ServiceResponse:
    """Build ServiceResponse with all fields including resources and location."""
    # Build location coordinates dict if available
    location_coords = None
    if service.location_latitude is not None and service.location_longitude is not None:
        location_coords = {
            "lat": service.location_latitude,
            "lon": service.location_longitude
        }

    return ServiceResponse(
        id=service.id,
        name=service.name,
        slug=service.slug,
        service_type=service.service_type,
        api_type=service.api_type,
        base_url=str(service.base_url),
        description=service.description,
        version=service.version,
        requires_auth=service.requires_auth,
        auth_type=service.auth_type,
        max_file_size_mb=service.max_file_size_mb,
        supported_formats=service.supported_formats or [],
        supported_builds=service.supported_builds or [],
        api_config=service.api_config or {},
        is_active=service.is_active,
        is_available=service.is_available,
        last_health_check=service.last_health_check,
        health_status=service.health_status,
        response_time_ms=service.response_time_ms,
        error_message=service.error_message,
        created_at=service.created_at,
        updated_at=service.updated_at,
        # Resources (None if not set, frontend will assume max available)
        cpu_available=service.cpu_available,
        cpu_total=service.cpu_total,
        memory_available_gb=service.memory_available_gb,
        memory_total_gb=service.memory_total_gb,
        storage_available_gb=service.storage_available_gb,
        storage_total_gb=service.storage_total_gb,
        queue_capacity=service.queue_capacity,
        queue_current=service.queue_current,
        # Location
        location_country=service.location_country,
        location_city=service.location_city,
        location_datacenter=service.location_datacenter,
        location_coordinates=location_coords
    )

# API Endpoints
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "service-registry", "timestamp": datetime.utcnow()}

@app.get("/services", response_model=List[ServiceResponse])
async def list_services(
    service_type: Optional[str] = None,
    is_active: Optional[bool] = None,
    is_available: Optional[bool] = None,
    db: Session = Depends(get_db)
):
    """List all imputation services with optional filtering."""
    query = db.query(ImputationService)
    
    if service_type:
        query = query.filter(ImputationService.service_type == service_type)
    if is_active is not None:
        query = query.filter(ImputationService.is_active == is_active)
    if is_available is not None:
        query = query.filter(ImputationService.is_available == is_available)
    
    services = query.all()

    return [build_service_response(service) for service in services]

@app.get("/services/at-risk")
async def services_at_risk_check(db: Session = Depends(get_db)):
    """Get services that will be auto-deactivated soon (offline >25 days)."""
    from datetime import timedelta

    # Services offline for 25+ days are at risk (will deactivate at 30 days)
    threshold = datetime.utcnow() - timedelta(days=25)

    at_risk_services = db.query(ImputationService).filter(
        ImputationService.is_active == True,
        ImputationService.first_unhealthy_at < threshold,
        ImputationService.health_status.in_(['unhealthy', 'timeout'])
    ).all()

    return [
        {
            "id": service.id,
            "name": service.name,
            "service_type": service.service_type,
            "api_type": service.api_type,
            "base_url": service.base_url,
            "health_status": service.health_status,
            "days_offline": (datetime.utcnow() - service.first_unhealthy_at).days,
            "days_until_deactivation": 30 - (datetime.utcnow() - service.first_unhealthy_at).days,
            "first_unhealthy_at": service.first_unhealthy_at,
            "last_health_check": service.last_health_check,
            "error_message": service.error_message
        }
        for service in at_risk_services
    ]

@app.get("/services/discover", response_model=List[ServiceDiscoveryResponse])
async def discover_services(
    # Geographic filters
    latitude: Optional[float] = Query(None, description="User's latitude for proximity filtering"),
    longitude: Optional[float] = Query(None, description="User's longitude for proximity filtering"),
    max_distance_km: Optional[float] = Query(None, description="Maximum distance in kilometers"),

    # Resource filters
    min_cpu: Optional[int] = Query(None, description="Minimum CPU cores required"),
    min_memory_gb: Optional[float] = Query(None, description="Minimum memory in GB required"),
    min_storage_gb: Optional[float] = Query(None, description="Minimum storage in GB required"),

    # Service type filters
    service_type: Optional[str] = Query(None, description="Filter by service type"),
    api_type: Optional[str] = Query(None, description="Filter by API type"),

    # Other filters
    only_active: bool = Query(True, description="Only include active services"),
    only_healthy: bool = Query(False, description="Only include healthy services"),
    limit: int = Query(10, description="Maximum number of services to return", ge=1, le=50),

    db: Session = Depends(get_db)
):
    """
    Discover and rank services based on geographic proximity and resource availability.

    ONLINE SERVICES ALWAYS RANK FIRST - scoring ensures this guarantee.

    Scoring system (100 points total):
    - Health/Availability (60 pts): healthy+online=60, timeout=25, unhealthy=10, inactive=0
    - Geographic proximity (20 pts): closer is better (if coordinates provided)
    - Response time (10 pts): faster is better (only for healthy services)
    - Resource availability (10 pts): meets requirements or assumed available

    Online services score 60-100 points, offline services max at 45 points.
    For services without resource data, resources are assumed available.

    Example queries:
    - Find nearest healthy services: ?latitude=-33.92&longitude=18.42&only_healthy=true
    - Find services with 16GB+ memory: ?min_memory_gb=16
    - Find GA4GH services within 1000km: ?api_type=ga4gh&max_distance_km=1000
    """
    # Start with base query
    query = db.query(ImputationService)

    # Apply filters
    if only_active:
        query = query.filter(ImputationService.is_active == True)

    if only_healthy:
        query = query.filter(ImputationService.health_status == "healthy")

    if service_type:
        query = query.filter(ImputationService.service_type == service_type)

    if api_type:
        query = query.filter(ImputationService.api_type == api_type)

    services = query.all()

    # Calculate scores and filter by distance
    service_scores = []
    for service in services:
        # Calculate score with all criteria
        score_data = calculate_service_score(
            service,
            user_lat=latitude,
            user_lon=longitude,
            min_cpu=min_cpu,
            min_memory_gb=min_memory_gb,
            min_storage_gb=min_storage_gb
        )

        # Apply distance filter if specified
        if max_distance_km and score_data["distance_km"]:
            if score_data["distance_km"] > max_distance_km:
                continue  # Skip services beyond max distance

        service_scores.append({
            "service": service,
            "score_data": score_data
        })

    # Sort by score (highest first)
    service_scores.sort(key=lambda x: x["score_data"]["score"], reverse=True)

    # Limit results
    service_scores = service_scores[:limit]

    # Build response
    results = []
    for item in service_scores:
        results.append(ServiceDiscoveryResponse(
            service=build_service_response(item["service"]),
            discovery_metadata=item["score_data"]
        ))

    return results

@app.get("/services/{service_identifier}", response_model=ServiceResponse)
async def get_service(service_identifier: str, db: Session = Depends(get_db)):
    """Get a specific service by ID or slug. Supports both numeric IDs and slugs (e.g., 'h3africa-ilifu')."""
    service = get_service_by_id_or_slug(db, service_identifier)

    if not service:
        raise HTTPException(status_code=404, detail=f"Service '{service_identifier}' not found")

    return build_service_response(service)

@app.post("/services", response_model=ServiceResponse)
async def create_service(service_data: ServiceCreate, db: Session = Depends(get_db)):
    """Create a new imputation service."""
    # Generate slug if not provided
    slug = service_data.slug or generate_slug(service_data.name)

    # Check for duplicate slug
    existing = db.query(ImputationService).filter(ImputationService.slug == slug).first()
    if existing:
        raise HTTPException(status_code=400, detail=f"Service with slug '{slug}' already exists")

    service = ImputationService(
        name=service_data.name,
        slug=slug,
        service_type=service_data.service_type,
        api_type=service_data.api_type,
        base_url=str(service_data.base_url),
        description=service_data.description,
        version=service_data.version,
        requires_auth=service_data.requires_auth,
        auth_type=service_data.auth_type,
        max_file_size_mb=service_data.max_file_size_mb,
        supported_formats=service_data.supported_formats,
        supported_builds=service_data.supported_builds,
        api_config=service_data.api_config or {},
        # Location information
        location_country=service_data.location_country,
        location_city=service_data.location_city,
        location_datacenter=service_data.location_datacenter,
        location_latitude=service_data.location_latitude,
        location_longitude=service_data.location_longitude,
        # Resource capacity
        cpu_total=service_data.cpu_total,
        memory_total_gb=service_data.memory_total_gb,
        storage_total_gb=service_data.storage_total_gb,
        queue_capacity=service_data.queue_capacity
    )

    db.add(service)
    db.commit()
    db.refresh(service)

    logger.info(f"Created new service: {service.name} (slug: {service.slug})")

    return build_service_response(service)

@app.patch("/services/{service_id}", response_model=ServiceResponse)
async def update_service(
    service_id: int,
    service_data: ServiceUpdate,
    db: Session = Depends(get_db)
):
    """Update an existing imputation service (partial update)."""
    service = db.query(ImputationService).filter(ImputationService.id == service_id).first()

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    # Update only provided fields
    update_data = service_data.dict(exclude_unset=True)

    # Convert HttpUrl to string if base_url is being updated
    if 'base_url' in update_data and update_data['base_url'] is not None:
        update_data['base_url'] = str(update_data['base_url'])

    # Update service attributes
    for field, value in update_data.items():
        setattr(service, field, value)

    # Update the updated_at timestamp
    service.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(service)

    logger.info(f"Updated service: {service.name} (ID: {service_id})")

    return build_service_response(service)

@app.delete("/services/{service_id}")
async def delete_service(
    service_id: int,
    db: Session = Depends(get_db)
):
    """Delete an imputation service permanently."""
    service = db.query(ImputationService).filter(ImputationService.id == service_id).first()

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    service_name = service.name

    # Delete associated health logs first (foreign key constraint)
    db.query(ServiceHealthLog).filter(ServiceHealthLog.service_id == service_id).delete()

    # Delete associated reference panels
    db.query(ReferencePanel).filter(ReferencePanel.service_id == service_id).delete()

    # Delete the service
    db.delete(service)
    db.commit()

    logger.info(f"Deleted service: {service_name} (ID: {service_id})")

    return {
        "message": f"Service '{service_name}' deleted successfully",
        "deleted_service_id": service_id,
        "deleted_service_name": service_name
    }

@app.get("/services/{service_id}/health", response_model=HealthCheckResponse)
async def check_service_health_endpoint(
    service_id: int,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Manually trigger health check for a specific service."""
    service = db.query(ImputationService).filter(ImputationService.id == service_id).first()
    
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    # Perform health check
    health_result = await health_checker.check_service_health(service)
    
    # Update service status
    service.health_status = health_result["status"]
    service.response_time_ms = health_result["response_time_ms"]
    service.error_message = health_result["error_message"]
    service.last_health_check = datetime.utcnow()
    service.is_available = health_result["status"] == "healthy"
    
    # Log health check
    health_log = ServiceHealthLog(
        service_id=service.id,
        status=health_result["status"],
        response_time_ms=health_result["response_time_ms"],
        error_message=health_result["error_message"]
    )
    db.add(health_log)
    db.commit()
    
    return HealthCheckResponse(
        service_id=service.id,
        status=health_result["status"],
        response_time_ms=health_result["response_time_ms"],
        error_message=health_result["error_message"],
        checked_at=service.last_health_check
    )

@app.post("/services/force-health-check")
async def force_health_check_all(db: Session = Depends(get_db)):
    """
    Force an immediate health check for all services.
    This allows users to manually trigger health checks instead of waiting for the next scheduled check (15 min interval).
    Health checks run in background and results are stored in database.
    """
    try:
        # Run health checks asynchronously in background
        asyncio.create_task(health_checker.check_all_services(db))

        services_count = db.query(ImputationService).filter(ImputationService.is_active == True).count()

        return {
            "status": "initiated",
            "message": f"Health check initiated for {services_count} active services. Results will be available shortly.",
            "services_count": services_count,
            "timestamp": datetime.utcnow()
        }
    except Exception as e:
        logger.error(f"Error initiating force health check: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to initiate health check: {str(e)}")

@app.patch("/services/{service_id}/location", response_model=ServiceResponse)
async def update_service_location(
    service_id: int,
    location_data: dict,
    db: Session = Depends(get_db)
):
    """
    Manually set service location if not available from service API.

    Location data should include:
    - country: str (e.g., "South Africa")
    - city: str (e.g., "Cape Town")
    - datacenter: str (e.g., "ILIFU Data Centre")
    - coordinates: dict with "lat" and "lon" (e.g., {"lat": -33.9249, "lon": 18.4241})
    """
    service = db.query(ImputationService).filter(ImputationService.id == service_id).first()

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    # Update location fields if provided
    if "country" in location_data:
        service.location_country = location_data["country"]
    if "city" in location_data:
        service.location_city = location_data["city"]
    if "datacenter" in location_data:
        service.location_datacenter = location_data["datacenter"]
    if "coordinates" in location_data:
        coords = location_data["coordinates"]
        service.location_latitude = coords.get("lat")
        service.location_longitude = coords.get("lon")

    service.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(service)

    logger.info(f"Updated location for service: {service.name} (ID: {service_id})")

    return build_service_response(service)

@app.get("/reference-panels", response_model=List[ReferencePanelResponse])
async def list_reference_panels(
    service_id: Optional[int] = None,
    build: Optional[str] = None,
    population: Optional[str] = None,
    is_available: Optional[bool] = None,
    db: Session = Depends(get_db)
):
    """List reference panels with optional filtering."""
    query = db.query(ReferencePanel)

    if service_id:
        query = query.filter(ReferencePanel.service_id == service_id)
    if build:
        query = query.filter(ReferencePanel.build == build)
    if population:
        query = query.filter(ReferencePanel.population == population)
    if is_available is not None:
        query = query.filter(ReferencePanel.is_available == is_available)

    panels = query.all()

    return [
        ReferencePanelResponse(
            id=panel.id,
            service_id=panel.service_id,
            name=panel.name,
            slug=panel.slug,
            display_name=panel.display_name,
            description=panel.description,
            population=panel.population,
            build=panel.build,
            samples_count=panel.samples_count,
            variants_count=panel.variants_count,
            is_available=panel.is_available,
            is_public=panel.is_public,
            requires_permission=panel.requires_permission,
            created_at=panel.created_at,
            updated_at=panel.updated_at
        )
        for panel in panels
    ]

@app.post("/reference-panels", response_model=ReferencePanelResponse, status_code=201)
async def create_reference_panel(
    panel: ReferencePanelCreate,
    db: Session = Depends(get_db)
):
    """
    Manually create a reference panel for a service.

    This endpoint allows manual addition of reference panels since most
    imputation services don't provide programmatic APIs for panel discovery.
    """
    # Verify service exists
    service = db.query(ImputationService).filter(ImputationService.id == panel.service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail=f"Service with id {panel.service_id} not found")

    # Auto-generate slug if not provided
    slug = panel.slug
    if not slug:
        import re
        # Generate slug from name: lowercase, replace spaces/special chars with hyphens
        slug = re.sub(r'[^a-z0-9]+', '-', panel.name.lower()).strip('-')

        # Ensure slug uniqueness
        base_slug = slug
        counter = 1
        while db.query(ReferencePanel).filter(ReferencePanel.slug == slug).first():
            slug = f"{base_slug}-{counter}"
            counter += 1

    # Check if slug already exists
    existing = db.query(ReferencePanel).filter(ReferencePanel.slug == slug).first()
    if existing:
        raise HTTPException(status_code=400, detail=f"Reference panel with slug '{slug}' already exists")

    # Create panel
    db_panel = ReferencePanel(
        service_id=panel.service_id,
        name=panel.name,
        slug=slug,
        display_name=panel.display_name,
        description=panel.description,
        population=panel.population,
        build=panel.build,
        samples_count=panel.samples_count,
        variants_count=panel.variants_count,
        is_available=panel.is_available,
        is_public=panel.is_public,
        requires_permission=panel.requires_permission,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )

    db.add(db_panel)
    db.commit()
    db.refresh(db_panel)

    return ReferencePanelResponse(
        id=db_panel.id,
        service_id=db_panel.service_id,
        name=db_panel.name,
        slug=db_panel.slug,
        display_name=db_panel.display_name,
        description=db_panel.description,
        population=db_panel.population,
        build=db_panel.build,
        samples_count=db_panel.samples_count,
        variants_count=db_panel.variants_count,
        is_available=db_panel.is_available,
        is_public=db_panel.is_public,
        requires_permission=db_panel.requires_permission,
        created_at=db_panel.created_at,
        updated_at=db_panel.updated_at
    )

@app.get("/panels/{panel_id}", response_model=ReferencePanelResponse)
async def get_reference_panel(
    panel_id: int,
    db: Session = Depends(get_db)
):
    """
    Get a specific reference panel by ID.

    Used by job processor to retrieve Cloudgene app format for Michigan API submissions.
    """
    panel = db.query(ReferencePanel).filter(ReferencePanel.id == panel_id).first()

    if not panel:
        raise HTTPException(status_code=404, detail=f"Reference panel with id {panel_id} not found")

    return ReferencePanelResponse(
        id=panel.id,
        service_id=panel.service_id,
        name=panel.name,
        slug=panel.slug,
        display_name=panel.display_name,
        description=panel.description,
        population=panel.population,
        build=panel.build,
        samples_count=panel.samples_count,
        variants_count=panel.variants_count,
        is_available=panel.is_available,
        is_public=panel.is_public,
        requires_permission=panel.requires_permission,
        created_at=panel.created_at,
        updated_at=panel.updated_at
    )

@app.patch("/reference-panels/{panel_id}", response_model=ReferencePanelResponse)
async def update_reference_panel(
    panel_id: int,
    updates: dict,
    db: Session = Depends(get_db)
):
    """
    Update a reference panel.

    Allows updating panel metadata like display_name, description, etc.
    """
    # Find the panel
    panel = db.query(ReferencePanel).filter(ReferencePanel.id == panel_id).first()
    if not panel:
        raise HTTPException(status_code=404, detail=f"Reference panel with id {panel_id} not found")

    # Update allowed fields
    allowed_fields = ['name', 'display_name', 'description', 'population', 'build',
                     'samples_count', 'variants_count', 'is_available',
                     'is_public', 'requires_permission']

    for field, value in updates.items():
        if field in allowed_fields:
            setattr(panel, field, value)

    panel.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(panel)

    return ReferencePanelResponse(
        id=panel.id,
        service_id=panel.service_id,
        name=panel.name,
        slug=panel.slug,
        display_name=panel.display_name,
        description=panel.description,
        population=panel.population,
        build=panel.build,
        samples_count=panel.samples_count,
        variants_count=panel.variants_count,
        is_available=panel.is_available,
        is_public=panel.is_public,
        requires_permission=panel.requires_permission,
        created_at=panel.created_at,
        updated_at=panel.updated_at
    )

@app.delete("/reference-panels/{panel_id}", status_code=204)
async def delete_reference_panel(
    panel_id: int,
    db: Session = Depends(get_db)
):
    """
    Delete a reference panel.

    This endpoint allows removal of manually added or synced reference panels.
    """
    # Find the panel
    panel = db.query(ReferencePanel).filter(ReferencePanel.id == panel_id).first()
    if not panel:
        raise HTTPException(status_code=404, detail=f"Reference panel with id {panel_id} not found")

    # Delete the panel
    db.delete(panel)
    db.commit()

    return None

@app.post("/services/{service_id}/sync_reference_panels")
async def sync_reference_panels(service_id: int, db: Session = Depends(get_db)):
    """
    Sync reference panels for a specific service.

    Note: Most imputation services (Michigan, GA4GH) do not provide programmatic
    APIs to list reference panels. This endpoint exists for future enhancement
    when services expose panel listing APIs.

    For now, reference panels must be manually added via the admin interface.
    """
    service = db.query(ImputationService).filter(ImputationService.id == service_id).first()

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    # Check existing panels
    existing_panels = db.query(ReferencePanel).filter(ReferencePanel.service_id == service_id).count()

    return {
        "status": "not_supported",
        "message": f"Reference panel sync is not yet implemented for {service.api_type} services. "
                   f"Most imputation services do not expose programmatic APIs to list panels. "
                   f"Please add reference panels manually via the admin interface.",
        "service_id": service_id,
        "service_name": service.name,
        "service_type": service.api_type,
        "existing_panels": existing_panels,
        "suggestion": "Reference panels can be added manually through the database or admin interface."
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8002, reload=True)
