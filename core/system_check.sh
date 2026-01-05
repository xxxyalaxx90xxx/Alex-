#!/bin/bash

################################################################################
# System Check Script v4.0
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Erweiterte System-Checks für XTREME-XAI-ULTIMATE
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_check() {
    echo -e "${YELLOW}[CHECK]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Check OS
check_os() {
    log_check "Checking operating system..."
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        log_pass "OS: $NAME $VERSION"
        return 0
    elif command -v termux-info &> /dev/null; then
        log_pass "OS: Termux (Android)"
        return 0
    else
        log_fail "Could not determine OS"
        return 1
    fi
}

# Check kernel version
check_kernel() {
    log_check "Checking kernel version..."
    KERNEL=$(uname -r)
    log_pass "Kernel: $KERNEL"
}

# Check CPU
check_cpu() {
    log_check "Checking CPU..."
    local arch=$(uname -m)
    log_info "Architecture: $arch"
    
    if command -v lscpu &> /dev/null; then
        CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
        CPU_CORES=$(nproc)
        log_pass "CPU: $CPU_MODEL ($CPU_CORES cores)"
    else
        CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
        log_pass "CPU cores: $CPU_CORES"
    fi
    
    # Check CPU frequency
    if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        local max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)
        if [[ -n "$max_freq" ]]; then
            local freq_mhz=$((max_freq / 1000))
            log_info "Max CPU Frequency: ${freq_mhz}MHz"
        fi
        
        local governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
        if [[ -n "$governor" ]]; then
            log_info "CPU Governor: $governor"
        fi
    fi
}

# Check memory
check_memory() {
    log_check "Checking memory..."
    TOTAL_MEM=$(free -h | awk '/^Mem:/ {print $2}')
    AVAIL_MEM=$(free -h | awk '/^Mem:/ {print $7}')
    USED_MEM=$(free -h | awk '/^Mem:/ {print $3}')
    log_pass "Memory: $TOTAL_MEM total, $USED_MEM used, $AVAIL_MEM available"
    
    # Check if sufficient memory (at least 2GB)
    TOTAL_MEM_MB=$(free -m | awk '/^Mem:/ {print $2}')
    if [[ $TOTAL_MEM_MB -lt 2048 ]]; then
        log_fail "Insufficient memory (< 2GB). Some features may not work properly."
        return 1
    fi
    
    # Check swap
    SWAP_TOTAL=$(free -h | awk '/^Swap:/ {print $2}')
    if [[ "$SWAP_TOTAL" != "0B" ]]; then
        log_info "Swap: $SWAP_TOTAL"
    fi
}

# Check disk space
check_disk() {
    log_check "Checking disk space..."
    
    # Internal storage
    DISK_USAGE=$(df -h "$HOME" | awk 'NR==2 {print $4 " available (" $5 " used)"}')
    log_pass "Internal: $DISK_USAGE"
    
    # Check if sufficient space (at least 1GB)
    AVAIL_KB=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [[ $AVAIL_KB -lt 1048576 ]]; then
        log_fail "Insufficient disk space (< 1GB). Installation may fail."
        return 1
    fi
    
    # Check SD card if available
    if [[ -d "/storage/emulated/0" ]]; then
        SD_USAGE=$(df -h "/storage/emulated/0" 2>/dev/null | awk 'NR==2 {print $4 " available (" $5 " used)"}')
        if [[ -n "$SD_USAGE" ]]; then
            log_pass "SD Card: $SD_USAGE"
        fi
    fi
}

# Check temperature
check_temperature() {
    log_check "Checking system temperature..."
    
    local temp_found=0
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        local temp_c=$((temp / 1000))
        log_info "CPU Temperature: ${temp_c}°C"
        temp_found=1
        
        if [[ $temp_c -gt 80 ]]; then
            log_fail "High temperature detected! (${temp_c}°C)"
        fi
    fi
    
    if [[ $temp_found -eq 0 ]]; then
        log_info "Temperature monitoring not available"
    fi
}

