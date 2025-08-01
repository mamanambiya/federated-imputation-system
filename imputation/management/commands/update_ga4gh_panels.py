from django.core.management.base import BaseCommand
from imputation.models import ImputationService, ReferencePanel
from imputation.admin_views import sync_ga4gh_panels


class Command(BaseCommand):
    help = 'Updates reference panels for GA4GH services to use H3Africa panels'

    def handle(self, *args, **options):
        # Find all GA4GH services
        ga4gh_services = ImputationService.objects.filter(api_type='ga4gh')
        
        if not ga4gh_services.exists():
            self.stdout.write(self.style.WARNING('No GA4GH services found'))
            return
        
        for service in ga4gh_services:
            self.stdout.write(f'\nUpdating panels for: {service.name}')
            
            # Delete existing panels
            old_count = service.reference_panels.count()
            service.reference_panels.all().delete()
            self.stdout.write(f'  - Removed {old_count} old panels')
            
            # Sync new H3Africa-style panels
            try:
                panels = sync_ga4gh_panels(service)
                
                # Create new panels
                for panel_data in panels:
                    panel = ReferencePanel.objects.create(
                        service=service,
                        **panel_data
                    )
                    self.stdout.write(f'  - Added: {panel.name}')
                
                self.stdout.write(self.style.SUCCESS(
                    f'  ✓ Successfully added {len(panels)} H3Africa panels'
                ))
                
            except Exception as e:
                self.stdout.write(self.style.ERROR(
                    f'  ✗ Error syncing panels: {str(e)}'
                ))
        
        # Show summary
        self.stdout.write('\n' + '='*50)
        self.stdout.write(self.style.SUCCESS('Panel Update Summary:'))
        
        for service in ga4gh_services:
            panel_count = service.reference_panels.count()
            self.stdout.write(f'  - {service.name}: {panel_count} panels')
            
            # Show panel populations
            populations = service.reference_panels.values_list('population', flat=True).distinct()
            if populations:
                self.stdout.write(f'    Populations: {", ".join(populations)}')
        
        self.stdout.write(self.style.SUCCESS('\nAll GA4GH services now use H3Africa reference panels!')) 