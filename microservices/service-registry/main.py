"""
Service Registry Service for Federated Genomic Imputation Platform
Manages external imputation services, health monitoring, and reference panels.
"""

import os
import logging
import asyncio
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any

import httpx
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
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
    
    # Service status
    is_active = Column(Boolean, default=True)
    is_available = Column(Boolean, default=True)
    last_health_check = Column(DateTime)
    health_status = Column(String(20), default='unknown')  # healthy, unhealthy, unknown
    response_time_ms = Column(Float)
    error_message = Column(Text)
    
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

# Dependency to get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Pydantic models
class ServiceCreate(BaseModel):
    name: str
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

class ServiceResponse(BaseModel):
    id: int
    name: str
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
    is_active: bool
    is_available: bool
    last_health_check: Optional[datetime]
    health_status: str
    response_time_ms: Optional[float]
    error_message: Optional[str]
    created_at: datetime
    updated_at: datetime

class ReferencePanelCreate(BaseModel):
    service_id: int
    name: str
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

# Service health checker
class ServiceHealthChecker:
    def __init__(self):
        self.client = httpx.AsyncClient(timeout=10.0)
    
    async def check_service_health(self, service: ImputationService) -> Dict[str, Any]:
        """Check health of a specific service."""
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

            response = await self.client.get(health_url, timeout=10.0)

            end_time = datetime.utcnow()
            response_time = (end_time - start_time).total_seconds() * 1000

            # Michigan special case: HTTP 401 means API is online and functioning
            if service.api_type == 'michigan' and response.status_code == 401:
                return {
                    "status": "healthy",
                    "response_time_ms": response_time,
                    "error_message": None
                }
            elif response.status_code in [200, 201, 202]:
                return {
                    "status": "healthy",
                    "response_time_ms": response_time,
                    "error_message": None
                }
            else:
                return {
                    "status": "unhealthy",
                    "response_time_ms": response_time,
                    "error_message": f"HTTP {response.status_code}: {response.text[:200]}"
                }
        
        except httpx.TimeoutException:
            return {
                "status": "timeout",
                "response_time_ms": None,
                "error_message": "Service health check timed out"
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "response_time_ms": None,
                "error_message": str(e)[:200]
            }
    
    async def check_all_services(self, db: Session):
        """Check health of all active services."""
        services = db.query(ImputationService).filter(ImputationService.is_active == True).all()
        
        for service in services:
            health_result = await self.check_service_health(service)
            
            # Update service health status
            service.health_status = health_result["status"]
            service.response_time_ms = health_result["response_time_ms"]
            service.error_message = health_result["error_message"]
            service.last_health_check = datetime.utcnow()
            service.is_available = health_result["status"] == "healthy"
            
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
    """Run health checks every 5 minutes."""
    while True:
        try:
            db = SessionLocal()
            await health_checker.check_all_services(db)
            db.close()
        except Exception as e:
            logger.error(f"Health check error: {e}")
        
        await asyncio.sleep(300)  # 5 minutes

# Start background task
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(periodic_health_check())

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
    
    return [
        ServiceResponse(
            id=service.id,
            name=service.name,
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
            is_active=service.is_active,
            is_available=service.is_available,
            last_health_check=service.last_health_check,
            health_status=service.health_status,
            response_time_ms=service.response_time_ms,
            error_message=service.error_message,
            created_at=service.created_at,
            updated_at=service.updated_at
        )
        for service in services
    ]

@app.get("/services/{service_id}", response_model=ServiceResponse)
async def get_service(service_id: int, db: Session = Depends(get_db)):
    """Get a specific service by ID."""
    service = db.query(ImputationService).filter(ImputationService.id == service_id).first()
    
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    return ServiceResponse(
        id=service.id,
        name=service.name,
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
        is_active=service.is_active,
        is_available=service.is_available,
        last_health_check=service.last_health_check,
        health_status=service.health_status,
        response_time_ms=service.response_time_ms,
        error_message=service.error_message,
        created_at=service.created_at,
        updated_at=service.updated_at
    )

@app.post("/services", response_model=ServiceResponse)
async def create_service(service_data: ServiceCreate, db: Session = Depends(get_db)):
    """Create a new imputation service."""
    service = ImputationService(
        name=service_data.name,
        service_type=service_data.service_type,
        api_type=service_data.api_type,
        base_url=str(service_data.base_url),
        description=service_data.description,
        version=service_data.version,
        requires_auth=service_data.requires_auth,
        auth_type=service_data.auth_type,
        max_file_size_mb=service_data.max_file_size_mb,
        supported_formats=service_data.supported_formats,
        supported_builds=service_data.supported_builds
    )
    
    db.add(service)
    db.commit()
    db.refresh(service)
    
    logger.info(f"Created new service: {service.name}")
    
    return ServiceResponse(
        id=service.id,
        name=service.name,
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
        is_active=service.is_active,
        is_available=service.is_available,
        last_health_check=service.last_health_check,
        health_status=service.health_status,
        response_time_ms=service.response_time_ms,
        error_message=service.error_message,
        created_at=service.created_at,
        updated_at=service.updated_at
    )

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

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8002, reload=True)
