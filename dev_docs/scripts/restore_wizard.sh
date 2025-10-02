#!/bin/bash

# Federated Genomic Imputation Platform - Backup Restoration Wizard
# Interactive wizard for easy database restoration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"
LOG_DIR="$PROJECT_ROOT/logs"
RESTORE_LOG="$LOG_DIR/restore.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$RESTORE_LOG"
}

# Error handling
error_exit() {
    log "ERROR" "$1"
    echo -e "${RED}❌ Error: $1${NC}"
    exit 1
}

# Create directories
setup_directories() {
    mkdir -p "$LOG_DIR"
}

# Welcome message
show_welcome() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           Federated Genomic Imputation Platform             ║${NC}"
    echo -e "${CYAN}║                  Database Restoration Wizard                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: This will replace your current database!${NC}"
    echo -e "${YELLOW}   Make sure to backup current data before proceeding.${NC}"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    
    # Check if Docker is running
    if ! docker info &>/dev/null; then
        error_exit "Docker is not running. Please start Docker first."
    fi
    
    # Check if services are running
    if ! sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" ps | grep -q "Up"; then
        echo -e "${YELLOW}⚠️ Docker services are not running.${NC}"
        read -p "Would you like to start them now? (y/N): " start_services
        if [[ "$start_services" =~ ^[Yy]$ ]]; then
            log "INFO" "Starting Docker services..."
            sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" up -d
            sleep 10
        else
            error_exit "Services must be running for restoration"
        fi
    fi
    
    # Check database connectivity
    if ! sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db pg_isready -U postgres &>/dev/null; then
        error_exit "Cannot connect to database"
    fi
    
    log "INFO" "Prerequisites check passed"
}

# List available backups
list_backups() {
    echo -e "${BLUE}=== Available Backup Files ===${NC}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        error_exit "Backup directory not found: $BACKUP_DIR"
    fi
    
    local backups=($(find "$BACKUP_DIR" -name "*.sql.gz" -type f | sort -r))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        error_exit "No backup files found in $BACKUP_DIR"
    fi
    
    echo "Found ${#backups[@]} backup files:"
    echo ""
    
    for i in "${!backups[@]}"; do
        local backup="${backups[$i]}"
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c %y "$backup" | cut -d' ' -f1,2 | cut -d'.' -f1)
        
        printf "%2d) %-50s %8s  %s\n" $((i+1)) "$filename" "$size" "$date"
    done
    
    echo ""
    echo "${backups[@]}"
}

# Select backup file
select_backup() {
    local backups_string="$1"
    read -a backups <<< "$backups_string"
    
    while true; do
        read -p "Select backup file (1-${#backups[@]}) or 'q' to quit: " selection
        
        if [[ "$selection" == "q" ]]; then
            echo "Restoration cancelled."
            exit 0
        fi
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#backups[@]} ]]; then
            selected_backup="${backups[$((selection-1))]}"
            break
        else
            echo -e "${RED}Invalid selection. Please enter a number between 1 and ${#backups[@]}.${NC}"
        fi
    done
    
    echo "$selected_backup"
}

# Show backup information
show_backup_info() {
    local backup_file="$1"
    
    echo -e "${BLUE}=== Backup Information ===${NC}"
    echo ""
    echo "Selected backup: $(basename "$backup_file")"
    echo "File size: $(du -h "$backup_file" | cut -f1)"
    echo "Created: $(stat -c %y "$backup_file" | cut -d'.' -f1)"
    echo ""
    
    # Verify backup integrity
    echo "Verifying backup integrity..."
    if gzip -t "$backup_file" 2>/dev/null; then
        echo -e "${GREEN}✅ Backup file integrity: OK${NC}"
    else
        error_exit "Backup file is corrupted"
    fi
    
    # Show backup contents preview
    echo ""
    echo "Backup contents preview:"
    echo "------------------------"
    zcat "$backup_file" | head -20 | grep -E "(CREATE TABLE|INSERT INTO)" | head -5 || true
    echo "..."
    echo ""
}

