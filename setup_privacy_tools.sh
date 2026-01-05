#!/bin/bash

# Privacy and Networking Tools Setup
# Includes Tor Browser, VPN, secure connections
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
INSTALL_TOR_BROWSER="${INSTALL_TOR_BROWSER:-true}"
INSTALL_TOR_SERVICE="${INSTALL_TOR_SERVICE:-true}"
INSTALL_VPN="${INSTALL_VPN:-true}"
INSTALL_PRIVACY_TOOLS="${INSTALL_PRIVACY_TOOLS:-true}"

# Print functions
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif command -v termux-info &> /dev/null; then
        OS="termux"
    else
        OS="unknown"
    fi
}

# Install Tor service
install_tor_service() {
    if [ "$INSTALL_TOR_SERVICE" != "true" ]; then
        print_info "Skipping Tor service installation"
        return
    fi
    
    print_header "Installing Tor Service"
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y tor
            ;;
        centos|rhel|fedora)
            sudo dnf install -y tor
            ;;
        termux)
            pkg install -y tor
            ;;
        *)
            print_error "Unsupported OS for Tor service"
            return
            ;;
    esac
    
    # Configure Tor
    if [ "$OS" != "termux" ]; then
        sudo tee /etc/tor/torrc > /dev/null << 'EOF'
# Tor configuration
SOCKSPort 9050
ControlPort 9051
CookieAuthentication 1

# DNS
DNSPort 5353

# Transparent proxy
TransPort 9040
TransListenAddress 127.0.0.1
EOF
        
        sudo systemctl enable tor
        sudo systemctl start tor
    fi
    
    print_success "Tor service installed"
}

# Install Tor Browser
install_tor_browser() {
    if [ "$INSTALL_TOR_BROWSER" != "true" ]; then
        print_info "Skipping Tor Browser installation"
        return
    fi
    
    print_header "Installing Tor Browser"
    
    local install_dir="${HOME}/.tor-browser"
    
    if [ "$OS" == "termux" ]; then
        print_info "Tor Browser not available for Termux, using Tor service instead"
        return
    fi
    
    # Download Tor Browser
    local tor_version="13.0"
    local arch=$(uname -m)
    
    if [ "$arch" == "x86_64" ]; then
        local tor_url="https://www.torproject.org/dist/torbrowser/${tor_version}/tor-browser-linux64-${tor_version}_en-US.tar.xz"
    else
        print_info "Tor Browser not available for $arch architecture"
        return
    fi
    
    mkdir -p "$install_dir"
    cd "$install_dir"
    
    print_info "Downloading Tor Browser..."
    curl -fsSL "$tor_url" -o tor-browser.tar.xz
    
    print_info "Extracting..."
    tar -xf tor-browser.tar.xz
    rm tor-browser.tar.xz
    
    # Create launcher script
    cat > "${HOME}/bin/tor-browser" << EOF
#!/bin/bash
cd "${install_dir}/tor-browser"
./start-tor-browser.desktop &
EOF
    chmod +x "${HOME}/bin/tor-browser"
    
    print_success "Tor Browser installed (run: tor-browser)"
}

# Install VPN tools
install_vpn_tools() {
    if [ "$INSTALL_VPN" != "true" ]; then
        print_info "Skipping VPN tools installation"
        return
    fi
    
    print_header "Installing VPN Tools"
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get install -y openvpn wireguard-tools
            ;;
        centos|rhel|fedora)
            sudo dnf install -y openvpn wireguard-tools
            ;;
        termux)
            pkg install -y openvpn wireguard-tools
            ;;
        *)
            print_error "Unsupported OS for VPN tools"
            return
            ;;
    esac
    
    # Create VPN helper scripts
    cat > "${HOME}/bin/vpn-connect" << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: vpn-connect <config.ovpn>"
    exit 1
fi

sudo openvpn --config "$1" --daemon
echo "VPN connecting..."
EOF
    chmod +x "${HOME}/bin/vpn-connect"
    
    cat > "${HOME}/bin/vpn-disconnect" << 'EOF'
