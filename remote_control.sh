#!/bin/bash

# Remote Control System - Fernbedienung
# Central control interface for all Kubernetes tools
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

# Configuration
REMOTE_PORT=${REMOTE_PORT:-9999}
WEB_PORT=${WEB_PORT:-8080}

# Functions
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║        🎮 Kubernetes Remote Control - Fernbedienung 🎮       ║"
    echo "║                                                              ║"
    echo "║              Complete System Management Interface            ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_menu() {
    echo -e "${BLUE}=== Main Menu ===${NC}"
    echo ""
    echo -e "${GREEN}[Installation]${NC}"
    echo "  1) Install Complete System"
    echo "  2) Install Optimized (Mobile)"
    echo "  3) Uninstall System"
    echo ""
    echo -e "${GREEN}[Management]${NC}"
    echo "  4) Start All Services"
    echo "  5) Stop All Services"
    echo "  6) Restart All Services"
    echo "  7) Check Status"
    echo ""
    echo -e "${GREEN}[Kubernetes]${NC}"
    echo "  8) Validate Cluster"
    echo "  9) Analyze Cluster"
    echo " 10) Backup Cluster"
    echo " 11) Restore Cluster"
    echo " 12) Upgrade Kubernetes"
    echo ""
    echo -e "${GREEN}[Databases]${NC}"
    echo " 13) Start Databases"
    echo " 14) Stop Databases"
    echo " 15) Database Status"
    echo ""
    echo -e "${GREEN}[AI & Tools]${NC}"
    echo " 16) AI Assistant"
    echo " 17) GitHub MCP"
    echo " 18) AI File Creator"
    echo ""
    echo -e "${GREEN}[Web Interfaces]${NC}"
    echo " 19) Open Web Dashboard"
    echo " 20) Open Database UIs"
    echo ""
    echo -e "${GREEN}[Monitoring]${NC}"
    echo " 21) Setup Monitoring"
    echo " 22) View Metrics"
    echo " 23) Performance Optimization"
    echo ""
    echo -e "${GREEN}[Troubleshooting]${NC}"
    echo " 24) Auto Troubleshoot"
    echo " 25) View Logs"
    echo ""
    echo -e "${GREEN}[System]${NC}"
    echo " 26) Auto Scan & Analyze"
    echo " 27) System Information"
    echo " 28) Remote Access Setup"
    echo ""
    echo -e "${YELLOW}[Other]${NC}"
    echo "  0) Exit"
    echo ""
    echo -ne "${CYAN}Select option: ${NC}"
}

# Service Management
start_all_services() {
    echo -e "${GREEN}Starting all services...${NC}"
    
    # Start K3s
    if command -v k3s &> /dev/null; then
        sudo systemctl start k3s 2>/dev/null || sudo k3s server &
        echo -e "  ✓ K3s started"
    fi
    
    # Start databases
    for service in postgresql mysql redis-server mongod; do
        if systemctl list-unit-files | grep -q $service; then
            sudo systemctl start $service 2>/dev/null && echo -e "  ✓ $service started"
        fi
    done
    
    # Start web dashboard
    if [ -f /usr/local/bin/k8s-dashboard ]; then
        /usr/local/bin/k8s-dashboard &
        echo -e "  ✓ Web dashboard started"
    fi
    
    echo -e "${GREEN}All services started!${NC}"
    sleep 2
}

stop_all_services() {
    echo -e "${YELLOW}Stopping all services...${NC}"
    
    # Stop K3s
    if command -v k3s &> /dev/null; then
        sudo systemctl stop k3s 2>/dev/null || sudo pkill -9 k3s
        echo -e "  ✓ K3s stopped"
    fi
    
    # Stop databases
    for service in postgresql mysql redis-server mongod; do
        if systemctl list-unit-files | grep -q $service; then
            sudo systemctl stop $service 2>/dev/null && echo -e "  ✓ $service stopped"
        fi
    done
    
    echo -e "${GREEN}All services stopped!${NC}"
    sleep 2
}

check_status() {
    echo -e "${BLUE}=== System Status ===${NC}"
    echo ""
    
    # K3s status
    if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
        echo -e "Kubernetes: ${GREEN}✓ Running${NC}"
        echo -e "  Nodes: $(kubectl get nodes --no-headers 2>/dev/null | wc -l)"
        echo -e "  Pods: $(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l)"
    else
        echo -e "Kubernetes: ${RED}✗ Not Running${NC}"
    fi
    
    echo ""
    
    # Database status
    echo -e "${BLUE}Databases:${NC}"
    for db in postgresql mysql redis-server mongod; do
        if systemctl is-active --quiet $db 2>/dev/null || pgrep -x $db &>/dev/null; then
            echo -e "  $db: ${GREEN}✓ Running${NC}"
        else
            echo -e "  $db: ${RED}✗ Stopped${NC}"
        fi
    done
    
    echo ""
    echo -e "Press Enter to continue..."
    read
}

