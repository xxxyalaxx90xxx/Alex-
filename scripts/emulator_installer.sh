#!/bin/bash

################################################################################
# Emulator Installer with System Support
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Automatische Installation von Emulatoren mit System-Unterstützung
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
EMULATOR_DIR="${INSTALL_DIR}/emulators"
LOG_FILE="${INSTALL_DIR}/logs/emulator_install_$(date +%Y%m%d_%H%M%S).log"

log_info() {
    echo -e "${BLUE}[EMULATOR]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Ensure directories exist
mkdir -p "$EMULATOR_DIR" "$(dirname "$LOG_FILE")"

# Show banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║         XTREME XAI Emulator Installer v4.0                ║
║     © Elektronikx-Center-Matte ® | Alexander Mathey ©     ║
║                                                            ║
║     Automatische Installation von Emulatoren              ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check system requirements
check_requirements() {
    log_info "Überprüfe System-Anforderungen..."
    
    local errors=0
    
    # Check available space
    local free_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    local free_space_gb=$((free_space / 1024 / 1024))
    
    if [[ $free_space_gb -lt 2 ]]; then
        log_error "Nicht genug Speicherplatz (benötigt: 2GB, verfügbar: ${free_space_gb}GB)"
        errors=$((errors + 1))
    else
        log_success "Speicherplatz: ${free_space_gb}GB verfügbar"
    fi
    
    # Check package manager
    if ! command -v pkg &>/dev/null; then
        log_error "pkg (Termux Paketmanager) nicht gefunden"
        errors=$((errors + 1))
    else
        log_success "Paketmanager verfügbar"
    fi
    
    return $errors
}

# Install QEMU
install_qemu() {
    log_info "Installiere QEMU..."
    
    if command -v qemu-system-x86_64 &>/dev/null || command -v qemu-system-aarch64 &>/dev/null; then
        log_info "QEMU bereits installiert"
        return 0
    fi
    
    # Install QEMU packages
    pkg install -y qemu-system-x86-64 qemu-system-aarch64 qemu-utils &>>"$LOG_FILE"
    
    if command -v qemu-system-x86_64 &>/dev/null || command -v qemu-system-aarch64 &>/dev/null; then
        log_success "QEMU erfolgreich installiert"
        
        # Create launcher script
        cat > "$EMULATOR_DIR/qemu-launcher.sh" << 'QEMU_EOF'
#!/bin/bash
# QEMU Quick Launcher

QEMU_DIR="$HOME/xtreme_ai_system/emulators/qemu"
mkdir -p "$QEMU_DIR"

echo "QEMU Launcher - Wähle Option:"
echo "  1) x86_64 VM starten (2GB RAM)"
echo "  2) ARM64 VM starten (2GB RAM)"
echo "  3) Custom ISO starten"
echo "  4) Beenden"
echo
read -p "Option: " choice

case $choice in
    1)
        qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -display sdl "$@"
        ;;
    2)
        qemu-system-aarch64 -M virt -m 2048 -cpu cortex-a57 -smp 2 "$@"
        ;;
    3)
        read -p "Pfad zur ISO-Datei: " iso_path
        if [[ -f "$iso_path" ]]; then
            qemu-system-x86_64 -m 2048 -smp 2 -cdrom "$iso_path" -boot d "$@"
        else
            echo "ISO-Datei nicht gefunden"
        fi
        ;;
    4)
        exit 0
        ;;
esac
QEMU_EOF
        chmod +x "$EMULATOR_DIR/qemu-launcher.sh"
        log_success "QEMU Launcher erstellt: $EMULATOR_DIR/qemu-launcher.sh"
        return 0
    else
        log_error "QEMU Installation fehlgeschlagen"
        return 1
    fi
}

