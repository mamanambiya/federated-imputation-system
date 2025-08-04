"""
Serializers for the federated imputation system.
"""
from rest_framework import serializers
from django.contrib.auth.models import User, Group, Permission
from django.contrib.auth.password_validation import validate_password
from .models import (
    ImputationService, ReferencePanel, ImputationJob, JobStatusUpdate, 
    ResultFile, UserServiceAccess, UserRole, UserProfile, ServicePermission,
    ServiceUserGroup, ServiceUserGroupMembership, AuditLog
)


class PermissionSerializer(serializers.ModelSerializer):
    """Serializer for Django permissions."""
    
    class Meta:
        model = Permission
        fields = ['id', 'name', 'codename', 'content_type']


class UserRoleSerializer(serializers.ModelSerializer):
    """Serializer for user roles."""
    
    permissions = PermissionSerializer(many=True, read_only=True)
    permissions_list = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False
    )
    
    class Meta:
        model = UserRole
        fields = [
            'id', 'name', 'description', 'permissions', 'permissions_list',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def create(self, validated_data):
        permissions_list = validated_data.pop('permissions_list', [])
        role = UserRole.objects.create(**validated_data)
        
        if permissions_list:
            permissions = Permission.objects.filter(codename__in=permissions_list)
            role.permissions.set(permissions)
        
        return role
    
    def update(self, instance, validated_data):
        permissions_list = validated_data.pop('permissions_list', None)
        
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        if permissions_list is not None:
            permissions = Permission.objects.filter(codename__in=permissions_list)
            instance.permissions.set(permissions)
        
        return instance


class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for user profiles."""
    
    role = UserRoleSerializer(read_only=True)
    role_id = serializers.IntegerField(write_only=True, required=False, allow_null=True)
    quota_percentage = serializers.ReadOnlyField()
    
    class Meta:
        model = UserProfile
        fields = [
            'id', 'role', 'role_id', 'organization', 'department', 'position',
            'phone', 'research_area', 'institution', 'country',
            'preferred_language', 'timezone', 'email_notifications',
            'is_verified', 'verification_date', 'last_activity',
            'monthly_job_limit', 'monthly_jobs_used', 'storage_limit_gb',
            'storage_used_gb', 'quota_percentage', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'verification_date', 'last_activity', 'monthly_jobs_used',
            'storage_used_gb', 'quota_percentage', 'created_at', 'updated_at'
        ]
    
    def update(self, instance, validated_data):
        role_id = validated_data.pop('role_id', None)
        
        if role_id is not None:
            try:
                role = UserRole.objects.get(id=role_id)
                instance.role = role
            except UserRole.DoesNotExist:
                raise serializers.ValidationError("Invalid role ID")
        
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        return instance


class UserSerializer(serializers.ModelSerializer):
    """Serializer for Django User model."""
    
    profile = UserProfileSerializer(read_only=True)
    full_name = serializers.SerializerMethodField()
    groups = serializers.PrimaryKeyRelatedField(many=True, read_only=True)
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name', 'full_name',
            'is_active', 'is_staff', 'is_superuser', 'date_joined', 'last_login',
            'profile', 'groups'
        ]
        read_only_fields = ['id', 'date_joined', 'last_login']
    
    def get_full_name(self, obj):
        return obj.get_full_name()


class UserCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new users."""
    
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)
    profile = UserProfileSerializer(required=False)
    
    class Meta:
        model = User
        fields = [
            'username', 'email', 'first_name', 'last_name', 'password',
            'password_confirm', 'profile'
        ]
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError("Passwords don't match")
        return attrs
    
    def create(self, validated_data):
        password_confirm = validated_data.pop('password_confirm')
        profile_data = validated_data.pop('profile', {})
        
        user = User.objects.create_user(**validated_data)
        
        # Create user profile
        UserProfile.objects.create(user=user, **profile_data)
        
        return user


class UserUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating users."""
    
    profile = UserProfileSerializer(partial=True)
    
    class Meta:
        model = User
        fields = [
            'username', 'email', 'first_name', 'last_name', 'is_active',
            'is_staff', 'profile'
        ]
    
    def update(self, instance, validated_data):
        profile_data = validated_data.pop('profile', {})
        
        # Update user fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update profile
        if profile_data:
            profile_serializer = UserProfileSerializer(
                instance.profile, data=profile_data, partial=True
            )
            if profile_serializer.is_valid():
                profile_serializer.save()
        
        return instance


class ServicePermissionSerializer(serializers.ModelSerializer):
    """Serializer for service permissions."""
    
    user = UserSerializer(read_only=True)
    user_id = serializers.IntegerField(write_only=True)
    service = serializers.PrimaryKeyRelatedField(read_only=True)
    granted_by = UserSerializer(read_only=True)
    
    class Meta:
        model = ServicePermission
        fields = [
            'id', 'service', 'user', 'user_id', 'permission', 'granted_by',
            'granted_at', 'expires_at', 'is_active'
        ]
        read_only_fields = ['id', 'service', 'granted_by', 'granted_at']
    
    def create(self, validated_data):
        user_id = validated_data.pop('user_id')
        service = self.context['service']
        
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            raise serializers.ValidationError("Invalid user ID")
        
        # Check if permission already exists
        if ServicePermission.objects.filter(
            service=service, user=user, permission=validated_data['permission']
        ).exists():
            raise serializers.ValidationError("Permission already exists")
        
        return ServicePermission.objects.create(
            service=service,
            user=user,
            granted_by=self.context['request'].user,
            **validated_data
        )


class ServiceUserGroupMembershipSerializer(serializers.ModelSerializer):
    """Serializer for service user group memberships."""
    
    user = UserSerializer(read_only=True)
    user_id = serializers.IntegerField(write_only=True)
    added_by = UserSerializer(read_only=True)
    
    class Meta:
        model = ServiceUserGroupMembership
        fields = ['id', 'group', 'user', 'user_id', 'joined_at', 'added_by']
        read_only_fields = ['id', 'joined_at', 'added_by']


class ServiceUserGroupSerializer(serializers.ModelSerializer):
    """Serializer for service user groups."""
    
    users = UserSerializer(many=True, read_only=True)
    memberships = ServiceUserGroupMembershipSerializer(many=True, read_only=True)
    created_by = UserSerializer(read_only=True)
    service = serializers.PrimaryKeyRelatedField(read_only=True)
    
    class Meta:
        model = ServiceUserGroup
        fields = [
            'id', 'name', 'description', 'service', 'users', 'memberships',
            'created_by', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at']


class ServiceUserGroupCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating service user groups."""
    
    user_ids = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False
    )
    permissions = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False
    )
    
    class Meta:
        model = ServiceUserGroup
        fields = [
            'name', 'description', 'user_ids', 'permissions'
        ]
    
    def create(self, validated_data):
        user_ids = validated_data.pop('user_ids', [])
        permissions = validated_data.pop('permissions', [])
        service = self.context['service']
        
        group = ServiceUserGroup.objects.create(
            service=service,
            created_by=self.context['request'].user,
            **validated_data
        )
        
        # Add users to group
        for user_id in user_ids:
            try:
                user = User.objects.get(id=user_id)
                group.add_user(user, permissions)
            except User.DoesNotExist:
                continue
        
        return group


class AuditLogSerializer(serializers.ModelSerializer):
    """Serializer for audit logs."""
    
    user = UserSerializer(read_only=True)
    action_display = serializers.CharField(source='get_action_display', read_only=True)
    
    class Meta:
        model = AuditLog
        fields = [
            'id', 'user', 'action', 'action_display', 'resource_type',
            'resource_id', 'details', 'ip_address', 'user_agent', 'timestamp'
        ]
        read_only_fields = ['id', 'timestamp']


