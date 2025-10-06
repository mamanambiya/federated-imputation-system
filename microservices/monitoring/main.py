"""
Monitoring Service for Federated Genomic Imputation Platform
Provides health checks, metrics collection, and system monitoring.
"""

import os
import logging
import asyncio
import psutil
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any

import httpx
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, Float, Text, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@postgres:5432/monitoring_db')
SERVICES = {
    'api-gateway': os.getenv('API_GATEWAY_URL', 'http://api-gateway:8000'),
    'user-service': os.getenv('USER_SERVICE_URL', 'http://user-service:8001'),
    'service-registry': os.getenv('SERVICE_REGISTRY_URL', 'http://service-registry:8002'),
    'job-processor': os.getenv('JOB_PROCESSOR_URL', 'http://job-processor:8003'),
    'file-manager': os.getenv('FILE_MANAGER_URL', 'http://file-manager:8004'),
    'notification': os.getenv('NOTIFICATION_URL', 'http://notification:8005'),
}

# Database setup
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Models
class ServiceHealth(Base):
    __tablename__ = "service_health"
    
    id = Column(Integer, primary_key=True, index=True)
    service_name = Column(String(100), nullable=False, index=True)
    status = Column(String(20), nullable=False)  # healthy, unhealthy, unknown
    response_time_ms = Column(Float)
    error_message = Column(Text)
    
    # Health check details
    endpoint_url = Column(String(500))
    http_status_code = Column(Integer)
    
    # Timestamp
    checked_at = Column(DateTime, default=datetime.utcnow, index=True)

class SystemMetrics(Base):
    __tablename__ = "system_metrics"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # CPU metrics
    cpu_usage_percent = Column(Float)
    cpu_count = Column(Integer)
    load_average_1m = Column(Float)
    load_average_5m = Column(Float)
    load_average_15m = Column(Float)
    
    # Memory metrics
    memory_total_gb = Column(Float)
    memory_used_gb = Column(Float)
    memory_available_gb = Column(Float)
    memory_usage_percent = Column(Float)
    
    # Disk metrics
    disk_total_gb = Column(Float)
    disk_used_gb = Column(Float)
    disk_free_gb = Column(Float)
    disk_usage_percent = Column(Float)
    
    # Network metrics
    network_bytes_sent = Column(Float)
    network_bytes_recv = Column(Float)
    network_packets_sent = Column(Float)
    network_packets_recv = Column(Float)
    
    # Timestamp
    collected_at = Column(DateTime, default=datetime.utcnow, index=True)

class Alert(Base):
    __tablename__ = "alerts"
    
    id = Column(Integer, primary_key=True, index=True)
    alert_type = Column(String(50), nullable=False)  # service_down, high_cpu, high_memory, etc.
    severity = Column(String(20), nullable=False)  # low, medium, high, critical
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    
    # Alert source
    service_name = Column(String(100))
    metric_name = Column(String(100))
    metric_value = Column(Float)
    threshold_value = Column(Float)
    
    # Alert status
    is_active = Column(Boolean, default=True)
    is_acknowledged = Column(Boolean, default=False)
    acknowledged_by = Column(String(100))
    acknowledged_at = Column(DateTime)
    resolved_at = Column(DateTime)
    
    # Additional data
    alert_metadata = Column(JSON, default=dict)
    
    # Timestamps
    triggered_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Create tables
Base.metadata.create_all(bind=engine)

