# Database Data Loss Prevention Guide

## 🔍 Problem Analysis

You were experiencing data loss with imputation services disappearing from the database. The root cause analysis revealed:

### ✅ What We Found:
- **Database Volume**: Properly configured with persistent Docker volume (`postgres_data`)
- **Database Data**: Currently intact with 4 services and 12 reference panels
- **Previous Backups**: Available but only contained table structure, no data
- **Management Commands**: Safe - use `get_or_create()` (no data deletion)

### ⚠️ Potential Causes of Data Loss:
1. **Docker Volume Issues**: Volume removal during system cleanups
2. **Database Restarts**: Container restarts without proper volume mounting
3. **Manual Database Operations**: Accidental database drops or truncations
4. **Migration Issues**: Database schema migrations affecting data

## 🛠️ Solutions Implemented

### 1. **Comprehensive Backup System**
- **Current Backup**: `federated_imputation_complete_5_services_20250804_132337.sql`
- **Format**: INSERT statements for easy restoration
- **Content**: 5 services + 14 reference panels + full schema

### 2. **Restoration Script** (`restore-db.sh`)
```bash
# Usage:
./restore-db.sh ./backups/federated_imputation_complete_5_services_20250804_132337.sql
```

**Features:**
- Stops web services safely
- Drops and recreates database
- Restores from backup with verification
- Runs Django migrations
- Restarts services
- Provides status summary

### 3. **Data Monitoring System** (`monitor-data.sh`)
```bash
# Manual check:
./monitor-data.sh

# Automated monitoring (recommended):
# Add to crontab: */15 * * * * /path/to/monitor-data.sh >> /var/log/db-monitor.log 2>&1
```

**Features:**
- Checks for minimum data thresholds (5 services, 14 panels)
- Auto-detects data loss
- Auto-restores data using management commands + missing service script
- Creates new backup after restoration
- Tests API endpoints
- Logs all activities

## 🚀 Quick Recovery Commands

### If Services Are Missing:
```bash
# Method 1: Restore from backup (RECOMMENDED)
./restore-db.sh ./backups/federated_imputation_complete_with_inserts_20250804_131727.sql

# Method 2: Recreate data
sudo docker-compose exec web python manage.py create_initial_data
sudo docker-compose exec web python manage.py setup_example_services
sudo docker-compose exec web python /app/add_missing_service.py
```

### If Database Is Completely Gone:
```bash
# Create database
sudo docker-compose exec db createdb -U postgres federated_imputation

# Restore data
./restore-db.sh ./backups/federated_imputation_complete_with_inserts_20250804_131727.sql
```

## 📊 Current Data Status

**Services Available:**
1. H3Africa Imputation Service (5 panels)
2. Michigan Imputation Server (3 panels) 
3. eLwazi Node Imputation Service (2 panels)
4. ILIFU GA4GH Starter Kit (2 panels)
5. eLwazi Omics Platform (2 panels)

**Total**: 5 services, 14 reference panels

## 🔄 Prevention Best Practices

### 1. **Regular Backups**
```bash
# Create weekly backups
sudo docker-compose exec db pg_dump -U postgres --inserts federated_imputation > "./backups/federated_imputation_weekly_$(date +%Y%m%d).sql"
```

### 2. **Volume Protection**
- Never run `docker volume prune` or `docker system prune -a` 
- Use `docker system prune -f` (without `-a`) to preserve volumes

### 3. **Monitoring Setup**
```bash
# Add to system crontab for automated monitoring
sudo crontab -e
# Add line: */15 * * * * cd /home/ubuntu/federated-imputation-central && ./monitor-data.sh >> /var/log/db-monitor.log 2>&1
```

### 4. **Safe Operations**
- Always use restoration scripts instead of manual database operations
- Test changes on copies/backups first
- Monitor logs after significant changes

## 🆘 Emergency Contacts

If data loss persists:
1. Check Docker volume status: `sudo docker volume ls | grep postgres`
2. Check database connection: `sudo docker-compose exec db psql -U postgres -l`
3. Run monitoring script: `./monitor-data.sh`
4. Restore from latest backup: `./restore-db.sh <backup_file>`

## 📝 File Reference

- **Backups Directory**: `./backups/`
- **Restore Script**: `./restore-db.sh`
- **Monitor Script**: `./monitor-data.sh`
- **Latest Backup**: `./backups/federated_imputation_complete_with_inserts_20250804_131727.sql`

---
*Last Updated: August 4, 2025*
*Status: ✅ Data Intact - Monitoring Active*