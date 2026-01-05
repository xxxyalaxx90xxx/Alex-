#!/bin/bash

################################################################################
# Backup Manager Script v4.0
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Erweiterte Backup-Verwaltung mit Validierung für XTREME-XAI-ULTIMATE
################################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
BACKUP_DIR="${HOME}/.xtreme-xai-backups"
SD_BACKUP_DIR="/storage/emulated/0/XAI/backups"
MAX_BACKUPS=10
MAX_BACKUP_AGE_DAYS=30

log_info() {
    echo -e "${BLUE}[BACKUP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Initialize backup directory
init_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: $BACKUP_DIR"
    fi
    
    # Also try to create SD card backup dir if available
    if [[ -w "/storage/emulated/0" ]]; then
        mkdir -p "$SD_BACKUP_DIR" 2>/dev/null && log_info "SD card backup dir available"
    fi
}

# Create a new backup
create_backup() {
    log_info "Creating new backup..."
    
    init_backup_dir
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_NAME="xai_backup_${TIMESTAMP}"
    BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    
    # Directories to backup
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    
    log_info "Backing up configuration files..."
    
    # Create temporary directory for backup staging
    TEMP_DIR=$(mktemp -d)
    mkdir -p "${TEMP_DIR}/config"
    mkdir -p "${TEMP_DIR}/data"
    
    # Backup configuration files (if they exist)
    [[ -d "${HOME}/.config/xtreme-xai" ]] && cp -r "${HOME}/.config/xtreme-xai" "${TEMP_DIR}/config/" 2>/dev/null || true
    [[ -d "${HOME}/.xtreme-xai" ]] && cp -r "${HOME}/.xtreme-xai" "${TEMP_DIR}/config/" 2>/dev/null || true
    [[ -d "${HOME}/xtreme_ai_system/config" ]] && cp -r "${HOME}/xtreme_ai_system/config" "${TEMP_DIR}/config/system" 2>/dev/null || true
    
    # Backup important data (exclude large files)
    if [[ -d "${HOME}/xtreme_ai_system/data" ]]; then
        find "${HOME}/xtreme_ai_system/data" -type f -size -10M -exec cp --parents {} "${TEMP_DIR}/data/" \; 2>/dev/null || true
    fi
    
    # Create backup metadata
    cat > "${TEMP_DIR}/backup_info.txt" << EOF
Backup Name: $BACKUP_NAME
Backup Date: $(date)
Hostname: $(hostname)
User: $(whoami)
System: $(uname -a)
XAI Version: 4.0.0
Backup Type: Full Configuration

Files Backed Up:
$(find "$TEMP_DIR" -type f | wc -l) files
$(du -sh "$TEMP_DIR" | cut -f1) total size
EOF
    
    # Create checksums for validation
    log_info "Generating checksums..."
    find "$TEMP_DIR" -type f -exec md5sum {} \; > "${TEMP_DIR}/checksums.md5" 2>/dev/null || true
    
    # Create tarball with compression
    log_info "Compressing backup..."
    tar -czf "$BACKUP_PATH" -C "$TEMP_DIR" . 2>/dev/null
    
    # Cleanup temp directory
    rm -rf "$TEMP_DIR"
    
    if [[ -f "$BACKUP_PATH" ]]; then
        BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
        log_success "Backup created: $BACKUP_NAME.tar.gz ($BACKUP_SIZE)"
        
        # Validate backup immediately
        if tar -tzf "$BACKUP_PATH" &>/dev/null; then
            log_success "Backup validation passed"
        else
            log_error "Backup validation failed!"
            rm -f "$BACKUP_PATH"
            return 1
        fi
        
        # Copy to SD card if available
        if [[ -d "$SD_BACKUP_DIR" ]] && [[ -w "$SD_BACKUP_DIR" ]]; then
            cp "$BACKUP_PATH" "$SD_BACKUP_DIR/" 2>/dev/null && log_success "Backup copied to SD card"
        fi
        
        # Cleanup old backups
        cleanup_old_backups
        
        return 0
    else
        log_error "Failed to create backup"
        return 1
    fi
}

