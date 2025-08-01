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

# API URLs
api_urlpatterns = [
    path('', include(router.urls)),
    # Test endpoint
    path('test/', views.TestView.as_view(), name='api_test'),
    # Authentication endpoints
    path('auth/login/', views.LoginView.as_view(), name='api_login'),
    path('auth/logout/', views.LogoutView.as_view(), name='api_logout'),
    path('auth/user/', views.UserInfoView.as_view(), name='api_user'),
]

# Frontend URLs (will serve React app)
frontend_urlpatterns = [
    path('', views.IndexView.as_view(), name='index'),
]

urlpatterns = api_urlpatterns + frontend_urlpatterns 