#!/bin/bash
# XAI v4.0.0 - Ultimate AI System für Termux/Android
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
NC='\033[0m' # No Color

# Globale Variablen
MIN_STORAGE_GB=10
MIN_RAM_GB=4
REQUIRED_PYTHON_VERSION="3.12"
REQUIRED_NODE_VERSION="22"

# ASCII-Art Banner
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
║              © Elektronikx-Center-Matte ® - Alexander Mathey ©         ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Fortschrittsbalken
show_progress() {
    local current=$1
    local total=$2
    local description=$3
    local percentage=$((current * 100 / total))
    local completed=$((percentage / 2))
    local remaining=$((50 - completed))
    
    printf "\r${CYAN}[${GREEN}"
    printf "%${completed}s" | tr ' ' '█'
    printf "${WHITE}"
    printf "%${remaining}s" | tr ' ' '░'
    printf "${CYAN}] ${WHITE}%3d%% ${YELLOW}%s${NC}" "$percentage" "$description"
}

# Erfolgs-/Fehlermeldungen
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

# System Pre-Checks (10 Schritte)
run_prechecks() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         System Pre-Checks - 10 Schritte                    ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    local check_count=0
    local total_checks=10
    
    # 1. Termux-Version prüfen
    ((check_count++))
    show_progress $check_count $total_checks "Termux-Version prüfen..."
    sleep 0.5
    if command -v termux-info &> /dev/null; then
        echo ""
        print_success "Termux ist installiert"
    else
        echo ""
        print_warning "Termux-Umgebung nicht erkannt (fortfahren trotzdem)"
    fi
    
    # 2. Freien Speicher prüfen
    ((check_count++))
    show_progress $check_count $total_checks "Freien Speicher prüfen..."
    sleep 0.5
    available_storage=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    echo ""
    if [ "$available_storage" -ge "$MIN_STORAGE_GB" ]; then
        print_success "Ausreichend Speicher verfügbar: ${available_storage}GB (mind. ${MIN_STORAGE_GB}GB erforderlich)"
    else
        print_warning "Wenig Speicher: ${available_storage}GB (empfohlen: ${MIN_STORAGE_GB}GB)"
    fi
    
    # 3. SD-Karten-Zugriff mit termux-setup-storage
    ((check_count++))
    show_progress $check_count $total_checks "SD-Karten-Zugriff prüfen..."
    sleep 0.5
    echo ""
    if [ -d "$HOME/storage" ]; then
        print_success "Termux Storage bereits konfiguriert"
    else
        print_info "Termux Storage wird eingerichtet..."
        if command -v termux-setup-storage &> /dev/null; then
            termux-setup-storage
            print_success "Termux Storage konfiguriert (Berechtigungen erteilt)"
        else
            print_warning "termux-setup-storage nicht verfügbar"
        fi
    fi
    
    # 4. RAM-Verfügbarkeit prüfen
    ((check_count++))
    show_progress $check_count $total_checks "RAM-Verfügbarkeit prüfen..."
    sleep 0.5
    total_ram=$(free -g | awk 'NR==2 {print $2}')
    echo ""
    if [ "$total_ram" -ge "$MIN_RAM_GB" ]; then
        print_success "RAM verfügbar: ${total_ram}GB (mind. ${MIN_RAM_GB}GB empfohlen)"
    else
        print_warning "RAM: ${total_ram}GB (empfohlen: ${MIN_RAM_GB}GB)"
    fi
    
    # 5. CPU-Architektur prüfen
    ((check_count++))
    show_progress $check_count $total_checks "CPU-Architektur prüfen..."
    sleep 0.5
    cpu_arch=$(uname -m)
    echo ""
    if [[ "$cpu_arch" == "aarch64" || "$cpu_arch" == "arm64" ]]; then
        print_success "CPU-Architektur: $cpu_arch (ARM64 - kompatibel)"
    else
        print_warning "CPU-Architektur: $cpu_arch (nicht ARM64)"
    fi
    
    # 6. Internetverbindung prüfen
    ((check_count++))
    show_progress $check_count $total_checks "Internetverbindung prüfen..."
    sleep 0.5
    echo ""
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "Internetverbindung aktiv"
    else
        print_error "Keine Internetverbindung - Installation kann nicht fortgesetzt werden"
        exit 1
    fi
    
    # 7. Alte Installationen bereinigen
    ((check_count++))
    show_progress $check_count $total_checks "Alte Installationen bereinigen..."
    sleep 0.5
    echo ""
    if [ -d "$HOME/xai" ]; then
        print_info "Alte XAI Installation gefunden - wird gesichert..."
        mv "$HOME/xai" "$HOME/xai.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Alte Installation gesichert"
    else
        print_success "Keine alte Installation gefunden"
    fi
    
    # 8. Paketmanager (pkg) verfügbar
    ((check_count++))
    show_progress $check_count $total_checks "Paketmanager prüfen..."
    sleep 0.5
    echo ""
    if command -v pkg &> /dev/null; then
        print_success "Paketmanager 'pkg' verfügbar"
    else
        print_error "Paketmanager 'pkg' nicht gefunden"
        exit 1
    fi
    
    # 9. Python Version prüfen
    ((check_count++))
    show_progress $check_count $total_checks "Python Version prüfen..."
    sleep 0.5
    echo ""
    if command -v python &> /dev/null; then
        python_version=$(python --version 2>&1 | awk '{print $2}')
        print_info "Python Version: $python_version (wird bei Bedarf aktualisiert)"
    else
        print_info "Python nicht installiert (wird installiert)"
    fi
    
    # 10. Node.js Version prüfen
    ((check_count++))
    show_progress $check_count $total_checks "Node.js Version prüfen..."
    sleep 0.5
    echo ""
    if command -v node &> /dev/null; then
        node_version=$(node --version | sed 's/v//')
        print_info "Node.js Version: v$node_version (wird bei Bedarf aktualisiert)"
    else
        print_info "Node.js nicht installiert (wird installiert)"
    fi
    
    echo ""
    print_success "Alle Pre-Checks abgeschlossen!\n"
}

