"""
Dashboard Data Caching Service

Provides Redis caching for frequently accessed dashboard data including:
- User statistics
- Service availability
- Job metrics
- System health summaries
"""
import json
import logging
import functools
from datetime import timedelta
from typing import Dict, Any, Optional, Callable
from django.core.cache import cache
from django.utils import timezone
from django.conf import settings
from django.db.models import Count, Q, Avg, Sum
from django.contrib.auth.models import User

logger = logging.getLogger(__name__)


class DashboardCacheService:
    """
    Centralized caching service for dashboard data with smart invalidation.

    Cache Durations:
    - User stats: 5 minutes (frequently changing)
    - Service status: 2 minutes (health checks update often)
    - Job statistics: 3 minutes (moderate update frequency)
    - System metrics: 1 minute (real-time monitoring)
    """

    # Cache key prefixes
    USER_STATS_PREFIX = "dashboard:user_stats"
    SERVICE_STATUS_PREFIX = "dashboard:service_status"
    JOB_STATS_PREFIX = "dashboard:job_stats"
    SYSTEM_METRICS_PREFIX = "dashboard:system_metrics"
    RECENT_JOBS_PREFIX = "dashboard:recent_jobs"

    # Cache durations in seconds
    USER_STATS_TTL = 5 * 60        # 5 minutes
    SERVICE_STATUS_TTL = 2 * 60    # 2 minutes
    JOB_STATS_TTL = 3 * 60         # 3 minutes
    SYSTEM_METRICS_TTL = 1 * 60    # 1 minute
    RECENT_JOBS_TTL = 2 * 60       # 2 minutes

    def __init__(self):
        self.enabled = getattr(settings, 'DASHBOARD_CACHE_ENABLED', True)
        self.default_timeout = getattr(settings, 'DASHBOARD_CACHE_TIMEOUT', 600)

    def _get_cache_key(self, prefix: str, *args) -> str:
        """Generate cache key with prefix and optional arguments."""
        key_parts = [prefix] + [str(arg) for arg in args]
        return ":".join(key_parts)

    def _get_cached(self, key: str) -> Optional[Any]:
        """Get cached data with error handling."""
        if not self.enabled:
            return None

        try:
            cached_data = cache.get(key)
            if cached_data:
                logger.debug(f"Cache HIT: {key}")
                return json.loads(cached_data) if isinstance(cached_data, str) else cached_data
        except Exception as e:
            logger.warning(f"Cache read error for {key}: {e}")

        logger.debug(f"Cache MISS: {key}")
        return None

    def _set_cached(self, key: str, data: Any, timeout: int) -> bool:
        """Set cached data with error handling."""
        if not self.enabled:
            return False

        try:
            cache_data = {
                'data': data,
                'cached_at': timezone.now().isoformat(),
                'expires_at': (timezone.now() + timedelta(seconds=timeout)).isoformat()
            }
            cache.set(key, json.dumps(cache_data, default=str), timeout=timeout)
            logger.debug(f"Cache SET: {key} (TTL: {timeout}s)")
            return True
        except Exception as e:
            logger.error(f"Cache write error for {key}: {e}")
            return False

    def get_user_stats(self, user_id: int) -> Optional[Dict[str, Any]]:
        """Get cached user statistics."""
        key = self._get_cache_key(self.USER_STATS_PREFIX, user_id)
        cached = self._get_cached(key)
        return cached['data'] if cached else None

    def set_user_stats(self, user_id: int, stats: Dict[str, Any]) -> bool:
        """Cache user statistics."""
        key = self._get_cache_key(self.USER_STATS_PREFIX, user_id)
        return self._set_cached(key, stats, self.USER_STATS_TTL)

    def get_service_status(self) -> Optional[Dict[str, Any]]:
        """Get cached service status summary."""
        key = self._get_cache_key(self.SERVICE_STATUS_PREFIX, "all")
        cached = self._get_cached(key)
        return cached['data'] if cached else None

    def set_service_status(self, status: Dict[str, Any]) -> bool:
        """Cache service status summary."""
        key = self._get_cache_key(self.SERVICE_STATUS_PREFIX, "all")
        return self._set_cached(key, status, self.SERVICE_STATUS_TTL)

    def get_job_stats(self, user_id: Optional[int] = None) -> Optional[Dict[str, Any]]:
        """Get cached job statistics (global or per-user)."""
        key = self._get_cache_key(self.JOB_STATS_PREFIX, user_id or "global")
        cached = self._get_cached(key)
        return cached['data'] if cached else None

    def set_job_stats(self, stats: Dict[str, Any], user_id: Optional[int] = None) -> bool:
        """Cache job statistics."""
        key = self._get_cache_key(self.JOB_STATS_PREFIX, user_id or "global")
        return self._set_cached(key, stats, self.JOB_STATS_TTL)

    def get_system_metrics(self) -> Optional[Dict[str, Any]]:
        """Get cached system metrics."""
        key = self._get_cache_key(self.SYSTEM_METRICS_PREFIX, "current")
        cached = self._get_cached(key)
        return cached['data'] if cached else None

    def set_system_metrics(self, metrics: Dict[str, Any]) -> bool:
        """Cache system metrics."""
        key = self._get_cache_key(self.SYSTEM_METRICS_PREFIX, "current")
        return self._set_cached(key, metrics, self.SYSTEM_METRICS_TTL)

    def get_recent_jobs(self, user_id: int, limit: int = 10) -> Optional[list]:
        """Get cached recent jobs for a user."""
        key = self._get_cache_key(self.RECENT_JOBS_PREFIX, user_id, limit)
        cached = self._get_cached(key)
        return cached['data'] if cached else None

    def set_recent_jobs(self, user_id: int, jobs: list, limit: int = 10) -> bool:
        """Cache recent jobs for a user."""
        key = self._get_cache_key(self.RECENT_JOBS_PREFIX, user_id, limit)
        return self._set_cached(key, jobs, self.RECENT_JOBS_TTL)

    def invalidate_user_cache(self, user_id: int) -> None:
        """Invalidate all cached data for a specific user."""
        patterns = [
            self._get_cache_key(self.USER_STATS_PREFIX, user_id),
            self._get_cache_key(self.JOB_STATS_PREFIX, user_id),
            # Recent jobs might have multiple limits, but we'll clear common ones
            self._get_cache_key(self.RECENT_JOBS_PREFIX, user_id, 10),
            self._get_cache_key(self.RECENT_JOBS_PREFIX, user_id, 20),
            self._get_cache_key(self.RECENT_JOBS_PREFIX, user_id, 50),
        ]

        for key in patterns:
            try:
                cache.delete(key)
                logger.debug(f"Invalidated cache: {key}")
            except Exception as e:
                logger.warning(f"Failed to invalidate {key}: {e}")

    def invalidate_job_stats(self, user_id: Optional[int] = None) -> None:
        """Invalidate job statistics cache."""
        if user_id:
            key = self._get_cache_key(self.JOB_STATS_PREFIX, user_id)
        else:
            key = self._get_cache_key(self.JOB_STATS_PREFIX, "global")

        try:
            cache.delete(key)
            logger.debug(f"Invalidated job stats cache: {key}")
        except Exception as e:
            logger.warning(f"Failed to invalidate job stats: {e}")

    def invalidate_service_status(self) -> None:
        """Invalidate service status cache."""
        key = self._get_cache_key(self.SERVICE_STATUS_PREFIX, "all")
        try:
            cache.delete(key)
            logger.debug("Invalidated service status cache")
        except Exception as e:
            logger.warning(f"Failed to invalidate service status: {e}")

    def clear_all(self) -> None:
        """Clear all dashboard caches."""
        try:
            # Get all dashboard cache keys
            # Note: This is a simplified version. In production, you might want to
            # use Redis SCAN or maintain a set of active keys
            logger.warning("Clearing all dashboard cache")
            # For Redis backend, you could use: cache.delete_pattern("dashboard:*")
        except Exception as e:
            logger.error(f"Failed to clear dashboard cache: {e}")

    def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache statistics and configuration."""
        return {
            'enabled': self.enabled,
            'backend': cache.__class__.__name__,
            'ttl_config': {
                'user_stats': f"{self.USER_STATS_TTL}s",
                'service_status': f"{self.SERVICE_STATUS_TTL}s",
                'job_stats': f"{self.JOB_STATS_TTL}s",
                'system_metrics': f"{self.SYSTEM_METRICS_TTL}s",
                'recent_jobs': f"{self.RECENT_JOBS_TTL}s",
            },
            'cache_info': self._get_cache_info()
        }

    def _get_cache_info(self) -> Dict[str, Any]:
        """Get information about cached items (if supported by backend)."""
        try:
            # This would need to be implemented based on cache backend
            # For Redis, you could count keys matching patterns
            return {
                'total_keys': 'N/A',
                'memory_used': 'N/A',
                'hit_rate': 'N/A'
            }
        except:
            return {}


def cache_dashboard_data(cache_key_func: Callable, ttl: int):
    """
    Decorator for caching dashboard view methods.

    Args:
        cache_key_func: Function that takes (*args, **kwargs) and returns cache key
        ttl: Time to live in seconds

    Example:
        @cache_dashboard_data(lambda self, user_id: f"user_jobs:{user_id}", 300)
        def get_user_jobs(self, user_id):
            return Job.objects.filter(user_id=user_id)
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key
            try:
                cache_key = cache_key_func(*args, **kwargs)
            except Exception as e:
                logger.warning(f"Failed to generate cache key: {e}")
                return func(*args, **kwargs)

            # Try to get from cache
            cached_data = cache.get(cache_key)
            if cached_data is not None:
                logger.debug(f"Cache HIT: {cache_key}")
                try:
                    return json.loads(cached_data) if isinstance(cached_data, str) else cached_data
                except json.JSONDecodeError:
                    logger.warning(f"Failed to decode cache for {cache_key}")

            # Cache miss - execute function
            logger.debug(f"Cache MISS: {cache_key}")
            result = func(*args, **kwargs)

            # Cache the result
            try:
                cache.set(cache_key, json.dumps(result, default=str), timeout=ttl)
                logger.debug(f"Cached result for {cache_key} (TTL: {ttl}s)")
            except Exception as e:
                logger.warning(f"Failed to cache result for {cache_key}: {e}")

            return result
        return wrapper
    return decorator


