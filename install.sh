#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XAI v4.0 - ULTIMATE INSTALLER
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Vollständige automatisierte Installation mit System-Checks & Optimierungen
# ==============================================================================

set -euo pipefail

# ==============================================================================
# KONFIGURATION
# ==============================================================================
VERSION="4.0.0"
INSTALL_DIR="$HOME/xtreme_ai_system"
BACKUP_DIR="$HOME/xtreme_backups"
SD_CARD_DIR="/storage/emulated/0/XAI"
LOG_FILE="$HOME/xai_install_$(date +%s).log"
MIN_FREE_SPACE_GB=5
MIN_RAM_MB=4096
REQUIRED_TERMUX_VERSION=118

# Farben
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗ FEHLER:${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}⚠ WARNUNG:${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${CYAN}ℹ${NC} $1" | tee -a "$LOG_FILE"
}

# ==============================================================================
# BANNER
# ==============================================================================
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   ██╗  ██╗████████╗██████╗ ███████╗███╗   ███╗███████╗          ║
║   ╚██╗██╔╝╚══██╔══╝██╔══██╗██╔════╝████╗ ████║██╔════╝          ║
║    ╚███╔╝    ██║   ██████╔╝█████╗  ██╔████╔██║█████╗            ║
║    ██╔██╗    ██║   ██╔══██╗██╔══╝  ██║╚██╔╝██║██╔══╝            ║
║   ██╔╝ ██╗   ██║   ██║  ██║███████╗██║ ╚═╝ ██║███████╗          ║
║   ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝          ║
║                                                                  ║
║                      XAI v4.0.0                                  ║
║            Ultimate AI System für Termux/Android                ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  © Elektronikx-Center-Matte ®                                   ║
║  Entwicklung: Alexander Mathey ©                                ║
║                                                                  ║
║  Optimiert für: Realme C63 RMX3939                              ║
║  CPU: Unisoc Tiger T612 (2x A75 @ 1.8GHz + 6x A55 @ 1.6GHz)    ║
║  RAM: 8GB LPDDR4X | Storage: 256GB UFS 2.2                     ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ==============================================================================
# SYSTEM PRE-CHECK
# ==============================================================================
pre_check() {
    info "Starte System-Pre-Check..."
    local errors=0
    
    # 1. Termux-Version
    echo -n "  [1/10] Termux-Version prüfen... "
    if command -v termux-info &> /dev/null; then
        success "OK"
    else
        error "Termux-Tools nicht installiert"
        ((errors++))
    fi
    
    # 2. Speicherplatz (intern)
    echo -n "  [2/10] Freier Speicher (intern)... "
    local free_space_mb=$(df "$HOME" | tail -1 | awk '{print $4}')
    local free_space_gb=$((free_space_mb / 1024 / 1024))
    if [[ $free_space_gb -ge $MIN_FREE_SPACE_GB ]]; then
        success "${free_space_gb}GB verfügbar"
    else
        warn "Nur ${free_space_gb}GB frei (empfohlen: ${MIN_FREE_SPACE_GB}GB)"
        ((errors++))
    fi
    
    # 3. SD-Karte Zugriff
    echo -n "  [3/10] SD-Karten-Zugriff... "
    if [[ -d "/storage/emulated/0" ]]; then
        termux-setup-storage 2>/dev/null || true
        if [[ -w "/storage/emulated/0" ]]; then
            success "Verfügbar"
        else
            warn "Keine Schreibrechte - führe 'termux-setup-storage' aus"
        fi
    else
        warn "SD-Karte nicht gefunden"
    fi
    
    # 4. RAM
    echo -n "  [4/10] Verfügbarer RAM... "
    local total_ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $total_ram_mb -ge $MIN_RAM_MB ]]; then
        success "${total_ram_mb}MB gesamt"
    else
        warn "Nur ${total_ram_mb}MB RAM (empfohlen: ${MIN_RAM_MB}MB)"
    fi
    
    # 5. CPU-Architektur
    echo -n "  [5/10] CPU-Architektur... "
    local arch=$(uname -m)
    if [[ "$arch" == "aarch64" ]] || [[ "$arch" == "armv8"* ]]; then
        success "$arch (ARM64)"
    else
        error "Nicht unterstützte Architektur: $arch"
        ((errors++))
    fi
    
    # 6. Netzwerkverbindung
    echo -n "  [6/10] Internetverbindung... "
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        success "Aktiv"
    else
        error "Keine Internetverbindung"
        ((errors++))
    fi
    
    # 7. Bestehende Installation
    echo -n "  [7/10] Alte Installation... "
    if [[ -d "$INSTALL_DIR" ]]; then
        warn "Gefunden - wird gesichert"
    else
        success "Keine gefunden"
    fi
    
    # 8. Termux Pakete
    echo -n "  [8/10] Paketmanager... "
    if command -v pkg &> /dev/null; then
        success "pkg verfügbar"
    else
        error "pkg nicht gefunden"
        ((errors++))
    fi
    
    # 9. Python
    echo -n "  [9/10] Python... "
    if command -v python &> /dev/null; then
        local py_version=$(python --version 2>&1 | awk '{print $2}')
        success "v$py_version"
    else
        info "Wird installiert"
    fi
    
    # 10. Node.js
    echo -n " [10/10] Node.js... "
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        success "$node_version"
    else
        info "Wird installiert"
    fi
    
    echo ""
    if [[ $errors -gt 0 ]]; then
        error "$errors kritische Fehler gefunden!"
        read -p "Trotzdem fortfahren? (j/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Jj]$ ]]; then
            exit 1
        fi
    else
        success "Alle Pre-Checks bestanden! ✓"
    fi
}

