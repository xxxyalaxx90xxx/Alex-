#!/bin/bash

################################################################################
# Security Check Script v4.0
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Erweiterte Security-Checks für XTREME-XAI-ULTIMATE
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${HOME}/xtreme_ai_system"
LOG_DIR="${INSTALL_DIR}/logs"
SECURITY_LOG="${LOG_DIR}/security_$(date +%Y%m%d).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

log_check() {
    echo -e "${CYAN}[CHECK]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Log to file
log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$SECURITY_LOG"
}

# Header
show_header() {
    echo "========================================"
    echo "  XTREME XAI Security Check v4.0"
    echo "  © Elektronikx-Center-Matte ®"
    echo "  Alexander Mathey ©"
    echo "========================================"
    echo
}

# Check file permissions
check_file_permissions() {
    log_check "Checking file permissions..."
    
    local issues=0
    
    if [[ -d "$INSTALL_DIR" ]]; then
        # Check for world-writable files
        local writable=$(find "$INSTALL_DIR" -type f -perm -002 2>/dev/null | wc -l)
        if [[ $writable -gt 0 ]]; then
            log_fail "Found $writable world-writable files"
            find "$INSTALL_DIR" -type f -perm -002 2>/dev/null | head -5 | while read -r file; do
                echo "  - $file"
            done
            issues=$((issues + 1))
            log_to_file "SECURITY: $writable world-writable files found"
        else
            log_pass "No world-writable files found"
        fi
        
        # Check for executable files in unusual locations
        local exec_count=$(find "$INSTALL_DIR/data" "$INSTALL_DIR/config" -type f -executable 2>/dev/null | wc -l)
        if [[ $exec_count -gt 0 ]]; then
            log_warn "Found $exec_count executable files in data/config directories"
            find "$INSTALL_DIR/data" "$INSTALL_DIR/config" -type f -executable 2>/dev/null | head -5 | while read -r file; do
                echo "  - $file"
            done
        fi
    else
        log_info "Installation directory not found"
    fi
    
    return $issues
}

# Check for suspicious processes
check_suspicious_processes() {
    log_check "Checking for suspicious processes..."
    
    local suspicious=0
    
    # Check for common backdoor/malware process names
    local bad_processes=("nc" "netcat" "ncat" "socat" "cryptominer" "xmrig")
    
    for proc in "${bad_processes[@]}"; do
        if pgrep -x "$proc" &>/dev/null; then
            log_fail "Suspicious process found: $proc"
            log_to_file "SECURITY: Suspicious process detected: $proc"
            suspicious=$((suspicious + 1))
        fi
    done
    
    # Check for processes with suspicious command lines
    if ps aux | grep -E "wget.*\|.*sh|curl.*\|.*bash" | grep -v grep &>/dev/null; then
        log_warn "Suspicious command patterns detected in running processes"
        ps aux | grep -E "wget.*\|.*sh|curl.*\|.*bash" | grep -v grep | head -3
        suspicious=$((suspicious + 1))
    fi
    
    if [[ $suspicious -eq 0 ]]; then
        log_pass "No suspicious processes detected"
    fi
    
    return $suspicious
}

# Check network connections
check_network_connections() {
    log_check "Checking network connections..."
    
    local issues=0
    
    # Check listening ports
    if command -v netstat &>/dev/null; then
        local listening=$(netstat -tunlp 2>/dev/null | grep LISTEN | wc -l)
        log_info "Listening ports: $listening"
        
        # Show listening ports
        echo "Active listening ports:"
        netstat -tunlp 2>/dev/null | grep LISTEN | awk '{print "  " $4 " - " $7}' | head -10
    elif command -v ss &>/dev/null; then
        local listening=$(ss -tunlp 2>/dev/null | grep LISTEN | wc -l)
        log_info "Listening ports: $listening"
        
        # Show listening ports
        echo "Active listening ports:"
        ss -tunlp 2>/dev/null | grep LISTEN | awk '{print "  " $5}' | head -10
    else
        log_warn "netstat/ss not available - cannot check network connections"
        return 1
    fi
    
    # Check for established connections to suspicious ports
    if netstat -tun 2>/dev/null | grep -E ":(4444|31337|6667|1337)" &>/dev/null; then
        log_fail "Connections to suspicious ports detected!"
        netstat -tun 2>/dev/null | grep -E ":(4444|31337|6667|1337)"
        issues=$((issues + 1))
        log_to_file "SECURITY: Suspicious network connections detected"
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_pass "No suspicious network connections"
    fi
    
    return $issues
}

# Check SSH configuration
check_ssh_config() {
    log_check "Checking SSH configuration..."
    
    if command -v sshd &>/dev/null; then
        # Check if SSH is running
        if pgrep -x sshd &>/dev/null; then
            log_info "SSH daemon is running"
            
            # Check SSH config
            if [[ -f /etc/ssh/sshd_config ]]; then
                # Check for PermitRootLogin
                if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
                    log_warn "Root login is permitted via SSH"
                    log_to_file "SECURITY: Root SSH login enabled"
                else
                    log_pass "Root SSH login is properly configured"
                fi
                
                # Check for PasswordAuthentication
                if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
                    log_info "Password authentication is enabled"
                fi
            fi
        else
            log_info "SSH daemon not running"
        fi
    else
        log_info "SSH not installed (normal for Termux)"
    fi
}