# Global instance
dashboard_cache = DashboardCacheService()


# Signal handlers for cache invalidation
try:
    from django.db.models.signals import post_save, post_delete
    from django.dispatch import receiver

    @receiver(post_save, sender='imputation.ImputationJob')
    def invalidate_job_cache_on_save(sender, instance, created, **kwargs):
        """Invalidate job-related caches when a job is created or updated."""
        if created or instance.status in ['completed', 'failed', 'cancelled']:
            dashboard_cache.invalidate_job_stats(instance.user_id)
            dashboard_cache.invalidate_job_stats()  # Global stats
            dashboard_cache.invalidate_user_cache(instance.user_id)

    @receiver(post_delete, sender='imputation.ImputationJob')
    def invalidate_job_cache_on_delete(sender, instance, **kwargs):
        """Invalidate job-related caches when a job is deleted."""
        dashboard_cache.invalidate_job_stats(instance.user_id)
        dashboard_cache.invalidate_job_stats()  # Global stats
        dashboard_cache.invalidate_user_cache(instance.user_id)

    @receiver(post_save, sender='imputation.ImputationService')
    def invalidate_service_cache_on_save(sender, instance, **kwargs):
        """Invalidate service status cache when a service is updated."""
        dashboard_cache.invalidate_service_status()

    logger.info("Dashboard cache signal handlers registered")

except ImportError:
    logger.warning("Could not register cache invalidation signal handlers")
