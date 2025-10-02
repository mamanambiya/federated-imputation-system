#!/bin/bash

# Setup Database Monitoring - Install automated monitoring system
# This script sets up cron jobs and systemd services for database monitoring

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔧 Setting up Database Monitoring System..."

# Create log directories
sudo mkdir -p /var/log
sudo touch /var/log/database_stability.log
sudo touch /var/log/database_alerts.log
sudo chmod 644 /var/log/database_stability.log
sudo chmod 644 /var/log/database_alerts.log

# Setup cron job for regular database checks
echo "📅 Setting up cron job for database monitoring..."
CRON_JOB="*/15 * * * * cd $PROJECT_ROOT && ./scripts/database_stability_monitor.sh check >> /var/log/database_cron.log 2>&1"

# Add cron job if it doesn't exist
(crontab -l 2>/dev/null | grep -v "database_stability_monitor.sh"; echo "$CRON_JOB") | crontab -

# Setup daily backup cron job
BACKUP_CRON="0 2 * * * cd $PROJECT_ROOT && ./scripts/database_stability_monitor.sh backup >> /var/log/database_backup_cron.log 2>&1"
(crontab -l 2>/dev/null | grep -v "database_stability_monitor.sh backup"; echo "$BACKUP_CRON") | crontab -

# Setup weekly health report
REPORT_CRON="0 8 * * 1 cd $PROJECT_ROOT && ./scripts/database_stability_monitor.sh report >> /var/log/database_report_cron.log 2>&1"
(crontab -l 2>/dev/null | grep -v "database_stability_monitor.sh report"; echo "$REPORT_CRON") | crontab -

echo "✅ Cron jobs configured:"
echo "  - Database check: Every 15 minutes"
echo "  - Automatic backup: Daily at 2 AM"
echo "  - Health report: Weekly on Monday at 8 AM"

# Create systemd service for continuous monitoring (optional)
echo "🔧 Creating systemd service for database monitoring..."

sudo tee /etc/systemd/system/database-monitor.service > /dev/null << EOF
[Unit]
Description=Database Stability Monitor
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$PROJECT_ROOT
ExecStart=$PROJECT_ROOT/scripts/database_stability_monitor.sh monitor
Restart=always
RestartSec=30
StandardOutput=append:/var/log/database_monitor_service.log
StandardError=append:/var/log/database_monitor_service.log

[Install]
WantedBy=multi-user.target
EOF

# Create logrotate configuration
echo "📋 Setting up log rotation..."
sudo tee /etc/logrotate.d/database-monitoring > /dev/null << EOF
/var/log/database_stability.log
/var/log/database_alerts.log
/var/log/database_cron.log
/var/log/database_backup_cron.log
/var/log/database_report_cron.log
/var/log/database_monitor_service.log
/var/log/database_health_*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF

# Setup alerting script
echo "🚨 Setting up alerting system..."
cat > "$PROJECT_ROOT/scripts/database_alert_handler.sh" << 'EOF'
#!/bin/bash

# Database Alert Handler - Process and send alerts
ALERT_FILE="/var/log/database_alerts.log"
LAST_CHECK_FILE="/tmp/database_alert_last_check"

# Get timestamp of last check
if [ -f "$LAST_CHECK_FILE" ]; then
    LAST_CHECK=$(cat "$LAST_CHECK_FILE")
else
    LAST_CHECK="1970-01-01 00:00:00"
fi

# Update last check timestamp
date '+%Y-%m-%d %H:%M:%S' > "$LAST_CHECK_FILE"

# Check for new alerts since last check
if [ -f "$ALERT_FILE" ]; then
    NEW_ALERTS=$(awk -v last_check="$LAST_CHECK" '$0 > last_check' "$ALERT_FILE")
    
    if [ -n "$NEW_ALERTS" ]; then
        echo "🚨 NEW DATABASE ALERTS DETECTED:"
        echo "$NEW_ALERTS"
        
        # Here you can add email notifications, Slack webhooks, etc.
        # Example: echo "$NEW_ALERTS" | mail -s "Database Alert" admin@example.com
        
        # Log to system log
        echo "$NEW_ALERTS" | logger -t "database-monitor"
    fi
fi
EOF

chmod +x "$PROJECT_ROOT/scripts/database_alert_handler.sh"

# Setup alert checking cron job
ALERT_CRON="*/5 * * * * $PROJECT_ROOT/scripts/database_alert_handler.sh >> /var/log/database_alert_handler.log 2>&1"
(crontab -l 2>/dev/null | grep -v "database_alert_handler.sh"; echo "$ALERT_CRON") | crontab -

# Reload systemd and enable service (but don't start it automatically)
sudo systemctl daemon-reload
sudo systemctl enable database-monitor.service

echo "✅ Database monitoring system setup complete!"
echo ""
echo "📊 Monitoring Components Installed:"
echo "  ✅ Database stability monitor script"
echo "  ✅ Cron jobs for automated checks"
echo "  ✅ Systemd service for continuous monitoring"
echo "  ✅ Log rotation configuration"
echo "  ✅ Alert handling system"
echo ""
echo "🔧 Management Commands:"
echo "  Start continuous monitoring: sudo systemctl start database-monitor"
echo "  Stop continuous monitoring:  sudo systemctl stop database-monitor"
echo "  Check monitoring status:     sudo systemctl status database-monitor"
echo "  View monitoring logs:        tail -f /var/log/database_stability.log"
echo "  View alerts:                 tail -f /var/log/database_alerts.log"
echo ""
echo "📋 Scheduled Tasks:"
echo "  - Database health check: Every 15 minutes"
echo "  - Automatic backup: Daily at 2 AM"
echo "  - Health report: Weekly on Monday at 8 AM"
echo "  - Alert processing: Every 5 minutes"
echo ""
echo "🎯 Next Steps:"
echo "  1. Test the monitoring: ./scripts/database_stability_monitor.sh check"
echo "  2. Generate health report: ./scripts/database_stability_monitor.sh report"
echo "  3. Start continuous monitoring: sudo systemctl start database-monitor"
