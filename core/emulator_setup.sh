#!/bin/bash

################################################################################
# Emulator Setup Script v4.0
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Erweiterte Emulator-Konfiguration für XTREME-XAI-ULTIMATE
################################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[EMULATOR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check for virtualization support
check_virtualization() {
    log_info "Checking virtualization support..."
    
    if grep -qE '(vmx|svm)' /proc/cpuinfo 2>/dev/null; then
        log_success "Virtualization support detected (VT-x/AMD-V)"
        return 0
    else
        log_warning "Virtualization support not detected or not enabled in BIOS"
        log_info "This is normal for Android/Termux environments"
        return 1
    fi
}

# Check for KVM
check_kvm() {
    log_info "Checking KVM support..."
    
    if [[ -e /dev/kvm ]]; then
        log_success "KVM is available"
        if [[ -r /dev/kvm ]] && [[ -w /dev/kvm ]]; then
            log_success "KVM is accessible"
        else
            log_warning "KVM exists but not accessible (check permissions)"
        fi
        return 0
    else
        log_info "KVM is not available (normal for Termux)"
        return 1
    fi
}

# Setup QEMU environment
setup_qemu() {
    log_info "Checking QEMU installation..."
    
    if command -v qemu-system-x86_64 &> /dev/null; then
        local qemu_version=$(qemu-system-x86_64 --version | head -n1)
        log_success "QEMU found: $qemu_version"
        
        # Check for QEMU acceleration support
        if qemu-system-x86_64 -accel help 2>/dev/null | grep -q "kvm"; then
            log_success "QEMU KVM acceleration available"
        fi
        
        return 0
    elif command -v qemu-system-aarch64 &> /dev/null; then
        local qemu_version=$(qemu-system-aarch64 --version | head -n1)
        log_success "QEMU ARM found: $qemu_version"
        return 0
    else
        log_warning "QEMU not installed"
        log_info "To install QEMU:"
        log_info "  Termux: pkg install qemu-system-x86-64 qemu-utils"
        log_info "  Ubuntu/Debian: sudo apt-get install qemu-system"
        log_info "  CentOS/RHEL: sudo yum install qemu-kvm"
        log_info "  Arch: sudo pacman -S qemu"
        return 1
    fi
}

# Setup Docker environment
setup_docker() {
    log_info "Checking Docker installation..."
    
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version)
        log_success "Docker found: $docker_version"
        
        # Check if Docker daemon is running
        if docker ps &> /dev/null; then
            log_success "Docker daemon is running"
            
            # Show Docker info
            local containers=$(docker ps -q | wc -l)
            local images=$(docker images -q | wc -l)
            log_info "Active containers: $containers"
            log_info "Available images: $images"
        else
            log_warning "Docker daemon is not running"
            log_info "Start Docker with: sudo systemctl start docker"
            log_info "or: dockerd (if running rootless)"
        fi
        return 0
    else
        log_warning "Docker not installed"
        log_info "To install Docker:"
        log_info "  Visit: https://docs.docker.com/get-docker/"
        log_info "  Termux: Docker is not officially supported"
        return 1
    fi
}

# Setup PRoot/Distro environment for Termux
setup_proot() {
    if command -v termux-info &> /dev/null; then
        log_info "Checking PRoot/Linux distro support..."
        
        if command -v proot &> /dev/null; then
            log_success "PRoot is available"
            
            # Check for proot-distro
            if command -v proot-distro &> /dev/null; then
                log_success "proot-distro is available"
                
                # List installed distros
                local distros=$(proot-distro list 2>/dev/null | grep -c "installed")
                if [[ $distros -gt 0 ]]; then
                    log_info "Installed distros: $distros"
                    proot-distro list | grep "installed" | awk '{print "  - " $1}'
                else
                    log_info "No distros installed yet"
                    log_info "Install with: proot-distro install ubuntu"
                fi
            else
                log_info "proot-distro not installed"
                log_info "Install with: pkg install proot-distro"
            fi
            return 0
        else
            log_warning "PRoot not installed"
            log_info "Install with: pkg install proot"
            return 1
        fi
    fi
}