#!/bin/bash
sudo pkill openvpn
echo "VPN disconnected"
EOF
    chmod +x "${HOME}/bin/vpn-disconnect"
    
    print_success "VPN tools installed"
}

# Install privacy tools
install_privacy_tools() {
    if [ "$INSTALL_PRIVACY_TOOLS" != "true" ]; then
        print_info "Skipping privacy tools installation"
        return
    fi
    
    print_header "Installing Privacy Tools"
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get install -y \
                privoxy \
                proxychains4 \
                dnscrypt-proxy \
                nmap \
                tcpdump \
                wireshark-common
            ;;
        centos|rhel|fedora)
            sudo dnf install -y \
                privoxy \
                proxychains-ng \
                dnscrypt-proxy \
                nmap \
                tcpdump \
                wireshark
            ;;
        termux)
            pkg install -y \
                privoxy \
                proxychains-ng \
                nmap \
                tcpdump
            ;;
    esac
    
    # Configure Proxychains
    if [ -f /etc/proxychains4.conf ]; then
        sudo sed -i 's/^strict_chain/#strict_chain/' /etc/proxychains4.conf
        sudo sed -i 's/^#dynamic_chain/dynamic_chain/' /etc/proxychains4.conf
    fi
    
    print_success "Privacy tools installed"
}

# Install DNS encryption
install_dns_encryption() {
    print_header "Installing DNS Encryption"
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get install -y dnscrypt-proxy
            ;;
        centos|rhel|fedora)
            sudo dnf install -y dnscrypt-proxy
            ;;
        termux)
            print_info "DNS encryption via Tor in Termux"
            return
            ;;
    esac
    
    # Configure DNSCrypt
    if [ -f /etc/dnscrypt-proxy/dnscrypt-proxy.toml ]; then
        sudo tee /etc/dnscrypt-proxy/dnscrypt-proxy.toml > /dev/null << 'EOF'
server_names = ['cloudflare', 'google']
listen_addresses = ['127.0.0.1:53']
max_clients = 250
ipv4_servers = true
ipv6_servers = false
dnscrypt_servers = true
doh_servers = true
require_dnssec = true
require_nolog = true
require_nofilter = true
EOF
        
        sudo systemctl enable dnscrypt-proxy
        sudo systemctl start dnscrypt-proxy
    fi
    
    print_success "DNS encryption configured"
}

# Create network helper scripts
create_network_helpers() {
    print_header "Creating Network Helper Scripts"
    
    # Proxy setup script
    cat > "${HOME}/bin/proxy-setup" << 'EOF'
#!/bin/bash
echo "Setting up proxy..."

# Set environment variables
export http_proxy="socks5://127.0.0.1:9050"
export https_proxy="socks5://127.0.0.1:9050"
export HTTP_PROXY="socks5://127.0.0.1:9050"
export HTTPS_PROXY="socks5://127.0.0.1:9050"

# Add to shell config
if ! grep -q "http_proxy=socks5" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOFRC'
# Tor proxy
export http_proxy="socks5://127.0.0.1:9050"
export https_proxy="socks5://127.0.0.1:9050"
EOFRC
fi

echo "Proxy configured for Tor"
echo "Test: curl --proxy socks5h://127.0.0.1:9050 https://check.torproject.org"
EOF
    chmod +x "${HOME}/bin/proxy-setup"
    
    # Network status script
    cat > "${HOME}/bin/net-status" << 'EOF'
#!/bin/bash
echo "=== Network Status ==="
echo

# Check Tor
if pgrep -x "tor" > /dev/null; then
    echo "✓ Tor: Running on 127.0.0.1:9050"
else
    echo "✗ Tor: Not running"
fi

# Check VPN
if pgrep -x "openvpn" > /dev/null; then
    echo "✓ VPN: Connected"
else
    echo "✗ VPN: Not connected"
fi

# Check DNS
echo
echo "DNS Servers:"
if [ -f /etc/resolv.conf ]; then
    grep nameserver /etc/resolv.conf
fi

# Check public IP
echo
echo "Public IP:"
curl -s https://api.ipify.org 2>/dev/null || echo "Cannot detect"

# Check Tor connection
if command -v tor &> /dev/null; then
    echo
    echo "Tor Status:"
    curl --proxy socks5h://127.0.0.1:9050 -s https://check.torproject.org/api/ip | grep -q "true" && echo "✓ Using Tor" || echo "✗ Not using Tor"
fi
EOF
    chmod +x "${HOME}/bin/net-status"
    
    # DNS leak test
    cat > "${HOME}/bin/dns-leak-test" << 'EOF'
#!/bin/bash
echo "Testing for DNS leaks..."
echo

# Standard DNS
echo "Standard DNS query:"
dig +short myip.opendns.com @resolver1.opendns.com

# Tor DNS
if pgrep -x "tor" > /dev/null; then
    echo
    echo "Through Tor:"
    torify dig +short myip.opendns.com @resolver1.opendns.com
fi
EOF
    chmod +x "${HOME}/bin/dns-leak-test"
    
    print_success "Network helper scripts created"
}

