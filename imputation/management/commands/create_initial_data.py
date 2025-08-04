from django.core.management.base import BaseCommand
from imputation.models import ImputationService, ReferencePanel


class Command(BaseCommand):
    help = 'Creates initial imputation services and reference panels'

    def handle(self, *args, **options):
        # Create H3Africa Service
        h3africa, created = ImputationService.objects.get_or_create(
            name='H3Africa Imputation Service',
            defaults={
                'service_type': 'h3africa',
                'api_url': 'https://h3africa.org/imputation',
                'description': 'Pan-African imputation service with African-specific reference panels',
                'location': 'H3Africa Consortium, Pan-African Network',
                'is_active': True,
                'api_key_required': True,
                'max_file_size_mb': 100,
                'supported_formats': ['vcf', 'vcf.gz']
            }
        )
        
        # Create Michigan Service
        michigan, created = ImputationService.objects.get_or_create(
            name='Michigan Imputation Server',
            defaults={
                'service_type': 'michigan',
                'api_url': 'https://imputationserver.sph.umich.edu',
                'description': 'Fast and accurate genotype imputation service',
                'location': 'University of Michigan, Ann Arbor, Michigan, USA',
                'is_active': True,
                'api_key_required': True,
                'max_file_size_mb': 200,
                'supported_formats': ['vcf', 'vcf.gz', 'plink']
            }
        )
        
        # Create reference panels for H3Africa
        h3africa_panels = [
            {
                'name': 'African Multi-Ethnic Panel',
                'description': 'Combined African populations reference panel',
                'population': 'African',
                'build': 'hg38',
                'samples_count': 5000,
                'variants_count': 20000000,
                'is_active': True
            },
            {
                'name': 'West African Panel',
                'description': 'West African specific reference panel',
                'population': 'West African',
                'build': 'hg38',
                'samples_count': 2000,
                'variants_count': 15000000,
                'is_active': True
            },
            {
                'name': 'East African Panel',
                'description': 'East African specific reference panel',
                'population': 'East African',
                'build': 'hg38',
                'samples_count': 1500,
                'variants_count': 14000000,
                'is_active': True
            },
            {
                'name': 'South African Panel',
                'description': 'Southern African populations reference panel',
                'population': 'South African',
                'build': 'hg38',
                'samples_count': 1800,
                'variants_count': 16000000,
                'is_active': True
            },
            {
                'name': 'North African Panel',
                'description': 'North African populations reference panel',
                'population': 'North African',
                'build': 'hg38',
                'samples_count': 1200,
                'variants_count': 13000000,
                'is_active': True
            }
        ]
        
        for i, panel_data in enumerate(h3africa_panels):
            panel_data['panel_id'] = f'h3africa_panel_{i+1}'
            ReferencePanel.objects.get_or_create(
                service=h3africa,
                name=panel_data['name'],
                defaults=panel_data
            )
        
        # Create reference panels for Michigan
        michigan_panels = [
            {
                'name': 'HRC r1.1 2016',
                'description': 'Haplotype Reference Consortium',
                'population': 'Mixed',
                'build': 'hg38',
                'samples_count': 32488,
                'variants_count': 39635008,
                'is_active': True
            },
            {
                'name': '1000G Phase 3 v5',
                'description': '1000 Genomes Project Phase 3',
                'population': 'Mixed',
                'build': 'hg38',
                'samples_count': 2504,
                'variants_count': 49143605,
                'is_active': True
            },
            {
                'name': 'CAAPA African American',
                'description': 'Consortium on Asthma among African-ancestry Populations',
                'population': 'African American',
                'build': 'hg38',
                'samples_count': 883,
                'variants_count': 31163897,
                'is_active': True
            }
        ]
        
        for i, panel_data in enumerate(michigan_panels):
            panel_data['panel_id'] = f'michigan_panel_{i+1}'
            ReferencePanel.objects.get_or_create(
                service=michigan,
                name=panel_data['name'],
                defaults=panel_data
            )
        
        self.stdout.write(self.style.SUCCESS('Successfully created initial data'))
        self.stdout.write(f'Created {ImputationService.objects.count()} services')
        self.stdout.write(f'Created {ReferencePanel.objects.count()} reference panels') 