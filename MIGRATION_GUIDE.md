# Migration Guide: Manual Containers → Docker Compose

**Status**: Ready to execute
**Risk Level**: Low (rollback available)
**Estimated Time**: 15 minutes
**Downtime**: ~2 minutes

---

## What This Migration Does

Converts your system from **manually created containers** to **docker-compose managed services**.

### Benefits

✅ **Automatic restart after reboot** - Never lose services again
✅ **Configuration in version control** - Easy to reproduce
✅ **Simple operations** - Single command to start/stop/restart
✅ **Professional deployment** - Industry standard approach
✅ **Easy rollback** - Can undo if needed

---

## Prerequisites Checklist

Before running migration, verify:

- [ ] `.env` file has correct JWT_SECRET (✅ already updated)
- [ ] `docker-compose.production.yml` exists (✅ created)
- [ ] Migration script is executable: `ls -l scripts/migrate_to_compose.sh`
- [ ] Rollback script is executable: `ls -l scripts/rollback_migration.sh`
- [ ] Current system is working: `curl http://localhost:8000/api/services/`
- [ ] You have recent database backup

---

## Migration Steps

### Option A: Full Automated Migration (Recommended)

```bash
# Run the migration script
cd /home/ubuntu/federated-imputation-central
sudo ./scripts/migrate_to_compose.sh
```

The script will:
1. ✅ Verify prerequisites (.env, compose file, etc.)
2. 📁 Create backup of current state
3. ⏸️  Stop manual containers
4. 🗑️  Remove manual containers (keeps images!)
5. 🚀 Build and start via docker-compose
6. 🏥 Run health checks
7. ✅ Report success or failures

**Total time**: ~5 minutes
**Downtime**: ~2 minutes (during container restart)

---

### Option B: Manual Step-by-Step (For Testing)

If you want more control:

#### 1. Verify Current State

```bash
# Check what's running
docker ps --format "table {{.Names}}\t{{.Status}}"

# Test API
curl http://localhost:8000/api/services/ | jq .
```

#### 2. Create Backup

```bash
# Backup current container configs
mkdir -p backups/manual_backup_$(date +%Y%m%d)
docker ps -a > backups/manual_backup_$(date +%Y%m%d)/containers.txt

# Export container configs
for c in $(docker ps --format "{{.Names}}" | grep federated); do
    docker inspect $c > backups/manual_backup_$(date +%Y%m%d)/${c}.json
done
```

#### 3. Stop and Remove Manual Containers

```bash
# Stop containers
docker stop \
  federated-imputation-central_api-gateway_1 \
  federated-imputation-central_user-service_1 \
  federated-imputation-central_service-registry_1 \
  federated-imputation-central_job-processor_1 \
  federated-imputation-central_file-manager_1 \
  federated-imputation-central_monitoring_1 \
  frontend-updated

# Remove containers (keeps images)
docker rm \
  federated-imputation-central_api-gateway_1 \
  federated-imputation-central_user-service_1 \
  federated-imputation-central_service-registry_1 \
  federated-imputation-central_job-processor_1 \
  federated-imputation-central_file-manager_1 \
  federated-imputation-central_monitoring_1 \
  frontend-updated
```

#### 4. Start via Docker Compose

```bash
# Build images
sudo docker-compose -f docker-compose.production.yml build

# Start services
sudo docker-compose -f docker-compose.production.yml up -d

# View logs
sudo docker-compose -f docker-compose.production.yml logs -f
```

#### 5. Verify

```bash
# Wait for services to start
sleep 30

# Check status
sudo docker-compose -f docker-compose.production.yml ps

# Test API
curl http://localhost:8000/api/services/ | jq .

# Test frontend
curl http://localhost:3000/

# Test dashboard
curl http://localhost:8000/api/dashboard/stats/ | jq .
```

---

## Post-Migration Operations

### Managing Services

```bash
# View all services
docker-compose -f docker-compose.production.yml ps

# View logs (all services)
docker-compose -f docker-compose.production.yml logs -f

# View logs (specific service)
docker-compose -f docker-compose.production.yml logs -f api-gateway

# Restart a service
docker-compose -f docker-compose.production.yml restart service-registry

# Rebuild and restart a service
docker-compose -f docker-compose.production.yml up -d --build job-processor

# Stop all services
docker-compose -f docker-compose.production.yml down

# Start all services
docker-compose -f docker-compose.production.yml up -d
```

### Scaling Services

```bash
# Scale celery workers
docker-compose -f docker-compose.production.yml up -d --scale celery-worker=4
```

### Updating a Service

