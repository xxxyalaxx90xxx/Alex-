#!/data/data/com.termux/files/usr/bin/bash
#
# Xtreme XA-vI ® Cyber KI Elektronikx-Center-Matte®
# Automatisches Installationsskript für Termux
# By Alexander Mathey XAi-Cyborg ©®
#
# Realme c63 (RMX3939) Optimiert
#

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner anzeigen
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║   Xtreme XA-vI ® Cyber KI Elektronikx-Center-Matte®     ║
    ║   Termux Development Environment Installer               ║
    ║   By Alexander Mathey XAi-Cyborg ©®                      ║
    ║                                                           ║
    ║   Optimiert für: Realme c63 (RMX3939)                    ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Logging-Funktionen
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Progress-Bar
progress_bar() {
    local duration=$1
    local steps=50
    local step_duration=$(echo "scale=2; $duration / $steps" | bc)
    
    echo -n "Progress: ["
    for i in $(seq 1 $steps); do
        echo -n "="
        sleep $step_duration
    done
    echo "] Done!"
}

# System-Check
check_system() {
    log_info "System-Check wird durchgeführt..."
    
    # Termux-Version
    if [ -f "$PREFIX/bin/termux-info" ]; then
        log_success "Termux erkannt"
    else
        log_error "Nicht in Termux-Umgebung!"
        exit 1
    fi
    
    # Internetverbindung
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log_success "Internetverbindung aktiv"
    else
        log_warning "Keine Internetverbindung - Installation könnte fehlschlagen"
    fi
    
    # Speicherplatz
    local free_space=$(df -h $HOME | awk 'NR==2 {print $4}')
    local free_space_mb=$(df -m $HOME | awk 'NR==2 {print $4}')
    if [ "$free_space_mb" -gt 2048 ]; then
        log_success "Ausreichend Speicherplatz verfügbar (${free_space} frei)"
    else
        log_warning "Wenig Speicherplatz verfügbar (${free_space} frei)"
    fi
}

# Packages aktualisieren
update_packages() {
    log_info "Aktualisiere Paket-Listen..."
    pkg update -y || log_warning "Package update hatte Probleme"
    
    log_info "Upgrade bestehender Pakete..."
    pkg upgrade -y || log_warning "Package upgrade hatte Probleme"
    
    log_success "Pakete aktualisiert"
}

# Basis-Pakete installieren
install_base_packages() {
    log_info "Installiere Basis-Pakete..."
    
    local packages=(
        "git"
        "wget"
        "curl"
        "openssh"
        "openssl"
        "gnupg"
        "tar"
        "zip"
        "unzip"
        "vim"
        "nano"
        "tree"
        "htop"
        "tmux"
        "ncurses-utils"
    )
    
    for package in "${packages[@]}"; do
        log_info "Installiere $package..."
        pkg install -y "$package" || log_warning "Fehler bei Installation von $package"
    done
    
    log_success "Basis-Pakete installiert"
}

# Entwicklungs-Tools installieren
install_dev_tools() {
    log_info "Installiere Entwicklungs-Tools..."
    
    # Programmiersprachen
    log_info "Installiere Programmiersprachen..."
    pkg install -y python python-pip nodejs ruby golang rust clang make cmake || true
    
    # Build-Tools
    log_info "Installiere Build-Tools..."
    pkg install -y build-essential binutils pkg-config autoconf automake libtool || true
    
    # Version-Control
    log_info "Installiere GitHub CLI..."
    pkg install -y gh || true
    
    log_success "Entwicklungs-Tools installiert"
}

# Python Packages installieren
install_python_packages() {
    log_info "Installiere Python-Pakete..."
    
    pip install --upgrade pip
    pip install requests flask fastapi httpie jq || true
    
    log_success "Python-Pakete installiert"
}

# Node.js Packages installieren
install_node_packages() {
    log_info "Installiere Node.js-Pakete..."
    
    npm install -g \
        npm \
        yarn \
        http-server \
        wscat \
        @angular/cli \
        @vue/cli \
        create-react-app \
        typescript || true
    
    log_success "Node.js-Pakete installiert"
}

# Storage-Zugriff einrichten
setup_storage() {
    log_info "Richte Storage-Zugriff ein..."
    
    if ! [ -d "$HOME/storage" ]; then
        termux-setup-storage
        log_success "Storage-Zugriff eingerichtet (Bitte Berechtigung erteilen)"
    else
        log_success "Storage-Zugriff bereits eingerichtet"
    fi
}

# Git konfigurieren
setup_git() {
    log_info "Konfiguriere Git..."
    
    # Prüfen ob bereits konfiguriert
    if ! git config --global user.name &> /dev/null; then
        log_info "Git-Benutzerkonfiguration wird übersprungen"
        log_info "Bitte später konfigurieren mit:"
        log_info "  git config --global user.name 'Dein Name'"
        log_info "  git config --global user.email 'deine.email@example.com'"
    fi
    
    git config --global credential.helper store
    git config --global http.version HTTP/2
    git config --global http.postBuffer 524288000
    git config --global core.editor vim
    
    log_success "Git konfiguriert"
}

# SSH Keys einrichten
setup_ssh() {
    log_info "Richte SSH ein..."
    
    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        mkdir -p $HOME/.ssh
        chmod 700 $HOME/.ssh
        
        log_info "SSH-Key wird übersprungen (generiere später manuell)"
        log_info "Zum Generieren verwende:"
        log_info "  ssh-keygen -t ed25519 -C 'deine.email@example.com'"
    else
        log_success "SSH-Key existiert bereits"
    fi
}

