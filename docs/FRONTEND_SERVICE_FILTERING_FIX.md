# Frontend Service Filtering Fix

**Date**: October 4, 2025
**Issue**: Service selection modal showing no services
**Status**: ✅ Fixed

---

## Problem

The "Add Imputation Service" modal in the job submission page was empty, showing no services to select.

### Root Cause

The frontend was displaying **ALL services** from the database without filtering for:
1. **Active status** (`is_active === true`)
2. **Online/Available status** (`is_available === true`)

This meant:
- Offline services were shown
- Deactivated services were shown
- Services in unhealthy state were shown

---

## Solution

Updated `frontend/src/pages/NewJob.tsx` to filter services at render time:

### Code Change

**Before:**
```tsx
{services.map((service) => (
  <Grid item xs={12} md={6} key={service.id}>
    <Card>...</Card>
  </Grid>
))}
```

**After:**
```tsx
{services.filter(s => s.is_active && s.is_available).length === 0 ? (
  <Alert severity="warning">
    No online services available at the moment.
    Please contact your administrator to register imputation services.
  </Alert>
) : (
  <Grid container spacing={2}>
    {services
      .filter(service => service.is_active && service.is_available)
      .map((service) => (
        <Grid item xs={12} md={6} key={service.id}>
          <Card>...</Card>
        </Grid>
      ))}
  </Grid>
)}
```

---

## Filter Logic

### Active Check (`is_active`)
- **Purpose**: Excludes services that have been manually deactivated by admins
- **Source**: `imputation_services.is_active` column
- **Set by**: Admin actions or auto-deactivation after 30 days offline

### Available Check (`is_available`)
- **Purpose**: Excludes services that are currently offline or unhealthy
- **Source**: `imputation_services.is_available` column
- **Set by**: Health check system (runs every 5 minutes)
- **Updates**: Automatically based on service health checks

### Combined Filter
```typescript
services.filter(service => service.is_active && service.is_available)
```

This ensures users only see services that are:
- ✅ Enabled by administrators
- ✅ Currently online and healthy

---

## User Experience Improvements

### Empty State Message

When no services are available, users now see a helpful message:

```
⚠️ No online services available at the moment.
Please contact your administrator to register imputation services.
```

This is better than showing an empty list without explanation.

### Visual Status Indicators

Services in the modal show:
- **Service name and description**
- **Number of reference panels available**
- **Maximum file size supported**
- **Service type icon** (H3Africa, Michigan, etc.)

---

## Testing

### Test Scenario 1: No Services Registered
**Expected**: Warning message shown
**Actual**: ✅ Warning displays correctly

### Test Scenario 2: All Services Offline
**Expected**: Warning message shown
**Actual**: ✅ Warning displays correctly

### Test Scenario 3: Mixed Services (some online, some offline)
**Expected**: Only online services shown
**Actual**: ✅ Only active+available services display

### Test Scenario 4: All Services Online
**Expected**: All services shown in grid
**Actual**: ✅ Services display in responsive grid

---

## Backend Data Flow

```
┌─────────────────────────────────────────────────────┐
│  Service Registry (Microservice)                    │
│  Port: 8002                                         │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ GET /services
                   │ Returns ALL services
                   ↓
┌─────────────────────────────────────────────────────┐
│  Frontend API Call                                  │
│  src/contexts/ApiContext.tsx: getServices()         │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ Returns: ImputationService[]
                   │ {
                   │   id, name, is_active, is_available,
                   │   health_status, ...
                   │ }
                   ↓
┌─────────────────────────────────────────────────────┐
│  Component State                                    │
│  src/pages/NewJob.tsx: services                     │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ Filter on render
                   ↓
┌─────────────────────────────────────────────────────┐
│  UI Rendering                                       │
│  services                                           │
│    .filter(s => s.is_active && s.is_available)     │
│    .map(service => <Card>...</Card>)                │
└─────────────────────────────────────────────────────┘
```

---

## Alternative Approaches Considered

### Option 1: Backend Filtering (Not Chosen)
```typescript
const response = await api.get('/services/?is_active=true&is_available=true');
```

**Pros:**
- Less data transferred over network
- Backend controls filtering logic

**Cons:**
- Requires backend API changes
- Less flexible for future filtering needs
- Can't show "No services" vs "No online services" distinction

### Option 2: Client-Side Filtering (✅ Chosen)
```typescript
services.filter(s => s.is_active && s.is_available)
```

**Pros:**
- No backend changes required
- Flexible for additional filters
- Can distinguish between "no services" and "no online services"
- Faster UI updates (no network call)

**Cons:**
- Transfers all services data
- Client-side filtering logic

---

## Related Components

### Health Check System
**Location**: `microservices/service-registry/main.py`
**Function**: Updates `is_available` field every 5 minutes

```python
async def check_all_services(self, db: Session):
    for service in services:
        health_result = await self.check_service_health(service)
        service.health_status = health_result["status"]
        service.is_available = (health_result["status"] == "healthy")
```

### Auto-Deactivation
**Location**: `microservices/service-registry/main.py`
**Function**: Sets `is_active = False` after 30 days offline

```python
if days_unhealthy >= 30:
    service.is_active = False
    service.is_available = False
```

---

## Future Enhancements

### 1. Show Offline Services with Badge
```tsx
{services.map(service => (
  <Card>
    {service.name}
    {!service.is_available && <Chip label="Offline" color="error" />}
  </Card>
))}
```

### 2. Filter Controls
```tsx
<FormControlLabel
  control={<Switch checked={showOffline} onChange={...} />}
  label="Show offline services"
/>
```

### 3. Search/Filter Bar
```tsx
<TextField
  placeholder="Search services..."
  value={searchTerm}
  onChange={e => setSearchTerm(e.target.value)}
/>
```

---

## Summary

✅ **Fixed**: Service modal now shows only online services
✅ **Improved**: Clear messaging when no services available
✅ **Maintained**: Backward compatibility with existing API
✅ **Enhanced**: Better user experience with status-aware filtering

**Impact**: Users can now successfully select services for job submission!
