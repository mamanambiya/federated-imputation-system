# Comprehensive Manual Testing Guide
## Federated Genomic Imputation Platform

### Testing Environment
- **Frontend URL**: http://154.114.10.123:3000
- **Backend API**: http://154.114.10.123:8000
- **Test User**: admin
- **Test Password**: (see ADMIN_CREDENTIALS_FINAL.md)

---

## Pre-Testing Checklist

### 1. Environment Verification
- [ ] Docker containers running: `sudo docker ps`
- [ ] API Gateway healthy: `curl http://localhost:8000/health`
- [ ] Frontend accessible: `curl http://localhost:3000`
- [ ] Database accessible: Check postgres container
- [ ] Redis accessible: Check redis container

### 2. Services Status
```bash
# Check all microservices
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Expected services:
# - api-gateway (port 8000)
# - frontend (port 3000)
# - user-service (port 8001)
# - service-registry (port 8002)
# - job-processor (port 8003)
# - file-manager (port 8004)
# - notification (port 8005)
# - monitoring (port 8006)
# - postgres
# - redis
```

---

## Page-by-Page Testing Checklist

### 1. LOGIN PAGE (`/login`)

#### Visual Elements
- [ ] Logo displays correctly
- [ ] Login form shows username field
- [ ] Login form shows password field
- [ ] "Sign In" button visible
- [ ] "Remember me" checkbox (if present)
- [ ] Page layout responsive on different screen sizes

#### Functionality
- [ ] **Test Case 1.1**: Valid Login
  - Enter valid username: `admin`
  - Enter valid password
  - Click "Sign In"
  - **Expected**: Redirect to Dashboard
  - **Actual**: _________

- [ ] **Test Case 1.2**: Invalid Credentials
  - Enter username: `invalid_user`
  - Enter password: `wrong_password`
  - Click "Sign In"
  - **Expected**: Error message displayed
  - **Actual**: _________

- [ ] **Test Case 1.3**: Empty Fields
  - Leave fields empty
  - Click "Sign In"
  - **Expected**: Validation errors shown
  - **Actual**: _________

- [ ] **Test Case 1.4**: SQL Injection Attempt
  - Enter: `admin' OR '1'='1`
  - **Expected**: Login fails safely
  - **Actual**: _________

#### Error Handling
- [ ] Network error shows appropriate message
- [ ] Session expired redirects to login
- [ ] CORS errors don't expose sensitive info

---

### 2. DASHBOARD PAGE (`/dashboard`)

#### Visual Elements
- [ ] Page title: "Dashboard"
- [ ] Navigation sidebar visible
- [ ] User profile/avatar in top right
- [ ] Logout button accessible
- [ ] Statistics cards display:
  - [ ] Total Jobs card
  - [ ] Completed Jobs card
  - [ ] Running Jobs card
  - [ ] Success Rate card
- [ ] Charts render:
  - [ ] Job Status Distribution pie chart
  - [ ] Recent jobs list/table
- [ ] Service Information section
- [ ] Last updated timestamp shows
- [ ] Auto-refresh toggle button
- [ ] Manual refresh button

#### Functionality
- [ ] **Test Case 2.1**: Dashboard Data Loading
  - Navigate to dashboard
  - **Expected**: All stats load within 5 seconds
  - **Actual**: _________
  - **Data Validation**:
    - Total Jobs: _____
    - Completed: _____
    - Running: _____
    - Success Rate: _____%

- [ ] **Test Case 2.2**: Manual Refresh
  - Click refresh button
  - **Expected**: Data reloads, timestamp updates
  - **Actual**: _________

- [ ] **Test Case 2.3**: Auto-Refresh
  - Enable auto-refresh
  - Wait 30 seconds
  - **Expected**: Data refreshes automatically
  - **Actual**: _________

- [ ] **Test Case 2.4**: Recent Jobs List
  - Check recent jobs section
  - Click on a job (if any exist)
  - **Expected**: Navigate to job detail page
  - **Actual**: _________

- [ ] **Test Case 2.5**: Create New Job Button
  - Click "New Job" button
  - **Expected**: Navigate to job creation page
  - **Actual**: _________

