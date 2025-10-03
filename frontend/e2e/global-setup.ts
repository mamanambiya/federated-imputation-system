import { chromium, FullConfig } from '@playwright/test';
import path from 'path';

/**
 * Global Setup for Playwright Tests
 *
 * This file runs once before all tests to establish authentication.
 * It logs in with test credentials and saves the authentication state
 * to a file that can be reused by all tests.
 *
 * Benefits:
 * - Login once instead of before every test (faster)
 * - Consistent authentication state across all tests
 * - Follows Playwright best practices
 */

async function globalSetup(config: FullConfig) {
  const baseURL = config.projects[0]?.use?.baseURL || 'http://localhost:3000';
  const storageStatePath = path.join(__dirname, '.auth', 'user.json');

  console.log('🔐 Global Setup: Performing authentication...');
  console.log(`   Base URL: ${baseURL}`);

  // Launch browser
  const browser = await chromium.launch();
  const context = await browser.newContext({
    baseURL
  });
  const page = await context.newPage();

  try {
    // Navigate to login page
    console.log('   Navigating to login page...');
    await page.goto('/login');

    // Wait for login form to be visible
    await page.waitForSelector('input[name="username"], input[type="text"]', { timeout: 10000 });
    await page.waitForSelector('input[name="password"], input[type="password"]', { timeout: 10000 });

    // Try to find the exact form fields
    const usernameInput = await page.locator('input[name="username"]').or(page.locator('input[type="text"]')).first();
    const passwordInput = await page.locator('input[name="password"]').or(page.locator('input[type="password"]')).first();

    // Fill in credentials
    console.log('   Filling in test credentials...');
    await usernameInput.fill('test_user');
    await passwordInput.fill('test_password');

    // Submit login form - find the submit button
    console.log('   Submitting login form...');
    const submitButton = await page.locator('button[type="submit"]').or(page.getByRole('button', { name: /sign in|login/i })).first();
    await submitButton.click();

    // Wait for navigation after login
    // The app might redirect to various places (dashboard, home, or stay on /login if failed)
    await page.waitForLoadState('networkidle', { timeout: 15000 });

    // Check what URL we're on
    const currentURL = page.url();
    console.log(`   Current URL after login: ${currentURL}`);

    // Check if there are any error messages on the page
    const errorMessage = await page.locator('text=/invalid|incorrect|failed|error/i').textContent().catch(() => null);
    if (errorMessage) {
      console.log(`   Error message found: ${errorMessage}`);
    }

    // Verify we're NOT still on login page (which would mean login failed)
    if (currentURL.includes('/login')) {
      // Take a screenshot for debugging
      await page.screenshot({ path: './e2e/.auth/login-failure.png' });
      console.log('   Screenshot saved to e2e/.auth/login-failure.png');
      throw new Error(`Login failed: Still on login page. Error: ${errorMessage || 'Unknown'}`);
    }

    console.log('   Login successful!');

    // Verify we have the auth token in localStorage
    const token = await page.evaluate(() => localStorage.getItem('access_token'));
    if (!token) {
      throw new Error('Authentication failed: No access token found in localStorage');
    }

    console.log('   ✓ JWT token verified in localStorage');

    // Save the authentication state
    console.log(`   Saving auth state to: ${storageStatePath}`);
    await context.storageState({ path: storageStatePath });

    console.log('✅ Global Setup: Authentication complete!');

  } catch (error) {
    console.error('❌ Global Setup: Authentication failed!');
    console.error(error);
    throw error;
  } finally {
    await context.close();
    await browser.close();
  }
}

export default globalSetup;
