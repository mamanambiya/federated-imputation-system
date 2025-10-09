"""
File Management Service for Federated Genomic Imputation Platform
Handles file uploads, downloads, storage, and access control.
"""

import os
import logging
import hashlib
import shutil
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from pathlib import Path

from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form, Response, Request
from fastapi.responses import FileResponse, StreamingResponse
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, BigInteger, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.dialects.postgresql import UUID
from pydantic import BaseModel
import uuid
import uvicorn
import aiofiles

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@postgres:5432/file_management_db')
STORAGE_PATH = os.getenv('STORAGE_PATH', '/app/storage')
MAX_FILE_SIZE_MB = int(os.getenv('MAX_FILE_SIZE_MB', '500'))
ALLOWED_EXTENSIONS = {'.vcf', '.vcf.gz', '.bed', '.bim', '.fam', '.plink', '.bgen', '.sample', '.txt', '.csv', '.zip', '.tar.gz'}

# Ensure storage directories exist
Path(STORAGE_PATH).mkdir(parents=True, exist_ok=True)
Path(f"{STORAGE_PATH}/uploads").mkdir(parents=True, exist_ok=True)
Path(f"{STORAGE_PATH}/results").mkdir(parents=True, exist_ok=True)
Path(f"{STORAGE_PATH}/temp").mkdir(parents=True, exist_ok=True)

# Database setup
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Models
class FileRecord(Base):
    __tablename__ = "file_records"
    
    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(UUID(as_uuid=True), default=uuid.uuid4, unique=True, index=True)
    filename = Column(String(255), nullable=False)
    original_filename = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=False)
    file_size = Column(BigInteger, nullable=False)
    file_type = Column(String(50), nullable=False)  # input, result, temp
    mime_type = Column(String(100))
    
    # File integrity
    checksum_md5 = Column(String(32))
    checksum_sha256 = Column(String(64))
    
    # Ownership and access
    user_id = Column(Integer, nullable=False, index=True)
    job_id = Column(String(36), index=True)  # UUID as string
    is_public = Column(Boolean, default=False)
    
    # File status
    is_available = Column(Boolean, default=True)
    is_processed = Column(Boolean, default=False)
    processing_status = Column(String(50))  # pending, processing, completed, failed
    
    # Expiration
    expires_at = Column(DateTime)

    # Metadata
    extra_metadata = Column(Text)  # JSON string for additional metadata
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    accessed_at = Column(DateTime)

class FileAccessLog(Base):
    __tablename__ = "file_access_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    file_id = Column(Integer, nullable=False, index=True)
    user_id = Column(Integer, nullable=False)
    action = Column(String(50), nullable=False)  # upload, download, view, delete
    ip_address = Column(String(45))
    user_agent = Column(String(500))
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)

# Create tables
Base.metadata.create_all(bind=engine)

