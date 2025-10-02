"""
Views for the federated imputation system.
"""
import logging
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.views import APIView
from rest_framework.authentication import SessionAuthentication
from django.shortcuts import get_object_or_404
from django.http import HttpResponse, Http404
from django.db.models import Q
from django.views.generic import TemplateView
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User, Group, Permission
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.utils import timezone
from .services.cache_service import health_cache
from .models import (
    ImputationService, ReferencePanel, ImputationJob,
    JobStatusUpdate, ResultFile, UserServiceAccess, UserRole, UserProfile,
    ServicePermission, ServiceUserGroup, ServiceUserGroupMembership, AuditLog
)
from .serializers import (
    ImputationServiceSerializer, ReferencePanelSerializer,
    ImputationJobListSerializer, ImputationJobDetailSerializer,
    ImputationJobCreateSerializer, JobStatusUpdateSerializer,
    ResultFileSerializer, UserServiceAccessSerializer,
    ServiceSyncSerializer, JobActionSerializer,
    UserRoleSerializer, UserProfileSerializer, UserSerializer,
    UserCreateSerializer, UserUpdateSerializer, ServicePermissionSerializer,
    ServiceUserGroupSerializer, ServiceUserGroupCreateSerializer,
    AuditLogSerializer
)

# Advanced job management imports
from .job_management import JobTemplate, JobBatch, ScheduledJob, JobManager
from .pagination import StandardResultsSetPagination, ImputationJobFilter
from .performance import CacheManager, monitor_performance
from .monitoring import SystemMetrics, HealthChecker, AlertManager, MonitoringDashboard
from .tasks import (
    submit_imputation_job, cancel_imputation_job,
    sync_service_reference_panels as sync_reference_panels
)

logger = logging.getLogger(__name__)


def log_audit_event(user, action, resource_type=None, resource_id=None, details=None, request=None):
    """Helper function to log audit events."""
    try:
        AuditLog.objects.create(
            user=user,
            action=action,
            resource_type=resource_type,
            resource_id=str(resource_id) if resource_id else '',
            details=details or {},
            ip_address=request.META.get('REMOTE_ADDR') if request else None,
            user_agent=request.META.get('HTTP_USER_AGENT') if request else None
        )
    except Exception as e:
        logger.error(f"Failed to log audit event: {e}")


class CsrfExemptSessionAuthentication(SessionAuthentication):
    """
    SessionAuthentication that bypasses CSRF checks.
    Use this for API endpoints that need session auth but not CSRF protection.
    """
    def enforce_csrf(self, request):
        return  # Skip CSRF check


class IsAdminUser(permissions.BasePermission):
    """Custom permission to allow access only to admin users."""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.profile.is_admin() if hasattr(request.user, 'profile') else request.user.is_superuser


class IsServiceAdmin(permissions.BasePermission):
    """Custom permission to allow access only to service administrators."""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.profile.is_service_admin() if hasattr(request.user, 'profile') else False


class CanManageUsers(permissions.BasePermission):
    """Custom permission to allow access only to users who can manage other users."""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.profile.can_manage_users() if hasattr(request.user, 'profile') else request.user.is_superuser


class CanViewAllJobs(permissions.BasePermission):
    """Custom permission to allow viewing all jobs."""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.profile.can_view_all_jobs() if hasattr(request.user, 'profile') else request.user.is_superuser


