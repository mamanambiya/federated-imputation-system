#!/bin/bash

# Federated Genomic Imputation Platform - Advanced Backup System
# This script provides comprehensive backup functionality with automation, rotation, and verification

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"
LOG_DIR="$PROJECT_ROOT/logs"
BACKUP_LOG="$LOG_DIR/backup.log"
RETENTION_DAYS=30
COMPRESSION_LEVEL=6
MAX_BACKUP_SIZE="500M"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$BACKUP_LOG"
}

# Error handling
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Check dependencies
check_dependencies() {
    local deps=("docker" "docker-compose" "gzip" "pg_dump")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error_exit "Required dependency '$dep' is not installed"
        fi
    done
}

# Ensure directories exist
setup_directories() {
    mkdir -p "$BACKUP_DIR" "$LOG_DIR"
    log "INFO" "Backup directories initialized"
}

# Check Docker services
check_services() {
    log "INFO" "Checking Docker services status..."
    
    if ! sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" ps | grep -q "Up"; then
        error_exit "Docker services are not running. Please start them first."
    fi
    
    # Check database connectivity
    if ! sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db pg_isready -U postgres -d federated_imputation &>/dev/null; then
        error_exit "Database is not accessible"
    fi
    
    log "INFO" "All services are healthy"
}

# Create database backup
create_database_backup() {
    local backup_type=$1
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/db_${backup_type}_${timestamp}.sql"
    
    log "INFO" "Creating ${backup_type} database backup..."
    
    # Create backup with custom format for better compression and features
    if sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db pg_dump \
        -U postgres \
        -d federated_imputation \
        --verbose \
        --no-owner \
        --no-privileges \
        --clean \
        --if-exists > "$backup_file" 2>>"$BACKUP_LOG"; then
        
        # Compress the backup
        log "INFO" "Compressing backup..."
        gzip -"$COMPRESSION_LEVEL" "$backup_file"
        backup_file="${backup_file}.gz"
        
        # Verify backup size
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log "INFO" "Backup created successfully: $(basename "$backup_file") (${backup_size})"
        
        # Verify backup integrity
        if verify_backup "$backup_file"; then
            log "INFO" "Backup verification passed"
            echo "$backup_file"
        else
            error_exit "Backup verification failed"
        fi
    else
        error_exit "Failed to create database backup"
    fi
}

# Create incremental backup (for large databases)
create_incremental_backup() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/db_incremental_${timestamp}.sql"
    
    log "INFO" "Creating incremental backup..."
    
    # Get the last full backup timestamp
    local last_backup=$(find "$BACKUP_DIR" -name "db_full_*.sql.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [[ -z "$last_backup" ]]; then
        log "WARN" "No full backup found, creating full backup instead"
        create_database_backup "full"
        return
    fi
    
    # Extract timestamp from last backup
    local last_timestamp=$(basename "$last_backup" | sed 's/db_full_\(.*\)\.sql\.gz/\1/')
    local last_date=$(date -d "${last_timestamp:0:8} ${last_timestamp:9:2}:${last_timestamp:11:2}:${last_timestamp:13:2}" '+%Y-%m-%d %H:%M:%S')
    
    # Create incremental backup (changes since last backup)
    sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db pg_dump \
        -U postgres \
        -d federated_imputation \
        --verbose \
        --no-owner \
        --no-privileges \
        --inserts \
        --data-only > "$backup_file" 2>>"$BACKUP_LOG"
    
    gzip -"$COMPRESSION_LEVEL" "$backup_file"
    backup_file="${backup_file}.gz"
    
    log "INFO" "Incremental backup created: $(basename "$backup_file")"
    echo "$backup_file"
}

