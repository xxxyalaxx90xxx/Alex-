#!/bin/bash

################################################################################
# System Doctor Script
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Umfassende Systemdiagnose und Problemlösung für XTREME-XAI
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${HOME}/xtreme_ai_system"
LOG_DIR="${INSTALL_DIR}/logs"
DIAGNOSTIC_LOG="${LOG_DIR}/diagnostic_$(date +%Y%m%d_%H%M%S).log"

log_info() {
    echo -e "${BLUE}[DOCTOR]${NC} $1" | tee -a "$DIAGNOSTIC_LOG"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1" | tee -a "$DIAGNOSTIC_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$DIAGNOSTIC_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$DIAGNOSTIC_LOG"
}

log_critical() {
    echo -e "${RED}${BOLD}[CRITICAL]${NC} $1" | tee -a "$DIAGNOSTIC_LOG"
}

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Show banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         XTREME XAI System Doctor v4.0                 ║"
    echo "║     © Elektronikx-Center-Matte ® | Alexander Mathey © ║"
    echo "║                                                        ║"
    echo "║     🩺 Umfassende Systemdiagnose & Problemlösung     ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

# System Overview
show_system_overview() {
    log_info "System-Übersicht wird erstellt..."
    echo
    
    # Hostname and User
    echo -e "${CYAN}═══ Basis-Informationen ═══${NC}"
    echo "  Hostname: $(hostname)"
    echo "  Benutzer: $(whoami)"
    echo "  Datum: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    
    # OS Information
    echo -e "${CYAN}═══ Betriebssystem ═══${NC}"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "  Distribution: $NAME"
        echo "  Version: $VERSION"
    elif command -v termux-info &>/dev/null; then
        echo "  Umgebung: Termux (Android)"
        termux-info 2>/dev/null | head -10
    fi
    echo "  Kernel: $(uname -r)"
    echo "  Architektur: $(uname -m)"
    echo
}

# Hardware Diagnostics
diagnose_hardware() {
    log_info "[1/10] Hardware-Diagnose..."
    echo
    
    # CPU
    echo -e "${CYAN}▼ CPU${NC}"
    local cpu_count=$(nproc)
    echo "  Kerne: $cpu_count"
    
    if [[ -f /proc/cpuinfo ]]; then
        local cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d':' -f2 | xargs)
        [[ -n "$cpu_model" ]] && echo "  Modell: $cpu_model"
    fi
    
    # CPU Frequency
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
        local freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
        echo "  Frequenz: $((freq / 1000))MHz"
    fi
    
    # CPU Governor
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        local governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
        echo "  Governor: $governor"
        [[ "$governor" != "performance" ]] && log_warning "Governor ist nicht auf 'performance' gesetzt"
    fi
    
    # Temperature
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        local temp_c=$((temp / 1000))
        echo "  Temperatur: ${temp_c}°C"
        
        if [[ $temp_c -gt 85 ]]; then
            log_critical "CPU-Temperatur kritisch hoch!"
        elif [[ $temp_c -gt 75 ]]; then
            log_warning "CPU-Temperatur erhöht"
        else
            log_success "CPU-Temperatur normal"
        fi
    fi
    
    echo
    
    # Memory
    echo -e "${CYAN}▼ Arbeitsspeicher${NC}"
    local total_mem=$(free -h | awk '/^Mem:/ {print $2}')
    local used_mem=$(free -h | awk '/^Mem:/ {print $3}')
    local avail_mem=$(free -h | awk '/^Mem:/ {print $7}')
    local mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    
    echo "  Gesamt: $total_mem"
    echo "  Verwendet: $used_mem ($mem_percent%)"
    echo "  Verfügbar: $avail_mem"
    
    if [[ $mem_percent -gt 90 ]]; then
        log_error "Arbeitsspeicher kritisch voll!"
    elif [[ $mem_percent -gt 80 ]]; then
        log_warning "Arbeitsspeicher stark belegt"
    else
        log_success "Arbeitsspeicher-Nutzung normal"
    fi
    
    echo
}

# Storage Diagnostics
diagnose_storage() {
    log_info "[2/10] Speicher-Diagnose..."
    echo
    
    # Internal storage
    echo -e "${CYAN}▼ Interner Speicher${NC}"
    local disk_usage=$(df -h "$HOME" | awk 'NR==2 {print $5}' | tr -d '%')
    local disk_avail=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    
    df -h "$HOME" | tail -1 | awk '{printf "  Gesamt: %s | Verwendet: %s (%s) | Verfügbar: %s\n", $2, $3, $5, $4}'
    
    if [[ $disk_usage -gt 95 ]]; then
        log_critical "Speicher fast voll!"
        echo "  → Empfehlung: Führe Storage-Optimizer aus"
    elif [[ $disk_usage -gt 85 ]]; then
        log_warning "Speicher wird knapp"
    else
        log_success "Speicher-Nutzung normal"
    fi
    
    # SD Card
    if [[ -d "/storage/emulated/0" ]]; then
        echo
        echo -e "${CYAN}▼ SD-Karte${NC}"
        df -h "/storage/emulated/0" 2>/dev/null | tail -1 | awk '{printf "  Gesamt: %s | Verwendet: %s (%s) | Verfügbar: %s\n", $2, $3, $5, $4}'
    fi
    
    echo
}

