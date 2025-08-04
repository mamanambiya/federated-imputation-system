from django.core.management.base import BaseCommand
from imputation.models import ImputationService, ReferencePanel


class Command(BaseCommand):
    help = 'Adds the missing eLwazi Omics Platform service'

    def handle(self, *args, **options):
        self.stdout.write("🔧 Adding missing eLwazi Omics Platform service...")
        
        # Create the missing eLwazi Omics Platform service
        elwazi_omics, created = ImputationService.objects.get_or_create(
            name='eLwazi Omics Platform',
            defaults={
                'service_type': 'dnastack',
                'api_type': 'dnastack',
                'api_url': 'https://platform.elwazi.org',
                'description': 'eLwazi Omics Platform for genomic data analysis and imputation workflows',
                'location': 'Witwatersrand University, Johannesburg, South Africa',
                'continent': 'Africa',
                'is_active': True,
                'api_key_required': True,
                'max_file_size_mb': 1000,
                'supported_formats': ['vcf', 'vcf.gz', 'plink', 'bed', 'bim', 'fam'],
                'api_config': {
                    'platform_type': 'omics_platform',
                    'supported_analyses': ['imputation', 'gwas', 'ancestry'],
                    'compute_environments': ['cloud', 'hpc']
                }
            }
        )

        if created:
            self.stdout.write(self.style.SUCCESS(f"✅ Created: {elwazi_omics.name}"))
            
            # Add reference panels for eLwazi Omics Platform
            panels = [
                {
                    'name': 'African Genomics Panel',
                    'panel_id': 'elwazi_african_v1',
                    'description': 'Comprehensive African genomics reference panel',
                    'population': 'African',
                    'build': 'hg38',
                    'samples_count': 8000,
                    'variants_count': 25000000,
                    'is_active': True
                },
                {
                    'name': 'Pan-African Diversity Panel',
                    'panel_id': 'elwazi_pan_african_v2',
                    'description': 'Pan-African population diversity reference panel',
                    'population': 'Pan-African',
                    'build': 'hg38',
                    'samples_count': 6500,
                    'variants_count': 22000000,
                    'is_active': True
                }
            ]
            
            for panel_data in panels:
                panel, panel_created = ReferencePanel.objects.get_or_create(
                    service=elwazi_omics,
                    name=panel_data['name'],
                    defaults=panel_data
                )
                if panel_created:
                    self.stdout.write(f"  ✅ Created panel: {panel.name}")
        else:
            self.stdout.write(self.style.WARNING(f"✅ Already exists: {elwazi_omics.name}"))

        # Show final count
        self.stdout.write(f"\n📊 Total services: {ImputationService.objects.count()}")
        self.stdout.write(f"📊 Total reference panels: {ReferencePanel.objects.count()}")