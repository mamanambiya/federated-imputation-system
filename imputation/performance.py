# Performance optimization utilities for the Federated Genomic Imputation Platform

import time
import logging
from functools import wraps
from django.core.cache import cache
from django.db import connection
from django.conf import settings
from django.utils import timezone
from datetime import timedelta
import hashlib
import json

logger = logging.getLogger(__name__)


def cache_result(timeout=300, key_prefix=''):
    """
    Decorator to cache function results
    
    Args:
        timeout: Cache timeout in seconds (default: 5 minutes)
        key_prefix: Prefix for cache key
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key from function name and arguments
            cache_key_data = {
                'func': func.__name__,
                'args': str(args),
                'kwargs': str(sorted(kwargs.items()))
            }
            cache_key_str = json.dumps(cache_key_data, sort_keys=True)
            cache_key = f"{key_prefix}:{hashlib.md5(cache_key_str.encode()).hexdigest()}"
            
            # Try to get from cache
            result = cache.get(cache_key)
            if result is not None:
                logger.debug(f"Cache hit for {func.__name__}")
                return result
            
            # Execute function and cache result
            logger.debug(f"Cache miss for {func.__name__}, executing...")
            result = func(*args, **kwargs)
            cache.set(cache_key, result, timeout)
            
            return result
        return wrapper
    return decorator


def monitor_performance(log_slow_queries=True, slow_threshold=1.0):
    """
    Decorator to monitor function performance
    
    Args:
        log_slow_queries: Whether to log slow database queries
        slow_threshold: Threshold in seconds for logging slow operations
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start_time = time.time()
            initial_queries = len(connection.queries) if settings.DEBUG else 0
            
            try:
                result = func(*args, **kwargs)
                return result
            finally:
                end_time = time.time()
                duration = end_time - start_time
                
                # Log performance metrics
                if duration > slow_threshold:
                    query_count = len(connection.queries) - initial_queries if settings.DEBUG else 0
                    logger.warning(
                        f"Slow operation: {func.__name__} took {duration:.2f}s "
                        f"with {query_count} database queries"
                    )
                
                # Log slow queries if enabled
                if log_slow_queries and settings.DEBUG:
                    for query in connection.queries[initial_queries:]:
                        query_time = float(query['time'])
                        if query_time > 0.1:  # Log queries taking more than 100ms
                            logger.warning(f"Slow query ({query_time:.3f}s): {query['sql'][:200]}...")
        
        return wrapper
    return decorator


class QueryOptimizer:
    """Utility class for optimizing database queries"""
    
    @staticmethod
    def get_user_jobs_optimized(user, status=None, limit=50):
        """
        Optimized query to get user jobs with related data
        """
        from .models import ImputationJob
        
        queryset = ImputationJob.objects.select_related(
            'service', 'reference_panel', 'user'
        ).filter(user=user)
        
        if status:
            queryset = queryset.filter(status=status)
        
        return queryset.order_by('-created_at')[:limit]
    
    @staticmethod
    def get_service_statistics():
        """
        Get service statistics with optimized queries
        """
        from .models import ImputationService, ImputationJob
        from django.db.models import Count, Avg, Q
        
        return ImputationService.objects.annotate(
            total_jobs=Count('imputationjob'),
            completed_jobs=Count('imputationjob', filter=Q(imputationjob__status='completed')),
            failed_jobs=Count('imputationjob', filter=Q(imputationjob__status='failed')),
            avg_execution_time=Avg('imputationjob__execution_time_seconds')
        ).select_related('institution')
    
    @staticmethod
    def get_recent_activity(days=7, limit=100):
        """
        Get recent activity with optimized queries
        """
        from .models import ImputationJob
        
        since_date = timezone.now() - timedelta(days=days)
        
        return ImputationJob.objects.select_related(
            'user', 'service', 'reference_panel'
        ).filter(
            created_at__gte=since_date
        ).order_by('-created_at')[:limit]


