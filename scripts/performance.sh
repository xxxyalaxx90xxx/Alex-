#!/bin/bash

################################################################################
# Performance Monitoring Script v4.0 (erweitert)
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Erweitertes Performance-Monitoring für XTREME-XAI-ULTIMATE
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
REFRESH_RATE=2
LOG_DIR="${HOME}/xtreme_ai_system/logs"
PERF_LOG="${LOG_DIR}/performance_$(date +%Y%m%d).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Header
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${BOLD}XTREME XAI Performance Monitor v4.0${NC}                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}      © Elektronikx-Center-Matte ® | Alexander Mathey ©      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Get CPU usage
get_cpu_usage() {
    # Method 1: Using top
    if command -v top &>/dev/null; then
        top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%.1f", 100 - $1}' 2>/dev/null
    else
        # Method 2: Using /proc/stat
        local cpu1=($(cat /proc/stat | grep '^cpu '))
        sleep 0.5
        local cpu2=($(cat /proc/stat | grep '^cpu '))
        
        local idle1=${cpu1[4]}
        local idle2=${cpu2[4]}
        
        local total1=0
        local total2=0
        for value in "${cpu1[@]:1}"; do
            total1=$((total1 + value))
        done
        for value in "${cpu2[@]:1}"; do
            total2=$((total2 + value))
        done
        
        local diff_idle=$((idle2 - idle1))
        local diff_total=$((total2 - total1))
        local cpu_usage=$((100 * (diff_total - diff_idle) / diff_total))
        
        echo "$cpu_usage"
    fi
}

# Get CPU temperature
get_cpu_temp() {
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        echo "$((temp / 1000))"
    else
        echo "N/A"
    fi
}

# Get CPU frequency
get_cpu_freq() {
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
        local freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
        echo "$((freq / 1000))"
    else
        echo "N/A"
    fi
}

# Get memory usage
get_memory_usage() {
    free | awk '/^Mem:/ {printf "%.1f|%.1f|%.0f", $3/1024/1024, $2/1024/1024, $3/$2 * 100}'
}

# Get swap usage
get_swap_usage() {
    free | awk '/^Swap:/ {if ($2 > 0) printf "%.1f|%.1f|%.0f", $3/1024/1024, $2/1024/1024, $3/$2 * 100; else print "0|0|0"}'
}

# Get disk usage
get_disk_usage() {
    df -h "$HOME" | awk 'NR==2 {printf "%s|%s|%s", $3, $2, $5}'
}

# Get network stats
get_network_stats() {
    local rx_bytes1=$(cat /sys/class/net/*/statistics/rx_bytes | awk '{sum+=$1} END {print sum}')
    local tx_bytes1=$(cat /sys/class/net/*/statistics/tx_bytes | awk '{sum+=$1} END {print sum}')
    
    sleep 1
    
    local rx_bytes2=$(cat /sys/class/net/*/statistics/rx_bytes | awk '{sum+=$1} END {print sum}')
    local tx_bytes2=$(cat /sys/class/net/*/statistics/tx_bytes | awk '{sum+=$1} END {print sum}')
    
    local rx_rate=$((rx_bytes2 - rx_bytes1))
    local tx_rate=$((tx_bytes2 - tx_bytes1))
    
    # Convert to KB/s
    rx_rate=$((rx_rate / 1024))
    tx_rate=$((tx_rate / 1024))
    
    echo "${rx_rate}|${tx_rate}"
}

# Get top processes by CPU
get_top_cpu_processes() {
    ps aux --sort=-%cpu | head -6 | tail -5
}

# Get top processes by memory
get_top_mem_processes() {
    ps aux --sort=-%mem | head -6 | tail -5
}

# Get battery status (Termux)
get_battery_status() {
    if command -v termux-battery-status &>/dev/null; then
        termux-battery-status 2>/dev/null | grep -oP '"percentage":\K[0-9]+' || echo "N/A"
    else
        echo "N/A"
    fi
}

# Draw progress bar
draw_bar() {
    local percent=$1
    local width=30
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    # Color based on percentage
    local color=$GREEN
    if [[ $percent -gt 80 ]]; then
        color=$RED
    elif [[ $percent -gt 60 ]]; then
        color=$YELLOW
    fi
    
    printf "${color}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]${NC} %3d%%" "$percent"
}