# Network Diagnostics
diagnose_network() {
    log_info "[3/10] Netzwerk-Diagnose..."
    echo
    
    # Internet connectivity
    echo -e "${CYAN}▼ Internetverbindung${NC}"
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        log_success "Internet erreichbar"
        
        # DNS check
        if ping -c 1 -W 2 google.com &>/dev/null; then
            log_success "DNS funktioniert"
        else
            log_error "DNS-Auflösung fehlgeschlagen"
        fi
    else
        log_error "Keine Internetverbindung"
    fi
    
    # Active connections
    if command -v netstat &>/dev/null; then
        local connections=$(netstat -tun 2>/dev/null | grep ESTABLISHED | wc -l)
        echo "  Aktive Verbindungen: $connections"
    fi
    
    echo
}

# Process Diagnostics
diagnose_processes() {
    log_info "[4/10] Prozess-Diagnose..."
    echo
    
    # Total processes
    local total_procs=$(ps aux | wc -l)
    echo "  Gesamt Prozesse: $total_procs"
    
    # Zombie processes
    local zombies=$(ps aux | awk '{if ($8 == "Z") print $0}' | wc -l)
    if [[ $zombies -gt 0 ]]; then
        log_warning "$zombies Zombie-Prozess(e) gefunden"
    else
        log_success "Keine Zombie-Prozesse"
    fi
    
    # High CPU processes
    echo
    echo -e "${CYAN}▼ Prozesse mit hoher CPU-Last:${NC}"
    ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "  %s: %.1f%% CPU - %s\n", $2, $3, $11}'
    
    # High memory processes
    echo
    echo -e "${CYAN}▼ Prozesse mit hohem RAM-Verbrauch:${NC}"
    ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "  %s: %.1f%% RAM - %s\n", $2, $4, $11}'
    
    echo
}

# Installation Diagnostics
diagnose_installation() {
    log_info "[5/10] Installations-Diagnose..."
    echo
    
    # Check if XAI is installed
    if [[ -d "$INSTALL_DIR" ]]; then
        log_success "XTREME XAI installiert"
        
        # Check directory structure
        local required_dirs=("bin" "config" "data" "logs" "scripts")
        local missing_dirs=0
        
        for dir in "${required_dirs[@]}"; do
            if [[ ! -d "$INSTALL_DIR/$dir" ]]; then
                log_warning "Verzeichnis fehlt: $dir"
                missing_dirs=$((missing_dirs + 1))
            fi
        done
        
        if [[ $missing_dirs -eq 0 ]]; then
            log_success "Alle erforderlichen Verzeichnisse vorhanden"
        else
            log_warning "$missing_dirs Verzeichnis(se) fehlen"
        fi
        
        # Check scripts
        local script_dir="$(dirname "$0")"
        local scripts=("system_check.sh" "optimization.sh" "backup_manager.sh")
        local missing_scripts=0
        
        for script in "${scripts[@]}"; do
            if [[ ! -f "$script_dir/../core/$script" ]]; then
                log_warning "Script fehlt: $script"
                missing_scripts=$((missing_scripts + 1))
            fi
        done
        
        if [[ $missing_scripts -eq 0 ]]; then
            log_success "Alle Core-Scripts vorhanden"
        fi
    else
        log_error "XTREME XAI nicht installiert"
        echo "  → Empfehlung: Führe install.sh aus"
    fi
    
    echo
}

