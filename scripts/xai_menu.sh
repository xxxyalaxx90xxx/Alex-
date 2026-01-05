#!/bin/bash

################################################################################
# XAI Interactive Menu v4.0 (überarbeitet)
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Interaktives Hauptmenü für XTREME-XAI-ULTIMATE
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/xtreme_ai_system"
CORE_DIR="${SCRIPT_DIR}/../core"

# Clear screen function
clear_screen() {
    clear
}

# Show banner
show_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                    XTREME XAI v4.0 MENU                          ║
║            © Elektronikx-Center-Matte ®                          ║
║            Entwicklung: Alexander Mathey ©                       ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Show system status
show_system_status() {
    echo -e "${CYAN}═══ System Status ═══${NC}"
    
    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' 2>/dev/null || echo "N/A")
    echo -e "  CPU Usage: ${YELLOW}${cpu_usage}%${NC}"
    
    # Memory
    local mem_used=$(free -m | awk '/^Mem:/ {printf "%.1f", $3/1024}')
    local mem_total=$(free -m | awk '/^Mem:/ {printf "%.1f", $2/1024}')
    local mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    echo -e "  Memory: ${YELLOW}${mem_used}GB${NC} / ${mem_total}GB (${mem_percent}%)"
    
    # Disk
    local disk_used=$(df -h "$HOME" | awk 'NR==2 {print $3}')
    local disk_total=$(df -h "$HOME" | awk 'NR==2 {print $2}')
    local disk_percent=$(df "$HOME" | awk 'NR==2 {print $5}')
    echo -e "  Disk: ${YELLOW}${disk_used}${NC} / ${disk_total} (${disk_percent})"
    
    echo
}

# Main menu
show_main_menu() {
    clear_screen
    show_banner
    show_system_status
    
    echo -e "${WHITE}${BOLD}Hauptmenü:${NC}"
    echo
    echo -e "${CYAN}━━━ System & Wartung ━━━${NC}"
    echo -e "  ${GREEN}1)${NC} System-Check ausführen"
    echo -e "  ${GREEN}2)${NC} System optimieren"
    echo -e "  ${GREEN}3)${NC} Backup erstellen"
    echo -e "  ${GREEN}4)${NC} Backup wiederherstellen"
    echo
    echo -e "${CYAN}━━━ Monitoring & Security ━━━${NC}"
    echo -e "  ${GREEN}5)${NC} Performance-Monitor"
    echo -e "  ${GREEN}6)${NC} Security-Check"
    echo -e "  ${GREEN}7)${NC} Storage-Optimizer"
    echo -e "  ${GREEN}8)${NC} System-Doctor"
    echo
    echo -e "${CYAN}━━━ Erweiterte Features ━━━${NC}"
    echo -e "  ${MAGENTA}9)${NC} Emulator-Installation"
    echo -e "  ${MAGENTA}10)${NC} VPN-Manager"
    echo -e "  ${MAGENTA}11)${NC} Tor-Integration"
    echo
    echo -e "${CYAN}━━━ Anwendungsentwicklung ━━━${NC}"
    echo -e "  ${BLUE}12)${NC} App Builder (Python/Node/CLI)"
    echo -e "  ${BLUE}13)${NC} APK Builder (Android)"
    echo -e "  ${BLUE}14)${NC} Web App Generator (PWA)"
    echo -e "  ${BLUE}15)${NC} AI Integration (Cyborg System)"
    echo
    echo -e "${CYAN}━━━ Cloud & Infrastructure ━━━${NC}"
    echo -e "  ${YELLOW}16)${NC} Cloud Integrator (Storage)"
    echo -e "  ${YELLOW}17)${NC} Container Manager"
    echo -e "  ${YELLOW}18)${NC} Automation Suite"
    echo
    echo -e "${CYAN}━━━ Dashboard & Sonstiges ━━━${NC}"
    echo -e "  ${YELLOW}19)${NC} Dashboard starten"
    echo -e "  ${YELLOW}20)${NC} Logs anzeigen"
    echo -e "  ${YELLOW}21)${NC} Einstellungen"
    echo
    echo -e "  ${RED}0)${NC} Beenden"
    echo
}

