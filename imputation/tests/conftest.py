"""
Pytest configuration and shared fixtures for backend tests.
"""
import pytest
from django.contrib.auth.models import User
from django.test import Client
from rest_framework.test import APIClient
from imputation.models import (
    ImputationService, ReferencePanel, ImputationJob,
    UserRole, UserProfile, ServicePermission
)


@pytest.fixture
def api_client():
    """Provide an API client for testing."""
    return APIClient()


@pytest.fixture
def authenticated_client(test_user):
    """Provide an authenticated API client."""
    client = APIClient()
    client.force_authenticate(user=test_user)
    return client


@pytest.fixture
def admin_client(admin_user):
    """Provide an admin-authenticated API client."""
    client = APIClient()
    client.force_authenticate(user=admin_user)
    return client


@pytest.fixture
def test_user(db):
    """Create a regular test user."""
    user = User.objects.create_user(
        username='testuser',
        email='test@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )

    # Create user role
    researcher_role, _ = UserRole.objects.get_or_create(
        name='researcher',
        defaults={'description': 'Research user role'}
    )

    # Create user profile
    UserProfile.objects.create(
        user=user,
        role=researcher_role,
        organization='Test Organization',
        department='Bioinformatics',
        monthly_job_limit=10
    )

    return user


@pytest.fixture
def admin_user(db):
    """Create an admin test user."""
    user = User.objects.create_user(
        username='admin',
        email='admin@example.com',
        password='adminpass123',
        is_staff=True,
        is_superuser=True
    )

    # Create admin role
    admin_role, _ = UserRole.objects.get_or_create(
        name='admin',
        defaults={'description': 'Administrator role'}
    )

    # Create admin profile
    UserProfile.objects.create(
        user=user,
        role=admin_role,
        organization='Admin Org',
        monthly_job_limit=1000
    )

    return user


@pytest.fixture
def imputation_service(db):
    """Create a test imputation service."""
    return ImputationService.objects.create(
        name='Test Michigan Service',
        service_type='michigan',
        api_type='michigan',
        api_url='https://test-imputation-server.example.com/api/v2/',
        description='Test Michigan Imputation Service',
        location='Ann Arbor, Michigan',
        continent='North America',
        is_active=True,
        api_key='test_api_key_12345',
        max_file_size_mb=100,
        supported_formats=['vcf', 'plink', 'bgen']
    )


@pytest.fixture
def reference_panel(db, imputation_service):
    """Create a test reference panel."""
    return ReferencePanel.objects.create(
        service=imputation_service,
        name='1000 Genomes Phase 3',
        panel_id='1000g_p3',
        description='1000 Genomes Project Phase 3',
        population='Mixed',
        build='hg19',
        samples_count=2504,
        variants_count=81271745,
        is_active=True
    )


@pytest.fixture
def imputation_job(db, test_user, imputation_service, reference_panel):
    """Create a test imputation job."""
    return ImputationJob.objects.create(
        user=test_user,
        name='Test Imputation Job',
        description='Testing job submission',
        service=imputation_service,
        reference_panel=reference_panel,
        input_format='vcf',
        build='hg19',
        phasing=True,
        status='pending'
    )


@pytest.fixture
def service_permission(db, test_user, imputation_service):
    """Create a service permission for test user."""
    return ServicePermission.objects.create(
        service=imputation_service,
        user=test_user,
        permission='submit_jobs',
        is_active=True
    )
