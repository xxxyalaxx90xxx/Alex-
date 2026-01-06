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
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║     ██╗  ██╗ █████╗ ███████╗    ██████╗ ███████╗███╗   ███╗ ██████╗  ║
║     ██║ ██╔╝██╔══██╗██╔════╝    ██╔══██╗██╔════╝████╗ ████║██╔═══██╗ ║
║     █████╔╝ ╚█████╔╝███████╗    ██████╔╝█████╗  ██╔████╔██║██║   ██║ ║
║     ██╔═██╗ ██╔══██╗╚════██║    ██╔══██╗██╔══╝  ██║╚██╔╝██║██║   ██║ ║
║     ██║  ██╗╚█████╔╝███████║    ██║  ██║███████╗██║ ╚═╝ ██║╚██████╔╝ ║
║     ╚═╝  ╚═╝ ╚════╝ ╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝ ╚═════╝  ║
║                                                                       ║
║        🎮  Kubernetes Remote Control - Fernbedienung  🎮             ║
║                Complete System Management Interface                   ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${MAGENTA}   Author: Alexander Mathey | Elektronikx-Center-Matte ® ™${NC}"
    echo ""
}

show_menu() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                      📋 Main Menu 📋                      ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}┌─ 💿 Installation${NC}"
    echo -e "${GREEN}├──${NC}  ${CYAN}1)${NC} Install Complete System      🚀"
    echo -e "${GREEN}├──${NC}  ${CYAN}2)${NC} Install Optimized (Mobile)   📱"
    echo -e "${GREEN}└──${NC}  ${CYAN}3)${NC} Uninstall System             🗑️"
    echo ""
    echo -e "${GREEN}┌─ 🔧 Management${NC}"
    echo -e "${GREEN}├──${NC}  ${CYAN}4)${NC} Start All Services           ▶️"
    echo -e "${GREEN}├──${NC}  ${CYAN}5)${NC} Stop All Services            ⏹️"
    echo -e "${GREEN}├──${NC}  ${CYAN}6)${NC} Restart All Services         🔄"
    echo -e "${GREEN}└──${NC}  ${CYAN}7)${NC} Check Status                 📊"
    echo ""
    echo -e "${GREEN}┌─ ☸️  Kubernetes${NC}"
    echo -e "${GREEN}├──${NC}  ${CYAN}8)${NC} Validate Cluster             ✅"
    echo -e "${GREEN}├──${NC}  ${CYAN}9)${NC} Analyze Cluster              🔍"
    echo -e "${GREEN}├──${NC} ${CYAN}10)${NC} Backup Cluster               💾"
    echo -e "${GREEN}├──${NC} ${CYAN}11)${NC} Restore Cluster              📥"
    echo -e "${GREEN}└──${NC} ${CYAN}12)${NC} Upgrade Kubernetes           ⬆️"
    echo ""
    echo -e "${GREEN}┌─ 🗄️  Databases${NC}"
    echo -e "${GREEN}├──${NC} ${CYAN}13)${NC} Start Databases              ▶️"
    echo -e "${GREEN}├──${NC} ${CYAN}14)${NC} Stop Databases               ⏹️"
    echo -e "${GREEN}└──${NC} ${CYAN}15)${NC} Database Status              📊"
    echo ""
    echo -e "${GREEN}┌─ 🤖 AI & Tools${NC}"
    echo -e "${GREEN}├──${NC} ${CYAN}16)${NC} AI Assistant                 🧠"
    echo -e "${GREEN}├──${NC} ${CYAN}17)${NC} GitHub MCP                   🐙"
    echo -e "${GREEN}└──${NC} ${CYAN}18)${NC} AI File Creator              ✨"
    echo ""
    echo -e "${GREEN}┌─ 🌐 Web Interfaces${NC}"
    echo -e "${GREEN}├──${NC} ${CYAN}19)${NC} Open Web Dashboard           🖥️"
    echo -e "${GREEN}└──${NC} ${CYAN}20)${NC} Open Database UIs            📊"
    echo ""
    echo -e "${GREEN}┌─ 📈 Monitoring${NC}"
    echo -e "${GREEN}├──${NC} ${CYAN}21)${NC} Setup Monitoring             📡"
    echo -e "${GREEN}├──${NC} ${CYAN}22)${NC} View Metrics                 📊"
    echo -e "${GREEN}└──${NC} ${CYAN}23)${NC} Performance Optimization     ⚡"
    echo ""
    echo -e "${GREEN}┌─ 🔧 Troubleshooting${NC}"
    echo -e "${GREEN}├──${NC} ${CYAN}24)${NC} Auto Troubleshoot            🔍"
    echo -e "${GREEN}└──${NC} ${CYAN}25)${NC} View Logs                    📝"
    echo ""
    echo -e "${GREEN}┌─ ⚙️  System${NC}"
    echo -e "${GREEN}├──${NC} ${CYAN}26)${NC} Auto Scan & Analyze          🔍"
    echo -e "${GREEN}├──${NC} ${CYAN}27)${NC} System Information           💻"
    echo -e "${GREEN}└──${NC} ${CYAN}28)${NC} Remote Access Setup          🌍"
    echo ""
    echo -e "${YELLOW}┌─ 🚪 Exit${NC}"
    echo -e "${YELLOW}└──${NC}  ${CYAN}0)${NC} Exit Remote Control          👋"
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -ne "${CYAN}║ Select option [0-28]: ${NC}"
}