# FastAPI app
app = FastAPI(
    title="File Management Service",
    description="File upload, download, and storage management",
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
class FileUploadResponse(BaseModel):
    id: int
    uuid: str
    filename: str
    original_filename: str
    file_size: int
    file_type: str
    mime_type: Optional[str]
    checksum_md5: str
    checksum_sha256: str
    upload_url: str
    created_at: datetime

class FileInfoResponse(BaseModel):
    id: int
    uuid: str
    filename: str
    original_filename: str
    file_path: Optional[str]  # Contains external URL for external files
    file_size: int
    file_type: str
    mime_type: Optional[str]
    user_id: int
    job_id: Optional[str]
    is_public: bool
    is_available: bool
    is_processed: bool
    processing_status: Optional[str]
    expires_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    accessed_at: Optional[datetime]

class FileDownloadResponse(BaseModel):
    download_url: str
    filename: str
    file_size: int
    expires_at: datetime

class ExternalLinkCreate(BaseModel):
    job_id: str
    user_id: int
    filename: str
    file_size: int
    file_type: str = 'output'
    external_url: str
    file_hash: Optional[str] = None
    description: Optional[str] = None

class ExternalLinkResponse(BaseModel):
    id: int
    uuid: str
    filename: str
    file_size: int
    file_type: str
    external_url: str
    job_id: str
    user_id: int
    created_at: datetime

# Utility functions
def calculate_checksums(file_path: str) -> tuple[str, str]:
    """Calculate MD5 and SHA256 checksums for a file."""
    md5_hash = hashlib.md5()
    sha256_hash = hashlib.sha256()
    
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            md5_hash.update(chunk)
            sha256_hash.update(chunk)
    
    return md5_hash.hexdigest(), sha256_hash.hexdigest()

def get_file_extension(filename: str) -> str:
    """Get file extension, handling compressed files."""
    if filename.endswith('.vcf.gz'):
        return '.vcf.gz'
    elif filename.endswith('.tar.gz'):
        return '.tar.gz'
    else:
        return Path(filename).suffix.lower()

def is_allowed_file(filename: str) -> bool:
    """Check if file extension is allowed."""
    extension = get_file_extension(filename)
    return extension in ALLOWED_EXTENSIONS

def generate_unique_filename(original_filename: str, user_id: int) -> str:
    """Generate a unique filename for storage."""
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    file_uuid = str(uuid.uuid4())[:8]
    extension = get_file_extension(original_filename)
    return f"{user_id}_{timestamp}_{file_uuid}{extension}"

def log_file_access(db: Session, file_id: int, user_id: int, action: str, ip_address: str = None, user_agent: str = None):
    """Log file access for audit trail."""
    access_log = FileAccessLog(
        file_id=file_id,
        user_id=user_id,
        action=action,
        ip_address=ip_address,
        user_agent=user_agent
    )
    db.add(access_log)
    db.commit()

# API Endpoints
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "file-manager", "timestamp": datetime.utcnow()}

@app.post("/files/upload", response_model=FileUploadResponse)
async def upload_file(
    file: UploadFile = File(...),
    file_type: str = Form('input'),
    job_id: Optional[str] = Form(None),
    user_id: int = 123,  # This would come from JWT token in real implementation
    db: Session = Depends(get_db)
):
    """Upload a file to the storage system."""
    
    # Validate file
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")
    
    if not is_allowed_file(file.filename):
        raise HTTPException(status_code=400, detail=f"File type not allowed. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}")
    
    # Check file size
    file_content = await file.read()
    file_size = len(file_content)
    
    if file_size > MAX_FILE_SIZE_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"File too large. Maximum size: {MAX_FILE_SIZE_MB}MB")
    
    # Generate unique filename and path
    unique_filename = generate_unique_filename(file.filename, user_id)
    
    if file_type == 'result':
        file_path = f"{STORAGE_PATH}/results/{unique_filename}"
    elif file_type == 'temp':
        file_path = f"{STORAGE_PATH}/temp/{unique_filename}"
    else:
        file_path = f"{STORAGE_PATH}/uploads/{unique_filename}"
    
    try:
        # Save file to disk
        async with aiofiles.open(file_path, 'wb') as f:
            await f.write(file_content)
        
        # Calculate checksums
        md5_checksum, sha256_checksum = calculate_checksums(file_path)
        
        # Create database record
        file_record = FileRecord(
            filename=unique_filename,
            original_filename=file.filename,
            file_path=file_path,
            file_size=file_size,
            file_type=file_type,
            mime_type=file.content_type,
            checksum_md5=md5_checksum,
            checksum_sha256=sha256_checksum,
            user_id=user_id,
            job_id=job_id,
            expires_at=datetime.utcnow() + timedelta(days=30) if file_type == 'temp' else None
        )
        
        db.add(file_record)
        db.commit()
        db.refresh(file_record)
        
        # Log access
        log_file_access(db, file_record.id, user_id, 'upload')
        
        logger.info(f"File uploaded: {file.filename} -> {unique_filename} (User: {user_id})")
        
        return FileUploadResponse(
            id=file_record.id,
            uuid=str(file_record.uuid),
            filename=file_record.filename,
            original_filename=file_record.original_filename,
            file_size=file_record.file_size,
            file_type=file_record.file_type,
            mime_type=file_record.mime_type,
            checksum_md5=file_record.checksum_md5,
            checksum_sha256=file_record.checksum_sha256,
            upload_url=f"/files/{file_record.id}",
            created_at=file_record.created_at
        )
        
    except Exception as e:
        # Clean up file if database operation fails
        if os.path.exists(file_path):
            os.remove(file_path)
        logger.error(f"File upload failed: {e}")
        raise HTTPException(status_code=500, detail="File upload failed")