# Remote Access Setup
setup_remote_access() {
    echo -e "${BLUE}=== Remote Access Setup ===${NC}"
    echo ""
    echo "Setting up SSH and web access..."
    
    # Enable SSH (if not already)
    if command -v sshd &> /dev/null; then
        sudo systemctl enable ssh 2>/dev/null
        sudo systemctl start ssh 2>/dev/null
        echo -e "  ✓ SSH enabled"
    fi
    
    # Get IP address
    IP=$(hostname -I | awk '{print $1}')
    echo ""
    echo -e "${GREEN}Remote Access Information:${NC}"
    echo -e "  SSH: ssh $(whoami)@$IP"
    echo -e "  Web Dashboard: http://$IP:$WEB_PORT"
    echo -e "  Remote Control: http://$IP:$REMOTE_PORT"
    echo ""
    echo -e "Press Enter to continue..."
    read
}

# Web Dashboard
open_web_dashboard() {
    echo -e "${GREEN}Opening web dashboard...${NC}"
    
    IP=$(hostname -I | awk '{print $1}')
    URL="http://$IP:$WEB_PORT"
    
    echo -e "Dashboard URL: ${CYAN}$URL${NC}"
    echo -e "Username: ${YELLOW}admin${NC}"
    echo -e "Password: ${YELLOW}admin123${NC}"
    
    # Try to open in browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "$URL" 2>/dev/null
    elif command -v open &> /dev/null; then
        open "$URL" 2>/dev/null
    elif command -v termux-open-url &> /dev/null; then
        termux-open-url "$URL"
    fi
    
    echo ""
    echo -e "Press Enter to continue..."
    read
}

# System Info
show_system_info() {
    echo -e "${BLUE}=== System Information ===${NC}"
    echo ""
    
    # OS Info
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "OS: ${GREEN}$NAME $VERSION_ID${NC}"
    fi
    
    # Architecture
    echo -e "Architecture: ${GREEN}$(uname -m)${NC}"
    
    # Memory
    echo -e "Memory: ${GREEN}$(free -h | awk '/^Mem:/{print $2}')${NC}"
    
    # CPU
    echo -e "CPU Cores: ${GREEN}$(nproc)${NC}"
    
    # Disk
    echo -e "Disk: ${GREEN}$(df -h / | awk 'NR==2{print $4}') free${NC}"
    
    # Uptime
    echo -e "Uptime: ${GREEN}$(uptime -p)${NC}"
    
    echo ""
    echo -e "Press Enter to continue..."
    read
}

# Main loop
main() {
    while true; do
        show_banner
        show_menu
        read choice
        
        case $choice in
            1) bash install_k8s_complete.sh ;;
            2) bash install_k8s_optimized.sh ;;
            3) bash uninstall_k8s.sh ;;
            4) start_all_services ;;
            5) stop_all_services ;;
            6) stop_all_services && start_all_services ;;
            7) check_status ;;
            8) bash validate_k8s.sh ;;
            9) bash analyze_k8s.sh ;;
            10) bash backup_k8s.sh backup ;;
            11) bash backup_k8s.sh restore ;;
            12) bash upgrade_k8s.sh ;;
            13) for db in postgresql mysql redis-server mongod; do sudo systemctl start $db 2>/dev/null; done ;;
            14) for db in postgresql mysql redis-server mongod; do sudo systemctl stop $db 2>/dev/null; done ;;
            15) for db in postgresql mysql redis-server mongod; do systemctl status $db 2>/dev/null; done | less ;;
            16) ai-assistant ;;
            17) ai-github ;;
            18) ai-create-file ;;
            19) open_web_dashboard ;;
            20) echo "Database UIs available at ports 8081-8085" && sleep 2 ;;
            21) bash setup_monitoring.sh ;;
            22) kubectl top nodes && kubectl top pods --all-namespaces ;;
            23) bash optimize_performance.sh ;;
            24) bash troubleshoot_k8s.sh --auto-fix ;;
            25) kubectl logs --tail=100 -n kube-system --all-containers=true | less ;;
            26) bash auto_scan_analyze.sh ;;
            27) show_system_info ;;
            28) setup_remote_access ;;
            0) echo -e "${GREEN}Goodbye!${NC}" && exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}" && sleep 1 ;;
        esac
    done
}

# Run
if [ "$1" == "--daemon" ]; then
    # Start as web service
    echo "Starting remote control web service on port $REMOTE_PORT..."
    # Here you would start a simple web server
    echo "Remote control available at: http://$(hostname -I | awk '{print $1}'):$REMOTE_PORT"
else
    # Interactive mode
    main
fi
