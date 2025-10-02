"""
Unit tests for Django models in the imputation app.

Tests cover:
- User profiles and roles
- Imputation services and reference panels
- Job management and status tracking
- Permissions and access control
"""
import pytest
from django.contrib.auth.models import User
from django.utils import timezone
from imputation.models import (
    ImputationService, ReferencePanel, ImputationJob,
    UserRole, UserProfile, ServicePermission, AuditLog
)


@pytest.mark.django_db
class TestUserProfile:
    """Test UserProfile model functionality."""

    def test_user_profile_creation(self, test_user):
        """Test that user profile is created correctly."""
        profile = test_user.profile
        assert profile is not None
        assert profile.user == test_user
        assert profile.role.name == 'researcher'
        assert profile.monthly_job_limit == 10

    def test_has_permission(self, test_user):
        """Test permission checking through user role."""
        profile = test_user.profile
        # Researcher should not have admin permissions
        assert not profile.is_admin()
        assert profile.has_role('researcher')

    def test_quota_management(self, test_user):
        """Test job quota increment and checking."""
        profile = test_user.profile
        assert profile.has_quota_available()

        # Use up some quota
        profile.increment_job_usage()
        assert profile.monthly_jobs_used == 1
        assert profile.has_quota_available()

        # Use up all quota
        profile.monthly_jobs_used = profile.monthly_job_limit
        profile.save()
        assert not profile.has_quota_available()

    def test_storage_usage_tracking(self, test_user):
        """Test storage usage tracking."""
        profile = test_user.profile
        initial_storage = profile.storage_used_gb

        profile.add_storage_usage(0.5)
        assert profile.storage_used_gb == initial_storage + 0.5

    def test_activity_update(self, test_user):
        """Test last activity timestamp update."""
        profile = test_user.profile
        old_activity = profile.last_activity
        profile.update_activity()

        # Reload from database
        profile.refresh_from_db()
        assert profile.last_activity > (old_activity or timezone.now() - timezone.timedelta(seconds=10))


@pytest.mark.django_db
class TestImputationService:
    """Test ImputationService model functionality."""

    def test_service_creation(self, imputation_service):
        """Test imputation service creation."""
        assert imputation_service.name == 'Test Michigan Service'
        assert imputation_service.service_type == 'michigan'
        assert imputation_service.is_active
        assert 'vcf' in imputation_service.supported_formats

    def test_service_string_representation(self, imputation_service):
        """Test service __str__ method."""
        assert str(imputation_service) == 'Test Michigan Service'

    def test_reference_panel_relationship(self, imputation_service, reference_panel):
        """Test service-to-reference-panel relationship."""
        panels = imputation_service.reference_panels.all()
        assert panels.count() == 1
        assert panels.first() == reference_panel


@pytest.mark.django_db
class TestReferencePanel:
    """Test ReferencePanel model functionality."""

    def test_panel_creation(self, reference_panel):
        """Test reference panel creation."""
        assert reference_panel.name == '1000 Genomes Phase 3'
        assert reference_panel.panel_id == '1000g_p3'
        assert reference_panel.population == 'Mixed'
        assert reference_panel.build == 'hg19'
        assert reference_panel.samples_count == 2504

    def test_panel_service_relationship(self, reference_panel, imputation_service):
        """Test panel-to-service relationship."""
        assert reference_panel.service == imputation_service

    def test_unique_together_constraint(self, imputation_service):
        """Test that service + panel_id must be unique."""
        ReferencePanel.objects.create(
            service=imputation_service,
            name='Test Panel 1',
            panel_id='test_panel_1'
        )

        # Try to create duplicate - should fail
        with pytest.raises(Exception):  # IntegrityError
            ReferencePanel.objects.create(
                service=imputation_service,
                name='Test Panel 2',
                panel_id='test_panel_1'  # Duplicate panel_id
            )


@pytest.mark.django_db
class TestImputationJob:
    """Test ImputationJob model functionality."""

    def test_job_creation(self, imputation_job):
        """Test job creation with all required fields."""
        assert imputation_job.name == 'Test Imputation Job'
        assert imputation_job.status == 'pending'
        assert imputation_job.progress_percentage == 0
        assert imputation_job.input_format == 'vcf'
        assert imputation_job.phasing is True

    def test_job_status_update(self, imputation_job):
        """Test job status update with timestamps."""
        # Update to running
        imputation_job.update_status('running', progress=10)
        assert imputation_job.status == 'running'
        assert imputation_job.progress_percentage == 10
        assert imputation_job.started_at is not None

        # Update to completed
        imputation_job.update_status('completed', progress=100)
        assert imputation_job.status == 'completed'
        assert imputation_job.completed_at is not None
        assert imputation_job.execution_time_seconds is not None

    def test_job_duration_calculation(self, imputation_job):
        """Test job duration property."""
        # Initially no duration
        assert imputation_job.duration is None

        # Start the job
        imputation_job.started_at = timezone.now()
        imputation_job.save()
        assert imputation_job.duration is not None

    def test_job_error_handling(self, imputation_job):
        """Test job failure with error message."""
        error_msg = "Service unavailable"
        imputation_job.update_status('failed', error_message=error_msg)

        assert imputation_job.status == 'failed'
        assert imputation_job.error_message == error_msg

    def test_job_user_relationship(self, imputation_job, test_user):
        """Test job-to-user relationship."""
        assert imputation_job.user == test_user
        user_jobs = test_user.imputation_jobs.all()
        assert imputation_job in user_jobs


@pytest.mark.django_db
class TestServicePermission:
    """Test ServicePermission model functionality."""

    def test_permission_creation(self, service_permission):
        """Test service permission creation."""
        assert service_permission.permission == 'submit_jobs'
        assert service_permission.is_active

    def test_permission_validity(self, service_permission):
        """Test permission validity checking."""
        # Active permission should be valid
        assert service_permission.is_valid()

        # Deactivated permission should be invalid
        service_permission.is_active = False
        service_permission.save()
        assert not service_permission.is_valid()

    def test_permission_expiration(self, service_permission):
        """Test permission expiration."""
        # Set expiration in the past
        service_permission.expires_at = timezone.now() - timezone.timedelta(days=1)
        service_permission.save()
        assert not service_permission.is_valid()

        # Set expiration in the future
        service_permission.expires_at = timezone.now() + timezone.timedelta(days=30)
        service_permission.save()
        assert service_permission.is_valid()


@pytest.mark.django_db
class TestAuditLog:
    """Test AuditLog model functionality."""

    def test_audit_log_creation(self, test_user, imputation_job):
        """Test audit log creation."""
        log = AuditLog.objects.create(
            user=test_user,
            action='create_job',
            resource_type='ImputationJob',
            resource_id=str(imputation_job.id),
            details={'job_name': imputation_job.name},
            ip_address='192.168.1.1'
        )

        assert log.user == test_user
        assert log.action == 'create_job'
        assert log.resource_type == 'ImputationJob'
        assert log.details['job_name'] == imputation_job.name

    def test_audit_log_ordering(self, test_user):
        """Test audit logs are ordered by timestamp descending."""
        # Create multiple logs
        for i in range(3):
            AuditLog.objects.create(
                user=test_user,
                action='login',
                details={'attempt': i}
            )

        logs = AuditLog.objects.filter(user=test_user)
        # Most recent should be first
        assert logs[0].details['attempt'] == 2
        assert logs[2].details['attempt'] == 0