# System check
menu_system_check() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ System-Check ═══${NC}"
    echo
    
    if [[ -f "$CORE_DIR/system_check.sh" ]]; then
        bash "$CORE_DIR/system_check.sh"
    else
        echo -e "${RED}Error: system_check.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# System optimization
menu_optimization() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ System-Optimierung ═══${NC}"
    echo
    
    if [[ -f "$CORE_DIR/optimization.sh" ]]; then
        bash "$CORE_DIR/optimization.sh"
    else
        echo -e "${RED}Error: optimization.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Backup menu
menu_backup() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Backup erstellen ═══${NC}"
    echo
    
    if [[ -f "$CORE_DIR/backup_manager.sh" ]]; then
        bash "$CORE_DIR/backup_manager.sh" create
    else
        echo -e "${RED}Error: backup_manager.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Restore menu
menu_restore() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Backup wiederherstellen ═══${NC}"
    echo
    
    if [[ -f "$CORE_DIR/backup_manager.sh" ]]; then
        bash "$CORE_DIR/backup_manager.sh" list
        echo
        read -p "Backup-Datei eingeben (oder Enter zum Abbrechen): " backup_file
        if [[ -n "$backup_file" ]]; then
            bash "$CORE_DIR/backup_manager.sh" restore "$backup_file"
        fi
    else
        echo -e "${RED}Error: backup_manager.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Performance monitor