# Setup Android emulator environment
setup_android_emulator() {
    log_info "Checking Android SDK/Emulator..."
    
    # Check for Android SDK
    if [[ -n "$ANDROID_HOME" ]] && [[ -d "$ANDROID_HOME" ]]; then
        log_success "Android SDK found at: $ANDROID_HOME"
        
        # Check for emulator
        if [[ -f "$ANDROID_HOME/emulator/emulator" ]]; then
            log_success "Android emulator found"
            
            # List available AVDs
            if [[ -f "$ANDROID_HOME/emulator/emulator" ]]; then
                local avd_count=$("$ANDROID_HOME/emulator/emulator" -list-avds 2>/dev/null | wc -l)
                if [[ $avd_count -gt 0 ]]; then
                    log_info "Available AVDs: $avd_count"
                else
                    log_info "No AVDs configured"
                fi
            fi
            return 0
        else
            log_warning "Android emulator not found in SDK"
            return 1
        fi
    elif [[ -d "$HOME/Android/Sdk" ]]; then
        log_success "Android SDK found at: $HOME/Android/Sdk"
        export ANDROID_HOME="$HOME/Android/Sdk"
        log_info "Set ANDROID_HOME=$ANDROID_HOME"
        return 0
    else
        log_warning "ANDROID_HOME not set or Android SDK not found"
        log_info "To setup Android SDK:"
        log_info "  1. Download Android Studio from https://developer.android.com/studio"
        log_info "  2. Set ANDROID_HOME environment variable"
        log_info "  3. Add to ~/.bashrc: export ANDROID_HOME=$HOME/Android/Sdk"
        return 1
    fi
}

# Setup Python virtual environment
setup_python_venv() {
    log_info "Setting up Python virtual environment..."
    
    if command -v python3 &> /dev/null || command -v python &> /dev/null; then
        local python_cmd=$(command -v python3 || command -v python)
        local python_version=$($python_cmd --version 2>&1)
        log_success "Python found: $python_version"
        
        VENV_DIR="${HOME}/.xtreme-xai-venv"
        
        if [[ ! -d "$VENV_DIR" ]]; then
            log_info "Creating virtual environment..."
            $python_cmd -m venv "$VENV_DIR" 2>/dev/null || {
                log_warning "venv module not available, trying virtualenv..."
                if command -v virtualenv &> /dev/null; then
                    virtualenv "$VENV_DIR" 2>/dev/null
                else
                    log_error "Cannot create virtual environment"
                    return 1
                fi
            }
            
            if [[ -d "$VENV_DIR" ]]; then
                log_success "Virtual environment created at: $VENV_DIR"
                log_info "Activate with: source $VENV_DIR/bin/activate"
                
                # Install basic packages
                if [[ -f "$VENV_DIR/bin/pip" ]]; then
                    log_info "Installing basic packages..."
                    "$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel &>/dev/null
                    log_success "Basic packages installed"
                fi
            else
                log_error "Failed to create virtual environment"
                return 1
            fi
        else
            log_info "Virtual environment already exists at: $VENV_DIR"
            
            # Check if it's valid
            if [[ -f "$VENV_DIR/bin/activate" ]]; then
                log_success "Virtual environment is valid"
            else
                log_warning "Virtual environment may be corrupted"
            fi
        fi
        return 0
    else
        log_warning "Python not installed"
        log_info "Install with:"
        log_info "  Termux: pkg install python"
        log_info "  Ubuntu/Debian: sudo apt-get install python3 python3-venv"
        return 1
    fi
}

# Setup Node.js environment
setup_nodejs() {
    log_info "Checking Node.js installation..."
    
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        log_success "Node.js found: $node_version"
        
        if command -v npm &> /dev/null; then
            local npm_version=$(npm --version)
            log_success "npm found: v$npm_version"
            
            # Check for global packages
            local global_packages=$(npm list -g --depth=0 2>/dev/null | grep -c "├─\|└─")
            log_info "Global packages installed: $global_packages"
        else
            log_warning "npm not found"
        fi
        
        # Check for yarn
        if command -v yarn &> /dev/null; then
            local yarn_version=$(yarn --version)
            log_info "Yarn found: v$yarn_version"
        fi
        
        return 0
    else
        log_warning "Node.js not installed"
        log_info "To install Node.js:"
        log_info "  Termux: pkg install nodejs"
        log_info "  Ubuntu/Debian: sudo apt-get install nodejs npm"
        log_info "  Or visit: https://nodejs.org/"
        return 1
    fi
}

