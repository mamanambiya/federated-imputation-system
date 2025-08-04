"""
Django models for the federated imputation system.
"""
from django.db import models
from django.contrib.auth.models import User, Group, Permission
from django.contrib.contenttypes.models import ContentType
from django.utils import timezone
from django.core.exceptions import ValidationError
import uuid


class UserRole(models.Model):
    """Model representing user roles in the system."""
    
    ROLE_CHOICES = [
        ('admin', 'Administrator'),
        ('service_admin', 'Service Administrator'),
        ('researcher', 'Researcher'),
        ('service_user', 'Service User'),
        ('viewer', 'Viewer'),
    ]
    
    name = models.CharField(max_length=50, choices=ROLE_CHOICES, unique=True)
    description = models.TextField(blank=True)
    permissions = models.ManyToManyField(Permission, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['name']
    
    def __str__(self):
        return self.get_name_display()
    
    def get_permissions_list(self):
        """Get list of permission codenames for this role."""
        return list(self.permissions.values_list('codename', flat=True))


class UserProfile(models.Model):
    """Extended user profile with role and additional information."""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    role = models.ForeignKey(UserRole, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Personal information
    organization = models.CharField(max_length=200, blank=True)
    department = models.CharField(max_length=200, blank=True)
    position = models.CharField(max_length=100, blank=True)
    phone = models.CharField(max_length=20, blank=True)
    
    # Research information
    research_area = models.CharField(max_length=200, blank=True)
    institution = models.CharField(max_length=200, blank=True)
    country = models.CharField(max_length=100, blank=True)
    
    # System preferences
    preferred_language = models.CharField(max_length=10, default='en')
    timezone = models.CharField(max_length=50, default='UTC')
    email_notifications = models.BooleanField(default=True)
    
    # Account status
    is_verified = models.BooleanField(default=False)
    verification_date = models.DateTimeField(null=True, blank=True)
    last_activity = models.DateTimeField(null=True, blank=True)
    
    # Quota and limits
    monthly_job_limit = models.IntegerField(default=10)
    monthly_jobs_used = models.IntegerField(default=0)
    storage_limit_gb = models.DecimalField(max_digits=10, decimal_places=2, default=1.0)
    storage_used_gb = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['user__username']
    
    def __str__(self):
        return f"{self.user.username} - {self.role.name if self.role else 'No Role'}"
    
    def has_permission(self, permission_codename):
        """Check if user has a specific permission through their role."""
        if not self.role or not self.role.is_active:
            return False
        return self.role.permissions.filter(codename=permission_codename).exists()
    
    def has_role(self, role_name):
        """Check if user has a specific role."""
        return self.role and self.role.name == role_name
    
    def is_admin(self):
        """Check if user is an administrator."""
        return self.has_role('admin')
    
    def is_service_admin(self):
        """Check if user is a service administrator."""
        return self.has_role('service_admin')
    
    def can_manage_services(self):
        """Check if user can manage services."""
        return (self.is_admin() or self.is_service_admin() or 
                self.has_permission('add_imputationservice') or 
                self.has_permission('change_imputationservice'))
    
    def can_view_all_jobs(self):
        """Check if user can view all jobs (not just their own)."""
        return (self.is_admin() or self.is_service_admin() or 
                self.has_permission('view_all_jobs'))
    
    def can_manage_users(self):
        """Check if user can manage other users."""
        return (self.is_admin() or 
                self.has_permission('add_user') or 
                self.has_permission('change_user'))
    
    def update_activity(self):
        """Update last activity timestamp."""
        self.last_activity = timezone.now()
        self.save(update_fields=['last_activity'])
    
    def reset_monthly_usage(self):
        """Reset monthly usage counters."""
        self.monthly_jobs_used = 0
        self.storage_used_gb = 0.0
        self.save(update_fields=['monthly_jobs_used', 'storage_used_gb'])
    
    def increment_job_usage(self):
        """Increment job usage counter."""
        self.monthly_jobs_used += 1
        self.save(update_fields=['monthly_jobs_used'])
    
    def add_storage_usage(self, size_gb):
        """Add to storage usage."""
        self.storage_used_gb += size_gb
        self.save(update_fields=['storage_used_gb'])
    
    def has_quota_available(self):
        """Check if user has quota available for new jobs."""
        return self.monthly_jobs_used < self.monthly_job_limit
    
    def get_quota_percentage(self):
        """Get percentage of quota used."""
        if self.monthly_job_limit == 0:
            return 0
        return (self.monthly_jobs_used / self.monthly_job_limit) * 100


class ServicePermission(models.Model):
    """Model for service-specific permissions."""
    
    PERMISSION_CHOICES = [
        ('view', 'View Service'),
        ('submit_jobs', 'Submit Jobs'),
        ('view_jobs', 'View Jobs'),
        ('manage_jobs', 'Manage Jobs'),
        ('admin', 'Admin Service'),
    ]
    
    service = models.ForeignKey('ImputationService', on_delete=models.CASCADE, related_name='permissions')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='service_permissions')
    permission = models.CharField(max_length=20, choices=PERMISSION_CHOICES)
    granted_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='granted_permissions')
    granted_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        unique_together = ['service', 'user', 'permission']
        ordering = ['service', 'user', 'permission']
    
    def __str__(self):
        return f"{self.user.username} - {self.service.name} - {self.get_permission_display()}"
    
    def is_valid(self):
        """Check if permission is still valid (not expired)."""
        if not self.is_active:
            return False
        if self.expires_at and timezone.now() > self.expires_at:
            return False
        return True


