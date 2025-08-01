"""
Celery tasks for async imputation job processing.
"""
import logging
from typing import Dict, Any
from celery import shared_task
from django.utils import timezone
from .models import ImputationJob, JobStatusUpdate, ResultFile
from .services import get_service_instance, sync_reference_panels

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3)
def submit_imputation_job(self, job_id: str, file_path: str = None):
    """Submit an imputation job to the external service."""
    try:
        job = ImputationJob.objects.get(id=job_id)
        service_instance = get_service_instance(job.service.id)
        
        # Read file data
        if file_path:
            with open(file_path, 'rb') as f:
                file_data = f.read()
        elif job.input_file:
            file_data = job.input_file.read()
        else:
            raise ValueError("No input file provided")
        
        # Update job status
        job.update_status('queued')
        JobStatusUpdate.objects.create(
            job=job,
            status='queued',
            message='Job queued for submission'
        )
        
        # Submit to external service
        external_job_id = service_instance.submit_job(job, file_data)
        
        # Update job with external ID
        job.external_job_id = external_job_id
        job.update_status('queued', progress=10)
        job.save()
        
        JobStatusUpdate.objects.create(
            job=job,
            status='queued',
            progress_percentage=10,
            message=f'Job submitted to {job.service.name} with ID: {external_job_id}'
        )
        
        # Schedule status monitoring
        monitor_job_status.apply_async((job_id,), countdown=30)
        
        logger.info(f"Successfully submitted job {job_id} to {job.service.name}")
        return {'status': 'success', 'external_job_id': external_job_id}
        
    except Exception as exc:
        logger.error(f"Failed to submit job {job_id}: {exc}")
        
        try:
            job = ImputationJob.objects.get(id=job_id)
            job.update_status('failed', error_message=str(exc))
            JobStatusUpdate.objects.create(
                job=job,
                status='failed',
                message=f'Job submission failed: {exc}'
            )
        except ImputationJob.DoesNotExist:
            pass
        
        # Retry if not max retries
        if self.request.retries < self.max_retries:
            raise self.retry(exc=exc, countdown=60 * (self.request.retries + 1))
        
        return {'status': 'failed', 'error': str(exc)}


@shared_task(bind=True, max_retries=10)
def monitor_job_status(self, job_id: str):
    """Monitor the status of a submitted job."""
    try:
        job = ImputationJob.objects.get(id=job_id)
        
        if not job.external_job_id:
            logger.error(f"Job {job_id} has no external job ID")
            return {'status': 'error', 'message': 'No external job ID'}
        
        if job.status in ['completed', 'failed', 'cancelled']:
            logger.info(f"Job {job_id} already in terminal state: {job.status}")
            return {'status': job.status}
        
        service_instance = get_service_instance(job.service.id)
        status_data = service_instance.get_job_status(job.external_job_id)
        
        # Update job status
        old_status = job.status
        old_progress = job.progress_percentage
        
        job.update_status(
            status_data['status'],
            progress=status_data['progress'],
            error_message=status_data.get('message', '')
        )
        job.service_response = status_data.get('external_data', {})
        job.save()
        
        # Create status update record if changed
        if (old_status != job.status or 
            old_progress != job.progress_percentage or 
            status_data.get('message')):
            
            JobStatusUpdate.objects.create(
                job=job,
                status=job.status,
                progress_percentage=job.progress_percentage,
                message=status_data.get('message', ''),
                external_data=status_data.get('external_data', {})
            )
        
        # If job completed, download results
        if job.status == 'completed':
            download_job_results.apply_async((job_id,), countdown=10)
            logger.info(f"Job {job_id} completed, scheduling result download")
            return {'status': 'completed'}
        
        # If job failed, log and stop monitoring
        elif job.status == 'failed':
            logger.error(f"Job {job_id} failed: {status_data.get('message', '')}")
            return {'status': 'failed'}
        
        # If job cancelled, stop monitoring
        elif job.status == 'cancelled':
            logger.info(f"Job {job_id} was cancelled")
            return {'status': 'cancelled'}
        
        # Continue monitoring for running/queued jobs
        else:
            # Schedule next status check with exponential backoff
            next_check = min(300, 30 + (self.request.retries * 30))  # Max 5 minutes
            monitor_job_status.apply_async((job_id,), countdown=next_check)
            
            logger.info(f"Job {job_id} status: {job.status} ({job.progress_percentage}%)")
            return {'status': job.status, 'progress': job.progress_percentage}
        
    except Exception as exc:
        logger.error(f"Failed to monitor job {job_id}: {exc}")
        
        # Retry with exponential backoff
        if self.request.retries < self.max_retries:
            countdown = min(3600, 60 * (2 ** self.request.retries))  # Max 1 hour
            raise self.retry(exc=exc, countdown=countdown)
        
        # Max retries reached, mark job as failed
        try:
            job = ImputationJob.objects.get(id=job_id)
            job.update_status('failed', error_message=f'Monitoring failed: {exc}')
            JobStatusUpdate.objects.create(
                job=job,
                status='failed',
                message=f'Status monitoring failed after {self.max_retries} retries: {exc}'
            )
        except ImputationJob.DoesNotExist:
            pass
        
        return {'status': 'failed', 'error': str(exc)}