# ==============================================================================
# BACKUP EXISTIERENDER INSTALLATION
# ==============================================================================
backup_old_installation() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        return 0
    fi
    
    info "Sichere alte Installation..."
    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    tar -czf "$BACKUP_DIR/${backup_name}.tar.gz" -C "$(dirname "$INSTALL_DIR")" "$(basename "$INSTALL_DIR")" 2>/dev/null || {
        warn "Backup fehlgeschlagen - überspringe"
        return 1
    }
    
    success "Backup erstellt: $BACKUP_DIR/${backup_name}.tar.gz"
}

# ==============================================================================
# CLEANUP ALTER BACKUPS
# ==============================================================================
cleanup_old_backups() {
    info "Bereinige alte Backups..."
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        return 0
    fi
    
    # Lösche Backups älter als 30 Tage
    find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +30 -delete 2>/dev/null || true
    
    # Validiere vorhandene Backups
    for backup in "$BACKUP_DIR"/backup_*.tar.gz; do
        if [[ -f "$backup" ]]; then
            if ! tar -tzf "$backup" &>/dev/null; then
                warn "Korruptes Backup gefunden: $(basename "$backup") - lösche"
                rm -f "$backup"
            fi
        fi
    done
    
    success "Backup-Bereinigung abgeschlossen"
}

# ==============================================================================
# INSTALLIERE ABHÄNGIGKEITEN
# ==============================================================================
install_dependencies() {
    info "Installiere System-Abhängigkeiten..."
    
    # Update Paketliste
    pkg update -y 2>&1 | tee -a "$LOG_FILE"
    
    # Basis-Pakete
    local packages=(
        "git" "wget" "curl" "openssh" "termux-tools"
        "python" "python-pip" "nodejs" "nodejs-lts"
        "clang" "cmake" "make" "binutils" "pkg-config"
        "ffmpeg" "imagemagick" "sqlite"
        "htop" "neofetch" "tmux" "vim"
    )
    
    for pkg_name in "${packages[@]}"; do
        echo -n "  Installing $pkg_name... "
        if pkg install -y "$pkg_name" &>>"$LOG_FILE"; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${YELLOW}⚠${NC}"
        fi
    done
    
    # Python-Pakete
    info "Installiere Python-Pakete..."
    pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE"
    pip install numpy scipy pandas flask fastapi uvicorn pyyaml 2>&1 | tee -a "$LOG_FILE"
    
    success "Abhängigkeiten installiert"
}

# ==============================================================================
# ERSTELLE VERZEICHNISSTRUKTUR
# ==============================================================================
create_directory_structure() {
    info "Erstelle Verzeichnisstruktur..."
    
    # Haupt-Verzeichnisse
    mkdir -p "$INSTALL_DIR"/{bin,config,containers,dashboards,data,logs,plugins,scripts,services,web}
    mkdir -p "$INSTALL_DIR"/data/{databases,cache,temp}
    mkdir -p "$INSTALL_DIR"/dashboards/{main,ai,storage}
    mkdir -p "$INSTALL_DIR"/containers/{dashboard,ai-services,database}
    mkdir -p "$INSTALL_DIR"/web/{css,js,assets}
    
    # SD-Karte Verzeichnisse
    if [[ -w "/storage/emulated/0" ]]; then
        mkdir -p "$SD_CARD_DIR"/{models,backups,downloads}
        
        # Symlinks erstellen
        ln -sf "$SD_CARD_DIR/models" "$INSTALL_DIR/models"
        ln -sf "$SD_CARD_DIR/backups" "$INSTALL_DIR/backups_sd"
        ln -sf "$SD_CARD_DIR/downloads" "$INSTALL_DIR/downloads"
        
        success "SD-Karte konfiguriert"
    else
        # Fallback: alles lokal
        mkdir -p "$INSTALL_DIR"/{models,backups_sd,downloads}
        warn "SD-Karte nicht verfügbar - verwende internen Speicher"
    fi
    
    success "Verzeichnisstruktur erstellt"
}

# ==============================================================================
# MAIN INSTALLATION
# ==============================================================================
main() {
    show_banner
    
    log "Starte XTREME XAI v$VERSION Installation"
    
    # Pre-Check
    pre_check
    
    # Backup
    cleanup_old_backups
    backup_old_installation
    
    # Installation
    install_dependencies
    create_directory_structure
    
    # Run core setup scripts
    info "Führe Core-Setup-Skripte aus..."
    [[ -f "$(dirname "$0")/core/system_check.sh" ]] && bash "$(dirname "$0")/core/system_check.sh"
    [[ -f "$(dirname "$0")/core/optimization.sh" ]] && bash "$(dirname "$0")/core/optimization.sh"
    [[ -f "$(dirname "$0")/core/emulator_setup.sh" ]] && bash "$(dirname "$0")/core/emulator_setup.sh"
    
    # Post-Install
    echo ""
    success "════════════════════════════════════════"
    success "  Installation erfolgreich abgeschlossen!"
    success "════════════════════════════════════════"
    echo ""
    info "📂 Installationsverzeichnis: $INSTALL_DIR"
    info "📊 Dashboard: Siehe web_ui/dashboard.html"
    info "🔧 Scripts: Siehe scripts/ Verzeichnis"
    echo ""
    info "📝 Logs: $LOG_FILE"
    echo ""
}

# RUN
main "$@"