class ServiceUserGroup(models.Model):
    """Model for managing groups of users with specific service access."""
    
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    service = models.ForeignKey('ImputationService', on_delete=models.CASCADE, related_name='user_groups')
    users = models.ManyToManyField(User, through='ServiceUserGroupMembership', related_name='service_groups')
    permissions = models.ManyToManyField(ServicePermission, blank=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='created_groups')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['name', 'service']
        ordering = ['service', 'name']
    
    def __str__(self):
        return f"{self.service.name} - {self.name}"
    
    def add_user(self, user, permissions=None):
        """Add a user to this group with optional permissions."""
        membership, created = ServiceUserGroupMembership.objects.get_or_create(
            group=self,
            user=user
        )
        if permissions:
            for perm in permissions:
                ServicePermission.objects.get_or_create(
                    service=self.service,
                    user=user,
                    permission=perm
                )
        return membership
    
    def remove_user(self, user):
        """Remove a user from this group."""
        ServiceUserGroupMembership.objects.filter(group=self, user=user).delete()
        # Also remove service permissions for this user and service
        ServicePermission.objects.filter(service=self.service, user=user).delete()


class ServiceUserGroupMembership(models.Model):
    """Through model for ServiceUserGroup and User relationship."""
    
    group = models.ForeignKey(ServiceUserGroup, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    joined_at = models.DateTimeField(auto_now_add=True)
    added_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='added_memberships')
    
    class Meta:
        unique_together = ['group', 'user']
    
    def __str__(self):
        return f"{self.user.username} in {self.group.name}"


class AuditLog(models.Model):
    """Model for tracking user actions and system events."""
    
    ACTION_CHOICES = [
        ('login', 'User Login'),
        ('logout', 'User Logout'),
        ('create_job', 'Create Job'),
        ('update_job', 'Update Job'),
        ('delete_job', 'Delete Job'),
        ('create_user', 'Create User'),
        ('update_user', 'Update User'),
        ('delete_user', 'Delete User'),
        ('grant_permission', 'Grant Permission'),
        ('revoke_permission', 'Revoke Permission'),
        ('service_access', 'Service Access'),
        ('data_access', 'Data Access'),
        ('system_config', 'System Configuration'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='audit_logs')
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)
    resource_type = models.CharField(max_length=50, blank=True)  # e.g., 'ImputationJob', 'User'
    resource_id = models.CharField(max_length=100, blank=True)  # ID of the affected resource
    details = models.JSONField(default=dict)  # Additional details about the action
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['user', 'action', 'timestamp']),
            models.Index(fields=['action', 'timestamp']),
            models.Index(fields=['resource_type', 'resource_id']),
        ]
    
    def __str__(self):
        return f"{self.user.username if self.user else 'System'} - {self.get_action_display()} - {self.timestamp}"


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
    continent = models.CharField(max_length=50, blank=True, help_text="Continent where the service is located")
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