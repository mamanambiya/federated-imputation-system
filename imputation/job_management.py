# Advanced Job Management System for Federated Genomic Imputation Platform

import uuid
import json
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from django.db import models, transaction
from django.contrib.auth.models import User
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.db.models import Q, Count, Avg
from .models import ImputationJob, ImputationService, ReferencePanel
from .performance import cache_result, monitor_performance

logger = logging.getLogger(__name__)


class JobTemplate(models.Model):
    """Model for storing job templates"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='job_templates')
    
    # Template configuration
    service = models.ForeignKey(ImputationService, on_delete=models.CASCADE)
    reference_panel = models.ForeignKey(ReferencePanel, on_delete=models.CASCADE)
    
    # Default job settings
    input_format = models.CharField(max_length=20, default='vcf')
    build = models.CharField(max_length=20, default='hg38')
    phasing = models.BooleanField(default=True)
    population = models.CharField(max_length=100, blank=True)
    
    # Template metadata
    is_public = models.BooleanField(default=False)
    usage_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_public']),
            models.Index(fields=['service', 'is_public']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.service.name})"
    
    def increment_usage(self):
        """Increment usage count"""
        self.usage_count += 1
        self.save(update_fields=['usage_count'])


class JobBatch(models.Model):
    """Model for batch job operations"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='job_batches')
    
    # Batch configuration
    template = models.ForeignKey(JobTemplate, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Batch status
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('running', 'Running'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Progress tracking
    total_jobs = models.IntegerField(default=0)
    completed_jobs = models.IntegerField(default=0)
    failed_jobs = models.IntegerField(default=0)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['status', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.total_jobs} jobs)"
    
    @property
    def progress_percentage(self):
        """Calculate batch progress percentage"""
        if self.total_jobs == 0:
            return 0
        return int((self.completed_jobs + self.failed_jobs) / self.total_jobs * 100)
    
    @property
    def success_rate(self):
        """Calculate batch success rate"""
        finished_jobs = self.completed_jobs + self.failed_jobs
        if finished_jobs == 0:
            return 0
        return int(self.completed_jobs / finished_jobs * 100)


class ScheduledJob(models.Model):
    """Model for scheduled job execution"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='scheduled_jobs')
    
    # Schedule configuration
    template = models.ForeignKey(JobTemplate, on_delete=models.CASCADE)
    
    # Scheduling options
    SCHEDULE_TYPES = [
        ('once', 'Run Once'),
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
    ]
    schedule_type = models.CharField(max_length=20, choices=SCHEDULE_TYPES)
    scheduled_time = models.DateTimeField()
    
    # Recurrence settings
    recurrence_interval = models.IntegerField(default=1)  # Every N days/weeks/months
    max_executions = models.IntegerField(null=True, blank=True)  # Limit executions
    
    # Status
    is_active = models.BooleanField(default=True)
    execution_count = models.IntegerField(default=0)
    last_execution = models.DateTimeField(null=True, blank=True)
    next_execution = models.DateTimeField()
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['next_execution']
        indexes = [
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['is_active', 'next_execution']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.get_schedule_type_display()})"
    
    def calculate_next_execution(self):
        """Calculate next execution time based on schedule type"""
        if self.schedule_type == 'once':
            return None
        
        if not self.last_execution:
            return self.scheduled_time
        
        if self.schedule_type == 'daily':
            return self.last_execution + timedelta(days=self.recurrence_interval)
        elif self.schedule_type == 'weekly':
            return self.last_execution + timedelta(weeks=self.recurrence_interval)
        elif self.schedule_type == 'monthly':
            # Approximate monthly calculation
            return self.last_execution + timedelta(days=30 * self.recurrence_interval)
        
        return None


class JobManager:
    """Advanced job management utilities"""
    
    @staticmethod
    @monitor_performance()
    def create_job_from_template(template: JobTemplate, user: User, 
                                job_name: str, input_files: List[str] = None,
                                overrides: Dict[str, Any] = None) -> ImputationJob:
        """
        Create a new job from a template
        
        Args:
            template: JobTemplate instance
            user: User creating the job
            job_name: Name for the new job
            input_files: List of input file paths
            overrides: Dictionary of field overrides
        
        Returns:
            Created ImputationJob instance
        """
        # Increment template usage
        template.increment_usage()
        
        # Prepare job data
        job_data = {
            'name': job_name,
            'user': user,
            'service': template.service,
            'reference_panel': template.reference_panel,
            'input_format': template.input_format,
            'build': template.build,
            'phasing': template.phasing,
            'population': template.population,
            'description': f"Created from template: {template.name}",
        }
        
        # Apply overrides
        if overrides:
            job_data.update(overrides)
        
        # Create job
        job = ImputationJob.objects.create(**job_data)
        
        logger.info(f"Created job {job.id} from template {template.id} for user {user.username}")
        return job
    
    @staticmethod
    @transaction.atomic
    def create_batch_jobs(batch: JobBatch, input_files: List[str], 
                         job_name_pattern: str = "Batch Job {index}") -> List[ImputationJob]:
        """
        Create multiple jobs for a batch
        
        Args:
            batch: JobBatch instance
            input_files: List of input file paths
            job_name_pattern: Pattern for job names (can include {index})
        
        Returns:
            List of created ImputationJob instances
        """
        jobs = []
        
        try:
            for i, input_file in enumerate(input_files, 1):
                job_name = job_name_pattern.format(index=i, filename=input_file)
                
                job = JobManager.create_job_from_template(
                    template=batch.template,
                    user=batch.user,
                    job_name=job_name,
                    input_files=[input_file]
                )
                
                # Associate job with batch
                job.batch = batch
                job.save()
                jobs.append(job)
            
            # Update batch totals
            batch.total_jobs = len(jobs)
            batch.save()
            
            logger.info(f"Created {len(jobs)} jobs for batch {batch.id}")
            
        except Exception as e:
            logger.error(f"Failed to create batch jobs: {e}")
            # Clean up any created jobs
            for job in jobs:
                job.delete()
            raise
        
        return jobs
    
    @staticmethod
    @cache_result(timeout=300)
    def get_user_job_statistics(user: User) -> Dict[str, Any]:
        """
        Get comprehensive job statistics for a user
        
        Args:
            user: User instance
        
        Returns:
            Dictionary with job statistics
        """
        jobs = ImputationJob.objects.filter(user=user)
        
        stats = {
            'total_jobs': jobs.count(),
            'status_breakdown': {},
            'service_usage': {},
            'recent_activity': [],
            'success_rate': 0,
            'avg_execution_time': 0,
        }
        
        # Status breakdown
        status_counts = jobs.values('status').annotate(count=Count('id'))
        for item in status_counts:
            stats['status_breakdown'][item['status']] = item['count']
        
        # Service usage
        service_counts = jobs.values('service__name').annotate(count=Count('id'))
        for item in service_counts:
            stats['service_usage'][item['service__name']] = item['count']
        
        # Success rate
        completed_jobs = stats['status_breakdown'].get('completed', 0)
        failed_jobs = stats['status_breakdown'].get('failed', 0)
        total_finished = completed_jobs + failed_jobs
        if total_finished > 0:
            stats['success_rate'] = int(completed_jobs / total_finished * 100)
        
        # Average execution time
        avg_time = jobs.filter(
            execution_time_seconds__isnull=False
        ).aggregate(avg_time=Avg('execution_time_seconds'))
        stats['avg_execution_time'] = avg_time['avg_time'] or 0
        
        # Recent activity (last 10 jobs)
        recent_jobs = jobs.order_by('-created_at')[:10]
        stats['recent_activity'] = [
            {
                'id': str(job.id),
                'name': job.name,
                'status': job.status,
                'service': job.service.name,
                'created_at': job.created_at.isoformat(),
            }
            for job in recent_jobs
        ]
        
        return stats
    
    @staticmethod
    def get_job_recommendations(user: User, limit: int = 5) -> List[Dict[str, Any]]:
        """
        Get job recommendations based on user history
        
        Args:
            user: User instance
            limit: Maximum number of recommendations
        
        Returns:
            List of recommendation dictionaries
        """
        # Get user's most used services and panels
        user_jobs = ImputationJob.objects.filter(user=user)
        
        # Most used services
        popular_services = user_jobs.values('service').annotate(
            count=Count('id')
        ).order_by('-count')[:3]
        
        # Most used reference panels
        popular_panels = user_jobs.values('reference_panel').annotate(
            count=Count('id')
        ).order_by('-count')[:3]
        
        recommendations = []
        
        # Recommend templates based on usage patterns
        for service_data in popular_services:
            service = ImputationService.objects.get(id=service_data['service'])
            templates = JobTemplate.objects.filter(
                service=service,
                is_public=True
            ).order_by('-usage_count')[:2]
            
            for template in templates:
                recommendations.append({
                    'type': 'template',
                    'template_id': str(template.id),
                    'name': template.name,
                    'service': service.name,
                    'reason': f"Based on your usage of {service.name}",
                    'usage_count': template.usage_count,
                })
        
        return recommendations[:limit]
    
    @staticmethod
    def cleanup_old_jobs(days: int = 90) -> int:
        """
        Clean up old completed/failed jobs
        
        Args:
            days: Number of days to keep jobs
        
        Returns:
            Number of jobs deleted
        """
        cutoff_date = timezone.now() - timedelta(days=days)
        
        old_jobs = ImputationJob.objects.filter(
            status__in=['completed', 'failed'],
            completed_at__lt=cutoff_date
        )
        
        count = old_jobs.count()
        old_jobs.delete()
        
        logger.info(f"Cleaned up {count} old jobs older than {days} days")
        return count
