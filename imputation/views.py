"""
Django REST Framework views for the imputation app.
"""
import logging
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.http import HttpResponse, Http404
from django.db.models import Q
from django.views.generic import TemplateView
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from .models import (
    ImputationService, ReferencePanel, ImputationJob,
    JobStatusUpdate, ResultFile, UserServiceAccess
)
from .serializers import (
    ImputationServiceSerializer, ReferencePanelSerializer,
    ImputationJobListSerializer, ImputationJobDetailSerializer,
    ImputationJobCreateSerializer, JobStatusUpdateSerializer,
    ResultFileSerializer, UserServiceAccessSerializer,
    ServiceSyncSerializer, JobActionSerializer
)
from .tasks import (
    submit_imputation_job, cancel_imputation_job,
    sync_service_reference_panels
)

logger = logging.getLogger(__name__)


class ImputationServiceViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for ImputationService operations."""
    
    serializer_class = ImputationServiceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
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
            task = sync_service_reference_panels.delay(service.id)
            
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


class ReferencePanelViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for ReferencePanel operations."""
    
    serializer_class = ReferencePanelSerializer
    permission_classes = [permissions.IsAuthenticated]
    
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
    
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_queryset(self):
        """Get jobs for the current user."""
        queryset = ImputationJob.objects.filter(user=self.request.user).select_related(
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
    
    serializer_class = JobStatusUpdateSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Get status updates for jobs owned by the current user."""
        return JobStatusUpdate.objects.filter(
            job__user=self.request.user
        ).select_related('job').order_by('-timestamp')


class ResultFileViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for ResultFile operations."""
    
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
    
    serializer_class = UserServiceAccessSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Get service access for the current user."""
        return UserServiceAccess.objects.filter(
            user=self.request.user
        ).select_related('user', 'service')


class DashboardViewSet(viewsets.ViewSet):
    """ViewSet for dashboard statistics and overview."""
    
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


@method_decorator(csrf_exempt, name='dispatch')
class LoginView(APIView):
    """API view for user login."""
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


@method_decorator(csrf_exempt, name='dispatch')
class LogoutView(APIView):
    """API view for user logout."""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        logout(request)
        return Response({'message': 'Logout successful'})


class UserInfoView(APIView):
    """API view to get current user information."""
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