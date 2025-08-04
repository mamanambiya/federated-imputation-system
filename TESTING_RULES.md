# Testing Rules and Guidelines
## Federated Genomic Imputation Platform

### 🎯 **MANDATORY TESTING RULE**

**After ANY major changes, you MUST run the following validation process:**

1. **Run Comprehensive Validation**: `./post_change_validation.sh`
2. **Check System Logs**: Review backend and frontend logs for errors
3. **Test Critical User Flows**: Manually verify key functionality works
4. **Document Results**: Record any issues and fixes applied

---

## 📋 **Testing Checklist**

### ✅ **Required Tests After Major Changes**

- [ ] **Container Health**: All Docker services running
- [ ] **Database Connectivity**: Django can connect to PostgreSQL
- [ ] **API Endpoints**: Core APIs returning expected responses
- [ ] **Authentication**: Login/logout functionality working
- [ ] **User Management**: Profile/role APIs functioning correctly
- [ ] **Frontend Accessibility**: React app loads and responds
- [ ] **Data Integrity**: Expected data counts in database
- [ ] **Log Analysis**: No critical errors in recent logs

### 🚨 **Critical Changes Requiring Full Validation**

1. **API Structure Changes** (models, serializers, views)
2. **Authentication/Authorization Updates**
3. **Database Schema Migrations**
4. **Docker Configuration Changes**
5. **Frontend Component Modifications**
6. **Service Integration Updates**

---

## 🛠️ **Testing Scripts**

### **1. Comprehensive Validation**
```bash
./post_change_validation.sh
```
- **Purpose**: Full system health check
- **Tests**: 14 comprehensive tests covering all system components
- **Expected Result**: All tests pass (14/14)
- **Runtime**: ~2-3 minutes

### **2. Automated Test Suite**
```bash
./scripts/run_tests.sh
```
- **Purpose**: Run all available unit/integration tests
- **Includes**: Django tests, React tests, linting, code quality
- **Expected Result**: All tests pass with clean code quality

### **3. Quick Health Check**
```bash
sudo docker-compose ps && curl -s http://localhost:8000/api/services/ > /dev/null && echo "✅ Quick check passed"
```

---

## 🔐 **Demo Credentials**

**For testing and validation, use these demo credentials:**

- **Username**: `test_user`  
- **Password**: `test_password`
- **Role**: Researcher (limited permissions)
- **Access**: Services, Reference Panels, User Profiles
- **Restrictions**: Cannot access Roles or Audit Logs (expected behavior)
- **Purpose**: Rapid verification system is responding
- **Runtime**: ~10 seconds

---

## 📊 **Test Categories**

### **Level 1: Container Health** 🐳
- All Docker services running (`web`, `db`, `redis`, `frontend`)
- No crashed or unhealthy containers
- Proper resource allocation

### **Level 2: API Functionality** 🌐
- **Public APIs**: Services, Reference Panels accessible
- **Authenticated APIs**: User management endpoints working
- **Response Codes**: Expected HTTP status codes returned
- **Data Structure**: API responses match frontend expectations

### **Level 3: Integration** 🔗
- **Login Flow**: Authentication working end-to-end
- **User Management**: CRUD operations functional
- **Data Persistence**: Changes saved and retrieved correctly
- **Frontend-Backend**: API calls and responses working

### **Level 4: Data Integrity** 💾
- **Expected Counts**: Services (5), Users (2+), Roles (5)
- **Relationships**: Foreign keys and associations intact
- **Migrations**: Database schema up-to-date

---

## 🔍 **Log Analysis Guidelines**

### **Backend Logs** (Django)
```bash
sudo docker-compose logs --tail=50 web
```
**Look for:**
- ❌ HTTP 500 errors
- ❌ Database connection errors  
- ❌ Authentication failures
- ❌ Model validation errors
- ✅ HTTP 200 responses for API calls

### **Frontend Logs** (React)
```bash
sudo docker-compose logs --tail=50 frontend
```
**Look for:**
- ❌ Compilation errors
- ❌ Runtime JavaScript errors
- ❌ Network request failures
- ✅ "Compiled successfully!" messages
- ✅ "No issues found" messages

---

## 🚀 **Post-Deployment Validation**

### **Immediate Checks** (First 5 minutes)
1. **Service Status**: All containers healthy
2. **Landing Page**: Frontend loads correctly
3. **Login**: Authentication works
4. **API Health**: Core endpoints responding

### **Extended Monitoring** (First 30 minutes)
1. **User Flows**: Create user, manage roles
2. **Service Integration**: Health checks functioning
3. **Error Rates**: No spike in error logs
4. **Performance**: Response times normal

---

## 📝 **Documentation Requirements**

### **For Major Changes**
1. **What Changed**: Brief description of modifications
2. **Test Results**: Copy/paste validation script output
3. **Issues Found**: Any failures and how they were resolved
4. **Verification**: Manual testing of affected features

### **Example Documentation**
```
## Change: UserManagement API Structure Fix
- **Modified**: UserProfileSerializer to include user field
- **Tests Run**: ./post_change_validation.sh (using test_user credentials)
- **Results**: 14/14 tests passed ✅
- **Issues**: None
- **Verification**: User Management page loads without runtime errors
```

### **Admin vs Demo Credentials**

**Demo Credentials (for testing):**
- `test_user` / `test_password` - Researcher role with limited permissions
- Use for validation scripts and general testing

**Admin Credentials (for administration):**
- `admin` / `admin_password` - Full system access
- Use only for admin-specific testing or system management

---

## ⚡ **Quick Commands Reference**

```bash
# Full validation after major changes
./post_change_validation.sh

# Quick health check
sudo docker-compose ps

# Check recent logs
sudo docker-compose logs --tail=20 web
sudo docker-compose logs --tail=20 frontend

# Test specific API endpoint
curl -s http://localhost:8000/api/services/

# Test authentication
curl -c session.txt -X POST -H "Content-Type: application/json" \
  -d '{"username":"test_user","password":"test_password"}' \
  http://localhost:8000/api/auth/login/
```

---

## 🎯 **Success Criteria**

### **Before Committing Changes**
- [ ] All validation tests pass (14/14)
- [ ] No errors in recent logs
- [ ] Critical user flows tested manually
- [ ] Changes documented

### **Before Deployment**
- [ ] Full test suite passes
- [ ] Integration tests complete
- [ ] Performance baseline maintained
- [ ] Rollback plan prepared

---

## 🔄 **Continuous Improvement**

### **Add New Tests When:**
- New features are implemented
- Bugs are discovered and fixed
- User feedback indicates issues
- Performance problems are resolved

### **Review and Update:**
- Test scripts monthly
- Success criteria quarterly  
- Documentation after major releases
- Monitoring thresholds based on usage patterns

---

**Remember: Testing is not optional - it's insurance for system reliability!** 🛡️