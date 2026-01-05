#!/bin/bash
# XAI v4.0.0 - XAI Launcher
# Entwickler: Alexander Mathey ©
# Organisation: Elektronikx-Center-Matte ®
# Datum: 2026-01-05

# Farben für bessere UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# XAI Verzeichnisse
XAI_HOME="$HOME/xai"
XAI_CONFIG="$XAI_HOME/config"
XAI_LOGS="$XAI_HOME/logs"
XAI_VERSION="4.0.0"

# Umgebungsvariablen laden
if [ -f "$XAI_CONFIG/env.sh" ]; then
    source "$XAI_CONFIG/env.sh"
fi

# Hilfsfunktionen
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Banner anzeigen
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║    ██╗  ██╗████████╗██████╗ ███████╗███╗   ███╗███████╗                ║
║    ╚██╗██╔╝╚══██╔══╝██╔══██╗██╔════╝████╗ ████║██╔════╝                ║
║     ╚███╔╝    ██║   ██████╔╝█████╗  ██╔████╔██║█████╗                  ║
║     ██╔██╗    ██║   ██╔══██╗██╔══╝  ██║╚██╔╝██║██╔══╝                  ║
║    ██╔╝ ██╗   ██║   ██║  ██║███████╗██║ ╚═╝ ██║███████╗                ║
║    ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝                ║
║                                                                          ║
║                      XAI v4.0.0 - Ultimate AI System                    ║
║                      Optimiert für Termux/Android                       ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${WHITE}© Elektronikx-Center-Matte ® - Alexander Mathey © 2026${NC}\n"
}

# System-Status anzeigen
show_status() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         System-Status                                      ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    # XAI Version
    echo -e "${YELLOW}XAI Version:${NC} $XAI_VERSION"
    
    # System Info
    echo -e "\n${WHITE}System:${NC}"
    echo -e "${CYAN}├──${NC} Hostname: $(hostname)"
    echo -e "${CYAN}├──${NC} Kernel: $(uname -r)"
    echo -e "${CYAN}└──${NC} Architektur: $(uname -m)"
    
    # CPU Info
    cpu_count=$(nproc)
    echo -e "\n${WHITE}CPU:${NC}"
    echo -e "${CYAN}├──${NC} Kerne: $cpu_count"
    if [ -f /proc/cpuinfo ]; then
        cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)
        if [ -n "$cpu_model" ]; then
            echo -e "${CYAN}└──${NC} Modell: $cpu_model"
        fi
    fi
    
    # RAM Info
    echo -e "\n${WHITE}RAM:${NC}"
    total_ram=$(free -h | awk 'NR==2 {print $2}')
    used_ram=$(free -h | awk 'NR==2 {print $3}')
    free_ram=$(free -h | awk 'NR==2 {print $4}')
    echo -e "${CYAN}├──${NC} Gesamt: $total_ram"
    echo -e "${CYAN}├──${NC} Verwendet: $used_ram"
    echo -e "${CYAN}└──${NC} Frei: $free_ram"
    
    # Storage Info
    echo -e "\n${WHITE}Speicher:${NC}"
    total_storage=$(df -h . | awk 'NR==2 {print $2}')
    used_storage=$(df -h . | awk 'NR==2 {print $3}')
    free_storage=$(df -h . | awk 'NR==2 {print $4}')
    echo -e "${CYAN}├──${NC} Gesamt: $total_storage"
    echo -e "${CYAN}├──${NC} Verwendet: $used_storage"
    echo -e "${CYAN}└──${NC} Frei: $free_storage"
    
    # Python Version
    if command -v python &> /dev/null; then
        python_ver=$(python --version 2>&1 | awk '{print $2}')
        echo -e "\n${WHITE}Python:${NC} $python_ver"
    fi
    
    # Node.js Version
    if command -v node &> /dev/null; then
        node_ver=$(node --version)
        echo -e "${WHITE}Node.js:${NC} $node_ver"
    fi
    
    # XAI Verzeichnisse Status
    echo -e "\n${WHITE}XAI Verzeichnisse:${NC}"
    if [ -d "$XAI_HOME" ]; then
        print_success "XAI Home: $XAI_HOME"
    else
        print_error "XAI Home nicht gefunden"
    fi
    
    echo ""
}

