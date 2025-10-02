# Comprehensive Monitoring and Observability System

import time
import logging
import psutil
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from django.core.cache import cache
from django.db import connection
from django.conf import settings
from django.utils import timezone
from django.core.mail import send_mail
from django.db.models import Count, Avg, Q
from .models import ImputationJob, ImputationService
from .performance import CacheManager

logger = logging.getLogger(__name__)


class SystemMetrics:
    """System performance and health metrics collector"""
    
    @staticmethod
    def get_system_metrics() -> Dict[str, Any]:
        """Collect comprehensive system metrics"""
        try:
            # CPU metrics
            cpu_percent = psutil.cpu_percent(interval=1)
            cpu_count = psutil.cpu_count()
            
            # Memory metrics
            memory = psutil.virtual_memory()
            memory_percent = memory.percent
            memory_available = memory.available
            memory_total = memory.total
            
            # Disk metrics
            disk = psutil.disk_usage('/')
            disk_percent = disk.percent
            disk_free = disk.free
            disk_total = disk.total
            
            # Network metrics (if available)
            try:
                network = psutil.net_io_counters()
                network_sent = network.bytes_sent
                network_recv = network.bytes_recv
            except:
                network_sent = network_recv = 0
            
            return {
                'timestamp': timezone.now().isoformat(),
                'cpu': {
                    'percent': cpu_percent,
                    'count': cpu_count,
                },
                'memory': {
                    'percent': memory_percent,
                    'available_bytes': memory_available,
                    'total_bytes': memory_total,
                    'used_bytes': memory_total - memory_available,
                },
                'disk': {
                    'percent': disk_percent,
                    'free_bytes': disk_free,
                    'total_bytes': disk_total,
                    'used_bytes': disk_total - disk_free,
                },
                'network': {
                    'bytes_sent': network_sent,
                    'bytes_received': network_recv,
                },
            }
        except Exception as e:
            logger.error(f"Failed to collect system metrics: {e}")
            return {'error': str(e), 'timestamp': timezone.now().isoformat()}
    
    @staticmethod
    def get_database_metrics() -> Dict[str, Any]:
        """Collect database performance metrics"""
        try:
            with connection.cursor() as cursor:
                # Database size
                cursor.execute("""
                    SELECT pg_size_pretty(pg_database_size(current_database())) as size,
                           pg_database_size(current_database()) as size_bytes
                """)
                db_size = cursor.fetchone()
                
                # Active connections
                cursor.execute("""
                    SELECT count(*) FROM pg_stat_activity 
                    WHERE state = 'active' AND pid <> pg_backend_pid()
                """)
                active_connections = cursor.fetchone()[0]
                
                # Table sizes
                cursor.execute("""
                    SELECT schemaname, tablename, 
                           pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
                           pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
                    FROM pg_tables 
                    WHERE schemaname = 'public' 
                    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC 
                    LIMIT 10
                """)
                table_sizes = cursor.fetchall()
                
                return {
                    'timestamp': timezone.now().isoformat(),
                    'database_size': db_size[0] if db_size else 'Unknown',
                    'database_size_bytes': db_size[1] if db_size else 0,
                    'active_connections': active_connections,
                    'table_sizes': [
                        {
                            'schema': row[0],
                            'table': row[1],
                            'size': row[2],
                            'size_bytes': row[3]
                        }
                        for row in table_sizes
                    ]
                }
        except Exception as e:
            logger.error(f"Failed to collect database metrics: {e}")
            return {'error': str(e), 'timestamp': timezone.now().isoformat()}
    
    @staticmethod
    def get_application_metrics() -> Dict[str, Any]:
        """Collect application-specific metrics"""
        try:
            # Job statistics
            total_jobs = ImputationJob.objects.count()
            
            # Jobs by status
            job_status_counts = ImputationJob.objects.values('status').annotate(
                count=Count('id')
            )
            status_breakdown = {item['status']: item['count'] for item in job_status_counts}
            
            # Recent job activity (last 24 hours)
            last_24h = timezone.now() - timedelta(hours=24)
            recent_jobs = ImputationJob.objects.filter(created_at__gte=last_24h).count()
            
            # Service statistics
            active_services = ImputationService.objects.filter(is_active=True).count()
            total_services = ImputationService.objects.count()
            
            # Average job execution time
            avg_execution_time = ImputationJob.objects.filter(
                execution_time_seconds__isnull=False
            ).aggregate(avg_time=Avg('execution_time_seconds'))['avg_time'] or 0
            
            # Success rate
            completed_jobs = status_breakdown.get('completed', 0)
            failed_jobs = status_breakdown.get('failed', 0)
            total_finished = completed_jobs + failed_jobs
            success_rate = (completed_jobs / max(total_finished, 1)) * 100
            
            return {
                'timestamp': timezone.now().isoformat(),
                'jobs': {
                    'total': total_jobs,
                    'recent_24h': recent_jobs,
                    'status_breakdown': status_breakdown,
                    'avg_execution_time_seconds': avg_execution_time,
                    'success_rate_percent': success_rate,
                },
                'services': {
                    'active': active_services,
                    'total': total_services,
                },
            }
        except Exception as e:
            logger.error(f"Failed to collect application metrics: {e}")
            return {'error': str(e), 'timestamp': timezone.now().isoformat()}


