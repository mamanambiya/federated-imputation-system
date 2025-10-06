"""
User Management Service for Federated Genomic Imputation Platform
Handles authentication, authorization, user profiles, and permissions.
"""

import os
import logging
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any

from fastapi import FastAPI, HTTPException, Depends, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, Text, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
from sqlalchemy.dialects.postgresql import UUID
import jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
import uuid
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@postgres:5432/user_management_db')
JWT_SECRET = os.getenv('JWT_SECRET', 'your-secret-key-change-in-production')
JWT_ALGORITHM = 'HS256'
JWT_EXPIRATION_HOURS = 24

# Database setup
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Security
security = HTTPBearer()

# Database Models
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(UUID(as_uuid=True), default=uuid.uuid4, unique=True, index=True)
    username = Column(String(150), unique=True, index=True, nullable=False)
    email = Column(String(254), unique=True, index=True, nullable=False)
    first_name = Column(String(150), nullable=False)
    last_name = Column(String(150), nullable=False)
    hashed_password = Column(String(128), nullable=False)
    is_active = Column(Boolean, default=True)
    is_staff = Column(Boolean, default=False)
    is_superuser = Column(Boolean, default=False)
    date_joined = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
    
    # Relationships
    profile = relationship("UserProfile", back_populates="user", uselist=False)
    roles = relationship("UserRole", back_populates="user", foreign_keys="[UserRole.user_id]")
    audit_logs = relationship("AuditLog", back_populates="user")

class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    institution = Column(String(200), nullable=True)
    department = Column(String(200), nullable=True)
    position = Column(String(100), nullable=True)
    research_interests = Column(Text, nullable=True)
    phone_number = Column(String(20), nullable=True)
    country = Column(String(100), nullable=True)
    bio = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="profile")

class UserRole(Base):
    __tablename__ = "user_roles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    role = Column(String(50), nullable=False)  # admin, service_admin, researcher, service_user, viewer
    service_id = Column(Integer, nullable=True)  # For service-specific roles
    granted_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    granted_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True)
    
    # Relationships
    user = relationship("User", back_populates="roles", foreign_keys=[user_id])
    granted_by = relationship("User", foreign_keys=[granted_by_id])

class UserServiceCredential(Base):
    """
    Stores per-user credentials for external imputation services.
    Each user must configure their own API tokens for services they want to use.
    """
    __tablename__ = "user_service_credentials"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    service_id = Column(Integer, nullable=False, index=True)  # References service in service-registry

    # Credential information
    credential_type = Column(String(50), default='api_token')  # api_token, oauth2, basic_auth
    api_token = Column(Text, nullable=True)  # TODO: Should be encrypted in production
    oauth_token = Column(Text, nullable=True)
    oauth_refresh_token = Column(Text, nullable=True)
    username = Column(String(255), nullable=True)  # For basic auth
    password = Column(Text, nullable=True)  # For basic auth (encrypted)

    # Metadata
    label = Column(String(100), nullable=True)  # User-friendly label
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)  # Has the credential been tested?
    last_verified_at = Column(DateTime, nullable=True)
    last_used_at = Column(DateTime, nullable=True)
    verification_error = Column(Text, nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)

    # Unique constraint: one active credential per user per service
    from sqlalchemy import UniqueConstraint
    __table_args__ = (
        UniqueConstraint('user_id', 'service_id', name='uq_user_service_credential'),
    )

    # Relationships
    user = relationship("User", backref="service_credentials")

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action = Column(String(50), nullable=False)
    resource_type = Column(String(50), nullable=True)
    resource_id = Column(String(100), nullable=True)
    details = Column(Text, nullable=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(500), nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)

    # Relationships
    user = relationship("User", back_populates="audit_logs")

# Create tables
Base.metadata.create_all(bind=engine)

