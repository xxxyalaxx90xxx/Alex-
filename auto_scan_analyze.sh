#!/bin/bash

# Auto Scan & Analyze System
# Automatically scans and analyzes all installations and configurations
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Show banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║      🔍 Automatic System Scan & Analysis Tool 🔍                      ║
║                                                                       ║
║          Intelligent Configuration & Optimization Analysis            ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${MAGENTA}   Author: Alexander Mathey | Elektronikx-Center-Matte ® ™${NC}"
    echo ""
}

show_banner

# Scan System
scan_system() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ 📡 [1/5] Scanning System Environment...                               ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        OS="Unknown"
        VERSION="Unknown"
    fi
    
    # Detect Architecture
    ARCH=$(uname -m)
    
    # Detect Memory
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    
    # Detect CPU
    CPU_CORES=$(nproc)
    
    # Detect Device
    if [ -f /proc/device-tree/model ]; then
        DEVICE=$(cat /proc/device-tree/model)
    elif command -v getprop &> /dev/null; then
        DEVICE=$(getprop ro.product.model 2>/dev/null || echo "Android Device")
    else
        DEVICE="Standard Computer"
    fi
    
    echo -e "  ${CYAN}OS:${NC}             ${GREEN}$OS $VERSION${NC}"
    echo -e "  ${CYAN}Architecture:${NC}   ${GREEN}$ARCH${NC}"
    echo -e "  ${CYAN}Memory:${NC}         ${GREEN}${TOTAL_MEM}MB${NC}"
    echo -e "  ${CYAN}CPU Cores:${NC}      ${GREEN}$CPU_CORES${NC}"
    echo -e "  ${CYAN}Device:${NC}         ${GREEN}$DEVICE${NC}"
    echo ""
    
    # Show resource bar
    local mem_gb=$(awk "BEGIN {printf \"%.1f\", $TOTAL_MEM/1024}")
    echo -e "  ${CYAN}Resource Profile:${NC}"
    
    if [ "$TOTAL_MEM" -lt 2048 ]; then
        echo -e "    ${YELLOW}⚠${NC} Low Memory Device (${mem_gb}GB) - K3s Recommended"
    elif [ "$TOTAL_MEM" -lt 4096 ]; then
        echo -e "    ${GREEN}✓${NC} Standard Device (${mem_gb}GB) - K3s or Full Kubernetes"
    else
        echo -e "    ${GREEN}✓${NC} High Memory Device (${mem_gb}GB) - Full Kubernetes Recommended"
    fi
    echo ""
}

# Scan Installed Tools
scan_tools() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ 🛠️  [2/5] Scanning Installed Tools & Services...                      ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    INSTALLED_TOOLS=()
    
    echo -e "  ${CYAN}━━━ Kubernetes Tools ━━━${NC}"
    # Check for kubectl
    if command -v kubectl &> /dev/null; then
        INSTALLED_TOOLS+=("kubectl")
        local version=$(kubectl version --client --short 2>/dev/null | head -n1 | awk '{print $3}')
        echo -e "    ${GREEN}✓${NC} kubectl ${GREEN}$version${NC}"
    else
        echo -e "    ${RED}✗${NC} kubectl ${YELLOW}(not installed)${NC}"
    fi
    
    # Check for K3s
    if command -v k3s &> /dev/null; then
        INSTALLED_TOOLS+=("k3s")
        local version=$(k3s --version 2>/dev/null | head -n1 | awk '{print $3}')
        echo -e "    ${GREEN}✓${NC} K3s ${GREEN}$version${NC}"
    else
        echo -e "    ${RED}✗${NC} K3s ${YELLOW}(not installed)${NC}"
    fi
    
    # Check for Docker
    if command -v docker &> /dev/null; then
        INSTALLED_TOOLS+=("docker")
        local version=$(docker --version | awk '{print $3}' | tr -d ',')
        echo -e "    ${GREEN}✓${NC} Docker ${GREEN}$version${NC}"
    else
        echo -e "    ${RED}✗${NC} Docker ${YELLOW}(not installed)${NC}"
    fi
    
    echo ""
    echo -e "  ${CYAN}━━━ Database Services ━━━${NC}"
    # Check for databases
    if command -v psql &> /dev/null; then
        INSTALLED_TOOLS+=("postgresql")
        echo -e "    ${GREEN}✓${NC} PostgreSQL"
    else
        echo -e "    ${RED}✗${NC} PostgreSQL ${YELLOW}(not installed)${NC}"
    fi
    
    if command -v mysql &> /dev/null; then
        INSTALLED_TOOLS+=("mysql")
        echo -e "    ${GREEN}✓${NC} MySQL/MariaDB"
    else
        echo -e "    ${RED}✗${NC} MySQL/MariaDB ${YELLOW}(not installed)${NC}"
    fi
    
    if command -v redis-cli &> /dev/null; then
        INSTALLED_TOOLS+=("redis")
        echo -e "    ${GREEN}✓${NC} Redis"
    else
        echo -e "    ${RED}✗${NC} Redis ${YELLOW}(not installed)${NC}"
    fi
    
    if command -v mongo &> /dev/null || command -v mongosh &> /dev/null; then
        INSTALLED_TOOLS+=("mongodb")
        echo -e "    ${GREEN}✓${NC} MongoDB"
    else
        echo -e "    ${RED}✗${NC} MongoDB ${YELLOW}(not installed)${NC}"
    fi
    
    echo ""
    echo -e "  ${CYAN}━━━ AI & Advanced Tools ━━━${NC}"
    # Check for AI tools
    if [ -d ~/.termux-ai ]; then
        INSTALLED_TOOLS+=("ai-assistant")
        echo -e "    ${GREEN}✓${NC} AI Assistant"
    else
        echo -e "    ${RED}✗${NC} AI Assistant ${YELLOW}(not installed)${NC}"
    fi
    
    # Check for web dashboard
    if [ -f /usr/local/bin/k8s-dashboard ]; then
        INSTALLED_TOOLS+=("web-dashboard")
        echo -e "    ${GREEN}✓${NC} Web Dashboard"
    else
        echo -e "    ${RED}✗${NC} Web Dashboard ${YELLOW}(not installed)${NC}"
    fi
    
    echo ""
    echo -e "  ${CYAN}╭─────────────────────────────────────────╮${NC}"
    echo -e "  ${CYAN}│${NC} Total Installed Tools: ${GREEN}${#INSTALLED_TOOLS[@]}${NC}/${CYAN}30${NC}"
    echo -e "  ${CYAN}╰─────────────────────────────────────────╯${NC}"
    echo ""
}

