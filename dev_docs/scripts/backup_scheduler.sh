#!/bin/bash

# Federated Genomic Imputation Platform - Backup Scheduler
# Automated backup scheduling with cron integration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_SCRIPT="$SCRIPT_DIR/backup_system.sh"
CRON_FILE="/tmp/federated_imputation_cron"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Install backup scheduler
install_scheduler() {
    log "${GREEN}Installing backup scheduler...${NC}"
    
    # Check if backup script exists
    if [[ ! -f "$BACKUP_SCRIPT" ]]; then
        echo -e "${RED}Error: Backup script not found at $BACKUP_SCRIPT${NC}"
        exit 1
    fi
    
    # Make backup script executable
    chmod +x "$BACKUP_SCRIPT"
    
    # Get current crontab
    crontab -l 2>/dev/null > "$CRON_FILE" || touch "$CRON_FILE"
    
    # Remove existing federated imputation backup entries
    grep -v "federated.*imputation.*backup" "$CRON_FILE" > "${CRON_FILE}.tmp" || true
    mv "${CRON_FILE}.tmp" "$CRON_FILE"
    
    # Add new backup schedule
    cat >> "$CRON_FILE" << EOF

# Federated Genomic Imputation Platform - Automated Backups
# Daily full backup at 2:00 AM
0 2 * * * $BACKUP_SCRIPT backup full >> $PROJECT_ROOT/logs/backup_cron.log 2>&1

# Incremental backup every 6 hours (6 AM, 12 PM, 6 PM)
0 6,12,18 * * * $BACKUP_SCRIPT backup incremental >> $PROJECT_ROOT/logs/backup_cron.log 2>&1

# Weekly backup rotation (Sunday at 3:00 AM)
0 3 * * 0 $BACKUP_SCRIPT rotate >> $PROJECT_ROOT/logs/backup_cron.log 2>&1

# Daily backup verification (4:00 AM) - verify latest backup
0 4 * * * find $PROJECT_ROOT/backups -name "db_full_*.sql.gz" -type f -mtime -1 -exec $BACKUP_SCRIPT verify {} \; >> $PROJECT_ROOT/logs/backup_cron.log 2>&1

EOF
    
    # Install new crontab
    crontab "$CRON_FILE"
    rm "$CRON_FILE"
    
    # Create log directory
    mkdir -p "$PROJECT_ROOT/logs"
    
    log "${GREEN}✅ Backup scheduler installed successfully!${NC}"
    echo ""
    echo "Backup Schedule:"
    echo "  - Full backup: Daily at 2:00 AM"
    echo "  - Incremental backup: Every 6 hours (6 AM, 12 PM, 6 PM)"
    echo "  - Backup rotation: Weekly on Sunday at 3:00 AM"
    echo "  - Backup verification: Daily at 4:00 AM"
    echo ""
    echo "Logs will be written to: $PROJECT_ROOT/logs/backup_cron.log"
}

# Uninstall backup scheduler
uninstall_scheduler() {
    log "${YELLOW}Uninstalling backup scheduler...${NC}"
    
    # Get current crontab
    crontab -l 2>/dev/null > "$CRON_FILE" || touch "$CRON_FILE"
    
    # Remove federated imputation backup entries
    grep -v "federated.*imputation.*backup" "$CRON_FILE" > "${CRON_FILE}.tmp" || true
    grep -v "$BACKUP_SCRIPT" "${CRON_FILE}.tmp" > "$CRON_FILE" || true
    
    # Install cleaned crontab
    crontab "$CRON_FILE"
    rm "$CRON_FILE"
    
    log "${GREEN}✅ Backup scheduler uninstalled${NC}"
}

# Show current schedule
show_schedule() {
    echo -e "${GREEN}=== Current Backup Schedule ===${NC}"
    echo ""
    
    if crontab -l 2>/dev/null | grep -q "federated.*imputation"; then
        echo "Active backup jobs:"
        crontab -l | grep -A 10 -B 2 "federated.*imputation" || true
        echo ""
        
        # Show next run times
        echo "Next scheduled runs:"
        echo "  Full backup: $(date -d 'tomorrow 02:00' '+%Y-%m-%d %H:%M')"
        echo "  Next incremental: $(date -d 'today 18:00' '+%Y-%m-%d %H:%M' 2>/dev/null || date -d 'tomorrow 06:00' '+%Y-%m-%d %H:%M')"
        echo ""
        
        # Show recent log entries
        if [[ -f "$PROJECT_ROOT/logs/backup_cron.log" ]]; then
            echo "Recent backup activity:"
            tail -10 "$PROJECT_ROOT/logs/backup_cron.log" | grep -E "(SUCCESS|ERROR|INFO)" || echo "No recent activity"
        fi
    else
        echo -e "${YELLOW}No backup schedule installed${NC}"
        echo "Run '$0 install' to set up automated backups"
    fi
}