# List all backups
list_backups() {
    log_info "Available backups:"
    echo
    
    local found_backups=0
    
    # List internal backups
    if [[ -d "$BACKUP_DIR" ]]; then
        echo -e "${CYAN}Internal Storage:${NC}"
        local count=1
        for backup in "$BACKUP_DIR"/xai_backup_*.tar.gz; do
            if [[ -f "$backup" ]]; then
                local size=$(du -h "$backup" | cut -f1)
                local date=$(stat -c %y "$backup" 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$backup" 2>/dev/null)
                local name=$(basename "$backup")
                
                # Validate backup
                if tar -tzf "$backup" &>/dev/null; then
                    echo -e "  ${GREEN}✓${NC} [$count] $name - $size - $date"
                else
                    echo -e "  ${RED}✗${NC} [$count] $name - $size - $date ${RED}(corrupted)${NC}"
                fi
                
                count=$((count + 1))
                found_backups=1
            fi
        done
        echo
    fi
    
    # List SD card backups
    if [[ -d "$SD_BACKUP_DIR" ]]; then
        echo -e "${CYAN}SD Card Storage:${NC}"
        local count=1
        for backup in "$SD_BACKUP_DIR"/xai_backup_*.tar.gz; do
            if [[ -f "$backup" ]]; then
                local size=$(du -h "$backup" | cut -f1)
                local date=$(stat -c %y "$backup" 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$backup" 2>/dev/null)
                local name=$(basename "$backup")
                echo "  [$count] $name - $size - $date"
                count=$((count + 1))
                found_backups=1
            fi
        done
        echo
    fi
    
    if [[ $found_backups -eq 0 ]]; then
        log_warning "No backups found"
        return 1
    fi
}

# Restore from backup
restore_backup() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        log_error "No backup file specified"
        echo
        list_backups
        return 1
    fi
    
    # Try to find the backup file
    if [[ ! -f "$backup_file" ]]; then
        # Try internal storage
        backup_file="${BACKUP_DIR}/${backup_file}"
        if [[ ! -f "$backup_file" ]]; then
            # Try SD card
            backup_file="${SD_BACKUP_DIR}/${backup_file}"
        fi
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    log_info "Restoring from backup: $(basename "$backup_file")"
    
    # Validate backup first
    if ! tar -tzf "$backup_file" &>/dev/null; then
        log_error "Backup file is corrupted and cannot be restored!"
        return 1
    fi
    
    log_success "Backup validation passed"
    
    # Create temporary directory for extraction
    TEMP_DIR=$(mktemp -d)
    
    # Extract backup
    log_info "Extracting backup..."
    tar -xzf "$backup_file" -C "$TEMP_DIR" 2>/dev/null
    
    # Show backup info
    if [[ -f "${TEMP_DIR}/backup_info.txt" ]]; then
        echo
        echo -e "${CYAN}Backup Information:${NC}"
        cat "${TEMP_DIR}/backup_info.txt"
        echo
    fi
    
    # Verify checksums if available
    if [[ -f "${TEMP_DIR}/checksums.md5" ]]; then
        log_info "Verifying checksums..."
        if (cd "$TEMP_DIR" && md5sum -c checksums.md5 &>/dev/null); then
            log_success "Checksum verification passed"
        else
            log_warning "Some checksums failed (files may have been modified)"
        fi
    fi
    
    # Ask for confirmation
    read -p "Continue with restore? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Restore cancelled"
        rm -rf "$TEMP_DIR"
        return 0
    fi
    
    # Restore configuration files
    if [[ -d "${TEMP_DIR}/config/.xtreme-xai" ]]; then
        cp -r "${TEMP_DIR}/config/.xtreme-xai" "${HOME}/" 2>/dev/null || true
        log_success "Configuration restored to ~/.xtreme-xai"
    fi
    
    if [[ -d "${TEMP_DIR}/config/xtreme-xai" ]]; then
        mkdir -p "${HOME}/.config"
        cp -r "${TEMP_DIR}/config/xtreme-xai" "${HOME}/.config/" 2>/dev/null || true
        log_success "Configuration restored to ~/.config/xtreme-xai"
    fi
    
    if [[ -d "${TEMP_DIR}/config/system" ]]; then
        mkdir -p "${HOME}/xtreme_ai_system"
        cp -r "${TEMP_DIR}/config/system" "${HOME}/xtreme_ai_system/config" 2>/dev/null || true
        log_success "System configuration restored"
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    echo
    log_success "Restore completed successfully!"
    log_info "You may need to restart services for changes to take effect"
}

# Cleanup old backups
cleanup_old_backups() {
    log_info "Cleaning up old backups..."
    
    local removed=0
    
    # Internal storage cleanup
    if [[ -d "$BACKUP_DIR" ]]; then
        # Remove backups older than MAX_BACKUP_AGE_DAYS
        while IFS= read -r -d '' backup; do
            rm -f "$backup"
            removed=$((removed + 1))
        done < <(find "$BACKUP_DIR" -name "xai_backup_*.tar.gz" -mtime +$MAX_BACKUP_AGE_DAYS -print0 2>/dev/null)
        
        # Keep only MAX_BACKUPS most recent backups
        local backup_count=$(ls -1 "$BACKUP_DIR"/xai_backup_*.tar.gz 2>/dev/null | wc -l)
        if [[ $backup_count -gt $MAX_BACKUPS ]]; then
            local to_delete=$((backup_count - MAX_BACKUPS))
            ls -1t "$BACKUP_DIR"/xai_backup_*.tar.gz | tail -n $to_delete | xargs rm -f
            removed=$((removed + to_delete))
        fi
    fi
    
    if [[ $removed -gt 0 ]]; then
        log_success "Removed $removed old backup(s)"
    else
        log_info "No cleanup needed"
    fi
}

# Validate all backups
validate_backups() {
    log_info "Validating all backups..."
    
    local total=0
    local valid=0
    local corrupted=0
    
    for backup in "$BACKUP_DIR"/xai_backup_*.tar.gz "$SD_BACKUP_DIR"/xai_backup_*.tar.gz; do
        if [[ -f "$backup" ]]; then
            total=$((total + 1))
            echo -n "  Checking $(basename "$backup")... "
            if tar -tzf "$backup" &>/dev/null; then
                echo -e "${GREEN}✓${NC}"
                valid=$((valid + 1))
            else
                echo -e "${RED}✗ (corrupted)${NC}"
                corrupted=$((corrupted + 1))
            fi
        fi
    done
    
    echo
    log_info "Total: $total backups"
    log_success "Valid: $valid backups"
    if [[ $corrupted -gt 0 ]]; then
        log_error "Corrupted: $corrupted backup(s)"
    fi
}

# Delete a specific backup
delete_backup() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        log_error "No backup file specified"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        backup_file="${BACKUP_DIR}/${backup_file}"
        if [[ ! -f "$backup_file" ]]; then
            backup_file="${SD_BACKUP_DIR}/${backup_file}"
        fi
    fi
    
    if [[ -f "$backup_file" ]]; then
        rm -f "$backup_file"
        log_success "Backup deleted: $(basename "$backup_file")"
    else
        log_error "Backup file not found"
        return 1
    fi
}

# Show help
show_help() {
    echo "XTREME XAI Backup Manager v4.0"
    echo "© Elektronikx-Center-Matte ® | Alexander Mathey ©"
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  create              Create a new backup"
    echo "  list                List all backups"
    echo "  restore [FILE]      Restore from a backup"
    echo "  delete [FILE]       Delete a specific backup"
    echo "  cleanup             Remove old backups"
    echo "  validate            Validate all backups"
    echo "  help                Show this help message"
    echo
    echo "Examples:"
    echo "  $0 create"
    echo "  $0 list"
    echo "  $0 restore xai_backup_20240101_120000.tar.gz"
    echo "  $0 validate"
    echo
}

# Main function
main() {
    local command="${1:-create}"
    
    case "$command" in
        create)
            create_backup
            ;;
        list)
            list_backups
            ;;
        restore)
            restore_backup "$2"
            ;;
        delete)
            delete_backup "$2"
            ;;
        cleanup)
            cleanup_old_backups
            ;;
        validate)
            validate_backups
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
