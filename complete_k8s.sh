#!/usr/bin/env bash
set -euo pipefail

# Complete K8s Automation Wrapper
# Runs verification, analysis, and optimization in sequence

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}

# Required scripts
REQUIRED_SCRIPTS=("verify_k8s.sh" "analyze_k8s.sh" "optimize_k8s.sh")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_header() {
  echo ""
  echo -e "${BOLD}${CYAN}========================================${NC}"
  echo -e "${BOLD}${CYAN}  $*${NC}"
  echo -e "${BOLD}${CYAN}========================================${NC}"
  echo ""
}

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $*"
}

log_error() {
  echo -e "${RED}[✗]${NC} $*"
}

# Check if scripts exist
check_scripts() {
  local missing=0
  
  for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "${SCRIPT_DIR}/${script}" ]; then
      log_error "Required script not found: ${script}"
      missing=1
    fi
  done
  
  if [ "${missing}" -eq 1 ]; then
    log_error "Please ensure all required scripts are in the same directory"
    exit 1
  fi
  
  log_success "All required scripts found"
}

# Display usage information
usage() {
  cat << EOF
${BOLD}Complete K8s Cluster Automation${NC}

${BOLD}USAGE:${NC}
  $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
  --verify-only      Run verification checks only
  --analyze-only     Run analysis only
  --optimize-only    Run optimization only
  --skip-verify      Skip verification step
  --skip-analyze     Skip analysis step
  --skip-optimize    Skip optimization step
  --help, -h         Show this help message

${BOLD}ENVIRONMENT VARIABLES:${NC}
  KUBECONFIG_FILE    Path to kubeconfig file (default: \$HOME/.kube/config)
  VERBOSE            Enable verbose output (0/1)
  OUTPUT_FORMAT      Output format for analysis (text/json)
  DRY_RUN            Optimization mode (1=recommendations only, 0=apply)

${BOLD}EXAMPLES:${NC}
  # Run complete workflow
  $0

  # Run only verification
  $0 --verify-only

  # Skip verification, run analysis and optimization
  $0 --skip-verify

  # Use custom kubeconfig
  KUBECONFIG_FILE=/path/to/config $0

EOF
}

# Parse command line arguments
VERIFY=1
ANALYZE=1
OPTIMIZE=1

while [[ $# -gt 0 ]]; do
  case $1 in
    --verify-only)
      ANALYZE=0
      OPTIMIZE=0
      shift
      ;;
    --analyze-only)
      VERIFY=0
      OPTIMIZE=0
      shift
      ;;
    --optimize-only)
      VERIFY=0
      ANALYZE=0
      shift
      ;;
    --skip-verify)
      VERIFY=0
      shift
      ;;
    --skip-analyze)
      ANALYZE=0
      shift
      ;;
    --skip-optimize)
      OPTIMIZE=0
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Main execution
main() {
  log_header "Kubernetes Cluster Complete Automation"
  
  log_info "Using kubeconfig: ${KUBECONFIG_FILE}"
  log_info "Start time: $(date)"
  echo ""
  
  check_scripts
  echo ""
  
  # Run verification
  if [ "${VERIFY}" -eq 1 ]; then
    log_header "STEP 1: Verification"
    
    if bash "${SCRIPT_DIR}/verify_k8s.sh"; then
      log_success "Verification completed successfully"
    else
      log_error "Verification failed - please review errors above"
      log_info "Continuing with analysis and optimization..."
    fi
    echo ""
  fi
  
  # Run analysis
  if [ "${ANALYZE}" -eq 1 ]; then
    log_header "STEP 2: Analysis"
    
    if bash "${SCRIPT_DIR}/analyze_k8s.sh"; then
      log_success "Analysis completed successfully"
    else
      log_error "Analysis encountered issues"
    fi
    echo ""
  fi
  
  # Run optimization
  if [ "${OPTIMIZE}" -eq 1 ]; then
    log_header "STEP 3: Optimization Recommendations"
    
    if bash "${SCRIPT_DIR}/optimize_k8s.sh"; then
      log_success "Optimization recommendations generated"
    else
      log_error "Optimization analysis encountered issues"
    fi
    echo ""
  fi
  
  # Final summary
  log_header "Automation Complete"
  
  log_info "End time: $(date)"
  log_info ""
  log_success "All automation steps completed!"
  log_info ""
  log_info "Next steps:"
  log_info "  1. Review any warnings or recommendations above"
  log_info "  2. Apply optimizations as appropriate for your environment"
  log_info "  3. Monitor cluster with: kubectl get nodes && kubectl get pods --all-namespaces"
  log_info ""
}

main "$@"
