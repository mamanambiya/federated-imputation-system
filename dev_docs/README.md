# Developer Documentation

This directory contains all development-related documentation, scripts, and tools for the Federated Genomic Imputation Platform.

## 📁 Directory Structure

```
dev_docs/
├── scripts/           # Development and maintenance scripts
├── tests/            # All testing files and configurations  
├── maintenance/      # Database and system maintenance docs
├── architecture/     # Technical architecture documentation
└── troubleshooting/  # Debugging and issue resolution guides
```

## 🔧 Scripts Directory (`scripts/`)

### Backup and Recovery
- `backup_system.sh` - Advanced backup management system
- `backup_scheduler.sh` - Automated backup scheduling with cron
- `restore_wizard.sh` - Interactive database restoration wizard

### Testing and Validation
- `run_comprehensive_tests.sh` - Complete test suite runner
- `run_tests.sh` - Basic test runner
- `test_login.sh` - Authentication testing utility

### Monitoring and Maintenance
- `monitor-data.sh` - System monitoring utilities
- `restore-db.sh` - Database restoration script

### Usage Examples
```bash
# Run comprehensive tests
./dev_docs/scripts/run_comprehensive_tests.sh

# Create full backup
./dev_docs/scripts/backup_system.sh backup full

# Install backup scheduler
./dev_docs/scripts/backup_scheduler.sh install

# Interactive database restoration
./dev_docs/scripts/restore_wizard.sh
```

## 🧪 Tests Directory (`tests/`)

### Playwright Testing
- `playwright.config.js` - Playwright configuration
- `playwright/` - End-to-end test suites
- `playwright/comprehensive_tests.spec.js` - Main test suite
- `playwright/global-setup.js` - Test environment setup
- `playwright/global-teardown.js` - Test cleanup

### Running Tests
```bash
# Run all Playwright tests
cd dev_docs/tests && npx playwright test

# Run specific test suite
npx playwright test comprehensive_tests.spec.js

# Generate test report
npx playwright show-report
```

## 🛠️ Maintenance Directory (`maintenance/`)

### Documentation
- `DATABASE_MAINTENANCE.md` - Database backup and recovery procedures
- `DATA_LOSS_PREVENTION.md` - Data protection strategies
- `AUTOMATED_MONITORING_SETUP.md` - Monitoring system configuration
- `COMPREHENSIVE_IMPROVEMENTS_SUMMARY.md` - Recent improvements summary

### Key Procedures
- **Daily Backups**: Automated at 2:00 AM
- **Health Checks**: Continuous monitoring
- **Recovery**: Step-by-step restoration guides
- **Performance**: Optimization recommendations

## 🏗️ Architecture Directory (`architecture/`)

### Technical Documentation
- `DJANGO_FASTAPI_ARCHITECTURE.md` - **Comprehensive guide to Django + FastAPI hybrid architecture**
  - Why both frameworks? Performance comparison and use cases
  - 7-database architecture explained (database-per-service pattern)
  - ILIFU service connection deep dive
  - Django Admin & microservices integration (current gaps and solutions)
  - Data synchronization challenges and future patterns
- `DJANGO_REACT_ARCHITECTURE_FIX.md` - Architecture improvements and fixes

### Quick Reference
- **Architecture Overview**: `architecture/ARCHITECTURE_CONTEXT.md` - 30-second overview and troubleshooting

### System Design
- **Backend**: Django REST Framework (admin, auth) + FastAPI microservices (async operations)
- **Frontend**: React with TypeScript and Material-UI
- **Queue**: Celery with Redis
- **Deployment**: Docker Compose (7 microservices + infrastructure)
- **Databases**: 7 PostgreSQL databases (database-per-service pattern)

### Key Architecture Decisions
- **Hybrid Framework**: Django for admin/UI, FastAPI for performance (10x faster health checks)
- **Microservices**: 7 independent services with isolated databases
- **Async Operations**: FastAPI native async for concurrent external service health monitoring
- **Memory Efficiency**: 75% less RAM than all-Django (300 MB vs 1.2 GB for microservices)

## 🔍 Troubleshooting Directory (`troubleshooting/`)

### Issue Resolution
- `TROUBLESHOOTING.md` - **Comprehensive troubleshooting guide** for common issues
- `LOGIN_TROUBLESHOOTING.md` - Authentication issue debugging
- `TESTING_RULES.md` - Testing guidelines and best practices

### Common Issues
- Authentication failures
- Database connectivity
- Service integration problems
- Performance bottlenecks

## 🚀 Quick Start for Developers

### 1. Environment Setup
```bash
# Clone repository
git clone <repository-url>
cd federated-imputation-central

# Start services
docker-compose up -d

# Run initial setup
./post_change_validation.sh
```

### 2. Development Workflow
```bash
# Install backup system
./dev_docs/scripts/backup_scheduler.sh install

# Run comprehensive tests
./dev_docs/scripts/run_comprehensive_tests.sh

# Monitor system health
./post_change_validation.sh
```

### 3. Testing Workflow
```bash
# Run Playwright tests
cd dev_docs/tests
npx playwright test

# Run API tests
./dev_docs/scripts/run_comprehensive_tests.sh api

# Run performance tests
./dev_docs/scripts/run_comprehensive_tests.sh performance
```

## 📊 Monitoring and Alerts

### Health Checks
- **System Validation**: `./post_change_validation.sh`
- **Backup Status**: `./dev_docs/scripts/backup_scheduler.sh status`
- **Service Health**: Check services page for real-time status

### Key Metrics
- System uptime: >99.9%
- API response time: <2 seconds
- Backup success rate: 100%
- Test pass rate: >90%

## 🔐 Security Considerations

### Development Security
- Never commit secrets or API keys
- Use environment variables for configuration
- Regular security scans and updates
- Follow secure coding practices

### Production Security
- Implement proper authentication
- Use HTTPS for all communications
- Regular backup verification
- Monitor for security incidents

## 📚 Additional Resources

### Documentation
- Main project docs: `docs/`
- User guides: `docs/README.md`
- API documentation: Available at `/api/docs/`

### External Links
- Django Documentation: https://docs.djangoproject.com/
- React Documentation: https://reactjs.org/docs/
- Playwright Documentation: https://playwright.dev/
- Docker Documentation: https://docs.docker.com/

## 🤝 Contributing

### Development Guidelines
1. Follow existing code style and patterns
2. Write tests for new features
3. Update documentation for changes
4. Run validation before committing
5. Use meaningful commit messages

### Code Review Process
1. Create feature branch
2. Implement changes with tests
3. Run comprehensive test suite
4. Submit pull request
5. Address review feedback

## 📞 Support

### Getting Help
- Check troubleshooting guides first
- Review existing documentation
- Run diagnostic scripts
- Contact development team

### Reporting Issues
- Use GitHub issues for bug reports
- Include system information
- Provide reproduction steps
- Attach relevant logs

---

*This documentation is maintained by the development team and updated regularly. Last updated: September 2025*
