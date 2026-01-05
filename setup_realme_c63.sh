#!/bin/bash

#################################################################################
# Realme C63 (RMX3939) Complete Setup Script
# 
# This script provides comprehensive setup for Realme C63 devices including:
# - Termux environment optimization
# - Proot Linux distribution installation
# - K3s lightweight Kubernetes
# - Database installations (PostgreSQL, MySQL, MongoDB, Redis)
# - Performance tuning specific to Realme C63
#
# Device: Realme C63 (RMX3939)
# CPU: Unisoc T612 (Octa-core)
# RAM: 4GB/6GB/8GB variants
# Architecture: ARM64 (aarch64)
#################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Symbols
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
INFO="${BLUE}ℹ${NC}"
WARN="${YELLOW}⚠${NC}"

# Configuration
DEVICE_MODEL="Realme C63 (RMX3939)"
TERMUX_PACKAGES_BASE="proot-distro wget curl git openssh"
TERMUX_PACKAGES_DEV="python nodejs rust golang"
TERMUX_PACKAGES_DB="postgresql mariadb redis"
DISTRO="${REALME_LINUX_DISTRO:-ubuntu}"

log() {
    echo -e "${1}"
}

log_info() {
    log "${INFO} ${1}"
}

log_success() {
    log "${CHECK} ${1}"
}

log_error() {
    log "${CROSS} ${1}"
}

log_warn() {
    log "${WARN} ${1}"
}

detect_environment() {
    log_info "Detecting environment..."
    
    # Check if running in Termux
    if [[ -n "$TERMUX_VERSION" ]] || [[ -d "/data/data/com.termux" ]]; then
        ENV_TYPE="termux"
        log_success "Detected Termux environment"
    # Check if running in proot
    elif [[ -n "$PROOT_TMP_DIR" ]] || grep -q "proot" /proc/1/cmdline 2>/dev/null; then
        ENV_TYPE="proot"
        log_success "Detected proot Linux environment"
    # Check if running on Linux
    elif [[ "$(uname -s)" == "Linux" ]]; then
        ENV_TYPE="linux"
        log_success "Detected native Linux environment"
    else
        ENV_TYPE="unknown"
        log_warn "Unknown environment"
    fi
    
    # Detect device model
    if [[ -f /proc/cpuinfo ]]; then
        CPU_INFO=$(cat /proc/cpuinfo | grep -i "Hardware" | head -1 | cut -d: -f2 | xargs)
        if [[ -n "$CPU_INFO" ]]; then
            log_info "CPU: $CPU_INFO"
        fi
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    log_info "Architecture: $ARCH"
    
    # Detect RAM
    if [[ -f /proc/meminfo ]]; then
        TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
        log_info "RAM: ${TOTAL_RAM_GB}GB"
    fi
}

setup_termux_base() {
    log_info "Setting up Termux base environment..."
    
    if [[ "$ENV_TYPE" != "termux" ]]; then
        log_warn "Not running in Termux, skipping Termux setup"
        return
    fi
    
    # Update package lists
    log_info "Updating package lists..."
    pkg update -y || apt update -y
    
    # Upgrade existing packages
    log_info "Upgrading packages..."
    pkg upgrade -y || apt upgrade -y
    
    # Install base packages
    log_info "Installing base packages..."
    for package in $TERMUX_PACKAGES_BASE; do
        log_info "Installing $package..."
        pkg install -y "$package" 2>/dev/null || apt install -y "$package" 2>/dev/null || log_warn "Failed to install $package"
    done
    
    # Setup storage access
    if command -v termux-setup-storage &> /dev/null; then
        log_info "Setting up storage access..."
        termux-setup-storage || log_warn "Storage setup failed or already configured"
    fi
    
    log_success "Termux base environment setup complete"
}

setup_proot_distro() {
    log_info "Setting up proot Linux distribution..."
    
    if [[ "$ENV_TYPE" != "termux" ]]; then
        log_warn "Not running in Termux, cannot setup proot distribution"
        return
    fi
    
    if ! command -v proot-distro &> /dev/null; then
        log_error "proot-distro not found. Installing..."
        pkg install -y proot-distro
    fi
    
    # List available distributions
    log_info "Available distributions:"
    proot-distro list
    
    # Install selected distribution
    log_info "Installing $DISTRO distribution..."
    proot-distro install "$DISTRO" || log_error "Failed to install $DISTRO"
    
    log_success "Proot distribution setup complete"
    log_info "To enter the distribution, run: proot-distro login $DISTRO"
}