@app.post("/files/external-link", response_model=ExternalLinkResponse)
async def create_external_link(
    link_data: ExternalLinkCreate,
    db: Session = Depends(get_db)
):
    """
    Create a file record for an external download link (e.g., from Michigan API).
    This doesn't store the actual file, just the metadata and URL.
    """
    try:
        # Create database record with external URL in file_path
        file_record = FileRecord(
            filename=link_data.filename,
            original_filename=link_data.filename,
            file_path=link_data.external_url,  # Store external URL in file_path
            file_size=link_data.file_size,
            file_type=link_data.file_type,
            mime_type='application/octet-stream',  # Generic for external files
            checksum_sha256=link_data.file_hash or '',
            user_id=link_data.user_id,
            job_id=link_data.job_id,
            is_available=True,
            is_processed=True,
            processing_status='external',
            extra_metadata=f'{{"description": "{link_data.description or ""}", "external": true, "source": "michigan_api"}}'
        )

        db.add(file_record)
        db.commit()
        db.refresh(file_record)

        logger.info(f"External link created: {link_data.filename} for job {link_data.job_id}")

        return ExternalLinkResponse(
            id=file_record.id,
            uuid=str(file_record.uuid),
            filename=file_record.filename,
            file_size=file_record.file_size,
            file_type=file_record.file_type,
            external_url=link_data.external_url,
            job_id=link_data.job_id,
            user_id=link_data.user_id,
            created_at=file_record.created_at
        )

    except Exception as e:
        logger.error(f"External link creation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create external link: {str(e)}")

@app.get("/files/{file_id}", response_model=FileInfoResponse)
async def get_file_info(file_id: int, db: Session = Depends(get_db)):
    """Get file information by ID."""
    file_record = db.query(FileRecord).filter(FileRecord.id == file_id).first()
    
    if not file_record:
        raise HTTPException(status_code=404, detail="File not found")
    
    # Update accessed timestamp
    file_record.accessed_at = datetime.utcnow()
    db.commit()
    
    return FileInfoResponse(
        id=file_record.id,
        uuid=str(file_record.uuid),
        filename=file_record.filename,
        original_filename=file_record.original_filename,
        file_path=file_record.file_path,
        file_size=file_record.file_size,
        file_type=file_record.file_type,
        mime_type=file_record.mime_type,
        user_id=file_record.user_id,
        job_id=file_record.job_id,
        is_public=file_record.is_public,
        is_available=file_record.is_available,
        is_processed=file_record.is_processed,
        processing_status=file_record.processing_status,
        expires_at=file_record.expires_at,
        created_at=file_record.created_at,
        updated_at=file_record.updated_at,
        accessed_at=file_record.accessed_at
    )

@app.get("/files/{file_id}/download", response_model=FileDownloadResponse)
async def get_download_url(file_id: int, user_id: int = 123, db: Session = Depends(get_db)):
    """Get download URL for a file."""
    file_record = db.query(FileRecord).filter(FileRecord.id == file_id).first()
    
    if not file_record:
        raise HTTPException(status_code=404, detail="File not found")
    
    # Check access permissions
    if not file_record.is_public and file_record.user_id != user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    if not file_record.is_available:
        raise HTTPException(status_code=410, detail="File no longer available")
    
    # Check if file exists on disk
    if not os.path.exists(file_record.file_path):
        raise HTTPException(status_code=404, detail="File not found on storage")
    
    # Log access
    log_file_access(db, file_record.id, user_id, 'download')
    
    # Generate download URL (in production, this would be a signed URL)
    download_url = f"/files/{file_id}/stream"
    expires_at = datetime.utcnow() + timedelta(hours=1)
    
    return FileDownloadResponse(
        download_url=download_url,
        filename=file_record.original_filename,
        file_size=file_record.file_size,
        expires_at=expires_at
    )