# Analyze Configuration
analyze_config() {
    echo -e "${GREEN}[3/5] Analyzing configuration...${NC}"
    
    # Check Kubernetes cluster
    if command -v kubectl &> /dev/null; then
        if kubectl cluster-info &> /dev/null; then
            echo -e "  ✓ Kubernetes cluster: ${GREEN}Running${NC}"
            
            # Node count
            NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
            echo -e "    Nodes: ${GREEN}$NODE_COUNT${NC}"
            
            # Pod count
            POD_COUNT=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
            echo -e "    Pods: ${GREEN}$POD_COUNT${NC}"
        else
            echo -e "  ✗ Kubernetes cluster: ${RED}Not running${NC}"
        fi
    fi
    
    # Check services
    if systemctl list-units --type=service --state=running | grep -q k3s; then
        echo -e "  ✓ K3s service: ${GREEN}Running${NC}"
    fi
    
    # Check databases
    for db in postgresql mysql redis-server mongod; do
        if systemctl is-active --quiet $db 2>/dev/null || pgrep -x $db &>/dev/null; then
            echo -e "  ✓ $db: ${GREEN}Running${NC}"
        fi
    done
}

# Optimization Recommendations
recommend_optimizations() {
    echo -e "${GREEN}[4/5] Generating optimization recommendations...${NC}"
    
    RECOMMENDATIONS=()
    
    # Memory-based recommendations
    if [ "$TOTAL_MEM" -lt 2048 ]; then
        RECOMMENDATIONS+=("Install K3s instead of full Kubernetes (low memory)")
        RECOMMENDATIONS+=("Enable aggressive memory eviction policies")
    fi
    
    # CPU-based recommendations
    if [ "$CPU_CORES" -lt 4 ]; then
        RECOMMENDATIONS+=("Limit maximum pods to $(($CPU_CORES * 10))")
    fi
    
    # Architecture-based recommendations
    if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "armv7l" ]]; then
        RECOMMENDATIONS+=("Use ARM-optimized container images")
        RECOMMENDATIONS+=("Enable host-gateway networking")
    fi
    
    # Display recommendations
    if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
        for rec in "${RECOMMENDATIONS[@]}"; do
            echo -e "  📋 $rec"
        done
    else
        echo -e "  ✓ ${GREEN}No specific optimizations needed${NC}"
    fi
}

# Generate Installation Plan
generate_install_plan() {
    echo -e "${GREEN}[5/5] Generating installation plan...${NC}"
    
    INSTALL_PLAN="/tmp/k8s_install_plan.sh"
    
    cat > $INSTALL_PLAN <<'EOF'
#!/bin/bash
# Auto-generated Installation Plan
# Generated by auto_scan_analyze.sh

set -e

echo "Starting automated installation..."

EOF
    
    # Add memory check
    if [ "$TOTAL_MEM" -lt 2048 ]; then
        echo "INSTALL_MODE=lightweight" >> $INSTALL_PLAN
    else
        echo "INSTALL_MODE=full" >> $INSTALL_PLAN
    fi
    
    # Add architecture detection
    echo "ARCH=$ARCH" >> $INSTALL_PLAN
    
    # Add recommendations as environment variables
    for i in "${!RECOMMENDATIONS[@]}"; do
        echo "# Recommendation $((i+1)): ${RECOMMENDATIONS[$i]}" >> $INSTALL_PLAN
    done
    
    chmod +x $INSTALL_PLAN
    
    echo -e "  ✓ Installation plan saved to: ${GREEN}$INSTALL_PLAN${NC}"
}

# Generate Report
generate_report() {
    REPORT_FILE="~/k8s_scan_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== Kubernetes System Scan Report ==="
        echo "Generated: $(date)"
        echo ""
        echo "=== System Information ==="
        echo "OS: $OS $VERSION"
        echo "Architecture: $ARCH"
        echo "Memory: ${TOTAL_MEM}MB"
        echo "CPU Cores: $CPU_CORES"
        echo "Device: $DEVICE"
        echo ""
        echo "=== Installed Tools ==="
        printf '%s\n' "${INSTALLED_TOOLS[@]}"
        echo ""
        echo "=== Recommendations ==="
        printf '%s\n' "${RECOMMENDATIONS[@]}"
    } > $REPORT_FILE
    
    echo -e "${BLUE}=== Scan Complete ===${NC}"
    echo -e "Report saved to: ${GREEN}$REPORT_FILE${NC}"
}

# Main execution
main() {
    scan_system
    echo ""
    scan_tools
    echo ""
    analyze_config
    echo ""
    recommend_optimizations
    echo ""
    generate_install_plan
    echo ""
    generate_report
}

main "$@"