# Create current database backup
create_current_backup() {
    echo -e "${YELLOW}Creating backup of current database...${NC}"
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local current_backup="$BACKUP_DIR/pre_restore_backup_${timestamp}.sql.gz"
    
    if sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db pg_dump \
        -U postgres \
        -d federated_imputation \
        --verbose \
        --no-owner \
        --no-privileges \
        --clean \
        --if-exists 2>>"$RESTORE_LOG" | gzip > "$current_backup"; then
        
        log "INFO" "Current database backed up to: $(basename "$current_backup")"
        echo -e "${GREEN}✅ Current database backed up successfully${NC}"
        echo "$current_backup"
    else
        error_exit "Failed to backup current database"
    fi
}

# Restore database
restore_database() {
    local backup_file="$1"
    local current_backup="$2"
    
    echo -e "${YELLOW}Restoring database from backup...${NC}"
    log "INFO" "Starting database restoration from: $(basename "$backup_file")"
    
    # Drop and recreate database
    echo "Preparing database..."
    if sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" &>>"$RESTORE_LOG"; then
        log "INFO" "Database schema reset successfully"
    else
        error_exit "Failed to reset database schema"
    fi
    
    # Restore from backup
    echo "Restoring data..."
    if zcat "$backup_file" | sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation &>>"$RESTORE_LOG"; then
        log "INFO" "Database restoration completed"
        echo -e "${GREEN}✅ Database restored successfully${NC}"
    else
        log "ERROR" "Database restoration failed"
        echo -e "${RED}❌ Database restoration failed${NC}"
        
        # Offer to restore from current backup
        echo ""
        read -p "Would you like to restore from the pre-restoration backup? (y/N): " restore_current
        if [[ "$restore_current" =~ ^[Yy]$ ]]; then
            echo "Restoring from pre-restoration backup..."
            if zcat "$current_backup" | sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation &>>"$RESTORE_LOG"; then
                echo -e "${GREEN}✅ Restored from pre-restoration backup${NC}"
            else
                error_exit "Failed to restore from pre-restoration backup"
            fi
        fi
        exit 1
    fi
}

# Apply migrations
apply_migrations() {
    echo -e "${YELLOW}Applying database migrations...${NC}"
    
    if sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec web python manage.py migrate &>>"$RESTORE_LOG"; then
        log "INFO" "Database migrations applied successfully"
        echo -e "${GREEN}✅ Migrations applied successfully${NC}"
    else
        log "WARN" "Some migrations may have failed"
        echo -e "${YELLOW}⚠️ Some migrations may have failed (check logs)${NC}"
    fi
}

# Verify restoration
verify_restoration() {
    echo -e "${YELLOW}Verifying restoration...${NC}"
    
    # Check database connectivity
    if ! sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db pg_isready -U postgres -d federated_imputation &>/dev/null; then
        error_exit "Database is not accessible after restoration"
    fi
    
    # Check data integrity
    local services_count=$(sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation -t -c "SELECT COUNT(*) FROM imputation_imputationservice;" 2>/dev/null | tr -d ' \n' || echo "0")
    local users_count=$(sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation -t -c "SELECT COUNT(*) FROM auth_user;" 2>/dev/null | tr -d ' \n' || echo "0")
    local panels_count=$(sudo docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql -U postgres -d federated_imputation -t -c "SELECT COUNT(*) FROM imputation_referencepanel;" 2>/dev/null | tr -d ' \n' || echo "0")
    
    echo ""
    echo "Data verification:"
    echo "  Services: $services_count"
    echo "  Users: $users_count"
    echo "  Reference Panels: $panels_count"
    echo ""
    
    if [[ $services_count -gt 0 ]]; then
        echo -e "${GREEN}✅ Restoration verification passed${NC}"
        log "INFO" "Restoration verification passed: $services_count services, $users_count users, $panels_count panels"
    else
        echo -e "${YELLOW}⚠️ Warning: No services found in restored database${NC}"
        log "WARN" "Restoration verification warning: No services found"
    fi
}