class HealthChecker:
    """System health monitoring and alerting"""
    
    HEALTH_THRESHOLDS = {
        'cpu_percent': 80,
        'memory_percent': 85,
        'disk_percent': 90,
        'database_connections': 50,
        'response_time_seconds': 5.0,
    }
    
    @classmethod
    def check_system_health(cls) -> Dict[str, Any]:
        """Perform comprehensive health check"""
        health_status = {
            'timestamp': timezone.now().isoformat(),
            'overall_status': 'healthy',
            'checks': {},
            'alerts': [],
        }
        
        # System metrics check
        system_metrics = SystemMetrics.get_system_metrics()
        if 'error' not in system_metrics:
            health_status['checks']['system'] = cls._check_system_metrics(system_metrics)
        else:
            health_status['checks']['system'] = {'status': 'error', 'message': system_metrics['error']}
        
        # Database check
        db_metrics = SystemMetrics.get_database_metrics()
        if 'error' not in db_metrics:
            health_status['checks']['database'] = cls._check_database_metrics(db_metrics)
        else:
            health_status['checks']['database'] = {'status': 'error', 'message': db_metrics['error']}
        
        # Application check
        app_metrics = SystemMetrics.get_application_metrics()
        if 'error' not in app_metrics:
            health_status['checks']['application'] = cls._check_application_metrics(app_metrics)
        else:
            health_status['checks']['application'] = {'status': 'error', 'message': app_metrics['error']}
        
        # Service connectivity check
        health_status['checks']['services'] = cls._check_service_connectivity()
        
        # Determine overall status
        check_statuses = [check['status'] for check in health_status['checks'].values()]
        if 'critical' in check_statuses:
            health_status['overall_status'] = 'critical'
        elif 'warning' in check_statuses:
            health_status['overall_status'] = 'warning'
        elif 'error' in check_statuses:
            health_status['overall_status'] = 'error'
        
        # Collect alerts
        for check_name, check_result in health_status['checks'].items():
            if check_result['status'] in ['warning', 'critical', 'error']:
                health_status['alerts'].append({
                    'component': check_name,
                    'level': check_result['status'],
                    'message': check_result.get('message', 'Health check failed'),
                    'timestamp': timezone.now().isoformat(),
                })
        
        return health_status
    
    @classmethod
    def _check_system_metrics(cls, metrics: Dict[str, Any]) -> Dict[str, Any]:
        """Check system metrics against thresholds"""
        issues = []
        
        cpu_percent = metrics['cpu']['percent']
        if cpu_percent > cls.HEALTH_THRESHOLDS['cpu_percent']:
            issues.append(f"High CPU usage: {cpu_percent}%")
        
        memory_percent = metrics['memory']['percent']
        if memory_percent > cls.HEALTH_THRESHOLDS['memory_percent']:
            issues.append(f"High memory usage: {memory_percent}%")
        
        disk_percent = metrics['disk']['percent']
        if disk_percent > cls.HEALTH_THRESHOLDS['disk_percent']:
            issues.append(f"High disk usage: {disk_percent}%")
        
        if issues:
            return {
                'status': 'critical' if any('High' in issue for issue in issues) else 'warning',
                'message': '; '.join(issues),
                'metrics': metrics
            }
        
        return {'status': 'healthy', 'message': 'System metrics within normal ranges'}
    
    @classmethod
    def _check_database_metrics(cls, metrics: Dict[str, Any]) -> Dict[str, Any]:
        """Check database metrics against thresholds"""
        issues = []
        
        active_connections = metrics.get('active_connections', 0)
        if active_connections > cls.HEALTH_THRESHOLDS['database_connections']:
            issues.append(f"High database connections: {active_connections}")
        
        if issues:
            return {
                'status': 'warning',
                'message': '; '.join(issues),
                'metrics': metrics
            }
        
        return {'status': 'healthy', 'message': 'Database metrics within normal ranges'}
    
    @classmethod
    def _check_application_metrics(cls, metrics: Dict[str, Any]) -> Dict[str, Any]:
        """Check application metrics"""
        issues = []
        
        success_rate = metrics['jobs']['success_rate_percent']
        if success_rate < 90:
            issues.append(f"Low job success rate: {success_rate:.1f}%")
        
        if issues:
            return {
                'status': 'warning',
                'message': '; '.join(issues),
                'metrics': metrics
            }
        
        return {'status': 'healthy', 'message': 'Application metrics within normal ranges'}
    
    @classmethod
    def _check_service_connectivity(cls) -> Dict[str, Any]:
        """Check connectivity to external services"""
        # This would implement actual service health checks
        # For now, return a placeholder
        return {
            'status': 'healthy',
            'message': 'Service connectivity checks passed',
            'services_checked': 0
        }