optimize_realme_c63() {
    log_info "Applying Realme C63 (RMX3939) specific optimizations..."
    
    # Create optimization script
    cat > /tmp/realme_c63_optimize.sh << 'EOF'
#!/bin/bash

# Realme C63 Performance Optimizations

# 1. Reduce swappiness (better for low RAM devices)
if [[ -w /proc/sys/vm/swappiness ]]; then
    echo 10 > /proc/sys/vm/swappiness
    echo "Swappiness set to 10"
fi

# 2. Increase file descriptor limits
ulimit -n 65536 2>/dev/null || echo "Could not set file descriptor limit"

# 3. Optimize for low latency
if [[ -w /proc/sys/vm/dirty_ratio ]]; then
    echo 10 > /proc/sys/vm/dirty_ratio
    echo 5 > /proc/sys/vm/dirty_background_ratio
fi

# 4. Disable unnecessary services in Termux
if [[ -n "$TERMUX_VERSION" ]]; then
    # Termux-specific optimizations
    export TMPDIR=$PREFIX/tmp
    mkdir -p $TMPDIR
fi

echo "Realme C63 optimizations applied"
EOF
    
    chmod +x /tmp/realme_c63_optimize.sh
    
    if [[ "$EUID" -eq 0 ]] || [[ -n "$TERMUX_VERSION" ]]; then
        bash /tmp/realme_c63_optimize.sh
        log_success "Realme C63 optimizations applied"
    else
        log_warn "Root access needed for system optimizations. Run with sudo."
    fi
}

install_databases() {
    log_info "Installing database systems..."
    
    local INSTALL_CMD=""
    
    if [[ "$ENV_TYPE" == "termux" ]]; then
        INSTALL_CMD="pkg install -y"
    elif command -v apt &> /dev/null; then
        INSTALL_CMD="apt install -y"
    elif command -v yum &> /dev/null; then
        INSTALL_CMD="yum install -y"
    else
        log_error "No package manager found"
        return 1
    fi
    
    # PostgreSQL
    if [[ "${INSTALL_POSTGRESQL:-true}" == "true" ]]; then
        log_info "Installing PostgreSQL..."
        $INSTALL_CMD postgresql || log_warn "PostgreSQL installation failed"
        
        if command -v initdb &> /dev/null && [[ "$ENV_TYPE" == "termux" ]]; then
            mkdir -p $PREFIX/var/lib/postgresql
            initdb $PREFIX/var/lib/postgresql 2>/dev/null || log_warn "PostgreSQL already initialized"
        fi
        
        log_success "PostgreSQL installed"
    fi
    
    # MySQL/MariaDB
    if [[ "${INSTALL_MYSQL:-true}" == "true" ]]; then
        log_info "Installing MariaDB (MySQL compatible)..."
        $INSTALL_CMD mariadb || log_warn "MariaDB installation failed"
        log_success "MariaDB installed"
    fi
    
    # Redis
    if [[ "${INSTALL_REDIS:-true}" == "true" ]]; then
        log_info "Installing Redis..."
        $INSTALL_CMD redis || log_warn "Redis installation failed"
        log_success "Redis installed"
    fi
    
    # MongoDB (if available)
    if [[ "${INSTALL_MONGODB:-false}" == "true" ]]; then
        log_info "Installing MongoDB..."
        if [[ "$ENV_TYPE" == "termux" ]]; then
            log_warn "MongoDB not available in Termux, consider using proot distribution"
        else
            $INSTALL_CMD mongodb || log_warn "MongoDB installation failed"
            log_success "MongoDB installed"
        fi
    fi
}

install_dev_tools() {
    log_info "Installing development tools..."
    
    local INSTALL_CMD=""
    
    if [[ "$ENV_TYPE" == "termux" ]]; then
        INSTALL_CMD="pkg install -y"
    elif command -v apt &> /dev/null; then
        INSTALL_CMD="apt install -y"
    elif command -v yum &> /dev/null; then
        INSTALL_CMD="yum install -y"
    else
        log_error "No package manager found"
        return 1
    fi
    
    # Install development packages
    for package in $TERMUX_PACKAGES_DEV; do
        if [[ "${INSTALL_DEV_TOOLS:-true}" == "true" ]]; then
            log_info "Installing $package..."
            $INSTALL_CMD "$package" 2>/dev/null || log_warn "Failed to install $package"
        fi
    done
    
    log_success "Development tools installed"
}

setup_k3s_for_realme() {
    log_info "Setting up K3s for Realme C63..."
    
    if [[ "$ENV_TYPE" == "termux" ]]; then
        log_warn "K3s cannot run directly in Termux. Use proot distribution instead."
        log_info "To setup K3s in proot:"
        log_info "1. proot-distro login $DISTRO"
        log_info "2. Run: ./install_k8s_optimized.sh with INSTALL_MODE=lightweight"
        return
    fi
    
    # Check if install_k8s_optimized.sh exists
    if [[ -f "./install_k8s_optimized.sh" ]]; then
        log_info "Running optimized K3s installation..."
        INSTALL_MODE=lightweight bash ./install_k8s_optimized.sh
    else
        log_warn "install_k8s_optimized.sh not found in current directory"
        log_info "K3s can be installed manually with:"
        log_info "curl -sfL https://get.k3s.io | sh -"
    fi
}

