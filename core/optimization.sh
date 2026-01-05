#!/bin/bash

################################################################################
# System Optimization Script v4.0
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Erweiterte Performance-Optimierungen für XTREME-XAI-ULTIMATE
################################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[OPT]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Optimize system limits
optimize_limits() {
    log_info "Optimizing system limits..."
    
    if [[ $EUID -eq 0 ]]; then
        # Increase file descriptor limits
        if ! grep -q "* soft nofile 65535" /etc/security/limits.conf 2>/dev/null; then
            echo "* soft nofile 65535" >> /etc/security/limits.conf
            echo "* hard nofile 65535" >> /etc/security/limits.conf
            log_success "File descriptor limits increased"
        else
            log_info "File descriptor limits already optimized"
        fi
        
        # Increase process limits
        if ! grep -q "* soft nproc 32768" /etc/security/limits.conf 2>/dev/null; then
            echo "* soft nproc 32768" >> /etc/security/limits.conf
            echo "* hard nproc 32768" >> /etc/security/limits.conf
            log_success "Process limits increased"
        fi
    else
        # For non-root (Termux), set ulimit in current shell
        ulimit -n 4096 2>/dev/null && log_success "File descriptors set to 4096" || log_warning "Cannot set file descriptor limit"
    fi
}

# Optimize swap settings
optimize_swap() {
    log_info "Checking swap configuration..."
    
    if [[ $EUID -eq 0 ]]; then
        # Adjust swappiness for better performance
        current_swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "60")
        if [[ $current_swappiness -gt 10 ]]; then
            sysctl -w vm.swappiness=10 2>/dev/null || true
            echo "vm.swappiness=10" >> /etc/sysctl.conf 2>/dev/null || true
            log_success "Swappiness optimized to 10"
        else
            log_info "Swappiness already optimal ($current_swappiness)"
        fi
        
        # VFS cache pressure
        sysctl -w vm.vfs_cache_pressure=50 2>/dev/null || true
        log_success "VFS cache pressure optimized"
    else
        local swap_total=$(free -m | awk '/^Swap:/ {print $2}')
        if [[ "$swap_total" == "0" ]]; then
            log_info "No swap configured (normal for Termux)"
        else
            log_info "Swap: ${swap_total}MB configured"
        fi
    fi
}

# Optimize network settings
optimize_network() {
    log_info "Optimizing network settings..."
    
    if [[ $EUID -eq 0 ]]; then
        # Increase network buffer sizes
        sysctl -w net.core.rmem_max=16777216 2>/dev/null || true
        sysctl -w net.core.wmem_max=16777216 2>/dev/null || true
        sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216" 2>/dev/null || true
        sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216" 2>/dev/null || true
        
        # Enable TCP fast open
        sysctl -w net.ipv4.tcp_fastopen=3 2>/dev/null || true
        
        log_success "Network buffers optimized"
    else
        log_warning "Skipping network optimization (requires root)"
    fi
}

# CPU governor optimization
optimize_cpu_governor() {
    log_info "Checking CPU governor..."
    
    if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
        log_info "Current CPU governor: $current_governor"
        
        if [[ $EUID -eq 0 ]]; then
            if [[ "$current_governor" != "performance" ]]; then
                for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                    echo "performance" > $cpu 2>/dev/null || true
                done
                log_success "CPU governor set to performance"
            else
                log_info "CPU governor already set to performance"
            fi
        else
            log_info "Available governors: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo 'unknown')"
            log_warning "Cannot change governor (requires root)"
        fi
    else
        log_info "CPU frequency scaling not available"
    fi
}

