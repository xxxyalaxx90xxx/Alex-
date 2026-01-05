#!/bin/bash

#################################################################################
# Complete Development Environment Setup
# 
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©
#
# This script provides comprehensive development environment including:
# - VS Code with extensions
# - Android SDK and APK build tools
# - AI/ML development frameworks (TensorFlow, PyTorch, etc.)
# - Cybersecurity tools and frameworks
# - Programming languages and IDEs
# - Docker and containerization
# - Git and version control
#################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
INFO="${BLUE}ℹ${NC}"
WARN="${YELLOW}⚠${NC}"
STAR="${CYAN}★${NC}"

# Configuration
AUTHOR="Alexander Mathey"
EMAIL="xyalaxxx90@gmail.com"
COPYRIGHT="Elektronikx-Center-Matte ® ™ By Alexander Mathey ©"
GRADLE_VERSION="${GRADLE_VERSION:-8.5}"
ANDROID_SDK_VERSION="${ANDROID_SDK_VERSION:-9477386}"

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

log_header() {
    log "${CYAN}╔══════════════════════════════════════════╗${NC}"
    log "${CYAN}║  ${1}${NC}"
    log "${CYAN}╚══════════════════════════════════════════╝${NC}"
}

detect_system() {
    log_header "Detecting System"
    
    # Detect OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
        log_info "OS: $PRETTY_NAME"
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        OS="macos"
        log_info "OS: macOS"
    else
        OS="unknown"
        log_warn "Unknown OS"
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
    
    # Detect if Termux
    if [[ -n "$TERMUX_VERSION" ]]; then
        IS_TERMUX=true
        log_info "Environment: Termux"
    else
        IS_TERMUX=false
    fi
    
    # Detect if WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
        log_info "Environment: WSL"
    else
        IS_WSL=false
    fi
}

install_package_manager_tools() {
    log_header "Setting up Package Manager"
    
    if [[ "$IS_TERMUX" == true ]]; then
        PKG_CMD="pkg install -y"
        PKG_UPDATE="pkg update && pkg upgrade -y"
    elif command -v apt &> /dev/null; then
        PKG_CMD="apt install -y"
        PKG_UPDATE="apt update && apt upgrade -y"
    elif command -v dnf &> /dev/null; then
        PKG_CMD="dnf install -y"
        PKG_UPDATE="dnf update -y"
    elif command -v yum &> /dev/null; then
        PKG_CMD="yum install -y"
        PKG_UPDATE="yum update -y"
    elif command -v pacman &> /dev/null; then
        PKG_CMD="pacman -S --noconfirm"
        PKG_UPDATE="pacman -Syu --noconfirm"
    else
        log_error "No supported package manager found"
        exit 1
    fi
    
    log_info "Updating package lists..."
    eval "$PKG_UPDATE" || log_warn "Package update failed"
}

install_vscode() {
    log_header "Installing VS Code"
    
    if command -v code &> /dev/null; then
        log_success "VS Code already installed"
        return
    fi
    
    if [[ "$IS_TERMUX" == true ]]; then
        log_info "Installing code-server (VS Code for web) in Termux..."
        $PKG_CMD nodejs python
        npm install -g code-server
        
        # Create startup script
        cat > ~/start-vscode.sh << 'EOF'
#!/bin/bash
code-server --bind-addr 127.0.0.1:8080 --auth password
EOF
        chmod +x ~/start-vscode.sh
        
        log_success "code-server installed"
        log_info "Start with: ~/start-vscode.sh"
        log_info "Access at: http://127.0.0.1:8080"
        
    elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        log_info "Installing VS Code on Debian/Ubuntu..."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null
        rm -f packages.microsoft.gpg
        
        apt update
        apt install -y code
        
        log_success "VS Code installed"
        
    elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
        log_info "Installing VS Code on Fedora/RHEL/CentOS..."
        rpm --import https://packages.microsoft.com/keys/microsoft.asc
        echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null
        
        dnf install -y code || yum install -y code
        
        log_success "VS Code installed"
    else
        log_warn "Manual VS Code installation required for this OS"
        log_info "Download from: https://code.visualstudio.com/"
    fi
}

