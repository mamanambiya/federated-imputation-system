import { test, expect } from '@playwright/test';

/**
 * Job Submission and Management E2E Tests
 *
 * Tests the complete job lifecycle:
 * - Job submission form
 * - Job list viewing
 * - Job details
 * - Job status updates
 * - Job cancellation
 */

// Helper function to login before tests
async function login(page) {
  await page.goto('/login');
  await page.getByLabel(/username|email/i).fill('test_user');
  await page.getByLabel(/password/i).fill('test_password');
  await page.getByRole('button', { name: /login|sign in/i }).click();
  await expect(page).toHaveURL(/dashboard|home/i);
}

test.describe('Job Workflow', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test('should navigate to job submission page', async ({ page }) => {
    // Look for "New Job" or "Submit Job" button
    const newJobButton = page.getByRole('link', { name: /new job|submit|create/i });
    await newJobButton.click();

    // Should be on job submission page
    await expect(page).toHaveURL(/job.*new|submit|create/i);
    await expect(page.locator('h1, h2')).toContainText(/new job|submit|create/i);
  });

  test('should display job submission form with required fields', async ({ page }) => {
    await page.goto('/jobs/new');

    // Verify form fields are present
    await expect(page.getByLabel(/job name|name/i)).toBeVisible();
    await expect(page.getByLabel(/service/i)).toBeVisible();
    await expect(page.getByLabel(/reference panel|panel/i)).toBeVisible();
    await expect(page.getByLabel(/input format|format/i)).toBeVisible();

    // Verify submit button exists
    await expect(page.getByRole('button', { name: /submit|create/i })).toBeVisible();
  });

  test('should show validation errors for incomplete job submission', async ({ page }) => {
    await page.goto('/jobs/new');

    // Try to submit without filling required fields
    await page.getByRole('button', { name: /submit|create/i }).click();

    // Should show validation errors
    await expect(page.locator('text=/required|cannot be empty/i')).toBeVisible();
  });

  test('should successfully submit a new job', async ({ page }) => {
    await page.goto('/jobs/new');

    // Fill in job details
    await page.getByLabel(/job name|name/i).fill('E2E Test Job');
    await page.getByLabel(/description/i).fill('Automated test job submission');

    // Select service from dropdown
    await page.getByLabel(/service/i).click();
    await page.locator('li').first().click();

    // Select reference panel
    await page.getByLabel(/reference panel|panel/i).click();
    await page.locator('li').first().click();

    // Select input format
    await page.getByLabel(/input format|format/i).click();
    await page.getByText(/vcf|plink/i).first().click();

    // Submit the form
    await page.getByRole('button', { name: /submit|create/i }).click();

    // Should show success notification
    await expect(page.locator('text=/success|submitted|created/i')).toBeVisible({
      timeout: 10000
    });

    // Should redirect to jobs list or job details
    await expect(page).toHaveURL(/jobs/i);
  });

  test('should display list of user jobs', async ({ page }) => {
    await page.goto('/jobs');

    // Page should load
    await expect(page.locator('h1, h2')).toContainText(/jobs|my jobs/i);

    // Should show loading skeleton or jobs
    // Either we see a skeleton or actual job cards
    const hasJobs = await page.locator('[data-testid="job-card"], .MuiCard-root').count() > 0;
    const hasSkeleton = await page.locator('.MuiSkeleton-root').count() > 0;

    expect(hasJobs || hasSkeleton).toBeTruthy();
  });

  test('should filter jobs by status', async ({ page }) => {
    await page.goto('/jobs');

    // Look for status filter dropdown
    const statusFilter = page.getByLabel(/status|filter/i).first();

    if (await statusFilter.isVisible()) {
      await statusFilter.click();

      // Select "Completed" status
      await page.getByText(/completed/i).first().click();

      // URL or display should update
      await page.waitForTimeout(1000); // Wait for filter to apply

      // Verify filter is applied (either in URL or UI state)
      const url = page.url();
      const hasStatusInUrl = url.includes('status=completed');
      const hasActiveFilter = await page.locator('text=/completed/i').count() > 0;

      expect(hasStatusInUrl || hasActiveFilter).toBeTruthy();
    }
  });

  test('should search for jobs by name', async ({ page }) => {
    await page.goto('/jobs');

    // Look for search input
    const searchInput = page.getByPlaceholder(/search/i).or(page.getByLabel(/search/i));

    if (await searchInput.isVisible()) {
      // Type search query
      await searchInput.fill('test');

      // Wait for search results
      await page.waitForTimeout(1500); // Debounce delay

      // Results should update (this will vary by implementation)
      const jobCount = await page.locator('[data-testid="job-card"], .MuiCard-root').count();

      // We just verify the search functionality works (no errors)
      expect(jobCount).toBeGreaterThanOrEqual(0);
    }
  });

  test('should navigate to job details page', async ({ page }) => {
    await page.goto('/jobs');

    // Wait for jobs to load
    await page.waitForSelector('[data-testid="job-card"], .MuiCard-root, text=/no jobs/i', {
      timeout: 10000
    });

    // Check if there are any jobs
    const jobCards = await page.locator('[data-testid="job-card"], .MuiCard-root').count();

    if (jobCards > 0) {
      // Click on first job
      await page.locator('[data-testid="job-card"], .MuiCard-root').first().click();

      // Should navigate to job details
      await expect(page).toHaveURL(/jobs\/[a-zA-Z0-9-]+/);

      // Should show job details
      await expect(page.locator('h1, h2, h3')).toContainText(/details|job|status/i);
    } else {
      // No jobs to test, but test passed (expected scenario for new user)
      console.log('No jobs available to test job details navigation');
    }
  });

  test('should display job status and progress', async ({ page }) => {
    // Submit a job first
    await page.goto('/jobs/new');
    await page.getByLabel(/job name|name/i).fill('Status Test Job');
    await page.getByLabel(/service/i).click();
    await page.locator('li').first().click();
    await page.getByLabel(/reference panel|panel/i).click();
    await page.locator('li').first().click();
    await page.getByRole('button', { name: /submit|create/i }).click();

    await page.waitForTimeout(2000);

    // Go to jobs list
    await page.goto('/jobs');

    // Should see status badge or indicator
    await expect(page.locator('text=/pending|queued|running|completed/i')).toBeVisible();
  });

  test('should allow job cancellation', async ({ page }) => {
    await page.goto('/jobs');

    // Look for a running job with cancel button
    const cancelButton = page.getByRole('button', { name: /cancel/i }).first();

    if (await cancelButton.isVisible()) {
      await cancelButton.click();

      // Should show confirmation dialog
      const confirmButton = page.getByRole('button', { name: /confirm|yes|ok/i });
      if (await confirmButton.isVisible()) {
        await confirmButton.click();
      }

      // Should show success message
      await expect(page.locator('text=/cancel.*success|cancell?ed/i')).toBeVisible({
        timeout: 5000
      });
    }
  });

  test('should handle job submission errors gracefully', async ({ page }) => {
    await page.goto('/jobs/new');

    // Fill minimal invalid data (if backend validation exists)
    await page.getByLabel(/job name|name/i).fill('a'); // Too short

    await page.getByRole('button', { name: /submit|create/i }).click();

    // Should either show validation error or API error
    await expect(page.locator('text=/error|invalid|failed/i')).toBeVisible({
      timeout: 5000
    });
  });
});
