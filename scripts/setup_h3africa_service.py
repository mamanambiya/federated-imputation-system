#!/usr/bin/env python3
"""
H3Africa Imputation Service Setup Script

This script registers the H3Africa Imputation Server (https://impute.afrigen-d.org/)
in the Service Registry with proper configuration for Michigan API integration.

Usage:
    python scripts/setup_h3africa_service.py --api-token YOUR_TOKEN

Prerequisites:
    1. Register account at https://impute.afrigen-d.org/
    2. Navigate to Settings → API Tokens
    3. Generate new API token
    4. Use the token with this script
"""

import argparse
import sys
import requests
import json
from typing import Dict, Any

# Service Registry URL
SERVICE_REGISTRY_URL = "http://localhost:8002"


def create_h3africa_service(api_token: str) -> Dict[str, Any]:
    """
    Create H3Africa imputation service entry.

    Args:
        api_token: H3Africa API authentication token

    Returns:
        Created service data with ID
    """
    service_data = {
        "name": "H3Africa Imputation Server",
        "service_type": "h3africa",
        "api_type": "michigan",  # Uses Michigan Imputation Server API
        "base_url": "https://impute.afrigen-d.org",
        "description": "African-focused imputation service using H3Africa reference panel with diverse African populations",
        "version": "2.0",
        "requires_auth": True,
        "auth_type": "token",
        "max_file_size_mb": 100,
        "supported_formats": ["vcf"],
        "supported_builds": ["hg19", "hg38"],
        "api_config": {
            "api_token": api_token,
            "api_endpoint": "https://impute.afrigen-d.org/api/v2"
        },
        "is_active": True
    }

    print("Creating H3Africa service in Service Registry...")
    print(f"URL: {SERVICE_REGISTRY_URL}/services")

    try:
        response = requests.post(
            f"{SERVICE_REGISTRY_URL}/services",
            json=service_data,
            timeout=30
        )
        response.raise_for_status()

        service = response.json()
        print(f"✅ Service created successfully - ID: {service['id']}")
        print(f"   Name: {service['name']}")
        print(f"   Type: {service['api_type']}")
        print(f"   URL: {service['base_url']}")

        return service

    except requests.exceptions.ConnectionError:
        print(f"❌ Error: Cannot connect to Service Registry at {SERVICE_REGISTRY_URL}")
        print("   Make sure the microservices are running: docker-compose ps")
        sys.exit(1)
    except requests.exceptions.HTTPError as e:
        print(f"❌ HTTP Error: {e}")
        print(f"   Response: {e.response.text}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error creating service: {e}")
        sys.exit(1)


def create_h3africa_panels(service_id: int) -> None:
    """
    Create reference panels for H3Africa service.

    IMPORTANT: Michigan/Cloudgene servers require specific app reference format:
    - Format: apps@{app-id}@{version}
    - Example: apps@h3africa-v6hc-s@1.0.0

    The 'name' field MUST contain this Cloudgene format for job submissions to work.

    Args:
        service_id: ID of the created service
    """
    panels = [
        {
            "service_id": service_id,
            "name": "apps@h3africa-v6hc-s@1.0.0",  # Cloudgene format - REQUIRED for Michigan API
            "display_name": "H3Africa Reference Panel (v6)",
            "description": "African populations reference panel with 5,000+ samples from diverse African regions",
            "population": "AFR",
            "build": "hg38",
            "samples_count": 5000,
            "is_available": True,
            "is_public": True
        },
        {
            "service_id": service_id,
            "name": "apps@1000g-phase-3-v5@1.0.0",  # Cloudgene format - REQUIRED for Michigan API
            "display_name": "1000 Genomes Phase 3 (v5)",
            "description": "1000 Genomes Project Phase 3 reference panel",
            "population": "ALL",
            "build": "hg19",
            "samples_count": 2504,
            "is_available": True,
            "is_public": True
        },
        {
            "service_id": service_id,
            "name": "apps@hapmap-2@1.0.0",  # Cloudgene format - REQUIRED for Michigan API
            "display_name": "HapMap 2",
            "description": "HapMap Phase 2 reference panel",
            "population": "ALL",
            "build": "hg19",
            "samples_count": 270,
            "is_available": True,
            "is_public": True
        }
    ]

    print("\nCreating reference panels...")

    for panel_data in panels:
        try:
            response = requests.post(
                f"{SERVICE_REGISTRY_URL}/services/{service_id}/panels",
                json=panel_data,
                timeout=30
            )
            response.raise_for_status()

            panel = response.json()
            print(f"✅ Created panel: {panel['display_name']} ({panel['name']})")
            print(f"   Population: {panel['population']}, Build: {panel['build']}, Samples: {panel.get('samples_count', 'N/A')}")

        except requests.exceptions.HTTPError as e:
            print(f"⚠️  Warning: Failed to create panel '{panel_data['name']}': {e}")
            print(f"   Response: {e.response.text}")
        except Exception as e:
            print(f"⚠️  Warning: Failed to create panel '{panel_data['name']}': {e}")