# Check for rootkits (basic check)
check_rootkits() {
    log_check "Checking for rootkit indicators..."
    
    local indicators=0
    
    # Check for hidden processes
    local ps_count=$(ps aux | wc -l)
    local proc_count=$(ls -d /proc/[0-9]* 2>/dev/null | wc -l)
    local diff=$((proc_count - ps_count))
    
    if [[ $diff -gt 5 ]]; then
        log_warn "Process count mismatch detected ($diff difference)"
        log_info "This may indicate hidden processes (or normal system behavior)"
        indicators=$((indicators + 1))
    else
        log_pass "No process hiding detected"
    fi
    
    # Check for common rootkit files
    local rootkit_paths=("/dev/shm/.ICE-unix" "/tmp/.X11-unix/..data" "/dev/.udev")
    for path in "${rootkit_paths[@]}"; do
        if [[ -e "$path" ]]; then
            log_warn "Suspicious path found: $path"
            indicators=$((indicators + 1))
        fi
    done
    
    if [[ $indicators -eq 0 ]]; then
        log_pass "No rootkit indicators found"
    fi
    
    return $indicators
}

# Check system logs for errors
check_system_logs() {
    log_check "Checking system logs..."
    
    local errors=0
    
    if [[ -d "$LOG_DIR" ]]; then
        # Check for error patterns
        local error_count=$(grep -ri "error\|fail\|critical" "$LOG_DIR"/*.log 2>/dev/null | wc -l)
        
        if [[ $error_count -gt 10 ]]; then
            log_warn "Found $error_count error entries in logs"
            echo "Recent errors:"
            grep -ri "error\|fail\|critical" "$LOG_DIR"/*.log 2>/dev/null | tail -5
            errors=$((errors + 1))
        else
            log_pass "Log files look clean"
        fi
        
        # Check for auth failures
        if grep -ri "authentication failure\|failed password" "$LOG_DIR"/*.log 2>/dev/null | head -1 &>/dev/null; then
            log_warn "Authentication failures detected in logs"
            errors=$((errors + 1))
        fi
    else
        log_info "No log directory found"
    fi
    
    return $errors
}

# Check environment variables
check_environment() {
    log_check "Checking environment variables..."
    
    local issues=0
    
    # Check for suspicious PATH entries
    if echo "$PATH" | grep -E "\.|/tmp|/var/tmp" &>/dev/null; then
        log_warn "Suspicious PATH entries detected"
        echo "PATH: $PATH"
        issues=$((issues + 1))
    else
        log_pass "PATH looks secure"
    fi
    
    # Check for LD_PRELOAD
    if [[ -n "$LD_PRELOAD" ]]; then
        log_warn "LD_PRELOAD is set: $LD_PRELOAD"
        log_to_file "SECURITY: LD_PRELOAD detected: $LD_PRELOAD"
        issues=$((issues + 1))
    else
        log_pass "No LD_PRELOAD manipulation detected"
    fi
    
    return $issues
}

# Check file integrity (basic)
check_file_integrity() {
    log_check "Checking critical file integrity..."
    
    local modified=0
    
    # Check if critical scripts have been modified recently
    if [[ -d "$INSTALL_DIR" ]]; then
        local recent_mods=$(find "$INSTALL_DIR"/{bin,scripts,core} -type f -mtime -1 2>/dev/null | wc -l)
        
        if [[ $recent_mods -gt 0 ]]; then
            log_info "Files modified in last 24 hours: $recent_mods"
            find "$INSTALL_DIR"/{bin,scripts,core} -type f -mtime -1 2>/dev/null | head -5 | while read -r file; do
                echo "  - $(basename "$file")"
            done
        else
            log_pass "No recent modifications to critical files"
        fi
    fi
    
    return $modified
}

# Check for malware signatures (basic patterns)
check_malware_signatures() {
    log_check "Scanning for malware signatures..."
    
    local detections=0
    
    if [[ -d "$INSTALL_DIR" ]]; then
        # Check for common malware patterns in scripts
        if grep -r "eval.*base64\|system.*wget\|curl.*bash" "$INSTALL_DIR"/{scripts,bin} 2>/dev/null | grep -v "\.git" &>/dev/null; then
            log_warn "Suspicious code patterns detected"
            detections=$((detections + 1))
        else
            log_pass "No malware signatures detected"
        fi
    fi
    
    return $detections
}

# Generate security report
generate_report() {
    echo
    echo "========================================"
    echo "  Security Report Summary"
    echo "========================================"
    echo
    echo "Scan completed: $(date)"
    echo "Log file: $SECURITY_LOG"
    echo
    
    if [[ -f "$SECURITY_LOG" ]]; then
        local security_issues=$(grep -c "SECURITY:" "$SECURITY_LOG" 2>/dev/null || echo "0")
        echo "Security issues logged: $security_issues"
    fi
    
    echo
    echo "Recommendations:"
    echo "  1. Review log file for details"
    echo "  2. Keep system and packages updated"
    echo "  3. Use strong passwords"
    echo "  4. Limit network exposure"
    echo "  5. Regular backups"
    echo
}

# Main function
main() {
    show_header
    
    log_to_file "=== Security scan started ==="
    
    local total_issues=0
    
    check_file_permissions || total_issues=$((total_issues + $?))
    echo
    check_suspicious_processes || total_issues=$((total_issues + $?))
    echo
    check_network_connections || total_issues=$((total_issues + $?))
    echo
    check_ssh_config
    echo
    check_rootkits || total_issues=$((total_issues + $?))
    echo
    check_system_logs || total_issues=$((total_issues + $?))
    echo
    check_environment || total_issues=$((total_issues + $?))
    echo
    check_file_integrity
    echo
    check_malware_signatures || total_issues=$((total_issues + $?))
    
    generate_report
    
    if [[ $total_issues -eq 0 ]]; then
        log_pass "Security scan completed - No critical issues found!"
        log_to_file "=== Security scan completed - PASSED ==="
        return 0
    else
        log_warn "Security scan completed with $total_issues issue(s)"
        log_to_file "=== Security scan completed with $total_issues issue(s) ==="
        return 1
    fi
}

main "$@"
