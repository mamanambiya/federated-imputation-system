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

# API URL patterns (for /api/ prefix)
api_patterns = [
    path('', include(router.urls)),
    # Test endpoint
    path('test/', views.TestView.as_view(), name='api_test'),
    # Authentication endpoints
    path('auth/login/', views.LoginView.as_view(), name='api_login'),
    path('auth/logout/', views.LogoutView.as_view(), name='api_logout'),
    path('auth/user/', views.UserInfoView.as_view(), name='api_user'),
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