```bash
# 1. Make code changes
vim microservices/api-gateway/main.py

# 2. Rebuild and restart
docker-compose -f docker-compose.production.yml up -d --build api-gateway

# 3. Check logs
docker-compose -f docker-compose.production.yml logs -f api-gateway
```

---

## Rollback Procedure

If something goes wrong:

### Automatic Rollback

```bash
# Find your backup directory
ls -la backups/

# Run rollback script
sudo ./scripts/rollback_migration.sh backups/migration_YYYYMMDD_HHMMSS
```

### Manual Rollback

```bash
# Stop docker-compose services
sudo docker-compose -f docker-compose.production.yml down

# Recreate manual containers with current production config
# (The rollback script has all the commands)
./scripts/rollback_migration.sh
```

---

## Troubleshooting

### Problem: Services Won't Start

```bash
# Check logs
docker-compose -f docker-compose.production.yml logs

# Check specific service
docker-compose -f docker-compose.production.yml logs service-registry

# Check if database is running
docker ps | grep postgres
```

### Problem: Database Connection Errors

```bash
# Check DATABASE_URL in .env
cat .env | grep POSTGRES

# Verify databases exist
docker exec federated-imputation-central_db_1 psql -U postgres -c "\l"

# Check if services can reach DB
docker-compose -f docker-compose.production.yml exec service-registry env | grep DATABASE_URL
```

### Problem: JWT Validation Fails

```bash
# Verify JWT_SECRET in .env
cat .env | grep JWT_SECRET

# Check if all services have same secret
docker-compose -f docker-compose.production.yml exec api-gateway env | grep JWT_SECRET
docker-compose -f docker-compose.production.yml exec user-service env | grep JWT_SECRET
docker-compose -f docker-compose.production.yml exec job-processor env | grep JWT_SECRET
```

### Problem: Frontend Shows 404

```bash
# Check if nginx config is mounted
docker-compose -f docker-compose.production.yml exec frontend ls -la /etc/nginx/conf.d/

# Check if build files are mounted
docker-compose -f docker-compose.production.yml exec frontend ls -la /usr/share/nginx/html/
```

---

## Testing Checklist

After migration, verify:

- [ ] Frontend loads: http://154.114.10.184:3000
- [ ] Can login with admin credentials
- [ ] Services page shows 5 services
- [ ] Dashboard shows correct stats
- [ ] Jobs page loads without errors
- [ ] Can create new job (test with sample data)
- [ ] System survives restart: `sudo reboot` then check after 5 minutes

---

## Clean Up After Successful Migration

Once you've verified everything works for 24 hours:

```bash
# Remove migration backups
rm -rf backups/migration_*/

# Optional: Remove old manual container images
# (Be careful - only do this if you're confident)
docker images | grep federated-imputation
# docker rmi [image-id]  # Only if not needed
```

---

## Future Deployments

After migration, your deployment workflow becomes:

```bash
# 1. Pull latest code
git pull origin main

# 2. Update if needed
vim docker-compose.production.yml
vim .env

# 3. Rebuild and restart services
sudo docker-compose -f docker-compose.production.yml up -d --build

# 4. Check logs
sudo docker-compose -f docker-compose.production.yml logs -f

# 5. Verify health
curl http://localhost:8000/api/services/
```

---

## Important Notes

### Network Configuration

The docker-compose setup creates two networks:
- `federated-imputation-central_default` - For DB connections
- `federated-imputation-central_microservices-network` - For service-to-service

Some services need both networks (this is intentional and matches current setup).

### Database Names

⚠️ **Important**: The production system uses different database names than the original docker-compose.microservices.yml:

- `job-processor`: Uses `federated_imputation` (not `job_processing_db`)
- `monitoring`: Uses `federated_imputation` (not `monitoring_db`)

This is reflected in `docker-compose.production.yml`.

### Restart Policies

All services now have `restart: unless-stopped`, meaning:
- ✅ Auto-restart on failure
- ✅ Auto-start after system reboot
- ⏹️  Won't restart if you manually stop them

---

## Next Steps After Migration

1. **Update documentation**: Mark old docker run commands as deprecated
2. **Set up monitoring**: Add proper monitoring/alerting
3. **CI/CD pipeline**: Automate deployments
4. **Backups**: Ensure database backups are automated
5. **Security**: Review and update security configurations

---

## Support

If you encounter issues:

1. Check the migration log: `backups/migration_YYYYMMDD_HHMMSS/migration.log`
2. Review troubleshooting section above
3. Check docker-compose logs: `docker-compose -f docker-compose.production.yml logs`
4. Use rollback if needed: `./scripts/rollback_migration.sh [backup-dir]`

---

**Migration Guide Version**: 1.0
**Last Updated**: 2025-10-09
**Tested**: ✅ Scripts created and validated
**Status**: Ready for execution
