"""
Custom admin views for imputation service management.
"""
import json
import requests
from datetime import datetime, timedelta
from django.contrib import messages
from django.contrib.admin.views.decorators import staff_member_required
from django.shortcuts import render, redirect, get_object_or_404
from django.urls import reverse
from django.utils.decorators import method_decorator
from django.views import View
from django.http import JsonResponse
from django.utils import timezone
from .models import ImputationService, ReferencePanel
from .forms import ServiceSetupForm


@method_decorator(staff_member_required, name='dispatch')
class ServiceSetupView(View):
    """View for setting up new imputation services."""
    
    template_name = 'admin/imputation/service_setup.html'
    
    def get(self, request, service_id=None):
        """Display the service setup form."""
        service = None
        initial = {}
        
        if service_id:
            service = get_object_or_404(ImputationService, id=service_id)
            initial = {
                'name': service.name,
                'service_type': service.service_type,
                'api_type': service.api_type,
                'api_url': service.api_url,
                'api_key': service.api_key,
                'description': service.description,
                'max_file_size_mb': service.max_file_size_mb,
                'supported_formats': json.dumps(service.supported_formats),
                'api_config': json.dumps(service.api_config, indent=2),
            }
        
        form = ServiceSetupForm(initial=initial)
        
        context = {
            'form': form,
            'service': service,
            'title': f'Edit Service: {service.name}' if service else 'Add New Service',
            'opts': ImputationService._meta,
            'has_view_permission': True,
            'has_add_permission': True,
            'has_change_permission': True,
        }
        
        return render(request, self.template_name, context)
    
    def post(self, request, service_id=None):
        """Handle form submission."""
        service = get_object_or_404(ImputationService, id=service_id) if service_id else None
        form = ServiceSetupForm(request.POST, instance=service)
        
        if form.is_valid():
            service = form.save()
            messages.success(
                request, 
                f'Service "{service.name}" has been {"updated" if service_id else "created"} successfully.'
            )
            return redirect('admin:imputation_imputationservice_changelist')
        
        context = {
            'form': form,
            'service': service,
            'title': f'Edit Service: {service.name}' if service else 'Add New Service',
            'opts': ImputationService._meta,
            'has_view_permission': True,
            'has_add_permission': True,
            'has_change_permission': True,
        }
        
        return render(request, self.template_name, context)