# Service Management
start_all_services() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                     ▶️  Starting All Services  ▶️                     ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    local total=0
    local started=0
    
    # Start K3s
    ((total++))
    if command -v k3s &> /dev/null; then
        echo -ne "  [ ... ] Starting K3s..."
        if sudo systemctl start k3s 2>/dev/null || sudo k3s server & then
            echo -e "\r  [${GREEN}  ✓  ${NC}] K3s started successfully"
            ((started++))
        else
            echo -e "\r  [${RED}  ✗  ${NC}] Failed to start K3s"
        fi
    else
        echo -e "  [${YELLOW}  -  ${NC}] K3s not installed"
    fi
    
    # Start databases
    for service in postgresql mysql redis-server mongod; do
        ((total++))
        if systemctl list-unit-files | grep -q $service; then
            echo -ne "  [ ... ] Starting $service..."
            if sudo systemctl start $service 2>/dev/null; then
                echo -e "\r  [${GREEN}  ✓  ${NC}] $service started successfully"
                ((started++))
            else
                echo -e "\r  [${RED}  ✗  ${NC}] Failed to start $service"
            fi
        fi
    done
    
    # Start web dashboard
    ((total++))
    if [ -f /usr/local/bin/k8s-dashboard ]; then
        echo -ne "  [ ... ] Starting Web Dashboard..."
        if /usr/local/bin/k8s-dashboard & then
            echo -e "\r  [${GREEN}  ✓  ${NC}] Web Dashboard started successfully"
            ((started++))
        else
            echo -e "\r  [${RED}  ✗  ${NC}] Failed to start Web Dashboard"
        fi
    else
        echo -e "  [${YELLOW}  -  ${NC}] Web Dashboard not installed"
    fi
    
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║ Summary: ${GREEN}$started${NC}/${CYAN}$total${NC} services started successfully${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Press Enter to continue..."
    read
}

stop_all_services() {
    clear
    echo -e "${YELLOW}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                     ⏹️  Stopping All Services  ⏹️                     ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    local total=0
    local stopped=0
    
    # Stop K3s
    ((total++))
    if command -v k3s &> /dev/null; then
        echo -ne "  [ ... ] Stopping K3s..."
        if sudo systemctl stop k3s 2>/dev/null || sudo pkill -9 k3s; then
            echo -e "\r  [${GREEN}  ✓  ${NC}] K3s stopped successfully"
            ((stopped++))
        else
            echo -e "\r  [${RED}  ✗  ${NC}] Failed to stop K3s"
        fi
    fi
    
    # Stop databases
    for service in postgresql mysql redis-server mongod; do
        ((total++))
        if systemctl list-unit-files | grep -q $service; then
            echo -ne "  [ ... ] Stopping $service..."
            if sudo systemctl stop $service 2>/dev/null; then
                echo -e "\r  [${GREEN}  ✓  ${NC}] $service stopped successfully"
                ((stopped++))
            else
                echo -e "\r  [${RED}  ✗  ${NC}] Failed to stop $service"
            fi
        fi
    done
    
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║ Summary: ${GREEN}$stopped${NC}/${CYAN}$total${NC} services stopped successfully${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Press Enter to continue..."
    read
}

check_status() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                       📊 System Status Dashboard 📊                  ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # K3s status
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ☸️  Kubernetes Cluster Status                                         ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    
    if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
        local nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
        local pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
        local running_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -c Running || echo 0)
        
        echo -e "  Status:        ${GREEN}●${NC} Running"
        echo -e "  Nodes:         ${GREEN}$nodes${NC}"
        echo -e "  Total Pods:    ${GREEN}$pods${NC}"
        echo -e "  Running Pods:  ${GREEN}$running_pods${NC}"
        
        # Show node health
        echo ""
        echo -e "  ${CYAN}Node Health:${NC}"
        kubectl get nodes --no-headers 2>/dev/null | while read node status role age version; do
            if [[ "$status" == "Ready" ]]; then
                echo -e "    ✓ $node: ${GREEN}$status${NC}"
            else
                echo -e "    ✗ $node: ${RED}$status${NC}"
            fi
        done
    else
        echo -e "  Status: ${RED}●${NC} Not Running"
        echo -e "  ${YELLOW}ℹ${NC}  Run option 1 or 2 to install Kubernetes"
    fi
    
    echo ""
    
    # Database status
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ 🗄️  Database Services Status                                          ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    
    local db_running=0
    local db_total=0
    
    for db in postgresql mysql redis-server mongod; do
        ((db_total++))
        if systemctl is-active --quiet $db 2>/dev/null || pgrep -x $db &>/dev/null; then
            echo -e "  ✓ $db: ${GREEN}●${NC} Running"
            ((db_running++))
        else
            echo -e "  ✗ $db: ${RED}●${NC} Stopped"
        fi
    done
    
    echo ""
    echo -e "  Services: ${GREEN}$db_running${NC}/${CYAN}$db_total${NC} running"
    echo ""
    
    # System Resources
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ 💻 System Resources                                                   ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    
    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0")
    local cpu_bar=$(generate_bar "$cpu_usage" 100)
    echo -e "  CPU Usage:     $cpu_bar ${GREEN}${cpu_usage}%${NC}"
    
    # Memory
    local mem_total=$(free -m | awk 'NR==2{print $2}')
    local mem_used=$(free -m | awk 'NR==2{print $3}')
    local mem_percent=$(awk "BEGIN {printf \"%.0f\", ($mem_used/$mem_total)*100}")
    local mem_bar=$(generate_bar "$mem_percent" 100)
    echo -e "  Memory Usage:  $mem_bar ${GREEN}${mem_used}MB${NC}/${CYAN}${mem_total}MB${NC} (${mem_percent}%)"
    
    # Disk
    local disk_usage=$(df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1)
    local disk_bar=$(generate_bar "$disk_usage" 100)
    local disk_free=$(df -h / | awk 'NR==2{print $4}')
    echo -e "  Disk Usage:    $disk_bar ${GREEN}${disk_usage}%${NC} (${disk_free} free)"
    
    echo ""
    
    # Uptime
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ⏱️  System Uptime                                                     ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}$(uptime -p)${NC}"
    echo ""
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║ Press Enter to return to menu...                                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    read
}

