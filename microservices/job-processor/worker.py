"""
Celery worker for job processing tasks.
Handles asynchronous job execution and external service communication.
"""

import os
import logging
import time
import json
from datetime import datetime
from typing import Dict, Any

import httpx
from celery import Celery
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@postgres:5432/job_processing_db')
REDIS_URL = os.getenv('REDIS_URL', 'redis://redis:6379')
SERVICE_REGISTRY_URL = os.getenv('SERVICE_REGISTRY_URL', 'http://service-registry:8002')
FILE_MANAGER_URL = os.getenv('FILE_MANAGER_URL', 'http://file-manager:8004')
NOTIFICATION_URL = os.getenv('NOTIFICATION_URL', 'http://notification:8005')
USER_SERVICE_URL = os.getenv('USER_SERVICE_URL', 'http://user-service:8001')

# Database setup
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Celery app
app = Celery('worker', broker=REDIS_URL, backend=REDIS_URL)

# Import models (assuming they're in the same package)
from main import ImputationJob, JobStatusUpdate, JobLog, JobStatus

class ExternalServiceClient:
    """Client for communicating with external imputation services."""

    def __init__(self):
        # Don't initialize client here to avoid connection pooling issues
        # Create fresh client for each request to avoid event loop problems
        self.timeout = 300.0

    def submit_job_to_service(self, service_info: Dict[str, Any], job_data: Dict[str, Any]) -> Dict[str, Any]:
        """Submit job to external imputation service."""
        service_type = service_info.get('api_type', 'michigan')

        if service_type == 'michigan':
            return self._submit_michigan_job(service_info, job_data)
        elif service_type == 'ga4gh':
            return self._submit_ga4gh_job(service_info, job_data)
        elif service_type == 'dnastack':
            return self._submit_dnastack_job(service_info, job_data)
        else:
            raise ValueError(f"Unsupported service type: {service_type}")

    def _submit_michigan_job(self, service_info: Dict[str, Any], job_data: Dict[str, Any]) -> Dict[str, Any]:
        """Submit job to Michigan Imputation Server (including H3Africa)."""
        try:
            base_url = service_info['base_url'].rstrip('/')
            # Michigan API requires specific tool endpoint (imputationserver2 for newer versions)
            submit_url = f"{base_url}/api/v2/jobs/submit/imputationserver2"

            # Get USER's API token from user service
            user_id = job_data.get('user_id')
            service_id = service_info.get('id')

            logger.info(f"Michigan API: Fetching credentials for user {user_id}, service {service_id}")

            # Fetch user's personal credentials
            with httpx.Client() as user_client:
                cred_response = user_client.get(
                    f"{USER_SERVICE_URL}/internal/users/{user_id}/service-credentials/{service_id}"
                )
                cred_response.raise_for_status()
                user_cred = cred_response.json()

            if not user_cred.get('has_credential'):
                error_msg = f"No credentials configured for service {service_info.get('name')}. Please add your API token in Settings → Service Credentials."
                logger.error(f"Michigan API: {error_msg}")
                return {
                    'error': error_msg,
                    'status': 'failed',
                    'requires_user_action': True
                }

            # Use user's personal API token
            api_token = user_cred.get('api_token')
            if not api_token:
                logger.error(f"Michigan API: User {user_id} has credential but no API token")
                return {
                    'error': 'Invalid credential configuration. Please reconfigure your API token.',
                    'status': 'failed'
                }

            # Download input file from file manager
            logger.info(f"Michigan API: Downloading input file from {job_data['input_file_url']}")
            with httpx.Client(timeout=self.timeout) as client:
                file_response = client.get(job_data['input_file_url'])
            file_response.raise_for_status()
            file_content = file_response.content
            logger.info(f"Michigan API: Downloaded {len(file_content)} bytes")

            # Prepare multipart form data with file and parameters
            # Michigan API expects 'files' key for file upload
            files = {
                'files': ('input.vcf.gz', file_content, 'application/gzip')
            }

            # Fetch reference panel details to get Cloudgene app ID
            # For Michigan API, we need the slug field which contains the Cloudgene format
            # e.g., "apps@h3africa-v6hc-s@1.0.0" not the database ID or display name
            with httpx.Client() as panel_client:
                panel_response = panel_client.get(
                    f"{SERVICE_REGISTRY_URL}/panels/{job_data['reference_panel']}"
                )
                panel_response.raise_for_status()
                panel_info = panel_response.json()

            panel_identifier = panel_info.get('slug') or panel_info.get('name')  # Use slug (Cloudgene format), fallback to name

            logger.info(f"Michigan API: Using reference panel '{panel_identifier}' (from panel ID: {job_data['reference_panel']})")

            # Michigan API parameters (imputationserver2 auto-detects format from file extension)
            data = {
                'refpanel': panel_identifier,  # Cloudgene app format: apps@{app-id}@{version}
                'build': job_data['build'],
                'phasing': 'eagle' if job_data.get('phasing', True) else 'no_phasing',
                'population': job_data.get('population') or 'mixed',  # Default to 'mixed' if None/empty
                'mode': 'imputation'
            }

            # Michigan API uses X-Auth-Token header for authentication
            headers = {
                'X-Auth-Token': api_token
            }

            logger.info(f"Michigan API: Submitting job to {submit_url}")
            logger.info(f"Michigan API: Full parameters - {data}")
            logger.info(f"Michigan API: Parameters - panel: {data['refpanel']}, build: {data['build']}, phasing: {data['phasing']}")

            # Submit job with authentication and extended timeout for file upload
            with httpx.Client(timeout=self.timeout) as client:
                response = client.post(
                submit_url,
                files=files,
                data=data,
                headers=headers,
                timeout=httpx.Timeout(connect=60.0, read=300.0, write=60.0, pool=30.0)  # 5min for upload
            )
            response.raise_for_status()

            result = response.json()
            external_job_id = result.get('id') or result.get('jobId')

            logger.info(f"Michigan API: Job submitted successfully - External Job ID: {external_job_id}")

            return {
                'external_job_id': external_job_id,
                'status': 'submitted',
                'service_response': result
            }

        except httpx.HTTPStatusError as e:
            error_msg = f"HTTP {e.response.status_code}"
            try:
                error_detail = e.response.json()
                error_msg += f": {error_detail}"
            except:
                error_msg += f": {e.response.text[:200]}"

            logger.error(f"Michigan job submission failed: {error_msg}")
            return {
                'error': error_msg,
                'status': 'failed'
            }
        except Exception as e:
            logger.error(f"Michigan job submission failed: {str(e)}")
            return {
                'error': str(e),
                'status': 'failed'
            }
    
    def _submit_ga4gh_job(self, service_info: Dict[str, Any], job_data: Dict[str, Any]) -> Dict[str, Any]:
        """Submit job to GA4GH WES service."""
        try:
            # GA4GH WES job submission
            base_url = service_info['base_url'].rstrip('/')
            submit_url = f"{base_url}/ga4gh/wes/v1/runs"

            # Prepare workflow request
            workflow_params = {
                'input_file': job_data['input_file_url'],
                'reference_panel': job_data['reference_panel'],
                'build': job_data['build'],
                'phasing': job_data['phasing'],
                'population': job_data.get('population')
            }

            request_data = {
                'workflow_params': workflow_params,
                'workflow_type': 'imputation',
                'workflow_type_version': '1.0'
            }

            with httpx.Client(timeout=self.timeout) as client:
                response = client.post(submit_url, json=request_data)
            response.raise_for_status()

            result = response.json()
            return {
                'external_job_id': result.get('run_id'),
                'status': 'submitted',
                'service_response': result
            }

        except Exception as e:
            logger.error(f"GA4GH job submission failed: {e}")
            return {
                'error': str(e),
                'status': 'failed'
            }

    def _submit_dnastack_job(self, service_info: Dict[str, Any], job_data: Dict[str, Any]) -> Dict[str, Any]:
        """Submit job to DNASTACK service."""
        try:
            # DNASTACK-specific job submission
            base_url = service_info['base_url'].rstrip('/')
            submit_url = f"{base_url}/api/jobs"

            # Prepare job request
            request_data = {
                'type': 'imputation',
                'input': {
                    'file_url': job_data['input_file_url'],
                    'format': job_data['input_format'],
                    'build': job_data['build']
                },
                'parameters': {
                    'reference_panel': job_data['reference_panel'],
                    'phasing': job_data['phasing'],
                    'population': job_data.get('population')
                }
            }

            with httpx.Client(timeout=self.timeout) as client:
                response = client.post(submit_url, json=request_data)
            response.raise_for_status()

            result = response.json()
            return {
                'external_job_id': result.get('job_id'),
                'status': 'submitted',
                'service_response': result
            }

        except Exception as e:
            logger.error(f"DNASTACK job submission failed: {e}")
            return {
                'error': str(e),
                'status': 'failed'
            }
    
    def check_job_status(self, service_info: Dict[str, Any], external_job_id: str, user_id: int = None) -> Dict[str, Any]:
        """Check job status on external service."""
        service_type = service_info.get('api_type', 'michigan')

        try:
            if service_type == 'michigan':
                # Michigan requires user_id for authentication
                return self._check_michigan_status(service_info, external_job_id, user_id)
            elif service_type == 'ga4gh':
                return self._check_ga4gh_status(service_info, external_job_id)
            elif service_type == 'dnastack':
                return self._check_dnastack_status(service_info, external_job_id)
            else:
                return {'status': 'unknown', 'error': f'Unsupported service type: {service_type}'}
        except Exception as e:
            logger.error(f"Status check failed: {e}")
            return {'status': 'error', 'error': str(e)}

    def _check_michigan_status(self, service_info: Dict[str, Any], external_job_id: str, user_id: int = None) -> Dict[str, Any]:
        """Check Michigan job status."""
        try:
            base_url = service_info['base_url'].rstrip('/')
            # Michigan API: Get full job details endpoint (NO /status suffix - that returns 401)
            status_url = f"{base_url}/api/v2/jobs/{external_job_id}"

            # Get user's API token for authenticated status check
            # Michigan API REQUIRES authentication for all endpoints including status checks
            api_token = None
            if user_id:
                service_id = service_info.get('id')
                with httpx.Client() as user_client:
                    cred_response = user_client.get(
                        f"{USER_SERVICE_URL}/internal/users/{user_id}/service-credentials/{service_id}"
                    )
                    if cred_response.status_code == 200:
                        user_cred = cred_response.json()
                        if user_cred.get('has_credential'):
                            api_token = user_cred.get('api_token')

            if not api_token:
                logger.error(f"Michigan API: Cannot check status without API token for user {user_id}")
                return {
                    'status': 'error',
                    'progress': 0,
                    'message': 'Authentication required for status check',
                    'service_response': {},
                    'steps': []
                }

            headers = {'X-Auth-Token': api_token}

            with httpx.Client(timeout=self.timeout) as client:
                response = client.get(status_url, headers=headers)
            response.raise_for_status()

            result = response.json()

            # Log full response for debugging (only when job completes)
            state_code = result.get('state', 0)
            if state_code in [3, 4]:  # completed states
                logger.info(f"Michigan API: Job {external_job_id} completed. Full response: {json.dumps(result, indent=2)}")

            # Michigan uses numeric state codes (not strings)
            # 1=waiting, 2=running, 3=success(exportable), 4=success(complete), 5=failed, 6=cancelled, 7=deleted
            status_mapping = {
                1: 'queued',      # waiting
                2: 'running',     # running
                3: 'completed',   # success (exportable)
                4: 'completed',   # success (complete)
                5: 'failed',      # error
                6: 'cancelled',   # cancelled
                7: 'cancelled'    # deleted/retired
            }

            internal_status = status_mapping.get(state_code, 'unknown')

            # Calculate progress based on state and steps
            steps = result.get('steps', [])
            total_steps = len(steps) if steps else 4
            completed_steps = sum(1 for step in steps if step.get('logMessages'))

            if state_code == 1:  # waiting
                progress = 5
            elif state_code == 2:  # running
                progress = 10 + int((completed_steps / total_steps) * 80) if total_steps > 0 else 50
            elif state_code in [3, 4]:  # completed
                progress = 100
            elif state_code == 5:  # failed
                progress = completed_steps * 25 if completed_steps else 10
            else:
                progress = 0

            # Extract error message if failed
            error_message = None
            if state_code == 5:
                for step in steps:
                    for msg in step.get('logMessages', []):
                        if msg.get('type') == 0 and 'error' in msg.get('message', '').lower():
                            error_message = msg.get('message')
                            break
                    if error_message:
                        break

                if not error_message:
                    error_message = 'Job failed during execution'

            return {
                'status': internal_status,
                'progress': progress,
                'message': error_message or f'Job {internal_status}',
                'service_response': result,
                'steps': steps
            }

        except Exception as e:
            logger.error(f"Michigan status check failed: {e}")
            return {
                'status': 'error',
                'progress': 0,
                'message': str(e),
                'service_response': {},
                'steps': []
            }
    
    def _check_ga4gh_status(self, service_info: Dict[str, Any], external_job_id: str) -> Dict[str, Any]:
        """Check GA4GH job status."""
        base_url = service_info['base_url'].rstrip('/')
        status_url = f"{base_url}/ga4gh/wes/v1/runs/{external_job_id}/status"
        
        with httpx.Client(timeout=self.timeout) as client:
                response = client.get(status_url)
        response.raise_for_status()
        
        result = response.json()
        status_mapping = {
            'QUEUED': 'queued',
            'INITIALIZING': 'queued',
            'RUNNING': 'running',
            'PAUSED': 'running',
            'COMPLETE': 'completed',
            'EXECUTOR_ERROR': 'failed',
            'SYSTEM_ERROR': 'failed',
            'CANCELED': 'cancelled'
        }
        
        return {
            'status': status_mapping.get(result.get('state', 'UNKNOWN'), 'unknown'),
            'progress': 50 if result.get('state') == 'RUNNING' else (100 if result.get('state') == 'COMPLETE' else 0),
            'message': result.get('state', ''),
            'service_response': result
        }
    
    def _check_dnastack_status(self, service_info: Dict[str, Any], external_job_id: str) -> Dict[str, Any]:
        """Check DNASTACK job status."""
        base_url = service_info['base_url'].rstrip('/')
        status_url = f"{base_url}/api/jobs/{external_job_id}"

        with httpx.Client(timeout=self.timeout) as client:
                response = client.get(status_url)
        response.raise_for_status()

        result = response.json()
        status_mapping = {
            'pending': 'queued',
            'running': 'running',
            'completed': 'completed',
            'failed': 'failed',
            'cancelled': 'cancelled'
        }

        return {
            'status': status_mapping.get(result.get('status', 'unknown'), 'unknown'),
            'progress': result.get('progress', 0),
            'message': result.get('message', ''),
            'service_response': result
        }

    def download_job_results(self, service_info: Dict[str, Any], external_job_id: str, user_id: int = None, service_id: int = None) -> bytes:
        """Download results from external imputation service."""
        service_type = service_info.get('api_type', 'michigan')

        if service_type == 'michigan':
            return self._download_michigan_results(service_info, external_job_id, user_id, service_id)
        elif service_type == 'ga4gh':
            return self._download_ga4gh_results(service_info, external_job_id)
        elif service_type == 'dnastack':
            return self._download_dnastack_results(service_info, external_job_id)
        else:
            raise ValueError(f"Unsupported service type: {service_type}")

    def _download_michigan_results(self, service_info: Dict[str, Any], external_job_id: str, user_id: int = None, service_id: int = None) -> bytes:
        """Download results from Michigan Imputation Server."""
        try:
            base_url = service_info['base_url'].rstrip('/')
            results_url = f"{base_url}/api/v2/jobs/{external_job_id}/results"

            # Get user's API token for authenticated download (same as job submission)
            api_token = None
            if user_id and service_id:
                logger.info(f"Michigan API: Fetching credentials for user {user_id}, service {service_id}")
                with httpx.Client() as user_client:
                    cred_response = user_client.get(
                        f"{USER_SERVICE_URL}/internal/users/{user_id}/service-credentials/{service_id}"
                    )
                    cred_response.raise_for_status()
                    user_cred = cred_response.json()
                    api_token = user_cred.get('api_token')

            if not api_token:
                logger.warning("Michigan API: No API token available, attempting download without authentication")

            headers = {'X-Auth-Token': api_token} if api_token else {}

            logger.info(f"Michigan API: Downloading results from {results_url}")

            # Michigan returns a zip file with imputed results
            with httpx.Client(timeout=self.timeout) as client:
                response = client.get(
                results_url,
                headers=headers,
                timeout=httpx.Timeout(connect=30.0, read=600.0, write=30.0, pool=30.0)  # 10min for download
            )
            response.raise_for_status()

            results_data = response.content
            logger.info(f"Michigan API: Downloaded {len(results_data)} bytes")

            return results_data

        except Exception as e:
            logger.error(f"Michigan results download failed: {e}")
            raise

    def _download_ga4gh_results(self, service_info: Dict[str, Any], external_job_id: str) -> bytes:
        """Download results from GA4GH WES service."""
        try:
            base_url = service_info['base_url'].rstrip('/')

            # First get run details to find output files
            run_url = f"{base_url}/ga4gh/wes/v1/runs/{external_job_id}"
            with httpx.Client(timeout=self.timeout) as client:
                run_response = client.get(run_url)
            run_response.raise_for_status()

            run_data = run_response.json()
            outputs = run_data.get('outputs', {})

            # Download the main output file
            if outputs:
                output_url = outputs.get('output_file') or list(outputs.values())[0]
                with httpx.Client(timeout=self.timeout) as client:
                    response = client.get(output_url)
                response.raise_for_status()
                return response.content
            else:
                raise ValueError("No output files found in GA4GH run results")

        except Exception as e:
            logger.error(f"GA4GH results download failed: {e}")
            raise

    def _download_dnastack_results(self, service_info: Dict[str, Any], external_job_id: str) -> bytes:
        """Download results from DNASTACK service."""
        try:
            base_url = service_info['base_url'].rstrip('/')
            results_url = f"{base_url}/api/jobs/{external_job_id}/results"

            with httpx.Client(timeout=self.timeout) as client:
                response = client.get(results_url)
            response.raise_for_status()

            return response.content

        except Exception as e:
            logger.error(f"DNASTACK results download failed: {e}")
            raise

    def extract_result_file_links(self, service_info: Dict[str, Any], service_response: Dict[str, Any], external_job_id: str) -> list:
        """Extract result file download links from service response."""
        service_type = service_info.get('api_type', 'michigan')

        if service_type == 'michigan':
            return self._extract_michigan_result_links(service_info, service_response, external_job_id)
        elif service_type == 'ga4gh':
            return self._extract_ga4gh_result_links(service_response)
        elif service_type == 'dnastack':
            return self._extract_dnastack_result_links(service_response)
        else:
            logger.warning(f"Unsupported service type for result extraction: {service_type}")
            return []

    def _extract_michigan_result_links(self, service_info: Dict[str, Any], service_response: Dict[str, Any], external_job_id: str) -> list:
        """Extract result file links from Michigan API response."""
        try:
            base_url = service_info['base_url'].rstrip('/')
            result_files = []

            # Michigan API response structure: outputParams -> files
            output_params = service_response.get('outputParams', [])

            for param in output_params:
                if param.get('download', False):  # Only include downloadable files
                    files = param.get('files', [])
                    description = param.get('description', 'Output Files')

                    for file_info in files:
                        # Michigan provides file paths in the 'path' field
                        # Also check the 'tree' structure which contains download paths
                        file_path = file_info.get('path', '')
                        file_name = file_info.get('name', '')
                        file_hash = file_info.get('hash', '')
                        file_size_str = file_info.get('size', '0')

                        # The download URL pattern for Michigan API
                        # Based on the tree structure in the response, paths look like: /browse/{hash}/{file_path}
                        # We'll construct the full download URL
                        download_url = f"{base_url}/results/{external_job_id}/{file_path}"

                        # Convert size string to bytes (e.g., "82 MB" -> bytes)
                        file_size_bytes = self._parse_size_string(file_size_str)

                        result_files.append({
                            'name': file_name,
                            'download_url': download_url,
                            'hash': file_hash,
                            'size': file_size_bytes,
                            'description': description
                        })

                        logger.info(f"Michigan API: Extracted result file: {file_name} ({file_size_str})")

            return result_files

        except Exception as e:
            logger.error(f"Failed to extract Michigan result links: {e}")
            return []

    def _parse_size_string(self, size_str: str) -> int:
        """Parse size string like '82 MB', '1 KB' to bytes."""
        try:
            if not size_str or size_str == '0 bytes':
                return 0

            parts = size_str.strip().split()
            if len(parts) != 2:
                return 0

            value = float(parts[0].replace(',', ''))
            unit = parts[1].upper()

            multipliers = {
                'BYTES': 1,
                'KB': 1024,
                'MB': 1024 * 1024,
                'GB': 1024 * 1024 * 1024
            }

            return int(value * multipliers.get(unit, 1))
        except Exception:
            return 0

    def _extract_ga4gh_result_links(self, service_response: Dict[str, Any]) -> list:
        """Extract result file links from GA4GH response."""
        # TODO: Implement GA4GH result extraction
        return []

    def _extract_dnastack_result_links(self, service_response: Dict[str, Any]) -> list:
        """Extract result file links from DNASTACK response."""
        # TODO: Implement DNASTACK result extraction
        return []