# FastAPI app
app = FastAPI(
    title="Monitoring Service",
    description="System monitoring and health checks",
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
class ServiceHealthResponse(BaseModel):
    service_name: str
    status: str
    response_time_ms: Optional[float]
    error_message: Optional[str]
    endpoint_url: str
    http_status_code: Optional[int]
    checked_at: datetime

class SystemMetricsResponse(BaseModel):
    cpu_usage_percent: float
    cpu_count: int
    load_average_1m: Optional[float]
    load_average_5m: Optional[float]
    load_average_15m: Optional[float]
    memory_total_gb: float
    memory_used_gb: float
    memory_available_gb: float
    memory_usage_percent: float
    disk_total_gb: float
    disk_used_gb: float
    disk_free_gb: float
    disk_usage_percent: float
    network_bytes_sent: float
    network_bytes_recv: float
    network_packets_sent: float
    network_packets_recv: float
    collected_at: datetime

class AlertResponse(BaseModel):
    id: int
    alert_type: str
    severity: str
    title: str
    description: str
    service_name: Optional[str]
    metric_name: Optional[str]
    metric_value: Optional[float]
    threshold_value: Optional[float]
    is_active: bool
    is_acknowledged: bool
    acknowledged_by: Optional[str]
    acknowledged_at: Optional[datetime]
    resolved_at: Optional[datetime]
    alert_metadata: Dict[str, Any]
    triggered_at: datetime
    updated_at: datetime

class OverallHealthResponse(BaseModel):
    overall_status: str
    services: List[ServiceHealthResponse]
    system_metrics: SystemMetricsResponse
    active_alerts: List[AlertResponse]
    last_updated: datetime

# Health checking service
class HealthChecker:
    def __init__(self):
        self.client = httpx.AsyncClient(timeout=10.0)
    
    async def check_service_health(self, service_name: str, service_url: str) -> Dict[str, Any]:
        """Check health of a single service."""
        health_endpoint = f"{service_url}/health"
        start_time = datetime.utcnow()
        
        try:
            response = await self.client.get(health_endpoint)
            end_time = datetime.utcnow()
            response_time = (end_time - start_time).total_seconds() * 1000
            
            if response.status_code == 200:
                return {
                    'service_name': service_name,
                    'status': 'healthy',
                    'response_time_ms': response_time,
                    'endpoint_url': health_endpoint,
                    'http_status_code': response.status_code,
                    'error_message': None
                }
            else:
                return {
                    'service_name': service_name,
                    'status': 'unhealthy',
                    'response_time_ms': response_time,
                    'endpoint_url': health_endpoint,
                    'http_status_code': response.status_code,
                    'error_message': f"HTTP {response.status_code}"
                }
                
        except Exception as e:
            end_time = datetime.utcnow()
            response_time = (end_time - start_time).total_seconds() * 1000
            
            return {
                'service_name': service_name,
                'status': 'unhealthy',
                'response_time_ms': response_time,
                'endpoint_url': health_endpoint,
                'http_status_code': None,
                'error_message': str(e)
            }
    
    async def check_all_services(self) -> List[Dict[str, Any]]:
        """Check health of all services."""
        tasks = []
        for service_name, service_url in SERVICES.items():
            task = self.check_service_health(service_name, service_url)
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Handle any exceptions
        health_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                service_name = list(SERVICES.keys())[i]
                health_results.append({
                    'service_name': service_name,
                    'status': 'unknown',
                    'response_time_ms': None,
                    'endpoint_url': f"{SERVICES[service_name]}/health",
                    'http_status_code': None,
                    'error_message': str(result)
                })
            else:
                health_results.append(result)
        
        return health_results

health_checker = HealthChecker()

# System metrics collection
def collect_system_metrics() -> Dict[str, Any]:
    """Collect system metrics using psutil."""
    try:
        # CPU metrics
        cpu_percent = psutil.cpu_percent(interval=1)
        cpu_count = psutil.cpu_count()
        
        # Load average (Unix only)
        try:
            load_avg = os.getloadavg()
            load_1m, load_5m, load_15m = load_avg
        except (AttributeError, OSError):
            load_1m = load_5m = load_15m = None
        
        # Memory metrics
        memory = psutil.virtual_memory()
        memory_total_gb = memory.total / (1024**3)
        memory_used_gb = memory.used / (1024**3)
        memory_available_gb = memory.available / (1024**3)
        memory_percent = memory.percent
        
        # Disk metrics
        disk = psutil.disk_usage('/')
        disk_total_gb = disk.total / (1024**3)
        disk_used_gb = disk.used / (1024**3)
        disk_free_gb = disk.free / (1024**3)
        disk_percent = (disk.used / disk.total) * 100
        
        # Network metrics
        network = psutil.net_io_counters()
        
        return {
            'cpu_usage_percent': cpu_percent,
            'cpu_count': cpu_count,
            'load_average_1m': load_1m,
            'load_average_5m': load_5m,
            'load_average_15m': load_15m,
            'memory_total_gb': memory_total_gb,
            'memory_used_gb': memory_used_gb,
            'memory_available_gb': memory_available_gb,
            'memory_usage_percent': memory_percent,
            'disk_total_gb': disk_total_gb,
            'disk_used_gb': disk_used_gb,
            'disk_free_gb': disk_free_gb,
            'disk_usage_percent': disk_percent,
            'network_bytes_sent': float(network.bytes_sent),
            'network_bytes_recv': float(network.bytes_recv),
            'network_packets_sent': float(network.packets_sent),
            'network_packets_recv': float(network.packets_recv)
        }
    except Exception as e:
        logger.error(f"Failed to collect system metrics: {e}")
        return {}

# Alert management
def check_and_create_alerts(db: Session, health_results: List[Dict], metrics: Dict[str, Any]):
    """Check conditions and create alerts if necessary."""
    current_time = datetime.utcnow()
    
    # Check service health alerts
    for health in health_results:
        if health['status'] == 'unhealthy':
            # Check if alert already exists
            existing_alert = db.query(Alert).filter(
                Alert.alert_type == 'service_down',
                Alert.service_name == health['service_name'],
                Alert.is_active == True
            ).first()
            
            if not existing_alert:
                alert = Alert(
                    alert_type='service_down',
                    severity='high',
                    title=f"Service {health['service_name']} is down",
                    description=f"Service {health['service_name']} failed health check: {health.get('error_message', 'Unknown error')}",
                    service_name=health['service_name'],
                    metadata={'health_check_result': health}
                )
                db.add(alert)
    
    # Check system metrics alerts
    if metrics:
        # High CPU usage
        if metrics.get('cpu_usage_percent', 0) > 80:
            existing_alert = db.query(Alert).filter(
                Alert.alert_type == 'high_cpu',
                Alert.is_active == True
            ).first()
            
            if not existing_alert:
                alert = Alert(
                    alert_type='high_cpu',
                    severity='medium',
                    title='High CPU Usage',
                    description=f"CPU usage is {metrics['cpu_usage_percent']:.1f}%",
                    metric_name='cpu_usage_percent',
                    metric_value=metrics['cpu_usage_percent'],
                    threshold_value=80.0
                )
                db.add(alert)
        
        # High memory usage
        if metrics.get('memory_usage_percent', 0) > 85:
            existing_alert = db.query(Alert).filter(
                Alert.alert_type == 'high_memory',
                Alert.is_active == True
            ).first()
            
            if not existing_alert:
                alert = Alert(
                    alert_type='high_memory',
                    severity='medium',
                    title='High Memory Usage',
                    description=f"Memory usage is {metrics['memory_usage_percent']:.1f}%",
                    metric_name='memory_usage_percent',
                    metric_value=metrics['memory_usage_percent'],
                    threshold_value=85.0
                )
                db.add(alert)
        
        # High disk usage
        if metrics.get('disk_usage_percent', 0) > 90:
            existing_alert = db.query(Alert).filter(
                Alert.alert_type == 'high_disk',
                Alert.is_active == True
            ).first()
            
            if not existing_alert:
                alert = Alert(
                    alert_type='high_disk',
                    severity='high',
                    title='High Disk Usage',
                    description=f"Disk usage is {metrics['disk_usage_percent']:.1f}%",
                    metric_name='disk_usage_percent',
                    metric_value=metrics['disk_usage_percent'],
                    threshold_value=90.0
                )
                db.add(alert)
    
    db.commit()

# Background monitoring task
async def monitoring_task():
    """Background task for continuous monitoring."""
    while True:
        try:
            db = SessionLocal()
            
            # Check service health
            health_results = await health_checker.check_all_services()
            
            # Store health results
            for health in health_results:
                health_record = ServiceHealth(**health)
                db.add(health_record)
            
            # Collect system metrics
            metrics = collect_system_metrics()
            
            if metrics:
                metrics_record = SystemMetrics(**metrics)
                db.add(metrics_record)
            
            # Check for alerts
            check_and_create_alerts(db, health_results, metrics)
            
            db.commit()
            db.close()
            
            logger.info("Monitoring cycle completed")
            
        except Exception as e:
            logger.error(f"Monitoring task error: {e}")
        
        # Wait 30 seconds before next check
        await asyncio.sleep(30)

# Start monitoring task
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(monitoring_task())

# API Endpoints
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "monitoring", "timestamp": datetime.utcnow()}