# Main monitoring loop
monitor_loop() {
    local iteration=0
    
    while true; do
        show_header
        
        echo -e "${YELLOW}═══ System Resources ${NC}(Update: ${REFRESH_RATE}s)${NC}"
        echo
        
        # CPU
        echo -e "${CYAN}▼ CPU${NC}"
        local cpu_usage=$(get_cpu_usage)
        local cpu_temp=$(get_cpu_temp)
        local cpu_freq=$(get_cpu_freq)
        echo -n "  Usage:       "
        draw_bar "${cpu_usage%.*}"
        echo
        echo -e "  Temperature: ${YELLOW}${cpu_temp}°C${NC}"
        echo -e "  Frequency:   ${YELLOW}${cpu_freq}MHz${NC}"
        echo -e "  Cores:       ${YELLOW}$(nproc)${NC}"
        echo
        
        # Memory
        echo -e "${CYAN}▼ Memory${NC}"
        IFS='|' read -r mem_used mem_total mem_percent <<< "$(get_memory_usage)"
        echo -n "  RAM:         "
        draw_bar "${mem_percent%.*}"
        echo -e "  (${mem_used}GB / ${mem_total}GB)"
        
        # Swap
        IFS='|' read -r swap_used swap_total swap_percent <<< "$(get_swap_usage)"
        if [[ "$swap_total" != "0" ]]; then
            echo -n "  Swap:        "
            draw_bar "${swap_percent%.*}"
            echo -e "  (${swap_used}GB / ${swap_total}GB)"
        fi
        echo
        
        # Disk
        echo -e "${CYAN}▼ Disk${NC}"
        IFS='|' read -r disk_used disk_total disk_percent <<< "$(get_disk_usage)"
        echo -n "  Storage:     "
        draw_bar "${disk_percent%%%}"
        echo -e "  (${disk_used} / ${disk_total})"
        echo
        
        # Network
        echo -e "${CYAN}▼ Network${NC}"
        IFS='|' read -r rx_rate tx_rate <<< "$(get_network_stats)"
        echo -e "  Download:    ${GREEN}↓${NC} ${rx_rate} KB/s"
        echo -e "  Upload:      ${RED}↑${NC} ${tx_rate} KB/s"
        echo
        
        # Battery (if available)
        local battery=$(get_battery_status)
        if [[ "$battery" != "N/A" ]]; then
            echo -e "${CYAN}▼ Battery${NC}"
            echo -n "  Level:       "
            draw_bar "$battery"
            echo
            echo
        fi
        
        # Top processes by CPU
        echo -e "${YELLOW}═══ Top Processes (CPU) ═══${NC}"
        printf "%-10s %5s %5s %s\n" "USER" "%CPU" "%MEM" "COMMAND"
        echo "─────────────────────────────────────────────────────────────────"
        get_top_cpu_processes | awk '{printf "%-10s %5s %5s %s\n", $1, $3, $4, $11}'
        echo
        
        # Top processes by Memory
        echo -e "${YELLOW}═══ Top Processes (Memory) ═══${NC}"
        printf "%-10s %5s %5s %s\n" "USER" "%CPU" "%MEM" "COMMAND"
        echo "─────────────────────────────────────────────────────────────────"
        get_top_mem_processes | awk '{printf "%-10s %5s %5s %s\n", $1, $3, $4, $11}'
        echo
        
        # Log to file every 10 iterations
        if [[ $((iteration % 10)) -eq 0 ]]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] CPU:${cpu_usage}% MEM:${mem_percent}% DISK:${disk_percent}" >> "$PERF_LOG"
        fi
        
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${MAGENTA}Press Ctrl+C to exit${NC} | Logs: $PERF_LOG"
        
        iteration=$((iteration + 1))
        sleep $REFRESH_RATE
    done
}

# Handle Ctrl+C
trap 'echo -e "\n${GREEN}Performance monitoring stopped${NC}"; exit 0' INT TERM

# Show usage
show_usage() {
    echo "XTREME XAI Performance Monitor v4.0"
    echo "© Elektronikx-Center-Matte ® | Alexander Mathey ©"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -r, --rate SECONDS    Set refresh rate (default: 2)"
    echo "  -s, --snapshot        Take a single snapshot and exit"
    echo "  -l, --log             Show recent performance logs"
    echo "  -h, --help            Show this help message"
    echo
}

# Snapshot mode
snapshot_mode() {
    show_header
    
    echo -e "${YELLOW}═══ System Snapshot ═══${NC}"
    echo
    
    # Get all metrics
    local cpu_usage=$(get_cpu_usage)
    local cpu_temp=$(get_cpu_temp)
    local cpu_freq=$(get_cpu_freq)
    IFS='|' read -r mem_used mem_total mem_percent <<< "$(get_memory_usage)"
    IFS='|' read -r disk_used disk_total disk_percent <<< "$(get_disk_usage)"
    local battery=$(get_battery_status)
    
    # Display snapshot
    echo -e "CPU Usage:       ${cpu_usage}%"
    echo -e "CPU Temperature: ${cpu_temp}°C"
    echo -e "CPU Frequency:   ${cpu_freq}MHz"
    echo -e "Memory Usage:    ${mem_percent}% (${mem_used}GB / ${mem_total}GB)"
    echo -e "Disk Usage:      ${disk_percent} (${disk_used} / ${disk_total})"
    [[ "$battery" != "N/A" ]] && echo -e "Battery Level:   ${battery}%"
    echo
    
    echo "Snapshot saved to: $PERF_LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SNAPSHOT - CPU:${cpu_usage}% MEM:${mem_percent}% DISK:${disk_percent}" >> "$PERF_LOG"
}

# Show logs
show_logs() {
    echo "Recent Performance Logs:"
    echo "========================"
    
    if [[ -f "$PERF_LOG" ]]; then
        tail -20 "$PERF_LOG"
    else
        echo "No logs found"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--rate)
            REFRESH_RATE="$2"
            shift 2
            ;;
        -s|--snapshot)
            snapshot_mode
            exit 0
            ;;
        -l|--log)
            show_logs
            exit 0
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Start monitoring
monitor_loop
