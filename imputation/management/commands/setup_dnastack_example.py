from django.core.management.base import BaseCommand
from imputation.models import ImputationService, ReferencePanel


class Command(BaseCommand):
    help = 'Sets up an example DNASTACK Omics service'

    def handle(self, *args, **options):
        # Create or update DNASTACK service
        service, created = ImputationService.objects.get_or_create(
            name='eLwazi Omics Platform',
            defaults={
                'service_type': 'h3africa',
                'api_type': 'dnastack',
                'api_url': 'https://elwazi.omics.ai',
                'description': 'DNASTACK-powered genomics platform for African genomic data with DataConnect API',
                'is_active': True,
                'api_key_required': True,
                'max_file_size_mb': 1000,
                'supported_formats': ['vcf', 'vcf.gz', 'plink', 'bgen'],
                'api_config': {
                    'dnastack_factory': 'elwazi.omics.ai',
                    'data_connect_endpoints': [
                        'data-connect-elwazi-catalogue-katherine'
                    ],
                    'example_usage': """
from dnastack import use

factory = use('elwazi.omics.ai')
data_connect_client = factory.get('data-connect-elwazi-catalogue-katherine')
result_iterator = data_connect_client.query("SELECT * FROM collections.elwazi_catalogue_katherine.elwazi_agvd_allele_frequencies_sample LIMIT 10")"""
                }
            }
        )
        
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created DNASTACK service: {service.name}'))
            
            # Create reference panels
            panels = [
                {
                    'name': 'eLwazi AGVD Allele Frequencies',
                    'panel_id': 'elwazi-agvd-allele-freq',
                    'description': 'African Genomic Variation Database allele frequencies from eLwazi catalogue',
                    'population': 'African',
                    'build': 'hg38',
                    'samples_count': 0,
                    'variants_count': 0,
                    'is_active': True,
                },
                {
                    'name': 'eLwazi African Reference Panel',
                    'panel_id': 'elwazi-african-ref',
                    'description': 'African-specific reference panel with diverse population representation',
                    'population': 'African',
                    'build': 'hg38',
                    'samples_count': 0,
                    'variants_count': 0,
                    'is_active': True,
                }
            ]
            
            for panel_data in panels:
                panel, created = ReferencePanel.objects.get_or_create(
                    service=service,
                    panel_id=panel_data['panel_id'],
                    defaults=panel_data
                )
                if created:
                    self.stdout.write(f'  - Created panel: {panel.name}')
        else:
            self.stdout.write(self.style.WARNING(f'DNASTACK service already exists: {service.name}'))
            
        self.stdout.write(self.style.SUCCESS('\nDNASTACK service setup complete!'))
        self.stdout.write('\nTo test the connection:')
        self.stdout.write('1. Go to Admin → Imputation → Imputation services')
        self.stdout.write('2. Click on "eLwazi Omics Platform"')
        self.stdout.write('3. Use the Setup Wizard to test the connection')
        self.stdout.write('\nTo use the DNASTACK client library:')
        self.stdout.write('pip3 install -U dnastack-client-library') 