@app.get("/health/overall", response_model=OverallHealthResponse)
async def get_overall_health(db: Session = Depends(get_db)):
    """Get overall system health status."""
    
    # Get latest health checks for each service
    latest_health = []
    for service_name in SERVICES.keys():
        health_record = db.query(ServiceHealth).filter(
            ServiceHealth.service_name == service_name
        ).order_by(ServiceHealth.checked_at.desc()).first()
        
        if health_record:
            latest_health.append(ServiceHealthResponse(
                service_name=health_record.service_name,
                status=health_record.status,
                response_time_ms=health_record.response_time_ms,
                error_message=health_record.error_message,
                endpoint_url=health_record.endpoint_url,
                http_status_code=health_record.http_status_code,
                checked_at=health_record.checked_at
            ))
    
    # Get latest system metrics
    metrics_record = db.query(SystemMetrics).order_by(SystemMetrics.collected_at.desc()).first()
    
    if metrics_record:
        system_metrics = SystemMetricsResponse(
            cpu_usage_percent=metrics_record.cpu_usage_percent,
            cpu_count=metrics_record.cpu_count,
            load_average_1m=metrics_record.load_average_1m,
            load_average_5m=metrics_record.load_average_5m,
            load_average_15m=metrics_record.load_average_15m,
            memory_total_gb=metrics_record.memory_total_gb,
            memory_used_gb=metrics_record.memory_used_gb,
            memory_available_gb=metrics_record.memory_available_gb,
            memory_usage_percent=metrics_record.memory_usage_percent,
            disk_total_gb=metrics_record.disk_total_gb,
            disk_used_gb=metrics_record.disk_used_gb,
            disk_free_gb=metrics_record.disk_free_gb,
            disk_usage_percent=metrics_record.disk_usage_percent,
            network_bytes_sent=metrics_record.network_bytes_sent,
            network_bytes_recv=metrics_record.network_bytes_recv,
            network_packets_sent=metrics_record.network_packets_sent,
            network_packets_recv=metrics_record.network_packets_recv,
            collected_at=metrics_record.collected_at
        )
    else:
        # Return empty metrics if none available
        system_metrics = SystemMetricsResponse(
            cpu_usage_percent=0.0,
            cpu_count=1,
            load_average_1m=None,
            load_average_5m=None,
            load_average_15m=None,
            memory_total_gb=0.0,
            memory_used_gb=0.0,
            memory_available_gb=0.0,
            memory_usage_percent=0.0,
            disk_total_gb=0.0,
            disk_used_gb=0.0,
            disk_free_gb=0.0,
            disk_usage_percent=0.0,
            network_bytes_sent=0.0,
            network_bytes_recv=0.0,
            network_packets_sent=0.0,
            network_packets_recv=0.0,
            collected_at=datetime.utcnow()
        )
    
    # Get active alerts
    active_alerts = db.query(Alert).filter(Alert.is_active == True).order_by(Alert.triggered_at.desc()).all()
    
    alert_responses = [
        AlertResponse(
            id=alert.id,
            alert_type=alert.alert_type,
            severity=alert.severity,
            title=alert.title,
            description=alert.description,
            service_name=alert.service_name,
            metric_name=alert.metric_name,
            metric_value=alert.metric_value,
            threshold_value=alert.threshold_value,
            is_active=alert.is_active,
            is_acknowledged=alert.is_acknowledged,
            acknowledged_by=alert.acknowledged_by,
            acknowledged_at=alert.acknowledged_at,
            resolved_at=alert.resolved_at,
            alert_metadata=alert.alert_metadata,
            triggered_at=alert.triggered_at,
            updated_at=alert.updated_at
        )
        for alert in active_alerts
    ]
    
    # Determine overall status
    unhealthy_services = [h for h in latest_health if h.status != 'healthy']
    critical_alerts = [a for a in alert_responses if a.severity == 'critical']
    
    if critical_alerts or len(unhealthy_services) > len(latest_health) // 2:
        overall_status = 'critical'
    elif unhealthy_services or alert_responses:
        overall_status = 'degraded'
    else:
        overall_status = 'healthy'
    
    return OverallHealthResponse(
        overall_status=overall_status,
        services=latest_health,
        system_metrics=system_metrics,
        active_alerts=alert_responses,
        last_updated=datetime.utcnow()
    )