@shared_task(bind=True, max_retries=3)
def download_job_results(self, job_id: str):
    """Download results for a completed job."""
    try:
        job = ImputationJob.objects.get(id=job_id)
        
        if job.status != 'completed':
            logger.warning(f"Job {job_id} is not completed, cannot download results")
            return {'status': 'error', 'message': 'Job not completed'}
        
        if not job.external_job_id:
            logger.error(f"Job {job_id} has no external job ID")
            return {'status': 'error', 'message': 'No external job ID'}
        
        service_instance = get_service_instance(job.service.id)
        result_files = service_instance.download_results(job.external_job_id)
        
        # Create ResultFile objects
        created_files = []
        for file_data in result_files:
            result_file, created = ResultFile.objects.update_or_create(
                job=job,
                filename=file_data['filename'],
                defaults={
                    'file_type': file_data['file_type'],
                    'download_url': file_data.get('download_url', ''),
                    'file_size': file_data.get('file_size'),
                    'checksum': file_data.get('checksum', ''),
                    'is_available': True,
                }
            )
            created_files.append(result_file)
        
        # Update job result files list
        job.result_files = [
            {
                'filename': rf.filename,
                'file_type': rf.file_type,
                'download_url': rf.download_url,
                'file_size': rf.file_size,
                'is_available': rf.is_available,
            }
            for rf in created_files
        ]
        job.save()
        
        JobStatusUpdate.objects.create(
            job=job,
            status='completed',
            progress_percentage=100,
            message=f'Results available: {len(created_files)} files downloaded'
        )
        
        logger.info(f"Downloaded {len(created_files)} result files for job {job_id}")
        return {'status': 'success', 'files_count': len(created_files)}
        
    except Exception as exc:
        logger.error(f"Failed to download results for job {job_id}: {exc}")
        
        try:
            job = ImputationJob.objects.get(id=job_id)
            JobStatusUpdate.objects.create(
                job=job,
                status='completed',
                message=f'Job completed but result download failed: {exc}'
            )
        except ImputationJob.DoesNotExist:
            pass
        
        # Retry if not max retries
        if self.request.retries < self.max_retries:
            raise self.retry(exc=exc, countdown=60 * (self.request.retries + 1))
        
        return {'status': 'failed', 'error': str(exc)}


@shared_task
def cancel_imputation_job(job_id: str):
    """Cancel a submitted job."""
    try:
        job = ImputationJob.objects.get(id=job_id)
        
        if job.status in ['completed', 'failed', 'cancelled']:
            logger.warning(f"Job {job_id} already in terminal state: {job.status}")
            return {'status': 'error', 'message': f'Job already {job.status}'}
        
        if not job.external_job_id:
            # Job not yet submitted, just mark as cancelled
            job.update_status('cancelled')
            JobStatusUpdate.objects.create(
                job=job,
                status='cancelled',
                message='Job cancelled before submission'
            )
            return {'status': 'success', 'message': 'Job cancelled locally'}
        
        # Cancel with external service
        service_instance = get_service_instance(job.service.id)
        success = service_instance.cancel_job(job.external_job_id)
        
        if success:
            job.update_status('cancelled')
            JobStatusUpdate.objects.create(
                job=job,
                status='cancelled',
                message=f'Job cancelled in {job.service.name}'
            )
            logger.info(f"Successfully cancelled job {job_id}")
            return {'status': 'success'}
        else:
            logger.error(f"Failed to cancel job {job_id} in external service")
            return {'status': 'error', 'message': 'Failed to cancel in external service'}
        
    except Exception as exc:
        logger.error(f"Failed to cancel job {job_id}: {exc}")
        return {'status': 'failed', 'error': str(exc)}


@shared_task
def sync_service_reference_panels(service_id: int):
    """Sync reference panels from an external service."""
    try:
        synced_count = sync_reference_panels(service_id)
        logger.info(f"Synced {synced_count} reference panels for service {service_id}")
        return {'status': 'success', 'synced_count': synced_count}
        
    except Exception as exc:
        logger.error(f"Failed to sync reference panels for service {service_id}: {exc}")
        return {'status': 'failed', 'error': str(exc)}


@shared_task
def cleanup_old_jobs():
    """Clean up old completed/failed jobs and their files."""
    from datetime import timedelta
    
    # Delete jobs older than 30 days
    cutoff_date = timezone.now() - timedelta(days=30)
    old_jobs = ImputationJob.objects.filter(
        created_at__lt=cutoff_date,
        status__in=['completed', 'failed', 'cancelled']
    )
    
    deleted_count = 0
    for job in old_jobs:
        # Delete result files
        for result_file in job.files.all():
            result_file.delete()
        
        # Delete job
        job.delete()
        deleted_count += 1
    
    logger.info(f"Cleaned up {deleted_count} old jobs")
    return {'status': 'success', 'deleted_count': deleted_count}


@shared_task
def health_check_services():
    """Check the health of all active imputation services."""
    from .models import ImputationService
    
    results = {}
    
    for service in ImputationService.objects.filter(is_active=True):
        try:
            service_instance = get_service_instance(service.id)
            # Try to fetch reference panels as a health check
            panels = service_instance.get_reference_panels()
            results[service.name] = {
                'status': 'healthy',
                'panels_count': len(panels)
            }
        except Exception as exc:
            results[service.name] = {
                'status': 'unhealthy',
                'error': str(exc)
            }
            logger.error(f"Health check failed for {service.name}: {exc}")
    
    return results 