"""
Django REST Framework serializers for the imputation app.
"""
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import (
    ImputationService, ReferencePanel, ImputationJob,
    JobStatusUpdate, ResultFile, UserServiceAccess
)


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model."""
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']


class ImputationServiceSerializer(serializers.ModelSerializer):
    """Serializer for ImputationService model."""
    
    reference_panels_count = serializers.SerializerMethodField()
    
    class Meta:
        model = ImputationService
        fields = [
            'id', 'name', 'service_type', 'api_type', 'api_url', 'description', 'location', 'continent',
            'is_active', 'api_key_required', 'max_file_size_mb',
            'supported_formats', 'reference_panels_count', 'api_config', 
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_reference_panels_count(self, obj):
        """Get the count of active reference panels for this service."""
        return obj.reference_panels.filter(is_active=True).count()


class ReferencePanelSerializer(serializers.ModelSerializer):
    """Serializer for ReferencePanel model."""
    
    service_name = serializers.CharField(source='service.name', read_only=True)
    service_type = serializers.CharField(source='service.service_type', read_only=True)
    
    class Meta:
        model = ReferencePanel
        fields = [
            'id', 'name', 'panel_id', 'description', 'population', 'build',
            'samples_count', 'variants_count', 'is_active', 'service',
            'service_name', 'service_type', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class JobStatusUpdateSerializer(serializers.ModelSerializer):
    """Serializer for JobStatusUpdate model."""
    
    class Meta:
        model = JobStatusUpdate
        fields = [
            'id', 'status', 'progress_percentage', 'message', 
            'timestamp', 'external_data'
        ]
        read_only_fields = ['id', 'timestamp']


class ResultFileSerializer(serializers.ModelSerializer):
    """Serializer for ResultFile model."""
    
    file_size_display = serializers.SerializerMethodField()
    
    class Meta:
        model = ResultFile
        fields = [
            'id', 'file_type', 'filename', 'file_path', 'download_url',
            'file_size', 'file_size_display', 'checksum', 'is_available',
            'expires_at', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']
    
    def get_file_size_display(self, obj):
        """Get human-readable file size."""
        if obj.file_size:
            size = obj.file_size
            for unit in ['B', 'KB', 'MB', 'GB']:
                if size < 1024.0:
                    return f"{size:.1f} {unit}"
                size /= 1024.0
            return f"{size:.1f} TB"
        return "Unknown"


class ImputationJobListSerializer(serializers.ModelSerializer):
    """Serializer for ImputationJob list view."""
    
    user = UserSerializer(read_only=True)
    service = ImputationServiceSerializer(read_only=True)
    reference_panel = ReferencePanelSerializer(read_only=True)
    duration_display = serializers.SerializerMethodField()
    
    class Meta:
        model = ImputationJob
        fields = [
            'id', 'name', 'description', 'user', 'service', 'reference_panel',
            'input_format', 'build', 'phasing', 'population', 'status',
            'progress_percentage', 'external_job_id', 'created_at',
            'updated_at', 'started_at', 'completed_at', 'duration_display'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_duration_display(self, obj):
        """Get human-readable duration."""
        duration = obj.duration
        if duration:
            total_seconds = int(duration.total_seconds())
            hours, remainder = divmod(total_seconds, 3600)
            minutes, seconds = divmod(remainder, 60)
            if hours > 0:
                return f"{hours}h {minutes}m {seconds}s"
            elif minutes > 0:
                return f"{minutes}m {seconds}s"
            else:
                return f"{seconds}s"
        return None


class ImputationJobDetailSerializer(serializers.ModelSerializer):
    """Serializer for ImputationJob detail view."""
    
    user = UserSerializer(read_only=True)
    service = ImputationServiceSerializer(read_only=True)
    reference_panel = ReferencePanelSerializer(read_only=True)
    status_updates = JobStatusUpdateSerializer(many=True, read_only=True)
    files = ResultFileSerializer(many=True, read_only=True)
    duration_display = serializers.SerializerMethodField()
    input_file_size_display = serializers.SerializerMethodField()
    
    class Meta:
        model = ImputationJob
        fields = [
            'id', 'name', 'description', 'user', 'service', 'reference_panel',
            'input_format', 'build', 'phasing', 'population', 'status',
            'progress_percentage', 'external_job_id', 'input_file',
            'input_file_size', 'input_file_size_display', 'result_files',
            'created_at', 'updated_at', 'started_at', 'completed_at',
            'execution_time_seconds', 'duration_display', 'error_message',
            'service_response', 'status_updates', 'files'
        ]
        read_only_fields = [
            'id', 'user', 'status', 'progress_percentage', 'external_job_id',
            'created_at', 'updated_at', 'started_at', 'completed_at',
            'execution_time_seconds', 'error_message', 'service_response'
        ]
    
    def get_duration_display(self, obj):
        """Get human-readable duration."""
        duration = obj.duration
        if duration:
            total_seconds = int(duration.total_seconds())
            hours, remainder = divmod(total_seconds, 3600)
            minutes, seconds = divmod(remainder, 60)
            if hours > 0:
                return f"{hours}h {minutes}m {seconds}s"
            elif minutes > 0:
                return f"{minutes}m {seconds}s"
            else:
                return f"{seconds}s"
        return None
    
    def get_input_file_size_display(self, obj):
        """Get human-readable input file size."""
        if obj.input_file_size:
            size = obj.input_file_size
            for unit in ['B', 'KB', 'MB', 'GB']:
                if size < 1024.0:
                    return f"{size:.1f} {unit}"
                size /= 1024.0
            return f"{size:.1f} TB"
        return "Unknown"


class ImputationJobCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating ImputationJob."""
    
    class Meta:
        model = ImputationJob
        fields = [
            'name', 'description', 'service', 'reference_panel',
            'input_format', 'build', 'phasing', 'population', 'input_file',
            'user_token'
        ]
    
    def validate_input_file(self, value):
        """Validate input file size and format."""
        if value:
            # Check file size (100MB default limit)
            max_size = 100 * 1024 * 1024  # 100MB
            if value.size > max_size:
                raise serializers.ValidationError(
                    f"File size ({value.size} bytes) exceeds maximum allowed size ({max_size} bytes)"
                )
            
            # Check file format based on name
            allowed_extensions = ['.vcf', '.vcf.gz', '.bed', '.bim', '.fam', '.bgen']
            file_name = value.name.lower()
            if not any(file_name.endswith(ext) for ext in allowed_extensions):
                raise serializers.ValidationError(
                    f"File format not supported. Allowed formats: {', '.join(allowed_extensions)}"
                )
        
        return value
    
    def validate(self, data):
        """Validate that the reference panel belongs to the selected service."""
        service = data.get('service')
        reference_panel = data.get('reference_panel')
        
        if service and reference_panel:
            if reference_panel.service != service:
                raise serializers.ValidationError(
                    "Selected reference panel does not belong to the selected service."
                )
            
            if not reference_panel.is_active:
                raise serializers.ValidationError(
                    "Selected reference panel is not active."
                )
        
        return data
    
    def create(self, validated_data):
        """Create a new imputation job."""
        # Set the user from the request
        validated_data['user'] = self.context['request'].user
        
        # Set input file size
        if validated_data.get('input_file'):
            validated_data['input_file_size'] = validated_data['input_file'].size
        
        return super().create(validated_data)