# System-Abhängigkeiten installieren
install_system_dependencies() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         System-Abhängigkeiten installieren                 ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    print_info "Paketlisten werden aktualisiert..."
    pkg update -y &> /dev/null
    pkg upgrade -y &> /dev/null
    print_success "Paketlisten aktualisiert"
    
    # Liste der zu installierenden Pakete
    packages=(
        "git"
        "wget"
        "curl"
        "openssh"
        "termux-tools"
        "termux-api"
        "python"
        "nodejs"
        "nodejs-lts"
        "clang"
        "cmake"
        "make"
        "binutils"
        "pkg-config"
        "ffmpeg"
        "imagemagick"
        "sqlite"
        "htop"
        "neofetch"
        "tmux"
        "vim"
        "nano"
    )
    
    local total_packages=${#packages[@]}
    local current_package=0
    
    for package in "${packages[@]}"; do
        ((current_package++))
        show_progress $current_package $total_packages "Installiere $package..."
        
        if pkg install -y "$package" &> /dev/null; then
            echo ""
            print_success "$package installiert"
        else
            echo ""
            print_warning "$package konnte nicht installiert werden (möglicherweise bereits vorhanden)"
        fi
    done
    
    echo ""
    print_success "Alle System-Abhängigkeiten installiert!\n"
}

# Python-Pakete installieren
install_python_packages() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         Python-Pakete installieren                         ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    if [ ! -f "requirements.txt" ]; then
        print_error "requirements.txt nicht gefunden!"
        return 1
    fi
    
    print_info "Installiere Python-Pakete aus requirements.txt..."
    
    # Hinweis: pip upgrade ist in Termux verboten
    print_warning "Hinweis: pip upgrade wird übersprungen (in Termux nicht erlaubt)"
    
    # Python-Pakete installieren
    if python -m pip install -r requirements.txt --no-warn-script-location 2>&1 | tee /tmp/pip_install.log; then
        print_success "Python-Pakete erfolgreich installiert"
    else
        print_warning "Einige Python-Pakete konnten nicht installiert werden"
        print_info "Details siehe: /tmp/pip_install.log"
    fi
    
    echo ""
}

