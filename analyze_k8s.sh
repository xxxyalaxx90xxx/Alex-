#!/usr/bin/env bash
set -euo pipefail

# Automated Kubernetes Cluster Analysis Script
# Analyzes cluster health, performance, resource usage, and security

KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}
VERBOSE=${VERBOSE:-0}
OUTPUT_FORMAT=${OUTPUT_FORMAT:-text}  # text or json

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  if [ "${OUTPUT_FORMAT}" = "text" ]; then
    echo -e "${BLUE}[INFO]${NC} $*"
  fi
}

log_success() {
  if [ "${OUTPUT_FORMAT}" = "text" ]; then
    echo -e "${GREEN}[✓]${NC} $*"
  fi
}

log_warning() {
  if [ "${OUTPUT_FORMAT}" = "text" ]; then
    echo -e "${YELLOW}[WARNING]${NC} $*"
  fi
}

log_error() {
  if [ "${OUTPUT_FORMAT}" = "text" ]; then
    echo -e "${RED}[ERROR]${NC} $*"
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."
  
  if ! command_exists kubectl; then
    log_error "kubectl is not installed or not in PATH"
    exit 1
  fi
  
  if [ ! -f "${KUBECONFIG_FILE}" ]; then
    log_error "Kubeconfig file not found at ${KUBECONFIG_FILE}"
    exit 1
  fi
  
  if ! kubectl --kubeconfig="${KUBECONFIG_FILE}" cluster-info >/dev/null 2>&1; then
    log_error "Cannot connect to Kubernetes cluster"
    exit 1
  fi
  
  log_success "Prerequisites check passed"
}

# Analyze cluster health
analyze_cluster_health() {
  log_info "=== Cluster Health Analysis ==="
  
  # Check node status
  log_info "Checking node status..."
  node_status=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get nodes --no-headers 2>/dev/null || echo "")
  if [ -z "${node_status}" ]; then
    log_error "No nodes found in cluster"
    return 1
  fi
  
  not_ready_nodes=$(echo "${node_status}" | grep -v "Ready" | wc -l)
  total_nodes=$(echo "${node_status}" | wc -l)
  
  if [ "${not_ready_nodes}" -gt 0 ]; then
    log_warning "${not_ready_nodes} out of ${total_nodes} nodes are not Ready"
    echo "${node_status}" | grep -v "Ready"
  else
    log_success "All ${total_nodes} nodes are Ready"
  fi
  
  # Check pod health across all namespaces
  log_info "Checking pod health across all namespaces..."
  pod_status=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces --no-headers 2>/dev/null || echo "")
  
  if [ -n "${pod_status}" ]; then
    total_pods=$(echo "${pod_status}" | wc -l)
    running_pods=$(echo "${pod_status}" | grep -c "Running" || echo "0")
    failed_pods=$(echo "${pod_status}" | grep -cE "Error|CrashLoopBackOff|Failed" || echo "0")
    pending_pods=$(echo "${pod_status}" | grep -c "Pending" || echo "0")
    
    log_info "Total pods: ${total_pods}"
    log_success "Running: ${running_pods}"
    
    if [ "${failed_pods}" -gt 0 ]; then
      log_error "Failed/Error: ${failed_pods}"
      echo "${pod_status}" | grep -E "Error|CrashLoopBackOff|Failed"
    fi
    
    if [ "${pending_pods}" -gt 0 ]; then
      log_warning "Pending: ${pending_pods}"
    fi
  else
    log_warning "No pods found in cluster"
  fi
  
  # Check system pods
  log_info "Checking critical system pods..."
  system_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods -n kube-system --no-headers 2>/dev/null || echo "")
  
  critical_components=("kube-apiserver" "kube-controller-manager" "kube-scheduler" "coredns" "etcd")
  for component in "${critical_components[@]}"; do
    if echo "${system_pods}" | grep -q "${component}"; then
      if echo "${system_pods}" | grep "${component}" | grep -q "Running"; then
        log_success "${component} is running"
      else
        log_error "${component} is not running properly"
      fi
    else
      log_warning "${component} not found"
    fi
  done
}

# Analyze resource usage
analyze_resource_usage() {
  log_info "=== Resource Usage Analysis ==="
  
  # Node resource usage
  log_info "Node resource allocation:"
  kubectl --kubeconfig="${KUBECONFIG_FILE}" top nodes 2>/dev/null || log_warning "Metrics server not available - cannot retrieve resource usage"
  
  # Pod resource usage
  log_info "Top resource-consuming pods:"
  kubectl --kubeconfig="${KUBECONFIG_FILE}" top pods --all-namespaces 2>/dev/null | head -20 || log_warning "Metrics server not available"
  
  # Check for resource limits and requests
  log_info "Checking pods without resource limits..."
  pods_without_limits=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces -o json 2>/dev/null | \
    grep -c '"limits": {}' || echo "0")
  
  if [ "${pods_without_limits}" -gt 0 ]; then
    log_warning "${pods_without_limits} container(s) running without resource limits"
  else
    log_success "All containers have resource limits defined"
  fi
}

