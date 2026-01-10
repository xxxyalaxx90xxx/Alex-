#!/bin/bash

#################################################################################
# Windows WSL Kubernetes Setup Script
#
# This script provides WSL2 optimized setup for running Kubernetes on Windows:
# - WSL2 configuration and optimization
# - K3s installation with Windows integration
# - Windows/WSL file sharing setup
# - Performance tuning for WSL2
# - Optional GUI support (WSLg)
#################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
INFO="${BLUE}ℹ${NC}"
WARN="${YELLOW}⚠${NC}"

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

detect_wsl() {
    log_info "Detecting WSL environment..."
    
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
        log_success "Running in WSL"
        
        # Detect WSL version
        if grep -qi "WSL2" /proc/version 2>/dev/null; then
            WSL_VERSION=2
            log_success "Detected WSL2"
        else
            WSL_VERSION=1
            log_warn "Detected WSL1 - WSL2 is recommended for Kubernetes"
        fi
    else
        IS_WSL=false
        log_error "Not running in WSL environment"
        exit 1
    fi
    
    # Detect Windows username (more reliable method)
    if [[ -d "/mnt/c/Users" ]]; then
        # Try to get Windows username from WSL environment
        WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        
        # Fallback to directory listing if cmd.exe fails
        if [[ -z "$WIN_USER" ]] || [[ "$WIN_USER" == "%USERNAME%" ]]; then
            WIN_USER=$(ls -t /mnt/c/Users | grep -v "Public\|Default\|All Users" | head -1)
        fi
        
        log_info "Windows user: $WIN_USER"
    fi
}

configure_wsl() {
    log_info "Configuring WSL2..."
    
    # Create .wslconfig in Windows user directory
    local WSLCONFIG="/mnt/c/Users/$WIN_USER/.wslconfig"
    
    if [[ -f "$WSLCONFIG" ]]; then
        log_warn ".wslconfig already exists, backing up..."
        cp "$WSLCONFIG" "${WSLCONFIG}.backup"
    fi
    
    log_info "Creating optimized .wslconfig..."
    
    cat > "$WSLCONFIG" << 'EOF'
[wsl2]
# Memory allocation (50% of total RAM or 8GB, whichever is less)
memory=8GB

# Processors (all logical processors)
processors=8

# Swap size
swap=4GB

# Kernel parameters for Kubernetes
kernelCommandLine = systemd.unified_cgroup_hierarchy=1 cgroup_no_v1=all

# Enable systemd
[boot]
systemd=true

# Network settings
[network]
generateResolvConf=true
EOF
    
    log_success ".wslconfig created at $WSLCONFIG"
    log_warn "Restart WSL for changes to take effect: wsl --shutdown"
}

install_systemd_support() {
    log_info "Enabling systemd support..."
    
    if [[ -f /etc/wsl.conf ]]; then
        if grep -q "\[boot\]" /etc/wsl.conf; then
            log_warn "/etc/wsl.conf already has [boot] section"
        else
            echo "" >> /etc/wsl.conf
            echo "[boot]" >> /etc/wsl.conf
            echo "systemd=true" >> /etc/wsl.conf
            log_success "Systemd enabled in /etc/wsl.conf"
        fi
    else
        cat > /etc/wsl.conf << 'EOF'
[boot]
systemd=true

[network]
generateResolvConf=true

[interop]
enabled=true
appendWindowsPath=true
EOF
        log_success "Created /etc/wsl.conf with systemd support"
    fi
}

optimize_wsl_performance() {
    log_info "Applying WSL2 performance optimizations..."
    
    # Increase file descriptor limits
    cat >> /etc/security/limits.conf << 'EOF' 2>/dev/null || true
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF
    
    # Optimize network settings
    cat >> /etc/sysctl.conf << 'EOF' 2>/dev/null || true
# WSL2 Kubernetes optimizations
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
EOF
    
    # Apply sysctl settings
    sysctl -p /etc/sysctl.conf 2>/dev/null || log_warn "Could not apply sysctl settings (need root)"
    
    log_success "Performance optimizations applied"
}

setup_windows_integration() {
    log_info "Setting up Windows integration..."
    
    # Create directory for Windows scripts
    local WIN_SCRIPTS="/mnt/c/Users/$WIN_USER/.kube-scripts"
    mkdir -p "$WIN_SCRIPTS"
    
    # Create PowerShell script to access K3s from Windows
    cat > "$WIN_SCRIPTS/kubectl.ps1" << 'EOF'
# PowerShell script to run kubectl in WSL
wsl bash -c "kubectl $args"
EOF
    
    # Create batch file for easier access
    cat > "$WIN_SCRIPTS/kubectl.bat" << 'EOF'
@echo off
wsl bash -c "kubectl %*"
EOF
    
    log_success "Windows integration scripts created in $WIN_SCRIPTS"
    log_info "Add $WIN_SCRIPTS to Windows PATH to use kubectl from Windows"
}

