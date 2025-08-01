"""
Service integration classes for external imputation services.
"""
import requests
import logging
from typing import Dict, List, Optional, Any
from django.conf import settings
from .models import ImputationService, ReferencePanel, ImputationJob

logger = logging.getLogger(__name__)


class BaseImputationService:
    """Base class for imputation service integrations."""
    
    def __init__(self, service: ImputationService):
        self.service = service
        self.api_url = service.api_url
        self.config = getattr(service, 'configuration', None)
        self.session = requests.Session()
        self._setup_authentication()
    
    def _setup_authentication(self):
        """Setup authentication headers and session configuration."""
        if self.config:
            if self.config.api_key:
                self.session.headers.update({'Authorization': f'Bearer {self.config.api_key}'})
            
            # Add any additional headers
            if self.config.additional_headers:
                self.session.headers.update(self.config.additional_headers)
            
            # Set timeout
            self.session.timeout = self.config.timeout_seconds
    
    def _make_request(self, method: str, endpoint: str, **kwargs) -> Dict[str, Any]:
        """Make an authenticated request to the service API."""
        url = f"{self.api_url.rstrip('/')}/{endpoint.lstrip('/')}"
        
        try:
            response = self.session.request(method, url, **kwargs)
            response.raise_for_status()
            return response.json() if response.content else {}
        except requests.exceptions.RequestException as e:
            logger.error(f"API request failed for {self.service.name}: {e}")
            raise
    
    def get_reference_panels(self) -> List[Dict[str, Any]]:
        """Get available reference panels from the service."""
        raise NotImplementedError("Subclasses must implement get_reference_panels")
    
    def submit_job(self, job: ImputationJob, file_data: bytes) -> str:
        """Submit an imputation job to the service."""
        raise NotImplementedError("Subclasses must implement submit_job")
    
    def get_job_status(self, external_job_id: str) -> Dict[str, Any]:
        """Get the status of a submitted job."""
        raise NotImplementedError("Subclasses must implement get_job_status")
    
    def download_results(self, external_job_id: str) -> List[Dict[str, Any]]:
        """Get download URLs for job results."""
        raise NotImplementedError("Subclasses must implement download_results")
    
    def cancel_job(self, external_job_id: str) -> bool:
        """Cancel a submitted job."""
        raise NotImplementedError("Subclasses must implement cancel_job")


class H3AfricaImputationService(BaseImputationService):
    """H3Africa Imputation Service integration."""
    
    def get_reference_panels(self) -> List[Dict[str, Any]]:
        """Get available reference panels from H3Africa."""
        try:
            response = self._make_request('GET', 'reference-panels')
            panels = []
            
            for panel_data in response.get('data', []):
                panels.append({
                    'panel_id': panel_data.get('id'),
                    'name': panel_data.get('name'),
                    'description': panel_data.get('description', ''),
                    'population': panel_data.get('population', ''),
                    'build': panel_data.get('build', 'hg38'),
                    'samples_count': panel_data.get('samples', 0),
                    'variants_count': panel_data.get('variants', 0),
                })
            
            return panels
        except Exception as e:
            logger.error(f"Failed to fetch H3Africa reference panels: {e}")
            return []
    
    def submit_job(self, job: ImputationJob, file_data: bytes) -> str:
        """Submit an imputation job to H3Africa."""
        payload = {
            'name': job.name,
            'description': job.description,
            'reference_panel': job.reference_panel.panel_id,
            'input_format': job.input_format,
            'build': job.build,
            'phasing': job.phasing,
            'population': job.population or 'AFR',
        }
        
        files = {
            'input_file': ('data.vcf', file_data, 'application/octet-stream')
        }
        
        try:
            response = self._make_request('POST', 'jobs', data=payload, files=files)
            return response.get('job_id')
        except Exception as e:
            logger.error(f"Failed to submit job to H3Africa: {e}")
            raise
    
    def get_job_status(self, external_job_id: str) -> Dict[str, Any]:
        """Get job status from H3Africa."""
        try:
            response = self._make_request('GET', f'jobs/{external_job_id}')
            job_data = response.get('data', {})
            
            # Map H3Africa status to our internal status
            status_mapping = {
                'submitted': 'queued',
                'waiting': 'queued',
                'running': 'running',
                'success': 'completed',
                'error': 'failed',
                'cancelled': 'cancelled',
            }
            
            return {
                'status': status_mapping.get(job_data.get('state'), 'pending'),
                'progress': job_data.get('progress', 0),
                'message': job_data.get('message', ''),
                'external_data': job_data
            }
        except Exception as e:
            logger.error(f"Failed to get H3Africa job status: {e}")
            return {'status': 'failed', 'progress': 0, 'message': str(e)}
    
    def download_results(self, external_job_id: str) -> List[Dict[str, Any]]:
        """Get download URLs for H3Africa job results."""
        try:
            response = self._make_request('GET', f'jobs/{external_job_id}/results')
            files = []
            
            for file_data in response.get('files', []):
                files.append({
                    'filename': file_data.get('name'),
                    'file_type': self._map_file_type(file_data.get('type')),
                    'download_url': file_data.get('download_url'),
                    'file_size': file_data.get('size'),
                    'checksum': file_data.get('checksum'),
                })
            
            return files
        except Exception as e:
            logger.error(f"Failed to get H3Africa results: {e}")
            return []
    
    def cancel_job(self, external_job_id: str) -> bool:
        """Cancel a H3Africa job."""
        try:
            self._make_request('DELETE', f'jobs/{external_job_id}')
            return True
        except Exception as e:
            logger.error(f"Failed to cancel H3Africa job: {e}")
            return False
    
    def _map_file_type(self, service_type: str) -> str:
        """Map H3Africa file types to our internal types."""
        mapping = {
            'imputed': 'imputed_data',
            'quality': 'quality_report',
            'log': 'log_file',
            'summary': 'summary',
            'info': 'metadata',
        }
        return mapping.get(service_type, 'imputed_data')


