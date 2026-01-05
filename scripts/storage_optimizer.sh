#!/bin/bash

################################################################################
# Storage Optimizer Script
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Automatische Speicherbereinigung und -optimierung für XTREME-XAI
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${HOME}/xtreme_ai_system"
SD_CARD_DIR="/storage/emulated/0/XAI"
CACHE_THRESHOLD_MB=500
TEMP_FILE_AGE_DAYS=7

log_info() {
    echo -e "${BLUE}[STORAGE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show storage banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         XTREME XAI Storage Optimizer v4.0             ║"
    echo "║     © Elektronikx-Center-Matte ® | Alexander Mathey © ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Show current storage usage
show_storage_usage() {
    log_info "Aktuelle Speichernutzung:"
    echo
    
    # Internal storage
    if [[ -d "$HOME" ]]; then
        echo -e "${CYAN}Interner Speicher:${NC}"
        df -h "$HOME" | tail -1 | awk '{printf "  Gesamt: %s | Verwendet: %s | Verfügbar: %s | Auslastung: %s\n", $2, $3, $4, $5}'
    fi
    
    # SD card storage
    if [[ -d "/storage/emulated/0" ]]; then
        echo -e "${CYAN}SD-Karte:${NC}"
        df -h "/storage/emulated/0" 2>/dev/null | tail -1 | awk '{printf "  Gesamt: %s | Verwendet: %s | Verfügbar: %s | Auslastung: %s\n", $2, $3, $4, $5}'
    fi
    
    echo
}

# Clean package manager caches
clean_package_caches() {
    log_info "[1/7] Bereinige Package-Manager-Caches..."
    
    local cleaned=0
    
    # Termux pkg cache
    if command -v pkg &>/dev/null; then
        local before=$(du -sm "$PREFIX/var/cache/apt" 2>/dev/null | cut -f1)
        pkg clean 2>/dev/null
        local after=$(du -sm "$PREFIX/var/cache/apt" 2>/dev/null | cut -f1)
        if [[ -n "$before" ]] && [[ -n "$after" ]]; then
            local saved=$((before - after))
            log_success "pkg cache: ${saved}MB freigegeben"
            cleaned=$((cleaned + saved))
        fi
    fi
    
    # Python pip cache
    if command -v pip &>/dev/null; then
        local before_size=$(du -sm "$HOME/.cache/pip" 2>/dev/null | cut -f1)
        pip cache purge &>/dev/null
        local after_size=$(du -sm "$HOME/.cache/pip" 2>/dev/null | cut -f1)
        if [[ -n "$before_size" ]]; then
            local saved=$((before_size - after_size))
            log_success "pip cache: ${saved}MB freigegeben"
            cleaned=$((cleaned + saved))
        fi
    fi
    
    # NPM cache
    if command -v npm &>/dev/null; then
        local before_size=$(du -sm "$HOME/.npm" 2>/dev/null | cut -f1)
        npm cache clean --force &>/dev/null
        local after_size=$(du -sm "$HOME/.npm" 2>/dev/null | cut -f1)
        if [[ -n "$before_size" ]]; then
            local saved=$((before_size - after_size))
            log_success "npm cache: ${saved}MB freigegeben"
            cleaned=$((cleaned + saved))
        fi
    fi
    
    log_info "Gesamt freigegeben: ${cleaned}MB"
}

# Clean application caches
clean_app_caches() {
    log_info "[2/7] Bereinige Anwendungs-Caches..."
    
    local total_size=0
    
    if [[ -d "$INSTALL_DIR/data/cache" ]]; then
        local cache_size=$(du -sm "$INSTALL_DIR/data/cache" 2>/dev/null | cut -f1)
        rm -rf "$INSTALL_DIR/data/cache"/* 2>/dev/null
        mkdir -p "$INSTALL_DIR/data/cache"
        log_success "App-Cache geleert: ${cache_size}MB"
        total_size=$((total_size + cache_size))
    fi
    
    if [[ -d "$INSTALL_DIR/data/temp" ]]; then
        local temp_size=$(du -sm "$INSTALL_DIR/data/temp" 2>/dev/null | cut -f1)
        rm -rf "$INSTALL_DIR/data/temp"/* 2>/dev/null
        mkdir -p "$INSTALL_DIR/data/temp"
        log_success "Temp-Dateien geleert: ${temp_size}MB"
        total_size=$((total_size + temp_size))
    fi
    
    log_info "Gesamt freigegeben: ${total_size}MB"
}

# Clean old log files
clean_old_logs() {
    log_info "[3/7] Bereinige alte Log-Dateien..."
    
    if [[ -d "$INSTALL_DIR/logs" ]]; then
        # Count and size of logs older than 30 days
        local old_logs=$(find "$INSTALL_DIR/logs" -name "*.log" -mtime +30 2>/dev/null | wc -l)
        
        if [[ $old_logs -gt 0 ]]; then
            local log_size=$(find "$INSTALL_DIR/logs" -name "*.log" -mtime +30 -exec du -sm {} + 2>/dev/null | awk '{sum+=$1} END {print sum}')
            find "$INSTALL_DIR/logs" -name "*.log" -mtime +30 -delete 2>/dev/null
            log_success "${old_logs} alte Log-Dateien gelöscht (${log_size}MB)"
        else
            log_info "Keine alten Log-Dateien gefunden"
        fi
        
        # Compress logs older than 7 days
        local logs_to_compress=$(find "$INSTALL_DIR/logs" -name "*.log" -mtime +7 ! -name "*.gz" 2>/dev/null | wc -l)
        if [[ $logs_to_compress -gt 0 ]]; then
            find "$INSTALL_DIR/logs" -name "*.log" -mtime +7 ! -name "*.gz" -exec gzip {} \; 2>/dev/null
            log_success "${logs_to_compress} Log-Dateien komprimiert"
        fi
    fi
}

# Find and list large files
find_large_files() {
    log_info "[4/7] Suche große Dateien (>100MB)..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        local large_files=$(find "$INSTALL_DIR" -type f -size +100M 2>/dev/null | wc -l)
        
        if [[ $large_files -gt 0 ]]; then
            echo -e "${YELLOW}Gefundene große Dateien:${NC}"
            find "$INSTALL_DIR" -type f -size +100M -exec ls -lh {} \; 2>/dev/null | awk '{printf "  %s - %s\n", $5, $9}' | head -10
        else
            log_info "Keine Dateien >100MB gefunden"
        fi
    fi
}

# Find duplicate files
find_duplicates() {
    log_info "[5/7] Suche Duplikate..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        log_info "Analysiere Dateien (kann einige Sekunden dauern)..."
        
        # Find files with same size
        local duplicates=$(find "$INSTALL_DIR" -type f -exec du -b {} + 2>/dev/null | \
            sort -n | \
            awk '{size=$1; $1=""; files[size]=files[size] $0} END {for (s in files) if (gsub(/ /, " ", files[s]) > 1) print files[s]}' | \
            wc -l)
        
        if [[ $duplicates -gt 0 ]]; then
            log_warning "Mögliche Duplikate gefunden: $duplicates Dateien"
            log_info "Führe 'fdupes' für detaillierte Analyse aus (falls installiert)"
        else
            log_info "Keine offensichtlichen Duplikate gefunden"
        fi
    fi
}

# Analyze directory sizes
analyze_directories() {
    log_info "[6/7] Analysiere Verzeichnisgrößen..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "${CYAN}Top 10 größte Verzeichnisse:${NC}"
        du -sh "$INSTALL_DIR"/*/ 2>/dev/null | sort -hr | head -10 | awk '{printf "  %s\t%s\n", $1, $2}'
    fi
    
    echo
    
    # SD card analysis
    if [[ -d "$SD_CARD_DIR" ]]; then
        echo -e "${CYAN}SD-Karte Verzeichnisse:${NC}"
        du -sh "$SD_CARD_DIR"/*/ 2>/dev/null | sort -hr | head -10 | awk '{printf "  %s\t%s\n", $1, $2}'
    fi
}

# Clean temporary files
clean_temp_files() {
    log_info "[7/7] Bereinige temporäre Dateien..."
    
    local temp_dirs=("$HOME/tmp" "$HOME/.cache" "/tmp" "$TMPDIR")
    local total_cleaned=0
    
    for temp_dir in "${temp_dirs[@]}"; do
        if [[ -d "$temp_dir" ]] && [[ -w "$temp_dir" ]]; then
            # Delete files older than TEMP_FILE_AGE_DAYS
            local old_files=$(find "$temp_dir" -type f -mtime +$TEMP_FILE_AGE_DAYS 2>/dev/null | wc -l)
            if [[ $old_files -gt 0 ]]; then
                local temp_size=$(find "$temp_dir" -type f -mtime +$TEMP_FILE_AGE_DAYS -exec du -sm {} + 2>/dev/null | awk '{sum+=$1} END {print sum}')
                find "$temp_dir" -type f -mtime +$TEMP_FILE_AGE_DAYS -delete 2>/dev/null
                log_success "$(basename "$temp_dir"): ${old_files} Dateien gelöscht (${temp_size}MB)"
                total_cleaned=$((total_cleaned + temp_size))
            fi
        fi
    done
    
    log_info "Gesamt freigegeben: ${total_cleaned}MB"
}

# Generate storage report
generate_report() {
    echo
    echo "═══════════════════════════════════════════════════════"
    echo "               Optimierungs-Bericht"
    echo "═══════════════════════════════════════════════════════"
    echo
    
    show_storage_usage
    
    echo -e "${GREEN}Empfehlungen:${NC}"
    echo "  1. Führe regelmäßig Storage-Optimierung aus"
    echo "  2. Verschiebe große Dateien auf SD-Karte"
    echo "  3. Lösche nicht benötigte Backups"
    echo "  4. Komprimiere alte Log-Dateien"
    echo "  5. Überprüfe App-Cache regelmäßig"
    echo
}

# Interactive mode
interactive_mode() {
    show_banner
    show_storage_usage
    
    echo -e "${YELLOW}Möchtest du eine vollständige Optimierung durchführen?${NC}"
    echo "  1) Ja, alles bereinigen"
    echo "  2) Nur Caches leeren"
    echo "  3) Nur Analyse durchführen"
    echo "  4) Abbrechen"
    echo
    read -p "Wähle Option (1-4): " choice
    
    case $choice in
        1)
            clean_package_caches
            clean_app_caches
            clean_old_logs
            find_large_files
            find_duplicates
            analyze_directories
            clean_temp_files
            generate_report
            ;;
        2)
            clean_package_caches
            clean_app_caches
            generate_report
            ;;
        3)
            find_large_files
            find_duplicates
            analyze_directories
            show_storage_usage
            ;;
        4)
            log_info "Abgebrochen"
            exit 0
            ;;
        *)
            log_error "Ungültige Auswahl"
            exit 1
            ;;
    esac
}

# Main function
main() {
    local mode="${1:-interactive}"
    
    if [[ "$mode" == "auto" ]] || [[ "$mode" == "automatic" ]]; then
        show_banner
        clean_package_caches
        clean_app_caches
        clean_old_logs
        clean_temp_files
        generate_report
    elif [[ "$mode" == "quick" ]]; then
        show_banner
        clean_package_caches
        clean_app_caches
        show_storage_usage
    else
        interactive_mode
    fi
    
    log_success "Storage-Optimierung abgeschlossen!"
}

main "$@"