# Log Diagnostics
diagnose_logs() {
    log_info "[6/10] Log-Diagnose..."
    echo
    
    if [[ -d "$LOG_DIR" ]]; then
        # Count logs
        local log_count=$(find "$LOG_DIR" -name "*.log" 2>/dev/null | wc -l)
        echo "  Log-Dateien: $log_count"
        
        # Total log size
        local log_size=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
        echo "  Gesamt-Größe: $log_size"
        
        # Recent errors
        echo
        echo -e "${CYAN}▼ Letzte Fehler in Logs:${NC}"
        grep -i "error\|fail\|critical" "$LOG_DIR"/*.log 2>/dev/null | tail -5 | while read -r line; do
            echo "  $line"
        done || echo "  Keine Fehler gefunden"
        
        # Check log rotation
        local old_logs=$(find "$LOG_DIR" -name "*.log" -mtime +30 2>/dev/null | wc -l)
        if [[ $old_logs -gt 10 ]]; then
            log_warning "$old_logs alte Logs gefunden (>30 Tage)"
            echo "  → Empfehlung: Führe Log-Bereinigung aus"
        fi
    else
        log_warning "Log-Verzeichnis nicht gefunden"
    fi
    
    echo
}

# Security Check
diagnose_security() {
    log_info "[7/10] Sicherheits-Check..."
    echo
    
    # Check file permissions
    if [[ -d "$INSTALL_DIR" ]]; then
        local writable=$(find "$INSTALL_DIR" -type f -perm -002 2>/dev/null | wc -l)
        if [[ $writable -gt 0 ]]; then
            log_warning "$writable Dateien sind world-writable"
        else
            log_success "Dateiberechtigungen korrekt"
        fi
    fi
    
    # Check for suspicious processes
    local suspicious=0
    for proc in nc netcat ncat; do
        if pgrep -x "$proc" &>/dev/null; then
            log_warning "Verdächtiger Prozess: $proc"
            suspicious=$((suspicious + 1))
        fi
    done
    
    if [[ $suspicious -eq 0 ]]; then
        log_success "Keine verdächtigen Prozesse gefunden"
    fi
    
    echo
}

# Performance Check
diagnose_performance() {
    log_info "[8/10] Performance-Check..."
    echo
    
    # Load average
    local load=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)
    local cpu_count=$(nproc)
    echo "  Load Average (1min): $load (CPUs: $cpu_count)"
    
    # I/O wait
    if command -v iostat &>/dev/null; then
        local iowait=$(iostat -c 1 2 | tail -1 | awk '{print $4}')
        echo "  I/O Wait: ${iowait}%"
    fi
    
    # Quick CPU test
    echo "  Führe CPU-Test durch..."
    local start_time=$(date +%s%N)
    for i in {1..10000}; do
        : $((i * i))
    done
    local end_time=$(date +%s%N)
    local duration=$(((end_time - start_time) / 1000000))
    
    echo "  CPU-Test: ${duration}ms"
    
    if [[ $duration -lt 100 ]]; then
        log_success "Performance: Ausgezeichnet"
    elif [[ $duration -lt 500 ]]; then
        log_success "Performance: Gut"
    else
        log_warning "Performance: Moderat"
    fi
    
    echo
}

# Battery Status (Termux only)
diagnose_battery() {
    log_info "[9/10] Batterie-Status..."
    echo
    
    if command -v termux-battery-status &>/dev/null; then
        local battery_json=$(termux-battery-status 2>/dev/null)
        if [[ -n "$battery_json" ]]; then
            local battery_level=$(echo "$battery_json" | grep -o '"percentage":[0-9]*' | cut -d':' -f2)
            local battery_status=$(echo "$battery_json" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
            
            echo "  Level: ${battery_level}%"
            echo "  Status: $battery_status"
            
            if [[ $battery_level -lt 20 ]]; then
                log_warning "Batterie schwach"
            else
                log_success "Batterie OK"
            fi
        fi
    else
        log_info "Batterie-Monitoring nicht verfügbar"
    fi
    
    echo
}

# Generate recommendations
generate_recommendations() {
    log_info "[10/10] Erstelle Empfehlungen..."
    echo
    
    echo -e "${YELLOW}═══ Empfehlungen ═══${NC}"
    
    # Memory check
    local mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    if [[ $mem_percent -gt 80 ]]; then
        echo "  • Arbeitsspeicher optimieren (bash core/optimization.sh)"
    fi
    
    # Disk check
    local disk_usage=$(df "$HOME" | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ $disk_usage -gt 80 ]]; then
        echo "  • Speicher bereinigen (bash scripts/storage_optimizer.sh)"
    fi
    
    # Check if logs are old
    if [[ -d "$LOG_DIR" ]]; then
        local old_logs=$(find "$LOG_DIR" -name "*.log" -mtime +30 2>/dev/null | wc -l)
        if [[ $old_logs -gt 10 ]]; then
            echo "  • Alte Logs bereinigen"
        fi
    fi
    
    # General recommendations
    echo "  • Regelmäßige Backups erstellen (bash core/backup_manager.sh create)"
    echo "  • Security-Scans durchführen (bash scripts/security.sh)"
    echo "  • System-Updates installieren (pkg update && pkg upgrade)"
    
    echo
}

# Generate full report
generate_report() {
    echo
    echo "═══════════════════════════════════════════════════════"
    echo "               Diagnose-Bericht"
    echo "═══════════════════════════════════════════════════════"
    echo
    echo "Datum: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Log-Datei: $DIAGNOSTIC_LOG"
    echo
    echo "Status: Diagnose abgeschlossen"
    echo
    log_success "Vollständiger Bericht in $DIAGNOSTIC_LOG gespeichert"
}

# Main function
main() {
    show_banner
    
    log_info "Starte System-Diagnose..."
    echo "Log wird geschrieben nach: $DIAGNOSTIC_LOG"
    echo
    
    show_system_overview
    diagnose_hardware
    diagnose_storage
    diagnose_network
    diagnose_processes
    diagnose_installation
    diagnose_logs
    diagnose_security
    diagnose_performance
    diagnose_battery
    generate_recommendations
    generate_report
    
    log_success "System-Diagnose abgeschlossen!"
}

main "$@"
