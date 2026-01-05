#!/bin/bash

################################################################################
# VPN Setup & Manager
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# VPN Installation und Verwaltung für XTREME-XAI
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
VPN_DIR="${INSTALL_DIR}/vpn"
CONFIG_DIR="${VPN_DIR}/configs"
LOG_FILE="${INSTALL_DIR}/logs/vpn_$(date +%Y%m%d_%H%M%S).log"

log_info() {
    echo -e "${BLUE}[VPN]${NC} $1" | tee -a "$LOG_FILE"
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
mkdir -p "$VPN_DIR" "$CONFIG_DIR" "$(dirname "$LOG_FILE")"

# Show banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║           XTREME XAI VPN Manager v4.0                     ║
║     © Elektronikx-Center-Matte ® | Alexander Mathey ©     ║
║                                                            ║
║     Sichere VPN-Verbindungen für Termux                   ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Install OpenVPN
install_openvpn() {
    log_info "Installiere OpenVPN..."
    
    if command -v openvpn &>/dev/null; then
        log_info "OpenVPN bereits installiert"
        return 0
    fi
    
    pkg install -y openvpn &>>"$LOG_FILE"
    
    if command -v openvpn &>/dev/null; then
        log_success "OpenVPN installiert"
        
        # Create OpenVPN helper
        cat > "$VPN_DIR/openvpn-manager.sh" << 'OVPN_EOF'
#!/bin/bash
# OpenVPN Manager

CONFIG_DIR="$HOME/xtreme_ai_system/vpn/configs"
mkdir -p "$CONFIG_DIR"

echo "OpenVPN Manager"
echo "==============="
echo
echo "Optionen:"
echo "  1) VPN Verbindung starten"
echo "  2) VPN Verbindung stoppen"
echo "  3) Verbindungsstatus"
echo "  4) Neue Konfiguration hinzufügen"
echo "  5) Konfigurationen auflisten"
echo "  6) Beenden"
echo
read -p "Option: " choice

case $choice in
    1)
        echo "Verfügbare Konfigurationen:"
        ls -1 "$CONFIG_DIR"/*.ovpn 2>/dev/null | nl
        read -p "Nummer wählen: " num
        config=$(ls -1 "$CONFIG_DIR"/*.ovpn 2>/dev/null | sed -n "${num}p")
        if [[ -f "$config" ]]; then
            echo "Starte VPN mit $config..."
            sudo openvpn --config "$config"
        else
            echo "Konfiguration nicht gefunden"
        fi
        ;;
    2)
        sudo killall openvpn
        echo "VPN Verbindung gestoppt"
        ;;
    3)
        if pgrep -x openvpn > /dev/null; then
            echo "VPN Status: Verbunden"
            echo "Prozess-Info:"
            ps aux | grep openvpn | grep -v grep
        else
            echo "VPN Status: Nicht verbunden"
        fi
        ;;
    4)
        read -p "Pfad zur .ovpn Datei: " ovpn_file
        if [[ -f "$ovpn_file" ]]; then
            cp "$ovpn_file" "$CONFIG_DIR/"
            echo "Konfiguration hinzugefügt"
        else
            echo "Datei nicht gefunden"
        fi
        ;;
    5)
        echo "Verfügbare Konfigurationen:"
        ls -lh "$CONFIG_DIR"/*.ovpn 2>/dev/null || echo "Keine Konfigurationen gefunden"
        ;;
    6)
        exit 0
        ;;
esac
OVPN_EOF
        chmod +x "$VPN_DIR/openvpn-manager.sh"
        log_success "OpenVPN Manager erstellt"
        return 0
    else
        log_error "OpenVPN Installation fehlgeschlagen"
        return 1
    fi
}

# Install WireGuard
install_wireguard() {
    log_info "Installiere WireGuard..."
    
    if command -v wg &>/dev/null; then
        log_info "WireGuard bereits installiert"
        return 0
    fi
    
    pkg install -y wireguard-tools &>>"$LOG_FILE"
    
    if command -v wg &>/dev/null; then
        log_success "WireGuard Tools installiert"
        
        # Create WireGuard helper
        cat > "$VPN_DIR/wireguard-manager.sh" << 'WG_EOF'
#!/bin/bash
# WireGuard Manager

CONFIG_DIR="$HOME/xtreme_ai_system/vpn/configs"
WG_DIR="/data/data/com.termux/files/usr/etc/wireguard"
mkdir -p "$CONFIG_DIR" "$WG_DIR"

echo "WireGuard Manager"
echo "================="
echo
echo "Optionen:"
echo "  1) WireGuard Tunnel starten"
echo "  2) WireGuard Tunnel stoppen"
echo "  3) Tunnel Status"
echo "  4) Neue Konfiguration hinzufügen"
echo "  5) Konfigurationen auflisten"
echo "  6) Schlüsselpaar generieren"
echo "  7) Beenden"
echo
read -p "Option: " choice

case $choice in
    1)
        echo "Verfügbare Konfigurationen:"
        ls -1 "$CONFIG_DIR"/*.conf 2>/dev/null | nl
        read -p "Nummer wählen: " num
        config=$(ls -1 "$CONFIG_DIR"/*.conf 2>/dev/null | sed -n "${num}p")
        if [[ -f "$config" ]]; then
            interface=$(basename "$config" .conf)
            sudo wg-quick up "$config"
            echo "WireGuard Tunnel '$interface' gestartet"
        else
            echo "Konfiguration nicht gefunden"
        fi
        ;;
    2)
        read -p "Interface Name (z.B. wg0): " interface
        sudo wg-quick down "$interface"
        echo "WireGuard Tunnel gestoppt"
        ;;
    3)
        sudo wg show
        ;;
    4)
        read -p "Pfad zur .conf Datei: " conf_file
        if [[ -f "$conf_file" ]]; then
            cp "$conf_file" "$CONFIG_DIR/"
            echo "Konfiguration hinzugefügt"
        else
            echo "Datei nicht gefunden"
        fi
        ;;
    5)
        echo "Verfügbare Konfigurationen:"
        ls -lh "$CONFIG_DIR"/*.conf 2>/dev/null || echo "Keine Konfigurationen gefunden"
        ;;
    6)
        echo "Generiere WireGuard Schlüsselpaar..."
        private_key=$(wg genkey)
        public_key=$(echo "$private_key" | wg pubkey)
        echo
        echo "Private Key: $private_key"
        echo "Public Key: $public_key"
        echo
        echo "Speichere Schlüssel sicher!"
        ;;
    7)
        exit 0
        ;;
esac
WG_EOF
        chmod +x "$VPN_DIR/wireguard-manager.sh"
        log_success "WireGuard Manager erstellt"
        return 0
    else
        log_warning "WireGuard Installation nicht verfügbar"
        return 1
    fi
}

# Install Shadowsocks
install_shadowsocks() {
    log_info "Installiere Shadowsocks..."
    
    if command -v ss-local &>/dev/null; then
        log_info "Shadowsocks bereits installiert"
        return 0
    fi
    
    pkg install -y shadowsocks-libev &>>"$LOG_FILE"
    
    if command -v ss-local &>/dev/null; then
        log_success "Shadowsocks installiert"
        
        # Create config template
        cat > "$CONFIG_DIR/shadowsocks-template.json" << 'SS_EOF'
{
    "server": "your.server.com",
    "server_port": 8388,
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "your_password",
    "timeout": 300,
    "method": "aes-256-gcm"
}
SS_EOF
        
        # Create Shadowsocks manager
        cat > "$VPN_DIR/shadowsocks-manager.sh" << 'SS_MGR_EOF'
#!/bin/bash
# Shadowsocks Manager

CONFIG_DIR="$HOME/xtreme_ai_system/vpn/configs"

echo "Shadowsocks Manager"
echo "==================="
echo
echo "Optionen:"
echo "  1) Shadowsocks starten"
echo "  2) Shadowsocks stoppen"
echo "  3) Status"
echo "  4) Konfiguration bearbeiten"
echo "  5) Beenden"
echo
read -p "Option: " choice

case $choice in
    1)
        if [[ -f "$CONFIG_DIR/shadowsocks.json" ]]; then
            ss-local -c "$CONFIG_DIR/shadowsocks.json" &
            echo "Shadowsocks gestartet auf localhost:1080"
        else
            echo "Konfiguration nicht gefunden. Bitte erstelle $CONFIG_DIR/shadowsocks.json"
            echo "Template: $CONFIG_DIR/shadowsocks-template.json"
        fi
        ;;
    2)
        killall ss-local
        echo "Shadowsocks gestoppt"
        ;;
    3)
        if pgrep -x ss-local > /dev/null; then
            echo "Status: Läuft"
            ps aux | grep ss-local | grep -v grep
        else
            echo "Status: Gestoppt"
        fi
        ;;
    4)
        ${EDITOR:-nano} "$CONFIG_DIR/shadowsocks.json"
        ;;
    5)
        exit 0
        ;;
esac
SS_MGR_EOF
        chmod +x "$VPN_DIR/shadowsocks-manager.sh"
        log_success "Shadowsocks Manager erstellt"
        return 0
    else
        log_warning "Shadowsocks Installation nicht verfügbar"
        return 1
    fi
}

# Install V2Ray
install_v2ray() {
    log_info "Installiere V2Ray..."
    
    if command -v v2ray &>/dev/null; then
        log_info "V2Ray bereits installiert"
        return 0
    fi
    
    # V2Ray manual installation
    log_info "Lade V2Ray herunter..."
    
    local arch=$(uname -m)
    local v2ray_url=""
    
    case "$arch" in
        aarch64|arm64)
            v2ray_url="https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-arm64-v5.zip"
            ;;
        armv7l|armhf)
            v2ray_url="https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-arm32-v7a.zip"
            ;;
        x86_64|amd64)
            v2ray_url="https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip"
            ;;
        *)
            log_error "Architektur nicht unterstützt: $arch"
            return 1
            ;;
    esac
    
    local v2ray_install_dir="$VPN_DIR/v2ray"
    mkdir -p "$v2ray_install_dir"
    
    if command -v curl &>/dev/null; then
        curl -L "$v2ray_url" -o "$v2ray_install_dir/v2ray.zip" &>>"$LOG_FILE"
    elif command -v wget &>/dev/null; then
        wget "$v2ray_url" -O "$v2ray_install_dir/v2ray.zip" &>>"$LOG_FILE"
    else
        log_error "curl oder wget benötigt"
        return 1
    fi
    
    if command -v unzip &>/dev/null; then
        unzip -o "$v2ray_install_dir/v2ray.zip" -d "$v2ray_install_dir" &>>"$LOG_FILE"
        chmod +x "$v2ray_install_dir/v2ray"
        rm "$v2ray_install_dir/v2ray.zip"
        
        # Create symlink
        ln -sf "$v2ray_install_dir/v2ray" "$HOME/../usr/bin/v2ray" 2>/dev/null
        
        log_success "V2Ray installiert"
        return 0
    else
        log_error "unzip benötigt für Installation"
        return 1
    fi
}

# Create VPN connection tester
create_connection_tester() {
    cat > "$VPN_DIR/vpn-test.sh" << 'TEST_EOF'
#!/bin/bash
# VPN Connection Tester

echo "VPN Verbindungstest"
echo "==================="
echo

# Test 1: Check default gateway
echo "[1/5] Prüfe Default Gateway..."
ip route | grep default && echo "✓ Gateway OK" || echo "✗ Kein Gateway"
echo

# Test 2: DNS Resolution
echo "[2/5] Teste DNS Auflösung..."
nslookup google.com &>/dev/null && echo "✓ DNS OK" || echo "✗ DNS Fehler"
echo

# Test 3: Internet connectivity
echo "[3/5] Teste Internet-Verbindung..."
ping -c 3 8.8.8.8 &>/dev/null && echo "✓ Internet OK" || echo "✗ Keine Verbindung"
echo

# Test 4: Check IP address
echo "[4/5] Externe IP-Adresse:"
curl -s ifconfig.me || curl -s ipinfo.io/ip || echo "✗ Konnte IP nicht ermitteln"
echo
echo

# Test 5: DNS Leak Test
echo "[5/5] DNS Server:"
cat /etc/resolv.conf | grep nameserver
echo

echo "Test abgeschlossen"
TEST_EOF
    chmod +x "$VPN_DIR/vpn-test.sh"
    log_success "VPN Tester erstellt"
}

# Main menu
show_main_menu() {
    show_banner
    
    echo -e "${CYAN}VPN Installation & Management${NC}"
    echo
    echo "  1) OpenVPN installieren"
    echo "  2) WireGuard installieren"
    echo "  3) Shadowsocks installieren"
    echo "  4) V2Ray installieren"
    echo "  5) Alle installieren"
    echo "  6) VPN-Verbindung testen"
    echo "  7) Installationsstatus"
    echo "  8) Beenden"
    echo
    read -p "Wähle Option: " choice
    
    case $choice in
        1) install_openvpn ;;
        2) install_wireguard ;;
        3) install_shadowsocks ;;
        4) install_v2ray ;;
        5)
            install_openvpn
            install_wireguard
            install_shadowsocks
            install_v2ray
            create_connection_tester
            ;;
        6)
            if [[ -f "$VPN_DIR/vpn-test.sh" ]]; then
                bash "$VPN_DIR/vpn-test.sh"
            else
                create_connection_tester
                bash "$VPN_DIR/vpn-test.sh"
            fi
            ;;
        7) show_status ;;
        8) exit 0 ;;
        *)
            log_error "Ungültige Option"
            sleep 2
            show_main_menu
            ;;
    esac
    
    echo
    read -p "Drücke Enter zum Fortfahren..."
    show_main_menu
}

# Show status
show_status() {
    echo
    echo -e "${CYAN}═══ VPN Installationsstatus ═══${NC}"
    echo
    
    check_vpn_installed "OpenVPN" "openvpn"
    check_vpn_installed "WireGuard" "wg"
    check_vpn_installed "Shadowsocks" "ss-local"
    check_vpn_installed "V2Ray" "v2ray"
    
    echo
    echo -e "${CYAN}═══ Manager Scripts ═══${NC}"
    echo
    
    [[ -f "$VPN_DIR/openvpn-manager.sh" ]] && echo "  ✓ OpenVPN Manager"
    [[ -f "$VPN_DIR/wireguard-manager.sh" ]] && echo "  ✓ WireGuard Manager"
    [[ -f "$VPN_DIR/shadowsocks-manager.sh" ]] && echo "  ✓ Shadowsocks Manager"
    [[ -f "$VPN_DIR/vpn-test.sh" ]] && echo "  ✓ VPN Tester"
    
    echo
    echo "Konfigurationsverzeichnis: $CONFIG_DIR"
    echo
}

check_vpn_installed() {
    local name="$1"
    local cmd="$2"
    
    if command -v "$cmd" &>/dev/null; then
        echo "  ✓ $name: installiert"
    else
        echo "  ✗ $name: nicht installiert"
    fi
}

# Main
main() {
    log_info "Starte VPN Manager..."
    create_connection_tester
    show_main_menu
}

main "$@"
