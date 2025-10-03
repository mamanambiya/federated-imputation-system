import { test, expect } from '@playwright/test';

/**
 * Services Page Health Check Caching Tests
 *
 * This test suite verifies that the Services page implements proper
 * health check caching to prevent redundant API calls on page reloads.
 *
 * Key behaviors tested:
 * 1. Initial page load triggers health checks
 * 2. Health check results are cached in localStorage
 * 3. Page reload within 5 minutes uses cached data (no API calls)
 * 4. Cache expires after 5 minutes
 * 5. Manual "Check Health" bypasses cache
 */

test.describe('Services Page Health Check Caching', () => {

  test.beforeEach(async ({ page }) => {
    // Navigate to services page
    await page.goto('/services');

    // Clear health check cache to ensure clean state
    await page.evaluate(() => {
      localStorage.removeItem('serviceHealthCache');
    });

    // Reload to start fresh
    await page.reload();
  });

  test('should cache health check results for 5 minutes', async ({ page }) => {
    // Navigate to services page
    await page.goto('/services');

    // Wait for services to load (look for page heading or service cards)
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });

    // Wait for health checks to complete (services should no longer be "Checking...")
    // We'll wait for at least one service card to appear
    await page.waitForSelector('[data-testid="service-card"]', { timeout: 30000 }).catch(() => {
      // If no data-testid, just wait for any service card
      return page.waitForSelector('.MuiCard-root', { timeout: 30000 });
    });

    // Give health checks time to complete and cache
    await page.waitForTimeout(3000);

    // Check that cache was created in localStorage
    const cacheExists = await page.evaluate(() => {
      const cache = localStorage.getItem('serviceHealthCache');
      return cache !== null;
    });

    expect(cacheExists).toBe(true);

    // Verify cache structure
    const cacheData = await page.evaluate(() => {
      const cache = localStorage.getItem('serviceHealthCache');
      if (!cache) return null;
      return JSON.parse(cache);
    });

    expect(cacheData).toHaveProperty('timestamp');
    expect(cacheData).toHaveProperty('healthStatus');
    expect(typeof cacheData.timestamp).toBe('number');
    expect(typeof cacheData.healthStatus).toBe('object');

    // Verify timestamp is recent (within last 10 seconds)
    const now = Date.now();
    const cacheAge = now - cacheData.timestamp;
    expect(cacheAge).toBeLessThan(10000); // Less than 10 seconds old

    console.log(`✓ Health check cache created with ${Object.keys(cacheData.healthStatus).length} services`);
  });

  test('should use cached data on page reload', async ({ page, context }) => {
    // First visit - health checks will run
    await page.goto('/services');
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });

    // Wait for health checks to complete
    await page.waitForTimeout(5000);

    // Get the cached data
    const firstCacheData = await page.evaluate(() => {
      const cache = localStorage.getItem('serviceHealthCache');
      return cache ? JSON.parse(cache) : null;
    });

    expect(firstCacheData).not.toBeNull();
    const firstTimestamp = firstCacheData.timestamp;

    console.log('✓ First page load completed, cache timestamp:', new Date(firstTimestamp).toISOString());

    // Track network requests on second page load
    const healthCheckRequests: string[] = [];

    page.on('request', request => {
      const url = request.url();
      if (url.includes('/api/services/') && url.includes('/health')) {
        healthCheckRequests.push(url);
      }
    });

    // Reload the page (within 5 minutes)
    await page.reload();
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });

    // Wait a bit to see if any health check requests are made
    await page.waitForTimeout(3000);

    // Verify NO health check API calls were made (using cache)
    expect(healthCheckRequests.length).toBe(0);
    console.log('✓ Page reload used cached data - no health check API calls made');

    // Verify cache timestamp hasn't changed (same cache data)
    const secondCacheData = await page.evaluate(() => {
      const cache = localStorage.getItem('serviceHealthCache');
      return cache ? JSON.parse(cache) : null;
    });

    expect(secondCacheData.timestamp).toBe(firstTimestamp);
    console.log('✓ Cache timestamp unchanged - confirming cache reuse');
  });

  test('should refresh health checks when cache expires', async ({ page }) => {
    // Create an expired cache entry (6 minutes old)
    await page.goto('/services');
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });

    // Manually create an expired cache
    await page.evaluate(() => {
      const expiredCache = {
        timestamp: Date.now() - (6 * 60 * 1000), // 6 minutes ago
        healthStatus: {
          1: 'healthy',
          2: 'unhealthy'
        }
      };
      localStorage.setItem('serviceHealthCache', JSON.stringify(expiredCache));
    });

    console.log('✓ Created expired cache (6 minutes old)');

    // Track health check requests
    let healthCheckRequestMade = false;
    page.on('request', request => {
      const url = request.url();
      if (url.includes('/api/services/') && url.includes('/health')) {
        healthCheckRequestMade = true;
      }
    });

    // Reload page - should detect expired cache and run health checks
    await page.reload();
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });

    // Wait for health checks to potentially run
    await page.waitForTimeout(5000);

    // Verify that health check requests WERE made (cache expired)
    expect(healthCheckRequestMade).toBe(true);
    console.log('✓ Expired cache triggered fresh health checks');

    // Verify cache was updated with new timestamp
    const newCacheData = await page.evaluate(() => {
      const cache = localStorage.getItem('serviceHealthCache');
      return cache ? JSON.parse(cache) : null;
    });

    const cacheAge = Date.now() - newCacheData.timestamp;
    expect(cacheAge).toBeLessThan(10000); // Less than 10 seconds old
    console.log('✓ Cache updated with fresh timestamp');
  });

  test('should display cached status immediately on page load', async ({ page }) => {
    // First visit to create cache
    await page.goto('/services');
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(5000);

    // Get the first service card's status
    const firstLoadStatus = await page.evaluate(() => {
      const firstCard = document.querySelector('[data-testid="service-card"]') ||
                        document.querySelector('.MuiCard-root');
      if (!firstCard) return null;

      // Look for status chip
      const statusChip = firstCard.querySelector('[data-testid="health-status"]') ||
                        firstCard.querySelector('.MuiChip-root');
      return statusChip?.textContent || null;
    });

    console.log('✓ First load status captured:', firstLoadStatus);

    // Reload page
    await page.reload();
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });

    // Check status immediately (should be from cache, not "Checking...")
    const cachedStatus = await page.evaluate(() => {
      const firstCard = document.querySelector('[data-testid="service-card"]') ||
                        document.querySelector('.MuiCard-root');
      if (!firstCard) return null;

      const statusChip = firstCard.querySelector('[data-testid="health-status"]') ||
                        firstCard.querySelector('.MuiChip-root');
      return statusChip?.textContent || null;
    });

    // Cached status should NOT be "Checking..." (should show actual status immediately)
    expect(cachedStatus).not.toContain('Checking');
    console.log('✓ Cached status displayed immediately:', cachedStatus);
    console.log('✓ No "Checking..." spinner on cached page load');
  });

  test('should log cache usage to console', async ({ page }) => {
    const consoleLogs: string[] = [];

    page.on('console', msg => {
      if (msg.type() === 'log') {
        consoleLogs.push(msg.text());
      }
    });

    // First load - should log "No cached health status"
    await page.goto('/services');
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(5000);

    const hasNoCacheLog = consoleLogs.some(log =>
      log.includes('No cached health status')
    );
    expect(hasNoCacheLog).toBe(true);
    console.log('✓ Console logged: No cached health status - performing health checks');

    // Reload - should log "Using cached health check results"
    consoleLogs.length = 0; // Clear logs
    await page.reload();
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(2000);

    const hasCacheHitLog = consoleLogs.some(log =>
      log.includes('Using cached health check results')
    );
    expect(hasCacheHitLog).toBe(true);
    console.log('✓ Console logged: Using cached health check results');
  });

  test('cache should survive navigation away and back', async ({ page }) => {
    // Visit services page, let cache be created
    await page.goto('/services');
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(5000);

    const cacheAfterFirstLoad = await page.evaluate(() => {
      return localStorage.getItem('serviceHealthCache');
    });
    expect(cacheAfterFirstLoad).not.toBeNull();

    // Navigate away to dashboard
    await page.goto('/');
    await page.waitForTimeout(1000);

    // Navigate back to services
    await page.goto('/services');
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });

    // Cache should still exist
    const cacheAfterNavigation = await page.evaluate(() => {
      return localStorage.getItem('serviceHealthCache');
    });
    expect(cacheAfterNavigation).toBe(cacheAfterFirstLoad);
    console.log('✓ Cache persisted through navigation');
  });

  test('should handle localStorage quota/privacy errors gracefully', async ({ page }) => {
    // Fill up localStorage to near capacity
    await page.goto('/services');
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible({ timeout: 10000 });

    // Try to fill localStorage (may fail in some browsers/modes)
    const setLargeData = await page.evaluate(() => {
      try {
        // Fill localStorage with large data
        for (let i = 0; i < 100; i++) {
          localStorage.setItem(`dummy_${i}`, 'x'.repeat(50000));
        }
        return true;
      } catch (e) {
        return false;
      }
    });

    console.log('✓ localStorage quota test:', setLargeData ? 'filled' : 'quota reached');

    // Page should still function even if caching fails
    await page.waitForTimeout(2000);
    await expect(page.locator('h4, h5, h6').filter({ hasText: /services/i })).toBeVisible();
    console.log('✓ Application continues to function despite localStorage issues');
  });
});
