# Enhanced pagination and filtering for the Federated Genomic Imputation Platform

from rest_framework.pagination import PageNumberPagination, CursorPagination
from rest_framework.response import Response
from rest_framework import filters
from django_filters import rest_framework as django_filters
from django.db.models import Q
import django_filters
from .models import ImputationJob, ImputationService, ReferencePanel


class StandardResultsSetPagination(PageNumberPagination):
    """
    Standard pagination with configurable page size
    """
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100
    
    def get_paginated_response(self, data):
        return Response({
            'links': {
                'next': self.get_next_link(),
                'previous': self.get_previous_link()
            },
            'count': self.page.paginator.count,
            'total_pages': self.page.paginator.num_pages,
            'current_page': self.page.number,
            'page_size': self.get_page_size(self.request),
            'results': data
        })


class LargeResultsSetPagination(PageNumberPagination):
    """
    Pagination for large datasets
    """
    page_size = 50
    page_size_query_param = 'page_size'
    max_page_size = 200


class CursorBasedPagination(CursorPagination):
    """
    Cursor-based pagination for real-time data
    """
    page_size = 20
    ordering = '-created_at'
    cursor_query_param = 'cursor'
    page_size_query_param = 'page_size'
    
    def get_paginated_response(self, data):
        return Response({
            'links': {
                'next': self.get_next_link(),
                'previous': self.get_previous_link()
            },
            'results': data
        })


class ImputationJobFilter(django_filters.FilterSet):
    """
    Advanced filtering for ImputationJob model
    """
    # Status filtering
    status = django_filters.ChoiceFilter(choices=ImputationJob.STATUS_CHOICES)
    status__in = django_filters.BaseInFilter(field_name='status', lookup_expr='in')
    
    # Date range filtering
    created_after = django_filters.DateTimeFilter(field_name='created_at', lookup_expr='gte')
    created_before = django_filters.DateTimeFilter(field_name='created_at', lookup_expr='lte')
    completed_after = django_filters.DateTimeFilter(field_name='completed_at', lookup_expr='gte')
    completed_before = django_filters.DateTimeFilter(field_name='completed_at', lookup_expr='lte')
    
    # Service and panel filtering
    service = django_filters.ModelChoiceFilter(queryset=ImputationService.objects.all())
    service__name = django_filters.CharFilter(field_name='service__name', lookup_expr='icontains')
    reference_panel = django_filters.ModelChoiceFilter(queryset=ReferencePanel.objects.all())
    reference_panel__name = django_filters.CharFilter(field_name='reference_panel__name', lookup_expr='icontains')
    
    # User filtering
    user = django_filters.NumberFilter(field_name='user__id')
    user__username = django_filters.CharFilter(field_name='user__username', lookup_expr='icontains')
    
    # Job configuration filtering
    input_format = django_filters.CharFilter()
    build = django_filters.CharFilter()
    phasing = django_filters.BooleanFilter()
    population = django_filters.CharFilter(lookup_expr='icontains')
    
    # Progress filtering
    progress_min = django_filters.NumberFilter(field_name='progress_percentage', lookup_expr='gte')
    progress_max = django_filters.NumberFilter(field_name='progress_percentage', lookup_expr='lte')
    
    # Execution time filtering
    execution_time_min = django_filters.NumberFilter(field_name='execution_time_seconds', lookup_expr='gte')
    execution_time_max = django_filters.NumberFilter(field_name='execution_time_seconds', lookup_expr='lte')
    
    # Text search across multiple fields
    search = django_filters.CharFilter(method='filter_search')
    
    class Meta:
        model = ImputationJob
        fields = [
            'status', 'service', 'reference_panel', 'user',
            'input_format', 'build', 'phasing', 'population'
        ]
    
    def filter_search(self, queryset, name, value):
        """
        Search across multiple fields
        """
        if not value:
            return queryset
        
        return queryset.filter(
            Q(name__icontains=value) |
            Q(description__icontains=value) |
            Q(service__name__icontains=value) |
            Q(reference_panel__name__icontains=value) |
            Q(user__username__icontains=value) |
            Q(user__first_name__icontains=value) |
            Q(user__last_name__icontains=value)
        )


