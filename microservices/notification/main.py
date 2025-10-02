"""
Notification Service for Federated Genomic Imputation Platform
Handles real-time notifications, email alerts, and event-driven messaging.
"""

import os
import logging
import asyncio
import json
import smtplib
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any, Set
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

import redis
from fastapi import FastAPI, HTTPException, Depends, WebSocket, WebSocketDisconnect, BackgroundTasks
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, Text, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel, EmailStr
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@postgres:5432/notification_db')
REDIS_URL = os.getenv('REDIS_URL', 'redis://redis:6379')
SMTP_HOST = os.getenv('SMTP_HOST', 'localhost')
SMTP_PORT = int(os.getenv('SMTP_PORT', '587'))
SMTP_USER = os.getenv('SMTP_USER', '')
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD', '')
SMTP_FROM_EMAIL = os.getenv('SMTP_FROM_EMAIL', 'noreply@federated-imputation.org')

# Database setup
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Redis setup
redis_client = redis.Redis.from_url(REDIS_URL, decode_responses=True)

# Database Models
class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    type = Column(String(50), nullable=False)  # job_status_update, system_alert, etc.
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    data = Column(JSON, default=dict)  # Additional structured data
    
    # Delivery channels
    channels = Column(JSON, default=list)  # ['web', 'email', 'sms']
    
    # Status
    is_read = Column(Boolean, default=False)
    is_sent = Column(Boolean, default=False)
    sent_at = Column(DateTime)
    read_at = Column(DateTime)
    
    # Priority and scheduling
    priority = Column(String(20), default='normal')  # low, normal, high, urgent
    scheduled_for = Column(DateTime)  # For scheduled notifications
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    expires_at = Column(DateTime)

class NotificationPreference(Base):
    __tablename__ = "notification_preferences"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, unique=True, index=True)
    
    # Channel preferences
    email_enabled = Column(Boolean, default=True)
    web_enabled = Column(Boolean, default=True)
    sms_enabled = Column(Boolean, default=False)
    
    # Notification type preferences
    job_status_updates = Column(Boolean, default=True)
    system_alerts = Column(Boolean, default=True)
    security_alerts = Column(Boolean, default=True)
    maintenance_notices = Column(Boolean, default=True)
    
    # Frequency settings
    digest_frequency = Column(String(20), default='immediate')  # immediate, hourly, daily, weekly
    quiet_hours_start = Column(String(5))  # HH:MM format
    quiet_hours_end = Column(String(5))  # HH:MM format
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class EmailTemplate(Base):
    __tablename__ = "email_templates"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, unique=True)
    subject = Column(String(200), nullable=False)
    html_content = Column(Text, nullable=False)
    text_content = Column(Text)
    
    # Template variables
    variables = Column(JSON, default=list)  # List of variable names used in template
    
    # Metadata
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Create tables
Base.metadata.create_all(bind=engine)