# AI-Module starten (Platzhalter für zukünftige Module)
start_ai_modules() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         AI-Module starten                                  ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    print_info "Verfügbare AI-Module:"
    echo -e "${CYAN}1.${NC} Natural Language Processing (NLP)"
    echo -e "${CYAN}2.${NC} Computer Vision (CV)"
    echo -e "${CYAN}3.${NC} Data Analysis"
    echo -e "${CYAN}4.${NC} Machine Learning"
    
    echo ""
    print_warning "Hinweis: AI-Module sind in dieser Version noch nicht implementiert"
    print_info "Diese Funktionen werden in zukünftigen Updates verfügbar sein"
    
    echo ""
    read -p "Drücke Enter zum Fortfahren..." -r
}

# Konfiguration bearbeiten
edit_configuration() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         Konfiguration bearbeiten                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    config_file="$XAI_CONFIG/config.json"
    
    if [ ! -f "$config_file" ]; then
        print_error "Konfigurationsdatei nicht gefunden: $config_file"
        read -p "Drücke Enter zum Fortfahren..." -r
        return
    fi
    
    print_info "Konfigurationsdatei: $config_file"
    echo ""
    
    # Editor auswählen
    if command -v nano &> /dev/null; then
        editor="nano"
    elif command -v vim &> /dev/null; then
        editor="vim"
    else
        print_error "Kein Editor gefunden (nano oder vim)"
        read -p "Drücke Enter zum Fortfahren..." -r
        return
    fi
    
    print_info "Öffne mit $editor..."
    sleep 1
    $editor "$config_file"
    
    print_success "Konfiguration gespeichert"
    echo ""
}

# Updates durchführen
perform_updates() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         System-Updates durchführen                        ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    print_info "Prüfe auf Updates..."
    
    # System-Pakete aktualisieren
    if command -v pkg &> /dev/null; then
        echo ""
        read -p "$(echo -e ${YELLOW}System-Pakete aktualisieren? [J/n]: ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[JjYy]$ ]] || [[ -z $REPLY ]]; then
            print_info "Aktualisiere System-Pakete..."
            pkg update -y && pkg upgrade -y
            print_success "System-Pakete aktualisiert"
        else
            print_info "System-Paket-Update übersprungen"
        fi
    fi
    
    # Python-Pakete aktualisieren (optional)
    echo ""
    read -p "$(echo -e ${YELLOW}Python-Pakete aktualisieren? [J/n]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[JjYy]$ ]] || [[ -z $REPLY ]]; then
        if [ -f "requirements.txt" ]; then
            print_info "Aktualisiere Python-Pakete..."
            python -m pip install --upgrade -r requirements.txt
            print_success "Python-Pakete aktualisiert"
        else
            print_warning "requirements.txt nicht gefunden"
        fi
    fi
    
    # XAI selbst aktualisieren (wenn Git-Repo)
    echo ""
    if [ -d ".git" ]; then
        read -p "$(echo -e ${YELLOW}XAI von Git aktualisieren? [J/n]: ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[JjYy]$ ]] || [[ -z $REPLY ]]; then
            print_info "Aktualisiere XAI..."
            # Prüfe Git-Status vor dem Pull
            if [ -n "$(git status --porcelain)" ]; then
                print_warning "Lokale Änderungen gefunden. Bitte erst committen oder stashen."
            else
                git pull
                print_success "XAI aktualisiert"
            fi
        fi
    fi
    
    echo ""
    print_success "Updates abgeschlossen"
    read -p "Drücke Enter zum Fortfahren..." -r
}

