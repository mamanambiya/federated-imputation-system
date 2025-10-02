# End-to-End Testing Guide
## Playwright E2E Testing for Federated Genomic Imputation Platform

**Version**: 1.0.0
**Last Updated**: September 30, 2025
**Testing Framework**: Playwright

---

## Table of Contents

1. [Overview](#overview)
2. [Test Architecture](#test-architecture)
3. [Setup Instructions](#setup-instructions)
4. [Writing Tests](#writing-tests)
5. [Running Tests](#running-tests)
6. [CI/CD Integration](#cicd-integration)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Overview

### What is E2E Testing?

End-to-End (E2E) testing validates complete user workflows from start to finish, simulating real user interactions with the application. Unlike unit tests that test individual components in isolation, E2E tests verify that all parts of the system work together correctly.

### Why Playwright?

Playwright is a modern E2E testing framework that offers:
- **Cross-browser testing**: Chromium, Firefox, WebKit (Safari)
- **Mobile device emulation**: Test responsive designs
- **Auto-waiting**: Automatically waits for elements to be ready
- **Parallel execution**: Fast test runs
- **Rich debugging**: Screenshots, videos, traces
- **TypeScript support**: Full type safety

### Test Coverage

Our E2E test suite covers:

| Test Suite | Tests | Coverage |
|------------|-------|----------|
| **Authentication** | 7 tests | Login, logout, session, protected routes |
| **Job Workflow** | 10 tests | Submit, list, filter, search, cancel |
| **Dashboard** | 12 tests | Statistics, navigation, responsive design |
| **Total** | **29 E2E tests** | Complete critical user paths |

---

## Test Architecture

### Project Structure

```
frontend/
├── e2e/                        # E2E test directory
│   ├── auth.spec.ts            # Authentication tests
│   ├── job-workflow.spec.ts    # Job management tests
│   ├── dashboard.spec.ts       # Dashboard tests
│   └── helpers/                # Test utilities (future)
├── playwright.config.ts        # Playwright configuration
├── playwright-report/          # Test reports (generated)
└── test-results/               # Videos & screenshots (generated)
```

### Test Organization

Tests are organized by **user journey** rather than by page:

- **auth.spec.ts**: Complete authentication flow
- **job-workflow.spec.ts**: Job submission → viewing → management
- **dashboard.spec.ts**: Dashboard interaction and data display

Each test file contains:
1. **Helper functions**: Reusable functions like `login()`
2. **describe blocks**: Group related tests
3. **beforeEach hooks**: Setup before each test
4. **Test cases**: Individual test scenarios

---

## Setup Instructions

### Prerequisites

- Node.js 18+ installed
- Frontend dependencies installed (`npm install`)
- Backend server accessible

### Initial Setup

1. **Install Playwright**:
   ```bash
   cd frontend
   npm install -D @playwright/test
   ```

2. **Install browsers**:
   ```bash
   npm run playwright:install
   ```
   This installs Chromium, Firefox, and WebKit browsers.

3. **Verify installation**:
   ```bash
   npx playwright --version
   ```

### Configuration

The `playwright.config.ts` file contains all configuration:

```typescript
export default defineConfig({
  testDir: './e2e',              // Test directory
  timeout: 30 * 1000,            // 30 second timeout per test
  fullyParallel: true,           // Run tests in parallel
  retries: process.env.CI ? 2 : 0,  // Retry on CI failures

  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'on-first-retry',
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],

  webServer: {
    command: 'npm start',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

---

## Writing Tests

### Test Structure

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature Name', () => {
  // Setup before each test
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  // Individual test case
  test('should do something', async ({ page }) => {
    // Arrange: Set up test data
    await login(page);

    // Act: Perform actions
    await page.getByRole('button', { name: /click me/i }).click();

    // Assert: Verify results
    await expect(page.locator('text=Success')).toBeVisible();
  });
});
```

### Helper Functions

Reusable functions reduce duplication:

```typescript
// Helper: Login to application
async function login(page) {
  await page.goto('/login');
  await page.getByLabel(/username/i).fill('test_user');
  await page.getByLabel(/password/i).fill('test_password');
  await page.getByRole('button', { name: /login/i }).click();
  await expect(page).toHaveURL(/dashboard/i);
}

// Usage in tests
test('user can view jobs', async ({ page }) => {
  await login(page);  // Reuse login logic
  await page.goto('/jobs');
  // ... rest of test
});
```

### Selectors

Playwright supports multiple selector strategies:

```typescript
// 1. By role (preferred - accessible)
await page.getByRole('button', { name: /submit/i });

// 2. By label (forms)
await page.getByLabel(/email/i);

// 3. By text
await page.getByText('Welcome back');

// 4. By test ID
await page.locator('[data-testid="job-card"]');

// 5. By CSS selector (last resort)
await page.locator('.MuiButton-root');
```

**Priority**: Use role-based and label-based selectors first (most resilient to UI changes).

### Assertions

Common assertion patterns:

```typescript
// Visibility
await expect(page.getByText('Success')).toBeVisible();
await expect(page.getByText('Error')).not.toBeVisible();

// URL
await expect(page).toHaveURL(/dashboard/i);

// Content
await expect(page.locator('h1')).toContainText(/dashboard/i);

// Count
expect(await page.locator('.job-card').count()).toBeGreaterThan(0);

// Attribute
await expect(page.getByLabel('Email')).toHaveAttribute('type', 'email');
```

### Waiting Strategies

Playwright auto-waits, but sometimes you need manual control:

```typescript
// Wait for navigation
await page.goto('/dashboard');

// Wait for element
await page.waitForSelector('[data-testid="job-list"]');

// Wait for timeout (avoid if possible)
await page.waitForTimeout(1000);

// Wait for network idle
await page.goto('/dashboard', { waitUntil: 'networkidle' });

// Wait for function
await page.waitForFunction(() => document.querySelector('.loading') === null);
```

### Error Handling

Tests should handle expected errors gracefully:

```typescript
test('handles API errors', async ({ page }) => {
  // Simulate offline
  await page.context().setOffline(true);

  await page.goto('/dashboard');

  // Should show error message
  await expect(page.locator('text=/error|offline/i')).toBeVisible({
    timeout: 10000
  });

  // Restore online
  await page.context().setOffline(false);
});
```

---

## Running Tests

### Local Development

```bash
cd frontend

# Run all tests (headless)
npm run test:e2e

# Run with UI (interactive)
npm run test:e2e:ui

# Run in headed mode (see browser)
npm run test:e2e:headed

# Run specific browser
npm run test:e2e:chromium

# Run specific test file
npx playwright test e2e/auth.spec.ts

# Run tests matching pattern
npx playwright test -g "login"
```

### Debugging

```bash
# Debug specific test
npx playwright test e2e/auth.spec.ts --debug

# Run with trace viewer
npx playwright test --trace on

# View last run's trace
npx playwright show-trace trace.zip
```

### Test Reports

After running tests:

```bash
# View HTML report
npm run test:report

# Opens browser with detailed test report including:
# - Test results
# - Screenshots
# - Videos (on failure)
# - Traces
```

### CI/CD Execution

In CI (GitHub Actions), tests run automatically:

```yaml
- name: Run E2E tests
  run: npm run test:e2e:chromium
```

CI configuration:
- Runs only Chromium (faster)
- Retries failed tests twice
- Uploads artifacts on failure
- Saves videos for debugging

---

## CI/CD Integration

### GitHub Actions Workflow

The `.github/workflows/ci.yml` includes E2E testing:

```yaml
frontend-e2e-tests:
  runs-on: ubuntu-latest

  services:
    postgres:
      image: postgres:14
    redis:
      image: redis:7

  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4

    - name: Install dependencies
      run: npm ci

    - name: Install Playwright browsers
      run: npx playwright install --with-deps chromium

    - name: Start backend
      run: python manage.py runserver &

    - name: Run E2E tests
      run: npm run test:e2e:chromium

    - name: Upload reports
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: playwright-report
        path: frontend/playwright-report/
```

### Test Artifacts

On test failure, CI automatically uploads:
- **HTML reports**: Full test results
- **Screenshots**: Visual evidence of failures
- **Videos**: Recording of failed test runs
- **Traces**: Complete browser interaction log

Access artifacts in GitHub Actions:
1. Go to Actions tab
2. Select failed workflow run
3. Download artifacts at bottom of page

---

## Best Practices

### 1. Write User-Centric Tests

```typescript
// ❌ Bad: Testing implementation details
test('clicks submit button', async ({ page }) => {
  await page.locator('.submit-btn').click();
});

// ✅ Good: Testing user behavior
test('user can submit a job', async ({ page }) => {
  await page.goto('/jobs/new');
  await page.getByLabel('Job Name').fill('My Job');
  await page.getByRole('button', { name: /submit/i }).click();
  await expect(page.getByText('Job submitted')).toBeVisible();
});
```

### 2. Use Descriptive Test Names

```typescript
// ❌ Bad
test('test1', async ({ page }) => { ... });

// ✅ Good
test('should display validation error when submitting empty job form', async ({ page }) => { ... });
```

### 3. Keep Tests Independent

Each test should:
- Set up its own data
- Clean up after itself
- Not depend on other tests
- Be runnable in any order

```typescript
test.describe('Jobs', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);  // Fresh login each test
  });

  test('test 1', async ({ page }) => {
    // Independent test
  });

  test('test 2', async ({ page }) => {
    // Independent test
  });
});
```

### 4. Use Page Object Pattern (for complex tests)

```typescript
// pages/LoginPage.ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/login');
  }

  async login(username: string, password: string) {
    await this.page.getByLabel(/username/i).fill(username);
    await this.page.getByLabel(/password/i).fill(password);
    await this.page.getByRole('button', { name: /login/i }).click();
  }
}

// In test
import { LoginPage } from './pages/LoginPage';

test('login flow', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('test_user', 'password');
  await expect(page).toHaveURL(/dashboard/i);
});
```

### 5. Avoid Hard-Coded Waits

```typescript
// ❌ Bad
await page.waitForTimeout(5000);

// ✅ Good
await expect(page.getByText('Data loaded')).toBeVisible();
```

### 6. Test Mobile Responsiveness

```typescript
test('mobile view', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto('/dashboard');

  // Verify mobile layout
  const menu = page.getByRole('button', { name: /menu/i });
  await expect(menu).toBeVisible();
});
```

### 7. Handle Flaky Tests

```typescript
// Increase timeout for slow operations
test('slow operation', async ({ page }) => {
  test.setTimeout(60000);  // 60 seconds

  await page.goto('/large-dataset');
  await expect(page.getByText('Loaded')).toBeVisible({
    timeout: 30000  // 30 seconds
  });
});

// Retry specific tests
test('flaky test', async ({ page }) => {
  test.fixme(true, 'Known flaky test - under investigation');
  // ...
});
```

---

## Troubleshooting

### Common Issues

#### 1. Test Timeout

**Error**: `Test timeout of 30000ms exceeded`

**Solutions**:
```typescript
// Increase test timeout
test('slow test', async ({ page }) => {
  test.setTimeout(60000);
  // ...
});

// Or increase specific action timeout
await expect(element).toBeVisible({ timeout: 10000 });
```

#### 2. Element Not Found

**Error**: `Locator: ... not found`

**Solutions**:
- Check selector: `npx playwright codegen http://localhost:3000`
- Add wait: `await page.waitForSelector('.element')`
- Verify element exists in DOM inspector

#### 3. Backend Not Ready

**Error**: Tests fail because backend isn't responding

**Solutions**:
```yaml
# In CI
- name: Start backend
  run: |
    python manage.py runserver &
    sleep 10  # Wait for server to start

# Or check health endpoint
- name: Wait for backend
  run: |
    for i in {1..30}; do
      curl -f http://localhost:8000/health && break
      sleep 1
    done
```

#### 4. Authentication Issues

**Error**: Tests can't login or session expires

**Solutions**:
```typescript
// Store authenticated state
test.beforeEach(async ({ page, context }) => {
  // Login once and reuse context
  await context.addCookies([{
    name: 'sessionid',
    value: 'stored-session-token',
    domain: 'localhost',
    path: '/',
  }]);
});
```

#### 5. Screenshots/Videos Not Saved

**Check configuration**:
```typescript
use: {
  screenshot: 'only-on-failure',  // or 'on'
  video: 'retain-on-failure',     // or 'on'
}
```

---

## Test Maintenance

### Updating Tests

When UI changes:
1. Run tests to identify failures
2. Use `npx playwright codegen` to find new selectors
3. Update test selectors
4. Verify tests pass

### Adding New Tests

1. **Identify user journey**: What flow needs testing?
2. **Create test file**: Or add to existing file
3. **Write test**: Follow best practices
4. **Run locally**: Verify it works
5. **Check CI**: Ensure it passes in CI

### Monitoring Test Health

Track metrics:
- **Pass rate**: Should be >95%
- **Execution time**: Should be <10 minutes total
- **Flaky tests**: Should be <5%

---

## Advanced Topics

### API Mocking

```typescript
test('with mocked API', async ({ page }) => {
  // Intercept API calls
  await page.route('**/api/jobs', (route) => {
    route.fulfill({
      status: 200,
      body: JSON.stringify({ jobs: [] })
    });
  });

  await page.goto('/jobs');
  // Test with mocked response
});
```

### Network Conditions

```typescript
test('slow network', async ({ page, context }) => {
  // Simulate slow 3G
  await context.route('**/*', (route) => {
    setTimeout(() => route.continue(), 1000);
  });

  await page.goto('/dashboard');
  // Verify loading states
});
```

### Visual Regression Testing

```typescript
test('visual regression', async ({ page }) => {
  await page.goto('/dashboard');

  // Take screenshot
  await expect(page).toHaveScreenshot('dashboard.png', {
    maxDiffPixels: 100
  });
});
```

---

## Resources

### Documentation
- [Playwright Documentation](https://playwright.dev)
- [Best Practices](https://playwright.dev/docs/best-practices)
- [API Reference](https://playwright.dev/docs/api/class-playwright)

### Tools
- **Playwright Inspector**: `npx playwright test --debug`
- **Codegen**: `npx playwright codegen http://localhost:3000`
- **Trace Viewer**: `npx playwright show-trace`
- **Test Generator**: Records actions and generates code

### Community
- [Playwright Discord](https://discord.com/invite/playwright)
- [GitHub Discussions](https://github.com/microsoft/playwright/discussions)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/playwright)

---

## Summary

E2E testing with Playwright provides:
- ✅ **Confidence**: Complete user flows are tested
- ✅ **Coverage**: 29 tests covering critical paths
- ✅ **Speed**: Parallel execution in <10 minutes
- ✅ **Debugging**: Rich artifacts on failure
- ✅ **CI Integration**: Automated quality gates

**Next Steps**:
1. Review existing test coverage
2. Add tests for uncovered flows
3. Monitor test health metrics
4. Continuously improve test quality

---

*Document Version: 1.0.0*
*Last Updated: September 30, 2025*