- [ ] **Test Case 2.6**: Service Stats
  - Check "Available Services" count
  - Check "Accessible Services" count
  - **Expected**: Numbers match actual services
  - **Actual**: Available: _____, Accessible: _____

#### Error Handling
- [ ] API timeout shows fallback data
- [ ] Network error displays user-friendly message
- [ ] Empty state shows "No jobs" message
- [ ] Loading states show spinners/skeletons

---

### 3. SERVICES PAGE (`/services`)

#### Visual Elements
- [ ] Page title: "Imputation Services"
- [ ] Services list/grid view
- [ ] Each service card shows:
  - [ ] Service name
  - [ ] Service type
  - [ ] Description
  - [ ] Health status indicator
  - [ ] Action buttons
- [ ] "Add Service" button (if admin)
- [ ] Search/filter controls

#### Functionality
- [ ] **Test Case 3.1**: List All Services
  - Navigate to services page
  - **Expected**: All active services displayed
  - **Actual**: Services count: _____
  - Service names: _______________

- [ ] **Test Case 3.2**: Health Check
  - Click "Check Health" on a service
  - **Expected**: Health status updates
  - **Actual**: Status: _____, Response Time: ___ms

- [ ] **Test Case 3.3**: Service Details
  - Click on a service name/card
  - **Expected**: Navigate to service detail page
  - **Actual**: _________
  - **Detail Page Shows**:
    - [ ] Service information
    - [ ] Reference panels
    - [ ] Configuration details
    - [ ] Health history

- [ ] **Test Case 3.4**: Filter Services
  - Use filter/search
  - **Expected**: Results filtered correctly
  - **Actual**: _________

- [ ] **Test Case 3.5**: Sync Reference Panels
  - Click "Sync Panels" button
  - **Expected**: Sync task initiated
  - **Actual**: Task ID: _____, Status: _____

#### Admin Functionality (if applicable)
- [ ] **Test Case 3.6**: Create Service
  - Click "Add Service"
  - Fill in required fields
  - Submit
  - **Expected**: New service created
  - **Actual**: _________

- [ ] **Test Case 3.7**: Edit Service
  - Click edit on existing service
  - Modify fields
  - Save
  - **Expected**: Service updated
  - **Actual**: _________

- [ ] **Test Case 3.8**: Delete Service
  - Click delete on a service
  - Confirm deletion
  - **Expected**: Service removed
  - **Actual**: _________

---

### 4. JOBS PAGE (`/jobs`)

#### Visual Elements
- [ ] Page title: "Imputation Jobs"
- [ ] Jobs table/list with columns:
  - [ ] Job Name
  - [ ] Service
  - [ ] Status
  - [ ] Progress
  - [ ] Created Date
  - [ ] Actions
- [ ] "Create New Job" button
- [ ] Status filter dropdown
- [ ] Search box
- [ ] Pagination controls (if applicable)

#### Functionality
- [ ] **Test Case 4.1**: List User Jobs
  - Navigate to jobs page
  - **Expected**: Shows jobs for current user
  - **Actual**: Jobs count: _____

- [ ] **Test Case 4.2**: Filter by Status
  - Select "Completed" from filter
  - **Expected**: Only completed jobs shown
  - **Actual**: _________
  - Repeat for: Pending, Running, Failed

- [ ] **Test Case 4.3**: Search Jobs
  - Enter search term
  - **Expected**: Results filtered
  - **Actual**: _________

- [ ] **Test Case 4.4**: Job Details
  - Click on a job name
  - **Expected**: Navigate to job detail page
  - **Actual**: _________
  - **Detail Page Shows**:
    - [ ] Job metadata
    - [ ] Status timeline
    - [ ] Progress indicator
    - [ ] Input file info
    - [ ] Result files (if completed)
    - [ ] Error message (if failed)

- [ ] **Test Case 4.5**: Cancel Running Job
  - Find a running job
  - Click "Cancel"
  - Confirm
  - **Expected**: Job cancelled
  - **Actual**: _________

- [ ] **Test Case 4.6**: Retry Failed Job
  - Find a failed job
  - Click "Retry"
  - **Expected**: Job resubmitted
  - **Actual**: Task ID: _____