# Setup Java environment
setup_java() {
    log_info "Checking Java installation..."
    
    if command -v java &> /dev/null; then
        local java_version=$(java -version 2>&1 | head -n1)
        log_success "Java found: $java_version"
        
        # Check JAVA_HOME
        if [[ -n "$JAVA_HOME" ]]; then
            log_info "JAVA_HOME: $JAVA_HOME"
        else
            log_warning "JAVA_HOME not set"
        fi
        
        return 0
    else
        log_warning "Java not installed"
        log_info "Install with:"
        log_info "  Termux: pkg install openjdk-17"
        log_info "  Ubuntu/Debian: sudo apt-get install default-jdk"
        return 1
    fi
}

# Create emulator configuration
create_emulator_config() {
    log_info "Creating emulator configuration..."
    
    CONFIG_DIR="${HOME}/.config/xtreme-xai"
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_DIR/emulator.conf" << EOF
# XTREME-XAI-ULTIMATE Emulator Configuration v4.0
# © Elektronikx-Center-Matte ® | Alexander Mathey ©
# Generated: $(date)

[general]
emulator_backend=auto
enable_kvm=auto
enable_gpu_acceleration=true
config_version=4.0.0

[qemu]
memory=4096
cpu_cores=2
disk_size=20G
network_mode=user
display=sdl

[docker]
default_image=ubuntu:latest
network_mode=bridge
restart_policy=unless-stopped

[proot]
default_distro=ubuntu
shared_tmp=true
link2symlink=true

[android]
api_level=30
device_profile=pixel_4
gpu_mode=auto

[python]
venv_path=$HOME/.xtreme-xai-venv
default_version=3.x

[performance]
enable_cache=true
optimize_io=true
use_tmpfs=false

[paths]
working_dir=$HOME/xtreme_ai_system
data_dir=$HOME/xtreme_ai_system/data
models_dir=$HOME/xtreme_ai_system/models
EOF

    log_success "Configuration created at: $CONFIG_DIR/emulator.conf"
}

# Create helper scripts
create_helper_scripts() {
    log_info "Creating helper scripts..."
    
    local scripts_dir="${HOME}/xtreme_ai_system/scripts"
    mkdir -p "$scripts_dir"
    
    # Create QEMU starter script
    cat > "$scripts_dir/start-qemu.sh" << 'EOF'
#!/bin/bash
# QEMU Quick Start Script

qemu-system-x86_64 \
    -m 4G \
    -smp 2 \
    -enable-kvm \
    -display sdl \
    "$@"
EOF
    chmod +x "$scripts_dir/start-qemu.sh"
    
    # Create PRoot distro launcher
    if command -v proot-distro &> /dev/null; then
        cat > "$scripts_dir/launch-linux.sh" << 'EOF'
#!/bin/bash
# PRoot Distro Launcher

DISTRO="${1:-ubuntu}"
proot-distro login "$DISTRO"
EOF
        chmod +x "$scripts_dir/launch-linux.sh"
    fi
    
    log_success "Helper scripts created in $scripts_dir"
}

# Main setup function
main() {
    echo "========================================"
    echo "  Emulator Environment Setup v4.0"
    echo "  © Elektronikx-Center-Matte ®"
    echo "  Alexander Mathey ©"
    echo "========================================"
    echo
    
    local warnings=0
    
    check_virtualization || warnings=$((warnings + 1))
    check_kvm || warnings=$((warnings + 1))
    setup_qemu || warnings=$((warnings + 1))
    setup_docker || warnings=$((warnings + 1))
    setup_proot || warnings=$((warnings + 1))
    setup_android_emulator || warnings=$((warnings + 1))
    setup_python_venv || warnings=$((warnings + 1))
    setup_nodejs || warnings=$((warnings + 1))
    setup_java || warnings=$((warnings + 1))
    
    echo
    create_emulator_config
    create_helper_scripts
    
    echo
    echo "========================================"
    if [[ $warnings -eq 0 ]]; then
        log_success "Emulator environment setup completed successfully!"
    else
        log_warning "Setup completed with $warnings warning(s)"
        log_info "Some emulator features may be unavailable"
        log_info "This is normal for Android/Termux environments"
    fi
    echo "========================================"
    echo
    log_info "Next steps:"
    echo "  - Source the virtual environment: source ~/.xtreme-xai-venv/bin/activate"
    echo "  - Install additional packages as needed"
    echo "  - Check configuration: cat ~/.config/xtreme-xai/emulator.conf"
}

main "$@"
