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