#### Job Creation
- [ ] **Test Case 4.7**: Create New Job - Valid
  - Click "Create New Job"
  - Select service
  - Select reference panel
  - Upload input file (VCF)
  - Fill in job name and parameters
  - Submit
  - **Expected**: Job created and queued
  - **Actual**: Job ID: _____, Status: _____

- [ ] **Test Case 4.8**: Create Job - Validation
  - Try creating without required fields
  - **Expected**: Validation errors shown
  - **Actual**: _________

- [ ] **Test Case 4.9**: Create Job - File Upload
  - Upload invalid file type
  - **Expected**: Error message
  - **Actual**: _________

---

### 5. RESULTS PAGE (`/results`)

#### Visual Elements
- [ ] Page title: "Results"
- [ ] Results list/table
- [ ] Download buttons
- [ ] File metadata (size, type, date)

#### Functionality
- [ ] **Test Case 5.1**: List Result Files
  - Navigate to results page
  - **Expected**: All available results shown
  - **Actual**: Files count: _____

- [ ] **Test Case 5.2**: Download File
  - Click download button
  - **Expected**: File downloads or redirect to download URL
  - **Actual**: _________
  - **File Verification**:
    - [ ] File size matches metadata
    - [ ] File is not corrupted
    - [ ] Checksum valid (if provided)

- [ ] **Test Case 5.3**: Filter Results
  - Use filters (by job, date, type)
  - **Expected**: Results filtered
  - **Actual**: _________

---

### 6. USER MANAGEMENT PAGE (`/users`) [Admin Only]

#### Visual Elements
- [ ] Page title: "User Management"
- [ ] Users table with columns:
  - [ ] Username
  - [ ] Email
  - [ ] Role
  - [ ] Status
  - [ ] Actions
- [ ] "Add User" button
- [ ] Search/filter controls

#### Functionality
- [ ] **Test Case 6.1**: List All Users
  - Navigate to user management
  - **Expected**: All users displayed
  - **Actual**: Users count: _____

- [ ] **Test Case 6.2**: Create User
  - Click "Add User"
  - Fill in details
  - Submit
  - **Expected**: New user created
  - **Actual**: User ID: _____

- [ ] **Test Case 6.3**: Edit User
  - Click edit on a user
  - Modify details
  - Save
  - **Expected**: User updated
  - **Actual**: _________

- [ ] **Test Case 6.4**: Delete/Deactivate User
  - Click delete/deactivate
  - Confirm
  - **Expected**: User removed or deactivated
  - **Actual**: _________

- [ ] **Test Case 6.5**: Assign Roles
  - Edit user
  - Change role
  - Save
  - **Expected**: Role updated
  - **Actual**: _________

- [ ] **Test Case 6.6**: Reset Password
  - Click reset password
  - Enter new password
  - Submit
  - **Expected**: Password updated
  - **Actual**: _________

---

### 7. NAVIGATION & ROUTING

#### Main Navigation
- [ ] **Test Case 7.1**: Sidebar Navigation
  - Click each menu item:
    - [ ] Dashboard → `/dashboard`
    - [ ] Services → `/services`
    - [ ] Jobs → `/jobs`
    - [ ] Results → `/results` (if exists)
    - [ ] User Management → `/users` (if admin)
  - **Expected**: Correct page loads
  - **Actual**: _________

- [ ] **Test Case 7.2**: Breadcrumbs
  - Navigate to nested pages
  - **Expected**: Breadcrumbs show correct path
  - **Actual**: _________

- [ ] **Test Case 7.3**: Back Button
  - Navigate through pages
  - Use browser back button
  - **Expected**: Previous page loads correctly
  - **Actual**: _________

- [ ] **Test Case 7.4**: Direct URL Access
  - Enter URL directly: `http://154.114.10.123:3000/services`
  - **Expected**: Page loads if authenticated
  - **Actual**: _________

- [ ] **Test Case 7.5**: Protected Routes
  - Logout
  - Try accessing `/dashboard` directly
  - **Expected**: Redirect to login
  - **Actual**: _________

#### Top Navigation
- [ ] User profile dropdown works
- [ ] Logout button works
- [ ] Notifications (if present) display

---

### 8. AUTHENTICATION & AUTHORIZATION

#### Session Management
- [ ] **Test Case 8.1**: Session Persistence
  - Login
  - Refresh page
  - **Expected**: Still logged in
  - **Actual**: _________

