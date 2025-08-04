# 🔧 Automated Database Monitoring Setup

## ✅ **Setup Completed Successfully!**

This document records the successful configuration of automated database monitoring for the Federated Genomic Imputation Platform.

---

## 🔧 **Configuration Details**

### **Cron Job Configuration**
```bash
# Cron Schedule: Every 15 minutes
*/15 * * * * /home/ubuntu/federated-imputation-central/monitor-data.sh >> /var/log/db-monitor.log 2>&1
```

### **File Locations**
- **Monitoring Script**: `/home/ubuntu/federated-imputation-central/monitor-data.sh`
- **Log File**: `/var/log/db-monitor.log`
- **Backup Directory**: `./backups/`

### **Permissions**
- Script: Executable by ubuntu user (`-rwxrwxr-x`)
- Log file: Writable by ubuntu user
- Cron service: Active and running

---

## 🔍 **Monitoring Capabilities**

### **Data Integrity Checks**
- ✅ **5 Services**: H3Africa, Michigan, eLwazi Node, ILIFU, eLwazi Omics
- ✅ **14 Reference Panels**: Distributed across all services
- ✅ **Minimum Thresholds**: Configurable in `monitor-data.sh`

### **Auto-Detection & Recovery**
- **Data Loss Detection**: Compares current counts vs. expected minimums
- **Auto-Restoration**: Executes management commands if data is missing
  - `python manage.py create_initial_data`
  - `python manage.py setup_example_services`
  - `python manage.py add_elwazi_omics`
- **Backup Creation**: New SQL dump after successful restoration

### **API Health Monitoring**
- **Frontend Check**: `http://localhost:3000/` (React app)
- **Backend Check**: `http://localhost:8000/` (Django API)
- **Response Validation**: HTTP 200 status expected

---

## 📊 **Current System Status**

### **Services (5 Total)**
1. **H3Africa Imputation Service** - `H3Africa Consortium, Pan-African Network`
2. **Michigan Imputation Server** - `University of Michigan, Ann Arbor, Michigan, USA`
3. **eLwazi Node Imputation Service** - `University of Sciences, Techniques and Technologies of Bamako, Bamako, Mali`
4. **ILIFU GA4GH Starter Kit** - `University of Cape Town, Cape Town, South Africa`
5. **eLwazi Omics Platform** - `Witwatersrand University, Johannesburg, South Africa`

### **Reference Panels (14 Total)**
- H3Africa: 5 panels
- Michigan: 3 panels
- eLwazi Node: 2 panels
- ILIFU: 2 panels
- eLwazi Omics: 2 panels

### **System Health**
- ✅ **Cron Service**: Active (running since Thu 2025-07-31)
- ✅ **Database**: All data present and accessible
- ✅ **Frontend API**: Responding correctly (HTTP 200)
- ✅ **Backend API**: Responding correctly (HTTP 200)

---

## 🛠️ **Management Commands**

### **Monitor System Status**
```bash
# View real-time logs
tail -f /var/log/db-monitor.log

# Manual monitoring check
./monitor-data.sh

# Check cron configuration
crontab -l

# Verify cron service
sudo systemctl status cron
```

### **Maintenance Operations**
```bash
# Edit monitoring schedule
crontab -e

# Clear log file
sudo truncate -s 0 /var/log/db-monitor.log

# Test script manually
./monitor-data.sh

# View log file permissions
ls -la /var/log/db-monitor.log
```

---

## ⏰ **Automation Schedule**

- **Frequency**: Every 15 minutes (24/7 monitoring)
- **Next Check**: Within 15 minutes of setup completion
- **Log Rotation**: Manual (consider setting up logrotate for production)
- **Retention**: Logs accumulate until manually cleared

---

## 🎯 **Benefits**

### **Proactive Monitoring**
- **24/7 Surveillance**: Continuous data integrity monitoring
- **Early Detection**: Issues identified within 15 minutes
- **Zero Downtime**: Auto-recovery without user intervention

### **Self-Healing System**
- **Automatic Recovery**: Data restoration without manual intervention
- **Backup Generation**: New backups created after successful recovery
- **Service Validation**: API endpoints tested after restoration

### **Operational Visibility**
- **Comprehensive Logging**: All activities recorded with timestamps
- **Status Reporting**: Clear success/failure indicators
- **Historical Tracking**: Log file provides audit trail

---

## 📝 **Setup Date & Version**

- **Setup Date**: August 4, 2025
- **System**: Ubuntu 5.15.0-151-generic
- **User**: ubuntu
- **Working Directory**: `/home/ubuntu/federated-imputation-central`
- **Initial Test**: ✅ Successful (5 services, 14 panels detected)

---

## 🔒 **Security & Reliability**

- **User Permissions**: Script runs as ubuntu user (non-root)
- **Log Security**: Log file owned by ubuntu user
- **Error Handling**: Script includes error handling and status reporting
- **Service Isolation**: Docker containers provide service isolation

---

The automated monitoring system is now **fully operational** and will maintain database integrity without manual intervention.