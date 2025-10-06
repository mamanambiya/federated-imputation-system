#!/usr/bin/env python3
"""
Test Michigan Job Submission with Cloudgene Format

This script demonstrates how the job processor will submit jobs to Michigan-type
services using the correct Cloudgene reference panel format.

It directly queries the service registry (via HTTP) to get panel details and
shows what parameters would be sent to the Michigan API.

Usage:
    python scripts/test_michigan_submission.py
"""

import requests
import json
from typing import Dict, Any

SERVICE_REGISTRY_URL = "http://localhost:8002"


def get_reference_panel(panel_id: int) -> Dict[str, Any]:
    """
    Get reference panel details from service registry.

    This simulates what the job processor does in worker.py line 112-117.
    """
    try:
        response = requests.get(f"{SERVICE_REGISTRY_URL}/reference-panels")
        response.raise_for_status()
        panels = response.json()

        # Find the panel with matching ID
        for panel in panels:
            if panel['id'] == panel_id:
                return panel

        raise ValueError(f"Panel ID {panel_id} not found")

    except Exception as e:
        print(f"❌ Error fetching panel: {e}")
        raise


def simulate_michigan_job_submission(panel_id: int, build: str = "hg19"):
    """
    Simulate what would be sent to Michigan API.

    This shows the exact parameters that will be used based on the
    Cloudgene format implementation.
    """
    print("=" * 70)
    print("Michigan Job Submission Simulation")
    print("=" * 70)

    # Step 1: Get panel details (like worker.py does)
    print(f"\n1. Fetching reference panel details for ID: {panel_id}")
    panel_info = get_reference_panel(panel_id)

    print(f"   ✓ Panel retrieved:")
    print(f"     Database ID:   {panel_info['id']}")
    print(f"     Panel Name:    {panel_info['name']}")  # This is what we'll send!
    print(f"     Display Name:  {panel_info['display_name']}")
    print(f"     Population:    {panel_info['population']}")
    print(f"     Build:         {panel_info['build']}")

    # Step 2: Prepare Michigan API parameters
    panel_identifier = panel_info.get('name')  # Cloudgene format

    print(f"\n2. Preparing Michigan API parameters:")

    # Check if panel name is in correct Cloudgene format
    if panel_identifier.startswith('apps@'):
        print(f"   ✅ Panel name is in correct Cloudgene format")
    else:
        print(f"   ❌ WARNING: Panel name is NOT in Cloudgene format!")
        print(f"   Expected format: apps@{{app-id}}@{{version}}")
        print(f"   Current value:   {panel_identifier}")

    # This is what gets sent to Michigan API
    michigan_params = {
        'input-format': 'vcf',
        'refpanel': panel_identifier,  # CRITICAL: Cloudgene format
        'build': build,
        'phasing': 'eagle',
        'population': 'mixed',
        'mode': 'imputation',
        'r2Filter': '0.3'
    }

    print(f"\n3. Michigan API POST parameters:")
    print(json.dumps(michigan_params, indent=2))

    # Step 3: Show what the request would look like
    print(f"\n4. Example curl command:")
    print(f"   curl -X POST https://impute.afrigen-d.org/api/v2/jobs/submit/imputationserver2 \\")
    print(f"     -H 'X-Auth-Token: YOUR_TOKEN' \\")
    print(f"     -F 'file=@input.vcf.gz' \\")
    for key, value in michigan_params.items():
        print(f"     -F '{key}={value}' \\")

    # Summary
    print(f"\n" + "=" * 70)
    if panel_identifier.startswith('apps@'):
        print("✅ SUCCESS: Panel is configured correctly for Michigan API")
        print(f"   Job submissions will use: {panel_identifier}")
    else:
        print("❌ ERROR: Panel needs to be updated to Cloudgene format")
        print(f"   Run: python scripts/migrate_michigan_panels_to_cloudgene.py")
    print("=" * 70)


def test_all_michigan_panels():
    """Test all Michigan service panels."""
    print("\n" + "=" * 70)
    print("Testing All Michigan Service Panels")
    print("=" * 70)

    try:
        # Get all panels
        response = requests.get(f"{SERVICE_REGISTRY_URL}/reference-panels")
        response.raise_for_status()
        all_panels = response.json()

        # Get Michigan services
        services_response = requests.get(f"{SERVICE_REGISTRY_URL}/services")
        services_response.raise_for_status()
        services = services_response.json()

        michigan_service_ids = [s['id'] for s in services if s.get('api_type') == 'michigan']

        print(f"\nFound {len(michigan_service_ids)} Michigan-type service(s)")

        # Filter panels for Michigan services
        michigan_panels = [p for p in all_panels if p['service_id'] in michigan_service_ids]

        print(f"Found {len(michigan_panels)} panel(s) for Michigan services\n")

        for panel in michigan_panels:
            panel_name = panel['name']
            status = "✅" if panel_name.startswith('apps@') else "❌"
            print(f"{status} Panel ID {panel['id']}: {panel_name}")

    except Exception as e:
        print(f"❌ Error: {e}")


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Test Michigan job submission parameters",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Test specific panel
    python scripts/test_michigan_submission.py --panel-id 2

    # Test specific panel with build
    python scripts/test_michigan_submission.py --panel-id 2 --build hg38

    # Test all Michigan panels
    python scripts/test_michigan_submission.py --all

Notes:
    - This script simulates what the job processor will do
    - It shows the exact parameters that will be sent to Michigan API
    - Use this to verify Cloudgene format is correct before submitting real jobs
        """
    )

    parser.add_argument(
        '--panel-id',
        type=int,
        help='Reference panel ID to test'
    )

    parser.add_argument(
        '--build',
        default='hg19',
        choices=['hg19', 'hg38'],
        help='Genome build (default: hg19)'
    )

    parser.add_argument(
        '--all',
        action='store_true',
        help='Test all Michigan service panels'
    )

    args = parser.parse_args()

    if args.all:
        test_all_michigan_panels()
    elif args.panel_id:
        simulate_michigan_job_submission(args.panel_id, args.build)
    else:
        # Default: test panel 2 (H3Africa)
        print("No panel specified, testing panel ID 2 (H3Africa)...\n")
        simulate_michigan_job_submission(2, args.build)


if __name__ == "__main__":
    main()
