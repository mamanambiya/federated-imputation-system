#!/bin/bash

# Security Monitoring Script for Federated Genomic Imputation Platform
# Monitors system security status and alerts on threats

set -e

LOG_FILE="/var/log/security_monitor.log"
ALERT_FILE="/var/log/security_alerts.log"

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE"
}

# Function to log alerts
log_alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" | sudo tee -a "$ALERT_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" | sudo tee -a "$LOG_FILE"
}

echo "🔍 Starting Security Monitoring..."

# 1. Check for Failed Login Attempts
echo "🔐 Checking Failed Login Attempts..."
failed_logins=$(sudo grep "Failed password" /var/log/auth.log | tail -20 | wc -l)
if [ "$failed_logins" -gt 10 ]; then
    log_alert "High number of failed login attempts detected: $failed_logins"
fi

# 2. Check for Suspicious Network Connections
echo "🌐 Checking Network Connections..."
suspicious_connections=$(netstat -tuln | grep -E ":(22|23|25|53|80|110|143|443|993|995)" | wc -l)
log_message "Active network connections: $suspicious_connections"

# 3. Check for Unusual Processes
echo "🔄 Checking for Unusual Processes..."
# Check for cryptocurrency miners
miners=$(ps aux | grep -iE "(kinsing|kdevtmpfsi|xmrig|minerd|cpuminer)" | grep -v grep | wc -l)
if [ "$miners" -gt 0 ]; then
    log_alert "Cryptocurrency miner processes detected!"
    ps aux | grep -iE "(kinsing|kdevtmpfsi|xmrig|minerd|cpuminer)" | grep -v grep | sudo tee -a "$ALERT_FILE"
fi

# Check for suspicious processes
suspicious_procs=$(ps aux | grep -E "(nc|netcat|ncat|socat)" | grep -v grep | wc -l)
if [ "$suspicious_procs" -gt 0 ]; then
    log_alert "Suspicious network tools detected in running processes"
fi

# 4. Check System Load
echo "📊 Checking System Load..."
load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
if (( $(echo "$load_avg > 5.0" | bc -l) )); then
    log_alert "High system load detected: $load_avg"
fi

# 5. Check Disk Usage
echo "💾 Checking Disk Usage..."
disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 90 ]; then
    log_alert "High disk usage detected: ${disk_usage}%"
fi

# 6. Check for Rootkit Signatures
echo "🦠 Quick Rootkit Check..."
if command -v rkhunter >/dev/null 2>&1; then
    rkhunter_warnings=$(sudo rkhunter --check --sk --rwo 2>/dev/null | grep "Warning" | wc -l)
    if [ "$rkhunter_warnings" -gt 0 ]; then
        log_alert "Rootkit Hunter detected $rkhunter_warnings warnings"
    fi
fi

# 7. Check File Integrity
echo "📁 Checking Critical File Integrity..."
critical_files=(
    "/etc/passwd"
    "/etc/shadow"
    "/etc/group"
    "/etc/sudoers"
    "/etc/ssh/sshd_config"
    "/etc/hosts"
)

for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        current_hash=$(sha256sum "$file" | awk '{print $1}')
        hash_file="/var/lib/security_monitor/$(basename "$file").hash"
        
        if [ -f "$hash_file" ]; then
            stored_hash=$(cat "$hash_file")
            if [ "$current_hash" != "$stored_hash" ]; then
                log_alert "File integrity violation detected: $file"
            fi
        else
            # Create hash directory and store initial hash
            sudo mkdir -p /var/lib/security_monitor
            echo "$current_hash" | sudo tee "$hash_file" > /dev/null
        fi
    fi
done

# 8. Check Docker Security
echo "🐳 Checking Docker Security..."
if command -v docker >/dev/null 2>&1; then
    # Check for privileged containers
    privileged_containers=$(sudo docker ps --format "table {{.Names}}\t{{.Status}}" --filter "label=privileged=true" | wc -l)
    if [ "$privileged_containers" -gt 1 ]; then  # Subtract header line
        log_alert "Privileged Docker containers detected"
    fi
    
    # Check container resource usage
    container_count=$(sudo docker ps -q | wc -l)
    log_message "Running Docker containers: $container_count"