@staff_member_required
def test_service_connection(request):
    """Test connection to an imputation service."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    
    try:
        data = json.loads(request.body)
        api_type = data.get('api_type')
        api_url = data.get('api_url')
        api_key = data.get('api_key')
        
        if not api_url:
            return JsonResponse({'error': 'API URL is required'}, status=400)
        
        # Test based on API type
        if api_type == 'michigan':
            result = test_michigan_api(api_url, api_key)
        elif api_type == 'ga4gh':
            result = test_ga4gh_api(api_url, api_key)
        elif api_type == 'dnastack':
            result = test_dnastack_api(api_url, api_key)
        else:
            return JsonResponse({'error': f'Unknown API type: {api_type}'}, status=400)
        
        return JsonResponse(result)
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def test_michigan_api(api_url, api_key=None):
    """Test Michigan Imputation Server API."""
    try:
        # Michigan API typically has endpoints like /api/v2/server
        test_url = f"{api_url.rstrip('/')}/api/v2/server"
        
        headers = {}
        if api_key:
            headers['X-Auth-Token'] = api_key
        
        response = requests.get(test_url, headers=headers, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            return {
                'success': True,
                'message': 'Connection successful',
                'server_info': {
                    'name': data.get('name', 'Michigan Imputation Server'),
                    'version': data.get('version', 'Unknown'),
                    'contact': data.get('contact', 'Unknown'),
                }
            }
        else:
            return {
                'success': False,
                'message': f'Server returned status code: {response.status_code}',
                'details': response.text[:200]
            }
            
    except requests.exceptions.Timeout:
        return {'success': False, 'message': 'Connection timeout'}
    except requests.exceptions.ConnectionError:
        return {'success': False, 'message': 'Failed to connect to server'}
    except Exception as e:
        return {'success': False, 'message': str(e)}


def test_dnastack_api(api_url, api_key=None):
    """Test DNASTACK Omics API connection."""
    try:
        # For DNASTACK, we'll check if the service is accessible
        # Since we need the dnastack-client-library, we'll do a simple HTTP check
        # to verify the endpoint is reachable
        
        headers = {
            'Accept': 'application/json',
            'User-Agent': 'FederatedImputation/1.0'
        }
        if api_key:
            headers['Authorization'] = f'Bearer {api_key}'
        
        # Try to access the base URL
        response = requests.get(api_url, headers=headers, timeout=10, allow_redirects=True)
        
        # DNASTACK services typically return 200 or redirect to auth
        if response.status_code in [200, 302, 401]:
            # Extract domain from URL for factory name
            from urllib.parse import urlparse
            parsed = urlparse(api_url)
            domain = parsed.netloc or parsed.path
            
            return {
                'success': True,
                'message': 'DNASTACK endpoint is accessible',
                'server_info': {
                    'service_type': 'DNASTACK Omics',
                    'endpoint': api_url,
                    'domain': domain,
                    'status_code': response.status_code,
                    'auth_required': response.status_code == 401,
                    'install_command': 'pip3 install -U dnastack-client-library',
                    'usage_hint': f"factory = use('{domain}')",
                }
            }
        else:
            return {
                'success': False,
                'message': f'Unexpected status code: {response.status_code}',
                'details': f'Response: {response.text[:200]}'
            }
            
    except requests.exceptions.Timeout:
        return {'success': False, 'message': 'Connection timeout'}
    except requests.exceptions.ConnectionError:
        return {'success': False, 'message': 'Failed to connect to DNASTACK endpoint'}
    except Exception as e:
        return {'success': False, 'message': f'Error: {str(e)}'}


def test_ga4gh_api(api_url, api_key=None):
    """Test GA4GH Service Info API."""
    try:
        # GA4GH WES Service Info endpoint
        # If URL already ends with /service-info, use it as is
        if api_url.endswith('/service-info'):
            test_url = api_url
        else:
            # Otherwise append /service-info
            test_url = f"{api_url.rstrip('/')}/service-info"
        
        headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        }
        if api_key:
            headers['Authorization'] = f'Bearer {api_key}'
        
        response = requests.get(test_url, headers=headers, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            
            # Extract comprehensive information from GA4GH WES response
            server_info = {
                'service_type': 'GA4GH WES',
                'supported_wes_versions': ', '.join(data.get('supported_wes_versions', [])),
                'contact': data.get('contact_info_url', 'Not provided'),
                'auth_instructions': data.get('auth_instructions_url', 'None'),
            }
            
            # Add workflow engine information
            if 'workflow_engine_versions' in data:
                engines = data['workflow_engine_versions']
                server_info['workflow_engines'] = ', '.join([f"{k} {v}" for k, v in engines.items()])
                
                # Extract workflow parameters count
                if 'default_workflow_engine_parameters' in data:
                    params = data['default_workflow_engine_parameters']
                    engine_param_counts = {}
                    for param in params:
                        engine = param['name'].split('|')[0]
                        engine_param_counts[engine] = engine_param_counts.get(engine, 0) + 1
                    
                    param_summary = []
                    for engine, count in engine_param_counts.items():
                        param_summary.append(f"{engine}: {count} params")
                    server_info['workflow_parameters'] = ', '.join(param_summary)
            
            # Add detailed system state
            if 'system_state_counts' in data:
                states = data['system_state_counts']
                total_jobs = sum(states.values())
                server_info['total_jobs'] = total_jobs
                
                # Show active states
                active_states = []
                for state, count in sorted(states.items()):
                    if count > 0:
                        active_states.append(f"{state}: {count}")
                if active_states:
                    server_info['job_states'] = ', '.join(active_states)
            
            # Add supported protocols
            if 'supported_filesystem_protocols' in data:
                server_info['supported_protocols'] = ', '.join(data['supported_filesystem_protocols'])
            
            # Add tags if present
            if 'tags' in data and data['tags']:
                tag_list = [f"{k}={v}" for k, v in data['tags'].items()]
                server_info['tags'] = ', '.join(tag_list)
            
            # Store full response for advanced configuration
            server_info['_full_response'] = data
            
            return {
                'success': True,
                'message': 'GA4GH WES service connection successful',
                'server_info': server_info
            }
        else:
            return {
                'success': False,
                'message': f'Server returned status code: {response.status_code}',
                'details': response.text[:200]
            }
            
    except requests.exceptions.Timeout:
        return {'success': False, 'message': 'Connection timeout'}
    except requests.exceptions.ConnectionError:
        return {'success': False, 'message': 'Failed to connect to server'}
    except Exception as e:
        return {'success': False, 'message': str(e)}


@staff_member_required
def sync_reference_panels_view(request, service_id):
    """Sync reference panels for a service."""
    service = get_object_or_404(ImputationService, id=service_id)
    
    try:
        # Based on API type, sync panels differently
        if service.api_type == 'michigan':
            panels = sync_michigan_panels(service)
        elif service.api_type == 'ga4gh':
            panels = sync_ga4gh_panels(service)
        elif service.api_type == 'dnastack':
            panels = sync_dnastack_panels(service)
        else:
            messages.error(request, f'Unknown API type: {service.api_type}')
            return redirect('admin:imputation_imputationservice_changelist')
        
        # Clear existing panels
        service.reference_panels.all().delete()
        
        # Create new panels
        for panel_data in panels:
            ReferencePanel.objects.create(
                service=service,
                **panel_data
            )
        
        messages.success(
            request, 
            f'Successfully synced {len(panels)} reference panels for {service.name}'
        )
        
    except Exception as e:
        messages.error(request, f'Error syncing panels: {str(e)}')
    
    return redirect('admin:imputation_imputationservice_changelist')


def sync_michigan_panels(service):
    """Sync panels from Michigan Imputation Server."""
    # This would typically make an API call to get available panels
    # For now, return example panels
    return [
        {
            'name': 'HRC r1.1 2016',
            'panel_id': 'hrc-1.1',
            'description': 'Haplotype Reference Consortium',
            'population': 'Mixed',
            'build': 'hg38',
            'samples_count': 32488,
            'variants_count': 39635008,
            'is_active': True,
        },
        {
            'name': '1000G Phase 3 v5',
            'panel_id': '1000g-phase3-v5',
            'description': '1000 Genomes Project Phase 3',
            'population': 'Mixed',
            'build': 'hg38',
            'samples_count': 2504,
            'variants_count': 49143605,
            'is_active': True,
        }
    ]


def sync_ga4gh_panels(service):
    """Sync panels from GA4GH WES service - using H3Africa reference panels."""
    try:
        # For GA4GH WES services, we'll create panels that represent H3Africa reference panels
        # that can be processed through their workflow engines
        
        headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        }
        if service.api_key:
            headers['Authorization'] = f'Bearer {service.api_key}'
        
        # Get service info to understand available workflows
        service_info_url = f"{service.api_url.rstrip('/')}/service-info"
        response = requests.get(service_info_url, headers=headers, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            
            # Store service info in api_config
            if not service.api_config:
                service.api_config = {}
            service.api_config['_service_info'] = {
                'timestamp': datetime.now().isoformat(),
                'data': data
            }
            service.save()
            
            # Create H3Africa-style reference panels for GA4GH services
            panels = [
                {
                    'name': 'H3Africa Multi-Ethnic Panel',
                    'panel_id': 'h3africa-multi-ethnic',
                    'description': 'Combined African populations reference panel for imputation via GA4GH workflows',
                    'population': 'African',
                    'build': 'hg38',
                    'samples_count': 5000,
                    'variants_count': 20000000,
                    'is_active': True
                },
                {
                    'name': 'H3Africa West African Panel',
                    'panel_id': 'h3africa-west-african',
                    'description': 'West African specific reference panel for GA4GH workflow processing',
                    'population': 'West African',
                    'build': 'hg38',
                    'samples_count': 2000,
                    'variants_count': 15000000,
                    'is_active': True
                },
                {
                    'name': 'H3Africa East African Panel',
                    'panel_id': 'h3africa-east-african',
                    'description': 'East African specific reference panel for GA4GH workflow processing',
                    'population': 'East African',
                    'build': 'hg38',
                    'samples_count': 1500,
                    'variants_count': 14000000,
                    'is_active': True
                },
                {
                    'name': 'H3Africa South African Panel',
                    'panel_id': 'h3africa-south-african',
                    'description': 'Southern African populations reference panel for GA4GH workflow processing',
                    'population': 'South African',
                    'build': 'hg38',
                    'samples_count': 1800,
                    'variants_count': 16000000,
                    'is_active': True
                },
                {
                    'name': 'H3Africa North African Panel',
                    'panel_id': 'h3africa-north-african',
                    'description': 'North African populations reference panel for GA4GH workflow processing',
                    'population': 'North African',
                    'build': 'hg38',
                    'samples_count': 1200,
                    'variants_count': 13000000,
                    'is_active': True
                }
            ]
            
            # Add workflow engine information to each panel description
            if 'workflow_engine_versions' in data:
                engines = list(data['workflow_engine_versions'].keys())
                engine_info = f" (Available engines: {', '.join(engines)})"
                for panel in panels:
                    panel['description'] += engine_info
            
            return panels
            
    except Exception as e:
        # Fallback to example panels if API call fails
        return [
            {
                'name': 'GA4GH Reference Panel',
                'panel_id': 'ga4gh-ref-1',
                'description': f'GA4GH standard reference panel (Error: {str(e)})',
                'population': 'Global',
                'build': 'hg38',
                'samples_count': 10000,
                'variants_count': 30000000,
                'is_active': True,
            }
        ]


def sync_dnastack_panels(service):
    """Sync panels for DNASTACK service."""
    try:
        # For DNASTACK, we'll create example panels based on known datasets
        # In a real implementation, you would query the DNASTACK API for available datasets
        
        panels = [
            {
                'name': 'eLwazi AGVD Allele Frequencies',
                'panel_id': 'elwazi-agvd-allele-freq',
                'description': 'African Genomic Variation Database allele frequencies from eLwazi catalogue',
                'population': 'African',
                'build': 'hg38',
                'samples_count': 0,  # Would be fetched from API
                'variants_count': 0,  # Would be fetched from API
                'is_active': True,
            },
            {
                'name': 'DNASTACK Reference Panel',
                'panel_id': 'dnastack-ref-panel',
                'description': 'Standard reference panel available through DNASTACK Omics platform',
                'population': 'Global',
                'build': 'hg38',
                'samples_count': 0,
                'variants_count': 0,
                'is_active': True,
            }
        ]
        
        # Store the DNASTACK-specific configuration
        if not service.api_config:
            service.api_config = {}
        
        # Extract domain from URL for factory usage
        from urllib.parse import urlparse
        parsed = urlparse(service.api_url)
        domain = parsed.netloc or parsed.path
        
        service.api_config['dnastack_factory'] = domain
        service.api_config['install_command'] = 'pip3 install -U dnastack-client-library'
        service.api_config['usage_example'] = f"""
