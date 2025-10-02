"""
Caching service for health check results with intelligent intervals.
"""
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, Optional, Tuple, Any
from django.core.cache import cache
from django.utils import timezone
from django.conf import settings

logger = logging.getLogger(__name__)


class HealthCheckCacheService:
    """
    Service for caching health check results with intelligent interval management.
    
    Cache intervals:
    - Online services: 15 minutes for both user and system
    - Offline services: 1 minute for user, 10 seconds for system
    - Demo services: 30 minutes (they're expected to be unavailable)
    """
    
    # Cache key prefixes
    HEALTH_CACHE_PREFIX = "health_check"
    LAST_CHECK_PREFIX = "last_health_check"
    CHECK_COUNTER_PREFIX = "health_check_counter"
    
    # Cache intervals in seconds
    ONLINE_INTERVAL = 15 * 60  # 15 minutes
    OFFLINE_USER_INTERVAL = 1 * 60  # 1 minute
    OFFLINE_SYSTEM_INTERVAL = 10  # 10 seconds
    
    def __init__(self):
        self.cache_timeout = getattr(settings, 'HEALTH_CHECK_CACHE_TIMEOUT', 3600)  # 1 hour max
    
    def _get_cache_key(self, service_id: int, key_type: str) -> str:
        """Generate cache key for a service."""
        return f"{key_type}:service:{service_id}"
    
    def _get_interval(self, status: str, is_user_request: bool = True) -> int:
        """
        Get cache interval based on status and request type.

        Args:
            status: Service status ('healthy', 'unhealthy', 'unknown', 'timeout')
            is_user_request: True for user-initiated, False for system-initiated

        Returns:
            Cache interval in seconds

        Note: Removed 'demo' status - demo services should report as 'healthy' (online)
              or 'unhealthy' (offline) like any other service.
        """
        if status in ['healthy', 'checking']:
            return self.ONLINE_INTERVAL
        else:  # unhealthy, unknown, timeout, etc.
            return self.OFFLINE_USER_INTERVAL if is_user_request else self.OFFLINE_SYSTEM_INTERVAL
    
    def get_cached_health(self, service_id: int) -> Optional[Dict[str, Any]]:
        """
        Get cached health check result for a service.
        
        Returns:
            Cached health data or None if not cached/expired
        """
        cache_key = self._get_cache_key(service_id, self.HEALTH_CACHE_PREFIX)
        cached_data = cache.get(cache_key)
        
        if cached_data:
            try:
                health_data = json.loads(cached_data) if isinstance(cached_data, str) else cached_data
                logger.debug(f"Cache HIT for service {service_id}: {health_data.get('status')}")
                return health_data
            except (json.JSONDecodeError, TypeError) as e:
                logger.warning(f"Failed to decode cached health data for service {service_id}: {e}")
                self.clear_service_cache(service_id)
        
        logger.debug(f"Cache MISS for service {service_id}")
        return None
    
    def set_cached_health(self, service_id: int, health_data: Dict[str, Any], 
                         is_user_request: bool = True) -> None:
        """
        Cache health check result with appropriate interval.
        
        Args:
            service_id: Service ID
            health_data: Health check result data
            is_user_request: Whether this was user-initiated or system-initiated
        """
        status = health_data.get('status', 'unknown')
        interval = self._get_interval(status, is_user_request)
        
        # Add metadata to cached data
        cache_data = {
            **health_data,
            '_cached_at': timezone.now().isoformat(),
            '_cache_interval': interval,
            '_is_user_request': is_user_request,
            '_expires_at': (timezone.now() + timedelta(seconds=interval)).isoformat()
        }
        
        # Cache the health data
        cache_key = self._get_cache_key(service_id, self.HEALTH_CACHE_PREFIX)
        cache.set(cache_key, json.dumps(cache_data, default=str), timeout=interval)
        
        # Update last check timestamp
        last_check_key = self._get_cache_key(service_id, self.LAST_CHECK_PREFIX)
        cache.set(last_check_key, timezone.now().isoformat(), timeout=self.cache_timeout)
        
        # Increment check counter
        counter_key = self._get_cache_key(service_id, self.CHECK_COUNTER_PREFIX)
        current_count = cache.get(counter_key, 0)
        cache.set(counter_key, current_count + 1, timeout=self.cache_timeout)
        
        logger.info(f"Cached health for service {service_id}: {status} (interval: {interval}s, user: {is_user_request})")
    
    def should_check_health(self, service_id: int, is_user_request: bool = True) -> Tuple[bool, Optional[Dict[str, Any]]]:
        """
        Determine if health check should be performed or use cached result.
        
        Returns:
            Tuple of (should_check, cached_data)
        """
        cached_health = self.get_cached_health(service_id)
        
        if cached_health is None:
            return True, None
        
        cached_at_str = cached_health.get('_cached_at')
        cache_interval = cached_health.get('_cache_interval', 0)
        was_user_request = cached_health.get('_is_user_request', True)
        
        if not cached_at_str:
            return True, None
        
        try:
            cached_at = datetime.fromisoformat(cached_at_str.replace('Z', '+00:00'))
            if timezone.is_naive(cached_at):
                cached_at = timezone.make_aware(cached_at)
            
            age = (timezone.now() - cached_at).total_seconds()
            
            # If it's a system request and the cache was from a user request,
            # we might need to check more frequently for offline services
            if not is_user_request and was_user_request:
                status = cached_health.get('status', 'unknown')
                if status in ['unhealthy', 'unknown']:
                    # Use system interval for offline services
                    effective_interval = self.OFFLINE_SYSTEM_INTERVAL
                    if age >= effective_interval:
                        return True, None
            
            # Normal cache expiry check
            if age >= cache_interval:
                return True, None
            
            return False, cached_health
            
        except (ValueError, TypeError) as e:
            logger.warning(f"Error parsing cached timestamp for service {service_id}: {e}")
            return True, None
    
    def get_last_check_time(self, service_id: int) -> Optional[datetime]:
        """Get the last time a service was checked."""
        last_check_key = self._get_cache_key(service_id, self.LAST_CHECK_PREFIX)
        last_check_str = cache.get(last_check_key)
        
        if last_check_str:
            try:
                last_check = datetime.fromisoformat(last_check_str.replace('Z', '+00:00'))
                if timezone.is_naive(last_check):
                    last_check = timezone.make_aware(last_check)
                return last_check
            except (ValueError, TypeError):
                pass
        
        return None
    
    def get_check_count(self, service_id: int) -> int:
        """Get the number of times a service has been checked."""
        counter_key = self._get_cache_key(service_id, self.CHECK_COUNTER_PREFIX)
        return cache.get(counter_key, 0)
    
    def clear_service_cache(self, service_id: int) -> None:
        """Clear all cached data for a specific service."""
        health_key = self._get_cache_key(service_id, self.HEALTH_CACHE_PREFIX)
        last_check_key = self._get_cache_key(service_id, self.LAST_CHECK_PREFIX)
        counter_key = self._get_cache_key(service_id, self.CHECK_COUNTER_PREFIX)
        
        cache.delete_many([health_key, last_check_key, counter_key])
        logger.info(f"Cleared cache for service {service_id}")
    
    def clear_all_cache(self) -> None:
        """Clear all health check cache."""
        # This is a simple implementation. In production, you might want
        # to use cache.clear() or iterate through known keys
        logger.warning("Clearing all health check cache - implement based on cache backend")
        # cache.clear()  # Uncomment if you want to clear entire cache
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        # This would need to be implemented based on your cache backend
        # For now, return basic info
        return {
            'cache_backend': cache.__class__.__name__,
            'intervals': {
                'online': f"{self.ONLINE_INTERVAL}s ({self.ONLINE_INTERVAL//60}min)",
                'offline_user': f"{self.OFFLINE_USER_INTERVAL}s ({self.OFFLINE_USER_INTERVAL//60}min)",
                'offline_system': f"{self.OFFLINE_SYSTEM_INTERVAL}s"
            }
        }
    
    def get_service_cache_info(self, service_id: int) -> Dict[str, Any]:
        """Get cache information for a specific service."""
        cached_health = self.get_cached_health(service_id)
        last_check = self.get_last_check_time(service_id)
        check_count = self.get_check_count(service_id)
        
        if cached_health:
            cached_at_str = cached_health.get('_cached_at')
            expires_at_str = cached_health.get('_expires_at')
            
            try:
                cached_at = datetime.fromisoformat(cached_at_str.replace('Z', '+00:00'))
                expires_at = datetime.fromisoformat(expires_at_str.replace('Z', '+00:00'))
                if timezone.is_naive(cached_at):
                    cached_at = timezone.make_aware(cached_at)
                if timezone.is_naive(expires_at):
                    expires_at = timezone.make_aware(expires_at)
                
                age = (timezone.now() - cached_at).total_seconds()
                ttl = (expires_at - timezone.now()).total_seconds()
                
                return {
                    'service_id': service_id,
                    'has_cache': True,
                    'status': cached_health.get('status'),
                    'cached_at': cached_at.isoformat(),
                    'expires_at': expires_at.isoformat(),
                    'age_seconds': int(age),
                    'ttl_seconds': max(0, int(ttl)),
                    'cache_interval': cached_health.get('_cache_interval'),
                    'was_user_request': cached_health.get('_is_user_request'),
                    'last_check': last_check.isoformat() if last_check else None,
                    'check_count': check_count
                }
            except (ValueError, TypeError):
                pass
        
        return {
            'service_id': service_id,
            'has_cache': False,
            'last_check': last_check.isoformat() if last_check else None,
            'check_count': check_count
        }


# Global instance
health_cache = HealthCheckCacheService()