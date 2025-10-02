"""
URL configuration for federated_imputation project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView
)

# Import the separate URL patterns from imputation app
from imputation.urls import api_patterns, frontend_patterns

urlpatterns = [
    path('admin/', admin.site.urls),
    # API routes under /api/ prefix
    path('api/', include((api_patterns, 'imputation'), namespace='api')),
    # Frontend routes at root level
    path('', include((frontend_patterns, 'imputation'), namespace='frontend')),

    # API Documentation
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT) 