class MichiganImputationService(BaseImputationService):
    """Michigan Imputation Service integration."""
    
    def get_reference_panels(self) -> List[Dict[str, Any]]:
        """Get available reference panels from Michigan."""
        try:
            response = self._make_request('GET', 'refpanels')
            panels = []
            
            for panel_data in response:
                panels.append({
                    'panel_id': panel_data.get('id'),
                    'name': panel_data.get('name'),
                    'description': panel_data.get('description', ''),
                    'population': panel_data.get('population', ''),
                    'build': panel_data.get('build', 'hg38'),
                    'samples_count': panel_data.get('samples', 0),
                    'variants_count': panel_data.get('variants', 0),
                })
            
            return panels
        except Exception as e:
            logger.error(f"Failed to fetch Michigan reference panels: {e}")
            return []
    
    def submit_job(self, job: ImputationJob, file_data: bytes) -> str:
        """Submit an imputation job to Michigan."""
        # Step 1: Upload file
        files = {'file': ('data.vcf.gz', file_data, 'application/gzip')}
        upload_response = self._make_request('POST', 'files', files=files)
        file_id = upload_response.get('id')
        
        # Step 2: Submit job
        payload = {
            'name': job.name,
            'description': job.description,
            'refpanel': job.reference_panel.panel_id,
            'build': job.build,
            'phasing': 'eagle' if job.phasing else 'no_phasing',
            'population': job.population or 'mixed',
            'files': [file_id],
        }
        
        try:
            response = self._make_request('POST', 'jobs/submit', json=payload)
            return response.get('id')
        except Exception as e:
            logger.error(f"Failed to submit job to Michigan: {e}")
            raise
    
    def get_job_status(self, external_job_id: str) -> Dict[str, Any]:
        """Get job status from Michigan."""
        try:
            response = self._make_request('GET', f'jobs/{external_job_id}')
            
            # Map Michigan status to our internal status
            status_mapping = {
                'waiting': 'queued',
                'running': 'running',
                'success': 'completed',
                'error': 'failed',
                'canceled': 'cancelled',
            }
            
            return {
                'status': status_mapping.get(response.get('state'), 'pending'),
                'progress': response.get('progress', 0),
                'message': response.get('message', ''),
                'external_data': response
            }
        except Exception as e:
            logger.error(f"Failed to get Michigan job status: {e}")
            return {'status': 'failed', 'progress': 0, 'message': str(e)}
    
    def download_results(self, external_job_id: str) -> List[Dict[str, Any]]:
        """Get download URLs for Michigan job results."""
        try:
            response = self._make_request('GET', f'jobs/{external_job_id}/results')
            files = []
            
            for file_data in response:
                files.append({
                    'filename': file_data.get('name'),
                    'file_type': self._map_file_type(file_data.get('name')),
                    'download_url': file_data.get('url'),
                    'file_size': file_data.get('size'),
                    'checksum': file_data.get('hash'),
                })
            
            return files
        except Exception as e:
            logger.error(f"Failed to get Michigan results: {e}")
            return []
    
    def cancel_job(self, external_job_id: str) -> bool:
        """Cancel a Michigan job."""
        try:
            self._make_request('DELETE', f'jobs/{external_job_id}')
            return True
        except Exception as e:
            logger.error(f"Failed to cancel Michigan job: {e}")
            return False
    
    def _map_file_type(self, filename: str) -> str:
        """Map Michigan file types based on filename."""
        if 'dose.vcf' in filename.lower():
            return 'imputed_data'
        elif 'info' in filename.lower():
            return 'quality_report'
        elif 'log' in filename.lower():
            return 'log_file'
        elif 'summary' in filename.lower():
            return 'summary'
        else:
            return 'metadata'


class ImputationServiceFactory:
    """Factory class to create appropriate service instances."""
    
    @staticmethod
    def create_service(service: ImputationService) -> BaseImputationService:
        """Create appropriate service instance based on service type."""
        service_classes = {
            'h3africa': H3AfricaImputationService,
            'michigan': MichiganImputationService,
        }
        
        service_class = service_classes.get(service.service_type)
        if not service_class:
            raise ValueError(f"Unknown service type: {service.service_type}")
        
        return service_class(service)


def get_service_instance(service_id: int) -> BaseImputationService:
    """Get a service instance by ID."""
    try:
        service = ImputationService.objects.get(id=service_id, is_active=True)
        return ImputationServiceFactory.create_service(service)
    except ImputationService.DoesNotExist:
        raise ValueError(f"Service with ID {service_id} not found or inactive")


def sync_reference_panels(service_id: int) -> int:
    """Sync reference panels from external service."""
    service = ImputationService.objects.get(id=service_id, is_active=True)
    service_instance = ImputationServiceFactory.create_service(service)
    
    try:
        panels_data = service_instance.get_reference_panels()
        synced_count = 0
        
        for panel_data in panels_data:
            panel, created = ReferencePanel.objects.update_or_create(
                service=service,
                panel_id=panel_data['panel_id'],
                defaults={
                    'name': panel_data['name'],
                    'description': panel_data['description'],
                    'population': panel_data['population'],
                    'build': panel_data['build'],
                    'samples_count': panel_data['samples_count'],
                    'variants_count': panel_data['variants_count'],
                    'is_active': True,
                }
            )
            synced_count += 1
        
        logger.info(f"Synced {synced_count} reference panels for {service.name}")
        return synced_count
        
    except Exception as e:
        logger.error(f"Failed to sync reference panels for {service.name}: {e}")
        raise 