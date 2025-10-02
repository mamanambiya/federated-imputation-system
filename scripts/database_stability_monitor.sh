#!/bin/bash

# Database Stability Monitor - Advanced monitoring and recovery system
# This script provides comprehensive database monitoring, health checks, and automated recovery

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/var/log/database_stability.log"
ALERT_FILE="/var/log/database_alerts.log"
BACKUP_DIR="$PROJECT_ROOT/backups"
LATEST_BACKUP="$BACKUP_DIR/federated_imputation_5_services_with_institutions_20250804_133932.sql"

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE"
}

# Function to log alerts
log_alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" | sudo tee -a "$ALERT_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" | sudo tee -a "$LOG_FILE"
}

# Function to check database connectivity
check_db_connectivity() {
    if sudo docker-compose exec -T db pg_isready -U postgres >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check database existence
check_database_exists() {
    sudo docker-compose exec -T db psql -U postgres -lqt | cut -d \| -f 1 | grep -qw federated_imputation
}

# Function to check table integrity
check_table_integrity() {
    local tables=(
        "imputation_imputationservice"
        "imputation_referencepanel"
        "auth_user"
        "django_migrations"
    )
    
    for table in "${tables[@]}"; do
        if ! sudo docker-compose exec -T db psql -U postgres -d federated_imputation -c "\d $table" >/dev/null 2>&1; then
            log_alert "Table $table is missing or corrupted"
            return 1
        fi
    done
    return 0
}

# Function to check data integrity
check_data_integrity() {
    # Check if we have the expected number of services
    local service_count=$(sudo docker-compose exec -T db psql -U postgres -d federated_imputation -c "SELECT COUNT(*) FROM imputation_imputationservice;" -t 2>/dev/null | tr -d ' ' || echo "0")
    
    if [ "$service_count" -lt 5 ]; then
        log_alert "Service count is below expected: $service_count (expected: 5+)"
        return 1
    fi
    
    # Check if we have reference panels
    local panel_count=$(sudo docker-compose exec -T db psql -U postgres -d federated_imputation -c "SELECT COUNT(*) FROM imputation_referencepanel;" -t 2>/dev/null | tr -d ' ' || echo "0")
    
    if [ "$panel_count" -lt 1 ]; then
        log_alert "No reference panels found"
        return 1
    fi
    
    log_message "Data integrity check passed: $service_count services, $panel_count panels"
    return 0
}

# Function to check database performance
check_db_performance() {
    # Check for long-running queries
    local long_queries=$(sudo docker-compose exec -T db psql -U postgres -d federated_imputation -c "SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active' AND query_start < NOW() - INTERVAL '5 minutes';" -t 2>/dev/null | tr -d ' ' || echo "0")
    
    if [ "$long_queries" -gt 0 ]; then
        log_alert "Found $long_queries long-running queries"
    fi
    
    # Check database size
    local db_size=$(sudo docker-compose exec -T db psql -U postgres -d federated_imputation -c "SELECT pg_size_pretty(pg_database_size('federated_imputation'));" -t 2>/dev/null | tr -d ' ' || echo "unknown")
    log_message "Database size: $db_size"
    
    # Check connection count
    local connections=$(sudo docker-compose exec -T db psql -U postgres -c "SELECT COUNT(*) FROM pg_stat_activity;" -t 2>/dev/null | tr -d ' ' || echo "0")
    log_message "Active connections: $connections"
    
    if [ "$connections" -gt 50 ]; then
        log_alert "High connection count: $connections"
    fi
}

# Function to create automatic backup
create_backup() {
    local backup_file="$BACKUP_DIR/auto_backup_$(date +%Y%m%d_%H%M%S).sql"
    log_message "Creating automatic backup: $backup_file"
    
    if sudo docker-compose exec -T db pg_dump -U postgres federated_imputation > "$backup_file" 2>/dev/null; then
        # Compress the backup
        gzip "$backup_file"
        log_message "Backup created successfully: ${backup_file}.gz"
        
        # Keep only last 10 automatic backups
        find "$BACKUP_DIR" -name "auto_backup_*.sql.gz" -type f | sort -r | tail -n +11 | xargs rm -f 2>/dev/null || true
        
        return 0
    else
        log_alert "Failed to create backup"
        return 1
    fi
}

# Function to restore database from backup
restore_database() {
    log_alert "Attempting database restoration"
    
    # Create backup before restoration
    create_backup
    
    # Drop and recreate database
    sudo docker-compose exec -T db psql -U postgres -c "DROP DATABASE IF EXISTS federated_imputation;" 2>/dev/null || true
    sudo docker-compose exec -T db psql -U postgres -c "CREATE DATABASE federated_imputation;" 2>/dev/null || true
    
    # Restore from latest backup
    if [ -f "$LATEST_BACKUP" ]; then
        log_message "Restoring from: $LATEST_BACKUP"
        if sudo docker-compose exec -T db psql -U postgres -d federated_imputation < "$LATEST_BACKUP" 2>/dev/null; then
            log_message "Database restored successfully"
            return 0
        else
            log_alert "Failed to restore database from backup"
            return 1
        fi
    else
        log_alert "No backup file found for restoration"
        return 1
    fi
}

# Function to restart database container if needed
restart_database() {
    log_alert "Restarting database container"
    sudo docker-compose restart db
    
    # Wait for database to be ready
    local retries=0
    while [ $retries -lt 30 ]; do
        if check_db_connectivity; then
            log_message "Database container restarted successfully"
            return 0
        fi
        sleep 2
        retries=$((retries + 1))
    done
    
    log_alert "Database container failed to restart properly"
    return 1
}

# Function to check and fix celery workers
check_celery_workers() {
    # Check if celery workers are running
    if ! sudo docker-compose ps celery | grep -q "Up"; then
        log_alert "Celery worker is not running"
        sudo docker-compose restart celery
    fi
    
    if ! sudo docker-compose ps celery-beat | grep -q "Up"; then
        log_alert "Celery beat is not running"
        sudo docker-compose restart celery-beat
    fi
}

# Main monitoring function
run_stability_check() {
    log_message "Starting database stability check"
    
    # Check if Docker containers are running
    if ! sudo docker-compose ps db | grep -q "Up"; then
        log_alert "Database container is not running"
        sudo docker-compose up -d db
        sleep 10
    fi
    
    # Check database connectivity
    if ! check_db_connectivity; then
        log_alert "Database connectivity failed"
        restart_database
        
        if ! check_db_connectivity; then
            log_alert "Database still not accessible after restart"
            return 1
        fi
    fi
    
    # Check if database exists
    if ! check_database_exists; then
        log_alert "Database does not exist"
        restore_database
        
        if ! check_database_exists; then
            log_alert "Database restoration failed"
            return 1
        fi
    fi
    
    # Check table integrity
    if ! check_table_integrity; then
        log_alert "Table integrity check failed"
        restore_database
    fi
    
    # Check data integrity
    if ! check_data_integrity; then
        log_alert "Data integrity check failed"
        restore_database
    fi
    
    # Check database performance
    check_db_performance
    
    # Check celery workers
    check_celery_workers
    
    log_message "Database stability check completed"
    return 0
}

# Function to generate health report
generate_health_report() {
    local report_file="/var/log/database_health_$(date +%Y%m%d_%H%M%S).log"
    
    {
        echo "=== DATABASE HEALTH REPORT ==="
        echo "Generated: $(date)"
        echo ""
        echo "Container Status:"
        sudo docker-compose ps
        echo ""
        echo "Database Connectivity:"
        if check_db_connectivity; then
            echo "✅ Database is accessible"
        else
            echo "❌ Database is not accessible"
        fi
        echo ""
        echo "Database Information:"
        if check_database_exists; then
            echo "✅ Database exists"
            sudo docker-compose exec -T db psql -U postgres -d federated_imputation -c "SELECT COUNT(*) as service_count FROM imputation_imputationservice;" 2>/dev/null || echo "❌ Failed to query services"
            sudo docker-compose exec -T db psql -U postgres -d federated_imputation -c "SELECT COUNT(*) as panel_count FROM imputation_referencepanel;" 2>/dev/null || echo "❌ Failed to query panels"
        else
            echo "❌ Database does not exist"
        fi
        echo ""
        echo "Recent Alerts:"
        if [ -f "$ALERT_FILE" ]; then
            tail -10 "$ALERT_FILE" 2>/dev/null || echo "No recent alerts"
        else
            echo "No alert file found"
        fi
    } | sudo tee "$report_file" > /dev/null
    
    log_message "Health report generated: $report_file"
}

# Main execution
cd "$PROJECT_ROOT"

case "${1:-check}" in
    "check")
        run_stability_check
        ;;
    "report")
        generate_health_report
        ;;
    "backup")
        create_backup
        ;;
    "restore")
        restore_database
        ;;
    "monitor")
        # Continuous monitoring mode
        while true; do
            run_stability_check
            sleep 300  # Check every 5 minutes
        done
        ;;
    *)
        echo "Usage: $0 {check|report|backup|restore|monitor}"
        echo "  check   - Run single stability check (default)"
        echo "  report  - Generate health report"
        echo "  backup  - Create manual backup"
        echo "  restore - Restore from backup"
        echo "  monitor - Continuous monitoring mode"
        exit 1
        ;;
esac
