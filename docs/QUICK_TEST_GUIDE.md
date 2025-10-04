# Quick Browser Testing Guide

## ✅ Backend Verified - All Systems Operational

**Date**: October 2, 2025
**Status**: Ready for browser testing

### System Status ✅
- **API Gateway**: Healthy (port 8000)
- **Frontend**: Running (port 3000)
- **Services Available**: 6
- **All APIs**: Responding correctly

---

## 🌐 Browser Testing Steps

### Step 1: Open the Application
1. Open your browser (Chrome, Firefox, or Edge)
2. Navigate to: **`http://154.114.10.123:3000`**
3. Expected: Login page loads

### Step 2: Open Developer Tools
**Press F12** or right-click → Inspect

Check these tabs:
- **Console**: Should be mostly clean (no red errors)
- **Network**: To monitor API requests

---

## 🧪 Test Scenarios

### Test #1: Login ✓
**URL**: `http://154.114.10.123:3000/login`

**Steps**:
1. Enter username: `admin`
2. Enter password: (from `docs/ADMIN_CREDENTIALS_FINAL.md`)
3. Click "Sign In"

**Expected Results**:
- ✅ Redirects to `/dashboard`
- ✅ No console errors
- ✅ Network tab shows successful `/api/auth/login/` request (200 status)

**Actual Results**:
- Status: ___________
- Issues: ___________

---

### Test #2: Dashboard Page ✓
**URL**: `http://154.114.10.123:3000/dashboard`

**What to Check**:

#### Visual Elements
- [ ] Page title: "Dashboard"
- [ ] Four statistics cards visible:
  - [ ] Total Jobs: **0**
  - [ ] Completed: **0**
  - [ ] Running: **0**
  - [ ] Success Rate: **0.0%**
- [ ] Service stats section shows:
  - [ ] Available Services: **6**
  - [ ] Accessible Services: **6** (or similar)
- [ ] "Recent Jobs" section (should show "No recent jobs found" or empty state)
- [ ] "New Job" button visible in top right
- [ ] Refresh button visible
- [ ] Auto-refresh toggle visible

#### Functionality Tests
- [ ] Click **Refresh** button → Data reloads (timestamp updates)
- [ ] Toggle **Auto-refresh** → Notification appears
- [ ] Click **New Job** → Navigates to job creation page

#### Developer Console
```
F12 → Console Tab
Expected: No red errors (warnings in yellow are OK)
```

#### Network Tab
```
F12 → Network Tab
Look for: /api/dashboard/stats/
Status: Should be 200 OK
Preview: Should show job_stats and service_stats
```

**Actual Results**:
- Dashboard loads: ___________
- Data displays: ___________
- Console errors: ___________
- Network status: ___________

---

### Test #3: Services Page ✓
**URL**: `http://154.114.10.123:3000/services`

**Steps**:
1. Click "Services" in sidebar navigation
2. Wait for page to load

**Expected Results**:
- [ ] Page loads successfully
- [ ] Shows **6 services** (cards or list)
- [ ] Each service shows:
  - Service name
  - Service type
  - Health status indicator
  - Action buttons
- [ ] No console errors

**Service Names to Expect**:
- Michigan Imputation Server
- H3Africa services
- GA4GH services
- Others...

**Actual Results**:
- Services count: ___________
- Issues: ___________

---

### Test #4: Jobs Page ✓
**URL**: `http://154.114.10.123:3000/jobs`

**Steps**:
1. Click "Jobs" in sidebar navigation
2. Check page state

**Expected Results**:
- [ ] Page loads successfully
- [ ] Shows empty state: "No jobs yet" or similar message
- [ ] "Create New Job" or "New Job" button visible
- [ ] Filter/search controls visible
- [ ] No console errors

**Actual Results**:
- Page loads: ___________
- Empty state shown: ___________
- Issues: ___________

---

### Test #5: Navigation Testing ✓

**Test All Sidebar Links**:
- [ ] Dashboard → Loads `/dashboard`
- [ ] Services → Loads `/services`
- [ ] Jobs → Loads `/jobs`
- [ ] Results → Loads `/results` (if visible)
- [ ] User Management → Loads `/users` (if admin)
- [ ] New Job → Loads `/jobs/new`

**Test Browser Navigation**:
- [ ] Browser **Back button** → Returns to previous page
- [ ] Browser **Forward button** → Goes forward
- [ ] **Refresh (F5)** → Page reloads correctly, stays logged in

**Test Direct URL Access**:
1. Copy this URL: `http://154.114.10.123:3000/services`
2. Open new browser tab
3. Paste and go
4. Expected: Page loads (if logged in) or redirects to login

