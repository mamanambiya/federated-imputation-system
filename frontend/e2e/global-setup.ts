import { chromium, FullConfig } from '@playwright/test';
import path from 'path';

/**
 * Global Setup for Playwright Tests - API-Based Authentication
 *
 * This file runs once before all tests to establish authentication.
 * It uses direct API authentication (not UI form submission) for
 * maximum reliability and speed.
 *
 * Authentication Strategy:
 * 1. Make POST request to /api/auth/login/ to get JWT token
 * 2. Inject token into browser context's localStorage
 * 3. Verify authentication by navigating to a protected route
 * 4. Save authenticated state for reuse by all tests
 *
 * Benefits over UI login:
 * - 25x faster (~200ms vs ~5000ms)
 * - No React state/timing issues
 * - No form validation edge cases
 * - Standard Playwright best practice
 * - More maintainable (independent of login UI changes)
 */

async function globalSetup(config: FullConfig) {
  const baseURL = config.projects[0]?.use?.baseURL || 'http://localhost:3000';
  const apiURL = baseURL.replace(':3000', ':8000'); // Frontend runs on 3000, API on 8000
  const storageStatePath = path.join(__dirname, '.auth', 'user.json');

  console.log('🔐 Global Setup: Performing API-based authentication...');
  console.log(`   Frontend URL: ${baseURL}`);
  console.log(`   API URL: ${apiURL}`);

  try {
    // Step 1: Authenticate via API
    console.log('   Calling /api/auth/login/ endpoint...');

    const response = await fetch(`${apiURL}/api/auth/login/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        username: 'test_user',
        password: 'test_password'
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`API login failed: HTTP ${response.status} - ${errorText}`);
    }

    const authData = await response.json();

    if (!authData.access_token) {
      throw new Error('API login succeeded but no access_token in response');
    }

    console.log('   ✓ Authentication API call successful');
    console.log(`   ✓ JWT token received: ${authData.access_token.substring(0, 20)}...`);
    console.log(`   ✓ User: ${authData.user?.username || 'unknown'}`);

    // Step 2: Create browser context and inject token
    console.log('   Creating authenticated browser context...');

    const browser = await chromium.launch();
    const context = await browser.newContext({
      baseURL
    });

    // Inject the authentication token into localStorage
    // This runs before any page loads, ensuring the token is available
    await context.addInitScript((token) => {
      localStorage.setItem('access_token', token);
    }, authData.access_token);

    console.log('   ✓ JWT token injected into browser localStorage');

    // Step 3: Verify authentication works
    console.log('   Verifying authentication by loading protected route...');

    const page = await context.newPage();
    await page.goto('/services'); // Try to access a protected route

    // Wait for page to load
    await page.waitForLoadState('domcontentloaded', { timeout: 10000 });

    // Check if we got redirected to login (auth failed) or stayed on services (auth success)
    const finalURL = page.url();
    console.log(`   Final URL: ${finalURL}`);

    if (finalURL.includes('/login')) {
      throw new Error('Authentication verification failed: Redirected to login page');
    }

    // Double-check that token is in localStorage
    const storedToken = await page.evaluate(() => localStorage.getItem('access_token'));
    if (!storedToken) {
      throw new Error('Token not found in localStorage after injection');
    }

    console.log('   ✓ Authentication verified successfully');

    // Step 4: Save the authenticated storage state
    console.log(`   Saving auth state to: ${storageStatePath}`);
    await context.storageState({ path: storageStatePath });

    console.log('✅ Global Setup: Authentication complete!');
    console.log('   All tests will reuse this authenticated session');

    await context.close();
    await browser.close();

  } catch (error) {
    console.error('❌ Global Setup: Authentication failed!');
    console.error(error);
    throw error;
  }
}

export default globalSetup;
