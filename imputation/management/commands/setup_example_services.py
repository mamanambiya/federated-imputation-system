from django.core.management.base import BaseCommand
from imputation.models import ImputationService, ReferencePanel


class Command(BaseCommand):
    help = 'Sets up example GA4GH WES imputation services'

    def handle(self, *args, **options):
        # Example GA4GH WES services
        ga4gh_services = [
            {
                'name': 'eLwazi MALI Node - Imputation Service',
                'service_type': 'h3africa',
                'api_type': 'ga4gh',
                'api_url': 'http://elwazi-node.icermali.org:6000/ga4gh/wes/v1',
                'description': 'GA4GH WES service at eLwazi Node supporting Nextflow and Snakemake workflows',
                'location': 'University of Sciences, Techniques and Technologies of Bamako, Bamako, Mali',
                'is_active': True,
                'api_key_required': False,
                'max_file_size_mb': 500,
                'supported_formats': ['vcf', 'vcf.gz', 'plink'],
                'api_config': {
                    'workflow_engines': ['NFL', 'SMK'],
                    'filesystem_protocols': ['file', 'S3']
                }
            },
            {
                'name': 'ILIFU GA4GH Starter Kit',
                'service_type': 'h3africa',
                'api_type': 'ga4gh',
                'api_url': 'http://ga4gh-starter-kit.ilifu.ac.za:6000/ga4gh/wes/v1',
                'description': 'GA4GH WES starter kit deployment at ILIFU for imputation workflows',
                'location': 'University of Cape Town, Cape Town, South Africa',
                'is_active': True,
                'api_key_required': False,
                'max_file_size_mb': 500,
                'supported_formats': ['vcf', 'vcf.gz', 'plink'],
                'api_config': {
                    'workflow_engines': ['NFL', 'SMK'],
                    'filesystem_protocols': ['file', 'S3']
                }
            }
        ]
        
        for service_data in ga4gh_services:
            service, created = ImputationService.objects.get_or_create(
                name=service_data['name'],
                defaults=service_data
            )
            
            if created:
                self.stdout.write(
                    self.style.SUCCESS(f'Created service: {service.name}')
                )
                
                # Create example workflow-based panels
                workflows = [
                    {
                        'name': 'Nextflow Imputation Pipeline',
                        'panel_id': 'nfl-imputation-v1',
                        'description': 'Imputation pipeline using Nextflow workflow engine',
                        'population': 'African',
                        'build': 'hg38',
                        'samples_count': 5000,
                        'variants_count': 20000000,
                        'is_active': True
                    },
                    {
                        'name': 'Snakemake Imputation Pipeline',
                        'panel_id': 'smk-imputation-v1',
                        'description': 'Imputation pipeline using Snakemake workflow engine',
                        'population': 'African',
                        'build': 'hg38',
                        'samples_count': 5000,
                        'variants_count': 20000000,
                        'is_active': True
                    }
                ]
                
                for panel_data in workflows:
                    panel, panel_created = ReferencePanel.objects.get_or_create(
                        service=service,
                        panel_id=panel_data['panel_id'],
                        defaults=panel_data
                    )
                    if panel_created:
                        self.stdout.write(
                            self.style.SUCCESS(f'  Created panel: {panel.name}')
                        )
            else:
                self.stdout.write(
                    self.style.WARNING(f'Service already exists: {service.name}')
                )
        
        # Also ensure Michigan service has proper API type
        michigan_services = ImputationService.objects.filter(
            name__icontains='michigan',
            api_type__isnull=True
        )
        for service in michigan_services:
            service.api_type = 'michigan'
            service.save()
            self.stdout.write(
                self.style.SUCCESS(f'Updated {service.name} to Michigan API type')
            )
        
        self.stdout.write(
            self.style.SUCCESS(
                f'\nTotal services: {ImputationService.objects.count()}'
            )
        ) 