@app.get("/dashboard/stats/")
@app.get("/dashboard/stats")
async def get_dashboard_stats(db: Session = Depends(get_db)):
    """
    Get comprehensive dashboard statistics.
    Aggregates job stats, service health, and recent jobs.
    """
    import httpx

    # Initialize default response structure
    dashboard_data = {
        "job_stats": {
            "total": 0,
            "completed": 0,
            "running": 0,
            "failed": 0,
            "success_rate": 0.0
        },
        "service_stats": {
            "available_services": 0,
            "accessible_services": 0
        },
        "recent_jobs": [],
        "status": "success"
    }

    try:
        # Fetch job statistics from job-processor
        async with httpx.AsyncClient(timeout=5.0) as client:
            try:
                job_response = await client.get("http://job-processor:8003/jobs/stats")
                if job_response.status_code == 200:
                    job_data = job_response.json()
                    dashboard_data["job_stats"] = job_data
            except:
                logger.warning("Could not fetch job stats from job-processor")

            # Fetch recent jobs (last 5)
            try:
                recent_response = await client.get("http://job-processor:8003/jobs?limit=5")
                if recent_response.status_code == 200:
                    dashboard_data["recent_jobs"] = recent_response.json()
            except:
                logger.warning("Could not fetch recent jobs from job-processor")

            # Get service stats from service-registry
            try:
                services_response = await client.get("http://service-registry:8002/services")
                if services_response.status_code == 200:
                    services = services_response.json()
                    total_services = len(services)
                    online_services = sum(1 for s in services if s.get('is_available', False))
                    dashboard_data["service_stats"] = {
                        "available_services": total_services,
                        "accessible_services": online_services
                    }
                else:
                    raise Exception("Service registry unavailable")
            except:
                logger.warning("Could not fetch services from service-registry, using fallback")
                # Fallback to health check data
                health_records = db.query(ServiceHealth).order_by(ServiceHealth.checked_at.desc()).limit(6).all()
                if health_records:
                    available = sum(1 for h in health_records if h.status == 'healthy')
                    dashboard_data["service_stats"] = {
                        "available_services": len(health_records),
                        "accessible_services": available
                    }

    except Exception as e:
        logger.error(f"Error aggregating dashboard stats: {e}")
        dashboard_data["status"] = "fallback"
        dashboard_data["message"] = "Using cached or partial data"

    return dashboard_data