# Install PRoot/proot-distro
install_proot() {
    log_info "Installiere PRoot und proot-distro..."
    
    if command -v proot &>/dev/null && command -v proot-distro &>/dev/null; then
        log_info "PRoot bereits installiert"
        return 0
    fi
    
    pkg install -y proot proot-distro &>>"$LOG_FILE"
    
    if command -v proot-distro &>/dev/null; then
        log_success "PRoot und proot-distro installiert"
        
        # Show available distributions
        log_info "Verfügbare Distributionen:"
        proot-distro list
        
        # Create helper script
        cat > "$EMULATOR_DIR/proot-helper.sh" << 'PROOT_EOF'
#!/bin/bash
# PRoot Distribution Helper

echo "PRoot Distribution Manager"
echo "=========================="
echo
echo "Verfügbare Aktionen:"
echo "  1) Ubuntu installieren"
echo "  2) Debian installieren"
echo "  3) Arch Linux installieren"
echo "  4) Alpine installieren"
echo "  5) Distribution starten"
echo "  6) Liste installierter Distributionen"
echo "  7) Distribution löschen"
echo "  8) Beenden"
echo
read -p "Option: " choice

case $choice in
    1)
        proot-distro install ubuntu
        echo "Ubuntu wurde installiert. Starte mit: proot-distro login ubuntu"
        ;;
    2)
        proot-distro install debian
        echo "Debian wurde installiert. Starte mit: proot-distro login debian"
        ;;
    3)
        proot-distro install archlinux
        echo "Arch Linux wurde installiert. Starte mit: proot-distro login archlinux"
        ;;
    4)
        proot-distro install alpine
        echo "Alpine wurde installiert. Starte mit: proot-distro login alpine"
        ;;
    5)
        read -p "Distribution Name (z.B. ubuntu): " distro
        proot-distro login "$distro"
        ;;
    6)
        proot-distro list
        ;;
    7)
        read -p "Distribution Name: " distro
        proot-distro remove "$distro"
        ;;
    8)
        exit 0
        ;;
esac
PROOT_EOF
        chmod +x "$EMULATOR_DIR/proot-helper.sh"
        log_success "PRoot Helper erstellt: $EMULATOR_DIR/proot-helper.sh"
        return 0
    else
        log_error "PRoot Installation fehlgeschlagen"
        return 1
    fi
}

# Install Box64 (x86_64 emulation on ARM)
install_box64() {
    log_info "Installiere Box64 für x86_64 Emulation..."
    
    # Check if ARM architecture
    if [[ "$(uname -m)" != "aarch64" ]]; then
        log_warning "Box64 ist nur für ARM64 Systeme"
        return 1
    fi
    
    if command -v box64 &>/dev/null; then
        log_info "Box64 bereits installiert"
        return 0
    fi
    
    # Try to install from package
    pkg install -y box64 &>>"$LOG_FILE"
    
    if command -v box64 &>/dev/null; then
        log_success "Box64 installiert"
        
        # Create wrapper script
        cat > "$EMULATOR_DIR/box64-run.sh" << 'BOX64_EOF'
#!/bin/bash
# Box64 Wrapper für x86_64 Programme

if [[ -z "$1" ]]; then
    echo "Verwendung: $0 <x86_64-programm> [argumente]"
    exit 1
fi

if [[ ! -f "$1" ]]; then
    echo "Fehler: Datei nicht gefunden: $1"
    exit 1
fi

echo "Starte x86_64 Programm mit Box64..."
box64 "$@"
BOX64_EOF
        chmod +x "$EMULATOR_DIR/box64-run.sh"
        log_success "Box64 Wrapper erstellt"
        return 0
    else
        log_warning "Box64 Installation nicht verfügbar"
        return 1
    fi
}