# Verify backup integrity
verify_backup() {
    local backup_file=$1
    log "INFO" "Verifying backup integrity: $(basename "$backup_file")"
    
    # Test gzip integrity
    if ! gzip -t "$backup_file" 2>/dev/null; then
        log "ERROR" "Backup file is corrupted (gzip test failed)"
        return 1
    fi
    
    # Test SQL syntax (basic check)
    if ! zcat "$backup_file" | head -100 | grep -q "PostgreSQL database dump"; then
        log "ERROR" "Backup file doesn't appear to be a valid PostgreSQL dump"
        return 1
    fi
    
    # Check file size (should be reasonable)
    local size=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file")
    if [[ $size -lt 1000 ]]; then
        log "ERROR" "Backup file is suspiciously small ($size bytes)"
        return 1
    fi
    
    return 0
}

# Create system state backup
create_system_backup() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local system_backup="$BACKUP_DIR/system_state_${timestamp}.tar.gz"
    
    log "INFO" "Creating system state backup..."
    
    # Create temporary directory for system files
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Collect system information
    {
        echo "=== System State Backup ==="
        echo "Timestamp: $(date)"
        echo "Hostname: $(hostname)"
        echo "Docker Version: $(docker --version)"
        echo "Docker Compose Version: $(docker-compose --version)"
        echo ""
        
        echo "=== Docker Services ==="
        sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" ps
        echo ""
        
        echo "=== Docker Volumes ==="
        sudo docker volume ls | grep federated
        echo ""
        
        echo "=== Database Info ==="
        sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation -c "\l"
        echo ""
        
        echo "=== Service Counts ==="
        sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation -c "SELECT 'Services: ' || COUNT(*) FROM imputation_imputationservice;"
        sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation -c "SELECT 'Reference Panels: ' || COUNT(*) FROM imputation_referencepanel;"
        sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation -c "SELECT 'Users: ' || COUNT(*) FROM auth_user;"
        
    } > "$temp_dir/system_state.txt"
    
    # Copy configuration files
    cp "$PROJECT_ROOT/docker-compose.yml" "$temp_dir/"
    cp "$PROJECT_ROOT/requirements.txt" "$temp_dir/"
    [[ -f "$PROJECT_ROOT/.env" ]] && cp "$PROJECT_ROOT/.env" "$temp_dir/" || echo "No .env file found" > "$temp_dir/env_note.txt"
    
    # Create archive
    tar -czf "$system_backup" -C "$temp_dir" .
    
    log "INFO" "System state backup created: $(basename "$system_backup")"
    echo "$system_backup"
}

# Rotate old backups
rotate_backups() {
    log "INFO" "Rotating old backups (keeping last $RETENTION_DAYS days)..."
    
    local deleted_count=0
    while IFS= read -r -d '' file; do
        rm "$file"
        ((deleted_count++))
        log "INFO" "Deleted old backup: $(basename "$file")"
    done < <(find "$BACKUP_DIR" -name "*.sql.gz" -o -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -print0)
    
    if [[ $deleted_count -eq 0 ]]; then
        log "INFO" "No old backups to delete"
    else
        log "INFO" "Deleted $deleted_count old backup files"
    fi
}

# Send backup notification
send_notification() {
    local status=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log notification
    log "INFO" "Backup notification: $status - $message"
    
    # Here you could add email, Slack, or other notification integrations
    # For now, we'll just create a status file
    echo "$timestamp - $status: $message" >> "$BACKUP_DIR/backup_status.log"
}

# Main backup function
perform_backup() {
    local backup_type=${1:-"full"}
    local start_time=$(date +%s)
    
    log "INFO" "Starting $backup_type backup process..."
    
    # Pre-backup checks
    check_dependencies
    setup_directories
    check_services
    
    # Create backups
    local db_backup=""
    case $backup_type in
        "full")
            db_backup=$(create_database_backup "full")
            ;;
        "incremental")
            db_backup=$(create_incremental_backup)
            ;;
        *)
            error_exit "Unknown backup type: $backup_type"
            ;;
    esac
    
    # Create system backup
    local system_backup=$(create_system_backup)
    
    # Rotate old backups
    rotate_backups
    
    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Success notification
    local message="Backup completed successfully in ${duration}s. Files: $(basename "$db_backup"), $(basename "$system_backup")"
    send_notification "SUCCESS" "$message"
    
    log "INFO" "Backup process completed successfully"
    echo -e "${GREEN}✅ Backup completed successfully!${NC}"
    echo "Database backup: $(basename "$db_backup")"
    echo "System backup: $(basename "$system_backup")"
    echo "Duration: ${duration} seconds"
}

