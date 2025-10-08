"""
Job Processing Service for Federated Genomic Imputation Platform
Handles job lifecycle management, status tracking, and external service communication.
"""

import os
import logging
import asyncio
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from enum import Enum

import httpx
import jwt
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks, UploadFile, File, Form, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, Text, Float, JSON, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
from sqlalchemy.dialects.postgresql import UUID
from pydantic import BaseModel
import uuid
import uvicorn
from celery import Celery

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@postgres:5432/job_processing_db')
REDIS_URL = os.getenv('REDIS_URL', 'redis://redis:6379')
USER_SERVICE_URL = os.getenv('USER_SERVICE_URL', 'http://user-service:8001')  # For credential validation
SERVICE_REGISTRY_URL = os.getenv('SERVICE_REGISTRY_URL', 'http://service-registry:8002')
FILE_MANAGER_URL = os.getenv('FILE_MANAGER_URL', 'http://file-manager:8004')
NOTIFICATION_URL = os.getenv('NOTIFICATION_URL', 'http://notification:8005')

# JWT Configuration (must match user-service)
JWT_SECRET = os.getenv('JWT_SECRET', 'your-secret-key-change-in-production')
JWT_ALGORITHM = 'HS256'

# Security
security = HTTPBearer()

# Database setup
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Celery setup
celery_app = Celery(
    'job_processor',
    broker=REDIS_URL,
    backend=REDIS_URL,
    include=['worker']
)

# Job Status Enum
class JobStatus(str, Enum):
    PENDING = "pending"
    QUEUED = "queued"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

# Database Models
class ImputationJob(Base):
    __tablename__ = "imputation_jobs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    name = Column(String(200), nullable=False)
    description = Column(Text)
    
    # Service configuration
    service_id = Column(Integer, nullable=False)
    reference_panel_id = Column(Integer, nullable=False)
    
    # Job parameters
    input_format = Column(String(20), default='vcf')  # vcf, plink, bgen
    build = Column(String(20), default='hg38')
    phasing = Column(Boolean, default=True)
    population = Column(String(100))
    
    # Job status and progress
    status = Column(String(20), default=JobStatus.PENDING, index=True)
    progress_percentage = Column(Integer, default=0)
    external_job_id = Column(String(200))  # Service-specific job ID
    
    # File information
    input_file_id = Column(Integer)  # Reference to file in file-manager service
    input_file_name = Column(String(255))
    input_file_size = Column(Integer)
    # Note: results_file_id column does not exist in current schema
    # Result files are managed separately by the file-manager service
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    started_at = Column(DateTime)
    completed_at = Column(DateTime)
    
    # Execution details
    execution_time_seconds = Column(Integer)
    error_message = Column(Text)
    service_response = Column(JSON, default=dict)
    
    # Relationships
    status_updates = relationship("JobStatusUpdate", back_populates="job")
    logs = relationship("JobLog", back_populates="job", order_by="JobLog.step_index, JobLog.timestamp")

class JobStatusUpdate(Base):
    __tablename__ = "job_status_updates"
    
    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(UUID(as_uuid=True), ForeignKey("imputation_jobs.id"), index=True)
    status = Column(String(20), nullable=False)
    progress_percentage = Column(Integer, default=0)
    message = Column(Text)
    details = Column(JSON, default=dict)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    
    # Relationships
    job = relationship("ImputationJob", back_populates="status_updates")

class JobLog(Base):
    __tablename__ = "job_logs"

    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(UUID(as_uuid=True), ForeignKey("imputation_jobs.id"), index=True)
    step_name = Column(String(100), nullable=False)  # e.g., "Input Validation", "Quality Control"
    step_index = Column(Integer, default=0)  # Order of steps
    log_type = Column(String(20), default='info')  # error, warning, info, success
    message = Column(Text, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)

    # Relationships
    job = relationship("ImputationJob", back_populates="logs")

