import { test, expect } from '@playwright/test';

// Skip global authentication for this test (job details page is public)
test.use({ storageState: undefined });

test.describe('Job Details - API Request & Response Accordion', () => {
  test('should display API Request & Response Details accordion for failed job', async ({ page }) => {
    // Navigate to a specific failed job
    // Using the job ID from the screenshot: 10836cd4-b076-44b9-b23b-dcb084175411
    const jobId = '10836cd4-b076-44b9-b23b-dcb084175411';

    console.log(`Navigating to job details page for job: ${jobId}`);
    await page.goto(`http://localhost:3000/jobs/${jobId}`);

    // Wait for page to load
    await page.waitForLoadState('networkidle');

    // Click on the Logs tab
    console.log('Clicking on Logs tab');
    await page.click('button:has-text("LOGS")');

    // Wait a moment for tab content to render
    await page.waitForTimeout(1000);

    // Take a screenshot before checking for accordion
    await page.screenshot({ path: 'test-results/job-details-before-accordion-check.png', fullPage: true });

    // Check if the accordion header is visible
    console.log('Checking for accordion header: "API Request & Response Details"');
    const accordionHeader = page.locator('text=API Request & Response Details');

    // Wait for the accordion to be visible (with timeout)
    try {
      await accordionHeader.waitFor({ state: 'visible', timeout: 5000 });
      console.log('✓ Accordion header found!');

      // Click to expand the accordion
      await accordionHeader.click();
      await page.waitForTimeout(500);

      // Check for the content inside the accordion
      const rawApiRequest = page.locator('text=Raw API Request');
      const rawApiResponse = page.locator('text=Raw API Response');

      await expect(rawApiRequest).toBeVisible();
      await expect(rawApiResponse).toBeVisible();

      console.log('✓ Accordion content verified!');

      // Take a screenshot of the expanded accordion
      await page.screenshot({ path: 'test-results/job-details-accordion-expanded.png', fullPage: true });

    } catch (error) {
      console.error('✗ Accordion header NOT found!');
      console.error('Error:', error);

      // Take a screenshot of the failure
      await page.screenshot({ path: 'test-results/job-details-accordion-FAILED.png', fullPage: true });

      // Log the page HTML for debugging
      const html = await page.content();
      console.log('Page HTML length:', html.length);
      console.log('Contains "API Request":', html.includes('API Request'));
      console.log('Contains "main.2d0bc623.js":', html.includes('main.2d0bc623.js'));

      throw error;
    }
  });

  test('should show correct job status in the accordion', async ({ page }) => {
    const jobId = '10836cd4-b076-44b9-b23b-dcb084175411';

    await page.goto(`http://localhost:3000/jobs/${jobId}`);
    await page.waitForLoadState('networkidle');
    await page.click('button:has-text("LOGS")');
    await page.waitForTimeout(1000);

    // Expand accordion
    const accordionHeader = page.locator('text=API Request & Response Details');
    await accordionHeader.click();
    await page.waitForTimeout(500);

    // Check for error message in the accordion
    const errorAlert = page.locator('text=Submission Error');
    await expect(errorAlert).toBeVisible();

    // Check for the specific error message
    const errorMessage = page.locator('text=/No credentials configured/i');
    await expect(errorMessage).toBeVisible();

    console.log('✓ Error message displayed correctly in accordion');
  });
});