install_vscode_extensions() {
    log_header "Installing VS Code Extensions"
    
    if ! command -v code &> /dev/null; then
        log_warn "VS Code not found, skipping extensions"
        return
    fi
    
    local EXTENSIONS=(
        # General Development
        "ms-vscode.vscode-typescript-next"
        "dbaeumer.vscode-eslint"
        "esbenp.prettier-vscode"
        "eamodio.gitlens"
        
        # Python & AI/ML
        "ms-python.python"
        "ms-python.vscode-pylance"
        "ms-toolsai.jupyter"
        "ms-toolsai.vscode-jupyter-cell-tags"
        "ms-toolsai.vscode-jupyter-slideshow"
        
        # Android Development
        "vscjava.vscode-java-pack"
        "vscjava.vscode-gradle"
        "redhat.java"
        
        # Docker & Kubernetes
        "ms-azuretools.vscode-docker"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        
        # Web Development
        "formulahendry.auto-rename-tag"
        "ritwickdey.LiveServer"
        
        # Security
        "Snyk.snyk-vulnerability-scanner"
        
        # C/C++
        "ms-vscode.cpptools"
        
        # Go
        "golang.go"
        
        # Rust
        "rust-lang.rust-analyzer"
        
        # Git
        "mhutchie.git-graph"
        
        # AI Assistants
        "GitHub.copilot"
        "TabNine.tabnine-vscode"
    )
    
    log_info "Installing VS Code extensions..."
    for ext in "${EXTENSIONS[@]}"; do
        log_info "Installing: $ext"
        code --install-extension "$ext" 2>/dev/null || log_warn "Failed to install $ext"
    done
    
    log_success "VS Code extensions installed"
}

install_android_sdk() {
    log_header "Installing Android SDK & Build Tools"
    
    local ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
    
    if [[ -d "$ANDROID_HOME" ]]; then
        log_success "Android SDK already installed at: $ANDROID_HOME"
        export ANDROID_HOME
        export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
        return
    fi
    
    log_info "Installing Android SDK..."
    
    # Install Java (required for Android SDK)
    log_info "Installing Java..."
    if [[ "$IS_TERMUX" == true ]]; then
        $PKG_CMD openjdk-17
    else
        $PKG_CMD openjdk-17-jdk || $PKG_CMD java-17-openjdk || log_warn "Java installation failed"
    fi
    
    # Download Android SDK command line tools
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    cd "$ANDROID_HOME/cmdline-tools"
    
    local SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip"
    
    log_info "Downloading Android SDK command line tools..."
    wget -q "$SDK_URL" -O cmdline-tools.zip
    
    # Verify download
    if [[ ! -f cmdline-tools.zip ]] || [[ ! -s cmdline-tools.zip ]]; then
        log_error "Failed to download Android SDK"
        return 1
    fi
    
    unzip -q cmdline-tools.zip
    mv cmdline-tools latest
    rm cmdline-tools.zip
    
    # Set environment variables
    export ANDROID_HOME
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
    
    # Accept licenses
    yes | sdkmanager --licenses 2>/dev/null || true
    
    # Install essential SDK components
    log_info "Installing Android SDK components..."
    sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2" "ndk;25.2.9519653"
    
    # Add to bash/zsh profile
    echo "export ANDROID_HOME=$ANDROID_HOME" >> ~/.bashrc
    echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools" >> ~/.bashrc
    
    log_success "Android SDK installed at: $ANDROID_HOME"
}

install_gradle() {
    log_header "Installing Gradle (APK Build Tool)"
    
    if command -v gradle &> /dev/null; then
        log_success "Gradle already installed: $(gradle --version | head -1)"
        return
    fi
    
    local GRADLE_HOME="/opt/gradle"
    
    log_info "Installing Gradle $GRADLE_VERSION..."
    
    # Download Gradle
    wget -q "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -O /tmp/gradle.zip
    
    # Verify download succeeded
    if [[ ! -f /tmp/gradle.zip ]] || [[ ! -s /tmp/gradle.zip ]]; then
        log_error "Failed to download Gradle"
        return 1
    fi
    
    mkdir -p "$GRADLE_HOME"
    unzip -q /tmp/gradle.zip -d "$GRADLE_HOME"
    rm /tmp/gradle.zip
    
    export PATH="$PATH:$GRADLE_HOME/gradle-${GRADLE_VERSION}/bin"
    echo "export PATH=\$PATH:$GRADLE_HOME/gradle-${GRADLE_VERSION}/bin" >> ~/.bashrc
    
    log_success "Gradle installed: $(gradle --version | head -1)"
}

