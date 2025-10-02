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
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks, UploadFile, File, Form
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
USER_SERVICE_URL = os.getenv('USER_SERVICE_URL', 'http://user-service:8001')
SERVICE_REGISTRY_URL = os.getenv('SERVICE_REGISTRY_URL', 'http://service-registry:8002')
FILE_MANAGER_URL = os.getenv('FILE_MANAGER_URL', 'http://file-manager:8004')
NOTIFICATION_URL = os.getenv('NOTIFICATION_URL', 'http://notification:8005')

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

# FastAPI app
app = FastAPI(
    title="Job Processing Service",
    description="Job lifecycle management and execution",
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

class JobStatusUpdateResponse(BaseModel):
    id: int
    job_id: str
    status: str
    progress_percentage: int
    message: Optional[str]
    details: Dict[str, Any]
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

@app.post("/jobs", response_model=JobResponse)
async def create_job(
    name: str = Form(...),
    description: str = Form(None),
    service_id: int = Form(...),
    reference_panel_id: int = Form(...),
    input_format: str = Form('vcf'),
    build: str = Form('hg38'),
    phasing: bool = Form(True),
    population: str = Form(None),
    input_file: UploadFile = File(...),
    user_id: int = 123,  # This would come from JWT token in real implementation
    db: Session = Depends(get_db)
):
    """Create a new imputation job."""
    
    # Create job record
    job = ImputationJob(
        user_id=user_id,
        name=name,
        description=description,
        service_id=service_id,
        reference_panel_id=reference_panel_id,
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
    user_id: int = 123,  # This would come from JWT token
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

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8003, reload=True)
