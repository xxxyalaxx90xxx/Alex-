#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XAI v4.0 - ENHANCED EMULATORS FOR LINUX/WINDOWS
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Complete Linux distributions and Windows software compatibility
# ==============================================================================

set -euo pipefail

# Farben
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          XTREME XAI v4.0 - ENHANCED EMULATORS                    ║${NC}"
    echo -e "${CYAN}║          © Elektronikx-Center-Matte ®                            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  ${CYAN}━━━ LINUX DISTRIBUTIONEN ━━━${NC}"
    echo "    1) Ubuntu 22.04 LTS (PRoot)"
    echo "    2) Debian 12 (PRoot)"
    echo "    3) Arch Linux (PRoot)"
    echo "    4) Alpine Linux (PRoot)"
    echo "    5) Fedora (PRoot)"
    echo ""
    echo "  ${CYAN}━━━ DESKTOP ENVIRONMENTS ━━━${NC}"
    echo "    6) XFCE Desktop + VNC"
    echo "    7) LXDE Desktop + VNC"
    echo "    8) GNOME Desktop (QEMU)"
    echo "    9) KDE Plasma (QEMU)"
    echo ""
    echo "  ${CYAN}━━━ WINDOWS KOMPATIBILITÄT ━━━${NC}"
    echo "   10) Wine 8.0+ (Windows .exe)"
    echo "   11) Windows 10 (QEMU)"
    echo ""
    echo "    0) Zurück"
    echo ""
    echo -n "Auswahl: "
}

install_proot_distro() {
    local distro=$1
    echo -e "${CYAN}Installiere $distro mit proot-distro...${NC}"
    
    if ! command -v proot-distro &>/dev/null; then
        pkg install -y proot-distro
    fi
    
    proot-distro install "$distro"
    echo -e "${GREEN}✓${NC} $distro installiert"
    echo ""
    echo "Starten mit: proot-distro login $distro"
}

install_vnc_desktop() {
    local desktop=$1
    echo -e "${CYAN}Installiere $desktop Desktop + VNC...${NC}"
    
    # Dependencies
    pkg install -y x11-repo
    pkg install -y tigervnc "$desktop"
    
    # VNC Setup
    mkdir -p "$HOME/.vnc"
    echo "#!/bin/bash
    $desktop-session &
    " > "$HOME/.vnc/xstartup"
    chmod +x "$HOME/.vnc/xstartup"
    
    echo -e "${GREEN}✓${NC} $desktop Desktop installiert"
    echo ""
    echo "VNC starten mit: vncserver :1"
    echo "VNC verbinden: localhost:5901"
}

install_wine() {
    echo -e "${CYAN}Installiere Wine für Windows-Software...${NC}"
    
    pkg install -y x11-repo
    pkg install -y wine
    
    echo -e "${GREEN}✓${NC} Wine installiert"
    echo ""
    echo "Windows .exe ausführen mit: wine programm.exe"
}

while true; do
    show_menu
    read -r choice
    
    case $choice in
        1) install_proot_distro "ubuntu" ;;
        2) install_proot_distro "debian" ;;
        3) install_proot_distro "archlinux" ;;
        4) install_proot_distro "alpine" ;;
        5) install_proot_distro "fedora" ;;
        6) install_vnc_desktop "xfce4" ;;
        7) install_vnc_desktop "lxde" ;;
        8) echo -e "${YELLOW}GNOME via QEMU - Erweiterte Installation erforderlich${NC}" ;;
        9) echo -e "${YELLOW}KDE via QEMU - Erweiterte Installation erforderlich${NC}" ;;
        10) install_wine ;;
        11) echo -e "${YELLOW}Windows 10 QEMU - Erweiterte Installation erforderlich${NC}" ;;
        0) break ;;
        *) echo -e "${RED}Ungültige Auswahl${NC}" ;;
    esac
    
    echo ""
    echo -n "Drücke Enter um fortzufahren..."
    read -r
done