# I/O scheduler optimization
optimize_io_scheduler() {
    log_info "Checking I/O scheduler..."
    
    if [[ $EUID -eq 0 ]]; then
        for disk in /sys/block/*/queue/scheduler; do
            if [[ -f "$disk" ]]; then
                # Try to set deadline or noop scheduler
                if grep -q "deadline" "$disk"; then
                    echo "deadline" > "$disk" 2>/dev/null && log_success "I/O scheduler set to deadline"
                elif grep -q "noop" "$disk"; then
                    echo "noop" > "$disk" 2>/dev/null && log_success "I/O scheduler set to noop"
                fi
            fi
        done
    else
        log_warning "Skipping I/O scheduler optimization (requires root)"
    fi
}

# Clear caches
optimize_cache() {
    log_info "Optimizing system caches..."
    
    if [[ $EUID -eq 0 ]]; then
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        log_success "System caches cleared"
    else
        # Clear user-space caches
        if command -v pkg &> /dev/null; then
            pkg clean 2>/dev/null && log_success "Package manager cache cleared"
        fi
        
        if command -v pip &> /dev/null; then
            pip cache purge 2>/dev/null && log_success "Python pip cache cleared"
        fi
        
        if command -v npm &> /dev/null; then
            npm cache clean --force 2>/dev/null && log_success "NPM cache cleared"
        fi
    fi
}

# Optimize for Android/Termux
optimize_termux() {
    if command -v termux-info &> /dev/null; then
        log_info "Applying Termux-specific optimizations..."
        
        # Create .termux directory if not exists
        mkdir -p "$HOME/.termux"
        
        # Optimize Termux properties
        if [[ ! -f "$HOME/.termux/termux.properties" ]] || ! grep -q "allow-external-apps" "$HOME/.termux/termux.properties"; then
            cat >> "$HOME/.termux/termux.properties" << 'EOF'

# XTREME XAI Optimizations
allow-external-apps=true
bell-character=ignore
EOF
            log_success "Termux properties optimized"
            termux-reload-settings 2>/dev/null || true
        fi
        
        # Optimize shell environment
        if [[ -f "$HOME/.bashrc" ]] && ! grep -q "XTREME XAI" "$HOME/.bashrc"; then
            cat >> "$HOME/.bashrc" << 'EOF'

# XTREME XAI Environment Variables
export TMPDIR="$HOME/tmp"
export HISTSIZE=10000
export HISTFILESIZE=20000
EOF
            log_success "Shell environment optimized"
        fi
        
        # Create tmp directory
        mkdir -p "$HOME/tmp"
    fi
}

# Memory optimization
optimize_memory() {
    log_info "Checking memory optimization..."
    
    local total_mem_mb=$(free -m | awk '/^Mem:/ {print $2}')
    local avail_mem_mb=$(free -m | awk '/^Mem:/ {print $7}')
    local used_percent=$((100 * (total_mem_mb - avail_mem_mb) / total_mem_mb))
    
    log_info "Memory usage: ${used_percent}%"
    
    if [[ $used_percent -gt 90 ]]; then
        log_warning "High memory usage detected!"
        log_info "Consider closing some applications"
    elif [[ $used_percent -gt 70 ]]; then
        log_info "Memory usage is moderate"
    else
        log_success "Memory usage is optimal"
    fi
}

# Disable unnecessary services (for demonstration)
optimize_services() {
    log_info "Checking system services..."
    
    if [[ $EUID -eq 0 ]] && command -v systemctl &> /dev/null; then
        # This is system-specific and commented out for safety
        # systemctl disable bluetooth 2>/dev/null || true
        log_info "Service optimization requires manual configuration"
    else
        log_info "Service optimization skipped (not applicable or requires root)"
    fi
}

# Create optimization profile
create_optimization_profile() {
    log_info "Creating optimization profile..."
    
    local profile_dir="${HOME}/.config/xtreme-xai"
    mkdir -p "$profile_dir"
    
    cat > "$profile_dir/optimization.conf" << EOF
# XTREME XAI Optimization Profile
# Generated: $(date)

[system]
optimized_date=$(date +%Y-%m-%d)
cpu_cores=$(nproc)
total_memory=$(free -m | awk '/^Mem:/ {print $2}')MB

[performance]
file_descriptor_limit=4096
process_limit=32768
cache_cleared=true

[network]
tcp_fastopen=enabled
buffer_size=16MB

[status]
optimization_level=high
last_run=$(date +%s)
EOF
    
    log_success "Optimization profile created: $profile_dir/optimization.conf"
}

# Main optimization function
main() {
    echo "========================================"
    echo "  System Optimization v4.0"
    echo "  © Elektronikx-Center-Matte ®"
    echo "  Alexander Mathey ©"
    echo "========================================"
    echo
    
    local start_time=$(date +%s)
    
    optimize_limits
    optimize_swap
    optimize_network
    optimize_cpu_governor
    optimize_io_scheduler
    optimize_cache
    optimize_termux
    optimize_memory
    optimize_services
    create_optimization_profile
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo
    log_success "System optimization completed in ${duration}s!"
    echo
    log_info "Note: Some optimizations require root privileges"
    log_info "Reboot may be required for all changes to take effect"
    log_info "Run this script periodically for best performance"
}

main "$@"