class JobTemplate(Base):
    __tablename__ = "job_templates"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    description = Column(Text)
    user_id = Column(Integer, nullable=False)

    # Template configuration
    service_id = Column(Integer, nullable=False)
    reference_panel_id = Column(Integer, nullable=False)
    input_format = Column(String(20), default='vcf')
    build = Column(String(20), default='hg38')
    phasing = Column(Boolean, default=True)
    population = Column(String(100))

    # Metadata
    is_public = Column(Boolean, default=False)
    usage_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Create tables
Base.metadata.create_all(bind=engine)

# JWT Helper Functions
def get_user_id_from_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> int:
    """
    Extract user_id from JWT token.
    This is used as a dependency to authenticate requests.
    """
    try:
        token = credentials.credentials
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id: int = payload.get("user_id")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token: missing user_id")
        return user_id
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {str(e)}")
    except Exception as e:
        logger.error(f"Token verification error: {e}")
        raise HTTPException(status_code=401, detail="Authentication failed")

# FastAPI app
app = FastAPI(
    title="Job Processing Service",
    description="Job lifecycle management and execution",
    version="1.0.0",
    redirect_slashes=False  # Disable automatic redirect to prevent form data loss
)

# Dependency to get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Pydantic models
class JobCreate(BaseModel):
    name: str
    description: Optional[str] = None
    service_id: int
    reference_panel_id: int
    input_format: str = 'vcf'
    build: str = 'hg38'
    phasing: bool = True
    population: Optional[str] = None

class JobResponse(BaseModel):
    id: str
    user_id: int
    name: str
    description: Optional[str]
    service_id: int
    reference_panel_id: int
    status: str
    progress_percentage: int
    input_format: str
    build: str
    phasing: bool
    population: Optional[str]
    input_file_name: Optional[str]
    input_file_size: Optional[int]
    created_at: datetime
    updated_at: datetime
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    execution_time_seconds: Optional[int]
    error_message: Optional[str]
    service_response: Optional[Dict[str, Any]] = None
    external_job_id: Optional[str] = None

class JobStatusUpdateResponse(BaseModel):
    id: int
    job_id: str
    status: str
    progress_percentage: int
    message: Optional[str]
    details: Dict[str, Any]
    timestamp: datetime

class JobFileResponse(BaseModel):
    id: int
    name: str
    size: int
    type: str  # 'input' or 'result'
    created_at: Optional[datetime] = None

class JobLogResponse(BaseModel):
    id: int
    job_id: str
    step_name: str
    step_index: int
    log_type: str
    message: str
    timestamp: datetime

class JobTemplateCreate(BaseModel):
    name: str
    description: Optional[str] = None
    service_id: int
    reference_panel_id: int
    input_format: str = 'vcf'
    build: str = 'hg38'
    phasing: bool = True
    population: Optional[str] = None
    is_public: bool = False

class JobTemplateResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    user_id: int
    service_id: int
    reference_panel_id: int
    input_format: str
    build: str
    phasing: bool
    population: Optional[str]
    is_public: bool
    usage_count: int
    created_at: datetime
    updated_at: datetime

# Service communication
class ServiceCommunicator:
    def __init__(self):
        self.client = httpx.AsyncClient(timeout=30.0)
    
    async def get_user_info(self, user_id: int) -> Dict[str, Any]:
        """Get user information from user service."""
        try:
            response = await self.client.get(f"{USER_SERVICE_URL}/users/{user_id}")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to get user info: {e}")
            return {}
    
    async def get_service_info(self, service_id: int) -> Dict[str, Any]:
        """Get service information from service registry."""
        try:
            response = await self.client.get(f"{SERVICE_REGISTRY_URL}/services/{service_id}")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to get service info: {e}")
            return {}
    
    async def upload_file(self, file_data: bytes, filename: str, job_id: str) -> Dict[str, Any]:
        """Upload file to file manager service."""
        try:
            files = {"file": (filename, file_data, "application/octet-stream")}
            data = {"job_id": job_id, "file_type": "input"}
            response = await self.client.post(f"{FILE_MANAGER_URL}/files/upload", files=files, data=data)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to upload file: {e}")
            return {}
    
    async def send_notification(self, user_id: int, notification_type: str, title: str, message: str, data: Dict[str, Any] = None):
        """Send notification via notification service."""
        try:
            payload = {
                "user_id": user_id,
                "type": notification_type,
                "title": title,
                "message": message,
                "data": data or {},
                "channels": ["web", "email"]
            }
            response = await self.client.post(f"{NOTIFICATION_URL}/notifications", json=payload)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to send notification: {e}")
            return {}