class ImputationServiceFilter(django_filters.FilterSet):
    """
    Advanced filtering for ImputationService model
    """
    # Basic filtering
    name = django_filters.CharFilter(lookup_expr='icontains')
    api_type = django_filters.ChoiceFilter(choices=[
        ('michigan', 'Michigan Imputation Server'),
        ('ga4gh', 'GA4GH WES'),
        ('dnastack', 'DNASTACK'),
        ('h3africa', 'H3Africa'),
    ])
    is_active = django_filters.BooleanFilter()
    
    # Institution filtering
    institution__name = django_filters.CharFilter(field_name='institution__name', lookup_expr='icontains')
    institution__country = django_filters.CharFilter(field_name='institution__country', lookup_expr='icontains')
    
    # Location filtering
    location = django_filters.CharFilter(lookup_expr='icontains')
    
    # Capability filtering
    supports_phasing = django_filters.BooleanFilter()
    max_file_size_mb = django_filters.NumberFilter(lookup_expr='lte')
    
    # Search across multiple fields
    search = django_filters.CharFilter(method='filter_search')
    
    class Meta:
        model = ImputationService
        fields = ['name', 'api_type', 'is_active', 'location']
    
    def filter_search(self, queryset, name, value):
        """
        Search across multiple fields
        """
        if not value:
            return queryset
        
        return queryset.filter(
            Q(name__icontains=value) |
            Q(description__icontains=value) |
            Q(location__icontains=value) |
            Q(institution__name__icontains=value) |
            Q(institution__country__icontains=value)
        )


class ReferencePanelFilter(django_filters.FilterSet):
    """
    Advanced filtering for ReferencePanel model
    """
    # Basic filtering
    name = django_filters.CharFilter(lookup_expr='icontains')
    population = django_filters.CharFilter(lookup_expr='icontains')
    build = django_filters.CharFilter()
    is_active = django_filters.BooleanFilter()
    
    # Service filtering
    service = django_filters.ModelChoiceFilter(queryset=ImputationService.objects.all())
    service__name = django_filters.CharFilter(field_name='service__name', lookup_expr='icontains')
    
    # Sample size filtering
    sample_size_min = django_filters.NumberFilter(field_name='sample_size', lookup_expr='gte')
    sample_size_max = django_filters.NumberFilter(field_name='sample_size', lookup_expr='lte')
    
    # Search across multiple fields
    search = django_filters.CharFilter(method='filter_search')
    
    class Meta:
        model = ReferencePanel
        fields = ['name', 'population', 'build', 'is_active', 'service']
    
    def filter_search(self, queryset, name, value):
        """
        Search across multiple fields
        """
        if not value:
            return queryset
        
        return queryset.filter(
            Q(name__icontains=value) |
            Q(description__icontains=value) |
            Q(population__icontains=value) |
            Q(service__name__icontains=value)
        )


class AdvancedSearchFilter(filters.BaseFilterBackend):
    """
    Advanced search filter with ranking
    """
    search_param = 'search'
    
    def filter_queryset(self, request, queryset, view):
        search_term = request.query_params.get(self.search_param)
        if not search_term:
            return queryset
        
        # This would implement more sophisticated search with ranking
        # For now, we'll use basic text search
        return queryset.filter(
            Q(name__icontains=search_term) |
            Q(description__icontains=search_term)
        )


class OptimizedOrderingFilter(filters.OrderingFilter):
    """
    Optimized ordering filter with performance considerations
    """
    
    def filter_queryset(self, request, queryset, view):
        ordering = self.get_ordering(request, queryset, view)
        
        if ordering:
            # Add select_related/prefetch_related optimizations based on ordering
            if any('user' in field for field in ordering):
                queryset = queryset.select_related('user')
            if any('service' in field for field in ordering):
                queryset = queryset.select_related('service')
            if any('reference_panel' in field for field in ordering):
                queryset = queryset.select_related('reference_panel')
            
            return queryset.order_by(*ordering)
        
        return queryset


class SmartPaginationMixin:
    """
    Mixin to automatically choose pagination based on dataset size
    """
    
    def get_pagination_class(self):
        """
        Choose pagination class based on queryset size
        """
        queryset = self.filter_queryset(self.get_queryset())
        count = queryset.count()
        
        if count > 10000:
            return CursorBasedPagination
        elif count > 1000:
            return LargeResultsSetPagination
        else:
            return StandardResultsSetPagination
    
    def paginate_queryset(self, queryset):
        """
        Override to use smart pagination
        """
        if not hasattr(self, '_pagination_class'):
            self._pagination_class = self.get_pagination_class()
        
        if self._pagination_class is None:
            return None
        
        paginator = self._pagination_class()
        page = paginator.paginate_queryset(queryset, self.request, view=self)
        if page is not None:
            self.paginator = paginator
        return page
