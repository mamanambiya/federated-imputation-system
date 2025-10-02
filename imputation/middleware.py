# Security and Performance Middleware for Federated Genomic Imputation Platform

import time
import logging
import json
from django.http import JsonResponse
from django.core.cache import cache
from django.conf import settings
from django.utils.deprecation import MiddlewareMixin
from django.contrib.auth.models import AnonymousUser
from django.utils import timezone
from datetime import timedelta

logger = logging.getLogger(__name__)


class SecurityHeadersMiddleware(MiddlewareMixin):
    """
    Middleware to add security headers to all responses
    """
    
    def process_response(self, request, response):
        # Security headers
        response['X-Content-Type-Options'] = 'nosniff'
        response['X-Frame-Options'] = 'DENY'
        response['X-XSS-Protection'] = '1; mode=block'
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        
        # Content Security Policy
        csp_directives = [
            "default-src 'self'",
            "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
            "style-src 'self' 'unsafe-inline'",
            "img-src 'self' data: https:",
            "font-src 'self'",
            "connect-src 'self'",
            "frame-ancestors 'none'",
        ]
        response['Content-Security-Policy'] = '; '.join(csp_directives)
        
        # HSTS for HTTPS (only in production)
        if not settings.DEBUG and request.is_secure():
            response['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
        
        return response


class RateLimitMiddleware(MiddlewareMixin):
    """
    Simple rate limiting middleware
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        super().__init__(get_response)
    
    def process_request(self, request):
        # Skip rate limiting for certain paths
        skip_paths = ['/admin/', '/static/', '/media/']
        if any(request.path.startswith(path) for path in skip_paths):
            return None
        
        # Get client IP
        client_ip = self.get_client_ip(request)
        
        # Different limits for different endpoints
        if request.path.startswith('/api/auth/'):
            # Stricter limits for authentication endpoints
            limit = 10  # 10 requests per minute
            window = 60
        elif request.path.startswith('/api/'):
            # General API limits
            limit = 100  # 100 requests per minute
            window = 60
        else:
            # Frontend requests
            limit = 200  # 200 requests per minute
            window = 60
        
        # Check rate limit
        cache_key = f"rate_limit:{client_ip}:{request.path_info}"
        current_requests = cache.get(cache_key, 0)
        
        if current_requests >= limit:
            logger.warning(f"Rate limit exceeded for IP {client_ip} on {request.path}")
            return JsonResponse({
                'error': 'Rate limit exceeded',
                'detail': f'Maximum {limit} requests per {window} seconds allowed'
            }, status=429)
        
        # Increment counter
        cache.set(cache_key, current_requests + 1, window)
        
        return None
    
    def get_client_ip(self, request):
        """Get the client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class RequestLoggingMiddleware(MiddlewareMixin):
    """
    Middleware to log API requests for monitoring and debugging
    """
    
    def process_request(self, request):
        request.start_time = time.time()
        
        # Log API requests
        if request.path.startswith('/api/'):
            logger.info(f"API Request: {request.method} {request.path} from {self.get_client_ip(request)}")
    
    def process_response(self, request, response):
        # Calculate request duration
        if hasattr(request, 'start_time'):
            duration = time.time() - request.start_time
            
            # Log slow requests
            if duration > 2.0:  # Log requests taking more than 2 seconds
                logger.warning(f"Slow request: {request.method} {request.path} took {duration:.2f}s")
            
            # Add performance header
            response['X-Response-Time'] = f"{duration:.3f}s"
        
        # Log API responses
        if request.path.startswith('/api/'):
            status_code = response.status_code
            if status_code >= 400:
                logger.warning(f"API Error: {request.method} {request.path} returned {status_code}")
            elif status_code >= 300:
                logger.info(f"API Redirect: {request.method} {request.path} returned {status_code}")
        
        return response
    
    def get_client_ip(self, request):
        """Get the client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class HealthCheckMiddleware(MiddlewareMixin):
    """
    Middleware to handle health check requests
    """
    
    def process_request(self, request):
        if request.path == '/health/':
            return JsonResponse({
                'status': 'healthy',
                'timestamp': timezone.now().isoformat(),
                'version': getattr(settings, 'VERSION', '1.0.0'),
                'environment': getattr(settings, 'ENVIRONMENT', 'development')
            })
        
        if request.path == '/health/ready/':
            # Check if application is ready to serve requests
            try:
                from django.db import connection
                with connection.cursor() as cursor:
                    cursor.execute("SELECT 1")
                
                return JsonResponse({
                    'status': 'ready',
                    'timestamp': timezone.now().isoformat(),
                    'checks': {
                        'database': 'ok',
                        'cache': 'ok' if self._check_cache() else 'error'
                    }
                })
            except Exception as e:
                logger.error(f"Health check failed: {e}")
                return JsonResponse({
                    'status': 'not_ready',
                    'timestamp': timezone.now().isoformat(),
                    'error': str(e)
                }, status=503)
        
        return None
    
    def _check_cache(self):
        """Check if cache is working"""
        try:
            cache.set('health_check', 'ok', 10)
            return cache.get('health_check') == 'ok'
        except Exception:
            return False


class APIVersioningMiddleware(MiddlewareMixin):
    """
    Middleware to handle API versioning
    """
    
    def process_request(self, request):
        if request.path.startswith('/api/'):
            # Extract version from header or URL
            api_version = request.META.get('HTTP_API_VERSION', 'v1')
            
            # Validate version
            supported_versions = ['v1', 'v2']
            if api_version not in supported_versions:
                return JsonResponse({
                    'error': 'Unsupported API version',
                    'supported_versions': supported_versions
                }, status=400)
            
            # Add version to request
            request.api_version = api_version
        
        return None


class CORSSecurityMiddleware(MiddlewareMixin):
    """
    Enhanced CORS middleware with security considerations
    """
    
    def process_response(self, request, response):
        # Only add CORS headers for API endpoints
        if request.path.startswith('/api/'):
            origin = request.META.get('HTTP_ORIGIN')
            
            # Check if origin is allowed
            allowed_origins = getattr(settings, 'CORS_ALLOWED_ORIGINS', [])
            
            if origin in allowed_origins:
                response['Access-Control-Allow-Origin'] = origin
                response['Access-Control-Allow-Credentials'] = 'true'
                response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
                response['Access-Control-Allow-Headers'] = 'Accept, Content-Type, Authorization, X-CSRFToken, API-Version'
                response['Access-Control-Max-Age'] = '86400'  # 24 hours
            
            # Handle preflight requests
            if request.method == 'OPTIONS':
                response.status_code = 200
        
        return response


class AuditLoggingMiddleware(MiddlewareMixin):
    """
    Middleware to log important actions for audit purposes
    """
    
    def process_request(self, request):
        # Log authentication attempts
        if request.path.startswith('/api/auth/'):
            self._log_auth_attempt(request)
        
        # Log data modification attempts
        if request.method in ['POST', 'PUT', 'PATCH', 'DELETE'] and request.path.startswith('/api/'):
            self._log_data_modification(request)
    
    def _log_auth_attempt(self, request):
        """Log authentication attempts"""
        client_ip = self.get_client_ip(request)
        user_agent = request.META.get('HTTP_USER_AGENT', 'Unknown')
        
        logger.info(f"Auth attempt: {request.method} {request.path} from {client_ip} ({user_agent})")
    
    def _log_data_modification(self, request):
        """Log data modification attempts"""
        if not isinstance(request.user, AnonymousUser):
            client_ip = self.get_client_ip(request)
            logger.info(f"Data modification: {request.user.username} {request.method} {request.path} from {client_ip}")
    
    def get_client_ip(self, request):
        """Get the client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