# Test API endpoints
test_api() {
    echo -e "${YELLOW}Testing API endpoints...${NC}"
    
    # Test services endpoint
    if curl -s http://localhost:8000/api/services/ | grep -q '"count"'; then
        echo -e "${GREEN}✅ Services API: Working${NC}"
    else
        echo -e "${YELLOW}⚠️ Services API: May not be working${NC}"
    fi
    
    # Test frontend
    if curl -s http://localhost:3000/ | grep -q "Federated"; then
        echo -e "${GREEN}✅ Frontend: Working${NC}"
    else
        echo -e "${YELLOW}⚠️ Frontend: May not be working${NC}"
    fi
}

# Show completion summary
show_completion() {
    local backup_file="$1"
    local current_backup="$2"
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Restoration Complete!                    ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Restoration Summary:"
    echo "  Restored from: $(basename "$backup_file")"
    echo "  Pre-restoration backup: $(basename "$current_backup")"
    echo "  Log file: $RESTORE_LOG"
    echo ""
    echo "Next steps:"
    echo "  1. Test the application: http://localhost:3000"
    echo "  2. Verify your data is correct"
    echo "  3. Run validation: ./post_change_validation.sh"
    echo ""
    echo "If you encounter issues, you can restore from the pre-restoration backup:"
    echo "  $0 --file \"$current_backup\""
}

# Interactive restoration wizard
run_wizard() {
    setup_directories
    show_welcome
    
    # Get confirmation
    read -p "Do you want to proceed with database restoration? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Restoration cancelled."
        exit 0
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # List and select backup
    local backups_string=$(list_backups)
    local selected_backup=$(select_backup "$backups_string")
    
    # Show backup information
    show_backup_info "$selected_backup"
    
    # Final confirmation
    echo -e "${RED}⚠️ FINAL WARNING: This will replace your current database!${NC}"
    read -p "Are you absolutely sure you want to proceed? (yes/NO): " final_confirm
    if [[ "$final_confirm" != "yes" ]]; then
        echo "Restoration cancelled."
        exit 0
    fi
    
    # Create backup of current database
    local current_backup=$(create_current_backup)
    
    # Perform restoration
    restore_database "$selected_backup" "$current_backup"
    
    # Apply migrations
    apply_migrations
    
    # Verify restoration
    verify_restoration
    
    # Test API
    test_api
    
    # Show completion
    show_completion "$selected_backup" "$current_backup"
}

# Direct file restoration
restore_file() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        error_exit "Backup file not found: $backup_file"
    fi
    
    setup_directories
    check_prerequisites
    
    echo -e "${YELLOW}Restoring from: $(basename "$backup_file")${NC}"
    
    # Create backup of current database
    local current_backup=$(create_current_backup)
    
    # Perform restoration
    restore_database "$backup_file" "$current_backup"
    apply_migrations
    verify_restoration
    
    echo -e "${GREEN}✅ Restoration completed${NC}"
}

# Usage
usage() {
    echo "Federated Genomic Imputation Platform - Restoration Wizard"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --file <backup_file>    Restore from specific backup file"
    echo "  --wizard               Run interactive restoration wizard (default)"
    echo "  --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run interactive wizard"
    echo "  $0 --wizard                          # Run interactive wizard"
    echo "  $0 --file backup.sql.gz              # Restore from specific file"
    echo ""
}

# Main function
main() {
    case "${1:---wizard}" in
        "--file")
            if [[ -z "${2:-}" ]]; then
                error_exit "Please specify a backup file"
            fi
            restore_file "$2"
            ;;
        "--wizard")
            run_wizard
            ;;
        "--help"|"-h")
            usage
            ;;
        *)
            if [[ -f "$1" ]]; then
                restore_file "$1"
            else
                run_wizard
            fi
            ;;
    esac
}

main "$@"