# Stylisches Terminal einrichten
setup_style() {
    log_info "Richte stylisches Terminal ein..."
    
    # Termux-Farben
    mkdir -p $HOME/.termux
    
    cat > $HOME/.termux/colors.properties << 'EOF'
# Cyber-Style Dark Theme - Xtreme XA-vI
background=#0a0e27
foreground=#00ff41
cursor=#00ff41

color0=#0a0e27
color1=#ff0055
color2=#00ff41
color3=#ffaa00
color4=#0099ff
color5=#cc00ff
color6=#00ffff
color7=#ffffff
color8=#555555
color9=#ff0055
color10=#00ff41
color11=#ffaa00
color12=#0099ff
color13=#cc00ff
color14=#00ffff
color15=#ffffff
EOF
    
    # Font-Properties
    cat > $HOME/.termux/font.ttf << 'EOF' 2>/dev/null || true
EOF
    
    # Bash-Prompt mit Style
    cat >> $HOME/.bashrc << 'EOF'

# Xtreme XA-vI Cyber Style Prompt
PS1='\[\033[01;35m\]╭─[\[\033[01;36m\]\u\[\033[01;35m\]@\[\033[01;36m\]\h\[\033[01;35m\]]─[\[\033[01;33m\]\w\[\033[01;35m\]]\n╰─\[\033[01;32m\]λ\[\033[00m\] '

# Aliases
alias update='pkg update && pkg upgrade -y'
alias cleanup='apt autoremove && apt clean'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias gst='git status'
alias gpl='git pull'
alias gps='git push'
alias gc='git commit'
alias ga='git add'
alias glog='git log --oneline --graph --decorate'

# Turbo-Mode (konservativ für Stabilität)
alias turbo='renice -n -5 -p $$'

# Welcome Message
echo -e "\033[0;36m"
echo "╔═══════════════════════════════════════════════╗"
echo "║  Xtreme XA-vI ® Development Environment       ║"
echo "║  Realme c63 (RMX3939) - Optimiert             ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "\033[0m"
EOF
    
    log_success "Stylisches Terminal eingerichtet"
}

# Performance-Optimierungen
setup_performance() {
    log_info "Richte Performance-Optimierungen ein..."
    
    # DNS-Optimierung
    cat > $PREFIX/etc/resolv.conf << 'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
    
    log_success "Performance-Optimierungen angewendet"
}

# Utility-Scripts erstellen
create_utility_scripts() {
    log_info "Erstelle Utility-Scripts..."
    
    mkdir -p $HOME/bin
    
    # Update-Script
    cat > $HOME/bin/update-system.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Updating system..."
pkg update && pkg upgrade -y
pip install --upgrade pip
npm update -g
echo "System updated!"
EOF
    chmod +x $HOME/bin/update-system.sh
    
    # GitHub Search Script
    cat > $HOME/bin/gh-search.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
if [ -z "$1" ]; then
    echo "Usage: gh-search.sh <query>"
    exit 1
fi
gh search repos "$@" --limit 20
EOF
    chmod +x $HOME/bin/gh-search.sh
    
    # System Info Script
    cat > $HOME/bin/system-info.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "=== System Information ==="
echo "Device: $(getprop ro.product.model)"
echo "Android: $(getprop ro.build.version.release)"
echo "CPU: $(cat /proc/cpuinfo | grep 'model name' | head -n1 | cut -d: -f2)"
echo "Memory: $(free -h | awk 'NR==2{printf "%s/%s\n", $3,$2}')"
echo "Storage: $(df -h $HOME | awk 'NR==2{printf "%s/%s (%s used)\n", $3,$2,$5}')"
echo "Termux Version: $(termux-info | grep TERMUX_VERSION)"
EOF
    chmod +x $HOME/bin/system-info.sh
    
    # PATH hinzufügen
    if ! grep -q '$HOME/bin' $HOME/.bashrc; then
        echo 'export PATH="$HOME/bin:$PATH"' >> $HOME/.bashrc
    fi
    
    log_success "Utility-Scripts erstellt"
}

# Abschluss-Meldung
finish_installation() {
    log_success "Installation abgeschlossen!"
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Xtreme XA-vI ® Cyber KI Elektronikx-Center-Matte®      ║${NC}"
    echo -e "${GREEN}║  Installation erfolgreich abgeschlossen!                 ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    log_info "Nächste Schritte:"
    echo "  1. Starte Termux neu: exit (und App neu öffnen)"
    echo "  2. GitHub authentifizieren: gh auth login"
    echo "  3. Dokumentation lesen: cat TERMUX_SETUP.md"
    echo "  4. System-Info anzeigen: system-info.sh"
    echo "  5. Updates prüfen: update-system.sh"
    echo ""
    log_info "Utility-Commands:"
    echo "  - update-system.sh  : System aktualisieren"
    echo "  - gh-search.sh      : GitHub Repositories suchen"
    echo "  - system-info.sh    : System-Informationen anzeigen"
    echo ""
    log_warning "Bitte starte Termux neu, damit alle Änderungen wirksam werden!"
}

# Hauptprogramm
main() {
    show_banner
    
    log_info "Starte automatische Installation..."
    sleep 2
    
    check_system
    update_packages
    install_base_packages
    install_dev_tools
    setup_storage
    install_python_packages
    install_node_packages
    setup_git
    setup_ssh
    setup_style
    setup_performance
    create_utility_scripts
    
    finish_installation
}

# Script ausführen
main
