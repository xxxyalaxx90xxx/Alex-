#!/bin/bash

################################################################################
# Tor Browser & Network Integration
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Tor Browser Installation und Anonymisierungs-Tools
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
TOR_DIR="${INSTALL_DIR}/tor"
LOG_FILE="${INSTALL_DIR}/logs/tor_$(date +%Y%m%d_%H%M%S).log"

log_info() {
    echo -e "${BLUE}[TOR]${NC} $1" | tee -a "$LOG_FILE"
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
mkdir -p "$TOR_DIR" "$(dirname "$LOG_FILE")"

# Show banner
show_banner() {
    clear
    echo -e "${MAGENTA}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║           XTREME XAI Tor Integration v4.0                 ║
║     © Elektronikx-Center-Matte ® | Alexander Mathey ©     ║
║                                                            ║
║     Anonymes Surfen mit Tor Network                       ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Install Tor
install_tor() {
    log_info "Installiere Tor..."
    
    if command -v tor &>/dev/null; then
        log_info "Tor bereits installiert"
        return 0
    fi
    
    pkg install -y tor &>>"$LOG_FILE"
    
    if command -v tor &>/dev/null; then
        log_success "Tor installiert"
        
        # Create tor configuration
        mkdir -p "$HOME/.tor"
        cat > "$HOME/.tor/torrc" << 'TOR_CFG'
# Tor Configuration für XTREME XAI
SocksPort 9050
ControlPort 9051
DataDirectory /data/data/com.termux/files/home/.tor/data
Log notice file /data/data/com.termux/files/home/.tor/tor.log

# Transparenter Proxy (optional)
# TransPort 9040
# DNSPort 5353

# Hidden Service (optional auskommentiert)
# HiddenServiceDir /data/data/com.termux/files/home/.tor/hidden_service/
# HiddenServicePort 80 127.0.0.1:8080
TOR_CFG
        
        mkdir -p "$HOME/.tor/data"
        
        log_success "Tor Konfiguration erstellt"
        return 0
    else
        log_error "Tor Installation fehlgeschlagen"
        return 1
    fi
}

# Install Tor Browser Launcher
install_tor_browser() {
    log_info "Richte Tor Browser Umgebung ein..."
    
    # Create Tor Browser launcher
    cat > "$TOR_DIR/tor-browser-launcher.sh" << 'TOR_BROWSER_EOF'
#!/bin/bash
# Tor Browser Launcher für Termux

echo "Tor Browser Launcher"
echo "===================="
echo
echo "HINWEIS: Tor Browser für Android erfordert eine der folgenden Optionen:"
echo
echo "Optionen:"
echo "  1) Tor Browser (offizielle Android App) - Empfohlen"
echo "  2) Firefox + Orbot (Proxy-Modus)"
echo "  3) Brave Browser mit Tor (eingebaut)"
echo "  4) Tor im Terminal (torsocks)"
echo "  5) Zurück"
echo
read -p "Wähle Option: " choice

case $choice in
    1)
        echo
        echo "Installiere Tor Browser (offizielle App):"
        echo "1. Öffne F-Droid oder Play Store"
        echo "2. Suche nach 'Tor Browser'"
        echo "3. Installiere 'Tor Browser: Official, Private, & Secure'"
        echo
        echo "Oder nutze diesen Link:"
        echo "https://www.torproject.org/download/#android"
        echo
        read -p "App installiert? Drücke Enter..."
        
        # Try to open Tor Browser if installed
        am start -n org.torproject.torbrowser/.MainActivity 2>/dev/null || \
        echo "Tor Browser App nicht gefunden"
        ;;
    2)
        echo
        echo "Firefox + Orbot Setup:"
        echo "1. Installiere Orbot aus F-Droid"
        echo "2. Installiere Firefox"
        echo "3. In Firefox: Einstellungen → Erweitert → Proxy"
        echo "   - SOCKS Host: 127.0.0.1"
        echo "   - Port: 9050"
        echo "4. Starte Orbot und verbinde"
        echo
        ;;
    3)
        echo
        echo "Brave Browser mit Tor:"
        echo "1. Installiere Brave Browser"
        echo "2. Öffne Brave"
        echo "3. Tippe auf Menü (3 Punkte)"
        echo "4. Wähle 'Neues privates Tab mit Tor'"
        echo
        ;;
    4)
        if command -v torsocks &>/dev/null; then
            echo "torsocks ist installiert"
            echo "Verwendung: torsocks <befehl>"
            echo "Beispiel: torsocks curl https://check.torproject.org"
        else
            echo "Installiere torsocks..."
            pkg install -y torsocks
        fi
        ;;
    5)
        return
        ;;
