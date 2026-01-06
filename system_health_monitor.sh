#!/bin/bash

# System Health Monitor
# 24/7 monitoring daemon for complete system health
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
MONITOR_INTERVAL="${MONITOR_INTERVAL:-60}"  # seconds
LOG_DIR="${LOG_DIR:-$HOME/.health-monitor}"
PID_FILE="$LOG_DIR/monitor.pid"
LOG_FILE="$LOG_DIR/monitor.log"
METRICS_FILE="$LOG_DIR/metrics.txt"

# Thresholds
CPU_THRESHOLD="${CPU_THRESHOLD:-80}"
MEMORY_THRESHOLD="${MEMORY_THRESHOLD:-85}"
DISK_THRESHOLD="${DISK_THRESHOLD:-90}"

mkdir -p "$LOG_DIR"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Check if monitoring is running
is_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Collect system metrics
collect_metrics() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0")
    
    # Memory usage
    local mem_total=$(free -m | awk 'NR==2{print $2}')
    local mem_used=$(free -m | awk 'NR==2{print $3}')
    local mem_percent=$(awk "BEGIN {printf \"%.1f\", ($mem_used/$mem_total)*100}")
    
    # Disk usage
    local disk_usage=$(df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1)
    
    # Network connections
    local net_connections=$(ss -tun | wc -l || echo "0")
    
    # Write metrics
    cat > "$METRICS_FILE" << EOF
# HELP system_cpu_usage CPU usage percentage
# TYPE system_cpu_usage gauge
system_cpu_usage $cpu_usage

# HELP system_memory_usage Memory usage percentage
# TYPE system_memory_usage gauge
system_memory_usage $mem_percent

# HELP system_disk_usage Disk usage percentage
# TYPE system_disk_usage gauge
system_disk_usage $disk_usage

# HELP system_network_connections Active network connections
# TYPE system_network_connections gauge
system_network_connections $net_connections

# Timestamp
timestamp $timestamp
EOF
    
    # Check thresholds and alert
    check_thresholds "$cpu_usage" "$mem_percent" "$disk_usage"
}