fi

# 9. Check Fail2ban Status
echo "🚫 Checking Fail2ban Status..."
if systemctl is-active fail2ban >/dev/null 2>&1; then
    banned_ips=$(sudo fail2ban-client status | grep "Jail list" | awk -F: '{print $2}' | wc -w)
    log_message "Fail2ban active jails: $banned_ips"
    
    # Check for recent bans
    recent_bans=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $4}' || echo "0")
    if [ "$recent_bans" -gt 0 ]; then
        log_alert "Active SSH bans detected: $recent_bans IPs"
    fi
else
    log_alert "Fail2ban service is not running!"
fi

# 10. Check for Suspicious Network Activity
echo "🔍 Checking Network Activity..."
# Check for unusual outbound connections
outbound_connections=$(netstat -tuln | grep ":80\|:443\|:8080\|:3000\|:8000" | wc -l)
log_message "Outbound web connections: $outbound_connections"

# Check for listening services
listening_services=$(netstat -tuln | grep LISTEN | wc -l)
log_message "Listening services: $listening_services"

# 11. Memory Usage Check
echo "🧠 Checking Memory Usage..."
memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ "$memory_usage" -gt 90 ]; then
    log_alert "High memory usage detected: ${memory_usage}%"
fi

# 12. Check for Unauthorized SUID Files
echo "🔓 Checking SUID Files..."
suid_count=$(find / -type f -perm -4000 2>/dev/null | wc -l)
log_message "SUID files found: $suid_count"

# Store current SUID list for comparison
current_suid_file="/var/lib/security_monitor/current_suid.list"
sudo mkdir -p /var/lib/security_monitor
find / -type f -perm -4000 2>/dev/null | sudo tee "$current_suid_file" > /dev/null

# 13. Generate Security Report
echo "📋 Generating Security Report..."
report_file="/var/log/security_report_$(date +%Y%m%d_%H%M%S).log"

{
    echo "=== SECURITY MONITORING REPORT ==="
    echo "Generated: $(date)"
    echo ""
    echo "System Information:"
    echo "- Hostname: $(hostname)"
    echo "- Uptime: $(uptime)"
    echo "- Load Average: $load_avg"
    echo "- Memory Usage: ${memory_usage}%"
    echo "- Disk Usage: ${disk_usage}%"
    echo ""
    echo "Security Status:"
    echo "- Failed Login Attempts (last 20): $failed_logins"
    echo "- Active Network Connections: $suspicious_connections"
    echo "- Suspicious Processes: $suspicious_procs"
    echo "- Cryptocurrency Miners: $miners"
    echo "- Running Containers: $container_count"
    echo "- SUID Files: $suid_count"
    echo ""
    echo "Service Status:"
    echo "- Fail2ban: $(systemctl is-active fail2ban)"
    echo "- SSH: $(systemctl is-active ssh)"
    echo "- UFW: $(sudo ufw status | head -1)"
    echo "- Auditd: $(systemctl is-active auditd 2>/dev/null || echo 'not installed')"
    echo ""
    echo "Recent Alerts:"
    if [ -f "$ALERT_FILE" ]; then
        tail -10 "$ALERT_FILE" 2>/dev/null || echo "No recent alerts"
    else
        echo "No alerts file found"
    fi
} | sudo tee "$report_file" > /dev/null

log_message "Security monitoring completed. Report saved to: $report_file"

# 14. Check if any alerts were generated
if [ -f "$ALERT_FILE" ] && [ -s "$ALERT_FILE" ]; then
    echo "⚠️  SECURITY ALERTS DETECTED!"
    echo "Check $ALERT_FILE for details"
    exit 1
else
    echo "✅ Security monitoring completed - no critical issues detected"
    exit 0
fi
