# Service Management API Documentation

## Overview

The Service Management API provides comprehensive CRUD (Create, Read, Update, Delete) operations for managing imputation services in the Federated Genomic Imputation Platform. This API supports individual operations as well as bulk operations for efficient service management.

## Base URL

```
http://localhost:8000/api/services/
```

## Authentication & Permissions

- **List/Retrieve**: No authentication required (public access)
- **Create/Update/Delete**: Requires authentication and admin privileges
- **Bulk Operations**: Requires authentication and admin privileges

## Endpoints

### 1. List Services

**Endpoint:** `GET /api/services/`

**Description:** Retrieve a paginated list of imputation services with filtering options.

**Query Parameters:**
- `is_active` (boolean): Filter by active status (admin only)
- `service_type` (string): Filter by service type (h3africa, michigan, dnastack, custom)
- `api_type` (string): Filter by API type (ga4gh, michigan, dnastack, custom)
- `search` (string): Search in service name and description
- `page` (integer): Page number for pagination
- `page_size` (integer): Number of results per page

**Example Requests:**
```bash
# Get all active services
curl "http://localhost:8000/api/services/"

# Filter by service type
curl "http://localhost:8000/api/services/?service_type=h3africa"

# Search services
curl "http://localhost:8000/api/services/?search=michigan"

# Admin: Get all services including inactive
curl -H "Authorization: Token YOUR_TOKEN" "http://localhost:8000/api/services/?is_active=false"
```

**Response Format:**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "H3Africa Imputation Service",
      "service_type": "h3africa",
      "api_type": "ga4gh",
      "api_url": "https://h3africa.org/imputation",
      "description": "Pan-African imputation service",
      "location": "Cape Town, South Africa",
      "continent": "Africa",
      "is_active": true,
      "api_key_required": false,
      "max_file_size_mb": 100,
      "supported_formats": ["vcf", "vcf.gz"],
      "reference_panels_count": 5,
      "api_config": {},
      "health_status": "healthy",
      "created_at": "2025-01-01T00:00:00Z",
      "updated_at": "2025-01-01T00:00:00Z"
    }
  ]
}
```

### 2. Retrieve Service

**Endpoint:** `GET /api/services/{id}/`

**Description:** Retrieve detailed information about a specific service.

**Example Request:**
```bash
curl "http://localhost:8000/api/services/1/"
```

### 3. Create Service

**Endpoint:** `POST /api/services/`

**Description:** Create a new imputation service.

**Required Fields:**
- `name` (string): Unique service name (min 3 characters)
- `service_type` (string): Type of service
- `api_type` (string): API type
- `api_url` (string): Valid HTTP/HTTPS URL

**Optional Fields:**
- `description` (string): Service description
- `location` (string): Physical location
- `continent` (string): Continent
- `is_active` (boolean): Active status (default: true)
- `api_key_required` (boolean): Whether API key is required
- `max_file_size_mb` (integer): Maximum file size in MB (1-10000)
- `supported_formats` (array): Supported file formats
- `api_config` (object): API configuration JSON

**Example Request:**
```bash
curl -X POST "http://localhost:8000/api/services/" \
  -H "Authorization: Token YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Imputation Service",
    "service_type": "custom",
    "api_type": "ga4gh",
    "api_url": "https://example.com/api",
    "description": "Custom imputation service",
    "max_file_size_mb": 200,
    "supported_formats": ["vcf", "vcf.gz", "plink"]
  }'
```

**Response:**
```json
{
  "message": "Service \"New Imputation Service\" created successfully",
  "service": {
    "id": 6,
    "name": "New Imputation Service",
    ...
  }
}
```

### 4. Update Service

**Endpoint:** `PUT /api/services/{id}/` or `PATCH /api/services/{id}/`

**Description:** Update an existing service (PUT for full update, PATCH for partial).

**Example Request:**
```bash
curl -X PATCH "http://localhost:8000/api/services/1/" \
  -H "Authorization: Token YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Updated description",
    "max_file_size_mb": 300
  }'
```

### 5. Delete Service

**Endpoint:** `DELETE /api/services/{id}/`

**Description:** Delete a service (soft delete by default, hard delete with force parameter).

**Query Parameters:**
- `force` (boolean): If true, permanently delete the service

**Example Requests:**
```bash
# Soft delete (deactivate)
curl -X DELETE "http://localhost:8000/api/services/1/" \
  -H "Authorization: Token YOUR_TOKEN"

