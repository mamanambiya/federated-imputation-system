#!/usr/bin/env python3

import os
import sys
import django

# Setup Django environment
sys.path.append('/app')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'federated_imputation.settings')
django.setup()

from imputation.models import ImputationService

def update_elwazi_service_name():
    print("🔄 Updating eLwazi service names...")
    
    updates = [
        {
            'old_name': 'eLwazi Node Imputation Service',
            'new_name': 'eLwazi MALI Node - Imputation Service'
        },
        {
            'old_name': 'ILIFU GA4GH Starter Kit',
            'new_name': 'eLwazi ILIFU Node - Imputation Service'
        }
    ]
    
    success_count = 0
    
    for update in updates:
        try:
            service = ImputationService.objects.get(name=update['old_name'])
            old_name = service.name
            service.name = update['new_name']
            service.save()
            print(f"✅ Service name updated:")
            print(f"   From: {old_name}")
            print(f"   To: {service.name}")
            print()
            success_count += 1
        except ImputationService.DoesNotExist:
            print(f"❌ Service '{update['old_name']}' not found")
    
    print(f"🏁 Updated {success_count} out of {len(updates)} services")
    return success_count == len(updates)

if __name__ == '__main__':
    success = update_elwazi_service_name()
    sys.exit(0 if success else 1)