@app.get("/files/{file_id}/stream")
async def stream_file(file_id: int, user_id: int = 123, db: Session = Depends(get_db)):
    """Stream file content for download."""
    file_record = db.query(FileRecord).filter(FileRecord.id == file_id).first()
    
    if not file_record:
        raise HTTPException(status_code=404, detail="File not found")
    
    # Check access permissions
    if not file_record.is_public and file_record.user_id != user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    if not file_record.is_available:
        raise HTTPException(status_code=410, detail="File no longer available")
    
    # Check if file exists on disk
    if not os.path.exists(file_record.file_path):
        raise HTTPException(status_code=404, detail="File not found on storage")
    
    # Log access
    log_file_access(db, file_record.id, user_id, 'download')
    
    # Return file response
    return FileResponse(
        path=file_record.file_path,
        filename=file_record.original_filename,
        media_type=file_record.mime_type or 'application/octet-stream'
    )

@app.get("/files", response_model=List[FileInfoResponse])
async def list_files(
    request: Request,
    file_type: Optional[str] = None,
    job_id: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """List files for a user with optional filtering."""
    # Get user_id from header set by API gateway
    user_id = int(request.headers.get("X-User-ID", 123))

    query = db.query(FileRecord).filter(FileRecord.user_id == user_id)
    
    if file_type:
        query = query.filter(FileRecord.file_type == file_type)
    if job_id:
        query = query.filter(FileRecord.job_id == job_id)
    
    files = query.order_by(FileRecord.created_at.desc()).offset(skip).limit(limit).all()
    
    return [
        FileInfoResponse(
            id=file_record.id,
            uuid=str(file_record.uuid),
            filename=file_record.filename,
            original_filename=file_record.original_filename,
            file_path=file_record.file_path,
            file_size=file_record.file_size,
            file_type=file_record.file_type,
            mime_type=file_record.mime_type,
            user_id=file_record.user_id,
            job_id=file_record.job_id,
            is_public=file_record.is_public,
            is_available=file_record.is_available,
            is_processed=file_record.is_processed,
            processing_status=file_record.processing_status,
            expires_at=file_record.expires_at,
            created_at=file_record.created_at,
            updated_at=file_record.updated_at,
            accessed_at=file_record.accessed_at
        )
        for file_record in files
    ]

@app.delete("/files/{file_id}")
async def delete_file(file_id: int, user_id: int = 123, db: Session = Depends(get_db)):
    """Delete a file."""
    file_record = db.query(FileRecord).filter(FileRecord.id == file_id).first()
    
    if not file_record:
        raise HTTPException(status_code=404, detail="File not found")
    
    # Check permissions
    if file_record.user_id != user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Delete file from disk
    if os.path.exists(file_record.file_path):
        os.remove(file_record.file_path)
    
    # Log access
    log_file_access(db, file_record.id, user_id, 'delete')
    
    # Delete database record
    db.delete(file_record)
    db.commit()
    
    logger.info(f"File deleted: {file_record.filename} (User: {user_id})")
    
    return {"message": "File deleted successfully"}

@app.get("/jobs/{job_id}/files", response_model=List[FileInfoResponse])
async def get_job_files(
    job_id: str,
    request: Request,
    db: Session = Depends(get_db)
):
    """Get all files associated with a job."""
    # Get user_id from header set by API gateway
    user_id = int(request.headers.get("X-User-ID", 123))

    files = db.query(FileRecord).filter(
        FileRecord.job_id == job_id,
        FileRecord.user_id == user_id
    ).order_by(FileRecord.created_at.desc()).all()
    
    return [
        FileInfoResponse(
            id=file_record.id,
            uuid=str(file_record.uuid),
            filename=file_record.filename,
            original_filename=file_record.original_filename,
            file_path=file_record.file_path,
            file_size=file_record.file_size,
            file_type=file_record.file_type,
            mime_type=file_record.mime_type,
            user_id=file_record.user_id,
            job_id=file_record.job_id,
            is_public=file_record.is_public,
            is_available=file_record.is_available,
            is_processed=file_record.is_processed,
            processing_status=file_record.processing_status,
            expires_at=file_record.expires_at,
            created_at=file_record.created_at,
            updated_at=file_record.updated_at,
            accessed_at=file_record.accessed_at
        )
        for file_record in files
    ]

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8004, reload=True)
