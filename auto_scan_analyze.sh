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
NC='\033[0m'

echo -e "${BLUE}=== Auto Scan & Analyze System ===${NC}"

# Scan System
scan_system() {
    echo -e "${GREEN}[1/5] Scanning system...${NC}"
    
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
    
    echo -e "  OS: ${GREEN}$OS $VERSION${NC}"
    echo -e "  Architecture: ${GREEN}$ARCH${NC}"
    echo -e "  Memory: ${GREEN}${TOTAL_MEM}MB${NC}"
    echo -e "  CPU Cores: ${GREEN}$CPU_CORES${NC}"
    echo -e "  Device: ${GREEN}$DEVICE${NC}"
}

# Scan Installed Tools
scan_tools() {
    echo -e "${GREEN}[2/5] Scanning installed tools...${NC}"
    
    INSTALLED_TOOLS=()
    
    # Check for kubectl
    if command -v kubectl &> /dev/null; then
        INSTALLED_TOOLS+=("kubectl")
        echo -e "  ✓ kubectl: ${GREEN}$(kubectl version --client --short 2>/dev/null | head -n1)${NC}"
    fi
    
    # Check for K3s
    if command -v k3s &> /dev/null; then
        INSTALLED_TOOLS+=("k3s")
        echo -e "  ✓ K3s: ${GREEN}$(k3s --version | head -n1)${NC}"
    fi
    
    # Check for Docker
    if command -v docker &> /dev/null; then
        INSTALLED_TOOLS+=("docker")
        echo -e "  ✓ Docker: ${GREEN}$(docker --version)${NC}"
    fi
    
    # Check for databases
    if command -v psql &> /dev/null; then
        INSTALLED_TOOLS+=("postgresql")
        echo -e "  ✓ PostgreSQL: ${GREEN}Installed${NC}"
    fi
    
    if command -v mysql &> /dev/null; then
        INSTALLED_TOOLS+=("mysql")
        echo -e "  ✓ MySQL: ${GREEN}Installed${NC}"
    fi
    
    if command -v redis-cli &> /dev/null; then
        INSTALLED_TOOLS+=("redis")
        echo -e "  ✓ Redis: ${GREEN}Installed${NC}"
    fi
    
    if command -v mongo &> /dev/null || command -v mongosh &> /dev/null; then
        INSTALLED_TOOLS+=("mongodb")
        echo -e "  ✓ MongoDB: ${GREEN}Installed${NC}"
    fi
    
    # Check for AI tools
    if [ -d ~/.termux-ai ]; then
        INSTALLED_TOOLS+=("ai-assistant")
        echo -e "  ✓ AI Assistant: ${GREEN}Installed${NC}"
    fi
    
    # Check for web dashboard
    if [ -f /usr/local/bin/k8s-dashboard ]; then
        INSTALLED_TOOLS+=("web-dashboard")
        echo -e "  ✓ Web Dashboard: ${GREEN}Installed${NC}"
    fi
    
    echo -e "  Total tools: ${GREEN}${#INSTALLED_TOOLS[@]}${NC}"
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