class CacheManager:
    """Manager for application-level caching"""
    
    CACHE_KEYS = {
        'service_list': 'services:list',
        'reference_panels': 'panels:list',
        'user_stats': 'user:stats:{}',
        'service_health': 'service:health:{}',
        'system_stats': 'system:stats',
    }
    
    @classmethod
    def get_services(cls, force_refresh=False):
        """Get cached list of services"""
        cache_key = cls.CACHE_KEYS['service_list']
        
        if force_refresh:
            cache.delete(cache_key)
        
        services = cache.get(cache_key)
        if services is None:
            from .models import ImputationService
            services = list(ImputationService.objects.filter(is_active=True).select_related('institution'))
            cache.set(cache_key, services, 300)  # Cache for 5 minutes
        
        return services
    
    @classmethod
    def get_reference_panels(cls, service_id=None, force_refresh=False):
        """Get cached list of reference panels"""
        cache_key = f"{cls.CACHE_KEYS['reference_panels']}:{service_id or 'all'}"
        
        if force_refresh:
            cache.delete(cache_key)
        
        panels = cache.get(cache_key)
        if panels is None:
            from .models import ReferencePanel
            queryset = ReferencePanel.objects.filter(is_active=True)
            if service_id:
                queryset = queryset.filter(service_id=service_id)
            panels = list(queryset.select_related('service'))
            cache.set(cache_key, panels, 600)  # Cache for 10 minutes
        
        return panels
    
    @classmethod
    def get_user_stats(cls, user_id, force_refresh=False):
        """Get cached user statistics"""
        cache_key = cls.CACHE_KEYS['user_stats'].format(user_id)
        
        if force_refresh:
            cache.delete(cache_key)
        
        stats = cache.get(cache_key)
        if stats is None:
            from .models import ImputationJob
            from django.db.models import Count, Q
            
            job_stats = ImputationJob.objects.filter(user_id=user_id).aggregate(
                total_jobs=Count('id'),
                completed_jobs=Count('id', filter=Q(status='completed')),
                failed_jobs=Count('id', filter=Q(status='failed')),
                pending_jobs=Count('id', filter=Q(status='pending')),
                running_jobs=Count('id', filter=Q(status='running')),
            )
            
            stats = {
                'total_jobs': job_stats['total_jobs'] or 0,
                'completed_jobs': job_stats['completed_jobs'] or 0,
                'failed_jobs': job_stats['failed_jobs'] or 0,
                'pending_jobs': job_stats['pending_jobs'] or 0,
                'running_jobs': job_stats['running_jobs'] or 0,
                'success_rate': (
                    (job_stats['completed_jobs'] or 0) / max(job_stats['total_jobs'] or 1, 1) * 100
                ),
                'last_updated': timezone.now().isoformat(),
            }
            
            cache.set(cache_key, stats, 300)  # Cache for 5 minutes
        
        return stats
    
    @classmethod
    def invalidate_user_cache(cls, user_id):
        """Invalidate all cache entries for a user"""
        cache_key = cls.CACHE_KEYS['user_stats'].format(user_id)
        cache.delete(cache_key)
    
    @classmethod
    def invalidate_service_cache(cls):
        """Invalidate service-related cache entries"""
        cache.delete(cls.CACHE_KEYS['service_list'])
        cache.delete(cls.CACHE_KEYS['reference_panels'] + ':all')
    
    @classmethod
    def get_service_health(cls, service_id, force_refresh=False):
        """Get cached service health status"""
        cache_key = cls.CACHE_KEYS['service_health'].format(service_id)
        
        if force_refresh:
            cache.delete(cache_key)
        
        health = cache.get(cache_key)
        if health is None:
            # This would be implemented based on actual health check logic
            health = {
                'status': 'unknown',
                'last_check': timezone.now().isoformat(),
                'response_time': None,
            }
            cache.set(cache_key, health, 60)  # Cache for 1 minute
        
        return health


class DatabaseOptimizer:
    """Utilities for database optimization"""
    
    @staticmethod
    def analyze_slow_queries():
        """Analyze slow queries from Django debug toolbar data"""
        if not settings.DEBUG:
            return []
        
        slow_queries = []
        for query in connection.queries:
            query_time = float(query['time'])
            if query_time > 0.1:  # Queries taking more than 100ms
                slow_queries.append({
                    'sql': query['sql'],
                    'time': query_time,
                    'stack': query.get('stack', [])
                })
        
        return sorted(slow_queries, key=lambda x: x['time'], reverse=True)
    
    @staticmethod
    def get_query_count():
        """Get current query count for debugging"""
        return len(connection.queries) if settings.DEBUG else 0
    
    @staticmethod
    def reset_queries():
        """Reset query log for debugging"""
        if settings.DEBUG:
            connection.queries_log.clear()


# Decorators for common use cases
def cache_for_5_minutes(func):
    """Cache function result for 5 minutes"""
    return cache_result(timeout=300)(func)


def cache_for_1_hour(func):
    """Cache function result for 1 hour"""
    return cache_result(timeout=3600)(func)


def monitor_slow_operations(func):
    """Monitor and log slow operations"""
    return monitor_performance(slow_threshold=1.0)(func)
