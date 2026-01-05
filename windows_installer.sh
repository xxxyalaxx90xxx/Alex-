#!/bin/bash

# Windows Complete Installer with Linux Capabilities
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in WSL
check_wsl() {
    if ! grep -qi microsoft /proc/version; then
        print_error "This script must be run in WSL (Windows Subsystem for Linux)"
        print_info "Please install WSL first: wsl --install"
        exit 1
    fi
    
    print_success "Running in WSL"
}

# Setup WSL2 configuration
setup_wsl_config() {
    print_info "Configuring WSL2..."
    
    # Create .wslconfig in Windows user directory
    local win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    local wsl_config="/mnt/c/Users/$win_user/.wslconfig"
    
    cat > "$wsl_config" <<EOF
[wsl2]
memory=4GB
processors=2
swap=2GB
localhostForwarding=true

[experimental]
autoMemoryReclaim=gradual
networkingMode=mirrored
dnsTunneling=true
firewall=true
EOF
    
    print_success "WSL2 configured"
}

# Install databases
install_databases() {
    print_info "Installing database stack..."
    
    # PostgreSQL
    sudo apt-get install -y postgresql postgresql-contrib
    sudo service postgresql start
    
    # MySQL
    sudo apt-get install -y mysql-server
    sudo service mysql start
    
    # Redis
    sudo apt-get install -y redis-server
    sudo service redis-server start
    
    # MongoDB
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    sudo apt-get update
    sudo apt-get install -y mongodb-org
    sudo service mongod start
    
    print_success "Databases installed"
}

# Install development tools
install_dev_tools() {
    print_info "Installing development tools..."
    
    sudo apt-get install -y \
        git \
        build-essential \
        python3 \
        python3-pip \
        nodejs \
        npm \
        docker.io
    
    # VS Code integration
    if ! command -v code &> /dev/null; then
        print_info "Installing VS Code CLI..."
        curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz
        tar -xf vscode_cli.tar.gz
        sudo mv code /usr/local/bin/
        rm vscode_cli.tar.gz
    fi
    
    print_success "Development tools installed"
}

# Install K3s
install_k3s() {
    print_info "Installing K3s..."
    
    curl -sfL https://get.k3s.io | sh -
    
    # Configure kubectl for Windows access
    local win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    local kubeconfig="/mnt/c/Users/$win_user/.kube/config"
    
    mkdir -p "/mnt/c/Users/$win_user/.kube"
    sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/localhost/g' > "$kubeconfig"
    
    print_success "K3s installed"
}

# Create Windows GUI launcher
create_gui_launcher() {
    print_info "Creating Windows GUI launcher..."
    
    local win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    local launcher_path="/mnt/c/Users/$win_user/Desktop/K8s-Launcher.ps1"
    
    cat > "$launcher_path" <<'EOF'
# Kubernetes Management Launcher
# Author: Alexander Mathey

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Kubernetes Management'
$form.Size = New-Object System.Drawing.Size(500,600)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$form.ForeColor = [System.Drawing.Color]::White

$title = New-Object System.Windows.Forms.Label
$title.Location = New-Object System.Drawing.Point(20,20)
$title.Size = New-Object System.Drawing.Size(460,40)
$title.Text = '🚀 Kubernetes & Database Management'
$title.Font = New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle]::Bold)
$form.Controls.Add($title)

function Create-Button($text, $y, $command) {
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(50,$y)
    $button.Size = New-Object System.Drawing.Size(400,50)
    $button.Text = $text
    $button.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $button.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatStyle = 'Flat'
    $button.Add_Click({
        wsl -e bash -c $command
    })
    $form.Controls.Add($button)
}

Create-Button "Start K3s Cluster" 80 "sudo systemctl start k3s"
Create-Button "Stop K3s Cluster" 140 "sudo systemctl stop k3s"
Create-Button "Open Web Dashboard" 200 "~/dashboard-start.sh &"
Create-Button "Start All Databases" 260 "sudo service postgresql start && sudo service mysql start && sudo service redis-server start && sudo service mongod start"
Create-Button "Open Database UIs" 320 "~/db-ui-start.sh &"
Create-Button "System Information" 380 "sys-info"
Create-Button "Open Terminal" 440 "bash"

$status = New-Object System.Windows.Forms.Label
$status.Location = New-Object System.Drawing.Point(20,510)
$status.Size = New-Object System.Drawing.Size(460,30)
$status.Text = 'Ready'
$status.Font = New-Object System.Drawing.Font("Segoe UI",10)
$form.Controls.Add($status)

$form.ShowDialog()
EOF
    
    print_success "GUI launcher created on Desktop"
}

# Create helper scripts
create_helper_scripts() {
    print_info "Creating helper scripts..."
    
    cat > "$HOME/k3s-start.sh" <<'EOF'
#!/bin/bash
sudo systemctl start k3s
echo "K3s started"
kubectl get nodes
EOF
    
    cat > "$HOME/k3s-stop.sh" <<'EOF'
#!/bin/bash
sudo systemctl stop k3s
echo "K3s stopped"
EOF
    
    cat > "$HOME/k3s-restart.sh" <<'EOF'
#!/bin/bash
sudo systemctl restart k3s
echo "K3s restarted"
sleep 5
kubectl get nodes
EOF
    
    cat > "$HOME/db-start.sh" <<'EOF'
#!/bin/bash
sudo service postgresql start
sudo service mysql start
sudo service redis-server start
sudo service mongod start
echo "All databases started"
EOF
    
    chmod +x "$HOME"/k3s-*.sh "$HOME/db-start.sh"
    
    print_success "Helper scripts created"
}

# Main installation
main() {
    print_info "Windows Complete Installer"
    print_info "This will install a complete development environment with Linux capabilities"
    echo ""
    
    check_wsl
    
    print_info "Updating system..."
    sudo apt-get update
    sudo apt-get upgrade -y
    
    setup_wsl_config
    install_databases
    install_dev_tools
    install_k3s
    create_gui_launcher
    create_helper_scripts
    
    print_success "Installation complete!"
    echo ""
    print_info "Installed components:"
    print_info "  - PostgreSQL (port 5432)"
    print_info "  - MySQL (port 3306)"
    print_info "  - Redis (port 6379)"
    print_info "  - MongoDB (port 27017)"
    print_info "  - K3s Kubernetes"
    print_info "  - VS Code CLI"
    print_info "  - Docker"
    echo ""
    print_info "GUI Launcher created on your Desktop"
    print_info "Or use command line:"
    print_info "  - Start K3s: ~/k3s-start.sh"
    print_info "  - Start DBs: ~/db-start.sh"
    echo ""
    print_info "Restart WSL to apply configuration changes"
}

main