# FastAPI app
app = FastAPI(
    title="User Management Service",
    description="Authentication, authorization, and user management",
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
class UserCreate(BaseModel):
    username: str
    email: EmailStr
    first_name: str
    last_name: str
    password: str
    institution: Optional[str] = None
    department: Optional[str] = None

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    uuid: str
    username: str
    email: str
    first_name: str
    last_name: str
    is_active: bool
    is_staff: bool
    is_superuser: bool
    date_joined: datetime
    last_login: Optional[datetime]

class UserProfileResponse(BaseModel):
    institution: Optional[str]
    department: Optional[str]
    position: Optional[str]
    research_interests: Optional[str]
    phone_number: Optional[str]
    country: Optional[str]
    bio: Optional[str]

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int
    user: UserResponse

class RoleResponse(BaseModel):
    id: int
    role: str
    service_id: Optional[int]
    granted_at: datetime
    expires_at: Optional[datetime]
    is_active: bool

class ServiceCredentialCreate(BaseModel):
    service_id: int
    credential_type: str = 'api_token'
    api_token: Optional[str] = None
    oauth_token: Optional[str] = None
    username: Optional[str] = None
    password: Optional[str] = None
    label: Optional[str] = None

class ServiceCredentialUpdate(BaseModel):
    api_token: Optional[str] = None
    oauth_token: Optional[str] = None
    username: Optional[str] = None
    password: Optional[str] = None
    label: Optional[str] = None
    is_active: Optional[bool] = None

class ServiceCredentialResponse(BaseModel):
    id: int
    service_id: int
    credential_type: str
    label: Optional[str]
    is_active: bool
    is_verified: bool
    last_verified_at: Optional[datetime]
    last_used_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    # Note: Never return actual credentials in response
    has_api_token: bool = False
    has_oauth_token: bool = False
    has_basic_auth: bool = False

class ServiceCredentialVerifyResponse(BaseModel):
    credential_id: int
    service_id: int
    is_valid: bool
    message: str
    verified_at: datetime

# Utility functions
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(hours=JWT_EXPIRATION_HOURS)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALGORITHM)

def get_current_user_from_token(token: str, db: Session) -> User:
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id: int = payload.get("user_id")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    return get_current_user_from_token(credentials.credentials, db)

def log_user_action(
    db: Session,
    user_id: Optional[int],
    action: str,
    resource_type: Optional[str] = None,
    resource_id: Optional[str] = None,
    details: Optional[str] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None
):
    """Log user action for audit trail."""
    audit_log = AuditLog(
        user_id=user_id,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        details=details,
        ip_address=ip_address,
        user_agent=user_agent
    )
    db.add(audit_log)
    db.commit()

# API Endpoints
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "user-management", "timestamp": datetime.utcnow()}

@app.post("/auth/register", response_model=UserResponse)
async def register_user(
    user_data: UserCreate,
    request: Request,
    db: Session = Depends(get_db)
):
    """Register a new user."""
    
    # Check if user already exists
    if db.query(User).filter(User.username == user_data.username).first():
        raise HTTPException(status_code=400, detail="Username already registered")
    
    if db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create user
    hashed_password = get_password_hash(user_data.password)
    user = User(
        username=user_data.username,
        email=user_data.email,
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        hashed_password=hashed_password
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create user profile
    profile = UserProfile(
        user_id=user.id,
        institution=user_data.institution,
        department=user_data.department
    )
    db.add(profile)
    db.commit()
    
    # Log action
    log_user_action(
        db=db,
        user_id=user.id,
        action="user_registered",
        resource_type="user",
        resource_id=str(user.id),
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )
    
    logger.info(f"New user registered: {user.username}")
    
    return UserResponse(
        id=user.id,
        uuid=str(user.uuid),
        username=user.username,
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        is_active=user.is_active,
        is_staff=user.is_staff,
        is_superuser=user.is_superuser,
        date_joined=user.date_joined,
        last_login=user.last_login
    )

@app.post("/auth/login", response_model=TokenResponse)
async def login_user(
    login_data: UserLogin,
    request: Request,
    db: Session = Depends(get_db)
):
    """Authenticate user and return JWT token."""
    
    user = db.query(User).filter(User.username == login_data.username).first()
    
    if not user or not verify_password(login_data.password, user.hashed_password):
        log_user_action(
            db=db,
            user_id=None,
            action="login_failed",
            details=f"Failed login attempt for username: {login_data.username}",
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent")
        )
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    if not user.is_active:
        raise HTTPException(status_code=401, detail="Account is disabled")
    
    # Update last login
    user.last_login = datetime.utcnow()
    db.commit()
    
    # Get user roles
    roles = db.query(UserRole).filter(
        UserRole.user_id == user.id,
        UserRole.is_active == True
    ).all()
    
    # Create JWT token
    token_data = {
        "user_id": user.id,
        "username": user.username,
        "email": user.email,
        "roles": [role.role for role in roles]
    }
    access_token = create_access_token(token_data)
    
    # Log successful login
    log_user_action(
        db=db,
        user_id=user.id,
        action="login_success",
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )
    
    logger.info(f"User logged in: {user.username}")
    
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=JWT_EXPIRATION_HOURS * 3600,
        user=UserResponse(
            id=user.id,
            uuid=str(user.uuid),
            username=user.username,
            email=user.email,
            first_name=user.first_name,
            last_name=user.last_name,
            is_active=user.is_active,
            is_staff=user.is_staff,
            is_superuser=user.is_superuser,
            date_joined=user.date_joined,
            last_login=user.last_login
        )
    )

