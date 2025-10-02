# Service Interface Contracts
## Federated Genomic Imputation Platform Microservices

## 🎯 Overview

This document defines the API contracts and interface specifications for all microservices in the Federated Genomic Imputation Platform. These contracts ensure consistent communication patterns and data formats across services.

## 🔗 Common Patterns

### **Standard Response Format**
```json
{
  "success": true,
  "data": {},
  "message": "Operation completed successfully",
  "timestamp": "2024-01-15T10:30:00Z",
  "request_id": "req_123456789"
}
```

### **Error Response Format**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    }
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "request_id": "req_123456789"
}
```

### **Pagination Format**
```json
{
  "count": 150,
  "next": "http://api.example.com/endpoint?page=3",
  "previous": "http://api.example.com/endpoint?page=1",
  "results": []
}
```

### **Common Headers**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
X-Request-ID: req_123456789
X-User-ID: user_123
X-Client-Type: web-frontend
X-Client-Version: 1.0.0
```

## 🔐 API Gateway Service (Port 8000)

### **Health Check**
```
GET /health
Response: {
  "status": "healthy|degraded|unhealthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "services": {
    "user-service": "healthy",
    "service-registry": "healthy",
    "job-processor": "healthy",
    "file-manager": "healthy",
    "notification": "healthy",
    "monitoring": "healthy"
  }
}
```

