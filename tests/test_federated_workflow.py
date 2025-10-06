#!/usr/bin/env python3
"""
Federated Imputation Platform - Integration Test
Based on the Elwazi pilot node testing pattern
"""

import requests
import json
import time
import sys
from typing import Dict, List, Any

# Configuration
CENTRAL_BASE_URL = "http://154.114.10.123:8000"
TEST_USER = {
    "username": "testuser",
    "password": "testpass123"
}

# Helper functions
def print_head(text):
    """Print in green color"""
    print(f"\033[38;2;8;138;75m{text}\033[0m")

def print_error(text):
    """Print in red color"""
    print(f"\033[38;2;255;0;0m{text}\033[0m")

def print_info(text):
    """Print in blue color"""
    print(f"\033[38;2;8;75;138m{text}\033[0m")

class FederatedImputationTester:
    """Test harness for federated imputation platform"""

    def __init__(self, base_url: str, username: str, password: str):
        self.base_url = base_url
        self.username = username
        self.password = password
        self.token = None
        self.headers = {}
        self.test_results = []

    def run_all_tests(self):
        """Run all integration tests"""
        print("="*60)
        print("FEDERATED IMPUTATION PLATFORM - INTEGRATION TEST")
        print("="*60)

        tests = [
            ("Authentication", self.test_authentication),
            ("Service Discovery", self.test_service_discovery),
            ("Reference Panels", self.test_reference_panels),
            ("Dashboard Stats", self.test_dashboard_stats),
            ("Scatter-Gather Pattern", self.test_scatter_gather),
        ]

        for test_name, test_func in tests:
            print(f"\n{len(self.test_results) + 1}. Testing {test_name}...")
            try:
                result = test_func()
                self.test_results.append((test_name, result))
            except Exception as e:
                print_error(f"   ✗ Error: {e}")
                self.test_results.append((test_name, False))

        self.print_summary()

    def test_authentication(self) -> bool:
        """Test 1: Authentication"""
        try:
            login_resp = requests.post(
                f"{self.base_url}/api/auth/login/",
                json={"username": self.username, "password": self.password},
                timeout=10
            )

            if login_resp.status_code == 200:
                self.token = login_resp.json()["access_token"]
                self.headers = {"Authorization": f"Bearer {self.token}"}
                print_head(f"   ✓ Login successful! Token: {self.token[:30]}...")
                return True
            else:
                print_error(f"   ✗ Login failed: {login_resp.status_code}")
                return False
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            return False

    def test_service_discovery(self) -> bool:
        """Test 2: Service Discovery"""
        try:
            services_resp = requests.get(
                f"{self.base_url}/api/services/",
                headers=self.headers
            )

            if services_resp.status_code == 200:
                services = services_resp.json()
                healthy_services = [s for s in services if s.get('is_available', False)]

                print_head(f"   ✓ Found {len(services)} services ({len(healthy_services)} available)")

                for svc in services:
                    status = "✓" if svc.get('is_available') else "✗"
                    health = svc.get('health_status', 'unknown')
                    print(f"     {status} {svc['name']} ({health})")
                    print(f"        URL: {svc['base_url']}")
                    print(f"        Location: {svc.get('location_city', 'N/A')}, {svc.get('location_country', 'N/A')}")

                return True
            else:
                print_error(f"   ✗ Failed: {services_resp.status_code}")
                return False
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            return False

    def test_reference_panels(self) -> bool:
        """Test 3: Reference Panels"""
        try:
            panels_resp = requests.get(
                f"{self.base_url}/api/reference-panels/",
                headers=self.headers
            )

            if panels_resp.status_code == 200:
                panels = panels_resp.json()
                print_head(f"   ✓ Found {len(panels)} reference panels")

                for panel in panels:
                    print(f"     - {panel['name']} ({panel.get('build', 'N/A')})")
                    if panel.get('description'):
                        desc = panel['description'][:60]
                        print(f"       {desc}...")

                return True
            else:
                print_error(f"   ✗ Failed: {panels_resp.status_code}")
                return False
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            return False

    def test_dashboard_stats(self) -> bool:
        """Test 4: Dashboard Statistics"""
        try:
            stats_resp = requests.get(
                f"{self.base_url}/api/dashboard/stats/",
                headers=self.headers
            )

            if stats_resp.status_code == 200:
                stats = stats_resp.json()
                print_head("   ✓ Dashboard Statistics:")
                print(f"     Total Jobs: {stats.get('total_jobs', 0)}")
                print(f"     Completed: {stats.get('completed_jobs', 0)}")
                print(f"     Failed: {stats.get('failed_jobs', 0)}")
                print(f"     Running: {stats.get('running_jobs', 0)}")
                print(f"     Available Services: {stats.get('healthy_services', 0)}")

                return True
            else:
                print_error(f"   ✗ Failed: {stats_resp.status_code}")
                return False
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            return False

    def test_scatter_gather(self) -> bool:
        """Test 5: Scatter-Gather Service Grouping Pattern"""
        try:
            services_resp = requests.get(
                f"{self.base_url}/api/services/",
                headers=self.headers
            )

            if services_resp.status_code != 200:
                print_error("   ✗ No services available")
                return False

            services = services_resp.json()

            # Group by reference panel (scatter pattern)
            services_by_panel = {}
            for service in services:
                # Get reference panels from service API
                service_id = service['id']
                panels_resp = requests.get(
                    f"{self.base_url}/api/services/{service_id}/reference-panels/",
                    headers=self.headers
                )

                if panels_resp.status_code == 200:
                    panels = panels_resp.json()
                    for panel in panels:
                        panel_name = panel['name']
                        if panel_name not in services_by_panel:
                            services_by_panel[panel_name] = []
                        services_by_panel[panel_name].append({
                            'service': service,
                            'panel_info': panel
                        })

            print_head(f"   ✓ Scatter-Gather Pattern: {len(services_by_panel)} reference panel groups")

            for panel_name, panel_services in services_by_panel.items():
                available = sum(1 for ps in panel_services if ps['service'].get('is_available'))
                print(f"\n     {panel_name}: {len(panel_services)} service(s) ({available} available)")

                for ps in panel_services:
                    svc = ps['service']
                    status = "✓" if svc.get('is_available') else "✗"
                    print(f"       {status} {svc['name']}")
                    print(f"          {svc['base_url']}")
                    print(f"          {svc.get('location_city', 'N/A')}, {svc.get('location_country', 'N/A')}")

            print_info("\n   This demonstrates the federated scatter-gather pattern:")
            print_info("   - Jobs can be scattered across multiple geographic nodes")
            print_info("   - Each node processes data with its local reference panel")
            print_info("   - Results are gathered centrally for the user")

            return True
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            import traceback
            traceback.print_exc()
            return False

    def print_summary(self):
        """Print test summary"""
        print("\n" + "="*60)
        print("TEST SUMMARY")
        print("="*60)

        for test_name, passed in self.test_results:
            status = "✓ PASS" if passed else "✗ FAIL"
            color = "\033[38;2;8;138;75m" if passed else "\033[38;2;255;0;0m"
            print(f"{color}{status}\033[0m - {test_name}")

        total = len(self.test_results)
        passed = sum(1 for _, p in self.test_results if p)

        print(f"\n{passed}/{total} tests passed")

        if passed == total:
            print_head("\n✓ All tests passed! The federated imputation platform is working correctly.")
        else:
            print_error(f"\n✗ {total - passed} test(s) failed. Please review the errors above.")

        print("="*60)

        return passed == total


def main():
    """Main entry point"""
    tester = FederatedImputationTester(
        base_url=CENTRAL_BASE_URL,
        username=TEST_USER["username"],
        password=TEST_USER["password"]
    )

    success = tester.run_all_tests()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
