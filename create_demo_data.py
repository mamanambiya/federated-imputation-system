#!/usr/bin/env python
"""
Script to create demo data for the federated imputation system
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'federated_imputation.settings')
django.setup()

from imputation.models import ImputationService, ReferencePanel

def create_demo_data():
    print("Creating demo imputation services and reference panels...")
    
    # Create H3Africa Imputation Service
    h3africa, created = ImputationService.objects.get_or_create(
        name="H3Africa Imputation Service",
        defaults={
            'description': 'African-focused imputation service providing reference panels for African populations',
            'api_url': 'https://h3africa.org/api/v1/',
            'is_active': True,
            'supported_formats': ['VCF', 'PLINK'],
            'max_file_size_mb': 500,
        }
    )
    if created:
        print(f"✅ Created {h3africa.name}")
    else:
        print(f"🔄 {h3africa.name} already exists")
    
    # Create Michigan Imputation Service  
    michigan, created = ImputationService.objects.get_or_create(
        name="Michigan Imputation Server",
        defaults={
            'description': 'University of Michigan Imputation Server for high-quality genotype imputation',
            'api_url': 'https://imputationserver.sph.umich.edu/api/v2/',
            'is_active': True,
            'supported_formats': ['VCF', 'PLINK', 'BGEN'],
            'max_file_size_mb': 1000,
        }
    )
    if created:
        print(f"✅ Created {michigan.name}")
    else:
        print(f"🔄 {michigan.name} already exists")
    
    # Create H3Africa Reference Panels
    h3africa_panels = [
        {
            'name': 'H3Africa Reference Panel v1.0',
            'panel_id': 'h3africa_v1',
            'description': 'African populations reference panel',
            'population': 'African',
            'build': 'GRCh37',
            'is_active': True,
        },
        {
            'name': 'H3Africa WGS Panel',
            'panel_id': 'h3africa_wgs',
            'description': 'Whole genome sequencing reference panel for African populations',
            'population': 'African',
            'build': 'GRCh38',
            'is_active': True,
        }
    ]
    
    for panel_data in h3africa_panels:
        panel, created = ReferencePanel.objects.get_or_create(
            service=h3africa,
            panel_id=panel_data['panel_id'],
            defaults=panel_data
        )
        if created:
            print(f"✅ Created reference panel: {panel.name}")
        else:
            print(f"🔄 Reference panel already exists: {panel.name}")
    
    # Create Michigan Reference Panels
    michigan_panels = [
        {
            'name': '1000 Genomes Phase 3 v5',
            'panel_id': '1000g_phase3_v5',
            'description': 'High-quality reference panel based on 1000 Genomes Project',
            'population': 'Mixed',
            'build': 'GRCh37',
            'is_active': True,
        },
        {
            'name': 'HRC r1.1 2016',
            'panel_id': 'hrc_r1_1',
            'description': 'Haplotype Reference Consortium reference panel',
            'population': 'European',
            'build': 'GRCh37',
            'is_active': True,
        },
        {
            'name': 'TOPMed Freeze 5',
            'panel_id': 'topmed_freeze5',
            'description': 'Trans-Omics for Precision Medicine reference panel',
            'population': 'Mixed',
            'build': 'GRCh38',
            'is_active': True,
        }
    ]
    
    for panel_data in michigan_panels:
        panel, created = ReferencePanel.objects.get_or_create(
            service=michigan,
            panel_id=panel_data['panel_id'],
            defaults=panel_data
        )
        if created:
            print(f"✅ Created reference panel: {panel.name}")
        else:
            print(f"🔄 Reference panel already exists: {panel.name}")
    
    print("\n📊 Summary:")
    print(f"Services: {ImputationService.objects.count()}")
    print(f"Reference Panels: {ReferencePanel.objects.count()}")
    print("\n🎉 Demo data creation complete!")

if __name__ == "__main__":
    create_demo_data() 