class ImputationServiceViewSet(viewsets.ModelViewSet):
    """Enhanced ViewSet for comprehensive ImputationService CRUD operations."""

    authentication_classes = [CsrfExemptSessionAuthentication]
    serializer_class = ImputationServiceSerializer

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['list', 'retrieve']:
            permission_classes = [permissions.AllowAny]
        elif self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [permissions.IsAuthenticated, IsAdminUser]
        else:
            permission_classes = [permissions.IsAuthenticated]

        return [permission() for permission in permission_classes]

    def get_queryset(self):
        """Get imputation services with filtering options."""
        queryset = ImputationService.objects.all()

        # Filter by active status (default: active only for non-admin users)
        if not (self.request.user.is_authenticated and self.request.user.is_staff):
            queryset = queryset.filter(is_active=True)
        else:
            # Admin users can see all services
            is_active = self.request.query_params.get('is_active')
            if is_active is not None:
                queryset = queryset.filter(is_active=is_active.lower() == 'true')

        # Filter by service type
        service_type = self.request.query_params.get('service_type')
        if service_type:
            queryset = queryset.filter(service_type=service_type)

        # Filter by API type
        api_type = self.request.query_params.get('api_type')
        if api_type:
            queryset = queryset.filter(api_type=api_type)

        # Search by name or description
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) | Q(description__icontains=search)
            )

        return queryset.order_by('name')
    
    @action(detail=True, methods=['post'])
    def sync_reference_panels(self, request, pk=None):
        """Sync reference panels from external service."""
        service = self.get_object()
        serializer = ServiceSyncSerializer(data={'service_id': service.id})
        
        if serializer.is_valid():
            # Trigger async task
            task = sync_reference_panels.delay(service.id)
            
            return Response({
                'message': f'Reference panel sync started for {service.name}',
                'task_id': task.id
            }, status=status.HTTP_202_ACCEPTED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['get'])
    def reference_panels(self, request, pk=None):
        """Get reference panels for a specific service."""
        service = self.get_object()
        panels = service.reference_panels.filter(is_active=True)
        
        # Filter by population if provided
        population = request.query_params.get('population')
        if population:
            panels = panels.filter(population__icontains=population)
        
        # Filter by build if provided
        build = request.query_params.get('build')
        if build:
            panels = panels.filter(build=build)
        
        serializer = ReferencePanelSerializer(panels, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def health(self, request, pk=None):
        """Check the health status of a specific service with intelligent caching."""
        service = self.get_object()
        
        # Determine if this is a user-initiated request or system-initiated
        # User-initiated requests typically have specific headers or query params
        force_check = request.query_params.get('force', '').lower() in ['true', '1', 'yes']
        is_user_request = request.user.is_authenticated or force_check
        
        # Check cache first
        if not force_check:
            should_check, cached_data = health_cache.should_check_health(service.id, is_user_request)
            if not should_check and cached_data:
                # Return cached data with additional metadata
                response_data = dict(cached_data)
                # Remove internal cache metadata from response
                for key in list(response_data.keys()):
                    if key.startswith('_'):
                        del response_data[key]
                
                # Add cache metadata for debugging
                cache_info = health_cache.get_service_cache_info(service.id)
                response_data['cache_info'] = {
                    'from_cache': True,
                    'cached_at': cache_info.get('cached_at'),
                    'age_seconds': cache_info.get('age_seconds'),
                    'ttl_seconds': cache_info.get('ttl_seconds')
                }
                
                logger.debug(f"Returning cached health for service {service.id}: {response_data.get('status')}")
                return Response(response_data, status=status.HTTP_200_OK)
        
        # Perform actual health check
        health_data = self._perform_health_check(service)
        
        # Cache the result
        health_cache.set_cached_health(service.id, health_data, is_user_request)
        
        # Add cache metadata
        health_data['cache_info'] = {
            'from_cache': False,
            'just_checked': True,
            'is_user_request': is_user_request
        }
        
        return Response(health_data, status=status.HTTP_200_OK)
    
    def _perform_health_check(self, service):
        """Perform the actual health check without caching logic."""
        try:
            import requests
            from requests.exceptions import RequestException, Timeout, ConnectionError
            
            # Determine the appropriate health check URL
            test_url = service.api_url
            
            if service.api_type == 'ga4gh':
                # GA4GH WES services have a service-info endpoint
                test_url = f"{service.api_url.rstrip('/')}/service-info"
            elif service.api_type == 'michigan':
                # Michigan Imputation Server - use API endpoint for proper API response
                test_url = f"{service.api_url.rstrip('/')}/api/"
            elif service.api_type == 'dnastack':
                # DNAstack services - test root URL  
                test_url = service.api_url
            
            # Suppress SSL warnings for demo services
            import urllib3
            urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
            
            # Perform the actual health check with timeout
            response = requests.get(
                test_url,
                timeout=10,  # 10 second timeout
                verify=False,  # Skip SSL verification for demo services
                allow_redirects=True,
                headers={'User-Agent': 'Federated-Imputation-Platform/1.0'}
            )
            
            # Check if the response indicates the service is healthy
            if response.status_code in [200, 201, 202]:
                return {
                    'service_id': service.id,
                    'service_name': service.name,
                    'status': 'healthy',
                    'message': f'Service responded with HTTP {response.status_code}',
                    'test_url': test_url,
                    'response_time_ms': int(response.elapsed.total_seconds() * 1000)
                }
            elif service.api_type == 'michigan' and response.status_code == 401:
                # For Michigan services, HTTP 401 (Unauthorized) indicates the API is online and functioning
                return {
                    'service_id': service.id,
                    'service_name': service.name,
                    'status': 'healthy',
                    'message': f'Michigan API responded with HTTP {response.status_code} (API online, authentication required)',
                    'test_url': test_url,
                    'response_time_ms': int(response.elapsed.total_seconds() * 1000),
                    'api_response': 'Unauthorized - API is functioning properly'
                }
            else:
                return {
                    'service_id': service.id,
                    'service_name': service.name,
                    'status': 'unhealthy',
                    'message': f'Service responded with HTTP {response.status_code}',
                    'test_url': test_url,
                    'error': f'HTTP_{response.status_code}'
                }
            
        except Timeout:
            logger.error(f"Timeout checking {service.name} at {test_url}")
            return {
                'service_id': service.id,
                'service_name': service.name,
                'status': 'unhealthy',
                'message': 'Service request timed out (10s)',
                'test_url': test_url,
                'error': 'Timeout'
            }
            
        except ConnectionError:
            # For demo services, provide more informative messages
            if 'elwazi' in service.api_url.lower() or 'icermali' in service.api_url.lower():
                message = 'Demo service - not currently accessible (expected for development)'
                health_status = 'demo'
            else:
                message = 'Unable to connect to service'
                health_status = 'unhealthy'
            
            logger.warning(f"Connection error checking {service.name} at {test_url} - {message}")
            return {
                'service_id': service.id,
                'service_name': service.name,
                'status': health_status,
                'message': message,
                'test_url': test_url,
                'error': 'ConnectionError',
                'note': 'This is expected for demo/development services'
            }
            
        except RequestException as exc:
            logger.error(f"Request error checking {service.name} at {test_url}: {exc}")
            return {
                'service_id': service.id,
                'service_name': service.name,
                'status': 'unhealthy',
                'message': f'Request failed: {str(exc)}',
                'test_url': test_url,
                'error': 'RequestException'
            }
            
        except Exception as exc:
            logger.error(f"Unexpected error checking {service.name} at {test_url}: {exc}")
            return {
                'service_id': service.id,
                'service_name': service.name,
                'status': 'unhealthy',
                'message': f'Unexpected error: {str(exc)}',
                'test_url': test_url,
                'error': type(exc).__name__
            }
    
    @action(detail=True, methods=['get'])
    def cache_info(self, request, pk=None):
        """Get cache information for a specific service."""
        service = self.get_object()
        cache_info = health_cache.get_service_cache_info(service.id)
        
        return Response({
            'service_id': service.id,
            'service_name': service.name,
            'cache_info': cache_info
        })
    
    @action(detail=True, methods=['post'])
    def clear_cache(self, request, pk=None):
        """Clear cache for a specific service."""
        service = self.get_object()
        health_cache.clear_service_cache(service.id)
        
        log_audit_event(
            request.user,
            'clear_cache',
            'ImputationService',
            service.id,
            {'service_name': service.name},
            request
        )
        
        return Response({
            'message': f'Cache cleared for {service.name}',
            'service_id': service.id
        })
    
    @action(detail=False, methods=['get'])
    def cache_stats(self, request):
        """Get global cache statistics."""
        stats = health_cache.get_cache_stats()
        
        return Response({
            'cache_stats': stats,
            'timestamp': timezone.now().isoformat()
        })
    
    @action(detail=False, methods=['post'])
    def clear_all_cache(self, request):
        """Clear all health check cache (admin only)."""
        if not request.user.is_authenticated or not (
            request.user.is_superuser or 
            (hasattr(request.user, 'profile') and request.user.profile.is_admin())
        ):
            return Response(
                {'error': 'Admin privileges required'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        health_cache.clear_all_cache()
        
        log_audit_event(
            request.user,
            'clear_all_cache',
            'HealthCheckCache',
            None,
            {'action': 'clear_all_health_cache'},
            request
        )
        
        return Response({'message': 'All health check cache cleared'})
    
    @action(detail=False, methods=['get'])
    def health_all(self, request):
        """Check the health status of all services."""
        from django.utils import timezone
        
        results = {}
        
        for service in self.get_queryset():
            try:
                from .services import get_service_instance
                service_instance = get_service_instance(service.id)
                
                # Try to get service info as a health check
                service_info = service_instance.get_service_info()
                
                results[service.id] = {
                    'service_name': service.name,
                    'status': 'healthy',
                    'message': 'Service is responsive'
                }
                
            except Exception as exc:
                logger.error(f"Health check failed for {service.name}: {exc}")
                results[service.id] = {
                    'service_name': service.name,
                    'status': 'unhealthy',
                    'message': str(exc),
                    'error': type(exc).__name__
                }
        
        return Response({
            'timestamp': timezone.now().isoformat(),
            'services': results
        })

    def create(self, request, *args, **kwargs):
        """Create a new imputation service with validation."""
        try:
            # Validate required fields
            required_fields = ['name', 'service_type', 'api_type', 'api_url']
            for field in required_fields:
                if not request.data.get(field):
                    return Response(
                        {'error': f'Field "{field}" is required'},
                        status=status.HTTP_400_BAD_REQUEST
                    )

            # Check for duplicate service names
            if ImputationService.objects.filter(name=request.data.get('name')).exists():
                return Response(
                    {'error': 'A service with this name already exists'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Validate API URL format
            api_url = request.data.get('api_url')
            if not (api_url.startswith('http://') or api_url.startswith('https://')):
                return Response(
                    {'error': 'API URL must start with http:// or https://'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Create the service
            serializer = self.get_serializer(data=request.data)
            if serializer.is_valid():
                service = serializer.save()

                # Log the creation
                AuditLog.objects.create(
                    user=request.user,
                    action='create',
                    resource_type='service',
                    resource_id=str(service.id),
                    details=f'Created service: {service.name}'
                )

                return Response(
                    {
                        'message': f'Service "{service.name}" created successfully',
                        'service': serializer.data
                    },
                    status=status.HTTP_201_CREATED
                )
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            logger.error(f"Error creating service: {e}")
            return Response(
                {'error': 'Failed to create service'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def update(self, request, *args, **kwargs):
        """Update an existing imputation service."""
        try:
            partial = kwargs.pop('partial', False)
            instance = self.get_object()

            # Check if name is being changed and if it conflicts
            new_name = request.data.get('name')
            if new_name and new_name != instance.name:
                if ImputationService.objects.filter(name=new_name).exclude(id=instance.id).exists():
                    return Response(
                        {'error': 'A service with this name already exists'},
                        status=status.HTTP_400_BAD_REQUEST
                    )

            # Validate API URL if being updated
            api_url = request.data.get('api_url')
            if api_url and not (api_url.startswith('http://') or api_url.startswith('https://')):
                return Response(
                    {'error': 'API URL must start with http:// or https://'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            serializer = self.get_serializer(instance, data=request.data, partial=partial)
            if serializer.is_valid():
                service = serializer.save()

                # Log the update
                AuditLog.objects.create(
                    user=request.user,
                    action='update',
                    resource_type='service',
                    resource_id=str(service.id),
                    details=f'Updated service: {service.name}'
                )

                return Response(
                    {
                        'message': f'Service "{service.name}" updated successfully',
                        'service': serializer.data
                    }
                )
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            logger.error(f"Error updating service: {e}")
            return Response(
                {'error': 'Failed to update service'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def destroy(self, request, *args, **kwargs):
        """Soft delete a service (mark as inactive) or hard delete if no dependencies."""
        try:
            instance = self.get_object()

            # Check for dependencies
            active_jobs = ImputationJob.objects.filter(service=instance, status__in=['pending', 'queued', 'running']).count()
            if active_jobs > 0:
                return Response(
                    {'error': f'Cannot delete service with {active_jobs} active jobs. Please wait for jobs to complete or cancel them first.'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Check if force delete is requested
            force_delete = request.query_params.get('force', 'false').lower() == 'true'

            if force_delete:
                # Hard delete
                service_name = instance.name
                instance.delete()

                # Log the deletion
                AuditLog.objects.create(
                    user=request.user,
                    action='delete',
                    resource_type='service',
                    resource_id=str(instance.id),
                    details=f'Permanently deleted service: {service_name}'
                )

                return Response(
                    {'message': f'Service "{service_name}" permanently deleted'},
                    status=status.HTTP_204_NO_CONTENT
                )
            else:
                # Soft delete (mark as inactive)
                instance.is_active = False
                instance.save()

                # Log the soft deletion
                AuditLog.objects.create(
                    user=request.user,
                    action='deactivate',
                    resource_type='service',
                    resource_id=str(instance.id),
                    details=f'Deactivated service: {instance.name}'
                )

                return Response(
                    {'message': f'Service "{instance.name}" deactivated successfully'},
                    status=status.HTTP_200_OK
                )

        except Exception as e:
            logger.error(f"Error deleting service: {e}")
            return Response(
                {'error': 'Failed to delete service'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def bulk_create(self, request):
        """Create multiple services in bulk."""
        try:
            services_data = request.data.get('services', [])
            if not services_data:
                return Response(
                    {'error': 'No services data provided'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            created_services = []
            errors = []

            for i, service_data in enumerate(services_data):
                try:
                    # Validate required fields
                    required_fields = ['name', 'service_type', 'api_type', 'api_url']
                    for field in required_fields:
                        if not service_data.get(field):
                            errors.append(f'Service {i+1}: Field "{field}" is required')
                            continue

                    # Check for duplicate names
                    if ImputationService.objects.filter(name=service_data.get('name')).exists():
                        errors.append(f'Service {i+1}: A service with name "{service_data.get("name")}" already exists')
                        continue

                    # Create service
                    serializer = self.get_serializer(data=service_data)
                    if serializer.is_valid():
                        service = serializer.save()
                        created_services.append(serializer.data)

                        # Log creation
                        AuditLog.objects.create(
                            user=request.user,
                            action='create',
                            resource_type='service',
                            resource_id=str(service.id),
                            details=f'Bulk created service: {service.name}'
                        )
                    else:
                        errors.append(f'Service {i+1}: {serializer.errors}')

                except Exception as e:
                    errors.append(f'Service {i+1}: {str(e)}')

            return Response({
                'created_services': created_services,
                'created_count': len(created_services),
                'errors': errors,
                'error_count': len(errors)
            }, status=status.HTTP_201_CREATED if created_services else status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            logger.error(f"Error in bulk create: {e}")
            return Response(
                {'error': 'Failed to bulk create services'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['patch'])
    def bulk_update(self, request):
        """Update multiple services in bulk."""
        try:
            updates = request.data.get('updates', [])
            if not updates:
                return Response(
                    {'error': 'No updates provided'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            updated_services = []
            errors = []

            for update in updates:
                try:
                    service_id = update.get('id')
                    if not service_id:
                        errors.append('Service ID is required for each update')
                        continue

                    service = ImputationService.objects.get(id=service_id)
                    serializer = self.get_serializer(service, data=update.get('data', {}), partial=True)

                    if serializer.is_valid():
                        service = serializer.save()
                        updated_services.append(serializer.data)

                        # Log update
                        AuditLog.objects.create(
                            user=request.user,
                            action='update',
                            resource_type='service',
                            resource_id=str(service.id),
                            details=f'Bulk updated service: {service.name}'
                        )
                    else:
                        errors.append(f'Service {service_id}: {serializer.errors}')

                except ImputationService.DoesNotExist:
                    errors.append(f'Service with ID {service_id} not found')
                except Exception as e:
                    errors.append(f'Service {service_id}: {str(e)}')

            return Response({
                'updated_services': updated_services,
                'updated_count': len(updated_services),
                'errors': errors,
                'error_count': len(errors)
            })

        except Exception as e:
            logger.error(f"Error in bulk update: {e}")
            return Response(
                {'error': 'Failed to bulk update services'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['delete'])
    def bulk_delete(self, request):
        """Delete multiple services in bulk."""
        try:
            service_ids = request.data.get('service_ids', [])
            force_delete = request.data.get('force_delete', False)

            if not service_ids:
                return Response(
                    {'error': 'No service IDs provided'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            deleted_services = []
            deactivated_services = []
            errors = []

            for service_id in service_ids:
                try:
                    service = ImputationService.objects.get(id=service_id)

                    # Check for active jobs
                    active_jobs = ImputationJob.objects.filter(
                        service=service,
                        status__in=['pending', 'queued', 'running']
                    ).count()

                    if active_jobs > 0 and not force_delete:
                        errors.append(f'Service {service_id}: Has {active_jobs} active jobs')
                        continue

                    if force_delete:
                        service_name = service.name
                        service.delete()
                        deleted_services.append({'id': service_id, 'name': service_name})

                        # Log deletion
                        AuditLog.objects.create(
                            user=request.user,
                            action='delete',
                            resource_type='service',
                            resource_id=str(service_id),
                            details=f'Bulk deleted service: {service_name}'
                        )
                    else:
                        service.is_active = False
                        service.save()
                        deactivated_services.append({'id': service_id, 'name': service.name})

                        # Log deactivation
                        AuditLog.objects.create(
                            user=request.user,
                            action='deactivate',
                            resource_type='service',
                            resource_id=str(service.id),
                            details=f'Bulk deactivated service: {service.name}'
                        )

                except ImputationService.DoesNotExist:
                    errors.append(f'Service with ID {service_id} not found')
                except Exception as e:
                    errors.append(f'Service {service_id}: {str(e)}')

            return Response({
                'deleted_services': deleted_services,
                'deactivated_services': deactivated_services,
                'deleted_count': len(deleted_services),
                'deactivated_count': len(deactivated_services),
                'errors': errors,
                'error_count': len(errors)
            })

        except Exception as e:
            logger.error(f"Error in bulk delete: {e}")
            return Response(
                {'error': 'Failed to bulk delete services'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ReferencePanelViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for ReferencePanel operations."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    serializer_class = ReferencePanelSerializer
    permission_classes = [permissions.AllowAny]
    
    def get_queryset(self):
        """Get active reference panels."""
        queryset = ReferencePanel.objects.filter(is_active=True).select_related('service')
        
        # Filter by service if provided
        service_id = self.request.query_params.get('service')
        if service_id:
            queryset = queryset.filter(service_id=service_id)
        
        # Filter by population if provided
        population = self.request.query_params.get('population')
        if population:
            queryset = queryset.filter(population__icontains=population)
        
        # Filter by build if provided
        build = self.request.query_params.get('build')
        if build:
            queryset = queryset.filter(build=build)
        
        return queryset


class ImputationJobViewSet(viewsets.ModelViewSet):
    """ViewSet for ImputationJob operations."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    serializer_class = ImputationJobListSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Get jobs based on user permissions."""
        if hasattr(self.request.user, 'profile') and self.request.user.profile.can_view_all_jobs():
            queryset = ImputationJob.objects.all()
        else:
            queryset = ImputationJob.objects.filter(user=self.request.user)
        
        queryset = queryset.select_related(
            'user', 'service', 'reference_panel'
        ).prefetch_related('status_updates', 'files')
        
        # Filter by status if provided
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by service if provided
        service_id = self.request.query_params.get('service')
        if service_id:
            queryset = queryset.filter(service_id=service_id)
        
        # Search by name or description
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) | Q(description__icontains=search)
            )
        
        return queryset.order_by('-created_at')
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action."""
        if self.action == 'create':
            return ImputationJobCreateSerializer
        elif self.action in ['retrieve', 'update', 'partial_update']:
            return ImputationJobDetailSerializer
        else:
            return ImputationJobListSerializer
    
    def perform_create(self, serializer):
        """Create a new imputation job and submit it."""
        job = serializer.save()
        
        # Submit job asynchronously
        submit_imputation_job.delay(str(job.id))
        
        logger.info(f"Created and submitted imputation job {job.id} for user {job.user.username}")
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel a job."""
        job = self.get_object()
        serializer = JobActionSerializer(
            data={'action': 'cancel'},
            context={'job': job}
        )
        
        if serializer.is_valid():
            # Trigger async cancellation
            task = cancel_imputation_job.delay(str(job.id))
            
            return Response({
                'message': f'Cancellation requested for job {job.name}',
                'task_id': task.id
            }, status=status.HTTP_202_ACCEPTED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def retry(self, request, pk=None):
        """Retry a failed job."""
        job = self.get_object()
        serializer = JobActionSerializer(
            data={'action': 'retry'},
            context={'job': job}
        )
        
        if serializer.is_valid():
            # Reset job status and resubmit
            job.status = 'pending'
            job.progress_percentage = 0
            job.error_message = ''
            job.external_job_id = ''
            job.save()
            
            # Submit job asynchronously
            task = submit_imputation_job.delay(str(job.id))
            
            return Response({
                'message': f'Job {job.name} resubmitted',
                'task_id': task.id
            }, status=status.HTTP_202_ACCEPTED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['get'])
    def status_updates(self, request, pk=None):
        """Get status updates for a job."""
        job = self.get_object()
        updates = job.status_updates.all()
        serializer = JobStatusUpdateSerializer(updates, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def files(self, request, pk=None):
        """Get result files for a job."""
        job = self.get_object()
        files = job.files.filter(is_available=True)
        serializer = ResultFileSerializer(files, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'], url_path='files/(?P<file_id>[^/.]+)/download')
    def download_file(self, request, pk=None, file_id=None):
        """Download a result file."""
        job = self.get_object()
        
        try:
            result_file = job.files.get(id=file_id, is_available=True)
            
            if result_file.download_url:
                # Redirect to external download URL
                return Response({
                    'download_url': result_file.download_url,
                    'filename': result_file.filename,
                    'file_size': result_file.file_size
                })
            elif result_file.file_path:
                # Serve local file
                try:
                    with open(result_file.file_path, 'rb') as f:
                        response = HttpResponse(
                            f.read(),
                            content_type='application/octet-stream'
                        )
                        response['Content-Disposition'] = f'attachment; filename="{result_file.filename}"'
                        return response
                except FileNotFoundError:
                    return Response({
                        'error': 'File not found on server'
                    }, status=status.HTTP_404_NOT_FOUND)
            else:
                return Response({
                    'error': 'No download method available for this file'
                }, status=status.HTTP_404_NOT_FOUND)
                
        except ResultFile.DoesNotExist:
            return Response({
                'error': 'File not found'
            }, status=status.HTTP_404_NOT_FOUND)


class JobStatusUpdateViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for JobStatusUpdate operations."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    serializer_class = JobStatusUpdateSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Get status updates for jobs owned by the current user."""
        return JobStatusUpdate.objects.filter(
            job__user=self.request.user
        ).select_related('job').order_by('-timestamp')


class ResultFileViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for ResultFile operations."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    serializer_class = ResultFileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Get result files for jobs owned by the current user."""
        return ResultFile.objects.filter(
            job__user=self.request.user,
            is_available=True
        ).select_related('job').order_by('-created_at')
    
    @action(detail=True, methods=['get'])
    def download(self, request, pk=None):
        """Download a result file."""
        result_file = self.get_object()
        
        if result_file.download_url:
            # Redirect to external download URL
            return Response({
                'download_url': result_file.download_url,
                'filename': result_file.filename,
                'file_size': result_file.file_size
            })
        elif result_file.file_path:
            # Serve local file
            try:
                with open(result_file.file_path, 'rb') as f:
                    response = HttpResponse(
                        f.read(),
                        content_type='application/octet-stream'
                    )
                    response['Content-Disposition'] = f'attachment; filename="{result_file.filename}"'
                    return response
            except FileNotFoundError:
                return Response({
                    'error': 'File not found on server'
                }, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({
                'error': 'No download method available for this file'
            }, status=status.HTTP_404_NOT_FOUND)


class UserServiceAccessViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for UserServiceAccess operations."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    serializer_class = UserServiceAccessSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Get service access for the current user."""
        return UserServiceAccess.objects.filter(
            user=self.request.user
        ).select_related('user', 'service')


class DashboardViewSet(viewsets.ViewSet):
    """ViewSet for dashboard statistics and overview with enhanced error handling."""

    authentication_classes = [CsrfExemptSessionAuthentication]
    permission_classes = [permissions.AllowAny]  # Temporarily allow any for development

    def _get_default_stats(self):
        """Return default stats when data is unavailable."""
        return {
            'job_stats': {
                'total': 0,
                'completed': 0,
                'running': 0,
                'failed': 0,
                'success_rate': 0
            },
            'service_stats': {
                'available_services': 0,
                'accessible_services': 0
            },
            'recent_jobs': [],
            'status': 'fallback',
            'message': 'Using default values due to data unavailability'
        }

    def _get_safe_count(self, queryset, description="query"):
        """Safely get count from queryset with error handling."""
        try:
            return queryset.count()
        except Exception as e:
            logger.error(f"Error executing {description}: {e}")
            return 0

    def _get_safe_data(self, queryset, serializer_class, description="data"):
        """Safely serialize queryset data with error handling."""
        try:
            return serializer_class(queryset, many=True).data
        except Exception as e:
            logger.error(f"Error serializing {description}: {e}")
            return []

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get dashboard statistics with comprehensive error handling and fallbacks."""
        try:
            user = request.user if request.user.is_authenticated else None

            # Initialize default values
            total_jobs = completed_jobs = running_jobs = failed_jobs = 0
            recent_jobs_data = []
            user_services = 0
            available_services = 0

            # Job statistics with error handling
            if user:
                try:
                    jobs = ImputationJob.objects.filter(user=user)
                    total_jobs = self._get_safe_count(jobs, "total jobs")
                    completed_jobs = self._get_safe_count(
                        jobs.filter(status='completed'), "completed jobs"
                    )
                    running_jobs = self._get_safe_count(
                        jobs.filter(status__in=['pending', 'queued', 'running']), "running jobs"
                    )
                    failed_jobs = self._get_safe_count(
                        jobs.filter(status='failed'), "failed jobs"
                    )

                    # Recent jobs with error handling
                    try:
                        recent_jobs = jobs.order_by('-created_at')[:5]
                        recent_jobs_data = self._get_safe_data(
                            recent_jobs, ImputationJobListSerializer, "recent jobs"
                        )
                    except Exception as e:
                        logger.error(f"Error fetching recent jobs: {e}")
                        recent_jobs_data = []

                    # User services with error handling
                    try:
                        user_services = self._get_safe_count(
                            UserServiceAccess.objects.filter(user=user, has_access=True),
                            "user services"
                        )
                    except Exception as e:
                        logger.error(f"Error fetching user services: {e}")
                        user_services = 0

                except Exception as e:
                    logger.error(f"Error fetching user job statistics: {e}")
                    # Keep default values (0) for all stats

            # Service statistics (available to all) with error handling
            try:
                available_services = self._get_safe_count(
                    ImputationService.objects.filter(is_active=True),
                    "available services"
                )
            except Exception as e:
                logger.error(f"Error fetching available services: {e}")
                available_services = 0

            # Calculate success rate safely
            success_rate = 0
            if total_jobs > 0:
                try:
                    success_rate = round((completed_jobs / total_jobs * 100), 2)
                except (ZeroDivisionError, TypeError):
                    success_rate = 0

            response_data = {
                'job_stats': {
                    'total': total_jobs,
                    'completed': completed_jobs,
                    'running': running_jobs,
                    'failed': failed_jobs,
                    'success_rate': success_rate
                },
                'service_stats': {
                    'available_services': available_services,
                    'accessible_services': user_services
                },
                'recent_jobs': recent_jobs_data,
                'status': 'success',
                'timestamp': timezone.now().isoformat()
            }

            return Response(response_data)

        except Exception as e:
            logger.error(f"Critical error in dashboard stats: {e}")
            # Return fallback data with error indication
            fallback_data = self._get_default_stats()
            fallback_data['error'] = str(e)
            fallback_data['timestamp'] = timezone.now().isoformat()

            return Response(
                fallback_data,
                status=status.HTTP_200_OK  # Return 200 with fallback data
            )
    
    @action(detail=False, methods=['get'])
    def services_overview(self, request):
        """Get overview of all active services with enhanced error handling."""
        try:
            services = ImputationService.objects.filter(is_active=True)
            services_data = []

            for service in services:
                try:
                    # Safely get reference panels
                    active_panels = ReferencePanel.objects.filter(
                        service=service,
                        is_active=True
                    )

                    # Safely extract populations and builds
                    populations = []
                    builds = []

                    try:
                        populations = list(
                            active_panels.values_list('population', flat=True).distinct()
                        )
                    except Exception as e:
                        logger.error(f"Error fetching populations for service {service.id}: {e}")

                    try:
                        builds = list(
                            active_panels.values_list('build', flat=True).distinct()
                        )
                    except Exception as e:
                        logger.error(f"Error fetching builds for service {service.id}: {e}")

                    # Safely construct service data
                    service_data = {
                        'id': service.id,
                        'name': getattr(service, 'name', 'Unknown Service'),
                        'description': getattr(service, 'description', ''),
                        'is_active': getattr(service, 'is_active', False),
                        'api_url': getattr(service, 'api_url', ''),
                        'supported_formats': getattr(service, 'supported_formats', []),
                        'max_file_size_mb': getattr(service, 'max_file_size_mb', 0),
                        'populations': populations,
                        'builds': builds,
                        'reference_panels_count': self._get_safe_count(active_panels, f"panels for service {service.id}")
                    }

                    services_data.append(service_data)

                except Exception as e:
                    logger.error(f"Error processing service {service.id}: {e}")
                    # Add minimal service data on error
                    services_data.append({
                        'id': getattr(service, 'id', 0),
                        'name': getattr(service, 'name', 'Error Loading Service'),
                        'description': 'Error loading service details',
                        'is_active': False,
                        'api_url': '',
                        'supported_formats': [],
                        'max_file_size_mb': 0,
                        'populations': [],
                        'builds': [],
                        'reference_panels_count': 0,
                        'error': str(e)
                    })

            return Response({
                'services': services_data,
                'count': len(services_data),
                'status': 'success',
                'timestamp': timezone.now().isoformat()
            })

        except Exception as e:
            logger.error(f"Critical error in services overview: {e}")
            return Response({
                'services': [],
                'count': 0,
                'status': 'error',
                'error': str(e),
                'timestamp': timezone.now().isoformat()
            }, status=status.HTTP_200_OK)  # Return 200 with error info

    @action(detail=False, methods=['get'])
    def health(self, request):
        """Get dashboard health status and system information."""
        try:
            health_data = {
                'status': 'healthy',
                'timestamp': timezone.now().isoformat(),
                'checks': {},
                'services': {},
                'database': {},
                'errors': []
            }

            # Database connectivity check
            try:
                from django.db import connection
                with connection.cursor() as cursor:
                    cursor.execute("SELECT 1")
                    health_data['checks']['database'] = 'healthy'
                    health_data['database']['connection'] = 'active'
            except Exception as e:
                health_data['checks']['database'] = 'unhealthy'
                health_data['database']['connection'] = 'failed'
                health_data['errors'].append(f"Database: {str(e)}")
                health_data['status'] = 'degraded'

            # Service availability check
            try:
                active_services = ImputationService.objects.filter(is_active=True).count()
                total_services = ImputationService.objects.count()
                health_data['services'] = {
                    'active': active_services,
                    'total': total_services,
                    'status': 'healthy' if active_services > 0 else 'warning'
                }
                health_data['checks']['services'] = 'healthy' if active_services > 0 else 'warning'

                if active_services == 0:
                    health_data['errors'].append("No active services available")
                    health_data['status'] = 'degraded'

            except Exception as e:
                health_data['checks']['services'] = 'unhealthy'
                health_data['services']['status'] = 'error'
                health_data['errors'].append(f"Services: {str(e)}")
                health_data['status'] = 'unhealthy'

            # Reference panels check
            try:
                active_panels = ReferencePanel.objects.filter(is_active=True).count()
                health_data['checks']['reference_panels'] = 'healthy' if active_panels > 0 else 'warning'
                health_data['database']['reference_panels'] = active_panels

                if active_panels == 0:
                    health_data['errors'].append("No active reference panels available")
                    if health_data['status'] == 'healthy':
                        health_data['status'] = 'degraded'

            except Exception as e:
                health_data['checks']['reference_panels'] = 'unhealthy'
                health_data['errors'].append(f"Reference panels: {str(e)}")
                health_data['status'] = 'unhealthy'

            # Overall status determination
            if len(health_data['errors']) == 0:
                health_data['status'] = 'healthy'
            elif any('unhealthy' in check for check in health_data['checks'].values()):
                health_data['status'] = 'unhealthy'
            else:
                health_data['status'] = 'degraded'

            return Response(health_data)

        except Exception as e:
            logger.error(f"Critical error in dashboard health check: {e}")
            return Response({
                'status': 'unhealthy',
                'timestamp': timezone.now().isoformat(),
                'error': str(e),
                'checks': {},
                'services': {},
                'database': {}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class IndexView(TemplateView):
    """Serve the React frontend application."""
    template_name = 'imputation/index.html'


class TestView(APIView):
    """Simple test endpoint."""
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        return Response({'message': 'API is working!', 'method': 'GET'})
    
    def post(self, request):
        return Response({'message': 'API is working!', 'method': 'POST', 'data': request.data})


class LoginView(APIView):
    """API view for user login."""
    authentication_classes = [CsrfExemptSessionAuthentication]
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        
        if not username or not password:
            return Response(
                {'error': 'Username and password are required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user = authenticate(request, username=username, password=password)
        if user:
            login(request, user)
            return Response({
                'user': {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                },
                'message': 'Login successful'
            })
        else:
            return Response(
                {'error': 'Invalid username or password'}, 
                status=status.HTTP_401_UNAUTHORIZED
            )


class LogoutView(APIView):
    """API view for user logout."""
    authentication_classes = [CsrfExemptSessionAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        logout(request)
        return Response({'message': 'Logout successful'})


class UserInfoView(APIView):
    """API view to get current user information."""
    authentication_classes = [CsrfExemptSessionAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user

        # Get user profile information if available
        profile_data = {}
        if hasattr(user, 'profile') and user.profile:
            profile = user.profile
            profile_data = {
                'role': profile.role.name if profile.role else None,
                'organization': profile.organization,
                'department': profile.department,
                'position': profile.position,
                'research_area': profile.research_area,
                'institution': profile.institution,
                'country': profile.country,
            }

        return Response({
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'is_staff': user.is_staff,
                'is_superuser': user.is_superuser,
                'date_joined': user.date_joined.isoformat() if user.date_joined else None,
                'last_login': user.last_login.isoformat() if user.last_login else None,
                'profile': profile_data,
            },
            'authenticated': True,
            'session_id': request.session.session_key,
        })


class UserRoleViewSet(viewsets.ModelViewSet):
    """ViewSet for managing user roles."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    serializer_class = UserRoleSerializer
    permission_classes = [IsAdminUser]
    
    def get_queryset(self):
        """Get all active roles."""
        return UserRole.objects.filter(is_active=True)
    
    def perform_create(self, serializer):
        """Create role and log audit event."""
        role = serializer.save()
        log_audit_event(
            self.request.user,
            'create_role',
            'UserRole',
            role.id,
            {'role_name': role.name},
            self.request
        )
    
    def perform_update(self, serializer):
        """Update role and log audit event."""
        role = serializer.save()
        log_audit_event(
            self.request.user,
            'update_role',
            'UserRole',
            role.id,
            {'role_name': role.name},
            self.request
        )
    
    def perform_destroy(self, instance):
        """Delete role and log audit event."""
        role_name = instance.name
        instance.delete()
        log_audit_event(
            self.request.user,
            'delete_role',
            'UserRole',
            None,
            {'role_name': role_name},
            self.request
        )


class UserViewSet(viewsets.ModelViewSet):
    """ViewSet for managing users."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    permission_classes = [CanManageUsers]
    
    def get_queryset(self):
        """Get users based on permissions."""
        if self.request.user.profile.can_manage_users():
            return User.objects.all()
        return User.objects.filter(id=self.request.user.id)
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action."""
        if self.action == 'create':
            return UserCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return UserUpdateSerializer
        return UserSerializer
    
    def perform_create(self, serializer):
        """Create user and log audit event."""
        user = serializer.save()
        log_audit_event(
            self.request.user,
            'create_user',
            'User',
            user.id,
            {'username': user.username, 'email': user.email},
            self.request
        )
    
    def perform_update(self, serializer):
        """Update user and log audit event."""
        user = serializer.save()
        log_audit_event(
            self.request.user,
            'update_user',
            'User',
            user.id,
            {'username': user.username},
            self.request
        )
    
    def perform_destroy(self, instance):
        """Delete user and log audit event."""
        username = instance.username
        instance.delete()
        log_audit_event(
            self.request.user,
            'delete_user',
            'User',
            None,
            {'username': username},
            self.request
        )
    
    @action(detail=True, methods=['post'])
    def reset_password(self, request, pk=None):
        """Reset user password."""
        user = self.get_object()
        new_password = request.data.get('new_password')
        
        if not new_password:
            return Response(
                {'error': 'New password is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user.set_password(new_password)
        user.save()
        
        log_audit_event(
            request.user,
            'reset_password',
            'User',
            user.id,
            {'username': user.username},
            request
        )
        
        return Response({'message': 'Password reset successfully'})
    
    @action(detail=True, methods=['post'])
    def toggle_active(self, request, pk=None):
        """Toggle user active status."""
        user = self.get_object()
        user.is_active = not user.is_active
        user.save()
        
        log_audit_event(
            request.user,
            'toggle_user_active',
            'User',
            user.id,
            {'username': user.username, 'is_active': user.is_active},
            request
        )
        
        return Response({
            'message': f'User {"activated" if user.is_active else "deactivated"} successfully',
            'is_active': user.is_active
        })


class UserProfileViewSet(viewsets.ModelViewSet):
    """ViewSet for managing user profiles."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Get profiles based on permissions."""
        if self.request.user.profile.can_manage_users():
            return UserProfile.objects.all()
        return UserProfile.objects.filter(user=self.request.user)
    
    def perform_update(self, serializer):
        """Update profile and log audit event."""
        profile = serializer.save()
        log_audit_event(
            self.request.user,
            'update_profile',
            'UserProfile',
            profile.id,
            {'username': profile.user.username},
            self.request
        )
    
    @action(detail=True, methods=['post'])
    def reset_quota(self, request, pk=None):
        """Reset user quota usage."""
        profile = self.get_object()
        profile.reset_monthly_usage()
        
        log_audit_event(
            request.user,
            'reset_quota',
            'UserProfile',
            profile.id,
            {'username': profile.user.username},
            request
        )
        
        return Response({'message': 'Quota reset successfully'})
    
    @action(detail=True, methods=['post'])
    def verify_user(self, request, pk=None):
        """Verify user account."""
        profile = self.get_object()
        profile.is_verified = True
        profile.verification_date = timezone.now()
        profile.save()
        
        log_audit_event(
            request.user,
            'verify_user',
            'UserProfile',
            profile.id,
            {'username': profile.user.username},
            request
        )
        
        return Response({'message': 'User verified successfully'})


class ServicePermissionViewSet(viewsets.ModelViewSet):
    """ViewSet for managing service permissions."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    serializer_class = ServicePermissionSerializer
    permission_classes = [IsServiceAdmin]
    
    def get_queryset(self):
        """Get permissions for the current service."""
        service_id = self.kwargs.get('service_pk')
        return ServicePermission.objects.filter(service_id=service_id)
    
    def get_serializer_context(self):
        """Add service to serializer context."""
        context = super().get_serializer_context()
        context['service'] = get_object_or_404(ImputationService, pk=self.kwargs.get('service_pk'))
        return context
    
    def perform_create(self, serializer):
        """Create permission and log audit event."""
        permission = serializer.save()
        log_audit_event(
            self.request.user,
            'grant_permission',
            'ServicePermission',
            permission.id,
            {
                'service': permission.service.name,
                'user': permission.user.username,
                'permission': permission.permission
            },
            self.request
        )
    
    def perform_destroy(self, instance):
        """Delete permission and log audit event."""
        service_name = instance.service.name
        username = instance.user.username
        perm_name = instance.permission
        instance.delete()
        
        log_audit_event(
            self.request.user,
            'revoke_permission',
            'ServicePermission',
            None,
            {
                'service': service_name,
                'user': username,
                'permission': perm_name
            },
            self.request
        )


class ServiceUserGroupViewSet(viewsets.ModelViewSet):
    """ViewSet for managing service user groups."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    permission_classes = [IsServiceAdmin]
    
    def get_queryset(self):
        """Get groups for the current service."""
        service_id = self.kwargs.get('service_pk')
        return ServiceUserGroup.objects.filter(service_id=service_id)
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action."""
        if self.action == 'create':
            return ServiceUserGroupCreateSerializer
        return ServiceUserGroupSerializer
    
    def get_serializer_context(self):
        """Add service to serializer context."""
        context = super().get_serializer_context()
        context['service'] = get_object_or_404(ImputationService, pk=self.kwargs.get('service_pk'))
        return context
    
    def perform_create(self, serializer):
        """Create group and log audit event."""
        group = serializer.save()
        log_audit_event(
            self.request.user,
            'create_group',
            'ServiceUserGroup',
            group.id,
            {
                'service': group.service.name,
                'group_name': group.name
            },
            self.request
        )
    
    def perform_destroy(self, instance):
        """Delete group and log audit event."""
        service_name = instance.service.name
        group_name = instance.name
        instance.delete()
        
        log_audit_event(
            self.request.user,
            'delete_group',
            'ServiceUserGroup',
            None,
            {
                'service': service_name,
                'group_name': group_name
            },
            self.request
        )
    
    @action(detail=True, methods=['post'])
    def add_user(self, request, pk=None, service_pk=None):
        """Add user to group."""
        group = self.get_object()
        user_id = request.data.get('user_id')
        permissions = request.data.get('permissions', [])
        
        try:
            user = User.objects.get(id=user_id)
            membership = group.add_user(user, permissions)
            
            log_audit_event(
                request.user,
                'add_user_to_group',
                'ServiceUserGroup',
                group.id,
                {
                    'service': group.service.name,
                    'group_name': group.name,
                    'username': user.username
                },
                request
            )
            
            return Response({'message': f'User {user.username} added to group'})
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(detail=True, methods=['post'])
    def remove_user(self, request, pk=None, service_pk=None):
        """Remove user from group."""
        group = self.get_object()
        user_id = request.data.get('user_id')
        
        try:
            user = User.objects.get(id=user_id)
            group.remove_user(user)
            
            log_audit_event(
                request.user,
                'remove_user_from_group',
                'ServiceUserGroup',
                group.id,
                {
                    'service': group.service.name,
                    'group_name': group.name,
                    'username': user.username
                },
                request
            )
            
            return Response({'message': f'User {user.username} removed from group'})
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for viewing audit logs."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    serializer_class = AuditLogSerializer
    permission_classes = [IsAdminUser]
    
    def get_queryset(self):
        """Get audit logs with optional filtering."""
        queryset = AuditLog.objects.all()
        
        # Filter by user
        user_id = self.request.query_params.get('user_id')
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        
        # Filter by action
        action = self.request.query_params.get('action')
        if action:
            queryset = queryset.filter(action=action)
        
        # Filter by date range
        start_date = self.request.query_params.get('start_date')
        if start_date:
            queryset = queryset.filter(timestamp__gte=start_date)
        
        end_date = self.request.query_params.get('end_date')
        if end_date:
            queryset = queryset.filter(timestamp__lte=end_date)
        
        return queryset


# Monitoring and Observability Views

class SystemMetricsView(APIView):
    """API view for system metrics"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Get current system metrics"""
        try:
            metrics = SystemMetrics.get_system_metrics()
            return Response(metrics)
        except Exception as e:
            return Response(
                {'error': f'Failed to get system metrics: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class HealthCheckView(APIView):
    """API view for health checks"""
    permission_classes = []  # Allow unauthenticated access for monitoring tools

    def get(self, request):
        """Perform comprehensive health check"""
        try:
            health_status = HealthChecker.check_system_health()

            # Return appropriate HTTP status based on health
            if health_status['overall_status'] == 'critical':
                http_status = status.HTTP_503_SERVICE_UNAVAILABLE
            elif health_status['overall_status'] in ['error', 'warning']:
                http_status = status.HTTP_200_OK  # Still operational
            else:
                http_status = status.HTTP_200_OK

            return Response(health_status, status=http_status)
        except Exception as e:
            return Response(
                {
                    'overall_status': 'error',
                    'error': f'Health check failed: {str(e)}',
                    'timestamp': timezone.now().isoformat()
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MonitoringDashboardView(APIView):
    """API view for monitoring dashboard data with enhanced error handling"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Get comprehensive dashboard data with fallback mechanisms"""
        try:
            # Try to get full dashboard data
            dashboard_data = MonitoringDashboard.get_dashboard_data()

            # Validate the response
            if not dashboard_data or 'error' in dashboard_data:
                raise Exception("Invalid dashboard data received")

            # Add success status
            dashboard_data['status'] = 'success'
            dashboard_data['timestamp'] = timezone.now().isoformat()

            return Response(dashboard_data)

        except Exception as e:
            logger.error(f"Error getting monitoring dashboard data: {e}")

            # Return fallback data
            fallback_data = {
                'status': 'fallback',
                'error': str(e),
                'timestamp': timezone.now().isoformat(),
                'system_metrics': {
                    'cpu_percent': 0,
                    'memory_percent': 0,
                    'disk_percent': 0,
                    'error': 'System metrics unavailable'
                },
                'database_metrics': {
                    'active_connections': 0,
                    'database_size': 'Unknown',
                    'error': 'Database metrics unavailable'
                },
                'application_metrics': {
                    'jobs': {'total': 0, 'recent_24h': 0},
                    'services': {'active': 0, 'total': 0},
                    'error': 'Application metrics unavailable'
                },
                'health_status': {
                    'overall_status': 'unknown',
                    'checks': {},
                    'error': 'Health status unavailable'
                },
                'recent_alerts': []
            }

            return Response(
                fallback_data,
                status=status.HTTP_200_OK  # Return 200 with fallback data
            )