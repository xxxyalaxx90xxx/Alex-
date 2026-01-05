#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XA-vI v4.0 Pro - Network Manager
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey (xyalaxxx90@gmail.com)
# ==============================================================================

set -euo pipefail

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

INSTALL_DIR="$HOME/xtreme_ai_system"
LOG_FILE="$INSTALL_DIR/logs/network_$(date +%Y%m%d).log"

# ==============================================================================
# BANNER
# ==============================================================================
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║              🌐  NETWORK MANAGER v4.0 Pro                       ║
║                                                                  ║
║     Port Forwarding | Tunneling | Monitoring | Analysis        ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║  © Elektronikx-Center-Matte ®                                   ║
║  Cyborg System by Alexander Mathey                              ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ==============================================================================
# LOGGING
# ==============================================================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# ==============================================================================
# PORT FORWARDING
# ==============================================================================
setup_port_forwarding() {
    echo ""
    echo -e "${CYAN}=== Port Forwarding Setup ===${NC}"
    echo ""
    echo "1) SSH Tunnel (Local → Remote)"
    echo "2) SSH Tunnel (Remote → Local)"
    echo "3) SSH SOCKS Proxy"
    echo "4) Reverse SSH Tunnel"
    echo "5) Aktive Tunnels anzeigen"
    echo "0) Zurück"
    echo ""
    read -p "Wähle Option: " choice
    
    case $choice in
        1)
            read -p "Lokaler Port: " local_port
            read -p "Remote Host: " remote_host
            read -p "Remote Port: " remote_port
            read -p "SSH Server: " ssh_server
            
            ssh -f -N -L ${local_port}:${remote_host}:${remote_port} ${ssh_server}
            success "Tunnel erstellt: localhost:${local_port} → ${remote_host}:${remote_port}"
            ;;
        2)
            read -p "Remote Port: " remote_port
            read -p "Lokaler Host: " local_host
            read -p "Lokaler Port: " local_port
            read -p "SSH Server: " ssh_server
            
            ssh -f -N -R ${remote_port}:${local_host}:${local_port} ${ssh_server}
            success "Reverse Tunnel erstellt"
            ;;
        3)
            read -p "SOCKS Port (z.B. 1080): " socks_port
            read -p "SSH Server: " ssh_server
            
            ssh -f -N -D ${socks_port} ${ssh_server}
            success "SOCKS Proxy läuft auf localhost:${socks_port}"
            info "Konfiguriere Browser/Apps für SOCKS5 localhost:${socks_port}"
            ;;
        4)
            read -p "Reverse Port: " rev_port
            read -p "SSH Server: " ssh_server
            
            ssh -f -N -R ${rev_port}:localhost:22 ${ssh_server}
            success "Reverse SSH läuft (Remote Port: ${rev_port})"
            ;;
        5)
            ps aux | grep -E "ssh.*-[NfLD]"
            ;;
    esac
}

# ==============================================================================
# NETWORK MONITORING
# ==============================================================================
network_monitoring() {
    echo ""
    echo -e "${CYAN}=== Network Monitoring ===${NC}"
    echo ""
    echo "1) Aktive Verbindungen"
    echo "2) Listening Ports"
    echo "3) Bandbreiten-Monitor"
    echo "4) Ping Test"
    echo "5) Traceroute"
    echo "6) DNS Lookup"
    echo "7) Port Scan (lokal)"
    echo "0) Zurück"
    echo ""
    read -p "Wähle Option: " choice
    
    case $choice in
        1)
            echo ""
            netstat -tupn 2>/dev/null || ss -tupn
            ;;
        2)
            echo ""
            netstat -tuln 2>/dev/null || ss -tuln
            ;;
        3)
            if command -v vnstat &> /dev/null; then
                vnstat -l
            else
                info "vnstat nicht installiert. Installiere mit: pkg install vnstat"
            fi
            ;;
        4)
            read -p "Host: " host
            ping -c 5 "$host"
            ;;
        5)
            read -p "Host: " host
            if command -v traceroute &> /dev/null; then
                traceroute "$host"
            else
                tracepath "$host"
            fi
            ;;
        6)
            read -p "Domain: " domain
            nslookup "$domain" || dig "$domain"
            ;;
        7)
            if command -v nmap &> /dev/null; then
                nmap localhost
            else
                netstat -tuln | grep LISTEN
            fi
            ;;
    esac
}