# Service communication helpers
def get_service_info(service_id: int) -> Dict[str, Any]:
    """Get service information from service registry."""
    with httpx.Client() as client:
        response = client.get(f"{SERVICE_REGISTRY_URL}/services/{service_id}")
        response.raise_for_status()
        return response.json()

def get_file_download_url(file_id: int) -> str:
    """Get file download URL from file manager."""
    with httpx.Client() as client:
        response = client.get(f"{FILE_MANAGER_URL}/files/{file_id}/download")
        response.raise_for_status()
        result = response.json()
        download_url = result['download_url']

        # Ensure absolute URL - prepend FILE_MANAGER_URL if relative path
        if download_url.startswith('/'):
            download_url = f"{FILE_MANAGER_URL}{download_url}"

        return download_url

def send_notification(user_id: int, notification_type: str, title: str, message: str, data: Dict[str, Any] = None):
    """Send notification via notification service."""
    with httpx.Client() as client:
        payload = {
            "user_id": user_id,
            "type": notification_type,
            "title": title,
            "message": message,
            "data": data or {},
            "channels": ["web", "email"]
        }
        response = client.post(f"{NOTIFICATION_URL}/notifications", json=payload)
        response.raise_for_status()

def update_parent_job_status(parent_job_id: str):
    """
    Update parent job status based on child job statuses.

    Rules:
    - If all children are completed: parent = completed
    - If any child is failed: parent = failed
    - If any child is running: parent = running
    - Otherwise: parent = queued
    """
    db = SessionLocal()
    try:
        # Get all child jobs
        child_jobs = db.query(ImputationJob).filter(
            ImputationJob.parent_job_id == parent_job_id
        ).all()

        if not child_jobs:
            logger.warning(f"No child jobs found for parent {parent_job_id}")
            return

        # Count job statuses
        total = len(child_jobs)
        completed_count = sum(1 for job in child_jobs if job.status == 'completed')
        failed_count = sum(1 for job in child_jobs if job.status == 'failed')
        running_count = sum(1 for job in child_jobs if job.status == 'running')

        # Calculate aggregate progress
        total_progress = sum(job.progress_percentage for job in child_jobs)
        avg_progress = total_progress // total if total > 0 else 0

        # Determine parent status
        if completed_count == total:
            new_status = 'completed'
            new_progress = 100
        elif failed_count > 0:
            new_status = 'failed'
            new_progress = avg_progress
        elif running_count > 0:
            new_status = 'running'
            new_progress = avg_progress
        else:
            new_status = 'queued'
            new_progress = 0

        # Update parent job
        parent_job = db.query(ImputationJob).filter(
            ImputationJob.id == parent_job_id
        ).first()

        if parent_job:
            parent_job.status = new_status
            parent_job.progress_percentage = new_progress
            parent_job.updated_at = datetime.utcnow()

            # Set timestamps
            if new_status == 'running' and not parent_job.started_at:
                parent_job.started_at = datetime.utcnow()
            elif new_status in ['completed', 'failed']:
                if not parent_job.completed_at:
                    parent_job.completed_at = datetime.utcnow()
                if parent_job.started_at:
                    parent_job.execution_time_seconds = int(
                        (parent_job.completed_at - parent_job.started_at).total_seconds()
                    )

            # Build status message
            message = f"{completed_count}/{total} jobs completed"
            if failed_count > 0:
                message += f", {failed_count} failed"
            if running_count > 0:
                message += f", {running_count} running"

            parent_job.error_message = message if new_status == 'failed' else None

            db.commit()

            logger.info(f"Updated parent job {parent_job_id}: status={new_status}, progress={new_progress}%")

    except Exception as e:
        logger.error(f"Failed to update parent job {parent_job_id}: {e}")
        db.rollback()
    finally:
        db.close()

