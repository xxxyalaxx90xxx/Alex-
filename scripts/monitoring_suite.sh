#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XAI v4.0 - MONITORING SUITE
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Production-grade monitoring and alerting system
# ==============================================================================

set -euo pipefail

# Farben
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

MONITOR_DIR="$HOME/.xai_monitoring"
ALERT_LOG="$MONITOR_DIR/alerts.log"
METRICS_LOG="$MONITOR_DIR/metrics.log"

# Thresholds
CPU_THRESHOLD=80
RAM_THRESHOLD=85
DISK_THRESHOLD=90

mkdir -p "$MONITOR_DIR"

show_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          XTREME XAI v4.0 - MONITORING SUITE                      ║${NC}"
    echo -e "${CYAN}║          © Elektronikx-Center-Matte ®                            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  1) Real-time Dashboard"
    echo "  2) Resource Monitor"
    echo "  3) Alert Configuration"
    echo "  4) View Metrics History"
    echo "  5) Health Check"
    echo ""
    echo "  0) Zurück"
    echo ""
    echo -n "Auswahl: "
}

realtime_dashboard() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                   REAL-TIME DASHBOARD                            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    while true; do
        clear
        echo -e "${CYAN}Real-Time System Monitor${NC} - $(date '+%Y-%m-%d %H:%M:%S')"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # CPU
        if command -v top &>/dev/null; then
            CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
            if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
                echo -e "${RED}CPU:${NC} ${CPU_USAGE}% ${RED}[HIGH]${NC}"
            else
                echo -e "${GREEN}CPU:${NC} ${CPU_USAGE}%"
            fi
        else
            echo -e "${YELLOW}CPU:${NC} N/A"
        fi
        
        # RAM
        if command -v free &>/dev/null; then
            RAM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100}')
            if (( $(echo "$RAM_USAGE > $RAM_THRESHOLD" | bc -l) )); then
                echo -e "${RED}RAM:${NC} ${RAM_USAGE}% ${RED}[HIGH]${NC}"
            else
                echo -e "${GREEN}RAM:${NC} ${RAM_USAGE}%"
            fi
        else
            echo -e "${YELLOW}RAM:${NC} N/A"
        fi
        
        # Disk
        DISK_USAGE=$(df -h "$HOME" | awk 'NR==2 {print $5}' | cut -d'%' -f1)
        if [[ $DISK_USAGE -gt $DISK_THRESHOLD ]]; then
            echo -e "${RED}DISK:${NC} ${DISK_USAGE}% ${RED}[HIGH]${NC}"
        else
            echo -e "${GREEN}DISK:${NC} ${DISK_USAGE}%"
        fi
        
        # Network
        if command -v ifconfig &>/dev/null; then
            echo -e "${CYAN}NETWORK:${NC} Connected"
        else
            echo -e "${YELLOW}NETWORK:${NC} Unknown"
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Press Ctrl+C to exit"
        
        sleep 5
    done
}

resource_monitor() {
    echo -e "${CYAN}Resource Monitor${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # CPU Info
    echo -e "${CYAN}CPU Information:${NC}"
    if [[ -f "/proc/cpuinfo" ]]; then
        grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2
    fi
    echo ""
    
    # Memory Info
    echo -e "${CYAN}Memory Information:${NC}"
    if command -v free &>/dev/null; then
        free -h
    fi
    echo ""
    
    # Disk Info
    echo -e "${CYAN}Disk Information:${NC}"
    df -h "$HOME"
    echo ""
    
    # Top Processes
    echo -e "${CYAN}Top Processes (by CPU):${NC}"
    if command -v ps &>/dev/null; then
        ps aux --sort=-%cpu | head -10
    fi
    echo ""
    
    echo -n "Drücke Enter um fortzufahren..."
    read -r
}

configure_alerts() {
    echo -e "${CYAN}Alert Configuration${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Aktuelle Thresholds:"
    echo "  CPU: ${CPU_THRESHOLD}%"
    echo "  RAM: ${RAM_THRESHOLD}%"
    echo "  DISK: ${DISK_THRESHOLD}%"
    echo ""
    echo "Alert Log: $ALERT_LOG"
    echo ""
    echo -n "Drücke Enter um fortzufahren..."
    read -r
}

view_metrics() {
    echo -e "${CYAN}Metrics History${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [[ -f "$METRICS_LOG" ]]; then
        tail -50 "$METRICS_LOG"
    else
        echo "Keine Metriken vorhanden"
    fi
    
    echo ""
    echo -n "Drücke Enter um fortzufahren..."
    read -r
}

health_check() {
    echo -e "${CYAN}System Health Check${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    local status="${GREEN}HEALTHY${NC}"
    local issues=0
    
    # Check CPU
    if command -v top &>/dev/null; then
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
            echo -e "${RED}✗${NC} CPU-Auslastung zu hoch: ${CPU_USAGE}%"
            ((issues++))
        else
            echo -e "${GREEN}✓${NC} CPU-Auslastung OK: ${CPU_USAGE}%"
        fi
    fi
    
    # Check RAM
    if command -v free &>/dev/null; then
        RAM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100}')
        if (( $(echo "$RAM_USAGE > $RAM_THRESHOLD" | bc -l) )); then
            echo -e "${RED}✗${NC} RAM-Auslastung zu hoch: ${RAM_USAGE}%"
            ((issues++))
        else
            echo -e "${GREEN}✓${NC} RAM-Auslastung OK: ${RAM_USAGE}%"
        fi
    fi
    
    # Check Disk
    DISK_USAGE=$(df -h "$HOME" | awk 'NR==2 {print $5}' | cut -d'%' -f1)
    if [[ $DISK_USAGE -gt $DISK_THRESHOLD ]]; then
        echo -e "${RED}✗${NC} Festplatten-Auslastung zu hoch: ${DISK_USAGE}%"
        ((issues++))
    else
        echo -e "${GREEN}✓${NC} Festplatten-Auslastung OK: ${DISK_USAGE}%"
    fi
    
    echo ""
    if [[ $issues -eq 0 ]]; then
        echo -e "Status: ${GREEN}HEALTHY${NC} - Keine Probleme erkannt"
    else
        echo -e "Status: ${RED}ISSUES DETECTED${NC} - $issues Problem(e) gefunden"
    fi
    
    echo ""
    echo -n "Drücke Enter um fortzufahren..."
    read -r
}

while true; do
    show_menu
    read -r choice
    
    case $choice in
        1) realtime_dashboard ;;
        2) resource_monitor ;;
        3) configure_alerts ;;
        4) view_metrics ;;
        5) health_check ;;
        0) break ;;
        *) echo -e "${RED}Ungültige Auswahl${NC}" ;;
    esac
done