- [ ] **Test Case 8.2**: Session Timeout
  - Wait for session timeout (if configured)
  - Try to perform action
  - **Expected**: Redirect to login
  - **Actual**: _________

- [ ] **Test Case 8.3**: Logout
  - Click logout
  - **Expected**: Redirect to login, session cleared
  - **Actual**: _________
  - Try browser back button
  - **Expected**: Cannot access protected pages
  - **Actual**: _________

#### Role-Based Access
- [ ] **Test Case 8.4**: Admin Access
  - Login as admin
  - **Expected**: Can access all pages
  - **Actual**: _________

- [ ] **Test Case 8.5**: Regular User Access
  - Login as regular user
  - Try accessing admin pages
  - **Expected**: Access denied or hidden
  - **Actual**: _________

---

### 9. API ERROR HANDLING

#### Network Errors
- [ ] **Test Case 9.1**: API Timeout
  - Simulate slow network
  - **Expected**: Timeout message displayed
  - **Actual**: _________

- [ ] **Test Case 9.2**: API Down
  - Stop API gateway
  - Try to load dashboard
  - **Expected**: Fallback UI or error message
  - **Actual**: _________
  - Restart API gateway
  - **Expected**: App recovers automatically
  - **Actual**: _________

- [ ] **Test Case 9.3**: CORS Errors
  - Check browser console
  - **Expected**: No CORS errors
  - **Actual**: _________

#### Data Validation
- [ ] **Test Case 9.4**: Empty Responses
  - Clear database
  - Load pages
  - **Expected**: "No data" messages shown
  - **Actual**: _________

- [ ] **Test Case 9.5**: Invalid Data
  - Send malformed data to API
  - **Expected**: Validation error shown
  - **Actual**: _________

---

### 10. PERFORMANCE TESTING

#### Load Times
- [ ] **Test Case 10.1**: Initial Page Load
  - Clear cache
  - Load application
  - **Expected**: < 3 seconds
  - **Actual**: _____ seconds

- [ ] **Test Case 10.2**: Dashboard Load
  - Navigate to dashboard
  - **Expected**: < 2 seconds
  - **Actual**: _____ seconds

- [ ] **Test Case 10.3**: Large Data Sets
  - Load page with many items (100+ jobs/services)
  - **Expected**: Pagination or virtual scrolling works
  - **Actual**: _________

#### Concurrent Users
- [ ] Multiple users can login simultaneously
- [ ] Actions don't interfere with each other
- [ ] No race conditions observed

---

### 11. BROWSER COMPATIBILITY

Test on multiple browsers:
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile browsers (iOS Safari, Chrome Mobile)

For each browser:
- [ ] Login works
- [ ] Dashboard renders correctly
- [ ] Navigation works
- [ ] Forms submit correctly
- [ ] Charts/graphs display
- [ ] Console shows no errors

---

### 12. RESPONSIVE DESIGN

Test on different screen sizes:
- [ ] Desktop (1920x1080)
- [ ] Laptop (1366x768)
- [ ] Tablet (768x1024)
- [ ] Mobile (375x667)

For each size:
- [ ] Layout adapts correctly
- [ ] Navigation menu accessible
- [ ] Tables scroll or collapse
- [ ] Buttons and forms usable
- [ ] No horizontal scrolling

---

### 13. ACCESSIBILITY

#### Keyboard Navigation
- [ ] Tab through all interactive elements
- [ ] Enter key submits forms
- [ ] Escape key closes modals
- [ ] Arrow keys navigate lists/tables

#### Screen Reader
- [ ] Page titles announced
- [ ] Form labels read correctly
- [ ] Error messages announced
- [ ] Status updates announced

#### Visual
- [ ] Sufficient color contrast
- [ ] Focus indicators visible
- [ ] Text scalable to 200%
- [ ] No information conveyed by color alone

---

### 14. DATA INTEGRITY

#### CRUD Operations
- [ ] **Test Case 14.1**: Create → Read
  - Create an item
  - Verify it appears in list
  - Verify details are correct

- [ ] **Test Case 14.2**: Update
  - Update an item
  - Verify changes persist
  - Verify other fields unchanged

- [ ] **Test Case 14.3**: Delete
  - Delete an item
  - Verify it's removed from list
  - Verify it's actually deleted (not just hidden)

