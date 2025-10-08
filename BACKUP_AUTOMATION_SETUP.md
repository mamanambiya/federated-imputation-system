# Automated Database Backup Setup

**Date**: October 7, 2025
**Status**: ✅ **ACTIVE**

## Overview

Automated database backups are now configured to run every 6 hours using cron. This ensures your microservices databases are regularly backed up with minimal manual intervention.

## Backup Schedule

### Cron Configuration
```bash
# Runs every 6 hours (12:00 AM, 6:00 AM, 12:00 PM, 6:00 PM UTC)
0 */6 * * * /home/ubuntu/federated-imputation-central/scripts/auto_backup_database.sh >> /home/ubuntu/federated-imputation-central/logs/auto_backup_cron.log 2>&1
```

### Backup Times (UTC)
- **00:00** (Midnight)
- **06:00** (6 AM)
- **12:00** (Noon)
- **18:00** (6 PM)

## What Gets Backed Up

Each backup run creates the following files:

1. **PostgreSQL Volume Backup**
   - Filename: `auto_backup_YYYYMMDD_HHMMSS_postgres.tar.gz`
   - Contains: Complete PostgreSQL data directory
   - Includes: All databases (service_registry_db, user_management_db, job_processing_db, federated_imputation)
   - Size: ~16MB (compressed)

2. **Redis Volume Backup**
   - Filename: `auto_backup_YYYYMMDD_HHMMSS_redis.tar.gz`
   - Contains: Redis persistence data
   - Size: ~4KB (compressed)

3. **SQL Dumps**
   - Filename: `auto_backup_YYYYMMDD_HHMMSS_all_databases.sql.gz`
   - Contains: Plain SQL dumps of all databases
   - Useful for: Selective restoration, cross-platform migration
   - Size: ~17KB (compressed)

4. **System State**
   - Filename: `auto_backup_YYYYMMDD_HHMMSS_state.txt`
   - Contains: Docker container status, volume info, timestamps
   - Useful for: Troubleshooting, audit trails

## Backup Location

```
/home/ubuntu/federated-imputation-central/backups/
```

## Retention Policy

- **Duration**: 30 days
- **Cleanup**: Automatic (handled by backup script)
- **Frequency**: 4 backups per day = 120 backups over 30 days
- **Estimated Storage**: ~2GB for 30 days of backups

## Log Files

### Cron Log
```bash
/home/ubuntu/federated-imputation-central/logs/auto_backup_cron.log
```

View recent backup activity:
```bash
tail -100 /home/ubuntu/federated-imputation-central/logs/auto_backup_cron.log
```

### Backup Script Output
Each backup run logs:
- Start/end timestamps
- Backup sizes
- Cleanup actions
- Error messages (if any)

## Manual Backup

To run a backup immediately (outside of the schedule):
```bash
/home/ubuntu/federated-imputation-central/scripts/auto_backup_database.sh
```

## Restore from Backup

### List Available Backups
```bash
ls -lht /home/ubuntu/federated-imputation-central/backups/auto_backup_*_postgres.tar.gz | head -10
```

### Restore Using Helper Script
```bash
# Interactive restore
./scripts/restore_backup.sh

# Direct restore
./scripts/restore_backup.sh auto_backup_20251007_212311
```

### Manual Restore
```bash
# Stop PostgreSQL
sudo docker-compose -f docker-compose.microservices.yml stop postgres

# Clear current data
sudo docker run --rm \
  -v federated-imputation-central_postgres_data:/data \
  alpine sh -c "rm -rf /data/*"

# Restore from backup
sudo docker run --rm \
  -v federated-imputation-central_postgres_data:/data \
  -v /home/ubuntu/federated-imputation-central/backups:/backup \
  alpine tar xzf "/backup/auto_backup_YYYYMMDD_HHMMSS_postgres.tar.gz" -C /data

# Restart PostgreSQL
sudo docker-compose -f docker-compose.microservices.yml start postgres
```

## Monitoring Backup Health

### Check Last Backup
```bash
ls -lt /home/ubuntu/federated-imputation-central/backups/auto_backup_*_postgres.tar.gz | head -1
```

### Verify Backup Age
```bash
# Should show backups within last 6 hours
find /home/ubuntu/federated-imputation-central/backups -name "auto_backup_*_postgres.tar.gz" -mmin -360 | wc -l
# Expected: At least 1 backup
```

### Check Disk Space
```bash
df -h /home/ubuntu/federated-imputation-central/backups
```

### Review Cron Logs for Errors
```bash
grep -i error /home/ubuntu/federated-imputation-central/logs/auto_backup_cron.log
```

## Troubleshooting

### Backup Not Running
1. **Check cron is active**:
   ```bash
   sudo systemctl status cron
   ```

2. **Verify cron job exists**:
   ```bash
   crontab -l | grep auto_backup_database.sh
   ```

3. **Check script permissions**:
   ```bash
   ls -l /home/ubuntu/federated-imputation-central/scripts/auto_backup_database.sh
   # Should show: -rwxrwxr-x (executable)
   ```

### Backup Failing
1. **Check logs**:
   ```bash
   tail -50 /home/ubuntu/federated-imputation-central/logs/auto_backup_cron.log
   ```

2. **Test manually**:
   ```bash
   /home/ubuntu/federated-imputation-central/scripts/auto_backup_database.sh
   ```

3. **Verify Docker access**:
   ```bash
   sudo docker ps
   ```

### Disk Space Full
1. **Clean old backups manually**:
   ```bash
   # Remove backups older than 30 days
   find /home/ubuntu/federated-imputation-central/backups -name "auto_backup_*" -mtime +30 -delete
   ```

2. **Adjust retention policy**:
   Edit [auto_backup_database.sh](scripts/auto_backup_database.sh:15) line 15:
   ```bash
   RETENTION_DAYS=30  # Change to lower number
   ```

## Integration with Existing Backups

Your system already has other backup scripts running:
- `backup_system.sh` - Daily full backups at 2:00 AM
- `database_stability_monitor.sh` - Database monitoring backups at 2:00 AM

The new `auto_backup_database.sh` complements these by:
- Running at **different times** (every 6 hours vs. daily)
- Backing up **microservices architecture** specifically
- Providing **more frequent** recovery points (4x per day)

## Best Practices

1. **Monitor Regularly**: Check logs weekly for any errors
2. **Test Restores**: Quarterly, test restoring from a backup to verify integrity
3. **Off-site Backup**: Consider copying backups to remote storage monthly
4. **Document Changes**: Update this file if you modify the schedule or retention policy

## Success Verification

✅ **All tasks completed successfully:**
- [x] Backup script tested and working (67MB backup created)
- [x] Cron job installed and scheduled
- [x] Log directory created
- [x] First manual backup successful
- [x] Next automatic backup scheduled for: **October 8, 2025 at 00:00 UTC**

---

**Setup completed by**: Claude Code
**Next automatic backup**: Check `/home/ubuntu/federated-imputation-central/logs/auto_backup_cron.log` after midnight UTC
**Contact**: Review logs or run manual backup to verify
