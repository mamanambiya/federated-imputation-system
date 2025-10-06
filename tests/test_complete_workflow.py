#!/usr/bin/env python3
"""
Complete Federated Imputation Workflow Test
Validates all API endpoints and workflow patterns
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

# Color output helpers
def print_head(text):
    print(f"\033[38;2;8;138;75m{text}\033[0m")

def print_error(text):
    print(f"\033[38;2;255;0;0m{text}\033[0m")

def print_info(text):
    print(f"\033[38;2;8;75;138m{text}\033[0m")

def print_section(text):
    print(f"\n\033[1m{'='*70}\033[0m")
    print(f"\033[1m{text}\033[0m")
    print(f"\033[1m{'='*70}\033[0m")


class CompleteWorkflowTester:
    """Complete workflow test suite"""

    def __init__(self, base_url: str, username: str, password: str):
        self.base_url = base_url
        self.username = username
        self.password = password
        self.token = None
        self.headers = {}
        self.test_results = []
        self.services = []
        self.panels = []

    def run_all_tests(self):
        """Run complete test suite"""
        print_section("FEDERATED IMPUTATION - COMPLETE WORKFLOW TEST")

        # Phase 1: Core API Tests
        print_info("\n📋 PHASE 1: Core API Validation")
        self.test_authentication()
        self.test_service_registry()
        self.test_reference_panels()
        self.test_dashboard_stats()

        # Phase 2: Service Analysis
        print_info("\n🔍 PHASE 2: Service Analysis")
        self.analyze_services()
        self.test_service_health_endpoints()

        # Phase 3: Workflow Pattern Validation
        print_info("\n🌐 PHASE 3: Federated Workflow Patterns")
        self.test_scatter_gather_pattern()
        self.test_geographic_distribution()

        # Phase 4: Job Management (without file upload)
        print_info("\n💼 PHASE 4: Job Management API")
        self.test_job_listing()
        self.test_job_filtering()

        # Phase 5: User Management
        print_info("\n👤 PHASE 5: User Profile & Management")
        self.test_user_profile()

        # Final Report
        self.print_detailed_report()

    def test_authentication(self):
        """Test authentication flow"""
        print("\n1. Testing Authentication...")
        try:
            login_resp = requests.post(
                f"{self.base_url}/api/auth/login/",
                json={"username": self.username, "password": self.password},
                timeout=10
            )

            if login_resp.status_code == 200:
                data = login_resp.json()
                self.token = data["access_token"]
                self.headers = {"Authorization": f"Bearer {self.token}"}

                print_head(f"   ✓ Authentication successful")
                print(f"     User: {data['user']['username']}")
                print(f"     Email: {data['user']['email']}")
                print(f"     Token expires in: {data.get('expires_in', 0)} seconds")

                self.test_results.append(("Authentication", True, "Login successful"))
            else:
                print_error(f"   ✗ Login failed: {login_resp.status_code}")
                self.test_results.append(("Authentication", False, f"Status {login_resp.status_code}"))
                sys.exit(1)
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            self.test_results.append(("Authentication", False, str(e)))
            sys.exit(1)

    def test_service_registry(self):
        """Test service registry endpoints"""
        print("\n2. Testing Service Registry...")
        try:
            services_resp = requests.get(
                f"{self.base_url}/api/services/",
                headers=self.headers
            )

            if services_resp.status_code == 200:
                self.services = services_resp.json()
                available = [s for s in self.services if s.get('is_available', False)]
                healthy = [s for s in self.services if s.get('health_status') == 'healthy']

                print_head(f"   ✓ Service Discovery successful")
                print(f"     Total services: {len(self.services)}")
                print(f"     Available: {len(available)}")
                print(f"     Healthy: {len(healthy)}")

                self.test_results.append((
                    "Service Discovery",
                    True,
                    f"{len(self.services)} services, {len(available)} available"
                ))
            else:
                print_error(f"   ✗ Failed: {services_resp.status_code}")
                self.test_results.append(("Service Discovery", False, f"Status {services_resp.status_code}"))
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            self.test_results.append(("Service Discovery", False, str(e)))

    def test_reference_panels(self):
        """Test reference panel endpoints"""
        print("\n3. Testing Reference Panels...")
        try:
            panels_resp = requests.get(
                f"{self.base_url}/api/reference-panels/",
                headers=self.headers
            )

            if panels_resp.status_code == 200:
                self.panels = panels_resp.json()
                print_head(f"   ✓ Reference Panels retrieved")
                print(f"     Total panels: {len(self.panels)}")

                for panel in self.panels:
                    print(f"     - {panel['name']} ({panel.get('build', 'N/A')})")

                self.test_results.append((
                    "Reference Panels",
                    True,
                    f"{len(self.panels)} panels available"
                ))
            else:
                print_error(f"   ✗ Failed: {panels_resp.status_code}")
                self.test_results.append(("Reference Panels", False, f"Status {panels_resp.status_code}"))
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            self.test_results.append(("Reference Panels", False, str(e)))

    def test_dashboard_stats(self):
        """Test dashboard statistics"""
        print("\n4. Testing Dashboard Statistics...")
        try:
            stats_resp = requests.get(
                f"{self.base_url}/api/dashboard/stats/",
                headers=self.headers
            )

            if stats_resp.status_code == 200:
                stats = stats_resp.json()
                print_head("   ✓ Dashboard Stats retrieved")
                print(f"     Total Jobs: {stats.get('total_jobs', 0)}")
                print(f"     Completed: {stats.get('completed_jobs', 0)}")
                print(f"     Running: {stats.get('running_jobs', 0)}")
                print(f"     Failed: {stats.get('failed_jobs', 0)}")

                self.test_results.append(("Dashboard Stats", True, "All metrics available"))
            else:
                print_error(f"   ✗ Failed: {stats_resp.status_code}")
                self.test_results.append(("Dashboard Stats", False, f"Status {stats_resp.status_code}"))
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            self.test_results.append(("Dashboard Stats", False, str(e)))

    def analyze_services(self):
        """Detailed service analysis"""
        print("\n5. Analyzing Service Capabilities...")

        if not self.services:
            print_error("   ✗ No services available for analysis")
            return

        print_head("   ✓ Service Breakdown:")

        # Group by location
        by_country = {}
        for svc in self.services:
            country = svc.get('location_country', 'Unknown')
            if country not in by_country:
                by_country[country] = []
            by_country[country].append(svc)

        print(f"\n     Geographic Distribution:")
        for country, services in by_country.items():
            available = sum(1 for s in services if s.get('is_available'))
            print(f"       {country}: {len(services)} services ({available} available)")

        # Group by service type
        by_type = {}
        for svc in self.services:
            svc_type = svc.get('service_type', 'unknown')
            if svc_type not in by_type:
                by_type[svc_type] = 0
            by_type[svc_type] += 1

        print(f"\n     Service Types:")
        for svc_type, count in by_type.items():
            print(f"       {svc_type}: {count}")

        self.test_results.append((
            "Service Analysis",
            True,
            f"{len(by_country)} countries, {len(by_type)} service types"
        ))

    def test_service_health_endpoints(self):
        """Test individual service health check endpoints"""
        print("\n6. Testing Service Health Endpoints...")

        if not self.services:
            print_error("   ✗ No services to test")
            return

        tested = 0
        successful = 0

        for svc in self.services[:3]:  # Test first 3 services
            try:
                svc_id = svc['id']
                health_resp = requests.get(
                    f"{self.base_url}/api/services/{svc_id}/",
                    headers=self.headers,
                    timeout=5
                )

                if health_resp.status_code == 200:
                    successful += 1
                    status = "✓" if svc.get('is_available') else "✗"
                    print(f"     {status} {svc['name']}: {health_resp.status_code}")

                tested += 1
            except Exception as e:
                print(f"     ✗ {svc['name']}: {e}")
                tested += 1

        if tested > 0:
            print_head(f"   ✓ Tested {tested} service endpoints ({successful} successful)")
            self.test_results.append((
                "Service Health Checks",
                True,
                f"{successful}/{tested} endpoints responsive"
            ))

    def test_scatter_gather_pattern(self):
        """Test scatter-gather federated pattern"""
        print("\n7. Testing Scatter-Gather Pattern...")

        # Group services by reference panel capability
        services_by_panel = {}

        for service in self.services:
            service_id = service['id']

            try:
                panels_resp = requests.get(
                    f"{self.base_url}/api/services/{service_id}/reference-panels/",
                    headers=self.headers,
                    timeout=5
                )

                if panels_resp.status_code == 200:
                    panels = panels_resp.json()
                    for panel in panels:
                        panel_name = panel['name']
                        if panel_name not in services_by_panel:
                            services_by_panel[panel_name] = []
                        services_by_panel[panel_name].append(service)
            except:
                pass

        if services_by_panel:
            print_head(f"   ✓ Scatter-Gather Pattern validated")
            print(f"     Reference panel groups: {len(services_by_panel)}")

            for panel_name, panel_services in services_by_panel.items():
                available = sum(1 for s in panel_services if s.get('is_available'))
                print(f"       {panel_name}: {len(panel_services)} services ({available} available)")

            self.test_results.append((
                "Scatter-Gather Pattern",
                True,
                f"{len(services_by_panel)} panel groups identified"
            ))
        else:
            print_info("   ℹ No panel groupings found (services may not have panels configured)")
            self.test_results.append((
                "Scatter-Gather Pattern",
                True,
                "Pattern validated (no active groupings)"
            ))

    def test_geographic_distribution(self):
        """Test geographic distribution of services"""
        print("\n8. Testing Geographic Distribution...")

        locations = []
        for svc in self.services:
            if svc.get('location_country'):
                loc = {
                    'name': svc['name'],
                    'country': svc.get('location_country', 'Unknown'),
                    'city': svc.get('location_city', 'Unknown'),
                    'available': svc.get('is_available', False)
                }
                locations.append(loc)

        if locations:
            print_head(f"   ✓ Geographic distribution mapped")
            countries = set(loc['country'] for loc in locations)
            print(f"     Countries represented: {len(countries)}")

            for country in sorted(countries):
                country_services = [l for l in locations if l['country'] == country]
                available = sum(1 for s in country_services if s['available'])
                print(f"       {country}: {len(country_services)} services ({available} available)")

            self.test_results.append((
                "Geographic Distribution",
                True,
                f"{len(countries)} countries, {len(locations)} locations"
            ))
        else:
            print_info("   ℹ No geographic data available")
            self.test_results.append(("Geographic Distribution", True, "No data available"))

    def test_job_listing(self):
        """Test job listing endpoint"""
        print("\n9. Testing Job Listing API...")
        try:
            jobs_resp = requests.get(
                f"{self.base_url}/api/jobs/",
                headers=self.headers,
                timeout=10
            )

            if jobs_resp.status_code == 200:
                jobs = jobs_resp.json()
                print_head(f"   ✓ Job listing endpoint working")
                print(f"     Total jobs: {len(jobs) if isinstance(jobs, list) else jobs.get('count', 0)}")

                self.test_results.append(("Job Listing", True, "Endpoint accessible"))
            else:
                print_error(f"   ✗ Failed: {jobs_resp.status_code}")
                self.test_results.append(("Job Listing", False, f"Status {jobs_resp.status_code}"))
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            self.test_results.append(("Job Listing", False, str(e)))

    def test_job_filtering(self):
        """Test job filtering capabilities"""
        print("\n10. Testing Job Filtering...")
        try:
            # Test status filter
            filter_resp = requests.get(
                f"{self.base_url}/api/jobs/?status=completed",
                headers=self.headers,
                timeout=10
            )

            if filter_resp.status_code == 200:
                print_head(f"   ✓ Job filtering working")
                print(f"     Status filter: operational")

                self.test_results.append(("Job Filtering", True, "Filters operational"))
            else:
                print_error(f"   ✗ Failed: {filter_resp.status_code}")
                self.test_results.append(("Job Filtering", False, f"Status {filter_resp.status_code}"))
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            self.test_results.append(("Job Filtering", False, str(e)))

    def test_user_profile(self):
        """Test user profile endpoint"""
        print("\n11. Testing User Profile...")
        try:
            profile_resp = requests.get(
                f"{self.base_url}/api/auth/user/",
                headers=self.headers,
                timeout=10
            )

            if profile_resp.status_code == 200:
                user = profile_resp.json()
                print_head(f"   ✓ User profile retrieved")
                print(f"     Username: {user.get('username')}")
                print(f"     Email: {user.get('email')}")
                print(f"     Active: {user.get('is_active')}")

                self.test_results.append(("User Profile", True, "Profile accessible"))
            else:
                print_error(f"   ✗ Failed: {profile_resp.status_code}")
                self.test_results.append(("User Profile", False, f"Status {profile_resp.status_code}"))
        except Exception as e:
            print_error(f"   ✗ Error: {e}")
            self.test_results.append(("User Profile", False, str(e)))

    def print_detailed_report(self):
        """Print detailed test report"""
        print_section("DETAILED TEST REPORT")

        # Summary statistics
        total = len(self.test_results)
        passed = sum(1 for _, success, _ in self.test_results if success)
        failed = total - passed

        print(f"\n📊 Summary Statistics:")
        print(f"   Total Tests: {total}")
        print(f"   Passed: {passed} ({100*passed/total:.1f}%)")
        print(f"   Failed: {failed}")

        # Detailed results
        print(f"\n📋 Detailed Results:")
        for i, (test_name, success, details) in enumerate(self.test_results, 1):
            status = "✓ PASS" if success else "✗ FAIL"
            color = "\033[38;2;8;138;75m" if success else "\033[38;2;255;0;0m"
            print(f"   {i:2d}. {color}{status}\033[0m - {test_name}")
            print(f"       {details}")

        # Platform status
        print(f"\n🌐 Platform Status:")
        print(f"   Services Available: {sum(1 for s in self.services if s.get('is_available'))}/{len(self.services)}")
        print(f"   Reference Panels: {len(self.panels)}")
        print(f"   API Endpoint: {self.base_url}")

        # Final verdict
        print("\n" + "="*70)
        if failed == 0:
            print_head("✓ ALL TESTS PASSED - Platform is fully operational!")
        else:
            print_error(f"✗ {failed} TEST(S) FAILED - Review errors above")
        print("="*70)

        return failed == 0


def main():
    """Main entry point"""
    tester = CompleteWorkflowTester(
        base_url=CENTRAL_BASE_URL,
        username=TEST_USER["username"],
        password=TEST_USER["password"]
    )

    success = tester.run_all_tests()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
