"""
Django admin configuration for the imputation app.
"""
from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse, path
from django.utils.safestring import mark_safe
from django.http import HttpResponseRedirect
from .models import (
    ImputationService, ReferencePanel, ImputationJob,
    JobStatusUpdate, ResultFile, ServiceConfiguration, UserServiceAccess
)
from .admin_views import (
    ServiceSetupView, ServiceDetailView, test_service_connection, 
    sync_reference_panels_view, refresh_service_info
)


@admin.register(ImputationService)
class ImputationServiceAdmin(admin.ModelAdmin):
    list_display = ['name_with_link', 'service_type', 'api_type', 'is_active', 'api_key_required', 'max_file_size_mb', 'panel_count', 'view_details', 'created_at']
    list_filter = ['service_type', 'api_type', 'is_active', 'api_key_required']
    search_fields = ['name', 'description']
    readonly_fields = ['created_at', 'updated_at', 'panel_count']
    
    def name_with_link(self, obj):
        """Display name as a link to the change page."""
        return format_html(
            '<a href="{}">{}</a>',
            reverse('admin:imputation_imputationservice_change', args=[obj.id]),
            obj.name
        )
    name_with_link.short_description = 'Name'
    name_with_link.admin_order_field = 'name'
    
    def view_details(self, obj):
        """Link to detailed view."""
        return format_html(
            '<a href="{}" class="button">View Details</a>',
            reverse('admin:imputation_service_detail', args=[obj.id])
        )
    view_details.short_description = 'Details'
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'service_type', 'api_type', 'api_url', 'description', 'is_active')
        }),
        ('API Configuration', {
            'fields': ('api_key', 'api_key_required', 'api_config'),
            'description': 'API authentication and configuration settings'
        }),
        ('Service Limits', {
            'fields': ('max_file_size_mb', 'supported_formats')
        }),
        ('Statistics', {
            'fields': ('panel_count',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def panel_count(self, obj):
        """Display the number of reference panels."""
        count = obj.reference_panels.filter(is_active=True).count()
        return format_html(
            '<a href="{}?service__id__exact={}">{} panels</a>',
            reverse('admin:imputation_referencepanel_changelist'),
            obj.id,
            count
        )
    panel_count.short_description = 'Reference Panels'
    
    def get_urls(self):
        """Add custom URLs for service management."""
        urls = super().get_urls()
        custom_urls = [
            path('add-service/', 
                 self.admin_site.admin_view(ServiceSetupView.as_view()), 
                 name='imputation_service_setup'),
            path('<int:service_id>/setup/', 
                 self.admin_site.admin_view(ServiceSetupView.as_view()), 
                 name='imputation_service_setup_edit'),
            path('<int:service_id>/detail/', 
                 self.admin_site.admin_view(ServiceDetailView.as_view()), 
                 name='imputation_service_detail'),
            path('<int:service_id>/refresh/', 
                 self.admin_site.admin_view(refresh_service_info), 
                 name='imputation_service_refresh'),
            path('test-connection/', 
                 self.admin_site.admin_view(test_service_connection), 
                 name='imputation_test_connection'),
            path('<int:service_id>/sync-panels/', 
                 self.admin_site.admin_view(sync_reference_panels_view), 
                 name='imputation_sync_panels'),
        ]
        return custom_urls + urls
    
    def changelist_view(self, request, extra_context=None):
        """Add custom button to changelist view."""
        extra_context = extra_context or {}
        extra_context['show_add_service_button'] = True
        return super().changelist_view(request, extra_context)
    
    actions = ['sync_panels_action']
    
    def sync_panels_action(self, request, queryset):
        """Admin action to sync panels for selected services."""
        for service in queryset:
            url = reverse('admin:imputation_sync_panels', args=[service.id])
            return HttpResponseRedirect(url)
    sync_panels_action.short_description = "Sync reference panels"


class ReferencePanelInline(admin.TabularInline):
    model = ReferencePanel
    extra = 0
    readonly_fields = ['created_at', 'updated_at']


@admin.register(ReferencePanel)
class ReferencePanelAdmin(admin.ModelAdmin):
    list_display = ['name', 'service', 'panel_id', 'population', 'build', 'samples_count', 'is_active']
    list_filter = ['service', 'population', 'build', 'is_active']
    search_fields = ['name', 'panel_id', 'description', 'population']
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Basic Information', {
            'fields': ('service', 'name', 'panel_id', 'description', 'is_active')
        }),
        ('Panel Details', {
            'fields': ('population', 'build', 'samples_count', 'variants_count')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


class JobStatusUpdateInline(admin.TabularInline):
    model = JobStatusUpdate
    extra = 0
    readonly_fields = ['timestamp']
    fields = ['status', 'progress_percentage', 'message', 'timestamp']


class ResultFileInline(admin.TabularInline):
    model = ResultFile
    extra = 0
    readonly_fields = ['created_at']
    fields = ['file_type', 'filename', 'file_size', 'is_available', 'created_at']


@admin.register(ImputationJob)
class ImputationJobAdmin(admin.ModelAdmin):
    list_display = ['name', 'user', 'service', 'reference_panel', 'status', 'progress_bar', 'created_at']
    list_filter = ['status', 'service', 'input_format', 'build', 'phasing']
    search_fields = ['name', 'description', 'user__username', 'external_job_id']
    readonly_fields = ['id', 'created_at', 'updated_at', 'started_at', 'completed_at', 'duration_display']
    date_hierarchy = 'created_at'
    inlines = [JobStatusUpdateInline, ResultFileInline]
    
    fieldsets = (
        ('Job Information', {
            'fields': ('id', 'user', 'name', 'description')
        }),
        ('Service Configuration', {
            'fields': ('service', 'reference_panel', 'input_format', 'build', 'phasing', 'population')
        }),
        ('Status & Progress', {
            'fields': ('status', 'progress_percentage', 'external_job_id', 'error_message')
        }),
        ('Files', {
            'fields': ('input_file', 'input_file_size', 'result_files')
        }),
        ('Execution Details', {
            'fields': ('execution_time_seconds', 'service_response'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'started_at', 'completed_at', 'duration_display'),
            'classes': ('collapse',)
        }),
    )
    
    def progress_bar(self, obj):
        """Display a visual progress bar."""
        if obj.status == 'completed':
            color = 'green'
        elif obj.status == 'failed':
            color = 'red'
        elif obj.status in ['running', 'queued']:
            color = 'blue'
        else:
            color = 'gray'
        
        return format_html(
            '<div style="width: 100px; background-color: #f0f0f0; border-radius: 3px;">'
            '<div style="width: {}px; height: 20px; background-color: {}; border-radius: 3px; text-align: center; color: white; font-size: 12px; line-height: 20px;">'
            '{}%</div></div>',
            obj.progress_percentage,
            color,
            obj.progress_percentage
        )
    progress_bar.short_description = 'Progress'
    
    def duration_display(self, obj):
        """Display job duration in a readable format."""
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
        return "N/A"
    duration_display.short_description = 'Duration'


@admin.register(JobStatusUpdate)
class JobStatusUpdateAdmin(admin.ModelAdmin):
    list_display = ['job', 'status', 'progress_percentage', 'timestamp']
    list_filter = ['status', 'timestamp']
    search_fields = ['job__name', 'message']
    readonly_fields = ['timestamp']
    date_hierarchy = 'timestamp'


@admin.register(ResultFile)
class ResultFileAdmin(admin.ModelAdmin):
    list_display = ['job', 'file_type', 'filename', 'file_size_display', 'is_available', 'created_at']
    list_filter = ['file_type', 'is_available']
    search_fields = ['job__name', 'filename']
    readonly_fields = ['created_at']
    date_hierarchy = 'created_at'
    
    def file_size_display(self, obj):
        """Display file size in human-readable format."""
        if obj.file_size:
            size = obj.file_size
            for unit in ['B', 'KB', 'MB', 'GB']:
                if size < 1024.0:
                    return f"{size:.1f} {unit}"
                size /= 1024.0
            return f"{size:.1f} TB"
        return "N/A"
    file_size_display.short_description = 'File Size'


@admin.register(ServiceConfiguration)
class ServiceConfigurationAdmin(admin.ModelAdmin):
    list_display = ['service', 'rate_limit_per_hour', 'timeout_seconds', 'retry_attempts', 'updated_at']
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Service', {
            'fields': ('service',)
        }),
        ('Authentication', {
            'fields': ('api_key', 'api_secret', 'additional_headers'),
            'classes': ('collapse',)
        }),
        ('Rate Limiting & Timeouts', {
            'fields': ('rate_limit_per_hour', 'timeout_seconds', 'retry_attempts')
        }),
        ('Additional Settings', {
            'fields': ('settings',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(UserServiceAccess)
class UserServiceAccessAdmin(admin.ModelAdmin):
    list_display = ['user', 'service', 'has_access', 'quota_limit', 'quota_used', 'last_used']
    list_filter = ['has_access', 'service']
    search_fields = ['user__username', 'user__email']
    readonly_fields = ['created_at', 'updated_at', 'last_used']
    fieldsets = (
        ('User & Service', {
            'fields': ('user', 'service', 'has_access')
        }),
        ('Access Configuration', {
            'fields': ('api_key', 'quota_limit', 'quota_used')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'last_used'),
            'classes': ('collapse',)
        }),
    )


# Customize admin site
admin.site.site_header = "Federated Imputation Administration"
admin.site.site_title = "Federated Imputation Admin"
admin.site.index_title = "Welcome to Federated Imputation Administration" 