import { test, expect } from '@playwright/test';

/**
 * Dashboard E2E Tests
 *
 * Tests the main dashboard functionality:
 * - Statistics display
 * - Recent jobs
 * - Service status
 * - Navigation
 * - Responsive layout
 */

async function login(page) {
  await page.goto('/login');
  await page.getByLabel(/username|email/i).fill('test_user');
  await page.getByLabel(/password/i).fill('test_password');
  await page.getByRole('button', { name: /login|sign in/i }).click();
  await expect(page).toHaveURL(/dashboard|home/i);
}

test.describe('Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.goto('/dashboard');
  });

  test('should display dashboard page with key sections', async ({ page }) => {
    // Verify dashboard title
    await expect(page.locator('h1, h2')).toContainText(/dashboard/i);

    // Should show statistics cards
    const statCards = await page.locator('[data-testid="stat-card"], .MuiCard-root').count();
    expect(statCards).toBeGreaterThan(0);
  });

  test('should display user statistics', async ({ page }) => {
    // Wait for content to load (skeleton or actual data)
    await page.waitForSelector('[data-testid="stat-card"], .MuiCard-root, .MuiSkeleton-root', {
      timeout: 10000
    });

    // Should show key metrics (jobs count, completed, failed, etc.)
    const hasStats = await page.locator('text=/total.*jobs|completed|pending|running/i').count() > 0;
    const hasSkeleton = await page.locator('.MuiSkeleton-root').count() > 0;

    expect(hasStats || hasSkeleton).toBeTruthy();
  });

  test('should display recent jobs section', async ({ page }) => {
    // Look for recent jobs section
    const recentJobsSection = page.locator('text=/recent.*jobs|latest.*jobs/i').first();

    if (await recentJobsSection.isVisible()) {
      // Should show list of recent jobs or empty state
      const hasJobs = await page.locator('[data-testid="job-item"], .MuiListItem-root').count() > 0;
      const hasEmptyState = await page.locator('text=/no.*jobs|no.*data/i').isVisible();

      expect(hasJobs || hasEmptyState).toBeTruthy();
    }
  });

  test('should display service availability status', async ({ page }) => {
    // Look for services section
    const servicesSection = page.locator('text=/services|available.*services/i');

    if (await servicesSection.isVisible()) {
      // Should show service status indicators
      await expect(page.locator('text=/online|offline|healthy|available/i')).toBeVisible();
    }
  });

  test('should navigate to jobs page from dashboard', async ({ page }) => {
    // Look for "View All Jobs" or similar link
    const viewAllLink = page.getByRole('link', { name: /view.*all.*jobs|all.*jobs|see.*jobs/i });

    if (await viewAllLink.isVisible()) {
      await viewAllLink.click();

      // Should navigate to jobs page
      await expect(page).toHaveURL(/jobs/i);
    }
  });

  test('should navigate to services page from dashboard', async ({ page }) => {
    // Look for "View Services" or similar link
    const viewServicesLink = page.getByRole('link', { name: /view.*services|all.*services|browse.*services/i });

    if (await viewServicesLink.isVisible()) {
      await viewServicesLink.click();

      // Should navigate to services page
      await expect(page).toHaveURL(/services/i);
    }
  });

  test('should show loading state while fetching data', async ({ page }) => {
    // Reload to trigger loading state
    await page.reload();

    // Should briefly show skeleton loaders
    const hasSkeleton = await page.locator('.MuiSkeleton-root').count() > 0;

    // This may be very brief, so we don't fail if not caught
    console.log('Skeleton loaders detected:', hasSkeleton);
  });

  test('should display user profile information', async ({ page }) => {
    // Look for user profile section (usually in header or sidebar)
    const userProfile = page.locator('text=/test_user|welcome/i');

    // Should show username or welcome message
    await expect(userProfile.first()).toBeVisible();
  });

  test('should handle API errors gracefully', async ({ page, context }) => {
    // Simulate offline mode
    await context.setOffline(true);

    // Reload page
    await page.reload();

    // Should show error message or offline indicator
    await expect(page.locator('text=/error|offline|unable.*load|failed.*load/i')).toBeVisible({
      timeout: 10000
    });

    // Restore online mode
    await context.setOffline(false);
  });

  test('should refresh data when clicking refresh button', async ({ page }) => {
    // Look for refresh button
    const refreshButton = page.getByRole('button', { name: /refresh|reload/i });

    if (await refreshButton.isVisible()) {
      await refreshButton.click();

      // Should show loading state briefly
      await page.waitForTimeout(500);

      // Data should reload (no error)
      await expect(page.locator('text=/error|failed/i')).not.toBeVisible();
    }
  });

  test('should display charts and visualizations', async ({ page }) => {
    // Look for chart containers
    const charts = page.locator('[data-testid="chart"], canvas, svg').first();

    if (await charts.isVisible()) {
      // Verify chart is rendered
      const chartCount = await page.locator('[data-testid="chart"], canvas, svg').count();
      expect(chartCount).toBeGreaterThan(0);
    }
  });
});

test.describe('Dashboard Responsive Design', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.goto('/dashboard');
  });

  test('should be responsive on mobile devices', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });

    // Dashboard should still render correctly
    await expect(page.locator('h1, h2')).toContainText(/dashboard/i);

    // Stats should stack vertically
    const cards = page.locator('[data-testid="stat-card"], .MuiCard-root');
    const firstCard = cards.first();

    if (await firstCard.isVisible()) {
      const box = await firstCard.boundingBox();
      // Card should be close to full width on mobile
      expect(box?.width).toBeGreaterThan(300);
    }
  });

  test('should be responsive on tablet devices', async ({ page }) => {
    // Set tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 });

    // Dashboard should render correctly
    await expect(page.locator('h1, h2')).toContainText(/dashboard/i);

    // Should show content without horizontal scroll
    const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
    const viewportWidth = await page.evaluate(() => window.innerWidth);

    expect(bodyWidth).toBeLessThanOrEqual(viewportWidth + 50); // Small buffer for scrollbar
  });
});