# ==============================================================================
# NETWORK TOOLS
# ==============================================================================
network_tools() {
    echo ""
    echo -e "${CYAN}=== Network Tools ===${NC}"
    echo ""
    echo "1) HTTP Server starten (Python)"
    echo "2) TCP/UDP Test Server"
    echo "3) Netcat Listener"
    echo "4) Speed Test"
    echo "5) MTR (Network Diagnostic)"
    echo "6) IP Information anzeigen"
    echo "0) Zurück"
    echo ""
    read -p "Wähle Option: " choice
    
    case $choice in
        1)
            read -p "Port (Standard 8000): " port
            port=${port:-8000}
            read -p "Verzeichnis (Standard: aktuell): " dir
            dir=${dir:-.}
            
            cd "$dir"
            python -m http.server "$port" &
            success "HTTP Server läuft auf http://localhost:$port"
            info "PID: $!"
            ;;
        2)
            read -p "Protokoll (tcp/udp): " proto
            read -p "Port: " port
            
            if [ "$proto" = "tcp" ]; then
                nc -l -p "$port" &
                success "TCP Server auf Port $port"
            else
                nc -u -l -p "$port" &
                success "UDP Server auf Port $port"
            fi
            ;;
        3)
            read -p "Port: " port
            nc -l -p "$port"
            ;;
        4)
            if command -v speedtest-cli &> /dev/null; then
                speedtest-cli
            else
                curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -
            fi
            ;;
        5)
            read -p "Host: " host
            if command -v mtr &> /dev/null; then
                mtr "$host"
            else
                info "mtr nicht installiert. Verwende traceroute..."
                traceroute "$host"
            fi
            ;;
        6)
            echo ""
            echo "=== Lokale IP-Adressen ==="
            ip addr show | grep "inet " | grep -v "127.0.0.1"
            echo ""
            echo "=== Öffentliche IP ==="
            curl -s ifconfig.me
            echo ""
            ;;
    esac
}

# ==============================================================================
# FIREWALL & SECURITY
# ==============================================================================
network_security() {
    echo ""
    echo -e "${CYAN}=== Network Security ===${NC}"
    echo ""
    echo "1) Offene Ports prüfen"
    echo "2) Verdächtige Verbindungen"
    echo "3) Firewall-Regeln (iptables)"
    echo "4) Port blockieren"
    echo "5) DDoS Schutz aktivieren"
    echo "6) Netzwerk-Scan Erkennung"
    echo "0) Zurück"
    echo ""
    read -p "Wähle Option: " choice
    
    case $choice in
        1)
            echo ""
            echo "=== Listening Ports ==="
            netstat -tuln 2>/dev/null || ss -tuln
            ;;
        2)
            echo ""
            echo "=== Verdächtige Verbindungen ==="
            netstat -tupn 2>/dev/null | grep -E "ESTABLISHED|SYN_SENT" || ss -tupn
            ;;
        3)
            if command -v iptables &> /dev/null; then
                iptables -L -n -v
            else
                error "iptables benötigt Root-Rechte"
            fi
            ;;
        4)
            read -p "Port zu blockieren: " port
            if command -v iptables &> /dev/null; then
                iptables -A INPUT -p tcp --dport "$port" -j DROP
                success "Port $port blockiert"
            else
                error "iptables benötigt Root-Rechte"
            fi
            ;;
        5)
            info "DDoS-Schutz Regeln..."
            if command -v iptables &> /dev/null; then
                iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                success "DDoS-Schutz aktiviert"
            else
                error "iptables benötigt Root-Rechte"
            fi
            ;;
        6)
            info "Überwache Netzwerk auf Scans..."
            tcpdump -i any -n 'tcp[tcpflags] & (tcp-syn|tcp-fin) != 0' 2>/dev/null || \
                error "tcpdump benötigt Root oder ist nicht installiert"
            ;;
    esac
}

