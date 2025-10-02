# Database Maintenance Guide
## Federated Genomic Imputation Platform

### 🔄 **Regular Backup Schedule**

```bash
# Create automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
sudo docker-compose exec -T db pg_dump -U postgres federated_imputation > "backups/auto_backup_${DATE}.sql"
echo "Backup created: auto_backup_${DATE}.sql"
```

### 🚨 **Database Recovery Commands**

```bash
# Quick restore from latest backup
sudo docker-compose exec -T db psql -U postgres -d federated_imputation < backups/federated_imputation_5_services_with_institutions_20250804_133932.sql

# Apply latest migrations
sudo docker-compose exec web python manage.py migrate

# Create admin user
sudo docker-compose exec web python manage.py shell -c "
from django.contrib.auth.models import User
u, created = User.objects.get_or_create(username='admin', defaults={'email': 'admin@example.com'})
u.set_password('admin123')
u.save()
print('Admin user ready')
"
```

### 📋 **Health Check Commands**

```bash
# Check database status
sudo docker-compose exec db psql -U postgres -d federated_imputation -c "SELECT COUNT(*) FROM imputation_imputationservice;"

# Verify API
curl -s http://localhost:8000/api/services/ | grep -o '"count":[0-9]*'

# Run full validation
./post_change_validation.sh
```

### 🔧 **Troubleshooting Steps**

1. **If database is empty**:
   - Restore from backup (see commands above)
   - Run migrations
   - Create users

2. **If containers won't start**:
   - Check Docker volumes: `sudo docker volume ls`
   - Restart services: `sudo docker-compose restart`

3. **If API returns errors**:
   - Check logs: `sudo docker-compose logs web`
   - Verify database connection
   - Run validation script

### 💾 **Data Integrity Verification**

Expected counts after restoration:
- Services: 5
- Reference Panels: 14
- Users: 2+ (admin + test_user)
- Roles: 1+

### 🎯 **Best Practices**

1. **Regular Backups**: Run backup script weekly
2. **Test Restoration**: Verify backups work monthly
3. **Monitor Health**: Run validation after changes
4. **Document Changes**: Keep track of modifications