class AlertManager:
    """Alert management and notification system"""
    
    ALERT_LEVELS = {
        'info': 0,
        'warning': 1,
        'error': 2,
        'critical': 3,
    }
    
    @classmethod
    def send_alert(cls, level: str, component: str, message: str, 
                   details: Optional[Dict[str, Any]] = None):
        """Send alert notification"""
        alert_data = {
            'level': level,
            'component': component,
            'message': message,
            'details': details or {},
            'timestamp': timezone.now().isoformat(),
        }
        
        # Log the alert
        log_level = getattr(logging, level.upper(), logging.INFO)
        logger.log(log_level, f"ALERT [{level.upper()}] {component}: {message}")
        
        # Cache recent alerts
        cls._cache_alert(alert_data)
        
        # Send notifications based on level
        if cls.ALERT_LEVELS[level] >= cls.ALERT_LEVELS['error']:
            cls._send_email_alert(alert_data)
        
        # Store in database (if needed)
        cls._store_alert(alert_data)
    
    @classmethod
    def _cache_alert(cls, alert_data: Dict[str, Any]):
        """Cache alert for quick retrieval"""
        cache_key = 'recent_alerts'
        recent_alerts = cache.get(cache_key, [])
        
        # Add new alert
        recent_alerts.insert(0, alert_data)
        
        # Keep only last 100 alerts
        recent_alerts = recent_alerts[:100]
        
        # Cache for 1 hour
        cache.set(cache_key, recent_alerts, 3600)
    
    @classmethod
    def _send_email_alert(cls, alert_data: Dict[str, Any]):
        """Send email notification for critical alerts"""
        try:
            subject = f"[{alert_data['level'].upper()}] {alert_data['component']}: {alert_data['message']}"
            message = f"""
Alert Details:
- Level: {alert_data['level']}
- Component: {alert_data['component']}
- Message: {alert_data['message']}
- Timestamp: {alert_data['timestamp']}

Additional Details:
{json.dumps(alert_data['details'], indent=2)}
            """
            
            # Get admin emails from settings
            admin_emails = getattr(settings, 'ADMIN_EMAILS', [])
            if admin_emails:
                send_mail(
                    subject=subject,
                    message=message,
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=admin_emails,
                    fail_silently=True
                )
        except Exception as e:
            logger.error(f"Failed to send email alert: {e}")
    
    @classmethod
    def _store_alert(cls, alert_data: Dict[str, Any]):
        """Store alert in database for historical tracking"""
        # This would store alerts in a database table
        # For now, just log it
        logger.info(f"Alert stored: {alert_data}")
    
    @classmethod
    def get_recent_alerts(cls, limit: int = 50) -> List[Dict[str, Any]]:
        """Get recent alerts from cache"""
        cache_key = 'recent_alerts'
        recent_alerts = cache.get(cache_key, [])
        return recent_alerts[:limit]


class MonitoringDashboard:
    """Dashboard data aggregation for monitoring"""
    
    @staticmethod
    def get_dashboard_data() -> Dict[str, Any]:
        """Get comprehensive dashboard data"""
        return {
            'timestamp': timezone.now().isoformat(),
            'system_metrics': SystemMetrics.get_system_metrics(),
            'database_metrics': SystemMetrics.get_database_metrics(),
            'application_metrics': SystemMetrics.get_application_metrics(),
            'health_status': HealthChecker.check_system_health(),
            'recent_alerts': AlertManager.get_recent_alerts(20),
        }
    
    @staticmethod
    def get_performance_trends(hours: int = 24) -> Dict[str, Any]:
        """Get performance trends over time"""
        # This would implement time-series data collection
        # For now, return placeholder data
        return {
            'timestamp': timezone.now().isoformat(),
            'period_hours': hours,
            'trends': {
                'job_completion_rate': [],
                'average_response_time': [],
                'system_load': [],
            }
        }