from dnastack import use
from dnastack import DataConnectClient
factory = use('{domain}')
# Get specific data connect client
# data_connect_client = factory.get('data-connect-name')
"""
        service.save()
        
        return panels
        
    except Exception as e:
        # Return a default panel on error
        return [
            {
                'name': 'DNASTACK Default Panel',
                'panel_id': 'dnastack-default',
                'description': f'Default DNASTACK panel (Error syncing: {str(e)})',
                'population': 'Global',
                'build': 'hg38',
                'samples_count': 0,
                'variants_count': 0,
                'is_active': True,
            }
        ]


@method_decorator(staff_member_required, name='dispatch')
class ServiceDetailView(View):
    """Detailed view for a single imputation service."""
    
    template_name = 'admin/imputation/service_detail.html'
    
    def get(self, request, service_id):
        """Display detailed service information."""
        service = get_object_or_404(ImputationService, id=service_id)
        
        context = {
            'service': service,
            'panels': service.reference_panels.filter(is_active=True),
            'opts': ImputationService._meta,
            'has_view_permission': True,
            'has_change_permission': True,
        }
        
        # Get service info for GA4GH services
        if service.api_type == 'ga4gh':
            service_info = service.get_service_info()
            if service_info:
                context['service_info'] = service_info
                
                # Calculate cache age
                if service.api_config and '_service_info' in service.api_config:
                    cached_info = service.api_config['_service_info']
                    if 'timestamp' in cached_info:
                        timestamp = datetime.fromisoformat(cached_info['timestamp'])
                        age = timezone.now() - timestamp.replace(tzinfo=timezone.utc)
                        if age < timedelta(minutes=1):
                            context['cache_age'] = f"{age.seconds} seconds"
                        elif age < timedelta(hours=1):
                            context['cache_age'] = f"{age.seconds // 60} minutes"
                        else:
                            context['cache_age'] = f"{age.seconds // 3600} hours"
                
                # Calculate total jobs
                if 'system_state_counts' in service_info:
                    context['total_jobs'] = sum(service_info['system_state_counts'].values())
                
                # Extract workflow parameters
                if 'default_workflow_engine_parameters' in service_info:
                    workflow_params = {}
                    for param in service_info['default_workflow_engine_parameters']:
                        parts = param['name'].split('|')
                        if len(parts) >= 3:
                            engine = parts[0]
                            param_name = parts[2]
                            if engine not in workflow_params:
                                workflow_params[engine] = []
                            workflow_params[engine].append({
                                'name': param_name,
                                'type': param['type'],
                                'default': param.get('default_value', '')
                            })
                    context['workflow_params'] = workflow_params
                
                # Raw service info for advanced view
                context['raw_service_info'] = json.dumps(service_info, indent=2)
        
        # API configuration
        context['api_config_json'] = json.dumps(service.api_config or {}, indent=2)
        
        return render(request, self.template_name, context)


@staff_member_required
def refresh_service_info(request, service_id):
    """Refresh service info from the API."""
    service = get_object_or_404(ImputationService, id=service_id)
    
    # Clear cache to force refresh
    if service.api_config and '_service_info' in service.api_config:
        del service.api_config['_service_info']
        service.save()
    
    messages.success(request, f'Service information refreshed for {service.name}')
    return redirect('admin:imputation_service_detail', service_id=service_id) 