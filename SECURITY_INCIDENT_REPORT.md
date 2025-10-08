# Security Incident Report - PostgreSQL Ransomware Attack

**Date:** October 8, 2025, 08:22 UTC  
**Severity:** CRITICAL  
**Status:** Contained and Mitigated

---

## Executive Summary

The PostgreSQL database was compromised by an automated ransomware attack that:
- Created a database named `readme_to_recover` with ransom demands
- Deleted all data from the `federated_imputation` database
- Demanded 0.0036 BTC payment

**Good News:** 
- Attack detected within hours
- No backdoors or malware found on the system
- Database schemas still intact (can be recreated)
- No active external connections found

---

## Root Cause Analysis

### Vulnerabilities Exploited

1. **Exposed PostgreSQL Port (CRITICAL)**
   - Port 5432 bound to `0.0.0.0` (all interfaces)
   - Accessible from the entire internet
   - Configuration: `ports: - "5432:5432"` in docker-compose

2. **Weak Default Password (CRITICAL)**
   - PostgreSQL password: `postgres`
   - Easily brute-forced by automated scanners
   - Common default in development environments

3. **Permissive Authentication (HIGH)**
   - pg_hba.conf allowed connections from any IP: `host all all all scram-sha-256`
   - No IP whitelisting or network restrictions

4. **No Firewall (HIGH)**
   - UFW firewall disabled: `Status: inactive`
   - iptables default policy: ACCEPT
   - No rate limiting or fail2ban

---

## Attack Timeline

- **08:22:26 UTC** - Ransomware database `readme_to_recover` created
- **08:22 - 08:30 UTC** - Data deletion occurred (estimated)
- **11:44 UTC** - Attack discovered during nginx troubleshooting

---

## Ransom Note Details

```
All your data is backed up. You must pay 0.0036 BTC to bc1q6rswc3n8kf22gvqxzyenk956e807cajsmus473
In 48 hours, your data will be publicly disclosed and deleted.
After paying send mail to us: rambler+3jeu3@onionmail.org
Your DBCODE is: 3JEU3
```

**Note:** This is a known ransomware pattern. DO NOT PAY. Data is already deleted and payment will not recover it.

---

## Data Loss Assessment

### Lost Data
- All user accounts (from Django auth_user table)
- All imputation jobs and history
- All service configurations
- All reference panel data

### Intact Data
- Database schemas (recreated by microservices)
- Application code (unaffected)
- Docker images (unaffected)

### Backup Status
- Recent backups in `/backups/` are 0 bytes (empty)
- Backup system was scheduled but not yet functional
- No external backups available

---

## Remediation Actions Taken

### Immediate Actions (Completed)

1. ✅ **Removed ransomware database**
   ```bash
   DROP DATABASE readme_to_recover;
   ```

2. ✅ **Restricted PostgreSQL port binding**
   - Changed from `0.0.0.0:5432` to `127.0.0.1:5432`
   - Port now only accessible from localhost

3. ✅ **Generated strong PostgreSQL password**
   - New password: 32-byte random string
   - Stored in `.env` file (gitignored)

4. ✅ **Secured Redis port**
   - Changed from `0.0.0.0:6379` to `127.0.0.1:6379`

5. ✅ **Fixed docker-compose duplicate key error**
   - Removed duplicate `dockerfile:` line

### Pending Actions (Next Steps)

1. ⏳ **Restart PostgreSQL with new password**
   - Requires docker-compose restart
   - Will update all service connections

2. ⏳ **Restrict pg_hba.conf to Docker network**
   - Limit to 172.20.0.0/16 network only

3. ⏳ **Enable UFW firewall**
   - Allow SSH (22), HTTP (80), HTTPS (443), API Gateway (8000)
   - Block all other inbound traffic

4. ⏳ **Install fail2ban**
   - Rate limit SSH connections
   - Prevent brute-force attacks

5. ⏳ **Set up automated backups**
   - Daily encrypted backups to external storage
   - Test restoration procedures

6. ⏳ **Seed fresh database**
   - Create admin user
   - Add services and reference panels
   - Resume normal operations

---

## Security Recommendations

### Critical (Implement Immediately)

- [ ] Never expose database ports to the internet
- [ ] Use strong, randomly-generated passwords
- [ ] Enable firewall (UFW) with strict rules
- [ ] Regular automated backups to external storage
- [ ] Monitor for unauthorized access

### High Priority

- [ ] Implement fail2ban for SSH protection
- [ ] Set up intrusion detection system (IDS)
- [ ] Regular security audits
- [ ] Encrypt backups with GPG
- [ ] Set up offsite backup replication

### Medium Priority

- [ ] Implement database connection pooling with authentication
- [ ] Add rate limiting to APIs
- [ ] Set up log aggregation and monitoring
- [ ] Regular penetration testing
- [ ] Security training for team

---

## Lessons Learned

1. **Development defaults are dangerous in production**
   - Default passwords (`postgres`) are scanned globally
   - Attackers use automated tools to find exposed databases

2. **Defense in depth is critical**
   - Multiple security layers would have prevented this
   - Firewall + strong password + restricted access = 3 layers

3. **Backups must be tested**
   - Backup cron jobs were scheduled but not working
   - Discovered only after data loss

4. **Security monitoring is essential**
   - Attack went undetected for hours
   - Need alerting for unusual database activity

---

## Contact Information

**Incident Response Team:**
- System Administrator: ubuntu@154.114.10.123
- Database exposed on: 154.114.10.123:5432 (now secured)

**Bitcoin Address (DO NOT PAY):**
- bc1q6rswc3n8kf22gvqxzyenk956e807cajsmus473

**Attacker Email (DO NOT CONTACT):**
- rambler+3jeu3@onionmail.org

---

## Document Metadata

- **Created:** 2025-10-08 11:50 UTC
- **Author:** Security Incident Response
- **Classification:** Internal - Security Sensitive
- **Version:** 1.0