def update_job_status_sync(job_id: str, status: str, progress: int = None, message: str = None, error: str = None, service_response: Dict[str, Any] = None):
    """Update job status synchronously."""
    db = SessionLocal()
    try:
        job = db.query(ImputationJob).filter(ImputationJob.id == job_id).first()
        if job:
            job.status = status
            if progress is not None:
                job.progress_percentage = progress
            if message:
                job.error_message = message if status == 'failed' else None
            if error:
                job.error_message = error
            if service_response is not None:
                job.service_response = service_response
            job.updated_at = datetime.utcnow()
            
            if status == 'running' and not job.started_at:
                job.started_at = datetime.utcnow()
            elif status in ['completed', 'failed', 'cancelled']:
                if not job.completed_at:
                    job.completed_at = datetime.utcnow()
                if job.started_at:
                    job.execution_time_seconds = int((job.completed_at - job.started_at).total_seconds())
            
            # Create status update record
            status_update = JobStatusUpdate(
                job_id=job_id,
                status=status,
                progress_percentage=progress or job.progress_percentage,
                message=message
            )
            db.add(status_update)

            # Store parent_job_id before commit (in case we need it after connection closes)
            parent_job_id = str(job.parent_job_id) if job.parent_job_id else None

            db.commit()

            # Update parent job status if this is a child job
            if parent_job_id:
                try:
                    update_parent_job_status(parent_job_id)
                except Exception as e:
                    logger.error(f"Failed to update parent job status: {e}")

            # Send notification asynchronously in a background thread
            # Note: Using asyncio.run() instead of create_task() for Celery compatibility
            try:
                send_notification(
                    user_id=job.user_id,
                    notification_type="job_status_update",
                    title=f"Job {status.title()}",
                    message=f"Your job '{job.name}' is now {status}",
                    data={
                        "job_id": str(job.id),
                        "job_name": job.name,
                        "status": status,
                        "progress": job.progress_percentage
                    }
                )
            except Exception as e:
                logger.warning(f"Failed to send notification: {e}")
    finally:
        db.close()