@app.get("/health/services", response_model=List[ServiceHealthResponse])
async def get_services_health(db: Session = Depends(get_db)):
    """Get health status of all services."""
    health_results = await health_checker.check_all_services()

    # Store results in database
    for health in health_results:
        health_record = ServiceHealth(**health)
        db.add(health_record)
    db.commit()

    return [ServiceHealthResponse(**health) for health in health_results]

@app.get("/metrics/system", response_model=SystemMetricsResponse)
async def get_system_metrics(db: Session = Depends(get_db)):
    """Get current system metrics."""
    metrics = collect_system_metrics()
    
    if metrics:
        # Store in database
        metrics_record = SystemMetrics(**metrics)
        db.add(metrics_record)
        db.commit()
        
        return SystemMetricsResponse(**metrics)
    else:
        raise HTTPException(status_code=500, detail="Failed to collect system metrics")

@app.get("/alerts", response_model=List[AlertResponse])
async def get_alerts(
    is_active: Optional[bool] = None,
    severity: Optional[str] = None,
    alert_type: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get alerts with optional filtering."""
    query = db.query(Alert)
    
    if is_active is not None:
        query = query.filter(Alert.is_active == is_active)
    if severity:
        query = query.filter(Alert.severity == severity)
    if alert_type:
        query = query.filter(Alert.alert_type == alert_type)
    
    alerts = query.order_by(Alert.triggered_at.desc()).offset(skip).limit(limit).all()
    
    return [
        AlertResponse(
            id=alert.id,
            alert_type=alert.alert_type,
            severity=alert.severity,
            title=alert.title,
            description=alert.description,
            service_name=alert.service_name,
            metric_name=alert.metric_name,
            metric_value=alert.metric_value,
            threshold_value=alert.threshold_value,
            is_active=alert.is_active,
            is_acknowledged=alert.is_acknowledged,
            acknowledged_by=alert.acknowledged_by,
            acknowledged_at=alert.acknowledged_at,
            resolved_at=alert.resolved_at,
            alert_metadata=alert.alert_metadata,
            triggered_at=alert.triggered_at,
            updated_at=alert.updated_at
        )
        for alert in alerts
    ]

@app.patch("/alerts/{alert_id}/acknowledge")
async def acknowledge_alert(
    alert_id: int,
    acknowledged_by: str = "system",
    db: Session = Depends(get_db)
):
    """Acknowledge an alert."""
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    alert.is_acknowledged = True
    alert.acknowledged_by = acknowledged_by
    alert.acknowledged_at = datetime.utcnow()
    alert.updated_at = datetime.utcnow()
    
    db.commit()
    
    return {"message": "Alert acknowledged"}

@app.patch("/alerts/{alert_id}/resolve")
async def resolve_alert(alert_id: int, db: Session = Depends(get_db)):
    """Resolve an alert."""
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    alert.is_active = False
    alert.resolved_at = datetime.utcnow()
    alert.updated_at = datetime.utcnow()
    
    db.commit()
    
    return {"message": "Alert resolved"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8006, reload=True)
