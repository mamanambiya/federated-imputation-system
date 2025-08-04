"""
Management command to set up initial user roles and demo credentials.
"""
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User, Permission
from django.contrib.contenttypes.models import ContentType
from imputation.models import UserRole, UserProfile


class Command(BaseCommand):
    help = 'Set up initial user roles and create demo user'

    def handle(self, *args, **options):
        self.stdout.write('Setting up user management system...')
        
        # Create user roles
        self.create_roles()
        
        # Create demo user
        self.create_demo_user()
        
        self.stdout.write(
            self.style.SUCCESS('Successfully set up user management system!')
        )

    def create_roles(self):
        """Create initial user roles with appropriate permissions."""
        self.stdout.write('Creating user roles...')
        
        # Get content types for permissions
        user_ct = ContentType.objects.get_for_model(User)
        from imputation.models import ImputationService, ImputationJob
        service_ct = ContentType.objects.get_for_model(ImputationService)
        job_ct = ContentType.objects.get_for_model(ImputationJob)
        
        # Admin role - all permissions
        admin_role, created = UserRole.objects.get_or_create(
            name='admin',
            defaults={
                'description': 'System administrator with full access to all features'
            }
        )
        if created:
            # Add all permissions to admin
            admin_permissions = Permission.objects.all()
            admin_role.permissions.set(admin_permissions)
            self.stdout.write(f'  ✅ Created admin role with {admin_permissions.count()} permissions')
        
        # Service Admin role
        service_admin_role, created = UserRole.objects.get_or_create(
            name='service_admin',
            defaults={
                'description': 'Service administrator can manage services and users'
            }
        )
        if created:
            service_admin_perms = Permission.objects.filter(
                content_type__in=[service_ct, user_ct],
                codename__in=[
                    'add_imputationservice', 'change_imputationservice', 'view_imputationservice',
                    'add_user', 'change_user', 'view_user'
                ]
            )
            service_admin_role.permissions.set(service_admin_perms)
            self.stdout.write(f'  ✅ Created service_admin role with {service_admin_perms.count()} permissions')
        
        # Researcher role
        researcher_role, created = UserRole.objects.get_or_create(
            name='researcher',
            defaults={
                'description': 'Researcher can submit and manage their own jobs'
            }
        )
        if created:
            researcher_perms = Permission.objects.filter(
                content_type__in=[job_ct, service_ct],
                codename__in=[
                    'add_imputationjob', 'change_imputationjob', 'view_imputationjob',
                    'view_imputationservice'
                ]
            )
            researcher_role.permissions.set(researcher_perms)
            self.stdout.write(f'  ✅ Created researcher role with {researcher_perms.count()} permissions')
        
        # Service User role
        service_user_role, created = UserRole.objects.get_or_create(
            name='service_user',
            defaults={
                'description': 'Service user can submit basic jobs'
            }
        )
        if created:
            service_user_perms = Permission.objects.filter(
                content_type__in=[job_ct, service_ct],
                codename__in=['add_imputationjob', 'view_imputationjob', 'view_imputationservice']
            )
            service_user_role.permissions.set(service_user_perms)
            self.stdout.write(f'  ✅ Created service_user role with {service_user_perms.count()} permissions')
        
        # Viewer role
        viewer_role, created = UserRole.objects.get_or_create(
            name='viewer',
            defaults={
                'description': 'Viewer can only view services and public information'
            }
        )
        if created:
            viewer_perms = Permission.objects.filter(
                content_type__in=[service_ct],
                codename__in=['view_imputationservice']
            )
            viewer_role.permissions.set(viewer_perms)
            self.stdout.write(f'  ✅ Created viewer role with {viewer_perms.count()} permissions')

    def create_demo_user(self):
        """Create demo user with test_user credentials."""
        self.stdout.write('Creating demo user...')
        
        # Create demo user
        demo_user, created = User.objects.get_or_create(
            username='test_user',
            defaults={
                'email': 'test@example.com',
                'first_name': 'Test',
                'last_name': 'User',
                'is_active': True,
            }
        )
        
        if created or not demo_user.check_password('test_password'):
            demo_user.set_password('test_password')
            demo_user.save()
            self.stdout.write('  ✅ Created demo user: test_user / test_password')
        
        # Create or update profile
        researcher_role = UserRole.objects.get(name='researcher')
        profile, created = UserProfile.objects.get_or_create(
            user=demo_user,
            defaults={
                'role': researcher_role,
                'organization': 'Demo Organization',
                'department': 'Genomics Research',
                'position': 'Research Scientist',
                'research_area': 'Population Genetics',
                'institution': 'Demo University',
                'country': 'South Africa',
                'is_verified': True,
                'monthly_job_limit': 50,
            }
        )
        
        if created:
            self.stdout.write('  ✅ Created demo user profile with researcher role')
        else:
            # Update existing profile
            profile.role = researcher_role
            profile.is_verified = True
            profile.save()
            self.stdout.write('  ✅ Updated demo user profile')
        
        # Create admin user if it doesn't exist
        admin_user, created = User.objects.get_or_create(
            username='admin',
            defaults={
                'email': 'admin@example.com',
                'first_name': 'Admin',
                'last_name': 'User',
                'is_active': True,
                'is_staff': True,
                'is_superuser': True,
            }
        )
        
        if created or not admin_user.check_password('admin_password'):
            admin_user.set_password('admin_password')
            admin_user.save()
            self.stdout.write('  ✅ Created admin user: admin / admin_password')
        
        # Create admin profile
        admin_role = UserRole.objects.get(name='admin')
        admin_profile, created = UserProfile.objects.get_or_create(
            user=admin_user,
            defaults={
                'role': admin_role,
                'organization': 'System Administration',
                'department': 'IT',
                'position': 'System Administrator',
                'is_verified': True,
                'monthly_job_limit': 1000,
            }
        )
        
        if created:
            self.stdout.write('  ✅ Created admin user profile')