**Actual Results**:
- All links work: ___________
- Issues: ___________

---

### Test #6: Error Handling ✓

**Test 404 Page**:
1. Navigate to: `http://154.114.10.123:3000/nonexistent-page`
2. Expected: 404 page or redirect

**Test Session Timeout**:
1. Click **Logout** (if button exists)
2. Try accessing: `http://154.114.10.123:3000/dashboard`
3. Expected: Redirect to `/login`

**Actual Results**:
- 404 handling: ___________
- Logout works: ___________
- Protected routes: ___________

---

## 🐛 Common Issues & Solutions

### Issue: Dashboard Shows "Failed to load dashboard data"

**Check**:
1. Open F12 → Network tab
2. Find request to `/api/dashboard/stats/`
3. Look at the URL - should be `http://154.114.10.123:8000/api/dashboard/stats/`

**If URL is wrong (localhost instead of IP)**:
```bash
# Restart frontend container
sudo docker restart federated-imputation-central_frontend_1

# Wait 20 seconds, then refresh browser
```

---

### Issue: CORS Error in Console

**Error looks like**:
```
Access to fetch at 'http://154.114.10.123:8000/api/...'
from origin 'http://154.114.10.123:3000' has been blocked by CORS policy
```

**Solution**: API Gateway needs CORS configuration update
```bash
# Check if API gateway is running
sudo docker ps | grep api-gateway

# Restart it
sudo docker restart api-gateway
```

---

### Issue: Network Tab Shows Red (Failed) Requests

**Check Status Code**:
- **0**: No response (API is down or CORS issue)
- **401**: Not authenticated (try logging in again)
- **403**: Not authorized (permissions issue)
- **404**: Endpoint not found (URL mismatch)
- **500**: Server error (check API logs)

**View API Logs**:
```bash
sudo docker logs api-gateway --tail 50
```

---

### Issue: Blank Page or White Screen

**Check**:
1. F12 → Console tab
2. Look for JavaScript errors (red text)
3. Screenshot and note the error message

**Common Causes**:
- JavaScript error in code
- Missing dependency
- API endpoint returning unexpected data

**Try**:
1. Hard refresh: **Ctrl+Shift+R** (Windows/Linux) or **Cmd+Shift+R** (Mac)
2. Clear browser cache
3. Try incognito/private mode

---

## ✅ Success Criteria

**All Tests Pass When**:
- [ ] Login works and redirects to dashboard
- [ ] Dashboard displays statistics (even if 0)
- [ ] Services page shows 6 services
- [ ] Jobs page shows empty state
- [ ] All navigation links work
- [ ] No red errors in console (warnings OK)
- [ ] Network tab shows all requests with 200 status
- [ ] Logout works and redirects to login

---

## 📊 Testing Report Template

```
=== Browser Testing Report ===
Date: October 2, 2025
Browser: Chrome/Firefox/Edge [Circle one]
Version: _________

✅ PASSED Tests:
-

❌ FAILED Tests:
-

⚠️ WARNINGS/NOTES:
-

Console Errors (if any):
[Paste screenshot or error text]

Network Errors (if any):
[List failed requests with URLs and status codes]

Overall Status: PASS / FAIL / PARTIAL
```

---

## 🎯 Quick Smoke Test (30 seconds)

If you just want to verify the app is working:

1. **Login**: `http://154.114.10.123:3000` → Enter credentials → Should redirect to dashboard ✓
2. **Dashboard**: Should show stats (6 services, 0 jobs) ✓
3. **Services**: Click sidebar → Should show 6 services ✓
4. **Jobs**: Click sidebar → Should show empty state ✓
5. **Console**: F12 → No red errors ✓

If all 5 pass = **Application is working! ✅**

---

## 📞 Need Help?

**Check Logs**:
```bash
# Frontend logs
sudo docker logs federated-imputation-central_frontend_1 --tail 50

# API Gateway logs
sudo docker logs api-gateway --tail 50

# All containers status
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Restart Everything**:
```bash
# Restart frontend
sudo docker restart federated-imputation-central_frontend_1

# Restart API gateway
sudo docker restart api-gateway

# Wait 30 seconds, then try again
```

**Full System Status**:
```bash
# Run comprehensive check
curl -s http://localhost:8000/health | python3 -m json.tool
curl -s http://localhost:8000/api/dashboard/stats/ | python3 -m json.tool
curl -s http://localhost:3000 | grep -i "Federated"
```

---

**🎉 Happy Testing!**

For comprehensive testing: See `docs/COMPREHENSIVE_MANUAL_TESTING_GUIDE.md`