install_ai_ml_frameworks() {
    log_header "Installing AI/ML Development Frameworks"
    
    # Install Python and pip if not available
    if ! command -v python3 &> /dev/null; then
        log_info "Installing Python..."
        $PKG_CMD python3 python3-pip
    fi
    
    log_info "Upgrading pip..."
    python3 -m pip install --upgrade pip
    
    # Install AI/ML frameworks
    local AI_PACKAGES=(
        "tensorflow"
        "torch"
        "torchvision"
        "numpy"
        "pandas"
        "scikit-learn"
        "opencv-python"
        "keras"
        "transformers"
        "accelerate"
        "diffusers"
        "huggingface-hub"
        "jupyter"
        "notebook"
        "matplotlib"
        "seaborn"
        "pillow"
    )
    
    log_info "Installing AI/ML Python packages (batch mode for efficiency)..."
    # Create requirements file for faster installation
    local REQ_FILE="/tmp/ai_requirements.txt"
    printf "%s\n" "${AI_PACKAGES[@]}" > "$REQ_FILE"
    
    # Batch install for better performance
    pip3 install -r "$REQ_FILE" || log_warn "Some AI/ML packages failed to install"
    
    rm -f "$REQ_FILE"
    
    log_success "AI/ML frameworks installed"
}

install_cybersecurity_tools() {
    log_header "Installing Cybersecurity Tools"
    
    local SECURITY_TOOLS=(
        "nmap"           # Network scanner
        "netcat-openbsd" # Network utility
        "curl"           # HTTP client
        "wget"           # Download utility
        "git"            # Version control
        "openssl"        # SSL/TLS toolkit
        "gnupg"          # Encryption
    )
    
    log_info "Installing security tools..."
    for tool in "${SECURITY_TOOLS[@]}"; do
        if ! command -v "${tool%%-*}" &> /dev/null; then
            log_info "Installing: $tool"
            $PKG_CMD "$tool" 2>/dev/null || log_warn "Failed to install $tool"
        fi
    done
    
    # Install Python security packages
    local SECURITY_PYTHON=(
        "requests"
        "beautifulsoup4"
        "scapy"
        "cryptography"
        "pycryptodome"
        "paramiko"
    )
    
    log_info "Installing Python security libraries..."
    for pkg in "${SECURITY_PYTHON[@]}"; do
        pip3 install "$pkg" 2>/dev/null || log_warn "Failed to install $pkg"
    done
    
    log_success "Cybersecurity tools installed"
}

install_programming_languages() {
    log_header "Installing Programming Languages"
    
    # Python
    if ! command -v python3 &> /dev/null; then
        log_info "Installing Python..."
        $PKG_CMD python3 python3-pip
    fi
    log_success "Python: $(python3 --version)"
    
    # Node.js
    if ! command -v node &> /dev/null; then
        log_info "Installing Node.js..."
        if [[ "$IS_TERMUX" == true ]]; then
            $PKG_CMD nodejs
        else
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - 2>/dev/null
            $PKG_CMD nodejs
        fi
    fi
    log_success "Node.js: $(node --version)"
    
    # Go
    if ! command -v go &> /dev/null; then
        log_info "Installing Go..."
        $PKG_CMD golang || $PKG_CMD go
    fi
    if command -v go &> /dev/null; then
        log_success "Go: $(go version)"
    fi
    
    # Rust
    if ! command -v rustc &> /dev/null; then
        log_info "Installing Rust..."
        if [[ "$IS_TERMUX" == true ]]; then
            $PKG_CMD rust
        else
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
        fi
    fi
    if command -v rustc &> /dev/null; then
        log_success "Rust: $(rustc --version)"
    fi
}

install_docker() {
    log_header "Installing Docker"
    
    if [[ "$IS_TERMUX" == true ]]; then
        log_warn "Docker not available in Termux. Use proot-distro instead."
        return
    fi
    
    if command -v docker &> /dev/null; then
        log_success "Docker already installed: $(docker --version)"
        return
    fi
    
    log_info "Installing Docker..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        # Add Docker repository
        curl -fsSL https://download.docker.com/linux/${OS}/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${OS} $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        apt update
        apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
    elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]]; then
        dnf install -y dnf-plugins-core
        dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi
    
    # Start Docker service
    systemctl start docker 2>/dev/null || true
    systemctl enable docker 2>/dev/null || true
    
    # Add current user to docker group
    if [[ -n "$SUDO_USER" ]]; then
        usermod -aG docker "$SUDO_USER"
        log_info "Added $SUDO_USER to docker group. Logout and login for changes to take effect."
    fi
    
    log_success "Docker installed: $(docker --version)"
}

