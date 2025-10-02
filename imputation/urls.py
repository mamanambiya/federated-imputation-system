"""
URL configuration for the imputation app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Create a router and register our viewsets
router = DefaultRouter()
router.register(r'services', views.ImputationServiceViewSet, basename='imputationservice')
router.register(r'reference-panels', views.ReferencePanelViewSet, basename='referencepanel')
router.register(r'jobs', views.ImputationJobViewSet, basename='imputationjob')
router.register(r'status-updates', views.JobStatusUpdateViewSet, basename='jobstatusupdate')
router.register(r'result-files', views.ResultFileViewSet, basename='resultfile')
router.register(r'user-access', views.UserServiceAccessViewSet, basename='userserviceaccess')
router.register(r'dashboard', views.DashboardViewSet, basename='dashboard')

# User Management endpoints
router.register(r'roles', views.UserRoleViewSet, basename='userrole')
router.register(r'users', views.UserViewSet, basename='user')
router.register(r'profiles', views.UserProfileViewSet, basename='userprofile')
router.register(r'audit-logs', views.AuditLogViewSet, basename='auditlog')

# API URL patterns (for /api/ prefix)
api_patterns = [
    path('', include(router.urls)),
    # Test endpoint
    path('test/', views.TestView.as_view(), name='api_test'),
    # Authentication endpoints
    path('auth/login/', views.LoginView.as_view(), name='api_login'),
    path('auth/logout/', views.LogoutView.as_view(), name='api_logout'),
    path('auth/user/', views.UserInfoView.as_view(), name='api_user'),
    path('auth/check/', views.UserInfoView.as_view(), name='api_auth_check'),
    # Monitoring endpoints
    path('monitoring/metrics/', views.SystemMetricsView.as_view(), name='system_metrics'),
    path('monitoring/health/', views.HealthCheckView.as_view(), name='health_check'),
    path('monitoring/dashboard/', views.MonitoringDashboardView.as_view(), name='monitoring_dashboard'),
    # Service-specific user management
    path('services/<int:service_pk>/permissions/', views.ServicePermissionViewSet.as_view({'get': 'list', 'post': 'create'}), name='service-permissions-list'),
    path('services/<int:service_pk>/permissions/<int:pk>/', views.ServicePermissionViewSet.as_view({'get': 'retrieve', 'put': 'update', 'delete': 'destroy'}), name='service-permissions-detail'),
    path('services/<int:service_pk>/groups/', views.ServiceUserGroupViewSet.as_view({'get': 'list', 'post': 'create'}), name='service-groups-list'),
    path('services/<int:service_pk>/groups/<int:pk>/', views.ServiceUserGroupViewSet.as_view({'get': 'retrieve', 'put': 'update', 'delete': 'destroy'}), name='service-groups-detail'),
    path('services/<int:service_pk>/groups/<int:pk>/add_user/', views.ServiceUserGroupViewSet.as_view({'post': 'add_user'}), name='service-groups-add-user'),
    path('services/<int:service_pk>/groups/<int:pk>/remove_user/', views.ServiceUserGroupViewSet.as_view({'post': 'remove_user'}), name='service-groups-remove-user'),
]

# Frontend URL patterns (for root / prefix)
frontend_patterns = [
    # React application at root
    path('', views.IndexView.as_view(), name='app'),
    # Catch all other paths and serve React app (for client-side routing)
    path('<path:path>', views.IndexView.as_view(), name='react_catchall'),
]

# Legacy: For backward compatibility, export both patterns
# Main URLs will import these separately
urlpatterns = frontend_patterns 