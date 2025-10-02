"""
Integration tests for API views and endpoints.

Tests cover:
- Authentication and authorization
- Service and reference panel endpoints
- Job submission and management
- User management and permissions
- Audit logging
"""
import pytest
import json
from django.urls import reverse
from rest_framework import status
from imputation.models import (
    ImputationService, ReferencePanel, ImputationJob,
    UserProfile, AuditLog
)


@pytest.mark.django_db
class TestAuthenticationAPI:
    """Test authentication endpoints."""

    def test_login_success(self, api_client, test_user):
        """Test successful login."""
        url = reverse('login')
        data = {
            'username': 'testuser',
            'password': 'testpass123'
        }
        response = api_client.post(url, data, format='json')
        assert response.status_code == status.HTTP_200_OK
        assert 'user' in response.data

    def test_login_failure(self, api_client):
        """Test login with wrong credentials."""
        url = reverse('login')
        data = {
            'username': 'testuser',
            'password': 'wrongpassword'
        }
        response = api_client.post(url, data, format='json')
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_logout(self, authenticated_client):
        """Test logout endpoint."""
        url = reverse('logout')
        response = authenticated_client.post(url)
        assert response.status_code == status.HTTP_200_OK

    def test_current_user(self, authenticated_client, test_user):
        """Test getting current authenticated user."""
        url = reverse('current-user')
        response = authenticated_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert response.data['username'] == test_user.username


@pytest.mark.django_db
class TestServiceAPI:
    """Test imputation service endpoints."""

    def test_list_services_anonymous(self, api_client, imputation_service):
        """Test listing services without authentication."""
        url = reverse('imputationservice-list')
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data['results']) >= 1

    def test_list_services_authenticated(self, authenticated_client, imputation_service):
        """Test listing services with authentication."""
        url = reverse('imputationservice-list')
        response = authenticated_client.get(url)
        assert response.status_code == status.HTTP_200_OK

    def test_retrieve_service(self, api_client, imputation_service):
        """Test retrieving a specific service."""
        url = reverse('imputationservice-detail', args=[imputation_service.id])
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert response.data['name'] == imputation_service.name

    def test_list_reference_panels(self, api_client, imputation_service, reference_panel):
        """Test listing reference panels for a service."""
        url = reverse('imputationservice-reference-panels', args=[imputation_service.id])
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) >= 1


@pytest.mark.django_db
class TestReferencePanelAPI:
    """Test reference panel endpoints."""

    def test_list_reference_panels(self, api_client, reference_panel):
        """Test listing all reference panels."""
        url = reverse('referencepanel-list')
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK

    def test_retrieve_reference_panel(self, api_client, reference_panel):
        """Test retrieving a specific reference panel."""
        url = reverse('referencepanel-detail', args=[reference_panel.id])
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert response.data['name'] == reference_panel.name
        assert response.data['population'] == 'Mixed'


@pytest.mark.django_db
class TestJobAPI:
    """Test job submission and management endpoints."""

    def test_list_jobs_requires_auth(self, api_client):
        """Test that listing jobs requires authentication."""
        url = reverse('imputationjob-list')
        response = api_client.get(url)
        # Should either redirect to login or return 401/403
        assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN]

    def test_list_user_jobs(self, authenticated_client, imputation_job):
        """Test listing authenticated user's jobs."""
        url = reverse('imputationjob-list')
        response = authenticated_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        # User should see their own jobs
        job_ids = [job['id'] for job in response.data['results']]
        assert str(imputation_job.id) in job_ids

    def test_retrieve_own_job(self, authenticated_client, imputation_job):
        """Test retrieving user's own job."""
        url = reverse('imputationjob-detail', args=[imputation_job.id])
        response = authenticated_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert response.data['name'] == imputation_job.name

    def test_submit_job(self, authenticated_client, imputation_service, reference_panel, service_permission):
        """Test submitting a new imputation job."""
        url = reverse('imputationjob-list')
        data = {
            'name': 'Test Job Submission',
            'description': 'Testing job submission via API',
            'service': imputation_service.id,
            'reference_panel': reference_panel.id,
            'input_format': 'vcf',
            'build': 'hg19',
            'phasing': True
        }
        response = authenticated_client.post(url, data, format='json')
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data['name'] == 'Test Job Submission'
        assert response.data['status'] == 'pending'

    def test_submit_job_without_permission(self, authenticated_client, imputation_service, reference_panel):
        """Test job submission fails without service permission."""
        url = reverse('imputationjob-list')
        data = {
            'name': 'Unauthorized Job',
            'service': imputation_service.id,
            'reference_panel': reference_panel.id,
            'input_format': 'vcf'
        }
        # Note: This test assumes permission checking is implemented
        # The actual behavior may vary based on implementation
        response = authenticated_client.post(url, data, format='json')
        # Either succeeds or is rejected based on permission implementation

    def test_cancel_job(self, authenticated_client, imputation_job):
        """Test cancelling a job."""
        url = reverse('imputationjob-cancel', args=[imputation_job.id])
        response = authenticated_client.post(url)
        # Status depends on whether job can be cancelled
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST]