esac
TOR_BROWSER_EOF
    chmod +x "$TOR_DIR/tor-browser-launcher.sh"
    log_success "Tor Browser Launcher erstellt"
}

# Install Orbot (Tor for Android)
setup_orbot() {
    log_info "Orbot Setup-Anleitung..."
    
    cat > "$TOR_DIR/orbot-setup.txt" << 'ORBOT_SETUP'
ORBOT - Tor für Android
========================

Installation:
1. Öffne F-Droid oder Play Store
2. Suche nach "Orbot"
3. Installiere "Orbot: Tor for Android"

Konfiguration:
1. Öffne Orbot
2. Tippe auf das Zwiebel-Symbol zum Verbinden
3. Warte bis "Verbunden" angezeigt wird

Apps durch Tor leiten:
1. Tippe auf das Menü (3 Punkte oben rechts)
2. Wähle "Apps"
3. Wähle Apps aus, die Tor nutzen sollen

Browser-Konfiguration:
- Firefox: Proxy auf 127.0.0.1:9050 setzen
- Chrome/Brave: Orbot VPN-Modus nutzen

Termux-Integration:
- HTTP Proxy: 127.0.0.1:8118 (wenn Orbot mit PoliPo läuft)
- SOCKS Proxy: 127.0.0.1:9050

Tor testen:
- Browser: https://check.torproject.org
- Terminal: torsocks curl https://check.torproject.org
ORBOT_SETUP
    
    log_success "Orbot Setup-Anleitung erstellt: $TOR_DIR/orbot-setup.txt"
}

# Install torsocks
install_torsocks() {
    log_info "Installiere torsocks..."
    
    if command -v torsocks &>/dev/null; then
        log_info "torsocks bereits installiert"
        return 0
    fi
    
    pkg install -y torsocks &>>"$LOG_FILE"
    
    if command -v torsocks &>/dev/null; then
        log_success "torsocks installiert"
        
        # Create torsocks wrapper
        cat > "$TOR_DIR/tor-wrapper.sh" << 'TORSOCKS_EOF'
#!/bin/bash
# Tor Wrapper für Befehle

if [[ -z "$1" ]]; then
    echo "Verwendung: $0 <befehl> [argumente]"
    echo
    echo "Beispiele:"
    echo "  $0 curl https://check.torproject.org"
    echo "  $0 wget https://example.com"
    echo "  $0 ssh user@host"
    exit 1
fi

# Check if Tor is running
if ! pgrep -x tor >/dev/null; then
    echo "Warnung: Tor läuft nicht. Starte Tor..."
    tor &
    sleep 5
fi

echo "Führe Befehl über Tor aus: $@"
torsocks "$@"
TORSOCKS_EOF
        chmod +x "$TOR_DIR/tor-wrapper.sh"
        log_success "Tor Wrapper erstellt"
        return 0
    else
        log_warning "torsocks Installation nicht verfügbar"
        return 1
    fi
}

# Install Privoxy (HTTP Proxy for Tor)
install_privoxy() {
    log_info "Installiere Privoxy..."
    
    if command -v privoxy &>/dev/null; then
        log_info "Privoxy bereits installiert"
        return 0
    fi
    
    pkg install -y privoxy &>>"$LOG_FILE"
    
    if command -v privoxy &>/dev/null; then
        log_success "Privoxy installiert"
        
        # Configure Privoxy to use Tor
        local config_file="$PREFIX/etc/privoxy/config"
        if [[ -f "$config_file" ]]; then
            # Add Tor forward if not already present
            if ! grep -q "forward-socks5" "$config_file"; then
                echo "" >> "$config_file"
                echo "# Forward to Tor SOCKS proxy" >> "$config_file"
                echo "forward-socks5 / 127.0.0.1:9050 ." >> "$config_file"
                log_success "Privoxy für Tor konfiguriert"
            fi
        fi
        
        return 0
    else
        log_warning "Privoxy Installation nicht verfügbar"
        return 1
    fi
}