# FastAPI app
app = FastAPI(
    title="Notification Service",
    description="Real-time notifications and messaging",
    version="1.0.0"
)

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, Set[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        self.active_connections[user_id].add(websocket)
        logger.info(f"WebSocket connected for user {user_id}")
    
    def disconnect(self, websocket: WebSocket, user_id: int):
        if user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        logger.info(f"WebSocket disconnected for user {user_id}")
    
    async def send_personal_message(self, message: dict, user_id: int):
        if user_id in self.active_connections:
            disconnected = set()
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_text(json.dumps(message))
                except:
                    disconnected.add(connection)
            
            # Remove disconnected connections
            for connection in disconnected:
                self.active_connections[user_id].discard(connection)
    
    async def broadcast(self, message: dict):
        for user_id, connections in self.active_connections.items():
            disconnected = set()
            for connection in connections:
                try:
                    await connection.send_text(json.dumps(message))
                except:
                    disconnected.add(connection)
            
            # Remove disconnected connections
            for connection in disconnected:
                connections.discard(connection)

manager = ConnectionManager()

# Dependency to get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Pydantic models
class NotificationCreate(BaseModel):
    user_id: int
    type: str
    title: str
    message: str
    data: Optional[Dict[str, Any]] = {}
    channels: List[str] = ['web']
    priority: str = 'normal'
    scheduled_for: Optional[datetime] = None
    expires_at: Optional[datetime] = None

class NotificationResponse(BaseModel):
    id: int
    user_id: int
    type: str
    title: str
    message: str
    data: Dict[str, Any]
    channels: List[str]
    is_read: bool
    is_sent: bool
    sent_at: Optional[datetime]
    read_at: Optional[datetime]
    priority: str
    scheduled_for: Optional[datetime]
    created_at: datetime
    expires_at: Optional[datetime]

class NotificationPreferenceUpdate(BaseModel):
    email_enabled: Optional[bool] = None
    web_enabled: Optional[bool] = None
    sms_enabled: Optional[bool] = None
    job_status_updates: Optional[bool] = None
    system_alerts: Optional[bool] = None
    security_alerts: Optional[bool] = None
    maintenance_notices: Optional[bool] = None
    digest_frequency: Optional[str] = None
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None

class NotificationPreferenceResponse(BaseModel):
    id: int
    user_id: int
    email_enabled: bool
    web_enabled: bool
    sms_enabled: bool
    job_status_updates: bool
    system_alerts: bool
    security_alerts: bool
    maintenance_notices: bool
    digest_frequency: str
    quiet_hours_start: Optional[str]
    quiet_hours_end: Optional[str]
    created_at: datetime
    updated_at: datetime

# Email service
class EmailService:
    def __init__(self):
        self.smtp_host = SMTP_HOST
        self.smtp_port = SMTP_PORT
        self.smtp_user = SMTP_USER
        self.smtp_password = SMTP_PASSWORD
        self.from_email = SMTP_FROM_EMAIL
    
    async def send_email(self, to_email: str, subject: str, html_content: str, text_content: str = None):
        """Send email notification."""
        if not self.smtp_host or not self.smtp_user:
            logger.warning("SMTP not configured, skipping email send")
            return False
        
        try:
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = self.from_email
            msg['To'] = to_email
            
            # Add text content
            if text_content:
                text_part = MIMEText(text_content, 'plain')
                msg.attach(text_part)
            
            # Add HTML content
            html_part = MIMEText(html_content, 'html')
            msg.attach(html_part)
            
            # Send email
            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_password)
                server.send_message(msg)
            
            logger.info(f"Email sent to {to_email}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send email to {to_email}: {e}")
            return False

email_service = EmailService()

# Notification processing
async def process_notification(notification: Notification, db: Session):
    """Process and deliver a notification through specified channels."""
    
    # Check user preferences
    preferences = db.query(NotificationPreference).filter(
        NotificationPreference.user_id == notification.user_id
    ).first()
    
    if not preferences:
        # Create default preferences
        preferences = NotificationPreference(user_id=notification.user_id)
        db.add(preferences)
        db.commit()
    
    # Check if notification type is enabled
    type_enabled = True
    if notification.type == 'job_status_update' and not preferences.job_status_updates:
        type_enabled = False
    elif notification.type == 'system_alert' and not preferences.system_alerts:
        type_enabled = False
    elif notification.type == 'security_alert' and not preferences.security_alerts:
        type_enabled = False
    elif notification.type == 'maintenance_notice' and not preferences.maintenance_notices:
        type_enabled = False
    
    if not type_enabled:
        logger.info(f"Notification type {notification.type} disabled for user {notification.user_id}")
        return
    
    # Process each channel
    success = False
    
    for channel in notification.channels:
        if channel == 'web' and preferences.web_enabled:
            # Send WebSocket notification
            message = {
                'type': 'notification',
                'data': {
                    'id': notification.id,
                    'type': notification.type,
                    'title': notification.title,
                    'message': notification.message,
                    'data': notification.data,
                    'priority': notification.priority,
                    'timestamp': notification.created_at.isoformat(),
                    'read': notification.is_read
                }
            }
            await manager.send_personal_message(message, notification.user_id)
            success = True
            
        elif channel == 'email' and preferences.email_enabled:
            # Send email notification
            # In a real implementation, you'd get user email from user service
            user_email = f"user{notification.user_id}@example.com"  # Placeholder
            
            html_content = f"""
            <html>
                <body>
                    <h2>{notification.title}</h2>
                    <p>{notification.message}</p>
                    <hr>
                    <p><small>Federated Genomic Imputation Platform</small></p>
                </body>
            </html>
            """
            
            email_sent = await email_service.send_email(
                to_email=user_email,
                subject=notification.title,
                html_content=html_content,
                text_content=notification.message
            )
            
            if email_sent:
                success = True
    
    # Update notification status
    if success:
        notification.is_sent = True
        notification.sent_at = datetime.utcnow()
        db.commit()

