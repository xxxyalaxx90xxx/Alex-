#!/bin/bash
# Test Results Analyzer - Analyzes test results and generates reports
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Find latest test log
TEST_LOG=$(ls -t /tmp/comprehensive_test_*.log 2>/dev/null | head -1)

if [[ -z "$TEST_LOG" ]]; then
    echo -e "${RED}No test log found!${NC}"
    echo "Run ./comprehensive_test.sh first"
    exit 1
fi

echo -e "${BLUE}=== Test Results Analyzer ===${NC}"
echo "Analyzing: $TEST_LOG"
echo

# Parse results
PASSED=$(grep -c "✓" "$TEST_LOG" 2>/dev/null || echo 0)
FAILED=$(grep -c "✗" "$TEST_LOG" 2>/dev/null || echo 0)
SKIPPED=$(grep -c "⊘" "$TEST_LOG" 2>/dev/null || echo 0)
TOTAL=$((PASSED + FAILED + SKIPPED))

# Display statistics
echo -e "${CYAN}Test Statistics:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Passed:${NC}  $PASSED / $TOTAL"
echo -e "${RED}Failed:${NC}  $FAILED / $TOTAL"
echo -e "${YELLOW}Skipped:${NC} $SKIPPED / $TOTAL"
echo

# Calculate success rate
if [[ $TOTAL -gt 0 ]]; then
    SUCCESS_RATE=$((PASSED * 100 / TOTAL))
    echo -e "${CYAN}Success Rate:${NC} ${SUCCESS_RATE}%"
    
    if [[ $SUCCESS_RATE -ge 90 ]]; then
        echo -e "${GREEN}Excellent!${NC} ⭐⭐⭐⭐⭐"
    elif [[ $SUCCESS_RATE -ge 70 ]]; then
        echo -e "${GREEN}Good${NC} ⭐⭐⭐⭐"
    elif [[ $SUCCESS_RATE -ge 50 ]]; then
        echo -e "${YELLOW}Fair${NC} ⭐⭐⭐"
    else
        echo -e "${RED}Needs Improvement${NC} ⭐⭐"
    fi
fi

echo

# Show failed tests
if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}Failed Tests:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    grep "✗" "$TEST_LOG" | sed 's/✗//'
    echo
fi

# Show skipped tests
if [[ $SKIPPED -gt 0 ]]; then
    echo -e "${YELLOW}Skipped Tests:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    grep "⊘" "$TEST_LOG" | sed 's/⊘//'
    echo
fi

# Recommendations
echo -e "${CYAN}Recommendations:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAILED -gt 0 ]]; then
    echo "• Fix failed tests before deployment"
    echo "• Check error messages in log: $TEST_LOG"
fi

if [[ $SKIPPED -gt 5 ]]; then
    echo "• Many tests were skipped - system may not be fully ready"
    echo "• Install required dependencies"
fi

if [[ $SUCCESS_RATE -ge 90 ]]; then
    echo "• System is ready for deployment! ✓"
    echo "• All critical components are functional"
fi

echo
echo -e "${CYAN}Full log available at:${NC} $TEST_LOG"
