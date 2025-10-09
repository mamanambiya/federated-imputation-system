# Quick Reference: Container Management

## Current Status: ✅ STABLE (Restart policies added)

---

## Emergency Commands

### Check System Health
```bash
# Are services running?
docker ps | grep -E "api-gateway|user-service|service-registry|job-processor|file-manager|monitoring|frontend"

# Test API
curl http://localhost:8000/api/services/

# Test Frontend
curl http://154.114.10.184:3000
```

### Restart a Service
```bash
# Current system (manual containers)
docker restart federated-imputation-central_service-registry_1

# After migration (docker-compose)
docker-compose -f docker-compose.production.yml restart service-registry
```

### View Logs
```bash
# Current system
docker logs -f federated-imputation-central_api-gateway_1

# After migration
docker-compose -f docker-compose.production.yml logs -f api-gateway
```

---

## Migration Commands

### Run Migration
```bash
cd /home/ubuntu/federated-imputation-central
sudo ./scripts/migrate_to_compose.sh
```

### Rollback if Needed
```bash
# Find backup directory
ls -la backups/

# Rollback
sudo ./scripts/rollback_migration.sh backups/migration_YYYYMMDD_HHMMSS
```

---

## Important Files

| File | What It Is |
|------|------------|
| `.env` | Passwords and secrets (JWT_SECRET, POSTGRES_PASSWORD) |
| `docker-compose.production.yml` | Production docker-compose config |
| `MIGRATION_GUIDE.md` | Complete migration instructions |
| `SOLUTION_SUMMARY.md` | Everything you need to know |

---

## What Happened?

1. System rebooted at 00:20
2. Manual containers didn't restart (no restart policy)
3. Frontend appeared empty (backend down)
4. **Fix applied**: Added restart policies to all containers ✅
5. **Permanent fix ready**: Docker compose migration scripts ✅

---

## Admin Credentials

**Username**: `admin`
**Password**: `+Y9fP1EonNj+7jmLMfKMjscvcxADkzFB`

---

## Next Steps

1. ✅ **DONE**: System working with restart policies
2. 🎯 **TODO**: Migrate to docker-compose (next maintenance window)
3. 📚 **READ**: MIGRATION_GUIDE.md before migration

---

**Last Updated**: 2025-10-09 02:00 UTC
**System Status**: Operational ✅
**Reboot Safe**: Yes ✅