# API Endpoints
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "notification", "timestamp": datetime.utcnow()}

@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int):
    """WebSocket endpoint for real-time notifications."""
    await manager.connect(websocket, user_id)
    try:
        while True:
            # Keep connection alive and handle incoming messages
            data = await websocket.receive_text()
            # Handle client messages if needed (e.g., mark as read)
            try:
                message = json.loads(data)
                if message.get('action') == 'mark_read':
                    notification_id = message.get('notification_id')
                    if notification_id:
                        # Mark notification as read
                        db = SessionLocal()
                        notification = db.query(Notification).filter(
                            Notification.id == notification_id,
                            Notification.user_id == user_id
                        ).first()
                        if notification:
                            notification.is_read = True
                            notification.read_at = datetime.utcnow()
                            db.commit()
                        db.close()
            except json.JSONDecodeError:
                pass
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)

@app.post("/notifications", response_model=NotificationResponse)
async def create_notification(
    notification_data: NotificationCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Create and send a new notification."""
    
    notification = Notification(
        user_id=notification_data.user_id,
        type=notification_data.type,
        title=notification_data.title,
        message=notification_data.message,
        data=notification_data.data,
        channels=notification_data.channels,
        priority=notification_data.priority,
        scheduled_for=notification_data.scheduled_for,
        expires_at=notification_data.expires_at
    )
    
    db.add(notification)
    db.commit()
    db.refresh(notification)
    
    # Process notification in background
    if not notification_data.scheduled_for or notification_data.scheduled_for <= datetime.utcnow():
        background_tasks.add_task(process_notification, notification, db)
    
    logger.info(f"Notification created: {notification.id} for user {notification.user_id}")
    
    return NotificationResponse(
        id=notification.id,
        user_id=notification.user_id,
        type=notification.type,
        title=notification.title,
        message=notification.message,
        data=notification.data,
        channels=notification.channels,
        is_read=notification.is_read,
        is_sent=notification.is_sent,
        sent_at=notification.sent_at,
        read_at=notification.read_at,
        priority=notification.priority,
        scheduled_for=notification.scheduled_for,
        created_at=notification.created_at,
        expires_at=notification.expires_at
    )

@app.get("/notifications", response_model=List[NotificationResponse])
async def list_notifications(
    user_id: int = 123,  # This would come from JWT token
    is_read: Optional[bool] = None,
    notification_type: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db)
):
    """List notifications for a user."""
    query = db.query(Notification).filter(Notification.user_id == user_id)
    
    if is_read is not None:
        query = query.filter(Notification.is_read == is_read)
    if notification_type:
        query = query.filter(Notification.type == notification_type)
    
    # Filter out expired notifications
    query = query.filter(
        (Notification.expires_at.is_(None)) | 
        (Notification.expires_at > datetime.utcnow())
    )
    
    notifications = query.order_by(Notification.created_at.desc()).offset(skip).limit(limit).all()
    
    return [
        NotificationResponse(
            id=notification.id,
            user_id=notification.user_id,
            type=notification.type,
            title=notification.title,
            message=notification.message,
            data=notification.data,
            channels=notification.channels,
            is_read=notification.is_read,
            is_sent=notification.is_sent,
            sent_at=notification.sent_at,
            read_at=notification.read_at,
            priority=notification.priority,
            scheduled_for=notification.scheduled_for,
            created_at=notification.created_at,
            expires_at=notification.expires_at
        )
        for notification in notifications
    ]

@app.patch("/notifications/{notification_id}/read")
async def mark_notification_read(
    notification_id: int,
    user_id: int = 123,  # This would come from JWT token
    db: Session = Depends(get_db)
):
    """Mark a notification as read."""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == user_id
    ).first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    notification.is_read = True
    notification.read_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Notification marked as read"}

@app.post("/notifications/mark-all-read")
async def mark_all_notifications_read(
    user_id: int = 123,  # This would come from JWT token
    db: Session = Depends(get_db)
):
    """Mark all notifications as read for a user."""
    notifications = db.query(Notification).filter(
        Notification.user_id == user_id,
        Notification.is_read == False
    ).all()
    
    for notification in notifications:
        notification.is_read = True
        notification.read_at = datetime.utcnow()
    
    db.commit()
    
    return {"message": f"Marked {len(notifications)} notifications as read"}

@app.get("/notifications/preferences", response_model=NotificationPreferenceResponse)
async def get_notification_preferences(
    user_id: int = 123,  # This would come from JWT token
    db: Session = Depends(get_db)
):
    """Get user notification preferences."""
    preferences = db.query(NotificationPreference).filter(
        NotificationPreference.user_id == user_id
    ).first()
    
    if not preferences:
        # Create default preferences
        preferences = NotificationPreference(user_id=user_id)
        db.add(preferences)
        db.commit()
        db.refresh(preferences)
    
    return NotificationPreferenceResponse(
        id=preferences.id,
        user_id=preferences.user_id,
        email_enabled=preferences.email_enabled,
        web_enabled=preferences.web_enabled,
        sms_enabled=preferences.sms_enabled,
        job_status_updates=preferences.job_status_updates,
        system_alerts=preferences.system_alerts,
        security_alerts=preferences.security_alerts,
        maintenance_notices=preferences.maintenance_notices,
        digest_frequency=preferences.digest_frequency,
        quiet_hours_start=preferences.quiet_hours_start,
        quiet_hours_end=preferences.quiet_hours_end,
        created_at=preferences.created_at,
        updated_at=preferences.updated_at
    )

@app.patch("/notifications/preferences", response_model=NotificationPreferenceResponse)
async def update_notification_preferences(
    preference_update: NotificationPreferenceUpdate,
    user_id: int = 123,  # This would come from JWT token
    db: Session = Depends(get_db)
):
    """Update user notification preferences."""
    preferences = db.query(NotificationPreference).filter(
        NotificationPreference.user_id == user_id
    ).first()
    
    if not preferences:
        preferences = NotificationPreference(user_id=user_id)
        db.add(preferences)
    
    # Update fields
    update_data = preference_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(preferences, field, value)
    
    preferences.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(preferences)
    
    return NotificationPreferenceResponse(
        id=preferences.id,
        user_id=preferences.user_id,
        email_enabled=preferences.email_enabled,
        web_enabled=preferences.web_enabled,
        sms_enabled=preferences.sms_enabled,
        job_status_updates=preferences.job_status_updates,
        system_alerts=preferences.system_alerts,
        security_alerts=preferences.security_alerts,
        maintenance_notices=preferences.maintenance_notices,
        digest_frequency=preferences.digest_frequency,
        quiet_hours_start=preferences.quiet_hours_start,
        quiet_hours_end=preferences.quiet_hours_end,
        created_at=preferences.created_at,
        updated_at=preferences.updated_at
    )

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8005, reload=True)
