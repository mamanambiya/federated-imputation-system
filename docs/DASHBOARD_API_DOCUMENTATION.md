# Dashboard API Documentation

## Overview

The Dashboard API provides comprehensive endpoints for retrieving system statistics, service information, and health status with enhanced error handling and fallback mechanisms.

## Base URL

```
http://localhost:8000/api/dashboard/
```

## Endpoints

### 1. Dashboard Statistics

**Endpoint:** `GET /api/dashboard/stats/`

**Description:** Get comprehensive dashboard statistics including job stats, service stats, and recent jobs.

**Authentication:** Optional (returns user-specific data if authenticated, global stats if not)

**Response Format:**
```json
{
  "job_stats": {
    "total": 0,
    "completed": 0,
    "running": 0,
    "failed": 0,
    "success_rate": 0.0
  },
  "service_stats": {
    "available_services": 5,
    "accessible_services": 0
  },
  "recent_jobs": [],
  "status": "success",
  "timestamp": "2025-09-21T12:35:40.574408+00:00"
}
```

**Error Handling:**
- Returns fallback data with `status: "fallback"` if database errors occur
- Includes error details in `error` field
- Always returns HTTP 200 with appropriate status indicators

### 2. Services Overview

**Endpoint:** `GET /api/dashboard/services_overview/`

**Description:** Get detailed overview of all active imputation services with their capabilities.

**Authentication:** None required

**Response Format:**
```json
{
  "services": [
    {
      "id": 1,
      "name": "H3Africa Imputation Service",
      "description": "Pan-African imputation service with African-specific reference panels",
      "is_active": true,
      "api_url": "https://h3africa.org/imputation",
      "supported_formats": ["vcf", "vcf.gz"],
      "max_file_size_mb": 100,
      "populations": ["African", "East African", "North African", "South African", "West African"],
      "builds": ["hg38", "hg38", "hg38", "hg38", "hg38"],
      "reference_panels_count": 5
    }
  ],
  "count": 5,
  "status": "success",
  "timestamp": "2025-09-21T12:35:55.386630+00:00"
}
```

**Error Handling:**
- Individual service errors are handled gracefully
- Failed services include error information
- Returns empty array with error status if critical failure occurs

### 3. Health Check

**Endpoint:** `GET /api/dashboard/health/`

**Description:** Get comprehensive system health status including database, services, and reference panels.

**Authentication:** None required

**Response Format:**
```json
{
  "status": "healthy",
  "timestamp": "2025-09-21T12:35:47.858922+00:00",
  "checks": {
    "database": "healthy",
    "services": "healthy",
    "reference_panels": "healthy"
  },
  "services": {
    "active": 5,
    "total": 5,
    "status": "healthy"
  },
  "database": {
    "connection": "active",
    "reference_panels": 14
  },
  "errors": []
}
```

**Health Status Values:**
- `healthy`: All systems operational
- `degraded`: Some non-critical issues detected
- `unhealthy`: Critical issues detected

**Error Handling:**
- Returns HTTP 500 only for critical system failures
- Individual check failures are reported in the response
- Includes detailed error messages in `errors` array

## Enhanced Error Handling Features

### 1. Graceful Degradation
- APIs continue to function even when individual components fail
- Fallback data is provided when primary data sources are unavailable
- Clear status indicators distinguish between success, fallback, and error states

### 2. Comprehensive Logging
- All errors are logged with detailed context
- Performance issues are tracked and reported
- Database query failures are handled individually

### 3. Timeout Protection
- Database queries have implicit timeout protection
- Long-running operations are handled gracefully
- System remains responsive during high load

### 4. Data Validation
- Response data is validated before returning
- Invalid or corrupted data triggers fallback mechanisms
- Consistent response format maintained across all scenarios

## Frontend Integration

### Error Handling in React Components

```typescript
const loadStats = async () => {
  try {
    setLoading(true);
    setError(null);
    const data = await getDashboardStats();
    
    // Check for fallback status
    if (data.status === 'fallback') {
      setError('Some data may be unavailable. Using cached values.');
    }
    
    setStats(data);
  } catch (err) {
    console.error('Error loading dashboard:', err);
    setError('Failed to load dashboard data. Using default values.');
    
    // Set default stats if API fails completely
    setStats(getDefaultStats());
  } finally {
    setLoading(false);
  }
};
```

### Status Indicators

The frontend should handle different status values:

- `success`: Display data normally
- `fallback`: Show warning indicator with data
- `error`: Show error message with fallback data

## Monitoring and Alerting

### Database Stability Monitoring

The dashboard APIs are monitored by:
- Database stability monitor (runs every 15 minutes)
- Health check endpoint monitoring
- Automated recovery systems

### Performance Metrics

Key metrics tracked:
- Response times for each endpoint
- Error rates and types
- Database query performance
- Service availability

## Security Considerations

### Authentication
- User-specific data requires authentication
- Public endpoints provide general system information
- No sensitive data exposed in public endpoints

### Rate Limiting
- Standard rate limiting applies to all endpoints
- Health check endpoint has higher limits for monitoring tools
- Authenticated users have higher rate limits

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Check database container status
   - Verify database credentials
   - Run database stability monitor

2. **Service Data Missing**
   - Verify services are marked as active
   - Check reference panel associations
   - Review service configuration

3. **Performance Issues**
   - Monitor database query performance
   - Check system resource usage
   - Review error logs for patterns

### Debug Endpoints

For debugging, check:
- `/api/monitoring/health/` - System health status
- `/api/monitoring/metrics/` - Detailed system metrics
- `/api/monitoring/dashboard/` - Comprehensive monitoring data

## API Versioning

Current version: v1
- Backward compatibility maintained
- New features added without breaking changes
- Deprecation notices provided for removed features