# Create Tor manager
create_tor_manager() {
    cat > "$TOR_DIR/tor-manager.sh" << 'TOR_MANAGER'
#!/bin/bash
# Tor Network Manager

TOR_LOG="$HOME/.tor/tor.log"

echo "Tor Network Manager"
echo "==================="
echo
echo "Optionen:"
echo "  1) Tor starten"
echo "  2) Tor stoppen"
echo "  3) Tor Status"
echo "  4) Tor neu starten"
echo "  5) Tor Logs anzeigen"
echo "  6) IP-Adresse prüfen"
echo "  7) Neue Tor-Identität"
echo "  8) Hidden Service einrichten"
echo "  9) Beenden"
echo
read -p "Wähle Option: " choice

case $choice in
    1)
        if pgrep -x tor >/dev/null; then
            echo "Tor läuft bereits"
        else
            tor -f ~/.tor/torrc &
            sleep 3
            if pgrep -x tor >/dev/null; then
                echo "✓ Tor gestartet"
                echo "SOCKS Proxy: 127.0.0.1:9050"
            else
                echo "✗ Tor Start fehlgeschlagen"
            fi
        fi
        ;;
    2)
        killall tor 2>/dev/null
        echo "Tor gestoppt"
        ;;
    3)
        if pgrep -x tor >/dev/null; then
            echo "Status: ✓ Läuft"
            echo
            echo "Prozess-Info:"
            ps aux | grep tor | grep -v grep
            echo
            if [[ -f "$TOR_LOG" ]]; then
                echo "Letzte Log-Einträge:"
                tail -5 "$TOR_LOG"
            fi
        else
            echo "Status: ✗ Gestoppt"
        fi
        ;;
    4)
        killall tor 2>/dev/null
        sleep 2
        tor -f ~/.tor/torrc &
        sleep 3
        echo "Tor neu gestartet"
        ;;
    5)
        if [[ -f "$TOR_LOG" ]]; then
            tail -50 "$TOR_LOG"
        else
            echo "Keine Logs gefunden"
        fi
        ;;
    6)
        echo "Normale IP:"
        curl -s ifconfig.me
        echo
        echo
        echo "Tor IP:"
        torsocks curl -s ifconfig.me
        echo
        ;;
    7)
        if command -v nc &>/dev/null; then
            echo "Fordere neue Identität an..."
            echo -e 'AUTHENTICATE ""\r\nSIGNAL NEWNYM\r\nQUIT' | nc 127.0.0.1 9051
            echo "Neue Identität angefordert"
        else
            echo "nc (netcat) wird benötigt"
            echo "Installiere mit: pkg install netcat"
        fi
        ;;
    8)
        echo "Hidden Service Einrichtung"
        echo "=========================="
        echo
        read -p "Local Port (z.B. 8080): " local_port
        
        mkdir -p ~/.tor/hidden_service
        
        cat >> ~/.tor/torrc << HIDDEN
        
# Hidden Service Configuration
HiddenServiceDir /data/data/com.termux/files/home/.tor/hidden_service/
HiddenServicePort 80 127.0.0.1:$local_port
HIDDEN
        
        echo "Konfiguration hinzugefügt. Starte Tor neu..."
        killall tor 2>/dev/null
        sleep 2
        tor -f ~/.tor/torrc &
        sleep 5
        
        if [[ -f ~/.tor/hidden_service/hostname ]]; then
            echo
            echo "✓ Hidden Service erstellt!"
            echo "Onion-Adresse:"
            cat ~/.tor/hidden_service/hostname
            echo
            echo "Dein Service ist erreichbar unter dieser .onion Adresse"
        else
            echo "✗ Hidden Service konnte nicht erstellt werden"
        fi
        ;;
    9)
        exit 0
        ;;
esac
TOR_MANAGER
    chmod +x "$TOR_DIR/tor-manager.sh"
    log_success "Tor Manager erstellt"
}