# Celery tasks
@app.task(bind=True)
def process_job(self, job_id: str):
    """Process an imputation job."""
    logger.info(f"Starting job processing for job {job_id}")
    
    db = SessionLocal()
    try:
        # Get job details
        job = db.query(ImputationJob).filter(ImputationJob.id == job_id).first()
        if not job:
            logger.error(f"Job {job_id} not found")
            return
        
        # Update status to running
        update_job_status_sync(job_id, 'running', 0, "Job processing started")
        
        # Get service information
        service_info = get_service_info(job.service_id)
        if not service_info:
            update_job_status_sync(job_id, 'failed', 0, "Failed to get service information")
            return
        
        # Get file download URL
        file_url = get_file_download_url(job.input_file_id)
        if not file_url:
            update_job_status_sync(job_id, 'failed', 0, "Failed to get input file")
            return
        
        # Prepare job data for external service
        job_data = {
            'user_id': job.user_id,  # ← CRITICAL: Include user_id for credential lookup
            'input_file_url': file_url,
            'input_format': job.input_format,
            'reference_panel': job.reference_panel_id,
            'build': job.build,
            'phasing': job.phasing,
            'population': job.population
        }
        
        # Submit job to external service
        client = ExternalServiceClient()
        submission_result = client.submit_job_to_service(service_info, job_data)
        
        if submission_result.get('status') == 'failed':
            update_job_status_sync(job_id, 'failed', 0, submission_result.get('error', 'Job submission failed'))
            return
        
        # Update job with external job ID
        job.external_job_id = submission_result.get('external_job_id')
        job.service_response = submission_result.get('service_response', {})
        db.commit()
        
        update_job_status_sync(job_id, 'running', 10, "Job submitted to external service")
        
        # Monitor job progress
        max_checks = 720  # 6 hours with 30-second intervals
        check_count = 0
        
        while check_count < max_checks:
            time.sleep(30)  # Wait 30 seconds between checks
            check_count += 1

            # Check job status on external service (pass user_id for Michigan auth)
            status_result = client.check_job_status(service_info, job.external_job_id, job.user_id)
            
            external_status = status_result.get('status', 'unknown')
            progress = status_result.get('progress', 0)
            message = status_result.get('message', '')
            
            # Update local job status
            if external_status == 'completed':
                # Extract result file links from external service response
                try:
                    logger.info(f"Job {job_id}: Extracting result file links from service response")
                    result_files = client.extract_result_file_links(service_info, status_result.get('service_response', {}), job.external_job_id)

                    if result_files:
                        logger.info(f"Job {job_id}: Found {len(result_files)} result files")
                        # Store result file links in file manager
                        for file_info in result_files:
                            try:
                                with httpx.Client() as fm_client:
                                    response = fm_client.post(
                                        f"{FILE_MANAGER_URL}/files/external-link",
                                        json={
                                            'job_id': str(job_id),
                                            'user_id': job.user_id,
                                            'filename': file_info['name'],
                                            'file_size': file_info.get('size', 0),
                                            'file_type': 'output',
                                            'external_url': file_info['download_url'],
                                            'file_hash': file_info.get('hash', ''),
                                            'description': file_info.get('description', '')
                                        }
                                    )
                                    if response.status_code == 200:
                                        logger.info(f"Job {job_id}: Stored link for {file_info['name']}")
                            except Exception as link_error:
                                logger.warning(f"Job {job_id}: Failed to store link for {file_info['name']}: {link_error}")
                    else:
                        logger.warning(f"Job {job_id}: No result files found in service response")

                except Exception as e:
                    error_msg = f"Completed but failed to extract result links: {str(e)}"
                    logger.error(f"Job {job_id}: {error_msg}")
                    # Don't fail the job - it completed successfully even if we couldn't extract links
                    logger.warning(f"Job {job_id}: Marking as completed despite link extraction failure")

                update_job_status_sync(job_id, 'completed', 100, "Job completed successfully", service_response=status_result.get('service_response'))
                break
            elif external_status == 'failed':
                update_job_status_sync(job_id, 'failed', progress, f"Job failed: {message}", service_response=status_result.get('service_response'))
                break
            elif external_status == 'cancelled':
                update_job_status_sync(job_id, 'cancelled', progress, "Job was cancelled", service_response=status_result.get('service_response'))
                break
            elif external_status in ['running', 'queued']:
                # Calculate progress (10% for submission + 80% for processing + 10% for completion)
                calculated_progress = min(10 + int(progress * 0.8), 90)
                update_job_status_sync(job_id, 'running', calculated_progress, f"Job in progress: {message}")
            
            # Check if job was cancelled locally
            db.refresh(job)
            if job.status == 'cancelled':
                break
        
        # If we've exceeded max checks and job is still running, mark as failed
        if check_count >= max_checks and job.status == 'running':
            update_job_status_sync(job_id, 'failed', 0, "Job timeout - exceeded maximum processing time")
        
    except Exception as e:
        logger.error(f"Job processing failed for {job_id}: {e}")
        update_job_status_sync(job_id, 'failed', 0, f"Job processing error: {str(e)}")
    finally:
        db.close()

