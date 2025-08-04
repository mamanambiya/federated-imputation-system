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
from .tasks import (
    submit_imputation_job, cancel_imputation_job,
    sync_reference_panels
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


class ImputationServiceViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for ImputationService operations."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    serializer_class = ImputationServiceSerializer
    permission_classes = [permissions.AllowAny]
    
    def get_queryset(self):
        """Get active imputation services."""
        return ImputationService.objects.filter(is_active=True)
    
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
        """Check the health status of a specific service."""
        service = self.get_object()
        
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
                return Response({
                    'service_id': service.id,
                    'service_name': service.name,
                    'status': 'healthy',
                    'message': f'Service responded with HTTP {response.status_code}',
                    'test_url': test_url,
                    'response_time_ms': int(response.elapsed.total_seconds() * 1000)
                }, status=status.HTTP_200_OK)
            elif service.api_type == 'michigan' and response.status_code == 401:
                # For Michigan services, HTTP 401 (Unauthorized) indicates the API is online and functioning
                return Response({
                    'service_id': service.id,
                    'service_name': service.name,
                    'status': 'healthy',
                    'message': f'Michigan API responded with HTTP {response.status_code} (API online, authentication required)',
                    'test_url': test_url,
                    'response_time_ms': int(response.elapsed.total_seconds() * 1000),
                    'api_response': 'Unauthorized - API is functioning properly'
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'service_id': service.id,
                    'service_name': service.name,
                    'status': 'unhealthy',
                    'message': f'Service responded with HTTP {response.status_code}',
                    'test_url': test_url,
                    'error': f'HTTP_{response.status_code}'
                }, status=status.HTTP_200_OK)  # Still return 200 but with unhealthy status
            
        except Timeout:
            logger.error(f"Timeout checking {service.name} at {test_url}")
            return Response({
                'service_id': service.id,
                'service_name': service.name,
                'status': 'unhealthy',
                'message': 'Service request timed out (10s)',
                'test_url': test_url,
                'error': 'Timeout'
            }, status=status.HTTP_200_OK)
            
        except ConnectionError:
            # For demo services, provide more informative messages
            if 'elwazi' in service.api_url.lower() or 'icermali' in service.api_url.lower():
                message = 'Demo service - not currently accessible (expected for development)'
                status = 'demo'
            else:
                message = 'Unable to connect to service'
                status = 'unhealthy'
            
            logger.warning(f"Connection error checking {service.name} at {test_url} - {message}")
            return Response({
                'service_id': service.id,
                'service_name': service.name,
                'status': status,
                'message': message,
                'test_url': test_url,
                'error': 'ConnectionError',
                'note': 'This is expected for demo/development services'
            }, status=status.HTTP_200_OK)
            
        except RequestException as exc:
            logger.error(f"Request error checking {service.name} at {test_url}: {exc}")
            return Response({
                'service_id': service.id,
                'service_name': service.name,
                'status': 'unhealthy',
                'message': f'Request failed: {str(exc)}',
                'test_url': test_url,
                'error': 'RequestException'
            }, status=status.HTTP_200_OK)
            
        except Exception as exc:
            logger.error(f"Unexpected error checking {service.name} at {test_url}: {exc}")
            return Response({
                'service_id': service.id,
                'service_name': service.name,
                'status': 'unhealthy',
                'message': f'Unexpected error: {str(exc)}',
                'test_url': test_url,
                'error': type(exc).__name__
            }, status=status.HTTP_200_OK)
    
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
    """ViewSet for dashboard statistics and overview."""
    
    authentication_classes = [CsrfExemptSessionAuthentication]
    permission_classes = [permissions.AllowAny]  # Temporarily allow any for development
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get dashboard statistics for the current user."""
        user = request.user if request.user.is_authenticated else None
        
        # Job statistics
        if user:
            jobs = ImputationJob.objects.filter(user=user)
            total_jobs = jobs.count()
            completed_jobs = jobs.filter(status='completed').count()
            running_jobs = jobs.filter(status__in=['pending', 'queued', 'running']).count()
            failed_jobs = jobs.filter(status='failed').count()
            
            # Recent jobs
            recent_jobs = jobs.order_by('-created_at')[:5]
            recent_jobs_data = ImputationJobListSerializer(recent_jobs, many=True).data
            
            # User services
            user_services = UserServiceAccess.objects.filter(
                user=user, has_access=True
            ).count()
        else:
            # For unauthenticated users, show global stats
            total_jobs = completed_jobs = running_jobs = failed_jobs = 0
            recent_jobs_data = []
            user_services = 0
        
        # Service statistics (available to all)
        available_services = ImputationService.objects.filter(is_active=True).count()
        
        return Response({
            'job_stats': {
                'total': total_jobs,
                'completed': completed_jobs,
                'running': running_jobs,
                'failed': failed_jobs,
                'success_rate': (completed_jobs / total_jobs * 100) if total_jobs > 0 else 0
            },
            'service_stats': {
                'available_services': available_services,
                'accessible_services': user_services
            },
            'recent_jobs': recent_jobs_data
        })
    
    @action(detail=False, methods=['get'])
    def services_overview(self, request):
        """Get overview of all active services with their capabilities."""
        services = ImputationService.objects.filter(is_active=True)
        services_data = []
        
        for service in services:
            active_panels = ReferencePanel.objects.filter(
                service=service, 
                is_active=True
            )
            
            services_data.append({
                'id': service.id,
                'name': service.name,
                'description': service.description,
                'is_active': service.is_active,
                'api_url': service.api_url,
                'supported_formats': service.supported_formats,
                'max_file_size_mb': service.max_file_size_mb,
                'populations': list(
                    active_panels.values_list('population', flat=True).distinct()
                ),
                'builds': list(
                    active_panels.values_list('build', flat=True).distinct()
                )
            })
        
        return Response(services_data)


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
        return Response({
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
            }
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