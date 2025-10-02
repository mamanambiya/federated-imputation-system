#!/bin/bash
#
# Automated Database and File Backup Script
# For Federated Genomic Imputation Platform
#
# Features:
# - PostgreSQL database backup with compression
# - Uploaded files backup
# - Automatic cleanup of old backups
# - Backup verification
# - Email notifications (optional)
# - S3/Cloud upload support (optional)
#

set -e  # Exit on error
set -u  # Exit on undefined variable

# ============================================
# Configuration
# ============================================

# Backup directories
BACKUP_ROOT="/home/ubuntu/federated-imputation-central/backups"
DB_BACKUP_DIR="$BACKUP_ROOT/database"
FILE_BACKUP_DIR="$BACKUP_ROOT/files"
LOG_DIR="$BACKUP_ROOT/logs"

# Create directories if they don't exist
mkdir -p "$DB_BACKUP_DIR" "$FILE_BACKUP_DIR" "$LOG_DIR"

# Timestamp for backup files
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DATE=$(date +"%Y-%m-%d")

# Retention policy (days)
RETENTION_DAYS=30

# Database configuration
DB_CONTAINER="postgres"
DB_NAME="federated_imputation"
DB_USER="postgres"
DB_PASSWORD="${POSTGRES_PASSWORD:-postgres}"

# Files to backup
MEDIA_DIR="/home/ubuntu/federated-imputation-central/media"
UPLOADS_DIR="$MEDIA_DIR/uploads"

# Log file
LOG_FILE="$LOG_DIR/backup_$DATE.log"

# Email notification (set to empty to disable)
NOTIFICATION_EMAIL="${BACKUP_NOTIFICATION_EMAIL:-}"

# S3 bucket for remote backup (set to empty to disable)
S3_BUCKET="${BACKUP_S3_BUCKET:-}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# Functions
# ============================================

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}ℹ️  $@${NC}"
    log "INFO" "$@"
}

log_success() {
    echo -e "${GREEN}✅ $@${NC}"
    log "SUCCESS" "$@"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $@${NC}"
    log "WARNING" "$@"
}

log_error() {
    echo -e "${RED}❌ $@${NC}"
    log "ERROR" "$@"
}

# Check if Docker container is running
check_container() {
    local container=$1
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        log_error "Container $container is not running"
        return 1
    fi
    return 0
}

# Verify backup file integrity
verify_backup() {
    local backup_file=$1
    log_info "Verifying backup integrity: $(basename $backup_file)"

    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    # Test gzip integrity
    if gunzip -t "$backup_file" 2>/dev/null; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "Backup verified successfully ($size)"
        return 0
    else
        log_error "Backup verification failed: $backup_file"
        return 1
    fi
}

# Backup PostgreSQL database
backup_database() {
    log_info "Starting database backup..."

    local backup_file="$DB_BACKUP_DIR/db_${DB_NAME}_${TIMESTAMP}.sql.gz"

    # Check if database container is running
    if ! check_container "$DB_CONTAINER"; then
        return 1
    fi

    # Perform backup using pg_dump
    if docker exec -t "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$backup_file"; then
        log_success "Database backup created: $(basename $backup_file)"

        # Verify backup
        if verify_backup "$backup_file"; then
            log_success "Database backup completed and verified"
            echo "$backup_file"
            return 0
        else
            log_error "Database backup verification failed"
            rm -f "$backup_file"
            return 1
        fi
    else
        log_error "Database backup failed"
        return 1
    fi
}

# Backup uploaded files
backup_files() {
    log_info "Starting file backup..."

    if [ ! -d "$UPLOADS_DIR" ]; then
        log_warning "Uploads directory not found: $UPLOADS_DIR"
        return 0
    fi

    local backup_file="$FILE_BACKUP_DIR/files_${TIMESTAMP}.tar.gz"

    # Create tar archive of uploads
    if tar -czf "$backup_file" -C "$(dirname $UPLOADS_DIR)" "$(basename $UPLOADS_DIR)" 2>/dev/null; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "File backup created: $(basename $backup_file) ($size)"
        echo "$backup_file"
        return 0
    else
        log_warning "File backup failed or no files to backup"
        return 0
    fi
}

# Upload to S3 (if configured)
upload_to_s3() {
    local file=$1

    if [ -z "$S3_BUCKET" ]; then
        return 0  # S3 not configured, skip
    fi

    log_info "Uploading to S3: s3://$S3_BUCKET/$(basename $file)"

    if command -v aws >/dev/null 2>&1; then
        if aws s3 cp "$file" "s3://$S3_BUCKET/backups/$(date +%Y/%m)/$(basename $file)"; then
            log_success "S3 upload completed"
            return 0
        else
            log_error "S3 upload failed"
            return 1
        fi
    else
        log_warning "AWS CLI not installed, skipping S3 upload"
        return 0
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    log_info "Cleaning up backups older than $RETENTION_DAYS days..."

    local deleted_count=0

    # Cleanup database backups
    deleted_count=$(find "$DB_BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
    if [ $deleted_count -gt 0 ]; then
        log_info "Deleted $deleted_count old database backup(s)"
    fi

    # Cleanup file backups
    deleted_count=$(find "$FILE_BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
    if [ $deleted_count -gt 0 ]; then
        log_info "Deleted $deleted_count old file backup(s)"
    fi

    log_success "Cleanup completed"
}

# Send email notification
send_notification() {
    local subject=$1
    local message=$2

    if [ -z "$NOTIFICATION_EMAIL" ]; then
        return 0  # Email not configured
    fi

    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "$subject" "$NOTIFICATION_EMAIL"
        log_info "Email notification sent to $NOTIFICATION_EMAIL"
    else
        log_warning "Mail command not found, skipping email notification"
    fi
}

# Generate backup report
generate_report() {
    local status=$1

    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Backup Report - $DATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: $status
Timestamp: $(date "+%Y-%m-%d %H:%M:%S")

Database Backups:
$(ls -lh "$DB_BACKUP_DIR" | tail -5)

File Backups:
$(ls -lh "$FILE_BACKUP_DIR" | tail -5)

Disk Usage:
$(du -sh "$BACKUP_ROOT")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# ============================================
# Main Backup Process
# ============================================

main() {
    log_info "=========================================="
    log_info "Starting Backup Process"
    log_info "=========================================="

    local backup_status="SUCCESS"
    local db_backup_file=""
    local files_backup_file=""

    # Backup database
    if db_backup_file=$(backup_database); then
        # Upload to S3 if configured
        upload_to_s3 "$db_backup_file"
    else
        backup_status="FAILED"
    fi

    # Backup files
    if files_backup_file=$(backup_files); then
        # Upload to S3 if configured
        if [ -n "$files_backup_file" ]; then
            upload_to_s3 "$files_backup_file"
        fi
    fi

    # Cleanup old backups
    cleanup_old_backups

    # Generate report
    local report=$(generate_report "$backup_status")
    echo "$report" | tee -a "$LOG_FILE"

    # Send notification
    if [ "$backup_status" = "SUCCESS" ]; then
        send_notification "✅ Backup Successful - $DATE" "$report"
        log_success "=========================================="
        log_success "Backup Process Completed Successfully"
        log_success "=========================================="
        exit 0
    else
        send_notification "❌ Backup Failed - $DATE" "$report"
        log_error "=========================================="
        log_error "Backup Process Failed"
        log_error "=========================================="
        exit 1
    fi
}

# Run main function
main
