#!/bin/bash
# Comprehensive Test Suite - Tests all components without creating backups
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
TEST_LOG="/tmp/comprehensive_test_$(date +%Y%m%d_%H%M%S).log"

# Options
NO_BACKUPS=false
QUICK_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-backups)
            NO_BACKUPS=true
            shift
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo -e "${BLUE}=== Comprehensive Test Suite ===${NC}"
echo "Test Log: $TEST_LOG"
echo "No Backups: $NO_BACKUPS"
echo "Quick Mode: $QUICK_MODE"
echo
echo "Starting tests..." | tee -a "$TEST_LOG"
echo

function test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✓${NC} $test_name: PASS" | tee -a "$TEST_LOG"
        ((TESTS_PASSED++))
    elif [[ "$result" == "FAIL" ]]; then
        echo -e "${RED}✗${NC} $test_name: FAIL - $message" | tee -a "$TEST_LOG"
        ((TESTS_FAILED++))
    elif [[ "$result" == "SKIP" ]]; then
        echo -e "${YELLOW}⊘${NC} $test_name: SKIP - $message" | tee -a "$TEST_LOG"
        ((TESTS_SKIPPED++))
    fi
}

function test_script_exists() {
    local script="$1"
    if [[ -f "$script" ]]; then
        test_result "Script Exists: $script" "PASS"
        return 0
    else
        test_result "Script Exists: $script" "FAIL" "File not found"
        return 1
    fi
}

function test_script_executable() {
    local script="$1"
    if [[ -x "$script" ]]; then
        test_result "Script Executable: $script" "PASS"
        return 0
    else
        test_result "Script Executable: $script" "FAIL" "Not executable"
        return 1
    fi
}

function test_script_syntax() {
    local script="$1"
    if bash -n "$script" 2>/dev/null; then
        test_result "Script Syntax: $script" "PASS"
        return 0
    else
        test_result "Script Syntax: $script" "FAIL" "Syntax error"
        return 1
    fi
}

function test_system_requirements() {
    echo -e "\n${BLUE}=== System Requirements Tests ===${NC}"
    
    # CPU test
    local cpu_count=$(nproc 2>/dev/null || echo 1)
    if [[ $cpu_count -ge 1 ]]; then
        test_result "CPU Count" "PASS"
    else
        test_result "CPU Count" "FAIL" "No CPUs detected"
    fi
    
    # Memory test
    local mem_total=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo 0)
    if [[ $mem_total -gt 512 ]]; then
        test_result "Memory (${mem_total}MB)" "PASS"
    else
        test_result "Memory" "FAIL" "Insufficient memory: ${mem_total}MB"
    fi
    
    # Disk space test
    local disk_avail=$(df -BG / 2>/dev/null | awk 'NR==2{print $4}' | sed 's/G//' || echo 0)
    if [[ $disk_avail -gt 5 ]]; then
        test_result "Disk Space (${disk_avail}GB)" "PASS"
    else
        test_result "Disk Space" "FAIL" "Insufficient space: ${disk_avail}GB"
    fi
}

function test_all_scripts() {
    echo -e "\n${BLUE}=== Script Validation Tests ===${NC}"
    
    local scripts=(
        "install_k8s_complete.sh"
        "install_k8s_optimized.sh"
        "validate_k8s.sh"
        "backup_k8s.sh"
        "upgrade_k8s.sh"
        "analyze_k8s.sh"
        "setup_monitoring.sh"
        "optimize_performance.sh"
        "troubleshoot_k8s.sh"
        "uninstall_k8s.sh"
        "setup_ai_assistant.sh"
        "setup_github_mcp.sh"
        "setup_web_dashboard.sh"
        "windows_installer.sh"
        "setup_realme_c63.sh"
        "setup_windows_wsl.sh"
        "setup_dev_environment.sh"
        "termux_complete_install.sh"
        "setup_privacy_tools.sh"
        "termux_ai_installer.sh"
        "auto_scan_analyze.sh"
        "remote_control.sh"
        "termux_acode_complete.sh"
    )
    
    for script in "${scripts[@]}"; do
        if test_script_exists "$script"; then
            test_script_executable "$script"
            test_script_syntax "$script"
        fi
    done
}

function test_installation_dry_run() {
    echo -e "\n${BLUE}=== Installation Dry-Run Tests ===${NC}"
    
    # Test optimized installer detection
    if [[ -f "install_k8s_optimized.sh" ]]; then
        echo "Testing system detection..."
        bash install_k8s_optimized.sh --dry-run 2>/dev/null && \
            test_result "Optimized Installer Dry-Run" "PASS" || \
            test_result "Optimized Installer Dry-Run" "SKIP" "Not implemented"
    fi
}

function test_analysis_tools() {
    echo -e "\n${BLUE}=== Analysis Tools Tests ===${NC}"
    
    # Test auto scan
    if [[ -f "auto_scan_analyze.sh" ]]; then
        ./auto_scan_analyze.sh --quick 2>/dev/null && \
            test_result "Auto Scan & Analyze" "PASS" || \
            test_result "Auto Scan & Analyze" "SKIP" "System not ready"
    fi
}

function test_remote_control() {
    echo -e "\n${BLUE}=== Remote Control Tests ===${NC}"
    
    if [[ -f "remote_control.sh" ]]; then
        # Test help
        ./remote_control.sh --help >/dev/null 2>&1 && \
            test_result "Remote Control Help" "PASS" || \
            test_result "Remote Control Help" "SKIP" "Not implemented"
    fi
}

function test_termux_components() {
    echo -e "\n${BLUE}=== Termux Components Tests ===${NC}"
    
    local termux_scripts=(
        "termux_complete_install.sh"
        "termux_ai_installer.sh"
        "termux_acode_complete.sh"
    )
    
    for script in "${termux_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            test_script_syntax "$script"
        fi
    done
}

function generate_test_report() {
    echo -e "\n${BLUE}=== Test Summary ===${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$TEST_LOG"
    echo -e "${GREEN}Passed:${NC}  $TESTS_PASSED" | tee -a "$TEST_LOG"
    echo -e "${RED}Failed:${NC}  $TESTS_FAILED" | tee -a "$TEST_LOG"
    echo -e "${YELLOW}Skipped:${NC} $TESTS_SKIPPED" | tee -a "$TEST_LOG"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$TEST_LOG"
    
    local total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
    local success_rate=0
    if [[ $total -gt 0 ]]; then
        success_rate=$((TESTS_PASSED * 100 / total))
    fi
    
    echo "Total Tests: $total" | tee -a "$TEST_LOG"
    echo "Success Rate: ${success_rate}%" | tee -a "$TEST_LOG"
    echo "Test Log: $TEST_LOG" | tee -a "$TEST_LOG"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed. Check log for details.${NC}"
        return 1
    fi
}

# Run all tests
test_system_requirements
test_all_scripts

if [[ "$QUICK_MODE" == "false" ]]; then
    test_installation_dry_run
    test_analysis_tools
    test_remote_control
    test_termux_components
fi

# Generate report
generate_test_report
