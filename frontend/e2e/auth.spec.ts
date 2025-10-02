import { test, expect } from '@playwright/test';

/**
 * Authentication Flow E2E Tests
 *
 * These tests verify the complete authentication workflow:
 * - User login
 * - Session persistence
 * - Protected route access
 * - Logout functionality
 */

test.describe('Authentication', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the application
    await page.goto('/');
  });

  test('should display login page for unauthenticated users', async ({ page }) => {
    // Verify login page elements are present
    await expect(page.locator('h1, h2')).toContainText(/login|sign in/i);
    await expect(page.getByLabel(/username|email/i)).toBeVisible();
    await expect(page.getByLabel(/password/i)).toBeVisible();
    await expect(page.getByRole('button', { name: /login|sign in/i })).toBeVisible();
  });

  test('should show validation errors for invalid credentials', async ({ page }) => {
    await page.goto('/login');

    // Try to login with empty credentials
    await page.getByRole('button', { name: /login|sign in/i }).click();

    // Should show validation errors
    await expect(page.locator('text=/required|cannot be empty/i')).toBeVisible();
  });

  test('should successfully login with valid credentials', async ({ page }) => {
    await page.goto('/login');

    // Fill in test user credentials
    await page.getByLabel(/username|email/i).fill('test_user');
    await page.getByLabel(/password/i).fill('test_password');

    // Submit login form
    await page.getByRole('button', { name: /login|sign in/i }).click();

    // Should redirect to dashboard
    await expect(page).toHaveURL(/dashboard|home/i);

    // Should show user profile or welcome message
    await expect(page.locator('text=/welcome|dashboard/i')).toBeVisible();
  });

  test('should persist session after page reload', async ({ page, context }) => {
    // Login first
    await page.goto('/login');
    await page.getByLabel(/username|email/i).fill('test_user');
    await page.getByLabel(/password/i).fill('test_password');
    await page.getByRole('button', { name: /login|sign in/i }).click();

    await expect(page).toHaveURL(/dashboard/i);

    // Reload the page
    await page.reload();

    // Should still be on dashboard (session persisted)
    await expect(page).toHaveURL(/dashboard/i);
    await expect(page.locator('text=/dashboard/i')).toBeVisible();
  });

  test('should redirect to login when accessing protected routes', async ({ page }) => {
    // Try to access protected route directly
    await page.goto('/jobs');

    // Should redirect to login
    await expect(page).toHaveURL(/login/i);
  });

  test('should successfully logout', async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.getByLabel(/username|email/i).fill('test_user');
    await page.getByLabel(/password/i).fill('test_password');
    await page.getByRole('button', { name: /login|sign in/i }).click();

    await expect(page).toHaveURL(/dashboard/i);

    // Find and click logout button
    const logoutButton = page.getByRole('button', { name: /logout|sign out/i });
    await logoutButton.click();

    // Should redirect to login page
    await expect(page).toHaveURL(/login|^\//);

    // Trying to access protected route should now redirect to login
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/login/i);
  });

  test('should handle API authentication errors gracefully', async ({ page }) => {
    await page.goto('/login');

    // Fill in invalid credentials
    await page.getByLabel(/username|email/i).fill('invalid_user');
    await page.getByLabel(/password/i).fill('wrong_password');

    // Submit login form
    await page.getByRole('button', { name: /login|sign in/i }).click();

    // Should show error message
    await expect(page.locator('text=/invalid|incorrect|failed/i')).toBeVisible({
      timeout: 5000
    });

    // Should remain on login page
    await expect(page).toHaveURL(/login/i);
  });
});