@app.task
def cancel_job(job_id: str):
    """Cancel a job."""
    logger.info(f"Cancelling job {job_id}")
    
    db = SessionLocal()
    try:
        job = db.query(ImputationJob).filter(ImputationJob.id == job_id).first()
        if not job:
            logger.error(f"Job {job_id} not found")
            return
        
        # If job has external ID, try to cancel on external service
        if job.external_job_id:
            try:
                service_info = get_service_info(job.service_id)
                # Implementation would depend on external service API
                # For now, just update local status
                pass
            except Exception as e:
                logger.error(f"Failed to cancel external job: {e}")
        
        update_job_status_sync(job_id, 'cancelled', job.progress_percentage, "Job cancelled by user")
        
    except Exception as e:
        logger.error(f"Job cancellation failed for {job_id}: {e}")
    finally:
        db.close()


@app.task
def poll_job_statuses():
    """
    Periodic task to poll external service job statuses and update internal records.
    Should be called by celery-beat every 2-5 minutes.
    """
    logger.info("Polling job statuses from external services")

    db = SessionLocal()
    try:
        # Get all running jobs with external job IDs
        running_jobs = db.query(ImputationJob).filter(
            ImputationJob.status.in_(['queued', 'running']),
            ImputationJob.external_job_id.isnot(None)
        ).all()

        logger.info(f"Found {len(running_jobs)} jobs to check")

        for job in running_jobs:
            try:
                # Get service info
                service_info = get_service_info(job.service_id)

                # Check status based on service type
                service_type = service_info.get('api_type', 'michigan')
                client = ExternalServiceClient()

                if service_type == 'michigan':
                    status_result = client._check_michigan_status(service_info, job.external_job_id, job.user_id)
                elif service_type == 'ga4gh':
                    status_result = client._check_ga4gh_status(service_info, job.external_job_id)
                elif service_type == 'dnastack':
                    status_result = client._check_dnastack_status(service_info, job.external_job_id)
                else:
                    logger.warning(f"Unknown service type {service_type} for job {job.id}")
                    continue

                # Extract logs from steps (Michigan API specific)
                steps = status_result.get('steps', [])

                # Sync logs to database
                if steps:
                    try:
                        # Clear old logs for this job (we'll replace with fresh data)
                        db.query(JobLog).filter(JobLog.job_id == job.id).delete()

                        # Parse and store logs from each step
                        for step_index, step in enumerate(steps):
                            step_name = step.get('name', f'Step {step_index + 1}')
                            log_messages = step.get('logMessages', [])

                            for msg in log_messages:
                                # Michigan message types: 0=error, 1=info, 2=warning (assumed)
                                msg_type_mapping = {0: 'error', 1: 'info', 2: 'warning'}
                                log_type = msg_type_mapping.get(msg.get('type', 1), 'info')

                                job_log = JobLog(
                                    job_id=job.id,
                                    step_name=step_name,
                                    step_index=step_index,
                                    log_type=log_type,
                                    message=msg.get('message', ''),
                                    timestamp=datetime.utcnow()
                                )
                                db.add(job_log)

                        db.commit()
                        logger.info(f"Job {job.id}: Synced {sum(len(s.get('logMessages', [])) for s in steps)} log messages from {len(steps)} steps")
                    except Exception as e:
                        logger.error(f"Job {job.id}: Failed to sync logs: {e}")
                        db.rollback()

                # Update job status if changed
                new_status = status_result.get('status')
                new_progress = status_result.get('progress', 0)
                message = status_result.get('message', '')

                if new_status and new_status != job.status:
                    logger.info(f"Job {job.id}: {job.status} -> {new_status} (progress: {new_progress}%)")

                    old_status = job.status
                    job.status = new_status
                    job.progress_percentage = new_progress
                    job.updated_at = datetime.utcnow()

                    # Set timestamps
                    if new_status == 'running' and not job.started_at:
                        job.started_at = datetime.utcnow()

                    if new_status in ['completed', 'failed', 'cancelled']:
                        if not job.completed_at:
                            job.completed_at = datetime.utcnow()

                        if job.started_at:
                            execution_time = (job.completed_at - job.started_at).total_seconds()
                            job.execution_time_seconds = int(execution_time)

                        if new_status == 'failed':
                            job.error_message = message

                    db.commit()

                    # Create status update record
                    status_update = JobStatusUpdate(
                        job_id=job.id,
                        status=new_status,
                        message=message or f'Job {new_status}',
                        progress_percentage=new_progress
                    )
                    db.add(status_update)
                    db.commit()

                    # Send notification to user
                    try:
                        send_notification(
                            user_id=job.user_id,
                            notification_type="job_status_update",
                            title=f"Job {new_status.title()}",
                            message=f"Your job '{job.name}' is now {new_status}",
                            data={"job_id": str(job.id), "status": new_status}
                        )
                    except Exception as e:
                        logger.warning(f"Failed to send notification: {e}")

                elif new_progress != job.progress_percentage:
                    # Update progress even if status hasn't changed
                    job.progress_percentage = new_progress
                    job.updated_at = datetime.utcnow()
                    db.commit()

            except Exception as e:
                logger.error(f"Error checking status for job {job.id}: {e}")
                continue

        logger.info("Completed job status polling")

    except Exception as e:
        logger.error(f"Job status polling failed: {e}")
    finally:
        db.close()


# Configure celery beat schedule for periodic tasks
app.conf.beat_schedule = {
    'poll-job-statuses': {
        'task': 'worker.poll_job_statuses',
        'schedule': 120.0,  # Run every 2 minutes
    },
}
app.conf.timezone = 'UTC'


if __name__ == '__main__':
    app.start()