# Install Wine (Windows emulation)
install_wine() {
    log_info "Installiere Wine für Windows-Programme..."
    
    if command -v wine &>/dev/null; then
        log_info "Wine bereits installiert"
        return 0
    fi
    
    pkg install -y wine &>>"$LOG_FILE"
    
    if command -v wine &>/dev/null; then
        log_success "Wine installiert"
        
        # Initialize wine prefix
        WINEPREFIX="$HOME/.wine" wineboot &>>"$LOG_FILE" &
        
        log_info "Wine wird initialisiert (läuft im Hintergrund)..."
        
        # Create wine helper
        cat > "$EMULATOR_DIR/wine-helper.sh" << 'WINE_EOF'
#!/bin/bash
# Wine Helper für Windows-Programme

export WINEPREFIX="$HOME/.wine"

echo "Wine Helper"
echo "==========="
echo
echo "Optionen:"
echo "  1) Windows-Programm ausführen"
echo "  2) Wine Konfiguration öffnen"
echo "  3) Windows Explorer öffnen"
echo "  4) Wine neu initialisieren"
echo "  5) Beenden"
echo
read -p "Option: " choice

case $choice in
    1)
        read -p "Pfad zur .exe Datei: " exe_path
        if [[ -f "$exe_path" ]]; then
            wine "$exe_path"
        else
            echo "Datei nicht gefunden"
        fi
        ;;
    2)
        winecfg
        ;;
    3)
        wine explorer
        ;;
    4)
        wineboot -u
        ;;
    5)
        exit 0
        ;;
esac
WINE_EOF
        chmod +x "$EMULATOR_DIR/wine-helper.sh"
        log_success "Wine Helper erstellt"
        return 0
    else
        log_warning "Wine Installation nicht verfügbar"
        return 1
    fi
}

# Install DosBox (DOS emulation)
install_dosbox() {
    log_info "Installiere DosBox für DOS-Programme..."
    
    if command -v dosbox &>/dev/null; then
        log_info "DosBox bereits installiert"
        return 0
    fi
    
    pkg install -y dosbox &>>"$LOG_FILE"
    
    if command -v dosbox &>/dev/null; then
        log_success "DosBox installiert"
        
        # Create config directory
        mkdir -p "$HOME/.dosbox"
        
        # Create launcher
        cat > "$EMULATOR_DIR/dosbox-launcher.sh" << 'DOSBOX_EOF'
#!/bin/bash
# DosBox Launcher

DOSBOX_DIR="$HOME/dosbox-games"
mkdir -p "$DOSBOX_DIR"

echo "DosBox Launcher"
echo "==============="
echo
echo "DOS-Programme Verzeichnis: $DOSBOX_DIR"
echo
echo "Optionen:"
echo "  1) DosBox starten"
echo "  2) DOS-Programm direkt ausführen"
echo "  3) DosBox Konfiguration bearbeiten"
echo "  4) Beenden"
echo
read -p "Option: " choice

case $choice in
    1)
        dosbox
        ;;
    2)
        read -p "Pfad zur .exe oder .bat Datei: " prog
        if [[ -f "$prog" ]]; then
            dosbox "$prog"
        else
            echo "Datei nicht gefunden"
        fi
        ;;
    3)
        ${EDITOR:-nano} ~/.dosbox/dosbox.conf
        ;;
    4)
        exit 0
        ;;
esac
DOSBOX_EOF
        chmod +x "$EMULATOR_DIR/dosbox-launcher.sh"
        log_success "DosBox Launcher erstellt"
        return 0
    else
        log_warning "DosBox Installation nicht verfügbar"
        return 1
    fi
}

# Install Termux:X11 support
install_x11_support() {
    log_info "Installiere X11 Unterstützung..."
    
    # Install X11 packages
    pkg install -y x11-repo &>>"$LOG_FILE"
    pkg install -y tigervnc xfce4 &>>"$LOG_FILE"
    
    if command -v vncserver &>/dev/null; then
        log_success "VNC Server installiert"
        
        # Create VNC starter
        cat > "$EMULATOR_DIR/start-vnc.sh" << 'VNC_EOF'
#!/bin/bash
# VNC Server Starter

VNC_DIR="$HOME/.vnc"
mkdir -p "$VNC_DIR"

echo "VNC Server Manager"
echo "=================="
echo
echo "Optionen:"
echo "  1) VNC Server starten"
echo "  2) VNC Server stoppen"
echo "  3) VNC Passwort setzen"
echo "  4) Beenden"
echo
read -p "Option: " choice

case $choice in
    1)
        vncserver -localhost no -geometry 1280x720 -depth 24
        echo
        echo "VNC Server gestartet auf localhost:5901"
        echo "Verbinde mit VNC Viewer zu: localhost:5901"
        ;;
    2)
        vncserver -kill :1
        echo "VNC Server gestoppt"
        ;;
    3)
        vncpasswd
        ;;
    4)
        exit 0
        ;;