# Test backup schedule
test_schedule() {
    log "${GREEN}Testing backup schedule...${NC}"
    
    # Test backup script
    if [[ ! -x "$BACKUP_SCRIPT" ]]; then
        echo -e "${RED}❌ Backup script is not executable${NC}"
        exit 1
    fi
    
    # Test backup script functionality
    echo "Testing backup script..."
    if "$BACKUP_SCRIPT" status &>/dev/null; then
        echo -e "${GREEN}✅ Backup script is working${NC}"
    else
        echo -e "${RED}❌ Backup script test failed${NC}"
        exit 1
    fi
    
    # Test cron service
    if systemctl is-active --quiet cron 2>/dev/null || systemctl is-active --quiet crond 2>/dev/null; then
        echo -e "${GREEN}✅ Cron service is running${NC}"
    else
        echo -e "${YELLOW}⚠️ Cron service may not be running${NC}"
    fi
    
    # Test log directory
    if [[ -d "$PROJECT_ROOT/logs" ]]; then
        echo -e "${GREEN}✅ Log directory exists${NC}"
    else
        echo -e "${YELLOW}⚠️ Creating log directory${NC}"
        mkdir -p "$PROJECT_ROOT/logs"
    fi
    
    # Test backup directory
    if [[ -d "$PROJECT_ROOT/backups" ]]; then
        echo -e "${GREEN}✅ Backup directory exists${NC}"
    else
        echo -e "${YELLOW}⚠️ Creating backup directory${NC}"
        mkdir -p "$PROJECT_ROOT/backups"
    fi
    
    echo -e "${GREEN}✅ Schedule test completed${NC}"
}

# Run immediate backup test
run_test_backup() {
    log "${GREEN}Running test backup...${NC}"
    
    if "$BACKUP_SCRIPT" backup full; then
        echo -e "${GREEN}✅ Test backup completed successfully${NC}"
        
        # Find the latest backup
        latest_backup=$(find "$PROJECT_ROOT/backups" -name "db_full_*.sql.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        
        if [[ -n "$latest_backup" ]]; then
            echo "Latest backup: $(basename "$latest_backup")"
            
            # Test verification
            if "$BACKUP_SCRIPT" verify "$latest_backup"; then
                echo -e "${GREEN}✅ Backup verification passed${NC}"
            else
                echo -e "${RED}❌ Backup verification failed${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ Test backup failed${NC}"
        exit 1
    fi
}

# Monitor backup health
monitor_health() {
    echo -e "${GREEN}=== Backup System Health Monitor ===${NC}"
    echo ""
    
    # Check recent backups
    local recent_backups=$(find "$PROJECT_ROOT/backups" -name "*.sql.gz" -type f -mtime -1 | wc -l)
    if [[ $recent_backups -gt 0 ]]; then
        echo -e "${GREEN}✅ Recent backups: $recent_backups (last 24h)${NC}"
    else
        echo -e "${RED}❌ No recent backups found${NC}"
    fi
    
    # Check backup size trends
    local backup_sizes=$(find "$PROJECT_ROOT/backups" -name "db_full_*.sql.gz" -type f -mtime -7 -exec du -b {} \; | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')
    echo "Average backup size (7 days): $(echo "$backup_sizes" | awk '{print int($1/1024/1024)"MB"}')"
    
    # Check disk space
    local backup_dir_size=$(du -sh "$PROJECT_ROOT/backups" 2>/dev/null | cut -f1)
    echo "Backup directory size: $backup_dir_size"
    
    # Check available disk space
    local available_space=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
    echo "Available disk space: $available_space"
    
    # Check log file
    if [[ -f "$PROJECT_ROOT/logs/backup_cron.log" ]]; then
        local log_errors=$(grep -c "ERROR" "$PROJECT_ROOT/logs/backup_cron.log" 2>/dev/null || echo 0)
        if [[ $log_errors -eq 0 ]]; then
            echo -e "${GREEN}✅ No errors in backup logs${NC}"
        else
            echo -e "${YELLOW}⚠️ $log_errors errors found in backup logs${NC}"
        fi
    fi
    
    # Check cron status
    if crontab -l 2>/dev/null | grep -q "$BACKUP_SCRIPT"; then
        echo -e "${GREEN}✅ Backup schedule is active${NC}"
    else
        echo -e "${RED}❌ Backup schedule is not installed${NC}"
    fi
}

# Usage information
usage() {
    echo "Federated Genomic Imputation Platform - Backup Scheduler"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install     Install automated backup schedule"
    echo "  uninstall   Remove backup schedule"
    echo "  status      Show current backup schedule"
    echo "  test        Test backup schedule configuration"
    echo "  run-test    Run a test backup immediately"
    echo "  monitor     Monitor backup system health"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 install     # Set up daily automated backups"
    echo "  $0 status      # Check current schedule"
    echo "  $0 monitor     # Check backup system health"
    echo ""
}

# Main function
main() {
    case "${1:-help}" in
        "install")
            install_scheduler
            ;;
        "uninstall")
            uninstall_scheduler
            ;;
        "status")
            show_schedule
            ;;
        "test")
            test_schedule
            ;;
        "run-test")
            run_test_backup
            ;;
        "monitor")
            monitor_health
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            echo "Unknown command: ${1:-}"
            usage
            exit 1
            ;;
    esac
}

main "$@"
