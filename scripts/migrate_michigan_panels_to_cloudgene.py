#!/usr/bin/env python3
"""
Migrate Reference Panels to Cloudgene Format

This script updates reference panel names for Michigan-type services to use
the correct Cloudgene application format: apps@{app-id}@{version}

CRITICAL: Michigan Imputation Servers require this exact format for job submissions.
Using incorrect formats (like simple names or database IDs) causes job validation failures.

Usage:
    python scripts/migrate_michigan_panels_to_cloudgene.py
    python scripts/migrate_michigan_panels_to_cloudgene.py --dry-run  # Preview changes only
"""

import argparse
import requests
import sys
from typing import Dict, List

SERVICE_REGISTRY_URL = "http://localhost:8002"

# Mapping of current panel names to correct Cloudgene format
# Format: apps@{app-id}@{version}
# These app-ids come from Cloudgene YAML configurations on the servers
PANEL_MIGRATIONS = {
    # H3Africa panels (Afrigen server)
    "h3africa_v6": {
        "name": "apps@h3africa-v6hc-s@1.0.0",
        "display_name": "H3Africa Reference Panel (v6)",
        "description": "African populations reference panel with 5,000+ samples from diverse African regions"
    },
    "h3africa": {
        "name": "apps@h3africa-v6hc-s@1.0.0",
        "display_name": "H3Africa Reference Panel (v6)",
        "description": "African populations reference panel with 5,000+ samples from diverse African regions"
    },

    # 1000 Genomes panels
    "1kg_p3": {
        "name": "apps@1000g-phase-3-v5@1.0.0",
        "display_name": "1000 Genomes Phase 3 (v5)",
        "description": "1000 Genomes Project Phase 3 reference panel with 2,504 samples"
    },
    "1000genomes_phase3": {
        "name": "apps@1000g-phase-3-v5@1.0.0",
        "display_name": "1000 Genomes Phase 3 (v5)",
        "description": "1000 Genomes Project Phase 3 reference panel with 2,504 samples"
    },
    "1000g": {
        "name": "apps@1000g-phase-3-v5@1.0.0",
        "display_name": "1000 Genomes Phase 3 (v5)",
        "description": "1000 Genomes Project Phase 3 reference panel"
    },

    # HapMap panels
    "hapmap": {
        "name": "apps@hapmap-2@1.0.0",
        "display_name": "HapMap 2",
        "description": "HapMap Phase 2 reference panel with 270 samples"
    },
    "hapmap2": {
        "name": "apps@hapmap-2@1.0.0",
        "display_name": "HapMap 2",
        "description": "HapMap Phase 2 reference panel"
    },

    # TOPMed panels
    "topmed": {
        "name": "apps@topmed-r2@1.0.0",
        "display_name": "TOPMed Freeze 8 (r2)",
        "description": "TOPMed reference panel with deep coverage WGS data"
    },
    "topmed_r2": {
        "name": "apps@topmed-r2@1.0.0",
        "display_name": "TOPMed Freeze 8 (r2)",
        "description": "TOPMed reference panel"
    },

    # CAAPA panels
    "caapa": {
        "name": "apps@caapa@1.0.0",
        "display_name": "CAAPA",
        "description": "Consortium on Asthma among African-ancestry Populations in the Americas"
    },

    # HGDP panels
    "hgdp": {
        "name": "apps@hgdp@1.0.0",
        "display_name": "HGDP",
        "description": "Human Genome Diversity Project reference panel"
    }
}


def get_michigan_services() -> List[Dict]:
    """Get all Michigan-type services from service registry."""
    try:
        response = requests.get(f"{SERVICE_REGISTRY_URL}/services")
        response.raise_for_status()
        services = response.json()

        # Filter for Michigan API type
        michigan_services = [s for s in services if s.get('api_type') == 'michigan']

        return michigan_services
    except Exception as e:
        print(f"❌ Error fetching services: {e}")
        sys.exit(1)


def get_panels_for_service(service_id: int) -> List[Dict]:
    """Get all reference panels for a specific service."""
    try:
        response = requests.get(
            f"{SERVICE_REGISTRY_URL}/reference-panels",
            params={"service_id": service_id}
        )
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"❌ Error fetching panels for service {service_id}: {e}")
        return []


