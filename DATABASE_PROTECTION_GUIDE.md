# 🛡️ Database Protection Guide

## What Happened: Database Replacement Incident (Oct 7, 2025)

### Root Cause Analysis

During a routine docker-compose restart, a **fresh PostgreSQL container was created** instead of connecting to the existing data volume. This resulted in:

❌ New empty databases being created
❌ Loss of access to existing data (though data was safely preserved in backups)
❌ Confusion about missing services and users

**Why This Happened:**
1. Docker Compose created a new volume when services restarted
2. The connection string used generic hostnames (no volume pinning)
3. No pre-flight checks were in place to warn about existing data
4. Automatic backups weren't running

### Your Data Was Safe

✅ **Full PostgreSQL volume backup existed:** `postgres_volume_20250804_202219.tar.gz` (13MB)
✅ **All data successfully restored:**
- 5 Imputation Services
- 14 Reference Panels
- User accounts and authentication
- Complete job history

---

## 🔒 Protection Systems Now in Place

### 1. Automated Backup System

**Script:** `scripts/auto_backup_database.sh`

**What it does:**
- Creates compressed backups of PostgreSQL volume
- Backs up Redis cache
- Creates SQL dumps for double protection
- Records system state
- Automatically cleans old backups (30-day retention)

**Usage:**
```bash
# Manual backup
./scripts/auto_backup_database.sh

# Automatic backups via cron (recommended)
# Add to crontab:
# 0 */6 * * * /home/ubuntu/federated-imputation-central/scripts/auto_backup_database.sh
```

### 2. Restoration Script

**Script:** `scripts/restore_backup.sh`

**What it does:**
- Lists available backups
- Creates safety backup before restore
- Restores PostgreSQL volume
- Fixes directory structures
- Verifies restoration success

**Usage:**
```bash
# List available backups
./scripts/restore_backup.sh

# Restore specific backup
./scripts/restore_backup.sh auto_backup_20251007_201500
```

### 3. Pre-Docker Safety Check

**Script:** `scripts/pre_docker_safety_check.sh`

**What it does:**
- Detects existing data before docker operations
- Creates automatic backup if data exists
- Warns before potentially destructive operations

**Usage:**
```bash
# Before docker-compose operations
./scripts/pre_docker_safety_check.sh && docker-compose up -d
```

---

## 🚨 Preventing Future Data Loss

### CRITICAL: Always Use These Commands

❌ **NEVER run these without backups:**
```bash
docker-compose down -v              # Deletes volumes!
docker volume rm <volume_name>      # Deletes data!
docker system prune -a --volumes    # Deletes everything!
```

✅ **ALWAYS use these safe practices:**
```bash
# Before any docker operation:
./scripts/pre_docker_safety_check.sh

# Safe docker-compose restart:
docker-compose restart

# Safe docker-compose rebuild:
docker-compose build && docker-compose up -d

# Manual backup before risky operations:
./scripts/auto_backup_database.sh
```

### Docker Compose Volume Protection

**Ensure your docker-compose.yml includes:**
```yaml
volumes:
  postgres_data:
    external: true  # Prevents accidental deletion
    name: federated-imputation-central_postgres_data
```

---

## 📋 Backup Schedule (Recommended)

### Automatic Backups via Cron

```bash
# Edit crontab
crontab -e

# Add these lines:

# Backup every 6 hours
0 */6 * * * /home/ubuntu/federated-imputation-central/scripts/auto_backup_database.sh >> /var/log/auto_backup.log 2>&1

# Weekly full system backup
0 2 * * 0 /home/ubuntu/federated-imputation-central/scripts/backup_automation.sh >> /var/log/weekly_backup.log 2>&1
```

### Backup Retention Policy

- **Hourly/6-hourly:** Keep for 7 days
- **Daily:** Keep for 30 days
- **Weekly:** Keep for 90 days
- **Monthly:** Keep for 1 year
- **Before deployments:** Keep indefinitely (tagged with feature name)

---

## 🔍 Monitoring Database Health