@app.get("/auth/user", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information."""
    return UserResponse(
        id=current_user.id,
        uuid=str(current_user.uuid),
        username=current_user.username,
        email=current_user.email,
        first_name=current_user.first_name,
        last_name=current_user.last_name,
        is_active=current_user.is_active,
        is_staff=current_user.is_staff,
        is_superuser=current_user.is_superuser,
        date_joined=current_user.date_joined,
        last_login=current_user.last_login
    )

@app.get("/users/{user_id}/roles", response_model=List[RoleResponse])
async def get_user_roles(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user roles."""

    # Check permissions (user can view their own roles, admins can view any)
    if current_user.id != user_id and not current_user.is_staff:
        raise HTTPException(status_code=403, detail="Permission denied")

    roles = db.query(UserRole).filter(UserRole.user_id == user_id).all()

    return [
        RoleResponse(
            id=role.id,
            role=role.role,
            service_id=role.service_id,
            granted_at=role.granted_at,
            expires_at=role.expires_at,
            is_active=role.is_active
        )
        for role in roles
    ]

# ============================================================================
# SERVICE CREDENTIAL MANAGEMENT ENDPOINTS
# ============================================================================

@app.post("/users/me/service-credentials", response_model=ServiceCredentialResponse, status_code=201)
async def create_service_credential(
    credential_data: ServiceCredentialCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create or update service credentials for the current user.
    Each user must configure their own credentials for external services.
    """

    # Check if credential already exists
    existing = db.query(UserServiceCredential).filter(
        UserServiceCredential.user_id == current_user.id,
        UserServiceCredential.service_id == credential_data.service_id
    ).first()

    if existing:
        # Update existing credential
        if credential_data.api_token:
            existing.api_token = credential_data.api_token
        if credential_data.oauth_token:
            existing.oauth_token = credential_data.oauth_token
        if credential_data.username:
            existing.username = credential_data.username
        if credential_data.password:
            existing.password = get_password_hash(credential_data.password)
        if credential_data.label:
            existing.label = credential_data.label

        existing.credential_type = credential_data.credential_type
        existing.is_verified = False  # Reset verification on update
        existing.updated_at = datetime.utcnow()

        db.commit()
        db.refresh(existing)
        credential = existing
    else:
        # Create new credential
        credential = UserServiceCredential(
            user_id=current_user.id,
            service_id=credential_data.service_id,
            credential_type=credential_data.credential_type,
            api_token=credential_data.api_token,
            oauth_token=credential_data.oauth_token,
            username=credential_data.username,
            password=get_password_hash(credential_data.password) if credential_data.password else None,
            label=credential_data.label
        )
        db.add(credential)
        db.commit()
        db.refresh(credential)

    # Log the action
    audit_log = AuditLog(
        user_id=current_user.id,
        action="create_service_credential" if not existing else "update_service_credential",
        resource_type="service_credential",
        resource_id=str(credential.id),
        details=f"Service ID: {credential_data.service_id}"
    )
    db.add(audit_log)
    db.commit()

    return ServiceCredentialResponse(
        id=credential.id,
        service_id=credential.service_id,
        credential_type=credential.credential_type,
        label=credential.label,
        is_active=credential.is_active,
        is_verified=credential.is_verified,
        last_verified_at=credential.last_verified_at,
        last_used_at=credential.last_used_at,
        created_at=credential.created_at,
        updated_at=credential.updated_at,
        has_api_token=bool(credential.api_token),
        has_oauth_token=bool(credential.oauth_token),
        has_basic_auth=bool(credential.username and credential.password)
    )

@app.get("/users/me/service-credentials", response_model=List[ServiceCredentialResponse])
async def list_service_credentials(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List all service credentials for the current user."""

    credentials = db.query(UserServiceCredential).filter(
        UserServiceCredential.user_id == current_user.id
    ).order_by(UserServiceCredential.created_at.desc()).all()

    return [
        ServiceCredentialResponse(
            id=cred.id,
            service_id=cred.service_id,
            credential_type=cred.credential_type,
            label=cred.label,
            is_active=cred.is_active,
            is_verified=cred.is_verified,
            last_verified_at=cred.last_verified_at,
            last_used_at=cred.last_used_at,
            created_at=cred.created_at,
            updated_at=cred.updated_at,
            has_api_token=bool(cred.api_token),
            has_oauth_token=bool(cred.oauth_token),
            has_basic_auth=bool(cred.username and cred.password)
        )
        for cred in credentials
    ]

@app.get("/users/me/service-credentials/{service_id}", response_model=ServiceCredentialResponse)
async def get_service_credential(
    service_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's credential for a specific service."""

    credential = db.query(UserServiceCredential).filter(
        UserServiceCredential.user_id == current_user.id,
        UserServiceCredential.service_id == service_id
    ).first()

    if not credential:
        raise HTTPException(
            status_code=404,
            detail=f"No credentials configured for service {service_id}"
        )

    return ServiceCredentialResponse(
        id=credential.id,
        service_id=credential.service_id,
        credential_type=credential.credential_type,
        label=credential.label,
        is_active=credential.is_active,
        is_verified=credential.is_verified,
        last_verified_at=credential.last_verified_at,
        last_used_at=credential.last_used_at,
        created_at=credential.created_at,
        updated_at=credential.updated_at,
        has_api_token=bool(credential.api_token),
        has_oauth_token=bool(credential.oauth_token),
        has_basic_auth=bool(credential.username and credential.password)
    )

@app.delete("/users/me/service-credentials/{service_id}", status_code=204)
async def delete_service_credential(
    service_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete user's credential for a specific service."""

    credential = db.query(UserServiceCredential).filter(
        UserServiceCredential.user_id == current_user.id,
        UserServiceCredential.service_id == service_id
    ).first()

    if not credential:
        raise HTTPException(
            status_code=404,
            detail=f"No credentials configured for service {service_id}"
        )

    # Log the deletion
    audit_log = AuditLog(
        user_id=current_user.id,
        action="delete_service_credential",
        resource_type="service_credential",
        resource_id=str(credential.id),
        details=f"Service ID: {service_id}"
    )
    db.add(audit_log)

    db.delete(credential)
    db.commit()

# Internal endpoint for job processor to fetch user credentials
@app.get("/internal/users/{user_id}/service-credentials/{service_id}")
async def get_user_service_credential_internal(
    user_id: int,
    service_id: int,
    db: Session = Depends(get_db)
):
    """
    Internal endpoint for microservices to fetch user's service credentials.
    Used by job-processor when submitting jobs to external services.

    NOTE: This endpoint should be protected by internal network/API gateway.
    """

    credential = db.query(UserServiceCredential).filter(
        UserServiceCredential.user_id == user_id,
        UserServiceCredential.service_id == service_id,
        UserServiceCredential.is_active == True
    ).first()

    if not credential:
        return {
            "has_credential": False,
            "message": f"User {user_id} has not configured credentials for service {service_id}"
        }

    # Update last used timestamp
    credential.last_used_at = datetime.utcnow()
    db.commit()

    # Return actual credentials (only for internal use)
    return {
        "has_credential": True,
        "credential_type": credential.credential_type,
        "api_token": credential.api_token,
        "oauth_token": credential.oauth_token,
        "username": credential.username,
        "password": credential.password,  # Already hashed
        "is_verified": credential.is_verified,
        "last_verified_at": credential.last_verified_at
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