# Hard delete (permanent)
curl -X DELETE "http://localhost:8000/api/services/1/?force=true" \
  -H "Authorization: Token YOUR_TOKEN"
```

## Bulk Operations

### 1. Bulk Create

**Endpoint:** `POST /api/services/bulk_create/`

**Description:** Create multiple services in a single request.

**Example Request:**
```bash
curl -X POST "http://localhost:8000/api/services/bulk_create/" \
  -H "Authorization: Token YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "services": [
      {
        "name": "Service 1",
        "service_type": "custom",
        "api_type": "ga4gh",
        "api_url": "https://service1.com/api"
      },
      {
        "name": "Service 2",
        "service_type": "custom",
        "api_type": "ga4gh",
        "api_url": "https://service2.com/api"
      }
    ]
  }'
```

**Response:**
```json
{
  "created_services": [...],
  "created_count": 2,
  "errors": [],
  "error_count": 0
}
```

### 2. Bulk Update

**Endpoint:** `PATCH /api/services/bulk_update/`

**Description:** Update multiple services in a single request.

**Example Request:**
```bash
curl -X PATCH "http://localhost:8000/api/services/bulk_update/" \
  -H "Authorization: Token YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "updates": [
      {
        "id": 1,
        "data": {"is_active": false}
      },
      {
        "id": 2,
        "data": {"max_file_size_mb": 500}
      }
    ]
  }'
```

### 3. Bulk Delete

**Endpoint:** `DELETE /api/services/bulk_delete/`

**Description:** Delete multiple services in a single request.

**Example Request:**
```bash
curl -X DELETE "http://localhost:8000/api/services/bulk_delete/" \
  -H "Authorization: Token YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "service_ids": [1, 2, 3],
    "force_delete": false
  }'
```

## Validation Rules

### Service Name
- Minimum 3 characters
- Must be unique across all services
- Automatically trimmed of whitespace

### API URL
- Must start with http:// or https://
- Must be a valid URL format
- Supports domains, localhost, and IP addresses

### File Size Limits
- Must be greater than 0
- Maximum 10GB (10000 MB)

### Supported Formats
- Valid formats: vcf, vcf.gz, plink, bed, bim, fam, bgen, gen, haps, legend, sample
- Must be provided as an array

### Service Type & API Type Compatibility
- h3africa: ga4gh, custom
- michigan: michigan, custom
- dnastack: dnastack, ga4gh
- custom: any API type

## Error Handling

### Common Error Responses

**400 Bad Request:**
```json
{
  "error": "Field \"name\" is required"
}
```

**400 Validation Error:**
```json
{
  "name": ["A service with this name already exists"],
  "api_url": ["Invalid URL format"]
}
```

**403 Forbidden:**
```json
{
  "detail": "You do not have permission to perform this action."
}
```

**404 Not Found:**
```json
{
  "detail": "Not found."
}
```

**500 Internal Server Error:**
```json
{
  "error": "Failed to create service"
}
```

## Service Actions

### Sync Reference Panels

**Endpoint:** `POST /api/services/{id}/sync_reference_panels/`

**Description:** Trigger synchronization of reference panels from the external service.

### Get Reference Panels

**Endpoint:** `GET /api/services/{id}/reference_panels/`

**Description:** Get reference panels associated with a specific service.

**Query Parameters:**
- `population` (string): Filter by population
- `build` (string): Filter by genome build

### Health Check

**Endpoint:** `GET /api/services/{id}/health/`

**Description:** Check the health status of a specific service.

**Query Parameters:**
- `force` (boolean): Force a fresh health check (bypass cache)

## Audit Logging

All service management operations are automatically logged with:
- User who performed the action
- Action type (create, update, delete, deactivate)
- Resource details
- Timestamp

Audit logs can be accessed through the admin interface or audit API endpoints.

## Best Practices

1. **Use Bulk Operations**: For managing multiple services, use bulk endpoints for better performance
2. **Soft Delete First**: Use soft delete (deactivation) before hard delete to prevent data loss
3. **Validate Dependencies**: Check for active jobs before deleting services
4. **Monitor Health**: Regularly check service health status
5. **Use Filtering**: Leverage query parameters for efficient data retrieval
6. **Handle Errors**: Always check for validation errors in bulk operations

## Rate Limiting

- Standard rate limits apply to all endpoints
- Bulk operations have higher limits but may take longer to process
- Health check endpoints have relaxed limits for monitoring tools