class UserServiceAccessSerializer(serializers.ModelSerializer):
    """Serializer for UserServiceAccess model."""
    
    user = UserSerializer(read_only=True)
    service = ImputationServiceSerializer(read_only=True)
    quota_percentage = serializers.SerializerMethodField()
    
    class Meta:
        model = UserServiceAccess
        fields = [
            'id', 'user', 'service', 'has_access', 'quota_limit',
            'quota_used', 'quota_percentage', 'last_used',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'quota_used', 'last_used', 'created_at', 'updated_at']
    
    def get_quota_percentage(self, obj):
        """Get quota usage percentage."""
        if obj.quota_limit and obj.quota_limit > 0:
            return (obj.quota_used / obj.quota_limit) * 100
        return 0


class ServiceSyncSerializer(serializers.Serializer):
    """Serializer for service synchronization requests."""
    
    service_id = serializers.IntegerField()
    
    def validate_service_id(self, value):
        """Validate that the service exists and is active."""
        try:
            service = ImputationService.objects.get(id=value, is_active=True)
            return value
        except ImputationService.DoesNotExist:
            raise serializers.ValidationError("Service not found or inactive.")


class JobActionSerializer(serializers.Serializer):
    """Serializer for job actions (cancel, retry, etc.)."""
    
    action = serializers.ChoiceField(choices=['cancel', 'retry'])
    
    def validate_action(self, value):
        """Validate the action based on job status."""
        job = self.context.get('job')
        if not job:
            return value
        
        if value == 'cancel':
            if job.status in ['completed', 'failed', 'cancelled']:
                raise serializers.ValidationError(
                    f"Cannot cancel job with status '{job.status}'"
                )
        elif value == 'retry':
            if job.status not in ['failed', 'cancelled']:
                raise serializers.ValidationError(
                    f"Cannot retry job with status '{job.status}'"
                )
        
        return value 