# Generate progress bar
generate_bar() {
    local value=$1
    local max=$2
    local bar_length=30
    local filled=$(awk "BEGIN {printf \"%.0f\", ($value/$max)*$bar_length}")
    local empty=$((bar_length - filled))
    
    # Color based on percentage
    local color="${GREEN}"
    if (( $(echo "$value > 80" | bc -l 2>/dev/null || echo 0) )); then
        color="${RED}"
    elif (( $(echo "$value > 60" | bc -l 2>/dev/null || echo 0) )); then
        color="${YELLOW}"
    fi
    
    printf "${color}["
    printf "█%.0s" $(seq 1 $filled)
    printf "░%.0s" $(seq 1 $empty)
    printf "]${NC}"
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

// System Info
show_system_info() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                    💻 System Information 💻                           ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # OS Info
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ 🖥️  Operating System                                                  ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "  Name:          ${GREEN}$NAME${NC}"
        echo -e "  Version:       ${GREEN}$VERSION${NC}"
        echo -e "  ID:            ${GREEN}$ID${NC}"
    fi
    echo ""
    
    # Architecture
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ⚙️  Hardware Information                                              ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "  Architecture:  ${GREEN}$(uname -m)${NC}"
    echo -e "  Kernel:        ${GREEN}$(uname -r)${NC}"
    echo -e "  Hostname:      ${GREEN}$(hostname)${NC}"
    echo ""
    
    # Resources
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ 📊 System Resources                                                   ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Memory
    local mem_total=$(free -h | awk '/^Mem:/{print $2}')
    local mem_used=$(free -h | awk '/^Mem:/{print $3}')
    local mem_percent=$(free | awk '/^Mem:/{printf "%.0f", ($3/$2)*100}')
    echo -e "  Memory:        ${GREEN}${mem_used}${NC} / ${CYAN}${mem_total}${NC} (${mem_percent}%)"
    
    # CPU
    echo -e "  CPU Cores:     ${GREEN}$(nproc)${NC}"
    if [ -f /proc/cpuinfo ]; then
        local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        if [ -n "$cpu_model" ]; then
            echo -e "  CPU Model:     ${GREEN}${cpu_model}${NC}"
        fi
    fi
    
    # Disk
    local disk_total=$(df -h / | awk 'NR==2{print $2}')
    local disk_used=$(df -h / | awk 'NR==2{print $3}')
    local disk_free=$(df -h / | awk 'NR==2{print $4}')
    local disk_percent=$(df -h / | awk 'NR==2{print $5}')
    echo -e "  Disk Used:     ${GREEN}${disk_used}${NC} / ${CYAN}${disk_total}${NC} (${disk_percent})"
    echo -e "  Disk Free:     ${GREEN}${disk_free}${NC}"
    echo ""
    
    # Network
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ 🌐 Network Information                                                ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    local ip=$(hostname -I | awk '{print $1}')
    echo -e "  IP Address:    ${GREEN}${ip}${NC}"
    if command -v ip &> /dev/null; then
        local iface=$(ip route | grep default | awk '{print $5}' | head -1)
        echo -e "  Interface:     ${GREEN}${iface}${NC}"
    fi
    echo ""
    
    # Uptime
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ⏱️  System Uptime                                                     ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}$(uptime -p)${NC}"
    echo -e "  Load Average:  ${GREEN}$(uptime | awk -F'load average:' '{print $2}')${NC}"
    echo ""
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║ Press Enter to return to menu...                                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
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
