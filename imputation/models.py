"""
Django models for the federated imputation system.
"""
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
import uuid


class ImputationService(models.Model):
    """Model representing an external imputation service."""
    
    SERVICE_CHOICES = [
        ('h3africa', 'H3Africa Imputation Service'),
        ('michigan', 'Michigan Imputation Service'),
    ]
    
    API_TYPE_CHOICES = [
        ('michigan', 'Michigan Imputation Server API'),
        ('ga4gh', 'GA4GH Service Info'),
        ('dnastack', 'DNASTACK Omics API'),
    ]
    
    name = models.CharField(max_length=100, unique=True)
    service_type = models.CharField(max_length=20, choices=SERVICE_CHOICES)
    api_type = models.CharField(max_length=20, choices=API_TYPE_CHOICES, default='michigan')
    api_url = models.URLField()
    description = models.TextField(blank=True)
    location = models.CharField(max_length=200, blank=True, help_text="Geographic location or institution hosting the service")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Service-specific configuration
    api_key = models.CharField(max_length=255, blank=True, help_text="API key for authentication")
    api_key_required = models.BooleanField(default=True)
    max_file_size_mb = models.IntegerField(default=100)
    supported_formats = models.JSONField(default=list)  # ['vcf', 'plink', 'bgen']
    
    # API-specific configuration
    api_config = models.JSONField(default=dict, blank=True, help_text="Additional API-specific configuration")
    
    class Meta:
        ordering = ['name']
    
    def __str__(self):
        return self.name
    
    def get_service_info(self):
        """Get cached service info from api_config or fetch fresh data."""
        import requests
        from datetime import datetime, timedelta
        
        # Check if we have cached info that's less than 1 hour old
        if self.api_config and '_service_info' in self.api_config:
            cached_info = self.api_config['_service_info']
            if 'timestamp' in cached_info:
                timestamp = datetime.fromisoformat(cached_info['timestamp'])
                if datetime.now() - timestamp < timedelta(hours=1):
                    return cached_info.get('data', {})
        
        # Fetch fresh data
        if self.api_type == 'ga4gh':
            try:
                url = self.api_url
                if not url.endswith('/service-info'):
                    url = f"{url.rstrip('/')}/service-info"
                
                headers = {'Accept': 'application/json'}
                if self.api_key:
                    headers['Authorization'] = f'Bearer {self.api_key}'
                
                response = requests.get(url, headers=headers, timeout=10)
                if response.status_code == 200:
                    data = response.json()
                    
                    # Cache the response
                    if not self.api_config:
                        self.api_config = {}
                    self.api_config['_service_info'] = {
                        'timestamp': datetime.now().isoformat(),
                        'data': data
                    }
                    self.save()
                    
                    return data
            except Exception:
                pass
        
        return {}


class ReferencePanel(models.Model):
    """Model representing a reference panel available from an imputation service."""
    
    service = models.ForeignKey(ImputationService, on_delete=models.CASCADE, related_name='reference_panels')
    name = models.CharField(max_length=200)
    panel_id = models.CharField(max_length=100)  # Service-specific panel ID
    description = models.TextField(blank=True)
    population = models.CharField(max_length=100, blank=True)  # e.g., "African", "European", "Mixed"
    build = models.CharField(max_length=20, blank=True)  # e.g., "hg19", "hg38"
    samples_count = models.IntegerField(null=True, blank=True)
    variants_count = models.IntegerField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['service', 'name']
        unique_together = ['service', 'panel_id']
    
    def __str__(self):
        return f"{self.service.name} - {self.name}"