menu_performance() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Performance-Monitor ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/performance.sh" ]]; then
        bash "$SCRIPT_DIR/performance.sh"
    else
        echo -e "${YELLOW}Performance-Script wird gestartet...${NC}"
        echo
        
        # Simple inline performance monitor
        echo "CPU und Memory Überwachung (Ctrl+C zum Beenden)"
        echo "================================================"
        
        while true; do
            clear_screen
            echo -e "${CYAN}${BOLD}═══ Live Performance ═══${NC}"
            echo
            
            # CPU
            echo -e "${WHITE}CPU:${NC}"
            top -bn1 | head -5
            echo
            
            # Memory
            echo -e "${WHITE}Memory:${NC}"
            free -h
            echo
            
            # Top processes
            echo -e "${WHITE}Top Processes:${NC}"
            ps aux --sort=-%mem | head -6
            echo
            
            echo "Aktualisierung in 2 Sekunden... (Ctrl+C zum Beenden)"
            sleep 2
        done
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Security check
menu_security() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Security-Check ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/security.sh" ]]; then
        bash "$SCRIPT_DIR/security.sh"
    else
        echo -e "${YELLOW}Führe Security-Check aus...${NC}"
        echo
        
        # Basic security checks
        echo "[1/5] Checking file permissions..."
        if [[ -d "$INSTALL_DIR" ]]; then
            find "$INSTALL_DIR" -type f -perm -002 2>/dev/null | wc -l | awk '{print "  World-writable files: " $1}'
        fi
        
        echo "[2/5] Checking for suspicious processes..."
        ps aux | grep -E "nc|netcat|wget.*sh|curl.*sh" | grep -v grep || echo "  No suspicious processes found"
        
        echo "[3/5] Checking network connections..."
        if command -v netstat &>/dev/null; then
            netstat -tunlp 2>/dev/null | grep LISTEN | wc -l | awk '{print "  Listening ports: " $1}'
        else
            echo "  netstat not available"
        fi
        
        echo "[4/5] Checking system logs for errors..."
        if [[ -d "$INSTALL_DIR/logs" ]]; then
            grep -i "error" "$INSTALL_DIR"/logs/*.log 2>/dev/null | tail -5 || echo "  No recent errors found"
        fi
        
        echo "[5/5] Security check completed"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Emulator setup
menu_emulator() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Emulator-Setup ═══${NC}"
    echo
    
    if [[ -f "$CORE_DIR/emulator_setup.sh" ]]; then
        bash "$CORE_DIR/emulator_setup.sh"
    else
        echo -e "${RED}Error: emulator_setup.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Dashboard
menu_dashboard() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Dashboard ═══${NC}"
    echo
    
    echo -e "${YELLOW}Dashboard-Optionen:${NC}"
    echo
    echo "  1) Web-Dashboard starten (Port 3000)"
    echo "  2) Web-Dashboard im Browser öffnen"
    echo "  3) Dashboard-Status"
    echo "  0) Zurück"
    echo
    read -p "Wähle Option: " dashboard_choice
    
    case $dashboard_choice in
        1)
            if [[ -d "$INSTALL_DIR/dashboards/main" ]]; then
                cd "$INSTALL_DIR/dashboards/main"
                echo "Starte Dashboard..."
                npm start
            else
                echo -e "${RED}Dashboard nicht gefunden${NC}"
            fi
            ;;
        2)
            if command -v termux-open-url &>/dev/null; then
                termux-open-url "http://localhost:3000"
            else
                echo "Öffne http://localhost:3000 im Browser"
            fi
            ;;
        3)
            if pgrep -f "node.*server.js" &>/dev/null; then
                echo -e "${GREEN}Dashboard läuft${NC}"
                echo "PID: $(pgrep -f "node.*server.js")"
            else
                echo -e "${YELLOW}Dashboard läuft nicht${NC}"
            fi
            ;;
    esac
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Logs viewer
menu_logs() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Logs anzeigen ═══${NC}"
    echo
    
    if [[ -d "$INSTALL_DIR/logs" ]]; then
        echo "Verfügbare Logs:"
        ls -1 "$INSTALL_DIR"/logs/*.log 2>/dev/null | nl
        echo
        read -p "Log-Nummer eingeben (oder Enter zum Abbrechen): " log_num
        
        if [[ -n "$log_num" ]]; then
            log_file=$(ls -1 "$INSTALL_DIR"/logs/*.log 2>/dev/null | sed -n "${log_num}p")
            if [[ -f "$log_file" ]]; then
                less "$log_file"
            fi
        fi
    else
        echo "Keine Logs gefunden"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Settings
menu_settings() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Einstellungen ═══${NC}"
    echo
    
    echo "  1) System-Informationen"
    echo "  2) Konfiguration anzeigen"
    echo "  3) Backup-Verwaltung"
    echo "  4) Cache leeren"
    echo "  0) Zurück"
    echo
    read -p "Wähle Option: " settings_choice
    
    case $settings_choice in
        1)
            echo
            echo "=== System-Informationen ==="
            echo "Hostname: $(hostname)"
            echo "User: $(whoami)"
            echo "Kernel: $(uname -r)"
            echo "Architektur: $(uname -m)"
            command -v termux-info &>/dev/null && termux-info | head -10
            ;;
        2)
            if [[ -f "$HOME/.config/xtreme-xai/emulator.conf" ]]; then
                less "$HOME/.config/xtreme-xai/emulator.conf"
            else
                echo "Keine Konfiguration gefunden"
            fi
            ;;
        3)
            if [[ -f "$CORE_DIR/backup_manager.sh" ]]; then
                bash "$CORE_DIR/backup_manager.sh" list
            fi
            ;;
        4)
            echo "Leere Caches..."
            rm -rf "$INSTALL_DIR/data/cache"/* 2>/dev/null
            rm -rf "$INSTALL_DIR/data/temp"/* 2>/dev/null
            echo "Cache geleert"
            ;;
    esac
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Storage optimizer menu
menu_storage_optimizer() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Storage-Optimizer ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/storage_optimizer.sh" ]]; then
        bash "$SCRIPT_DIR/storage_optimizer.sh"
    else
        echo -e "${RED}Error: storage_optimizer.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# System doctor menu
menu_system_doctor() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ System-Doctor ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/system_doctor.sh" ]]; then
        bash "$SCRIPT_DIR/system_doctor.sh"
    else
        echo -e "${RED}Error: system_doctor.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Emulator installer menu
menu_emulator_installer() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Emulator-Installation ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/emulator_installer.sh" ]]; then
        bash "$SCRIPT_DIR/emulator_installer.sh"
    else
        echo -e "${RED}Error: emulator_installer.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# VPN manager menu
menu_vpn_manager() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ VPN-Manager ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/vpn_manager.sh" ]]; then
        bash "$SCRIPT_DIR/vpn_manager.sh"
    else
        echo -e "${RED}Error: vpn_manager.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Tor integration menu
menu_tor_integration() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Tor-Integration ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/tor_integration.sh" ]]; then
        bash "$SCRIPT_DIR/tor_integration.sh"
    else
        echo -e "${RED}Error: tor_integration.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# App builder menu
menu_app_builder() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Application Builder ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/app_builder.sh" ]]; then
        bash "$SCRIPT_DIR/app_builder.sh"
    else
        echo -e "${RED}Error: app_builder.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# APK builder menu
menu_apk_builder() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ APK Builder ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/apk_builder.sh" ]]; then
        bash "$SCRIPT_DIR/apk_builder.sh"
    else
        echo -e "${RED}Error: apk_builder.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Web app generator menu
menu_webapp_generator() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Web App Generator ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/webapp_generator.sh" ]]; then
        bash "$SCRIPT_DIR/webapp_generator.sh"
    else
        echo -e "${RED}Error: webapp_generator.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# AI integration menu
menu_ai_integration() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ AI Integration (Cyborg System) ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/ai_integration.sh" ]]; then
        bash "$SCRIPT_DIR/ai_integration.sh"
    else
        echo -e "${RED}Error: ai_integration.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Cloud integrator menu
menu_cloud_integrator() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Cloud Integrator ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/cloud_integrator.sh" ]]; then
        bash "$SCRIPT_DIR/cloud_integrator.sh"
    else
        echo -e "${RED}Error: cloud_integrator.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Container manager menu
menu_container_manager() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Container Manager ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/container_manager.sh" ]]; then
        bash "$SCRIPT_DIR/container_manager.sh"
    else
        echo -e "${RED}Error: container_manager.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Automation suite menu
menu_automation_suite() {
    clear_screen
    echo -e "${CYAN}${BOLD}═══ Automation Suite ═══${NC}"
    echo
    
    if [[ -f "$SCRIPT_DIR/automation_suite.sh" ]]; then
        bash "$SCRIPT_DIR/automation_suite.sh"
    else
        echo -e "${RED}Error: automation_suite.sh nicht gefunden${NC}"
    fi
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
}

# Main loop
main() {
    while true; do
        show_main_menu
        read -p "Wähle Option: " choice
        
        case $choice in
            1) menu_system_check ;;
            2) menu_optimization ;;
            3) menu_backup ;;
            4) menu_restore ;;
            5) menu_performance ;;
            6) menu_security ;;
            7) menu_storage_optimizer ;;
            8) menu_system_doctor ;;
            9) menu_emulator_installer ;;
            10) menu_vpn_manager ;;
            11) menu_tor_integration ;;
            12) menu_app_builder ;;
            13) menu_apk_builder ;;
            14) menu_webapp_generator ;;
            15) menu_ai_integration ;;
            16) menu_cloud_integrator ;;
            17) menu_container_manager ;;
            18) menu_automation_suite ;;
            19) menu_dashboard ;;
            20) menu_logs ;;
            21) menu_settings ;;
            0)
                clear_screen
                echo -e "${GREEN}Auf Wiedersehen!${NC}"
                echo -e "${CYAN}© Elektronikx-Center-Matte ®${NC}"
                echo -e "${CYAN}by Alexander Mathey (xyalaxxx90@gmail.com)${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Ungültige Auswahl${NC}"
                sleep 1
                ;;
        esac
    done
}

# Run main loop
main "$@"
