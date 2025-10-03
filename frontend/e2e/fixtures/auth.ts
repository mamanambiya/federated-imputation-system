import { test as base } from '@playwright/test';
import path from 'path';

/**
 * Authentication Fixture
 *
 * This fixture extends Playwright's base test to automatically provide
 * an authenticated session. Tests using this fixture will already be
 * logged in with test credentials.
 *
 * Usage:
 *   import { test, expect } from './fixtures/auth';
 *
 *   test('my authenticated test', async ({ page }) => {
 *     // page is already authenticated - no login needed!
 *     await page.goto('/services');
 *   });
 */

// Path to the stored authentication state
const authFile = path.join(__dirname, '..', '.auth', 'user.json');

/**
 * Extend base test with authentication state
 *
 * This automatically loads the saved authentication state (from global-setup.ts)
 * before each test, so tests don't need to login manually.
 */
export const test = base.extend({
  // Override the default context to use stored authentication state
  storageState: authFile,
});

// Re-export expect from Playwright for convenience
export { expect } from '@playwright/test';