create_project_templates() {
    log_header "Creating Project Templates"
    
    local TEMPLATES_DIR="$HOME/dev-templates"
    mkdir -p "$TEMPLATES_DIR"
    
    # Android App Template
    cat > "$TEMPLATES_DIR/create-android-app.sh" << 'EOF'
#!/bin/bash
# Android App Creation Template
# Author: Alexander Mathey (xyalaxxx90@gmail.com)

APP_NAME="$1"
PACKAGE_NAME="$2"

if [[ -z "$APP_NAME" ]] || [[ -z "$PACKAGE_NAME" ]]; then
    echo "Usage: $0 <AppName> <com.example.package>"
    exit 1
fi

mkdir -p "$APP_NAME"
cd "$APP_NAME"

# Initialize Gradle project
gradle init --type java-application

echo "Android app template created: $APP_NAME"
echo "Package: $PACKAGE_NAME"
EOF
    
    # AI Project Template
    cat > "$TEMPLATES_DIR/create-ai-project.sh" << 'EOF'
#!/bin/bash
# AI Project Template
# Author: Alexander Mathey (xyalaxxx90@gmail.com)

PROJECT_NAME="$1"

if [[ -z "$PROJECT_NAME" ]]; then
    echo "Usage: $0 <ProjectName>"
    exit 1
fi

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Create requirements.txt
cat > requirements.txt << 'REQUIREMENTS'
tensorflow
torch
numpy
pandas
scikit-learn
jupyter
matplotlib
REQUIREMENTS

pip install -r requirements.txt

# Create project structure
mkdir -p data models notebooks scripts

echo "AI project created: $PROJECT_NAME"
echo "Activate venv: source venv/bin/activate"
EOF
    
    chmod +x "$TEMPLATES_DIR"/*.sh
    
    log_success "Project templates created in: $TEMPLATES_DIR"
}

setup_git_config() {
    log_header "Configuring Git"
    
    if ! command -v git &> /dev/null; then
        log_info "Installing Git..."
        $PKG_CMD git
    fi
    
    # Configure Git with author information
    git config --global user.name "$AUTHOR"
    git config --global user.email "$EMAIL"
    
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    
    log_success "Git configured for $AUTHOR <$EMAIL>"
}

create_startup_script() {
    log_header "Creating Development Environment Launcher"
    
    cat > ~/start-dev-environment.sh << 'EOF'
#!/bin/bash
# Development Environment Launcher
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©

echo "================================================"
echo "Development Environment by Alexander Mathey"
echo "Email: xyalaxxx90@gmail.com"
echo "================================================"
echo ""

# Set environment variables
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Start services
echo "Starting development services..."

# Start Docker (if installed)
if command -v docker &> /dev/null; then
    sudo systemctl start docker 2>/dev/null || true
    echo "✓ Docker started"
fi

# Print available tools
echo ""
echo "Available tools:"
command -v code &> /dev/null && echo "  ✓ VS Code: $(code --version | head -1)"
command -v python3 &> /dev/null && echo "  ✓ Python: $(python3 --version)"
command -v node &> /dev/null && echo "  ✓ Node.js: $(node --version)"
command -v go &> /dev/null && echo "  ✓ Go: $(go version | cut -d' ' -f3)"
command -v rustc &> /dev/null && echo "  ✓ Rust: $(rustc --version | cut -d' ' -f2)"
command -v docker &> /dev/null && echo "  ✓ Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
command -v gradle &> /dev/null && echo "  ✓ Gradle: $(gradle --version | grep Gradle | cut -d' ' -f2)"

echo ""
echo "Ready for development!"
echo ""
echo "Project templates: ~/dev-templates/"
echo "Start VS Code: code"
echo ""
EOF
    
    chmod +x ~/start-dev-environment.sh
    
    log_success "Startup script created: ~/start-dev-environment.sh"
}

print_summary() {
    log ""
    log "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    log "${CYAN}║                                                ║${NC}"
    log "${CYAN}║    ${GREEN}Development Environment Setup Complete!${CYAN}    ║${NC}"
    log "${CYAN}║                                                ║${NC}"
    log "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    log ""
    log "${MAGENTA}Author: $AUTHOR${NC}"
    log "${MAGENTA}Email: $EMAIL${NC}"
    log "${MAGENTA}$COPYRIGHT${NC}"
    log ""
    log "${YELLOW}══════════════════════════════════════════════${NC}"
    log "${YELLOW}Installed Components:${NC}"
    log "${YELLOW}══════════════════════════════════════════════${NC}"
    
    command -v code &> /dev/null && log "  ${STAR} VS Code: $(code --version | head -1)"
    command -v python3 &> /dev/null && log "  ${STAR} Python: $(python3 --version)"
    command -v node &> /dev/null && log "  ${STAR} Node.js: $(node --version)"
    command -v go &> /dev/null && log "  ${STAR} Go: $(go version | cut -d' ' -f3)"
    command -v rustc &> /dev/null && log "  ${STAR} Rust: $(rustc --version)"
    command -v docker &> /dev/null && log "  ${STAR} Docker: $(docker --version)"
    command -v gradle &> /dev/null && log "  ${STAR} Gradle: $(gradle --version | grep Gradle)"
    [[ -d "$ANDROID_HOME" ]] && log "  ${STAR} Android SDK: $ANDROID_HOME"
    
    log ""
    log "${YELLOW}══════════════════════════════════════════════${NC}"
    log "${YELLOW}Next Steps:${NC}"
    log "${YELLOW}══════════════════════════════════════════════${NC}"
    log ""
    log "  1. Start development environment:"
    log "     ${GREEN}~/start-dev-environment.sh${NC}"
    log ""
    log "  2. Launch VS Code:"
    log "     ${GREEN}code${NC}"
    log ""
    log "  3. Create Android app:"
    log "     ${GREEN}~/dev-templates/create-android-app.sh MyApp com.example.myapp${NC}"
    log ""
    log "  4. Create AI project:"
    log "     ${GREEN}~/dev-templates/create-ai-project.sh my-ai-project${NC}"
    log ""
    log "  5. Build APK (in Android project):"
    log "     ${GREEN}gradle assembleDebug${NC}"
    log ""
    log "${YELLOW}══════════════════════════════════════════════${NC}"
    log "${YELLOW}Documentation:${NC}"
    log "${YELLOW}══════════════════════════════════════════════${NC}"
    log "  - VS Code: https://code.visualstudio.com/docs"
    log "  - Android: https://developer.android.com"
    log "  - TensorFlow: https://tensorflow.org"
    log "  - PyTorch: https://pytorch.org"
    log ""
}

main() {
    log "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    log "${CYAN}║                                                ║${NC}"
    log "${CYAN}║    ${BLUE}Complete Development Environment Setup${CYAN}     ║${NC}"
    log "${CYAN}║                                                ║${NC}"
    log "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    log ""
    log "${MAGENTA}By: $AUTHOR${NC}"
    log "${MAGENTA}Email: $EMAIL${NC}"
    log "${MAGENTA}$COPYRIGHT${NC}"
    log ""
    
    detect_system
    install_package_manager_tools
    
    if [[ "${SKIP_VSCODE:-false}" != "true" ]]; then
        install_vscode
        install_vscode_extensions
    fi
    
    if [[ "${SKIP_ANDROID:-false}" != "true" ]]; then
        install_android_sdk
        install_gradle
    fi
    
    if [[ "${SKIP_AI:-false}" != "true" ]]; then
        install_ai_ml_frameworks
    fi
    
    if [[ "${SKIP_SECURITY:-false}" != "true" ]]; then
        install_cybersecurity_tools
    fi
    
    install_programming_languages
    
    if [[ "${SKIP_DOCKER:-false}" != "true" ]] && [[ "$IS_TERMUX" != true ]]; then
        install_docker
    fi
    
    create_project_templates
    setup_git_config
    create_startup_script
    
    print_summary
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-vscode)
            SKIP_VSCODE=true
            shift
            ;;
        --skip-android)
            SKIP_ANDROID=true
            shift
            ;;
        --skip-ai)
            SKIP_AI=true
            shift
            ;;
        --skip-security)
            SKIP_SECURITY=true
            shift
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        --help)
            echo "Complete Development Environment Setup"
            echo "By: Alexander Mathey (xyalaxxx90@gmail.com)"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-vscode     Skip VS Code installation"
            echo "  --skip-android    Skip Android SDK/tools"
            echo "  --skip-ai         Skip AI/ML frameworks"
            echo "  --skip-security   Skip security tools"
            echo "  --skip-docker     Skip Docker installation"
            echo "  --help            Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

main