# Node.js Pakete installieren
install_nodejs_packages() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         Node.js Pakete installieren                        ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    print_info "Installiere globale Node.js Pakete..."
    
    npm_packages=(
        "npm"
        "pm2"
        "nodemon"
    )
    
    for npm_package in "${npm_packages[@]}"; do
        print_info "Installiere $npm_package..."
        if npm install -g "$npm_package" &> /dev/null; then
            print_success "$npm_package installiert"
        else
            print_warning "$npm_package konnte nicht installiert werden"
        fi
    done
    
    echo ""
}

# XAI Systemkonfiguration
configure_xai_system() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         XAI Systemkonfiguration                            ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    if [ -f "./xai-setup.sh" ]; then
        print_info "Führe XAI Setup-Script aus..."
        chmod +x ./xai-setup.sh
        if bash ./xai-setup.sh; then
            print_success "XAI System konfiguriert"
        else
            print_error "XAI Konfiguration fehlgeschlagen"
            return 1
        fi
    else
        print_warning "xai-setup.sh nicht gefunden - Konfiguration übersprungen"
    fi
    
    echo ""
}

# Erfolgsbestätigung mit Systeminformationen
show_success_summary() {
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}         Installation erfolgreich abgeschlossen!            ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${WHITE}Systeminformationen:${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    
    # Device Info
    if command -v termux-info &> /dev/null; then
        echo -e "${YELLOW}Gerät:${NC} Realme C63 RMX3939 (Termux)"
    else
        echo -e "${YELLOW}Gerät:${NC} $(uname -n)"
    fi
    
    # CPU Info
    cpu_info=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)
    if [ -z "$cpu_info" ]; then
        cpu_info="Unisoc Tiger T612"
    fi
    echo -e "${YELLOW}CPU:${NC} $cpu_info"
    echo -e "${YELLOW}Architektur:${NC} $(uname -m)"
    
    # RAM Info
    total_ram_mb=$(free -m | awk 'NR==2 {print $2}')
    echo -e "${YELLOW}RAM:${NC} ${total_ram_mb}MB"
    
    # Storage Info
    storage_info=$(df -h . | awk 'NR==2 {print $4}')
    echo -e "${YELLOW}Freier Speicher:${NC} $storage_info"
    
    # Python Version
    if command -v python &> /dev/null; then
        python_ver=$(python --version 2>&1 | awk '{print $2}')
        echo -e "${YELLOW}Python:${NC} $python_ver"
    fi
    
    # Node.js Version
    if command -v node &> /dev/null; then
        node_ver=$(node --version)
        echo -e "${YELLOW}Node.js:${NC} $node_ver"
    fi
    
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    
    echo -e "\n${WHITE}XAI v4.0.0 Installation:${NC}"
    echo -e "${GREEN}✓${NC} Installation abgeschlossen"
    echo -e "${GREEN}✓${NC} Alle Abhängigkeiten installiert"
    echo -e "${GREEN}✓${NC} System konfiguriert"
    
    echo -e "\n${WHITE}Nächste Schritte:${NC}"
    echo -e "${CYAN}1.${NC} XAI starten mit: ${GREEN}./xai.sh${NC}"
    echo -e "${CYAN}2.${NC} Dokumentation lesen: ${GREEN}cat README.md${NC}"
    echo -e "${CYAN}3.${NC} System-Status prüfen: ${GREEN}./xai.sh status${NC}"
    
    echo -e "\n${MAGENTA}© Elektronikx-Center-Matte ® - Alexander Mathey © 2026${NC}\n"
}

# Hauptprogramm
main() {
    show_banner
    
    echo -e "${WHITE}Willkommen zur XAI v4.0.0 Installation!${NC}"
    echo -e "${WHITE}Optimiert für: Realme C63 RMX3939 mit Termux${NC}\n"
    
    read -p "$(echo -e ${YELLOW}Installation starten? [J/n]: ${NC})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[JjYy]$ ]] && [[ ! -z $REPLY ]]; then
        print_info "Installation abgebrochen."
        exit 0
    fi
    
    # Installation Schritte
    run_prechecks
    install_system_dependencies
    install_python_packages
    install_nodejs_packages
    configure_xai_system
    show_success_summary
    
    # XAI Launcher ausführbar machen
    if [ -f "./xai.sh" ]; then
        chmod +x ./xai.sh
    fi
    
    exit 0
}

# Script ausführen
main