# Create Tor connection tester
create_tor_tester() {
    cat > "$TOR_DIR/tor-test.sh" << 'TOR_TEST'
#!/bin/bash
# Tor Connection Tester

echo "Tor Verbindungstest"
echo "==================="
echo

# Check if Tor is running
echo "[1/4] Prüfe Tor Status..."
if pgrep -x tor >/dev/null; then
    echo "✓ Tor läuft"
else
    echo "✗ Tor läuft nicht"
    echo "Starte mit: bash ~/xtreme_ai_system/tor/tor-manager.sh"
    exit 1
fi
echo

# Check Tor connection
echo "[2/4] Teste Tor-Verbindung..."
if command -v torsocks &>/dev/null; then
    if torsocks curl -s https://check.torproject.org | grep -q "Congratulations"; then
        echo "✓ Tor funktioniert!"
    else
        echo "✗ Tor-Verbindung fehlgeschlagen"
    fi
else
    echo "✗ torsocks nicht installiert"
fi
echo

# Check IP through Tor
echo "[3/4] Externe IP über Tor:"
if command -v torsocks &>/dev/null; then
    tor_ip=$(torsocks curl -s ifconfig.me)
    echo "Tor IP: $tor_ip"
else
    echo "torsocks wird benötigt"
fi
echo

# Check regular IP for comparison
echo "[4/4] Normale IP (ohne Tor):"
normal_ip=$(curl -s ifconfig.me)
echo "Normale IP: $normal_ip"
echo

echo "Test abgeschlossen"
TOR_TEST
    chmod +x "$TOR_DIR/tor-test.sh"
    log_success "Tor Tester erstellt"
}

# Main menu
show_main_menu() {
    show_banner
    
    echo -e "${CYAN}Tor Installation & Management${NC}"
    echo
    echo "  1) Tor installieren"
    echo "  2) Tor Browser Launcher"
    echo "  3) Orbot Setup-Anleitung"
    echo "  4) torsocks installieren"
    echo "  5) Privoxy installieren (HTTP Proxy)"
    echo "  6) Alle installieren"
    echo "  7) Tor-Verbindung testen"
    echo "  8) Tor Manager öffnen"
    echo "  9) Installationsstatus"
    echo "  10) Beenden"
    echo
    read -p "Wähle Option: " choice
    
    case $choice in
        1) install_tor ;;
        2)
            install_tor_browser
            bash "$TOR_DIR/tor-browser-launcher.sh"
            ;;
        3)
            setup_orbot
            cat "$TOR_DIR/orbot-setup.txt"
            ;;
        4) install_torsocks ;;
        5) install_privoxy ;;
        6)
            install_tor
            install_tor_browser
            setup_orbot
            install_torsocks
            install_privoxy
            create_tor_manager
            create_tor_tester
            ;;
        7)
            if [[ -f "$TOR_DIR/tor-test.sh" ]]; then
                bash "$TOR_DIR/tor-test.sh"
            else
                create_tor_tester
                bash "$TOR_DIR/tor-test.sh"
            fi
            ;;
        8)
            if [[ -f "$TOR_DIR/tor-manager.sh" ]]; then
                bash "$TOR_DIR/tor-manager.sh"
            else
                create_tor_manager
                bash "$TOR_DIR/tor-manager.sh"
            fi
            ;;
        9) show_status ;;
        10) exit 0 ;;
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
    echo -e "${CYAN}═══ Tor Installationsstatus ═══${NC}"
    echo
    
    check_tor_installed "Tor" "tor"
    check_tor_installed "torsocks" "torsocks"
    check_tor_installed "Privoxy" "privoxy"
    
    echo
    echo -e "${CYAN}═══ Tor Scripts ═══${NC}"
    echo
    
    [[ -f "$TOR_DIR/tor-manager.sh" ]] && echo "  ✓ Tor Manager"
    [[ -f "$TOR_DIR/tor-browser-launcher.sh" ]] && echo "  ✓ Tor Browser Launcher"
    [[ -f "$TOR_DIR/tor-wrapper.sh" ]] && echo "  ✓ Tor Wrapper"
    [[ -f "$TOR_DIR/tor-test.sh" ]] && echo "  ✓ Tor Tester"
    [[ -f "$TOR_DIR/orbot-setup.txt" ]] && echo "  ✓ Orbot Setup-Anleitung"
    
    echo
    echo "Tor-Verzeichnis: $TOR_DIR"
    echo
    
    # Check if Tor is currently running
    if pgrep -x tor >/dev/null; then
        echo -e "${GREEN}Status: Tor läuft${NC}"
    else
        echo -e "${YELLOW}Status: Tor läuft nicht${NC}"
    fi
    echo
}

check_tor_installed() {
    local name="$1"
    local cmd="$2"
    
    if command -v "$cmd" &>/dev/null; then
        local version=$("$cmd" --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        echo "  ✓ $name: installiert ${version:+(v$version)}"
    else
        echo "  ✗ $name: nicht installiert"
    fi
}

# Main
main() {
    log_info "Starte Tor Integration..."
    show_main_menu
}

main "$@"