# Configure firewall rules
configure_firewall() {
    print_header "Configuring Firewall"
    
    if [ "$OS" == "termux" ]; then
        print_info "Firewall configuration not applicable for Termux"
        return
    fi
    
    # Create firewall script
    cat > "${HOME}/bin/firewall-setup" << 'EOF'
#!/bin/bash
# Privacy-focused firewall rules

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Flush existing rules
iptables -F
iptables -X

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow Tor
iptables -A OUTPUT -p tcp --dport 9050 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 9051 -j ACCEPT

# Allow DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow HTTPS (for Tor downloads)
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

echo "Firewall configured for privacy"
EOF
    chmod +x "${HOME}/bin/firewall-setup"
    
    print_success "Firewall script created (run: sudo firewall-setup)"
}

# Print usage
print_usage() {
    print_header "Privacy Tools Installation Complete!"
    
    echo
    echo -e "${GREEN}Available Commands:${NC}"
    echo -e "  ${CYAN}tor-browser${NC}          - Launch Tor Browser"
    echo -e "  ${CYAN}vpn-connect <config>${NC} - Connect to VPN"
    echo -e "  ${CYAN}vpn-disconnect${NC}       - Disconnect VPN"
    echo -e "  ${CYAN}proxy-setup${NC}          - Configure Tor proxy"
    echo -e "  ${CYAN}net-status${NC}           - Check network status"
    echo -e "  ${CYAN}dns-leak-test${NC}        - Test for DNS leaks"
    echo -e "  ${CYAN}firewall-setup${NC}       - Configure privacy firewall"
    echo
    echo -e "${GREEN}Tor Service:${NC}"
    echo -e "  SOCKS proxy: 127.0.0.1:9050"
    echo -e "  Control port: 127.0.0.1:9051"
    echo -e "  DNS port: 127.0.0.1:5353"
    echo
    echo -e "${GREEN}Examples:${NC}"
    echo -e "  curl --proxy socks5h://127.0.0.1:9050 https://check.torproject.org"
    echo -e "  proxychains4 curl https://api.ipify.org"
    echo -e "  torify wget https://example.com"
    echo
}

# Main installation
main() {
    print_header "Privacy & Networking Tools Setup"
    echo -e "${MAGENTA}Author: Alexander Mathey (xyalaxxx90@gmail.com)${NC}"
    echo -e "${MAGENTA}Copyright: Elektronikx-Center-Matte ® ™${NC}"
    echo
    
    mkdir -p "${HOME}/bin"
    export PATH="${HOME}/bin:$PATH"
    
    detect_os
    print_info "Detected OS: $OS"
    
    install_tor_service
    install_tor_browser
    install_vpn_tools
    install_privacy_tools
    install_dns_encryption
    create_network_helpers
    configure_firewall
    print_usage
    
    print_success "Privacy tools setup complete!"
}

main "$@"
