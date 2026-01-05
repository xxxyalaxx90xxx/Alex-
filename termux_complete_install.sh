#!/data/data/com.termux/files/usr/bin/bash

# Complete Termux Installation for Realme C63 (RMX3939)
# One-command automated setup with all features
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
INSTALL_ALL="${INSTALL_ALL:-true}"
INSTALL_DATABASES="${INSTALL_DATABASES:-true}"
INSTALL_K3S="${INSTALL_K3S:-true}"
INSTALL_DEV_TOOLS="${INSTALL_DEV_TOOLS:-true}"
INSTALL_NETWORKING="${INSTALL_NETWORKING:-true}"
ENABLE_TOR="${ENABLE_TOR:-false}"

LOG_FILE="${HOME}/termux_install_$(date +%Y%m%d_%H%M%S).log"

# Progress tracking
TOTAL_STEPS=12
CURRENT_STEP=0

# Print functions
print_header() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${CYAN} $1${BLUE}$(printf '%*s' $((57 - ${#1})) '')║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo -e "${GREEN}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} ${CYAN}▶${NC} $1 ${YELLOW}(${percent}%)${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Update packages
update_packages() {
    print_step "Updating package repositories"
    log "Updating packages"
    
    pkg update -y 2>&1 | tee -a "$LOG_FILE"
    pkg upgrade -y 2>&1 | tee -a "$LOG_FILE"
    
    print_success "Packages updated"
}

# Setup storage
setup_storage() {
    print_step "Setting up storage access"
    log "Setting up storage"
    
    if [ ! -d "$HOME/storage" ]; then
        termux-setup-storage
        sleep 2
    fi
    
    print_success "Storage configured"
}

# Install essential packages
install_essentials() {
    print_step "Installing essential packages"
    log "Installing essentials"
    
    local packages=(
        "proot-distro"
        "wget"
        "curl"
        "git"
        "openssh"
        "python"
        "nodejs"
        "golang"
        "rust"
        "binutils"
        "clang"
        "make"
        "cmake"
        "pkg-config"
    )
    
    for pkg_name in "${packages[@]}"; do
        print_success "Installing $pkg_name..."
        pkg install -y "$pkg_name" 2>&1 | tee -a "$LOG_FILE"
    done
    
    print_success "Essential packages installed"
}

# Install proot Linux distribution
install_proot_distro() {
    print_step "Installing proot Linux distribution"
    log "Installing proot distro"
    
    local distro="${LINUX_DISTRO:-ubuntu}"
    
    if ! proot-distro list | grep -q "installed.*${distro}"; then
        print_success "Installing ${distro}..."
        proot-distro install "$distro" 2>&1 | tee -a "$LOG_FILE"
    else
        print_success "${distro} already installed"
    fi
    
    # Create launch script
    cat > "$HOME/bin/linux" << EOF
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ${distro}
EOF
    chmod +x "$HOME/bin/linux"
    
    print_success "Proot Linux ready (run: linux)"
}

# Install databases
install_databases() {
    if [ "$INSTALL_DATABASES" != "true" ]; then
        print_warning "Skipping database installation"
        return
    fi
    
    print_step "Installing databases"
    log "Installing databases"
    
    # PostgreSQL
    print_success "Installing PostgreSQL..."
    pkg install -y postgresql 2>&1 | tee -a "$LOG_FILE"
    
    if [ ! -d "$PREFIX/var/lib/postgresql" ]; then
        mkdir -p "$PREFIX/var/lib/postgresql"
        initdb "$PREFIX/var/lib/postgresql"
    fi
    
    # MariaDB
    print_success "Installing MariaDB..."
    pkg install -y mariadb 2>&1 | tee -a "$LOG_FILE"
    
    # Redis
    print_success "Installing Redis..."
    pkg install -y redis 2>&1 | tee -a "$LOG_FILE"
    
    # MongoDB (via proot)
    print_success "MongoDB will be available in proot Linux"
    
    # Create database startup scripts
    cat > "$HOME/bin/db-start" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Starting databases..."
pg_ctl -D $PREFIX/var/lib/postgresql start
mysqld_safe --datadir=$PREFIX/var/lib/mysql &
redis-server &
echo "Databases started"
EOF
    chmod +x "$HOME/bin/db-start"
    
    cat > "$HOME/bin/db-stop" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Stopping databases..."
pg_ctl -D $PREFIX/var/lib/postgresql stop
pkill mysqld
pkill redis-server
echo "Databases stopped"
EOF
    chmod +x "$HOME/bin/db-stop"
    
    print_success "Databases installed (start: db-start, stop: db-stop)"
}

# Install K3s
install_k3s() {
    if [ "$INSTALL_K3S" != "true" ]; then
        print_warning "Skipping K3s installation"
        return
    fi
    
    print_step "Installing K3s Kubernetes"
    log "Installing K3s"
    
    # Install in proot
    print_success "K3s will be installed in proot Linux..."
    
    cat > "$HOME/bin/k3s-setup" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu -- bash -c '
apt-get update
apt-get install -y curl
curl -sfL https://get.k3s.io | sh -
'
echo "K3s installed in proot Linux"
EOF
    chmod +x "$HOME/bin/k3s-setup"
    
    print_success "K3s setup script created (run: k3s-setup)"
}

# Install development tools
install_dev_tools() {
    if [ "$INSTALL_DEV_TOOLS" != "true" ]; then
        print_warning "Skipping development tools"
        return
    fi
    
    print_step "Installing development tools"
    log "Installing dev tools"
    
    # code-server (VS Code for browser)
    print_success "Installing code-server..."
    npm install -g code-server 2>&1 | tee -a "$LOG_FILE"
    
    # Python packages
    print_success "Installing Python packages..."
    pip install --upgrade pip
    pip install jupyter numpy pandas matplotlib seaborn scikit-learn
    
    # Android tools
    print_success "Installing Android tools..."
    pkg install -y aapt apksigner 2>&1 | tee -a "$LOG_FILE"
    
    print_success "Development tools installed"
}

# Install networking tools
install_networking() {
    if [ "$INSTALL_NETWORKING" != "true" ]; then
        print_warning "Skipping networking tools"
        return
    fi
    
    print_step "Installing networking tools"
    log "Installing networking tools"
    
    local net_packages=(
        "nmap"
        "netcat-openbsd"
        "dnsutils"
        "traceroute"
        "iproute2"
        "net-tools"
    )
    
    for pkg_name in "${net_packages[@]}"; do
        pkg install -y "$pkg_name" 2>&1 | tee -a "$LOG_FILE"
    done
    
    if [ "$ENABLE_TOR" == "true" ]; then
        print_success "Installing Tor..."
        pkg install -y tor 2>&1 | tee -a "$LOG_FILE"
        
        cat > "$HOME/bin/tor-start" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
tor &
echo "Tor started on 127.0.0.1:9050"
EOF
        chmod +x "$HOME/bin/tor-start"
    fi
    
    print_success "Networking tools installed"
}

# Configure environment
configure_environment() {
    print_step "Configuring environment"
    log "Configuring environment"
    
    # Create bin directory
    mkdir -p "$HOME/bin"
    
    # Update .bashrc
    if ! grep -q "export PATH=\$HOME/bin:\$PATH" "$HOME/.bashrc"; then
        echo 'export PATH=$HOME/bin:$PATH' >> "$HOME/.bashrc"
    fi
    
    # Add aliases
    cat >> "$HOME/.bashrc" << 'EOF'

# Kubernetes aliases
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'

# Termux aliases
alias linux='proot-distro login ubuntu'
alias update='pkg update && pkg upgrade'
EOF
    
    print_success "Environment configured"
}

# Create helper scripts
create_helpers() {
    print_step "Creating helper scripts"
    log "Creating helpers"
    
    # System info script
    cat > "$HOME/bin/sys-info" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "=== Realme C63 System Information ==="
echo "Device: $(getprop ro.product.model)"
echo "Android: $(getprop ro.build.version.release)"
echo "Kernel: $(uname -r)"
echo "CPU: $(getprop ro.product.cpu.abi)"
echo "RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Storage: $(df -h $HOME | awk 'NR==2 {print $4 " available"}')"
echo
echo "=== Installed Services ==="
pgrep -f postgres > /dev/null && echo "✓ PostgreSQL" || echo "✗ PostgreSQL"
pgrep -f mysql > /dev/null && echo "✓ MySQL" || echo "✗ MySQL"
pgrep -f redis > /dev/null && echo "✓ Redis" || echo "✗ Redis"
pgrep -f tor > /dev/null && echo "✓ Tor" || echo "✗ Tor"
EOF
    chmod +x "$HOME/bin/sys-info"
    
    # Quick start script
    cat > "$HOME/bin/quick-start" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Starting services..."
db-start
[ -f "$HOME/bin/tor-start" ] && tor-start
echo "Services started!"
echo "Run 'sys-info' to see status"
EOF
    chmod +x "$HOME/bin/quick-start"
    
    print_success "Helper scripts created"
}

# Optimize for Realme C63
optimize_device() {
    print_step "Optimizing for Realme C63 (RMX3939)"
    log "Device optimization"
    
    # Set resource limits
    cat > "$HOME/.termux_limits" << 'EOF'
# Realme C63 optimizations
export MAX_MEMORY_MB=2048
export MAX_SWAP_MB=1024
export CPU_CORES=8
EOF
    
    if ! grep -q "source ~/.termux_limits" "$HOME/.bashrc"; then
        echo 'source ~/.termux_limits' >> "$HOME/.bashrc"
    fi
    
    print_success "Device optimizations applied"
}

# Post-installation verification
verify_installation() {
    print_step "Verifying installation"
    log "Verification"
    
    local failed=0
    
    # Check essential commands
    for cmd in git python node; do
        if command -v "$cmd" &> /dev/null; then
            print_success "$cmd: OK"
        else
            print_error "$cmd: FAILED"
            failed=$((failed + 1))
        fi
    done
    
    # Check proot
    if proot-distro list | grep -q "installed"; then
        print_success "Proot Linux: OK"
    else
        print_warning "Proot Linux: Not installed"
    fi
    
    if [ $failed -eq 0 ]; then
        print_success "All verifications passed!"
    else
        print_warning "$failed checks failed"
    fi
}

# Print completion message
print_completion() {
    print_header "Installation Complete!"
    
    echo
    echo -e "${GREEN}✓ Termux Complete Setup Finished${NC}"
    echo
    echo -e "${CYAN}Quick Start Commands:${NC}"
    echo -e "  ${YELLOW}quick-start${NC}      - Start all services"
    echo -e "  ${YELLOW}sys-info${NC}         - Show system information"
    echo -e "  ${YELLOW}linux${NC}            - Enter proot Linux"
    echo -e "  ${YELLOW}db-start${NC}         - Start databases"
    echo -e "  ${YELLOW}db-stop${NC}          - Stop databases"
    if [ "$ENABLE_TOR" == "true" ]; then
        echo -e "  ${YELLOW}tor-start${NC}        - Start Tor service"
    fi
    echo
    echo -e "${CYAN}Installation Log:${NC} $LOG_FILE"
    echo
    echo -e "${MAGENTA}Author: Alexander Mathey (xyalaxxx90@gmail.com)${NC}"
    echo -e "${MAGENTA}Copyright: Elektronikx-Center-Matte ® ™${NC}"
    echo
}

# Main installation
main() {
    print_header "Termux Complete Installation for Realme C63"
    echo -e "${MAGENTA}RMX3939 Automatic Setup${NC}"
    echo
    
    log "Installation started"
    
    update_packages
    setup_storage
    install_essentials
    install_proot_distro
    install_databases
    install_k3s
    install_dev_tools
    install_networking
    configure_environment
    create_helpers
    optimize_device
    verify_installation
    
    log "Installation completed"
    
    print_completion
}

main "$@"
