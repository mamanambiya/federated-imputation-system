#!/usr/bin/env python
"""
Health check script for federated imputation system.
"""
import os
import sys
import django
from django.conf import settings

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'federated_imputation.settings')
django.setup()

from django.db import connections
from django.core.cache import cache
import requests


def check_database():
    """Check database connectivity."""
    try:
        db_conn = connections['default']
        with db_conn.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        return True, "Database OK"
    except Exception as e:
        return False, f"Database Error: {e}"


def check_redis():
    """Check Redis connectivity."""
    try:
        cache.set('health_check', 'ok', 10)
        result = cache.get('health_check')
        if result == 'ok':
            return True, "Redis OK"
        else:
            return False, "Redis not responding correctly"
    except Exception as e:
        return False, f"Redis Error: {e}"


def check_django():
    """Check Django application."""
    try:
        from django.http import HttpResponse
        from django.test import RequestFactory
        from django.conf import settings
        
        # Basic Django setup check
        if settings.configured:
            return True, "Django OK"
        else:
            return False, "Django not configured"
    except Exception as e:
        return False, f"Django Error: {e}"


def main():
    """Run all health checks."""
    checks = [
        ("Django", check_django),
        ("Database", check_database),
        ("Redis", check_redis),
    ]
    
    all_ok = True
    results = []
    
    for name, check_func in checks:
        try:
            status, message = check_func()
            results.append(f"{name}: {'✅' if status else '❌'} {message}")
            if not status:
                all_ok = False
        except Exception as e:
            results.append(f"{name}: ❌ Exception: {e}")
            all_ok = False
    
    print("\n".join(results))
    
    if all_ok:
        print("🎉 All systems healthy!")
        sys.exit(0)
    else:
        print("💥 Some systems unhealthy!")
        sys.exit(1)


if __name__ == "__main__":
    main() 