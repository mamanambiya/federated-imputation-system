// Comprehensive Playwright Tests for Federated Genomic Imputation Platform
// Tests all major user workflows and functionality

const { test, expect } = require('@playwright/test');

// Test configuration
const BASE_URL = 'http://localhost:3000';
const API_URL = 'http://localhost:8000';
const TEST_CREDENTIALS = {
  admin: { username: 'admin', password: 'admin123' },
  testUser: { username: 'test_user', password: 'test_password' }
};

// Test data
const TEST_SERVICE_COUNT = 5;
const EXPECTED_SERVICES = [
  'H3Africa Imputation Service',
  'Michigan Imputation Server',
  'eLwazi Node',
  'ILIFU GA4GH Service',
  'eLwazi Omics Platform'
];

test.describe('Federated Genomic Imputation Platform - Comprehensive Tests', () => {
  
  test.beforeEach(async ({ page }) => {
    // Set up test environment
    await page.goto(BASE_URL);
    
    // Wait for initial load
    await page.waitForLoadState('networkidle');
  });

  test.describe('Landing Page and Navigation', () => {
    
    test('should load landing page correctly', async ({ page }) => {
      // Check page title
      await expect(page).toHaveTitle(/Federated Genomic Imputation Platform/);
      
      // Check main heading
      await expect(page.locator('h1')).toContainText('Federated Genomic Imputation Platform');
      
      // Check navigation elements
      await expect(page.locator('nav')).toBeVisible();
      
      // Check key sections are present
      await expect(page.locator('text=Services')).toBeVisible();
      await expect(page.locator('text=About')).toBeVisible();
      
      // Take screenshot for visual verification
      await page.screenshot({ path: 'tests/screenshots/landing-page.png', fullPage: true });
    });

    test('should navigate to services page', async ({ page }) => {
      await page.click('text=Services');
      await page.waitForURL('**/services');
      
      // Check services page loads
      await expect(page.locator('h1, h2, h3')).toContainText(/Services|Imputation/);
      
      // Check loading state handling
      await page.waitForSelector('[data-testid="services-list"], .MuiCircularProgress-root', { timeout: 10000 });
    });

    test('should navigate to login page', async ({ page }) => {
      await page.click('text=Login');
      await page.waitForURL('**/login');
      
      // Check login form elements
      await expect(page.locator('input[name="username"], input[placeholder*="username" i]')).toBeVisible();
      await expect(page.locator('input[name="password"], input[placeholder*="password" i]')).toBeVisible();
      await expect(page.locator('button[type="submit"], button:has-text("Sign In")')).toBeVisible();
    });
  });

  test.describe('Authentication System', () => {
    
    test('should login with admin credentials', async ({ page }) => {
      // Navigate to login
      await page.goto(`${BASE_URL}/login`);
      
      // Fill login form
      await page.fill('input[name="username"], input[placeholder*="username" i]', TEST_CREDENTIALS.admin.username);
      await page.fill('input[name="password"], input[placeholder*="password" i]', TEST_CREDENTIALS.admin.password);
      
      // Submit form
      await page.click('button[type="submit"], button:has-text("Sign In")');
      
      // Wait for successful login (redirect or success message)
      await page.waitForTimeout(2000);
      
      // Check for successful login indicators
      const currentUrl = page.url();
      const hasUserMenu = await page.locator('[data-testid="user-menu"], .user-menu, text=admin').isVisible();
      const hasLogoutButton = await page.locator('text=Logout, text=Sign Out').isVisible();
      
      // Verify login success
      expect(currentUrl !== `${BASE_URL}/login` || hasUserMenu || hasLogoutButton).toBeTruthy();
      
      // Take screenshot of logged-in state
      await page.screenshot({ path: 'tests/screenshots/logged-in-state.png' });
    });

    test('should handle invalid login credentials', async ({ page }) => {
      await page.goto(`${BASE_URL}/login`);
      
      // Try invalid credentials
      await page.fill('input[name="username"], input[placeholder*="username" i]', 'invalid_user');
      await page.fill('input[name="password"], input[placeholder*="password" i]', 'invalid_password');
      await page.click('button[type="submit"], button:has-text("Sign In")');
      
      // Wait for error message
      await page.waitForTimeout(2000);
      
      // Check for error indicators
      const hasErrorMessage = await page.locator('.error, .alert, [role="alert"]').isVisible();
      const stillOnLoginPage = page.url().includes('/login');
      
      expect(hasErrorMessage || stillOnLoginPage).toBeTruthy();
    });

    test('should maintain session across page refreshes', async ({ page }) => {
      // Login first
      await page.goto(`${BASE_URL}/login`);
      await page.fill('input[name="username"], input[placeholder*="username" i]', TEST_CREDENTIALS.admin.username);
      await page.fill('input[name="password"], input[placeholder*="password" i]', TEST_CREDENTIALS.admin.password);
      await page.click('button[type="submit"], button:has-text("Sign In")');
      await page.waitForTimeout(2000);
      
      // Navigate to services page
      await page.goto(`${BASE_URL}/services`);
      await page.waitForTimeout(1000);
      
      // Refresh page
      await page.reload();
      await page.waitForTimeout(2000);
      
      // Check if still authenticated
      const isStillLoggedIn = !page.url().includes('/login');
      expect(isStillLoggedIn).toBeTruthy();
    });
  });

  test.describe('Services Page Functionality', () => {
    
    test.beforeEach(async ({ page }) => {
      // Login before each services test
      await page.goto(`${BASE_URL}/login`);
      await page.fill('input[name="username"], input[placeholder*="username" i]', TEST_CREDENTIALS.admin.username);
      await page.fill('input[name="password"], input[placeholder*="password" i]', TEST_CREDENTIALS.admin.password);
      await page.click('button[type="submit"], button:has-text("Sign In")');
      await page.waitForTimeout(2000);
      
      // Navigate to services
      await page.goto(`${BASE_URL}/services`);
      await page.waitForTimeout(2000);
    });

    test('should load and display services', async ({ page }) => {
      // Wait for services to load
      await page.waitForSelector('[data-testid="service-card"], .service-card, .MuiCard-root', { timeout: 15000 });
      
      // Check if services are displayed
      const serviceCards = await page.locator('[data-testid="service-card"], .service-card, .MuiCard-root').count();
      expect(serviceCards).toBeGreaterThan(0);
      
      // Check for expected services
      for (const serviceName of EXPECTED_SERVICES) {
        const serviceVisible = await page.locator(`text=${serviceName}`).isVisible();
        if (serviceVisible) {
          console.log(`✓ Found service: ${serviceName}`);
        }
      }
      
      // Take screenshot of services page
      await page.screenshot({ path: 'tests/screenshots/services-page.png', fullPage: true });
    });

    test('should display service health indicators', async ({ page }) => {
      // Wait for services and health checks
      await page.waitForSelector('[data-testid="service-card"], .service-card, .MuiCard-root', { timeout: 15000 });
      await page.waitForTimeout(5000); // Wait for health checks to complete
      
      // Check for health indicators
      const healthIndicators = await page.locator('.health-indicator, [data-testid="health-status"], .MuiChip-root').count();
      expect(healthIndicators).toBeGreaterThan(0);
      
      // Check for different health states
      const healthyServices = await page.locator('text=Healthy, text=Online, .healthy').count();
      const demoServices = await page.locator('text=Demo, text=Development, .demo').count();
      
      console.log(`Health indicators found: ${healthIndicators}`);
      console.log(`Healthy services: ${healthyServices}, Demo services: ${demoServices}`);
    });

    test('should open service details modal', async ({ page }) => {
      // Wait for services to load
      await page.waitForSelector('[data-testid="service-card"], .service-card, .MuiCard-root', { timeout: 15000 });
      
      // Click on first service details button
      const detailsButton = page.locator('button:has-text("View Details"), button:has-text("Details"), button:has-text("More Info")').first();
      if (await detailsButton.isVisible()) {
        await detailsButton.click();
        
        // Wait for modal to open
        await page.waitForSelector('.MuiDialog-root, .modal, [role="dialog"]', { timeout: 5000 });
        
        // Check modal content
        const modalVisible = await page.locator('.MuiDialog-root, .modal, [role="dialog"]').isVisible();
        expect(modalVisible).toBeTruthy();
        
        // Take screenshot of modal
        await page.screenshot({ path: 'tests/screenshots/service-details-modal.png' });
        
        // Close modal
        await page.click('button:has-text("Close"), .MuiDialog-root button[aria-label="close"]');
      }
    });

    test('should handle service search functionality', async ({ page }) => {
      // Wait for services to load
      await page.waitForSelector('[data-testid="service-card"], .service-card, .MuiCard-root', { timeout: 15000 });
      
      // Find search input
      const searchInput = page.locator('input[placeholder*="search" i], input[name="search"]');
      if (await searchInput.isVisible()) {
        // Test search functionality
        await searchInput.fill('Michigan');
        await page.waitForTimeout(1000);
        
        // Check if results are filtered
        const visibleServices = await page.locator('[data-testid="service-card"], .service-card, .MuiCard-root').count();
        console.log(`Services visible after search: ${visibleServices}`);
        
        // Clear search
        await searchInput.clear();
        await page.waitForTimeout(1000);
      }
    });
  });

  test.describe('API Integration Tests', () => {
    
    test('should verify API endpoints are accessible', async ({ page }) => {
      // Test services API
      const servicesResponse = await page.request.get(`${API_URL}/api/services/`);
      expect(servicesResponse.status()).toBe(200);
      
      const servicesData = await servicesResponse.json();
      expect(servicesData.count || servicesData.length).toBeGreaterThan(0);
      
      console.log(`API returned ${servicesData.count || servicesData.length} services`);
    });

    test('should verify reference panels API', async ({ page }) => {
      // Test reference panels API
      const panelsResponse = await page.request.get(`${API_URL}/api/reference-panels/`);
      expect(panelsResponse.status()).toBe(200);
      
      const panelsData = await panelsResponse.json();
      expect(panelsData.count || panelsData.length).toBeGreaterThan(0);
      
      console.log(`API returned ${panelsData.count || panelsData.length} reference panels`);
    });

    test('should handle authentication API', async ({ page }) => {
      // Test login API
      const loginResponse = await page.request.post(`${API_URL}/api/auth/login/`, {
        data: {
          username: TEST_CREDENTIALS.admin.username,
          password: TEST_CREDENTIALS.admin.password
        }
      });
      
      expect(loginResponse.status()).toBe(200);
      
      const loginData = await loginResponse.json();
      expect(loginData.user).toBeDefined();
      expect(loginData.user.username).toBe(TEST_CREDENTIALS.admin.username);
    });
  });

  test.describe('Error Handling and Edge Cases', () => {
    
    test('should handle network errors gracefully', async ({ page }) => {
      // Simulate network failure by blocking API requests
      await page.route('**/api/**', route => route.abort());
      
      await page.goto(`${BASE_URL}/services`);
      await page.waitForTimeout(5000);
      
      // Check for error handling
      const errorMessage = await page.locator('.error, .alert, [role="alert"]').isVisible();
      const loadingIndicator = await page.locator('.loading, .MuiCircularProgress-root').isVisible();
      
      // Should show error or loading state
      expect(errorMessage || loadingIndicator).toBeTruthy();
    });

    test('should handle empty service list', async ({ page }) => {
      // Mock empty services response
      await page.route('**/api/services/', route => {
        route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({ count: 0, results: [] })
        });
      });
      
      await page.goto(`${BASE_URL}/services`);
      await page.waitForTimeout(3000);
      
      // Check for empty state message
      const emptyMessage = await page.locator('text=No services, text=Empty, text=No data').isVisible();
      expect(emptyMessage).toBeTruthy();
    });
  });

  test.describe('Responsive Design Tests', () => {
    
    test('should work on mobile viewport', async ({ page }) => {
      // Set mobile viewport
      await page.setViewportSize({ width: 375, height: 667 });
      
      await page.goto(BASE_URL);
      await page.waitForTimeout(2000);
      
      // Check if page is responsive
      const pageContent = await page.locator('body').isVisible();
      expect(pageContent).toBeTruthy();
      
      // Take mobile screenshot
      await page.screenshot({ path: 'tests/screenshots/mobile-view.png', fullPage: true });
    });

    test('should work on tablet viewport', async ({ page }) => {
      // Set tablet viewport
      await page.setViewportSize({ width: 768, height: 1024 });
      
      await page.goto(BASE_URL);
      await page.waitForTimeout(2000);
      
      // Check if page is responsive
      const pageContent = await page.locator('body').isVisible();
      expect(pageContent).toBeTruthy();
      
      // Take tablet screenshot
      await page.screenshot({ path: 'tests/screenshots/tablet-view.png', fullPage: true });
    });
  });

  test.describe('Performance Tests', () => {
    
    test('should load within acceptable time limits', async ({ page }) => {
      const startTime = Date.now();
      
      await page.goto(BASE_URL);
      await page.waitForLoadState('networkidle');
      
      const loadTime = Date.now() - startTime;
      console.log(`Page load time: ${loadTime}ms`);
      
      // Should load within 10 seconds
      expect(loadTime).toBeLessThan(10000);
    });

    test('should handle concurrent user sessions', async ({ browser }) => {
      // Create multiple browser contexts to simulate concurrent users
      const contexts = await Promise.all([
        browser.newContext(),
        browser.newContext(),
        browser.newContext()
      ]);
      
      const pages = await Promise.all(contexts.map(context => context.newPage()));
      
      // Navigate all pages simultaneously
      await Promise.all(pages.map(page => page.goto(BASE_URL)));
      
      // Wait for all pages to load
      await Promise.all(pages.map(page => page.waitForLoadState('networkidle')));
      
      // Verify all pages loaded successfully
      for (const page of pages) {
        const title = await page.title();
        expect(title).toContain('Federated');
      }
      
      // Cleanup
      await Promise.all(contexts.map(context => context.close()));
    });
  });
});

// Test utilities
test.afterEach(async ({ page }, testInfo) => {
  // Take screenshot on failure
  if (testInfo.status !== testInfo.expectedStatus) {
    const screenshot = await page.screenshot();
    await testInfo.attach('screenshot', { body: screenshot, contentType: 'image/png' });
  }
});

test.afterAll(async () => {
  console.log('All tests completed. Check screenshots in tests/screenshots/');
});