esac
VNC_EOF
        chmod +x "$EMULATOR_DIR/start-vnc.sh"
        log_success "VNC Starter erstellt"
        return 0
    else
        log_warning "X11/VNC Installation nicht vollständig"
        return 1
    fi
}

# Create main menu
show_installation_menu() {
    show_banner
    
    echo -e "${CYAN}Verfügbare Emulatoren:${NC}"
    echo
    echo "  1) QEMU (x86_64/ARM Virtualisierung)"
    echo "  2) PRoot/proot-distro (Linux Distributionen)"
    echo "  3) Box64 (x86_64 auf ARM64)"
    echo "  4) Wine (Windows Programme)"
    echo "  5) DosBox (DOS Programme)"
    echo "  6) X11/VNC Support (Desktop-Umgebung)"
    echo "  7) Alle installieren"
    echo "  8) Status anzeigen"
    echo "  9) Beenden"
    echo
    read -p "Wähle Option: " choice
    
    case $choice in
        1) install_qemu ;;
        2) install_proot ;;
        3) install_box64 ;;
        4) install_wine ;;
        5) install_dosbox ;;
        6) install_x11_support ;;
        7)
            install_qemu
            install_proot
            install_box64
            install_wine
            install_dosbox
            install_x11_support
            ;;
        8) show_status ;;
        9) exit 0 ;;
        *)
            log_error "Ungültige Option"
            sleep 2
            show_installation_menu
            ;;
    esac
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
    show_installation_menu
}

# Show installation status
show_status() {
    echo
    echo -e "${CYAN}═══ Installationsstatus ═══${NC}"
    echo
    
    check_installed "QEMU" "qemu-system-x86_64"
    check_installed "PRoot" "proot"
    check_installed "proot-distro" "proot-distro"
    check_installed "Box64" "box64"
    check_installed "Wine" "wine"
    check_installed "DosBox" "dosbox"
    check_installed "VNC Server" "vncserver"
    
    echo
    echo -e "${CYAN}═══ Launcher Scripts ═══${NC}"
    echo
    
    [[ -f "$EMULATOR_DIR/qemu-launcher.sh" ]] && echo "  ✓ QEMU Launcher: $EMULATOR_DIR/qemu-launcher.sh"
    [[ -f "$EMULATOR_DIR/proot-helper.sh" ]] && echo "  ✓ PRoot Helper: $EMULATOR_DIR/proot-helper.sh"
    [[ -f "$EMULATOR_DIR/box64-run.sh" ]] && echo "  ✓ Box64 Wrapper: $EMULATOR_DIR/box64-run.sh"
    [[ -f "$EMULATOR_DIR/wine-helper.sh" ]] && echo "  ✓ Wine Helper: $EMULATOR_DIR/wine-helper.sh"
    [[ -f "$EMULATOR_DIR/dosbox-launcher.sh" ]] && echo "  ✓ DosBox Launcher: $EMULATOR_DIR/dosbox-launcher.sh"
    [[ -f "$EMULATOR_DIR/start-vnc.sh" ]] && echo "  ✓ VNC Starter: $EMULATOR_DIR/start-vnc.sh"
    
    echo
}

check_installed() {
    local name="$1"
    local cmd="$2"
    
    if command -v "$cmd" &>/dev/null; then
        local version=$("$cmd" --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        echo "  ✓ $name: installiert ${version:+(v$version)}"
    else
        echo "  ✗ $name: nicht installiert"
    fi
}

# Main function
main() {
    log_info "Starte Emulator Installer..."
    
    check_requirements || {
        log_error "System-Anforderungen nicht erfüllt"
        exit 1
    }
    
    show_installation_menu
}

main "$@"
