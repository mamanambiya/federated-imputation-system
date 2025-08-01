# Federated Imputation System

A web-based platform for connecting to multiple genomic imputation services, allowing users to submit jobs, monitor progress, and download results from both H3Africa and Michigan Imputation Services.

## Features

- **Multi-Service Support**: Connect to H3Africa and Michigan Imputation Services
- **Service Selection**: Browse available services and their reference panels
- **Reference Panel Selection**: View and select from available reference panels for each service
- **Job Submission**: Upload genomic data files and submit imputation jobs
- **Progress Tracking**: Real-time monitoring of job status and progress
- **Result Download**: Download imputed data and quality reports
- **User Management**: Authentication and user-specific job tracking
- **Dashboard**: Overview of jobs, statistics, and service health

## Architecture

- **Backend**: Django REST Framework with PostgreSQL database
- **Frontend**: React with TypeScript and Material-UI
- **Task Queue**: Celery with Redis for async job processing
- **Containerization**: Docker and Docker Compose for easy deployment

## Documentation

📚 **Comprehensive documentation is available in the [docs/](./docs/) folder:**

- **[Setup Guide](./docs/SETUP.md)** - Detailed installation and configuration instructions
- **[Implementation Guide](./docs/IMPLEMENTATION_GUIDE.md)** - Complete rebuild guide for developers
- **[Development Roadmap](./docs/ROADMAP.md)** - Future features and strategic planning
- **[Admin Setup](./docs/ADMIN_SERVICE_SETUP.md)** - Service configuration and management
- **[API Integration](./docs/GA4GH_IMPLEMENTATION_SUMMARY.md)** - GA4GH, Michigan, and DNASTACK API details
- **[Feature Guides](./docs/)** - Multi-service selection, service details, and more

👉 **Start with the [Documentation Index](./docs/README.md)** for a complete overview of all available guides.

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Git

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd federated-imputation-central
   ```

2. **Create environment file**:
   ```bash
   cp .env.example .env
   ```
   
   Edit the `.env` file with your API keys and configuration:
   ```bash
   # Required: Add your service API keys
   H3AFRICA_API_KEY=your_h3africa_api_key
   MICHIGAN_API_KEY=your_michigan_api_key
   
   # Optional: Customize other settings
   SECRET_KEY=your_django_secret_key
   ```

3. **Start the system**:
   ```bash
   docker-compose up -d
   ```

4. **Run initial setup**:
   ```bash
   # Run database migrations
   docker-compose exec web python manage.py migrate
   
   # Create superuser
   docker-compose exec web python manage.py createsuperuser
   
   # Load initial data (services and reference panels)
   docker-compose exec web python manage.py loaddata initial_services.json
   ```

5. **Access the application**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000/api/
   - Django Admin: http://localhost:8000/admin/

## Usage

### 1. Service Selection

Navigate to the **Services** page to:
- View available imputation services (H3Africa, Michigan)
- See service details and capabilities
- Browse reference panels for each service
- Sync latest reference panels from external services

### 2. Job Submission

Use the **New Job** workflow to:

1. **Upload File**: Drag and drop your genomic data file (VCF, PLINK, BGEN formats supported)
2. **Select Service & Panel**: Choose an imputation service and reference panel
3. **Configure Job**: Set job parameters (genome build, phasing options, etc.)
4. **Review & Submit**: Confirm settings and submit the job

### 3. Progress Monitoring

Track your jobs from the **Jobs** page:
- View all submitted jobs with status and progress
- Filter by status, service, or search by name
- Real-time progress updates for running jobs
- Detailed job information and status history

### 4. Results Download

Access completed job results:
- Download imputed data files
- Access quality reports and log files
- View result statistics and metrics
- Bulk download options for multiple files

## API Endpoints

The system provides a comprehensive REST API:

### Services
- `GET /api/services/` - List available services
- `GET /api/services/{id}/` - Get service details
- `GET /api/services/{id}/reference_panels/` - Get service reference panels
- `POST /api/services/{id}/sync_reference_panels/` - Sync panels from external service

### Jobs
- `GET /api/jobs/` - List user jobs
- `POST /api/jobs/` - Create new job
- `GET /api/jobs/{id}/` - Get job details
- `POST /api/jobs/{id}/cancel/` - Cancel job
- `POST /api/jobs/{id}/retry/` - Retry failed job
- `GET /api/jobs/{id}/files/` - Get job result files

### Reference Panels
- `GET /api/reference-panels/` - List all panels
- `GET /api/reference-panels/{id}/` - Get panel details

### Results
- `GET /api/result-files/` - List user result files
- `GET /api/result-files/{id}/download/` - Download file

## Development

### Backend Development

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Run migrations**:
   ```bash
   python manage.py migrate
   ```

3. **Start development server**:
   ```bash
   python manage.py runserver
   ```

### Frontend Development

1. **Install dependencies**:
   ```bash
   cd frontend
   npm install
   ```

2. **Start development server**:
   ```bash
   npm start
   ```

### Running Tests

```bash
# Backend tests
docker-compose exec web python manage.py test

# Frontend tests
docker-compose exec frontend npm test
```

## Configuration

### Service Configuration

Add new imputation services through the Django admin:

1. Create `ImputationService` instance
2. Configure `ServiceConfiguration` with API credentials
3. Sync reference panels using the API or admin

### User Management

Users can be managed through the Django admin interface:
- Create user accounts
- Assign service access permissions
- Set usage quotas and limits

## File Formats

Supported input formats:
- **VCF**: Variant Call Format (.vcf, .vcf.gz)
- **PLINK**: Binary format (.bed, .bim, .fam)
- **BGEN**: Oxford format (.bgen)

Maximum file size: 100MB (configurable)

## Monitoring

### System Health

- Dashboard provides service health status
- Job statistics and success rates
- Real-time progress monitoring

### Logs

View application logs:
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs web
docker-compose logs celery
```

## Troubleshooting

### Common Issues

1. **Service Connection Errors**:
   - Verify API keys in `.env` file
   - Check service status and availability
   - Review network connectivity

2. **File Upload Issues**:
   - Check file format and size limits
   - Verify file permissions
   - Review upload error messages

3. **Job Processing Delays**:
   - Monitor external service queues
   - Check Celery worker status
   - Review job logs for errors

### Support

For issues and questions:
1. Check the troubleshooting section
2. Review application logs
3. Contact system administrators

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- H3Africa Consortium for genomic imputation services
- University of Michigan Imputation Server
- Django and React communities for excellent frameworks 