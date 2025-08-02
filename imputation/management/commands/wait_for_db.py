"""
Django command to wait for database to be available.
"""
import time
from django.core.management.base import BaseCommand
from django.db import connections
from django.db.utils import OperationalError
from django.conf import settings


class Command(BaseCommand):
    """Django command to wait for database."""

    help = 'Wait for database to be available'

    def add_arguments(self, parser):
        parser.add_argument(
            '--timeout',
            type=int,
            default=60,
            help='Maximum time to wait for database (seconds)',
        )

    def handle(self, *args, **options):
        """Entry point for command."""
        timeout = options['timeout']
        max_retries = getattr(settings, 'DATABASE_CONNECTION_MAX_RETRIES', 30)
        retry_delay = getattr(settings, 'DATABASE_CONNECTION_RETRY_DELAY', 2)
        
        self.stdout.write('🔍 Waiting for database...')
        
        db_conn = None
        start_time = time.time()
        
        for attempt in range(max_retries):
            try:
                db_conn = connections['default']
                db_conn.ensure_connection()
                
                # Test if we can actually query the database
                with db_conn.cursor() as cursor:
                    cursor.execute("SELECT 1")
                    cursor.fetchone()
                
                # Check if our specific database exists
                with db_conn.cursor() as cursor:
                    cursor.execute("SELECT datname FROM pg_database WHERE datname = %s", ['federated_imputation'])
                    result = cursor.fetchone()
                    if not result:
                        self.stdout.write(
                            self.style.WARNING(
                                f'📋 Database "federated_imputation" not found, creating...'
                            )
                        )
                        # Try to create the database
                        cursor.execute("CREATE DATABASE federated_imputation")
                
                self.stdout.write(
                    self.style.SUCCESS('✅ Database available!')
                )
                return
                
            except OperationalError as e:
                elapsed = time.time() - start_time
                if elapsed >= timeout:
                    self.stdout.write(
                        self.style.ERROR(
                            f'❌ Database unavailable after {timeout}s timeout!'
                        )
                    )
                    raise e
                
                self.stdout.write(
                    f'🔄 Database unavailable, waiting... (attempt {attempt + 1}/{max_retries}) - {e}'
                )
                time.sleep(retry_delay)
        
        self.stdout.write(
            self.style.ERROR(
                f'❌ Database unavailable after {max_retries} attempts!'
            )
        ) 