### Quick Health Check
```bash
# Check if database is running and accessible
docker exec federated-imputation-central_postgres_1 psql -U postgres -c "SELECT version();"

# Check database sizes
docker exec federated-imputation-central_postgres_1 psql -U postgres -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;"

# Count critical data
docker exec federated-imputation-central_postgres_1 psql -U postgres -d federated_imputation -c "
SELECT
  'Services' as type, COUNT(*) as count FROM imputation_imputationservice
UNION ALL
SELECT 'Panels', COUNT(*) FROM imputation_referencepanel
UNION ALL
SELECT 'Users', COUNT(*) FROM auth_user;
"
```

### Database Volume Location
```bash
# Find where data is physically stored
docker volume inspect federated-imputation-central_postgres_data | grep Mountpoint

# Check volume size
docker run --rm -v federated-imputation-central_postgres_data:/data alpine du -sh /data
```

---

## 🆘 Emergency Recovery Procedures

### Scenario 1: Accidentally Deleted Data

```bash
# 1. STOP all services immediately
docker-compose stop

# 2. List available backups
ls -lth /home/ubuntu/federated-imputation-central/backups/*_postgres.tar.gz | head -10

# 3. Restore from most recent backup
./scripts/restore_backup.sh auto_backup_20251007_201500

# 4. Verify data
docker exec federated-imputation-central_postgres_1 psql -U postgres -d federated_imputation -c "SELECT COUNT(*) FROM imputation_imputationservice;"
```

### Scenario 2: Database Corruption

```bash
# 1. Try PostgreSQL recovery first
docker exec federated-imputation-central_postgres_1 psql -U postgres -c "REINDEX DATABASE federated_imputation;"

# 2. If that fails, restore from backup
./scripts/restore_backup.sh <latest_good_backup>
```

### Scenario 3: Wrong Database Connected

```bash
# 1. Check what databases exist
docker exec federated-imputation-central_postgres_1 psql -U postgres -c "\l"

# 2. Check if federated_imputation exists
docker exec federated-imputation-central_postgres_1 psql -U postgres -d federated_imputation -c "\dt"

# 3. If empty or missing, restore
./scripts/restore_backup.sh <backup_name>
```

---

## 📊 Backup Verification

### Monthly Backup Test (Required)

```bash
# 1. Create test restore environment
docker run --name postgres-restore-test -e POSTGRES_PASSWORD=postgres -d postgres:15

# 2. Restore backup to test container
docker cp /home/ubuntu/federated-imputation-central/backups/auto_backup_XXXXXX_postgres.tar.gz postgres-restore-test:/tmp/

# 3. Verify data integrity
docker exec postgres-restore-test psql -U postgres -d federated_imputation -c "SELECT COUNT(*) FROM imputation_imputationservice;"

# 4. Clean up test container
docker rm -f postgres-restore-test
```

---

## 🎯 Key Takeaways

`★ Critical Lessons Learned ─────────────────────`

1. **Docker volumes persist independently** of containers
2. **Always backup before docker-compose down -v**
3. **Automated backups are essential** (not optional)
4. **Test your backups** monthly
5. **Use volume naming** to prevent conflicts
6. **Document your backup locations**
7. **Keep multiple backup generations**

`────────────────────────────────────────────────`

---

## 📞 Backup Locations

**Primary Backups:** `/home/ubuntu/federated-imputation-central/backups/`
**Volume Backups:** Look for `*_postgres.tar.gz` files
**SQL Dumps:** Look for `*.sql.gz` files
**State Records:** Look for `*_state.txt` files

**Current Restoration Status:**
- ✅ Database restored from: `postgres_volume_20250804_202219.tar.gz`
- ✅ 5 services confirmed
- ✅ 14 reference panels confirmed
- ✅ User accounts confirmed

---

## ✅ New Safeguards Checklist

Before ANY docker-compose operation:

- [ ] Run `./scripts/pre_docker_safety_check.sh`
- [ ] Verify current backups exist: `ls -lth backups/*_postgres.tar.gz | head -5`
- [ ] Understand what the docker command will do
- [ ] Have restoration procedure ready if needed
- [ ] Never use `-v` flag unless you want to delete volumes
- [ ] Test in staging/development first if possible

---

**Document Created:** October 7, 2025
**Incident:** Database replacement during docker-compose restart
**Resolution:** Full restoration from volume backup
**Prevention:** Automated backup system + safety checks implemented
**Status:** ✅ PROTECTED - Multiple safeguards in place