create_startup_script() {
    log_info "Creating startup script..."
    
    local STARTUP_SCRIPT=""
    
    if [[ "$ENV_TYPE" == "termux" ]]; then
        STARTUP_SCRIPT="$HOME/.termux/boot/realme-startup.sh"
        mkdir -p "$HOME/.termux/boot"
    else
        STARTUP_SCRIPT="$HOME/realme-startup.sh"
    fi
    
    cat > "$STARTUP_SCRIPT" << 'EOF'
#!/bin/bash
# Realme C63 Startup Script

echo "Starting Realme C63 optimized environment..."

# Apply performance optimizations
if [[ -f /tmp/realme_c63_optimize.sh ]]; then
    bash /tmp/realme_c63_optimize.sh
fi

# Start databases (if installed)
if command -v redis-server &> /dev/null; then
    redis-server --daemonize yes 2>/dev/null || true
fi

if command -v pg_ctl &> /dev/null && [[ -n "$TERMUX_VERSION" ]]; then
    pg_ctl -D $PREFIX/var/lib/postgresql start 2>/dev/null || true
fi

if command -v mysqld &> /dev/null; then
    mysqld --daemonize 2>/dev/null || true
fi

echo "Realme C63 environment ready!"
EOF
    
    chmod +x "$STARTUP_SCRIPT"
    log_success "Startup script created at: $STARTUP_SCRIPT"
}

print_summary() {
    log ""
    log "${GREEN}========================================${NC}"
    log "${GREEN}Realme C63 Setup Complete!${NC}"
    log "${GREEN}========================================${NC}"
    log ""
    log "${BLUE}Device: $DEVICE_MODEL${NC}"
    log "${BLUE}Environment: $ENV_TYPE${NC}"
    log "${BLUE}Architecture: $ARCH${NC}"
    log ""
    log "${YELLOW}Installed Components:${NC}"
    
    if command -v psql &> /dev/null; then
        log "  ${CHECK} PostgreSQL: $(psql --version | head -1)"
    fi
    
    if command -v mysql &> /dev/null; then
        log "  ${CHECK} MySQL/MariaDB: $(mysql --version | head -1)"
    fi
    
    if command -v redis-server &> /dev/null; then
        log "  ${CHECK} Redis: $(redis-server --version | head -1)"
    fi
    
    if command -v python &> /dev/null; then
        log "  ${CHECK} Python: $(python --version 2>&1)"
    fi
    
    if command -v node &> /dev/null; then
        log "  ${CHECK} Node.js: $(node --version)"
    fi
    
    log ""
    log "${YELLOW}Next Steps:${NC}"
    
    if [[ "$ENV_TYPE" == "termux" ]]; then
        log "  1. Enter proot distribution: ${GREEN}proot-distro login $DISTRO${NC}"
        log "  2. Install K3s: ${GREEN}INSTALL_MODE=lightweight ./install_k8s_optimized.sh${NC}"
        log "  3. Run databases: ${GREEN}bash ~/realme-startup.sh${NC}"
    else
        log "  1. Install K3s: ${GREEN}./install_k8s_optimized.sh${NC}"
        log "  2. Validate cluster: ${GREEN}./validate_k8s.sh${NC}"
        log "  3. Optimize performance: ${GREEN}./optimize_performance.sh${NC}"
    fi
    
    log ""
    log "${BLUE}Documentation:${NC}"
    log "  - Quick Start: QUICKSTART.md"
    log "  - Optimized Installation: OPTIMIZED_INSTALLATION_GUIDE.md"
    log "  - Advanced Guide: ADVANCED_GUIDE.md"
    log ""
}

main() {
    log "${BLUE}========================================${NC}"
    log "${BLUE}Realme C63 (RMX3939) Complete Setup${NC}"
    log "${BLUE}========================================${NC}"
    log ""
    
    detect_environment
    
    case "$ENV_TYPE" in
        termux)
            setup_termux_base
            setup_proot_distro
            ;;
        proot|linux)
            log_info "Running in $ENV_TYPE environment"
            ;;
    esac
    
    optimize_realme_c63
    install_dev_tools
    install_databases
    create_startup_script
    
    if [[ "${INSTALL_K3S:-false}" == "true" ]]; then
        setup_k3s_for_realme
    fi
    
    print_summary
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-k3s)
            INSTALL_K3S=true
            shift
            ;;
        --distro)
            DISTRO="$2"
            shift 2
            ;;
        --skip-databases)
            INSTALL_POSTGRESQL=false
            INSTALL_MYSQL=false
            INSTALL_REDIS=false
            INSTALL_MONGODB=false
            shift
            ;;
        --skip-dev-tools)
            INSTALL_DEV_TOOLS=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --with-k3s           Install K3s Kubernetes"
            echo "  --distro <name>      Specify proot distribution (default: ubuntu)"
            echo "  --skip-databases     Skip database installations"
            echo "  --skip-dev-tools     Skip development tools"
            echo "  --help               Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  INSTALL_POSTGRESQL   Install PostgreSQL (default: true)"
            echo "  INSTALL_MYSQL        Install MySQL/MariaDB (default: true)"
            echo "  INSTALL_REDIS        Install Redis (default: true)"
            echo "  INSTALL_MONGODB      Install MongoDB (default: false)"
            echo "  INSTALL_DEV_TOOLS    Install dev tools (default: true)"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

main