# Check required commands
check_commands() {
    log_check "Checking required commands..."
    local missing=0
    
    for cmd in bash grep sed awk; do
        if ! command -v $cmd &> /dev/null; then
            log_fail "Required command not found: $cmd"
            missing=$((missing + 1))
        fi
    done
    
    if [[ $missing -eq 0 ]]; then
        log_pass "All required commands are available"
        return 0
    else
        log_fail "$missing required command(s) missing"
        return 1
    fi
}

# Check optional commands
check_optional_commands() {
    log_check "Checking optional commands..."
    local available=0
    local total=0
    
    for cmd in curl wget git docker python3 python node npm pip java gcc make; do
        total=$((total + 1))
        if command -v $cmd &> /dev/null; then
            available=$((available + 1))
            local version=$($cmd --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
            if [[ -n "$version" ]]; then
                log_info "$cmd: v$version"
            else
                log_info "$cmd: available"
            fi
        fi
    done
    
    log_pass "$available/$total optional command(s) available"
}

# Check network connectivity
check_network() {
    log_check "Checking network connectivity..."
    
    # Check internet connection
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        log_pass "Internet connection: Active"
        
        # Check DNS resolution
        if ping -c 1 -W 2 google.com &>/dev/null; then
            log_pass "DNS resolution: Working"
        else
            log_fail "DNS resolution: Failed"
        fi
    else
        log_fail "No internet connection"
        return 1
    fi
}

# Check Termux specific
check_termux() {
    if command -v termux-info &> /dev/null; then
        log_check "Checking Termux environment..."
        
        # Check storage access
        if [[ -d "$HOME/storage" ]]; then
            log_pass "Termux storage setup: Configured"
        else
            log_info "Termux storage setup: Run 'termux-setup-storage'"
        fi
        
        # Check if Termux API is available
        if command -v termux-battery-status &> /dev/null; then
            log_pass "Termux API: Available"
            
            # Get battery status
            if battery_info=$(termux-battery-status 2>/dev/null); then
                battery_level=$(echo "$battery_info" | grep -o '"percentage":[0-9]*' | cut -d':' -f2)
                if [[ -n "$battery_level" ]]; then
                    log_info "Battery: ${battery_level}%"
                fi
            fi
        else
            log_info "Termux API: Not installed"
        fi
    fi
}

# Performance test
performance_test() {
    log_check "Running quick performance test..."
    
    # CPU test (simple calculation)
    local start_time=$(date +%s%N)
    for i in {1..10000}; do
        : $((i * i))
    done
    local end_time=$(date +%s%N)
    local duration=$(((end_time - start_time) / 1000000))
    
    log_info "CPU test completed in ${duration}ms"
    
    if [[ $duration -lt 100 ]]; then
        log_pass "Performance: Excellent"
    elif [[ $duration -lt 500 ]]; then
        log_pass "Performance: Good"
    else
        log_info "Performance: Moderate"
    fi
}

# Main check function
main() {
    echo "========================================"
    echo "  XTREME-XAI-ULTIMATE System Check v4.0"
    echo "  © Elektronikx-Center-Matte ®"
    echo "  Alexander Mathey ©"
    echo "========================================"
    echo
    
    local failed=0
    
    check_os || failed=$((failed + 1))
    check_kernel
    check_cpu
    check_memory || failed=$((failed + 1))
    check_disk || failed=$((failed + 1))
    check_temperature
    check_commands || failed=$((failed + 1))
    check_optional_commands
    check_network || failed=$((failed + 1))
    check_termux
    performance_test
    
    echo
    echo "========================================"
    if [[ $failed -eq 0 ]]; then
        log_pass "All critical checks passed! ✓"
        echo "System is ready for XTREME XAI installation"
        return 0
    else
        log_fail "$failed critical check(s) failed"
        echo "Please address the issues before continuing."
        return 1
    fi
}

main "$@"