### **Rate Limiting Headers**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 2024-01-15T11:00:00Z
```

### **Request Routing**
- `/api/auth/*` → User Service
- `/api/users/*` → User Service
- `/api/services/*` → Service Registry
- `/api/reference-panels/*` → Service Registry
- `/api/jobs/*` → Job Processor
- `/api/files/*` → File Manager
- `/api/notifications/*` → Notification Service
- `/api/monitoring/*` → Monitoring Service
- `/api/dashboard/*` → Monitoring Service

## 👤 User Management Service (Port 8001)

### **Authentication Endpoints**

#### **Register User**
```
POST /auth/register
Request: {
  "username": "researcher123",
  "email": "researcher@university.edu",
  "first_name": "John",
  "last_name": "Doe",
  "password": "secure_password",
  "institution": "University of Research",
  "department": "Genomics"
}
Response: {
  "id": 123,
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "username": "researcher123",
  "email": "researcher@university.edu",
  "first_name": "John",
  "last_name": "Doe",
  "is_active": true,
  "is_staff": false,
  "is_superuser": false,
  "date_joined": "2024-01-15T10:30:00Z",
  "last_login": null
}
```

#### **Login User**
```
POST /auth/login
Request: {
  "username": "researcher123",
  "password": "secure_password"
}
Response: {
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 86400,
  "user": {
    "id": 123,
    "username": "researcher123",
    "email": "researcher@university.edu",
    "first_name": "John",
    "last_name": "Doe",
    "is_active": true,
    "is_staff": false,
    "is_superuser": false,
    "date_joined": "2024-01-15T10:30:00Z",
    "last_login": "2024-01-15T10:30:00Z"
  }
}
```

#### **Get Current User**
```
GET /auth/user
Headers: Authorization: Bearer <token>
Response: {
  "id": 123,
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "username": "researcher123",
  "email": "researcher@university.edu",
  "first_name": "John",
  "last_name": "Doe",
  "is_active": true,
  "is_staff": false,
  "is_superuser": false,
  "date_joined": "2024-01-15T10:30:00Z",
  "last_login": "2024-01-15T10:30:00Z"
}
```

### **User Management Endpoints**

#### **Get User Roles**
```
GET /users/{user_id}/roles
Response: [
  {
    "id": 1,
    "role": "researcher",
    "service_id": null,
    "granted_at": "2024-01-15T10:30:00Z",
    "expires_at": null,
    "is_active": true
  }
]
```

## 🏢 Service Registry Service (Port 8002)

### **Service Management**

#### **List Services**
```
GET /services?service_type=h3africa&is_active=true&is_available=true
Response: [
  {
    "id": 1,
    "name": "H3Africa Imputation Service",
    "service_type": "h3africa",
    "api_type": "ga4gh",
    "base_url": "https://imputation.h3africa.org",
    "description": "H3Africa genomic imputation service",
    "version": "1.0.0",
    "requires_auth": true,
    "auth_type": "token",
    "max_file_size_mb": 100,
    "supported_formats": ["vcf", "plink"],
    "supported_builds": ["hg19", "hg38"],
    "is_active": true,
    "is_available": true,
    "last_health_check": "2024-01-15T10:25:00Z",
    "health_status": "healthy",
    "response_time_ms": 150.5,
    "error_message": null,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:25:00Z"
  }
]
```

#### **Get Service Health**
```
GET /services/{service_id}/health
Response: {
  "service_id": 1,
  "status": "healthy",
  "response_time_ms": 150.5,
  "error_message": null,
  "checked_at": "2024-01-15T10:30:00Z"
}
```

### **Reference Panel Management**

#### **List Reference Panels**
```
GET /reference-panels?service_id=1&build=hg38&population=AFR
Response: [
  {
    "id": 1,
    "service_id": 1,
    "name": "1000G_AFR_hg38",
    "display_name": "1000 Genomes African Panel (hg38)",
    "description": "African population reference panel from 1000 Genomes",
    "population": "AFR",
    "build": "hg38",
    "samples_count": 661,
    "variants_count": 84700000,
    "is_available": true,
    "is_public": true,
    "requires_permission": false,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z"
  }
]
```

## ⚙️ Job Processing Service (Port 8003)

### **Job Management**

#### **Create Job**
```
POST /jobs
Content-Type: multipart/form-data
Request: {
  "name": "My Imputation Job",
  "description": "Imputation analysis for GWAS study",
  "service_id": 1,
  "reference_panel_id": 1,
  "input_format": "vcf",
  "build": "hg38",
  "phasing": true,
  "population": "AFR",
  "input_file": <file_upload>
}
Response: {
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "My Imputation Job",
  "description": "Imputation analysis for GWAS study",
  "user": {
    "id": 123,
    "username": "researcher123",
    "email": "researcher@university.edu",
    "first_name": "John",
    "last_name": "Doe"
  },
  "service": {
    "id": 1,
    "name": "H3Africa Imputation Service",
    "service_type": "h3africa"
  },
  "reference_panel": {
    "id": 1,
    "name": "1000G_AFR_hg38",
    "display_name": "1000 Genomes African Panel (hg38)"
  },
  "status": "pending",
  "progress_percentage": 0,
  "input_format": "vcf",
  "build": "hg38",
  "phasing": true,
  "population": "AFR",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z",
  "started_at": null,
  "completed_at": null,
  "execution_time_seconds": null,
  "error_message": null
}
```

#### **Get Job Status**
```
GET /jobs/{job_id}
Response: {
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "running",
  "progress_percentage": 45,
  "updated_at": "2024-01-15T10:35:00Z",
  "started_at": "2024-01-15T10:31:00Z",
  "estimated_completion": "2024-01-15T11:15:00Z"
}
```

#### **Cancel Job**
```
POST /jobs/{job_id}/cancel
Response: {
  "message": "Job cancellation initiated",
  "task_id": "celery_task_123456789",
  "status": "cancelling"
}
```

## 📁 File Management Service (Port 8004)

### **File Operations**

#### **Upload File**
```
POST /files/upload
Content-Type: multipart/form-data
Request: {
  "file": <file_upload>,
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "file_type": "input"
}
Response: {
  "id": 123,
  "filename": "input_data.vcf",
  "file_size": 1048576,
  "file_type": "input",
  "checksum": "d41d8cd98f00b204e9800998ecf8427e",
  "upload_url": "https://storage.example.com/files/123/input_data.vcf",
  "created_at": "2024-01-15T10:30:00Z"
}
```

#### **Download File**
```
GET /files/{file_id}/download
Response: {
  "download_url": "https://storage.example.com/files/123/download?token=abc123",
  "filename": "results.vcf.gz",
  "file_size": 2097152,
  "expires_at": "2024-01-15T11:30:00Z"
}
```

## 🔔 Notification Service (Port 8005)

### **Notification Management**

#### **Send Notification**
```
POST /notifications
Request: {
  "user_id": 123,
  "type": "job_completed",
  "title": "Job Completed Successfully",
  "message": "Your imputation job 'My Imputation Job' has completed successfully.",
  "data": {
    "job_id": "550e8400-e29b-41d4-a716-446655440000",
    "job_name": "My Imputation Job"
  },
  "channels": ["web", "email"]
}
Response: {
  "id": 456,
  "status": "sent",
  "created_at": "2024-01-15T10:30:00Z"
}
```

#### **WebSocket Connection**
```
WebSocket: ws://notification:8005/ws/{user_id}
Message Format: {
  "type": "notification",
  "data": {
    "id": 456,
    "type": "job_completed",
    "title": "Job Completed Successfully",
    "message": "Your imputation job has completed successfully.",
    "timestamp": "2024-01-15T10:30:00Z",
    "read": false
  }
}
```

## 📊 Monitoring Service (Port 8006)

### **Dashboard Data**

#### **Get Dashboard Stats**
```
GET /dashboard/stats
Response: {
  "job_stats": {
    "total": 1250,
    "pending": 15,
    "running": 8,
    "completed": 1200,
    "failed": 27,
    "success_rate": 97.8
  },
  "service_stats": {
    "available_services": 5,
    "accessible_services": 5,
    "total_reference_panels": 25
  },
  "user_stats": {
    "total_users": 150,
    "active_users_today": 45,
    "new_users_this_month": 12
  },
  "system_stats": {
    "cpu_usage": 65.5,
    "memory_usage": 78.2,
    "disk_usage": 45.8,
    "network_io": 1250000
  }
}
```

#### **Get System Health**
```
GET /monitoring/health
Response: {
  "overall_status": "healthy",
  "services": {
    "api-gateway": {
      "status": "healthy",
      "response_time": 25.5,
      "last_check": "2024-01-15T10:30:00Z"
    },
    "user-service": {
      "status": "healthy",
      "response_time": 15.2,
      "last_check": "2024-01-15T10:30:00Z"
    }
  },
  "infrastructure": {
    "database": "healthy",
    "redis": "healthy",
    "storage": "healthy"
  }
}
```

## 🔄 Inter-Service Communication

### **Service-to-Service Authentication**
```
Headers:
X-Service-Name: job-processor
X-Service-Token: <internal_service_token>
X-Request-ID: req_123456789
```

### **Event Messages (Redis Streams)**
```json
{
  "event_type": "job.status.updated",
  "timestamp": "2024-01-15T10:30:00Z",
  "source_service": "job-processor",
  "data": {
    "job_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": 123,
    "old_status": "running",
    "new_status": "completed",
    "progress_percentage": 100
  }
}
```

## 🛡️ Security Contracts

### **JWT Token Format**
```json
{
  "user_id": 123,
  "username": "researcher123",
  "email": "researcher@university.edu",
  "roles": ["researcher"],
  "exp": 1705401000,
  "iat": 1705314600,
  "iss": "federated-imputation-platform"
}
```

### **API Key Format**
```
X-API-Key: fip_live_1234567890abcdef
```

### **Rate Limiting**
- **Default:** 100 requests per hour per IP
- **Authenticated:** 1000 requests per hour per user
- **File Upload:** 10 uploads per hour per user
- **Service-to-Service:** No limit with valid service token

## 📝 Validation Rules

### **Common Validations**
- **Email:** RFC 5322 compliant
- **Username:** 3-150 characters, alphanumeric and underscores
- **Password:** Minimum 8 characters, complexity requirements
- **File Size:** Maximum 500MB per file
- **Job Name:** 1-200 characters
- **Service URLs:** Valid HTTPS URLs

### **Error Codes**
- `VALIDATION_ERROR`: Input validation failed
- `AUTHENTICATION_ERROR`: Invalid or missing authentication
- `AUTHORIZATION_ERROR`: Insufficient permissions
- `NOT_FOUND`: Resource not found
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `SERVICE_UNAVAILABLE`: External service unavailable
- `INTERNAL_ERROR`: Internal server error

This comprehensive service interface contract ensures consistent communication patterns and data formats across all microservices in the Federated Genomic Imputation Platform.