class ImputationJob(models.Model):
    """Model representing an imputation job submitted to a service."""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('queued', 'Queued'),
        ('running', 'Running'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
    ]
    
    # Job identification
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='imputation_jobs')
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    
    # Service and panel selection
    service = models.ForeignKey(ImputationService, on_delete=models.CASCADE)
    reference_panel = models.ForeignKey(ReferencePanel, on_delete=models.CASCADE)
    
    # Job configuration
    input_format = models.CharField(max_length=20, default='vcf')  # vcf, plink, bgen
    build = models.CharField(max_length=20, default='hg38')
    phasing = models.BooleanField(default=True)
    population = models.CharField(max_length=100, blank=True)
    
    # Job status and progress
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    progress_percentage = models.IntegerField(default=0)
    external_job_id = models.CharField(max_length=200, blank=True)  # Service-specific job ID
    
    # Authentication
    user_token = models.CharField(max_length=500, blank=True, help_text="User's authentication token for the service")
    
    # File management
    input_file = models.FileField(upload_to='uploads/input/', null=True, blank=True)
    input_file_size = models.BigIntegerField(null=True, blank=True)
    result_files = models.JSONField(default=list)  # List of result file URLs/paths
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    # Execution details
    execution_time_seconds = models.IntegerField(null=True, blank=True)
    error_message = models.TextField(blank=True)
    service_response = models.JSONField(default=dict)  # Store full service response
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} ({self.service.name})"
    
    @property
    def duration(self):
        """Calculate job duration if completed."""
        if self.started_at and self.completed_at:
            return self.completed_at - self.started_at
        elif self.started_at:
            return timezone.now() - self.started_at
        return None
    
    def update_status(self, status, progress=None, error_message=None):
        """Update job status and related fields."""
        self.status = status
        if progress is not None:
            self.progress_percentage = progress
        if error_message:
            self.error_message = error_message
        
        # Update timestamps
        if status == 'running' and not self.started_at:
            self.started_at = timezone.now()
        elif status in ['completed', 'failed', 'cancelled'] and not self.completed_at:
            self.completed_at = timezone.now()
            if self.started_at:
                self.execution_time_seconds = (self.completed_at - self.started_at).total_seconds()
        
        self.save()


class JobStatusUpdate(models.Model):
    """Model to track status updates for imputation jobs."""
    
    job = models.ForeignKey(ImputationJob, on_delete=models.CASCADE, related_name='status_updates')
    status = models.CharField(max_length=20)
    progress_percentage = models.IntegerField(default=0)
    message = models.TextField(blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    external_data = models.JSONField(default=dict)  # Additional data from service
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.job.name} - {self.status} ({self.progress_percentage}%)"


class ResultFile(models.Model):
    """Model representing a result file from an imputation job."""
    
    FILE_TYPE_CHOICES = [
        ('imputed_data', 'Imputed Data'),
        ('quality_report', 'Quality Report'),
        ('log_file', 'Log File'),
        ('summary', 'Summary'),
        ('metadata', 'Metadata'),
    ]
    
    job = models.ForeignKey(ImputationJob, on_delete=models.CASCADE, related_name='files')
    file_type = models.CharField(max_length=20, choices=FILE_TYPE_CHOICES)
    filename = models.CharField(max_length=255)
    file_path = models.CharField(max_length=500, blank=True)  # Local file path
    download_url = models.URLField(blank=True)  # External download URL
    file_size = models.BigIntegerField(null=True, blank=True)
    checksum = models.CharField(max_length=64, blank=True)  # MD5 or SHA256
    is_available = models.BooleanField(default=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['file_type', 'filename']
    
    def __str__(self):
        return f"{self.job.name} - {self.filename}"


class ServiceConfiguration(models.Model):
    """Model to store service-specific configuration and credentials."""
    
    service = models.OneToOneField(ImputationService, on_delete=models.CASCADE, related_name='configuration')
    api_key = models.CharField(max_length=500, blank=True)
    api_secret = models.CharField(max_length=500, blank=True)
    additional_headers = models.JSONField(default=dict)
    rate_limit_per_hour = models.IntegerField(default=100)
    timeout_seconds = models.IntegerField(default=300)
    retry_attempts = models.IntegerField(default=3)
    
    # Service-specific settings
    settings = models.JSONField(default=dict)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Config for {self.service.name}"


class UserServiceAccess(models.Model):
    """Model to manage user access to specific imputation services."""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='service_access')
    service = models.ForeignKey(ImputationService, on_delete=models.CASCADE)
    has_access = models.BooleanField(default=True)
    api_key = models.CharField(max_length=500, blank=True)  # User-specific API key
    quota_limit = models.IntegerField(null=True, blank=True)  # Jobs per month
    quota_used = models.IntegerField(default=0)
    last_used = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['user', 'service']
    
    def __str__(self):
        return f"{self.user.username} - {self.service.name}" 