# Test backup restoration
test_restore() {
    local backup_file=$1
    
    if [[ ! -f "$backup_file" ]]; then
        error_exit "Backup file not found: $backup_file"
    fi
    
    log "INFO" "Testing backup restoration: $(basename "$backup_file")"
    
    # Create test database
    local test_db="federated_imputation_test_$(date +%s)"
    
    # Create test database
    if sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db createdb -U postgres "$test_db" 2>>"$BACKUP_LOG"; then
        log "INFO" "Test database created: $test_db"
        
        # Restore backup to test database
        if zcat "$backup_file" | sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d "$test_db" &>>"$BACKUP_LOG"; then
            log "INFO" "Backup restoration test successful"
            
            # Verify data
            local service_count=$(sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d "$test_db" -t -c "SELECT COUNT(*) FROM imputation_imputationservice;" 2>/dev/null | tr -d ' \n')
            
            if [[ "$service_count" -gt 0 ]]; then
                log "INFO" "Data verification passed: $service_count services found"
                echo -e "${GREEN}✅ Backup restoration test passed${NC}"
            else
                log "WARN" "Data verification warning: No services found in restored backup"
                echo -e "${YELLOW}⚠️ Backup restoration test passed but no data found${NC}"
            fi
        else
            log "ERROR" "Backup restoration test failed"
            echo -e "${RED}❌ Backup restoration test failed${NC}"
        fi
        
        # Cleanup test database
        sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db dropdb -U postgres "$test_db" 2>>"$BACKUP_LOG"
        log "INFO" "Test database cleaned up"
    else
        error_exit "Failed to create test database"
    fi
}

# Show usage
usage() {
    echo "Federated Genomic Imputation Platform - Backup System"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  backup [full|incremental]  Create a backup (default: full)"
    echo "  verify <backup_file>       Verify backup integrity"
    echo "  test-restore <backup_file> Test backup restoration"
    echo "  rotate                     Rotate old backups"
    echo "  status                     Show backup status"
    echo "  help                       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 backup full             Create a full backup"
    echo "  $0 backup incremental      Create an incremental backup"
    echo "  $0 verify backup.sql.gz    Verify a backup file"
    echo "  $0 test-restore backup.sql.gz  Test restoring a backup"
    echo ""
}

# Show backup status
show_status() {
    echo -e "${BLUE}=== Backup System Status ===${NC}"
    echo ""
    
    # Show recent backups
    echo "Recent backups:"
    find "$BACKUP_DIR" -name "*.sql.gz" -o -name "*.tar.gz" -type f -mtime -7 -exec ls -lh {} \; | sort -k6,7 | tail -10
    echo ""
    
    # Show disk usage
    echo "Backup directory size: $(du -sh "$BACKUP_DIR" | cut -f1)"
    echo ""
    
    # Show last backup status
    if [[ -f "$BACKUP_DIR/backup_status.log" ]]; then
        echo "Last backup status:"
        tail -5 "$BACKUP_DIR/backup_status.log"
    fi
}

# Main script logic
main() {
    case "${1:-help}" in
        "backup")
            perform_backup "${2:-full}"
            ;;
        "verify")
            if [[ -z "${2:-}" ]]; then
                error_exit "Please specify a backup file to verify"
            fi
            verify_backup "$2"
            ;;
        "test-restore")
            if [[ -z "${2:-}" ]]; then
                error_exit "Please specify a backup file to test"
            fi
            test_restore "$2"
            ;;
        "rotate")
            setup_directories
            rotate_backups
            ;;
        "status")
            show_status
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            echo "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