service_comm = ServiceCommunicator()

# Job management functions
async def update_job_status(
    db: Session,
    job_id: str,
    status: JobStatus,
    progress: int = None,
    message: str = None,
    details: Dict[str, Any] = None
):
    """Update job status and create status update record."""
    job = db.query(ImputationJob).filter(ImputationJob.id == job_id).first()
    if not job:
        return
    
    # Update job
    job.status = status
    if progress is not None:
        job.progress_percentage = progress
    job.updated_at = datetime.utcnow()
    
    if status == JobStatus.RUNNING and not job.started_at:
        job.started_at = datetime.utcnow()
    elif status in [JobStatus.COMPLETED, JobStatus.FAILED, JobStatus.CANCELLED]:
        if not job.completed_at:
            job.completed_at = datetime.utcnow()
        if job.started_at:
            job.execution_time_seconds = int((job.completed_at - job.started_at).total_seconds())
    
    # Create status update record
    status_update = JobStatusUpdate(
        job_id=job_id,
        status=status,
        progress_percentage=progress or job.progress_percentage,
        message=message,
        details=details or {}
    )
    db.add(status_update)
    db.commit()
    
    # Send notification
    await service_comm.send_notification(
        user_id=job.user_id,
        notification_type="job_status_update",
        title=f"Job {status.title()}",
        message=f"Your job '{job.name}' is now {status}",
        data={
            "job_id": str(job.id),
            "job_name": job.name,
            "status": status,
            "progress": job.progress_percentage
        }
    )

# API Endpoints
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "job-processor", "timestamp": datetime.utcnow()}