def verify_service_health(service_id: int) -> None:
    """
    Verify the H3Africa service is accessible and healthy.

    Args:
        service_id: ID of the service to check
    """
    print("\nVerifying service health...")

    try:
        # Trigger health check
        response = requests.post(
            f"{SERVICE_REGISTRY_URL}/services/{service_id}/health-check",
            timeout=60  # H3Africa may take time to respond
        )

        if response.status_code == 200:
            health_data = response.json()
            status = health_data.get('health_status', 'unknown')
            response_time = health_data.get('response_time_ms', 0)

            if status == 'healthy':
                print(f"✅ Service is healthy - Response time: {response_time:.1f}ms")
            else:
                print(f"⚠️  Service status: {status}")
                if 'error_message' in health_data:
                    print(f"   Error: {health_data['error_message']}")
        else:
            print(f"⚠️  Health check returned status {response.status_code}")

    except requests.exceptions.Timeout:
        print("⚠️  Health check timed out - Service may be slow to respond")
        print("   This is normal for H3Africa. Run health check manually later.")
    except Exception as e:
        print(f"⚠️  Could not verify health: {e}")
        print("   Run health check manually: curl http://localhost:8002/services/{service_id}/health-check")


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(
        description="Setup H3Africa Imputation Service in Service Registry",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python scripts/setup_h3africa_service.py --api-token abc123def456

Note:
    Get your API token from https://impute.afrigen-d.org/
    Account Settings → API Tokens → Generate New Token
        """
    )

    parser.add_argument(
        '--api-token',
        required=True,
        help='H3Africa API authentication token'
    )

    parser.add_argument(
        '--skip-panels',
        action='store_true',
        help='Skip creating reference panels'
    )

    parser.add_argument(
        '--skip-health-check',
        action='store_true',
        help='Skip health check verification'
    )

    args = parser.parse_args()

    print("=" * 60)
    print("H3Africa Imputation Service Setup")
    print("=" * 60)

    # Create service
    service = create_h3africa_service(args.api_token)
    service_id = service['id']

    # Create reference panels
    if not args.skip_panels:
        create_h3africa_panels(service_id)
    else:
        print("\n⏭️  Skipping panel creation")

    # Verify health
    if not args.skip_health_check:
        verify_service_health(service_id)
    else:
        print("\n⏭️  Skipping health check")

    print("\n" + "=" * 60)
    print("✅ Setup Complete!")
    print("=" * 60)
    print(f"\nService ID: {service_id}")
    print(f"Service URL: {service['base_url']}")
    print("\nNext steps:")
    print("1. Verify service in admin panel: http://localhost:8000/admin/")
    print("2. Test job submission with a small VCF file")
    print("3. Monitor job processing in logs: docker logs job-processor -f")
    print("\n")


if __name__ == "__main__":
    main()