# Logs anzeigen
show_logs() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         System-Logs anzeigen                              ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    log_file="$XAI_LOGS/xai.log"
    
    if [ ! -f "$log_file" ]; then
        print_warning "Log-Datei nicht gefunden: $log_file"
        read -p "Drücke Enter zum Fortfahren..." -r
        return
    fi
    
    print_info "Log-Datei: $log_file"
    echo ""
    
    # Letzte 50 Zeilen anzeigen
    echo -e "${WHITE}Letzte 50 Log-Einträge:${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    tail -n 50 "$log_file" | while IFS= read -r line; do
        echo -e "${WHITE}$line${NC}"
    done
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    
    echo ""
    print_info "Für Live-Logs: tail -f $log_file"
    read -p "Drücke Enter zum Fortfahren..." -r
}

# System beenden
exit_system() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         System beenden                                     ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    print_info "XAI v$XAI_VERSION wird beendet..."
    
    # Log-Eintrag
    if [ -d "$XAI_LOGS" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - XAI beendet" >> "$XAI_LOGS/xai.log"
    fi
    
    echo -e "\n${MAGENTA}Danke für die Verwendung von XAI v$XAI_VERSION${NC}"
    echo -e "${WHITE}© Elektronikx-Center-Matte ® - Alexander Mathey © 2026${NC}\n"
    
    exit 0
}

# Hauptmenü
show_menu() {
    show_banner
    
    echo -e "${WHITE}Hauptmenü:${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}1.${NC} System-Status anzeigen"
    echo -e "${GREEN}2.${NC} AI-Module starten"
    echo -e "${GREEN}3.${NC} Konfiguration bearbeiten"
    echo -e "${GREEN}4.${NC} Updates durchführen"
    echo -e "${GREEN}5.${NC} Logs anzeigen"
    echo -e "${GREEN}6.${NC} System beenden"
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    echo ""
    
    read -p "$(echo -e ${YELLOW}Wähle eine Option [1-6]: ${NC})" -n 1 -r choice
    echo ""
    
    case $choice in
        1)
            show_status
            read -p "Drücke Enter zum Fortfahren..." -r
            ;;
        2)
            start_ai_modules
            ;;
        3)
            edit_configuration
            ;;
        4)
            perform_updates
            ;;
        5)
            show_logs
            ;;
        6)
            exit_system
            ;;
        *)
            print_error "Ungültige Auswahl"
            sleep 1
            ;;
    esac
}

# Hauptprogramm
main() {
    # Prüfen ob XAI installiert ist
    if [ ! -d "$XAI_HOME" ]; then
        show_banner
        print_error "XAI ist nicht installiert!"
        print_info "Bitte führe zuerst ./install.sh aus"
        exit 1
    fi
    
    # Log-Eintrag
    if [ -d "$XAI_LOGS" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - XAI gestartet" >> "$XAI_LOGS/xai.log"
    fi
    
    # Kommandozeilenargument verarbeiten
    if [ $# -gt 0 ]; then
        case "$1" in
            status)
                show_banner
                show_status
                exit 0
                ;;
            logs)
                show_banner
                show_logs
                exit 0
                ;;
            version)
                echo "XAI v$XAI_VERSION"
                exit 0
                ;;
            help|--help|-h)
                show_banner
                echo -e "${WHITE}Verwendung:${NC}"
                echo -e "  ./xai.sh           ${YELLOW}Interaktives Menü starten${NC}"
                echo -e "  ./xai.sh status    ${YELLOW}System-Status anzeigen${NC}"
                echo -e "  ./xai.sh logs      ${YELLOW}Logs anzeigen${NC}"
                echo -e "  ./xai.sh version   ${YELLOW}Version anzeigen${NC}"
                echo -e "  ./xai.sh help      ${YELLOW}Diese Hilfe anzeigen${NC}"
                echo ""
                exit 0
                ;;
            *)
                print_error "Unbekanntes Kommando: $1"
                print_info "Verwende './xai.sh help' für Hilfe"
                exit 1
                ;;
        esac
    fi
    
    # Interaktives Menü
    while true; do
        show_menu
    done
}

# Script ausführen
main "$@"