#### Data Consistency
- [ ] Refresh page doesn't duplicate data
- [ ] Concurrent edits don't cause conflicts
- [ ] Transactions are atomic (all or nothing)

---

### 15. SECURITY TESTING

#### Input Validation
- [ ] **Test Case 15.1**: XSS Prevention
  - Enter: `<script>alert('XSS')</script>` in form
  - **Expected**: Sanitized/escaped
  - **Actual**: _________

- [ ] **Test Case 15.2**: SQL Injection
  - Enter: `'; DROP TABLE users; --` in form
  - **Expected**: Safely handled
  - **Actual**: _________

- [ ] **Test Case 15.3**: File Upload
  - Upload executable file
  - **Expected**: Rejected
  - **Actual**: _________

#### Authentication
- [ ] Passwords not visible in network tab
- [ ] Tokens stored securely (httpOnly cookies or secure storage)
- [ ] CSRF protection active
- [ ] Session fixation prevented

---

### 16. LOGGING & MONITORING

#### Application Logs
- [ ] Check Docker logs: `sudo docker logs api-gateway`
- [ ] Check for errors
- [ ] Check for warnings
- [ ] Verify audit logs created

#### Browser Console
- [ ] No JavaScript errors
- [ ] No unhandled promise rejections
- [ ] No 404s for resources
- [ ] Appropriate log levels used

---

## CRITICAL BUGS CHECKLIST

These should be fixed before production:
- [ ] Login functionality works 100%
- [ ] No data loss on page refresh
- [ ] No CORS errors
- [ ] All navigation links work
- [ ] Forms submit correctly
- [ ] Error messages are user-friendly
- [ ] No security vulnerabilities
- [ ] Performance is acceptable
- [ ] Mobile view is usable

---

## Testing Report Template

```markdown
## Test Execution Report
Date: ___________
Tester: ___________
Environment: ___________

### Summary
- Total Test Cases: _____
- Passed: _____
- Failed: _____
- Blocked: _____
- Skipped: _____

### Critical Issues
1. [Description]
   - Severity: Critical/High/Medium/Low
   - Steps to Reproduce:
   - Expected Result:
   - Actual Result:
   - Screenshot/Logs:

### Passed Test Cases
- TC-X.X: [Description]

### Failed Test Cases
- TC-X.X: [Description]
  - Failure Reason:
  - Impact:

### Recommendations
1. [Recommendation]
```

---

## Quick Test Script (For Rapid Verification)

```bash
#!/bin/bash
# Quick smoke test

echo "1. Testing API health..."
curl -f http://localhost:8000/health || echo "❌ API Gateway down"

echo "2. Testing frontend..."
curl -f http://localhost:3000 > /dev/null && echo "✅ Frontend accessible" || echo "❌ Frontend down"

echo "3. Testing dashboard stats API..."
curl -f http://localhost:8000/api/dashboard/stats/ | grep -q "job_stats" && echo "✅ Dashboard API working" || echo "❌ Dashboard API failed"

echo "4. Testing services API..."
curl -f http://localhost:8000/api/services/ | grep -q "results" && echo "✅ Services API working" || echo "❌ Services API failed"

echo "5. Testing Docker containers..."
sudo docker ps --format "{{.Names}}: {{.Status}}" | grep -E "(api-gateway|frontend)"
```

---

## Notes for Testers

1. **Test Data**: Create dedicated test accounts and test data. Don't use production data.
2. **Documentation**: Document every bug with screenshots and steps to reproduce.
3. **Priority**: Test critical paths first (login, dashboard, job creation).
4. **Environment**: Test in an environment that matches production as closely as possible.
5. **Collaboration**: Communicate with developers immediately when blocking bugs are found.

---

## Automated Testing Recommendations

While manual testing is comprehensive, also maintain:
1. Unit tests for components
2. Integration tests for API endpoints
3. E2E tests for critical user flows
4. Performance tests for scalability
5. Security scans with tools like OWASP ZAP

---

## Sign-Off

This testing guide should be used for:
- Pre-deployment verification
- Regression testing after changes
- QA team onboarding
- Bug reproduction

**Last Updated**: 2025-10-02
**Version**: 1.0