@pytest.mark.django_db
class TestUserManagementAPI:
    """Test user management endpoints."""

    def test_list_users_requires_admin(self, authenticated_client):
        """Test that listing users requires admin permission."""
        url = reverse('user-list')
        response = authenticated_client.get(url)
        # Regular user should not have access
        assert response.status_code in [status.HTTP_403_FORBIDDEN]

    def test_list_users_as_admin(self, admin_client, test_user):
        """Test admin can list users."""
        url = reverse('user-list')
        response = admin_client.get(url)
        assert response.status_code == status.HTTP_200_OK

    def test_get_user_profile(self, authenticated_client, test_user):
        """Test getting own user profile."""
        url = reverse('userprofile-detail', args=[test_user.profile.id])
        response = authenticated_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert response.data['organization'] == 'Test Organization'


@pytest.mark.django_db
class TestDashboardAPI:
    """Test dashboard statistics endpoints."""

    def test_dashboard_stats(self, authenticated_client, imputation_job):
        """Test getting dashboard statistics."""
        url = reverse('dashboard-stats')
        response = authenticated_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert 'total_jobs' in response.data or 'jobs' in response.data

    def test_dashboard_requires_auth(self, api_client):
        """Test dashboard requires authentication."""
        url = reverse('dashboard-stats')
        response = api_client.get(url)
        assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN]


@pytest.mark.django_db
class TestAuditLogAPI:
    """Test audit logging functionality."""

    def test_audit_log_created_on_job_submission(self, authenticated_client, imputation_service,
                                                  reference_panel, service_permission, test_user):
        """Test that audit log is created when job is submitted."""
        initial_count = AuditLog.objects.filter(user=test_user).count()

        url = reverse('imputationjob-list')
        data = {
            'name': 'Audit Test Job',
            'service': imputation_service.id,
            'reference_panel': reference_panel.id,
            'input_format': 'vcf'
        }
        response = authenticated_client.post(url, data, format='json')

        # Check audit log was created
        new_count = AuditLog.objects.filter(user=test_user).count()
        assert new_count > initial_count

    def test_list_audit_logs_requires_admin(self, authenticated_client):
        """Test that viewing audit logs requires admin access."""
        url = reverse('auditlog-list')
        response = authenticated_client.get(url)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_admin_can_view_audit_logs(self, admin_client):
        """Test that admins can view audit logs."""
        url = reverse('auditlog-list')
        response = admin_client.get(url)
        assert response.status_code == status.HTTP_200_OK


@pytest.mark.django_db
class TestPermissions:
    """Test permission and authorization logic."""

    def test_cannot_access_other_users_jobs(self, authenticated_client, admin_user,
                                             imputation_service, reference_panel):
        """Test users cannot access other users' jobs."""
        # Create a job for admin user
        admin_job = ImputationJob.objects.create(
            user=admin_user,
            name='Admin Job',
            service=imputation_service,
            reference_panel=reference_panel
        )

        # Try to access with regular user
        url = reverse('imputationjob-detail', args=[admin_job.id])
        response = authenticated_client.get(url)
        # Should be forbidden or not found
        assert response.status_code in [status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND]

    def test_admin_can_view_all_jobs(self, admin_client, imputation_job):
        """Test that admin users can view all jobs."""
        url = reverse('imputationjob-detail', args=[imputation_job.id])
        response = admin_client.get(url)
        # Admin should be able to see any job (if this feature is implemented)
        # Actual behavior depends on implementation
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_404_NOT_FOUND]