def update_panel(panel_id: int, updates: Dict, dry_run: bool = False) -> bool:
    """Update a reference panel with Cloudgene format."""
    if dry_run:
        print(f"   [DRY RUN] Would update panel {panel_id} with: {updates}")
        return True

    try:
        response = requests.patch(
            f"{SERVICE_REGISTRY_URL}/reference-panels/{panel_id}",
            json=updates
        )
        response.raise_for_status()
        return True
    except Exception as e:
        print(f"   ❌ Error updating panel {panel_id}: {e}")
        return False


def migrate_panels(dry_run: bool = False):
    """Main migration function."""
    print("=" * 70)
    print("Reference Panel Cloudgene Format Migration")
    print("=" * 70)

    if dry_run:
        print("\n⚠️  DRY RUN MODE - No changes will be made\n")

    # Get Michigan services
    print("\n1. Finding Michigan-type services...")
    michigan_services = get_michigan_services()

    if not michigan_services:
        print("   ⚠️  No Michigan-type services found")
        return

    print(f"   ✓ Found {len(michigan_services)} Michigan-type service(s):")
    for svc in michigan_services:
        print(f"     - {svc['name']} (ID: {svc['id']})")

    # Process each service
    total_updated = 0
    total_skipped = 0
    total_already_correct = 0

    for service in michigan_services:
        print(f"\n2. Processing service: {service['name']} (ID: {service['id']})")

        panels = get_panels_for_service(service['id'])

        if not panels:
            print(f"   ℹ️  No panels found for this service")
            continue

        print(f"   Found {len(panels)} panel(s)")

        for panel in panels:
            panel_name = panel['name']
            panel_id = panel['id']

            print(f"\n   📋 Panel: {panel_name} (ID: {panel_id})")

            # Check if already in Cloudgene format
            if panel_name.startswith('apps@'):
                print(f"      ✓ Already in Cloudgene format")
                total_already_correct += 1
                continue

            # Check if we have a migration for this panel
            if panel_name in PANEL_MIGRATIONS:
                migration = PANEL_MIGRATIONS[panel_name]

                print(f"      Current name:  {panel_name}")
                print(f"      New name:      {migration['name']}")
                print(f"      Display name:  {migration['display_name']}")

                updates = {
                    'name': migration['name'],
                    'display_name': migration.get('display_name', panel.get('display_name')),
                    'description': migration.get('description', panel.get('description'))
                }

                if update_panel(panel_id, updates, dry_run):
                    print(f"      ✓ {'Would update' if dry_run else 'Updated'} successfully")
                    total_updated += 1
                else:
                    print(f"      ✗ Update failed")
            else:
                print(f"      ⚠️  No migration mapping found for '{panel_name}'")
                print(f"      💡 Panel needs manual review - add to PANEL_MIGRATIONS dict")
                total_skipped += 1

    # Summary
    print("\n" + "=" * 70)
    print("Migration Summary")
    print("=" * 70)
    print(f"  Total panels updated:        {total_updated}")
    print(f"  Already in correct format:   {total_already_correct}")
    print(f"  Skipped (no mapping):        {total_skipped}")

    if dry_run:
        print("\n⚠️  This was a DRY RUN - no actual changes were made")
        print("   Run without --dry-run to apply changes")
    else:
        print("\n✅ Migration complete!")

        if total_updated > 0:
            print("\n📝 Next steps:")
            print("   1. Restart job-processor: sudo docker restart job-processor")
            print("   2. Test job submission with a Michigan service")
            print("   3. Verify job uses correct Cloudgene format in logs")

    print("=" * 70)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Migrate reference panels to Cloudgene format",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Preview changes without applying them
    python scripts/migrate_michigan_panels_to_cloudgene.py --dry-run

    # Apply migrations
    python scripts/migrate_michigan_panels_to_cloudgene.py

Notes:
    - Only affects Michigan-type services (api_type='michigan')
    - Panel names must use format: apps@{app-id}@{version}
    - Display names remain human-readable for UI
    - See CLOUDGENE_REFERENCE_PANEL_FORMAT.md for details
        """
    )

    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Preview changes without applying them'
    )

    args = parser.parse_args()

    migrate_panels(dry_run=args.dry_run)


if __name__ == "__main__":
    main()
