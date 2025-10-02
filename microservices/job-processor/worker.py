"""
Celery worker for job processing tasks.
Handles asynchronous job execution and external service communication.
"""

import os
import logging
import asyncio
import time
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

# Database setup
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Celery app
app = Celery('worker', broker=REDIS_URL, backend=REDIS_URL)

# Import models (assuming they're in the same package)
from main import ImputationJob, JobStatusUpdate, JobStatus

class ExternalServiceClient:
    """Client for communicating with external imputation services."""
    
    def __init__(self):
        self.client = httpx.AsyncClient(timeout=300.0)  # 5 minute timeout for long operations
    
    async def submit_job_to_service(self, service_info: Dict[str, Any], job_data: Dict[str, Any]) -> Dict[str, Any]:
        """Submit job to external imputation service."""
        service_type = service_info.get('api_type', 'michigan')
        
        if service_type == 'michigan':
            return await self._submit_michigan_job(service_info, job_data)
        elif service_type == 'ga4gh':
            return await self._submit_ga4gh_job(service_info, job_data)
        elif service_type == 'dnastack':
            return await self._submit_dnastack_job(service_info, job_data)
        else:
            raise ValueError(f"Unsupported service type: {service_type}")
    
    async def _submit_michigan_job(self, service_info: Dict[str, Any], job_data: Dict[str, Any]) -> Dict[str, Any]:
        """Submit job to Michigan Imputation Server."""
        try:
            # Michigan-specific job submission
            base_url = service_info['base_url'].rstrip('/')
            submit_url = f"{base_url}/api/v2/jobs/submit"
            
            # Prepare job parameters
            params = {
                'input-files': job_data['input_file_url'],
                'input-format': job_data['input_format'],
                'reference-panel': job_data['reference_panel'],
                'build': job_data['build'],
                'phasing': 'true' if job_data['phasing'] else 'false',
                'population': job_data.get('population', 'mixed')
            }
            
            # Submit job
            response = await self.client.post(submit_url, data=params)
            response.raise_for_status()
            
            result = response.json()
            return {
                'external_job_id': result.get('id'),
                'status': 'submitted',
                'service_response': result
            }
            
        except Exception as e:
            logger.error(f"Michigan job submission failed: {e}")
            return {
                'error': str(e),
                'status': 'failed'
            }
    
    async def _submit_ga4gh_job(self, service_info: Dict[str, Any], job_data: Dict[str, Any]) -> Dict[str, Any]:
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
            
            response = await self.client.post(submit_url, json=request_data)
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
    
    async def _submit_dnastack_job(self, service_info: Dict[str, Any], job_data: Dict[str, Any]) -> Dict[str, Any]:
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
            
            response = await self.client.post(submit_url, json=request_data)
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
    
    async def check_job_status(self, service_info: Dict[str, Any], external_job_id: str) -> Dict[str, Any]:
        """Check job status on external service."""
        service_type = service_info.get('api_type', 'michigan')
        
        try:
            if service_type == 'michigan':
                return await self._check_michigan_status(service_info, external_job_id)
            elif service_type == 'ga4gh':
                return await self._check_ga4gh_status(service_info, external_job_id)
            elif service_type == 'dnastack':
                return await self._check_dnastack_status(service_info, external_job_id)
            else:
                return {'status': 'unknown', 'error': f'Unsupported service type: {service_type}'}
        except Exception as e:
            logger.error(f"Status check failed: {e}")
            return {'status': 'error', 'error': str(e)}
    
    async def _check_michigan_status(self, service_info: Dict[str, Any], external_job_id: str) -> Dict[str, Any]:
        """Check Michigan job status."""
        base_url = service_info['base_url'].rstrip('/')
        status_url = f"{base_url}/api/v2/jobs/{external_job_id}/status"
        
        response = await self.client.get(status_url)
        response.raise_for_status()
        
        result = response.json()
        status_mapping = {
            'waiting': 'queued',
            'running': 'running',
            'success': 'completed',
            'error': 'failed',
            'canceled': 'cancelled'
        }
        
        return {
            'status': status_mapping.get(result.get('state', 'unknown'), 'unknown'),
            'progress': result.get('progress', 0),
            'message': result.get('message', ''),
            'service_response': result
        }
    
    async def _check_ga4gh_status(self, service_info: Dict[str, Any], external_job_id: str) -> Dict[str, Any]:
        """Check GA4GH job status."""
        base_url = service_info['base_url'].rstrip('/')
        status_url = f"{base_url}/ga4gh/wes/v1/runs/{external_job_id}/status"
        
        response = await self.client.get(status_url)
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
    
    async def _check_dnastack_status(self, service_info: Dict[str, Any], external_job_id: str) -> Dict[str, Any]:
        """Check DNASTACK job status."""
        base_url = service_info['base_url'].rstrip('/')
        status_url = f"{base_url}/api/jobs/{external_job_id}"
        
        response = await self.client.get(status_url)
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

# Service communication helpers
async def get_service_info(service_id: int) -> Dict[str, Any]:
    """Get service information from service registry."""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{SERVICE_REGISTRY_URL}/services/{service_id}")
        response.raise_for_status()
        return response.json()

async def get_file_download_url(file_id: int) -> str:
    """Get file download URL from file manager."""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{FILE_MANAGER_URL}/files/{file_id}/download")
        response.raise_for_status()
        result = response.json()
        return result['download_url']

async def send_notification(user_id: int, notification_type: str, title: str, message: str, data: Dict[str, Any] = None):
    """Send notification via notification service."""
    async with httpx.AsyncClient() as client:
        payload = {
            "user_id": user_id,
            "type": notification_type,
            "title": title,
            "message": message,
            "data": data or {},
            "channels": ["web", "email"]
        }
        response = await client.post(f"{NOTIFICATION_URL}/notifications", json=payload)
        response.raise_for_status()

def update_job_status_sync(job_id: str, status: str, progress: int = None, message: str = None, error: str = None):
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
            db.commit()
            
            # Send notification asynchronously
            asyncio.create_task(send_notification(
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
            ))
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
        service_info = asyncio.run(get_service_info(job.service_id))
        if not service_info:
            update_job_status_sync(job_id, 'failed', 0, "Failed to get service information")
            return
        
        # Get file download URL
        file_url = asyncio.run(get_file_download_url(job.input_file_id))
        if not file_url:
            update_job_status_sync(job_id, 'failed', 0, "Failed to get input file")
            return
        
        # Prepare job data for external service
        job_data = {
            'input_file_url': file_url,
            'input_format': job.input_format,
            'reference_panel': job.reference_panel_id,
            'build': job.build,
            'phasing': job.phasing,
            'population': job.population
        }
        
        # Submit job to external service
        client = ExternalServiceClient()
        submission_result = asyncio.run(client.submit_job_to_service(service_info, job_data))
        
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
            
            # Check job status on external service
            status_result = asyncio.run(client.check_job_status(service_info, job.external_job_id))
            
            external_status = status_result.get('status', 'unknown')
            progress = status_result.get('progress', 0)
            message = status_result.get('message', '')
            
            # Update local job status
            if external_status == 'completed':
                update_job_status_sync(job_id, 'completed', 100, "Job completed successfully")
                break
            elif external_status == 'failed':
                update_job_status_sync(job_id, 'failed', progress, f"Job failed: {message}")
                break
            elif external_status == 'cancelled':
                update_job_status_sync(job_id, 'cancelled', progress, "Job was cancelled")
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
                service_info = asyncio.run(get_service_info(job.service_id))
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

if __name__ == '__main__':
    app.start()