# ==============================================================================
# PROXY MANAGEMENT
# ==============================================================================
proxy_management() {
    echo ""
    echo -e "${CYAN}=== Proxy Management ===${NC}"
    echo ""
    echo "1) Privoxy starten (HTTP Proxy)"
    echo "2) tinyproxy starten"
    echo "3) SOCKS zu HTTP Proxy"
    echo "4) Proxy Tester"
    echo "5) Proxy Chain konfigurieren"
    echo "0) Zurück"
    echo ""
    read -p "Wähle Option: " choice
    
    case $choice in
        1)
            if command -v privoxy &> /dev/null; then
                privoxy &
                success "Privoxy läuft auf localhost:8118"
            else
                error "Privoxy nicht installiert: pkg install privoxy"
            fi
            ;;
        2)
            if command -v tinyproxy &> /dev/null; then
                tinyproxy
                success "tinyproxy läuft"
            else
                error "tinyproxy nicht installiert: pkg install tinyproxy"
            fi
            ;;
        3)
            read -p "SOCKS Port: " socks_port
            read -p "HTTP Proxy Port: " http_port
            
            if command -v privoxy &> /dev/null; then
                echo "forward-socks5 / 127.0.0.1:$socks_port ." > /tmp/privoxy.conf
                echo "listen-address 127.0.0.1:$http_port" >> /tmp/privoxy.conf
                privoxy /tmp/privoxy.conf &
                success "SOCKS→HTTP Proxy: localhost:$http_port"
            else
                error "Privoxy nicht installiert"
            fi
            ;;
        4)
            read -p "Proxy (host:port): " proxy
            curl -x "$proxy" -I https://google.com
            ;;
        5)
            info "Erstelle ProxyChains Konfiguration..."
            cat > "$HOME/.proxychains.conf" << 'PROXYCONF'
strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
# SOCKS5 Proxy
socks5 127.0.0.1 9050
PROXYCONF
            success "ProxyChains konfiguriert"
            info "Verwendung: proxychains4 <command>"
            ;;
    esac
}

# ==============================================================================
# MAIN MENU
# ==============================================================================
main_menu() {
    while true; do
        show_banner
        
        echo ""
        echo -e "${CYAN}=== Network Status ===${NC}"
        echo ""
        
        # Netzwerk-Interface
        if command -v ip &> /dev/null; then
            echo "Interface: $(ip route | grep default | awk '{print $5}')"
            echo "Lokale IP: $(ip addr show | grep "inet " | grep -v "127.0.0.1" | head -1 | awk '{print $2}' | cut -d'/' -f1)"
        fi
        
        echo ""
        echo -e "${CYAN}=== Hauptmenü ===${NC}"
        echo ""
        echo "1) Port Forwarding & Tunneling"
        echo "2) Network Monitoring"
        echo "3) Network Tools"
        echo "4) Network Security"
        echo "5) Proxy Management"
        echo ""
        echo "0) Beenden"
        echo ""
        read -p "Wähle Option: " choice
        
        case $choice in
            1) setup_port_forwarding ;;
            2) network_monitoring ;;
            3) network_tools ;;
            4) network_security ;;
            5) proxy_management ;;
            0) exit 0 ;;
            *) error "Ungültige Option" ;;
        esac
        
        echo ""
        read -p "Drücke Enter um fortzufahren..."
    done
}

# ==============================================================================
# INIT
# ==============================================================================
mkdir -p "$INSTALL_DIR/logs"

main_menu