# Analyze performance
analyze_performance() {
  log_info "=== Performance Analysis ==="
  
  # API server responsiveness
  log_info "Testing API server responsiveness..."
  start_time=$(date +%s%N)
  kubectl --kubeconfig="${KUBECONFIG_FILE}" get nodes >/dev/null 2>&1
  end_time=$(date +%s%N)
  response_time=$(( (end_time - start_time) / 1000000 ))
  
  if [ "${response_time}" -lt 500 ]; then
    log_success "API server response time: ${response_time}ms (Good)"
  elif [ "${response_time}" -lt 1000 ]; then
    log_warning "API server response time: ${response_time}ms (Acceptable)"
  else
    log_error "API server response time: ${response_time}ms (Slow)"
  fi
  
  # Check for frequently restarting pods
  log_info "Checking for pods with high restart counts..."
  high_restart_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces --no-headers 2>/dev/null | \
    awk '$5 > 5 {print}' || echo "")
  
  if [ -n "${high_restart_pods}" ]; then
    log_warning "Pods with more than 5 restarts:"
    echo "${high_restart_pods}"
  else
    log_success "No pods with excessive restarts"
  fi
}

# Security analysis
analyze_security() {
  log_info "=== Security Analysis ==="
  
  # Check for pods running as root
  log_info "Checking for pods running as root..."
  root_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces -o json 2>/dev/null | \
    grep -c '"runAsUser": 0' || echo "0")
  
  if [ "${root_pods}" -gt 0 ]; then
    log_warning "${root_pods} container(s) running as root user"
  else
    log_success "No containers explicitly running as root"
  fi
  
  # Check for privileged containers
  log_info "Checking for privileged containers..."
  privileged_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces -o json 2>/dev/null | \
    grep -c '"privileged": true' || echo "0")
  
  if [ "${privileged_pods}" -gt 0 ]; then
    log_warning "${privileged_pods} privileged container(s) found"
  else
    log_success "No privileged containers found"
  fi
  
  # Check RBAC
  log_info "Checking RBAC configuration..."
  if kubectl --kubeconfig="${KUBECONFIG_FILE}" get clusterrolebindings,rolebindings --all-namespaces >/dev/null 2>&1; then
    log_success "RBAC is enabled"
  else
    log_error "RBAC might not be properly configured"
  fi
  
  # Check network policies
  log_info "Checking network policies..."
  netpol_count=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get networkpolicies --all-namespaces --no-headers 2>/dev/null | wc -l)
  
  if [ "${netpol_count}" -gt 0 ]; then
    log_success "${netpol_count} network policies found"
  else
    log_warning "No network policies found - consider implementing network segmentation"
  fi
}

# Analyze storage
analyze_storage() {
  log_info "=== Storage Analysis ==="
  
  # Check PVs and PVCs
  log_info "Persistent Volume status:"
  pv_status=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pv --no-headers 2>/dev/null || echo "")
  
  if [ -n "${pv_status}" ]; then
    total_pvs=$(echo "${pv_status}" | wc -l)
    bound_pvs=$(echo "${pv_status}" | grep -c "Bound" || echo "0")
    available_pvs=$(echo "${pv_status}" | grep -c "Available" || echo "0")
    
    log_info "Total PVs: ${total_pvs}, Bound: ${bound_pvs}, Available: ${available_pvs}"
  else
    log_info "No Persistent Volumes configured"
  fi
  
  pvc_status=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pvc --all-namespaces --no-headers 2>/dev/null || echo "")
  
  if [ -n "${pvc_status}" ]; then
    total_pvcs=$(echo "${pvc_status}" | wc -l)
    bound_pvcs=$(echo "${pvc_status}" | grep -c "Bound" || echo "0")
    pending_pvcs=$(echo "${pvc_status}" | grep -c "Pending" || echo "0")
    
    log_info "Total PVCs: ${total_pvcs}, Bound: ${bound_pvcs}"
    
    if [ "${pending_pvcs}" -gt 0 ]; then
      log_warning "${pending_pvcs} PVCs in Pending state"
    fi
  else
    log_info "No Persistent Volume Claims found"
  fi
}

# Generate summary report
generate_summary() {
  log_info ""
  log_info "=== Analysis Summary ==="
  log_info "Cluster analysis completed at $(date)"
  log_info "For detailed recommendations, see optimize_k8s.sh"
}

# Main execution
main() {
  log_info "Starting Kubernetes Cluster Analysis..."
  log_info "Using kubeconfig: ${KUBECONFIG_FILE}"
  log_info ""
  
  check_prerequisites
  echo ""
  
  analyze_cluster_health
  echo ""
  
  analyze_resource_usage
  echo ""
  
  analyze_performance
  echo ""
  
  analyze_security
  echo ""
  
  analyze_storage
  echo ""
  
  generate_summary
  
  log_success "Analysis complete!"
}

main "$@"