install_k3s_wsl() {
    log_info "Installing K3s for WSL2..."
    
    # Check if install_k8s_optimized.sh exists
    if [[ -f "./install_k8s_optimized.sh" ]]; then
        log_info "Running optimized K3s installation..."
        INSTALL_MODE=lightweight bash ./install_k8s_optimized.sh
    else
        log_info "Installing K3s directly..."
        
        # Install K3s with WSL-specific settings
        curl -sfL https://get.k3s.io | sh -s - \
            --write-kubeconfig-mode 644 \
            --disable traefik \
            --disable servicelb \
            --flannel-backend=host-gw
        
        # Wait for K3s to be ready
        log_info "Waiting for K3s to be ready..."
        sleep 10
        
        # Verify installation
        if systemctl is-active --quiet k3s; then
            log_success "K3s installed and running"
        else
            log_error "K3s installation failed"
            return 1
        fi
    fi
    
    # Copy kubeconfig to Windows user directory
    local WIN_KUBE="/mnt/c/Users/$WIN_USER/.kube"
    mkdir -p "$WIN_KUBE"
    
    if [[ -f /etc/rancher/k3s/k3s.yaml ]]; then
        cp /etc/rancher/k3s/k3s.yaml "$WIN_KUBE/config"
        chmod 644 "$WIN_KUBE/config"
        log_success "Kubeconfig copied to Windows: $WIN_KUBE/config"
    fi
}

create_wsl_helpers() {
    log_info "Creating WSL helper scripts..."
    
    # Create script to start K3s
    cat > /usr/local/bin/start-k3s << 'EOF'
#!/bin/bash
echo "Starting K3s..."
sudo systemctl start k3s
sleep 5
sudo systemctl status k3s
EOF
    chmod +x /usr/local/bin/start-k3s
    
    # Create script to stop K3s
    cat > /usr/local/bin/stop-k3s << 'EOF'
#!/bin/bash
echo "Stopping K3s..."
sudo systemctl stop k3s
EOF
    chmod +x /usr/local/bin/stop-k3s
    
    # Create script to restart K3s
    cat > /usr/local/bin/restart-k3s << 'EOF'
#!/bin/bash
echo "Restarting K3s..."
sudo systemctl restart k3s
sleep 5
sudo systemctl status k3s
EOF
    chmod +x /usr/local/bin/restart-k3s
    
    log_success "Helper scripts created: start-k3s, stop-k3s, restart-k3s"
}

print_wsl_summary() {
    log ""
    log "${GREEN}========================================${NC}"
    log "${GREEN}WSL2 Kubernetes Setup Complete!${NC}"
    log "${GREEN}========================================${NC}"
    log ""
    log "${BLUE}WSL Version: $WSL_VERSION${NC}"
    log "${BLUE}Windows User: $WIN_USER${NC}"
    log ""
    log "${YELLOW}Next Steps:${NC}"
    log ""
    log "  ${WARN} ${RED}IMPORTANT: Restart WSL${NC}"
    log "     Run in PowerShell (as Administrator):"
    log "     ${GREEN}wsl --shutdown${NC}"
    log ""
    log "  1. After restart, start K3s:"
    log "     ${GREEN}start-k3s${NC}"
    log ""
    log "  2. Verify installation:"
    log "     ${GREEN}kubectl get nodes${NC}"
    log ""
    log "  3. Access from Windows:"
    log "     Add to PATH: ${BLUE}C:\\Users\\$WIN_USER\\.kube-scripts${NC}"
    log "     Then use: ${GREEN}kubectl.bat get nodes${NC}"
    log ""
    log "${BLUE}Files Created:${NC}"
    log "  - Windows .wslconfig: ${BLUE}/mnt/c/Users/$WIN_USER/.wslconfig${NC}"
    log "  - WSL config: ${BLUE}/etc/wsl.conf${NC}"
    log "  - Windows scripts: ${BLUE}/mnt/c/Users/$WIN_USER/.kube-scripts/${NC}"
    log "  - Kubeconfig: ${BLUE}/mnt/c/Users/$WIN_USER/.kube/config${NC}"
    log ""
    log "${YELLOW}Useful Commands:${NC}"
    log "  - Start K3s: ${GREEN}start-k3s${NC}"
    log "  - Stop K3s: ${GREEN}stop-k3s${NC}"
    log "  - Restart K3s: ${GREEN}restart-k3s${NC}"
    log "  - Check status: ${GREEN}systemctl status k3s${NC}"
    log ""
}

main() {
    log "${BLUE}========================================${NC}"
    log "${BLUE}Windows WSL2 Kubernetes Setup${NC}"
    log "${BLUE}========================================${NC}"
    log ""
    
    detect_wsl
    
    if [[ "$WSL_VERSION" -ne 2 ]]; then
        log_error "WSL2 is required. Please upgrade to WSL2."
        log_info "Run in PowerShell: wsl --set-version <distro> 2"
        exit 1
    fi
    
    configure_wsl
    
    if [[ "$EUID" -eq 0 ]]; then
        install_systemd_support
        optimize_wsl_performance
    else
        log_warn "Some configurations require root access. Run with sudo for full setup."
    fi
    
    setup_windows_integration
    create_wsl_helpers
    
    if [[ "${INSTALL_K3S:-true}" == "true" ]]; then
        if [[ "$EUID" -eq 0 ]]; then
            install_k3s_wsl
        else
            log_warn "K3s installation requires root. Run with sudo to install K3s."
        fi
    fi
    
    print_wsl_summary
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-k3s)
            INSTALL_K3S=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-k3s    Skip K3s installation"
            echo "  --help        Show this help message"
            echo ""
            echo "Note: Run with sudo for full installation"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

main