@app.post("/jobs/", response_model=JobResponse)
@app.post("/jobs", response_model=JobResponse)
async def create_job(
    name: str = Form(...),
    description: str = Form(None),
    service_id: str = Form(...),  # Changed to str to support slugs
    reference_panel_id: str = Form(...),  # Changed to str to support slugs
    input_format: str = Form('vcf'),
    build: str = Form('hg38'),
    phasing: bool = Form(True),
    population: str = Form(None),
    user_token: str = Form(None),  # Optional user-provided API token for the service
    input_file: UploadFile = File(...),
    user_id: int = Depends(get_user_id_from_token),  # Extract user_id from JWT token
    db: Session = Depends(get_db)
):
    """
    Create a new imputation job.

    Supports both numeric IDs and slugs for service_id and reference_panel_id:
    - service_id: Can be "1" or "h3africa-ilifu"
    - reference_panel_id: Can be "1" or "h3africa-v6"
    """

    # Resolve service_id (support both numeric ID and slug)
    async with httpx.AsyncClient() as client:
        try:
            service_response = await client.get(f"{SERVICE_REGISTRY_URL}/services/{service_id}")
            service_response.raise_for_status()
            service_data = service_response.json()
            resolved_service_id = service_data['id']  # Get numeric ID
            logger.info(f"Resolved service '{service_id}' to ID {resolved_service_id}")
        except httpx.HTTPStatusError as e:
            raise HTTPException(
                status_code=404,
                detail=f"Service '{service_id}' not found. Please check the service ID or slug."
            )

    # Resolve reference_panel_id (support both numeric ID and slug)
    async with httpx.AsyncClient() as client:
        try:
            panels_response = await client.get(f"{SERVICE_REGISTRY_URL}/reference-panels")
            panels_response.raise_for_status()
            panels = panels_response.json()

            # Find panel by ID or slug
            resolved_panel = None
            if reference_panel_id.isdigit():
                resolved_panel = next((p for p in panels if p['id'] == int(reference_panel_id)), None)
            else:
                resolved_panel = next((p for p in panels if p['slug'] == reference_panel_id), None)

            if not resolved_panel:
                raise HTTPException(
                    status_code=404,
                    detail=f"Reference panel '{reference_panel_id}' not found. Please check the panel ID or slug."
                )

            resolved_panel_id = resolved_panel['id']
            logger.info(f"Resolved panel '{reference_panel_id}' to ID {resolved_panel_id}")
        except httpx.HTTPStatusError as e:
            raise HTTPException(
                status_code=500,
                detail="Failed to lookup reference panel"
            )

    # Handle user_token: If provided, save it to service credentials
    # This allows users to provide tokens directly during job submission
    if user_token and user_token.strip():
        async with httpx.AsyncClient() as client:
            try:
                # Save the token to user service credentials
                save_response = await client.post(
                    f"{USER_SERVICE_URL}/internal/users/{user_id}/service-credentials",
                    json={
                        "service_id": resolved_service_id,
                        "credential_type": "api_token",
                        "api_token": user_token,
                        "label": "Token from job submission",
                        "is_active": True
                    }
                )
                save_response.raise_for_status()
                logger.info(f"Saved API token for user {user_id}, service {resolved_service_id}")
            except httpx.HTTPStatusError as e:
                logger.warning(f"Failed to save user token: {e}. Job will proceed but may fail if service requires authentication.")
            except Exception as e:
                logger.warning(f"Error saving user token: {e}")

    # OPTIONAL: Validate user has credentials for the selected service
    # Note: This is currently set to warning-only mode for testing/development
    # In production, you may want to make this a hard requirement
    async with httpx.AsyncClient() as client:
        try:
            cred_response = await client.get(
                f"{USER_SERVICE_URL}/internal/users/{user_id}/service-credentials/{resolved_service_id}"
            )
            cred_response.raise_for_status()
            user_cred = cred_response.json()

            if not user_cred.get('has_credential'):
                logger.warning(
                    f"User {user_id} submitting job without configured credentials for service {resolved_service_id}. "
                    f"Job will proceed but may fail during execution if service requires authentication."
                )
                # Allow job submission to proceed
                # In production, you might want to:
                # - Make this a hard error
                # - Or allow only for services that don't require auth

            elif not user_cred.get('is_verified'):
                logger.warning(f"User {user_id} using unverified credential for service {resolved_service_id}")

        except httpx.HTTPStatusError as e:
            logger.warning(f"Could not verify user credentials for service {resolved_service_id}: {e}. Allowing job submission to proceed.")
            # Allow job submission even if credential check fails
            # This allows testing without setting up credentials

    # Create job record (use resolved numeric IDs)
    job = ImputationJob(
        user_id=user_id,
        name=name,
        description=description,
        service_id=resolved_service_id,  # Use resolved numeric ID
        reference_panel_id=resolved_panel_id,  # Use resolved numeric ID
        input_format=input_format,
        build=build,
        phasing=phasing,
        population=population,
        input_file_name=input_file.filename,
        input_file_size=input_file.size if hasattr(input_file, 'size') else 0
    )
    
    db.add(job)
    db.commit()
    db.refresh(job)
    
    # Upload file to file manager
    file_content = await input_file.read()
    file_info = await service_comm.upload_file(file_content, input_file.filename, str(job.id))
    
    if file_info:
        job.input_file_id = file_info.get('id')
        db.commit()
    
    # Queue job for processing
    celery_app.send_task('worker.process_job', args=[str(job.id)])
    
    # Update status to queued
    await update_job_status(db, str(job.id), JobStatus.QUEUED, 0, "Job queued for processing")
    
    logger.info(f"Created job {job.id} for user {user_id}")
    
    return JobResponse(
        id=str(job.id),
        user_id=job.user_id,
        name=job.name,
        description=job.description,
        service_id=job.service_id,
        reference_panel_id=job.reference_panel_id,
        status=job.status,
        progress_percentage=job.progress_percentage,
        input_format=job.input_format,
        build=job.build,
        phasing=job.phasing,
        population=job.population,
        input_file_name=job.input_file_name,
        input_file_size=job.input_file_size,
        created_at=job.created_at,
        updated_at=job.updated_at,
        started_at=job.started_at,
        completed_at=job.completed_at,
        execution_time_seconds=job.execution_time_seconds,
        error_message=job.error_message
    )