# Check thresholds
check_thresholds() {
    local cpu=$1
    local mem=$2
    local disk=$3
    
    if (( $(echo "$cpu > $CPU_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        log "⚠️  HIGH CPU USAGE: ${cpu}%"
    fi
    
    if (( $(echo "$mem > $MEMORY_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        log "⚠️  HIGH MEMORY USAGE: ${mem}%"
    fi
    
    if [[ $disk -gt $DISK_THRESHOLD ]]; then
        log "⚠️  HIGH DISK USAGE: ${disk}%"
    fi
}

# Check service health
check_services() {
    # Check K3s/Kubernetes
    if command -v kubectl &>/dev/null; then
        if kubectl cluster-info &>/dev/null; then
            log "✓ Kubernetes cluster: HEALTHY"
        else
            log "✗ Kubernetes cluster: UNHEALTHY"
        fi
    fi
    
    # Check databases
    for service in postgresql mysql redis-server mongod; do
        if systemctl is-active --quiet "$service" 2>/dev/null || pgrep -x "$service" &>/dev/null; then
            log "✓ $service: RUNNING"
        fi
    done
}

# Monitor loop
monitor_loop() {
    log "Starting health monitor (PID: $$)"
    echo $$ > "$PID_FILE"
    
    while true; do
        collect_metrics
        check_services
        sleep "$MONITOR_INTERVAL"
    done
}

# Start monitoring
start_monitor() {
    if is_running; then
        echo -e "${YELLOW}Monitor is already running${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Starting system health monitor...${NC}"
    nohup bash -c "$(declare -f monitor_loop collect_metrics check_thresholds check_services log); monitor_loop" > /dev/null 2>&1 &
    
    sleep 2
    if is_running; then
        echo -e "${GREEN}✓${NC} Monitor started successfully"
        echo "PID: $(cat "$PID_FILE")"
        echo "Logs: $LOG_FILE"
        echo "Metrics: $METRICS_FILE"
    else
        echo -e "${RED}✗${NC} Failed to start monitor"
        return 1
    fi
}

# Stop monitoring
stop_monitor() {
    if ! is_running; then
        echo -e "${YELLOW}Monitor is not running${NC}"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    echo -e "${BLUE}Stopping monitor (PID: $pid)...${NC}"
    
    kill "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
    
    echo -e "${GREEN}✓${NC} Monitor stopped"
}

# Show status
show_status() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║              📊 System Health Monitor Status 📊                      ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    if is_running; then
        local pid=$(cat "$PID_FILE")
        local uptime=$(ps -p "$pid" -o etime= 2>/dev/null || echo 'N/A')
        
        echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║ 🟢 Daemon Status                                                      ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        echo -e "  Status:        ${GREEN}● RUNNING${NC}"
        echo -e "  PID:           ${GREEN}$pid${NC}"
        echo -e "  Uptime:        ${GREEN}$uptime${NC}"
        echo -e "  Interval:      ${GREEN}${MONITOR_INTERVAL}s${NC}"
        echo ""
    else
        echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║ 🔴 Daemon Status                                                      ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        echo -e "  Status:        ${YELLOW}● STOPPED${NC}"
        echo ""
    fi
    
    if [[ -f "$METRICS_FILE" ]]; then
        echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║ 📈 Current Metrics                                                    ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        
        # Parse metrics
        local cpu=$(grep "^system_cpu_usage" "$METRICS_FILE" | awk '{print $2}')
        local mem=$(grep "^system_memory_usage" "$METRICS_FILE" | awk '{print $2}')
        local disk=$(grep "^system_disk_usage" "$METRICS_FILE" | awk '{print $2}')
        local conns=$(grep "^system_network_connections" "$METRICS_FILE" | awk '{print $2}')
        local timestamp=$(grep "^timestamp" "$METRICS_FILE" | cut -d' ' -f2-)
        
        # Display with color coding
        local cpu_color="${GREEN}"
        [[ $(echo "$cpu > $CPU_THRESHOLD" | bc -l 2>/dev/null || echo 0) -eq 1 ]] && cpu_color="${RED}"
        
        local mem_color="${GREEN}"
        [[ $(echo "$mem > $MEMORY_THRESHOLD" | bc -l 2>/dev/null || echo 0) -eq 1 ]] && mem_color="${RED}"
        
        local disk_color="${GREEN}"
        [[ "$disk" -gt "$DISK_THRESHOLD" ]] && disk_color="${RED}"
        
        echo -e "  CPU Usage:     ${cpu_color}${cpu}%${NC} (threshold: ${CPU_THRESHOLD}%)"
        echo -e "  Memory Usage:  ${mem_color}${mem}%${NC} (threshold: ${MEMORY_THRESHOLD}%)"
        echo -e "  Disk Usage:    ${disk_color}${disk}%${NC} (threshold: ${DISK_THRESHOLD}%)"
        echo -e "  Connections:   ${GREEN}${conns}${NC}"
        echo ""
        echo -e "  Last Update:   ${CYAN}${timestamp}${NC}"
        echo ""
    fi
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ 📁 Log Files                                                          ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "  Monitor Log:   ${CYAN}$LOG_FILE${NC}"
    echo -e "  Metrics File:  ${CYAN}$METRICS_FILE${NC}"
    echo ""
}

# Show metrics
show_metrics() {
    if [[ ! -f "$METRICS_FILE" ]]; then
        echo -e "${YELLOW}No metrics available. Start the monitor first.${NC}"
        return 1
    fi
    
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                    📊 System Health Metrics 📊                       ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # Parse and display metrics with visual bars
    local cpu=$(grep "^system_cpu_usage" "$METRICS_FILE" | awk '{print $2}')
    local mem=$(grep "^system_memory_usage" "$METRICS_FILE" | awk '{print $2}')
    local disk=$(grep "^system_disk_usage" "$METRICS_FILE" | awk '{print $2}')
    local conns=$(grep "^system_network_connections" "$METRICS_FILE" | awk '{print $2}')
    local timestamp=$(grep "^timestamp" "$METRICS_FILE" | cut -d' ' -f2-)
    
    # Generate progress bars
    generate_metric_bar() {
        local value=$1
        local threshold=$2
        local label=$3
        local bar_length=40
        local filled=$(awk "BEGIN {printf \"%.0f\", ($value/100)*$bar_length}")
        local empty=$((bar_length - filled))
        
        # Color based on threshold
        local color="${GREEN}"
        [[ $(echo "$value > $threshold" | bc -l 2>/dev/null || echo 0) -eq 1 ]] && color="${RED}"
        [[ $(echo "$value > ($threshold - 10)" | bc -l 2>/dev/null || echo 0) -eq 1 ]] && [[ $(echo "$value <= $threshold" | bc -l 2>/dev/null || echo 0) -eq 1 ]] && color="${YELLOW}"
        
        printf "  %-15s ${color}[" "$label"
        printf "█%.0s" $(seq 1 $filled)
        printf "░%.0s" $(seq 1 $empty)
        printf "] %.1f%%${NC}\n" "$value"
    }
    
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
    generate_metric_bar "$cpu" "$CPU_THRESHOLD" "CPU"
    generate_metric_bar "$mem" "$MEMORY_THRESHOLD" "Memory"
    generate_metric_bar "$disk" "$DISK_THRESHOLD" "Disk"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}Network Connections:${NC} ${GREEN}$conns${NC}"
    echo -e "  ${CYAN}Last Update:${NC}         ${GREEN}$timestamp${NC}"
    echo ""
    
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC} ⚠️  Alert Thresholds:"
    echo -e "${YELLOW}║${NC}   CPU:    ${CYAN}${CPU_THRESHOLD}%${NC}"
    echo -e "${YELLOW}║${NC}   Memory: ${CYAN}${MEMORY_THRESHOLD}%${NC}"
    echo -e "${YELLOW}║${NC}   Disk:   ${CYAN}${DISK_THRESHOLD}%${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main
case "${1:-}" in
    start)
        start_monitor
        ;;
    stop)
        stop_monitor
        ;;
    restart)
        stop_monitor
        sleep 1
        start_monitor
        ;;
    status)
        show_status
        ;;
    metrics)
        show_metrics
        ;;
    *)
        echo -e "${CYAN}"
        echo "╔═══════════════════════════════════════════════════════════════════════╗"
        echo "║              🏥 System Health Monitor - Usage 🏥                     ║"
        echo "╚═══════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo ""
        echo -e "${YELLOW}Usage:${NC} $0 ${CYAN}{start|stop|restart|status|metrics}${NC}"
        echo ""
        echo -e "${GREEN}Commands:${NC}"
        echo -e "  ${CYAN}start${NC}    - 🚀 Start the health monitor daemon"
        echo -e "  ${CYAN}stop${NC}     - ⏹️  Stop the health monitor daemon"
        echo -e "  ${CYAN}restart${NC}  - 🔄 Restart the health monitor daemon"
        echo -e "  ${CYAN}status${NC}   - 📊 Show monitor status and current metrics"
        echo -e "  ${CYAN}metrics${NC}  - 📈 Display current metrics with visual bars"
        echo ""
        echo -e "${BLUE}Examples:${NC}"
        echo -e "  $0 start     # Start monitoring"
        echo -e "  $0 status    # Check daemon status"
        echo -e "  $0 metrics   # View visual metrics"
        echo ""
        exit 1
        ;;
esac