@app.get("/jobs", response_model=List[JobResponse])
async def list_jobs(
    status: Optional[str] = None,
    service_id: Optional[int] = None,
    user_id: int = Depends(get_user_id_from_token),  # Extract user_id from JWT token
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """List jobs for a user with optional filtering."""
    query = db.query(ImputationJob).filter(ImputationJob.user_id == user_id)
    
    if status:
        query = query.filter(ImputationJob.status == status)
    if service_id:
        query = query.filter(ImputationJob.service_id == service_id)
    
    jobs = query.order_by(ImputationJob.created_at.desc()).offset(skip).limit(limit).all()
    
    return [
        JobResponse(
            id=str(job.id),
            user_id=job.user_id,
            name=job.name,
            description=job.description,
            service_id=job.service_id,
            reference_panel_id=job.reference_panel_id,
            status=job.status,
            progress_percentage=job.progress_percentage,
            input_format=job.input_format,
            build=job.build,
            phasing=job.phasing,
            population=job.population,
            input_file_name=job.input_file_name,
            input_file_size=job.input_file_size,
            created_at=job.created_at,
            updated_at=job.updated_at,
            started_at=job.started_at,
            completed_at=job.completed_at,
            execution_time_seconds=job.execution_time_seconds,
            error_message=job.error_message
        )
        for job in jobs
    ]

@app.get("/jobs/stats")
async def get_job_stats(db: Session = Depends(get_db)):
    """Get aggregated job statistics for dashboard."""
    from sqlalchemy import func

    # Get total count
    total = db.query(func.count(ImputationJob.id)).scalar() or 0

    # Get counts by status
    completed = db.query(func.count(ImputationJob.id)).filter(
        ImputationJob.status == JobStatus.COMPLETED
    ).scalar() or 0

    running = db.query(func.count(ImputationJob.id)).filter(
        ImputationJob.status == JobStatus.RUNNING
    ).scalar() or 0

    failed = db.query(func.count(ImputationJob.id)).filter(
        ImputationJob.status == JobStatus.FAILED
    ).scalar() or 0

    # Calculate success rate
    success_rate = (completed / total * 100) if total > 0 else 0.0

    return {
        "total": total,
        "completed": completed,
        "running": running,
        "failed": failed,
        "success_rate": round(success_rate, 2)
    }

@app.get("/jobs/{job_id}", response_model=JobResponse)
async def get_job(job_id: str, db: Session = Depends(get_db)):
    """Get a specific job by ID."""
    job = db.query(ImputationJob).filter(ImputationJob.id == job_id).first()
    
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    return JobResponse(
        id=str(job.id),
        user_id=job.user_id,
        name=job.name,
        description=job.description,
        service_id=job.service_id,
        reference_panel_id=job.reference_panel_id,
        status=job.status,
        progress_percentage=job.progress_percentage,
        input_format=job.input_format,
        build=job.build,
        phasing=job.phasing,
        population=job.population,
        input_file_name=job.input_file_name,
        input_file_size=job.input_file_size,
        created_at=job.created_at,
        updated_at=job.updated_at,
        started_at=job.started_at,
        completed_at=job.completed_at,
        execution_time_seconds=job.execution_time_seconds,
        error_message=job.error_message
    )

@app.post("/jobs/{job_id}/cancel")
async def cancel_job(job_id: str, db: Session = Depends(get_db)):
    """Cancel a running job."""
    job = db.query(ImputationJob).filter(ImputationJob.id == job_id).first()
    
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    if job.status in [JobStatus.COMPLETED, JobStatus.FAILED, JobStatus.CANCELLED]:
        raise HTTPException(status_code=400, detail="Job cannot be cancelled")
    
    # Send cancellation task to Celery
    celery_app.send_task('worker.cancel_job', args=[job_id])
    
    # Update status
    await update_job_status(db, job_id, JobStatus.CANCELLED, message="Job cancellation requested")
    
    return {"message": "Job cancellation initiated", "job_id": job_id}

@app.get("/jobs/{job_id}/status-updates", response_model=List[JobStatusUpdateResponse])
async def get_job_status_updates(job_id: str, db: Session = Depends(get_db)):
    """Get status update history for a job."""
    updates = db.query(JobStatusUpdate).filter(
        JobStatusUpdate.job_id == job_id
    ).order_by(JobStatusUpdate.timestamp.desc()).all()

    return [
        JobStatusUpdateResponse(
            id=update.id,
            job_id=str(update.job_id),
            status=update.status,
            progress_percentage=update.progress_percentage,
            message=update.message,
            details=update.details,
            timestamp=update.timestamp
        )
        for update in updates
    ]

@app.get("/jobs/{job_id}/logs", response_model=List[JobLogResponse])
async def get_job_logs(job_id: str, db: Session = Depends(get_db)):
    """
    Get execution logs for a job, grouped by processing steps.

    Returns logs in chronological order, preserving the step structure
    from the external imputation service (e.g., Michigan Imputation Server steps).
    """
    logs = db.query(JobLog).filter(
        JobLog.job_id == job_id
    ).order_by(JobLog.step_index, JobLog.timestamp).all()

    return [
        JobLogResponse(
            id=log.id,
            job_id=str(log.job_id),
            step_name=log.step_name,
            step_index=log.step_index,
            log_type=log.log_type,
            message=log.message,
            timestamp=log.timestamp
        )
        for log in logs
    ]

@app.get("/jobs/{job_id}/files", response_model=List[JobFileResponse])
async def get_job_files(job_id: str, db: Session = Depends(get_db)):
    """
    Get list of files associated with a job (input files and result files).

    Returns:
    - Input file information if available
    - Result file information can be retrieved from file-manager service separately
    """
    job = db.query(ImputationJob).filter(ImputationJob.id == job_id).first()

    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    files = []

    # Add input file if available
    if job.input_file_id and job.input_file_name:
        files.append(JobFileResponse(
            id=job.input_file_id,
            name=job.input_file_name,
            size=job.input_file_size or 0,
            type="input",
            created_at=job.created_at
        ))

    # Note: Result files are stored separately and managed by the file-manager service
    # The frontend can query the file-manager service directly for result files
    # using the job_id if needed

    return files

@app.get("/jobs/{job_id}/results")
async def download_job_results(job_id: str, db: Session = Depends(get_db)):
    """
    Download job results file.

    Returns a redirect to the file download URL or file metadata.
    """
    job = db.query(ImputationJob).filter(ImputationJob.id == job_id).first()

    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    if job.status != JobStatus.COMPLETED:
        raise HTTPException(
            status_code=400,
            detail=f"Job is not completed. Current status: {job.status}"
        )

    if not job.results_file_id:
        raise HTTPException(
            status_code=404,
            detail="Results file not available. The job may have completed without generating results."
        )

    # Get download URL from file manager
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{FILE_MANAGER_URL}/files/{job.results_file_id}"
            )
            response.raise_for_status()

            file_info = response.json()

            # Return file information with download URL
            return {
                "job_id": str(job.id),
                "job_name": job.name,
                "file_id": job.results_file_id,
                "filename": file_info.get('filename', 'results.zip'),
                "file_size": file_info.get('file_size', 0),
                "download_url": f"{FILE_MANAGER_URL}/files/{job.results_file_id}/download",
                "created_at": file_info.get('created_at'),
                "message": "Results ready for download"
            }

    except httpx.HTTPStatusError as e:
        logger.error(f"Failed to get results file info: {e}")
        raise HTTPException(
            status_code=500,
            detail="Failed to retrieve results file information"
        )
    except Exception as e:
        logger.error(f"Error retrieving results: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving results: {str(e)}"
        )

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8003, reload=True)
