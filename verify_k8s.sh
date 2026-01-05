#!/usr/bin/env bash
set -euo pipefail

# Automated Kubernetes Cluster Verification Script
# Validates that the cluster is properly installed and operational

KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}
TIMEOUT=${TIMEOUT:-300}  # 5 minutes timeout for readiness checks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[✓ PASS]${NC} $*"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

log_warning() {
  echo -e "${YELLOW}[⚠ WARN]${NC} $*"
  CHECKS_WARNING=$((CHECKS_WARNING + 1))
}

log_error() {
  echo -e "${RED}[✗ FAIL]${NC} $*"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Verify kubectl is available
verify_kubectl() {
  log_info "Checking kubectl availability..."
  
  if ! command_exists kubectl; then
    log_error "kubectl is not installed or not in PATH"
    return 1
  fi
  
  kubectl_version=$(kubectl version --client --short 2>/dev/null | head -1 || echo "unknown")
  log_success "kubectl is available: ${kubectl_version}"
}

# Verify kubeconfig
verify_kubeconfig() {
  log_info "Checking kubeconfig file..."
  
  if [ ! -f "${KUBECONFIG_FILE}" ]; then
    log_error "Kubeconfig file not found at ${KUBECONFIG_FILE}"
    return 1
  fi
  
  log_success "Kubeconfig file exists at ${KUBECONFIG_FILE}"
}

# Verify cluster connectivity
verify_connectivity() {
  log_info "Testing cluster connectivity..."
  
  if ! kubectl --kubeconfig="${KUBECONFIG_FILE}" cluster-info >/dev/null 2>&1; then
    log_error "Cannot connect to Kubernetes cluster"
    return 1
  fi
  
  cluster_info=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" cluster-info 2>/dev/null | head -1)
  log_success "Successfully connected to cluster"
  log_info "  ${cluster_info}"
}

# Verify API server
verify_apiserver() {
  log_info "Checking API server health..."
  
  if kubectl --kubeconfig="${KUBECONFIG_FILE}" get --raw /healthz >/dev/null 2>&1; then
    log_success "API server is healthy"
  else
    log_error "API server health check failed"
    return 1
  fi
  
  # Check API server responsiveness
  start_time=$(date +%s%N)
  kubectl --kubeconfig="${KUBECONFIG_FILE}" get nodes >/dev/null 2>&1
  end_time=$(date +%s%N)
  response_time=$(( (end_time - start_time) / 1000000 ))
  
  if [ "${response_time}" -lt 1000 ]; then
    log_success "API server response time: ${response_time}ms"
  else
    log_warning "API server response time is slow: ${response_time}ms"
  fi
}

# Verify nodes
verify_nodes() {
  log_info "Checking node status..."
  
  nodes=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get nodes --no-headers 2>/dev/null || echo "")
  
  if [ -z "${nodes}" ]; then
    log_error "No nodes found in cluster"
    return 1
  fi
  
  total_nodes=$(echo "${nodes}" | wc -l)
  ready_nodes=$(echo "${nodes}" | grep -c " Ready" || echo "0")
  not_ready_nodes=$((total_nodes - ready_nodes))
  
  if [ "${not_ready_nodes}" -gt 0 ]; then
    log_error "${not_ready_nodes} out of ${total_nodes} nodes are not Ready"
    echo "${nodes}" | grep -v " Ready"
    return 1
  else
    log_success "All ${total_nodes} node(s) are Ready"
  fi
  
  # Display node details
  while IFS= read -r node_line; do
    node_name=$(echo "${node_line}" | awk '{print $1}')
    node_status=$(echo "${node_line}" | awk '{print $2}')
    node_version=$(echo "${node_line}" | awk '{print $NF}')
    log_info "  Node: ${node_name} | Status: ${node_status} | Version: ${node_version}"
  done <<< "${nodes}"
}

# Verify system pods
verify_system_pods() {
  log_info "Checking system pods in kube-system namespace..."
  
  system_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods -n kube-system --no-headers 2>/dev/null || echo "")
  
  if [ -z "${system_pods}" ]; then
    log_error "No system pods found in kube-system namespace"
    return 1
  fi
  
  critical_components=("kube-apiserver" "kube-controller-manager" "kube-scheduler" "etcd")
  all_critical_running=1
  
  for component in "${critical_components[@]}"; do
    if echo "${system_pods}" | grep -q "${component}"; then
      component_status=$(echo "${system_pods}" | grep "${component}" | awk '{print $3}' | head -1)
      if [ "${component_status}" = "Running" ]; then
        log_success "${component} is running"
      else
        log_error "${component} is not running (status: ${component_status})"
        all_critical_running=0
      fi
    else
      log_warning "${component} not found (may be running outside cluster)"
    fi
  done
  
  # Check CoreDNS
  if echo "${system_pods}" | grep -q "coredns"; then
    coredns_running=$(echo "${system_pods}" | grep "coredns" | grep -c "Running" || echo "0")
    coredns_total=$(echo "${system_pods}" | grep -c "coredns" || echo "0")
    
    if [ "${coredns_running}" -eq "${coredns_total}" ] && [ "${coredns_running}" -gt 0 ]; then
      log_success "CoreDNS is running (${coredns_running}/${coredns_total} pods)"
    else
      log_error "CoreDNS has issues (${coredns_running}/${coredns_total} pods running)"
      all_critical_running=0
    fi
  else
    log_error "CoreDNS not found"
    all_critical_running=0
  fi
  
  return $((1 - all_critical_running))
}

# Verify CNI (flannel)
verify_cni() {
  log_info "Checking CNI (Container Network Interface)..."
  
  # Check for flannel
  flannel_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces --no-headers 2>/dev/null | \
    grep "flannel" || echo "")
  
  if [ -n "${flannel_pods}" ]; then
    flannel_running=$(echo "${flannel_pods}" | grep -c "Running" || echo "0")
    flannel_total=$(echo "${flannel_pods}" | wc -l)
    
    if [ "${flannel_running}" -eq "${flannel_total}" ]; then
      log_success "Flannel CNI is running (${flannel_running}/${flannel_total} pods)"
    else
      log_error "Flannel has issues (${flannel_running}/${flannel_total} pods running)"
      return 1
    fi
  else
    # Check for other CNI plugins
    cni_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces --no-headers 2>/dev/null | \
      grep -E "calico|weave|cilium" || echo "")
    
    if [ -n "${cni_pods}" ]; then
      log_success "Alternative CNI plugin detected"
    else
      log_warning "No CNI plugin pods found - networking may not work properly"
    fi
  fi
}

# Verify all pods
verify_all_pods() {
  log_info "Checking all pods across namespaces..."
  
  all_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces --no-headers 2>/dev/null || echo "")
  
  if [ -z "${all_pods}" ]; then
    log_warning "No pods found in cluster"
    return 0
  fi
  
  total_pods=$(echo "${all_pods}" | wc -l)
  running_pods=$(echo "${all_pods}" | grep -c "Running" || echo "0")
  failed_pods=$(echo "${all_pods}" | grep -cE "Error|CrashLoopBackOff|Failed" || echo "0")
  pending_pods=$(echo "${all_pods}" | grep -c "Pending" || echo "0")
  
  log_info "Pod Statistics:"
  log_info "  Total: ${total_pods}"
  log_info "  Running: ${running_pods}"
  log_info "  Pending: ${pending_pods}"
  log_info "  Failed/Error: ${failed_pods}"
  
  if [ "${failed_pods}" -gt 0 ]; then
    log_error "Found ${failed_pods} pod(s) with errors:"
    echo "${all_pods}" | grep -E "Error|CrashLoopBackOff|Failed"
    return 1
  else
    log_success "No failed pods detected"
  fi
  
  if [ "${pending_pods}" -gt 0 ]; then
    log_warning "${pending_pods} pod(s) in Pending state"
  fi
}

# Verify DNS functionality
verify_dns() {
  log_info "Testing DNS resolution..."
  
  # Create a test pod to verify DNS with timestamp for uniqueness
  test_pod_name="dns-test-pod-$(date +%s)-$$"
  
  kubectl --kubeconfig="${KUBECONFIG_FILE}" run "${test_pod_name}" \
    --image=busybox:1.28 \
    --restart=Never \
    --command -- sleep 30 >/dev/null 2>&1 || true
  
  # Wait for pod to be ready
  sleep 3
  
  # Test DNS resolution
  if kubectl --kubeconfig="${KUBECONFIG_FILE}" exec "${test_pod_name}" -- nslookup kubernetes.default >/dev/null 2>&1; then
    log_success "DNS resolution is working"
    kubectl --kubeconfig="${KUBECONFIG_FILE}" delete pod "${test_pod_name}" >/dev/null 2>&1 || true
  else
    log_warning "DNS test failed or pod not ready yet"
    kubectl --kubeconfig="${KUBECONFIG_FILE}" delete pod "${test_pod_name}" >/dev/null 2>&1 || true
  fi
}

# Verify container runtime
verify_container_runtime() {
  log_info "Checking container runtime..."
  
  node_info=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get nodes -o json 2>/dev/null)
  
  if echo "${node_info}" | grep -q "containerRuntimeVersion"; then
    runtime_version=$(echo "${node_info}" | grep -m 1 "containerRuntimeVersion" | \
      awk -F'"' '{print $4}')
    log_success "Container runtime: ${runtime_version}"
  else
    log_warning "Could not determine container runtime version"
  fi
}

# Verify resource availability
verify_resources() {
  log_info "Checking cluster resource availability..."
  
  # Check if metrics server is available
  if kubectl --kubeconfig="${KUBECONFIG_FILE}" top nodes >/dev/null 2>&1; then
    log_success "Metrics server is available and working"
    
    # Display node resources
    log_info "Node resource usage:"
    kubectl --kubeconfig="${KUBECONFIG_FILE}" top nodes 2>/dev/null | head -5
  else
    log_warning "Metrics server not available - cannot check resource usage"
  fi
}

# Verify hugepages (if configured)
verify_hugepages() {
  log_info "Checking hugepages configuration..."
  
  hugepages_info=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get nodes -o json 2>/dev/null | \
    grep -A 2 "hugepages-2Mi" || echo "")
  
  if [ -n "${hugepages_info}" ]; then
    log_success "Hugepages are configured"
  else
    log_info "Hugepages not configured (optional)"
  fi
}

# Generate verification report
generate_report() {
  log_info ""
  log_info "=========================================="
  log_info "   VERIFICATION REPORT"
  log_info "=========================================="
  log_info ""
  log_success "Checks Passed:  ${CHECKS_PASSED}"
  log_warning "Warnings:       ${CHECKS_WARNING}"
  log_error "Checks Failed:  ${CHECKS_FAILED}"
  log_info ""
  
  if [ "${CHECKS_FAILED}" -eq 0 ]; then
    log_success "✓ All critical checks passed!"
    log_success "✓ Cluster is operational and ready for use"
    return 0
  else
    log_error "✗ Some checks failed - please review errors above"
    return 1
  fi
}

# Main execution
main() {
  log_info "=========================================="
  log_info "  Kubernetes Cluster Verification"
  log_info "=========================================="
  log_info "Using kubeconfig: ${KUBECONFIG_FILE}"
  log_info "Start time: $(date)"
  log_info ""
  
  verify_kubectl
  echo ""
  
  verify_kubeconfig
  echo ""
  
  verify_connectivity
  echo ""
  
  verify_apiserver
  echo ""
  
  verify_nodes
  echo ""
  
  verify_container_runtime
  echo ""
  
  verify_system_pods
  echo ""
  
  verify_cni
  echo ""
  
  verify_all_pods
  echo ""
  
  verify_dns
  echo ""
  
  verify_resources
  echo ""
  
  verify_hugepages
  echo ""
  
  generate_report
  exit_code=$?
  
  log_info ""
  log_info "End time: $(date)"
  
  exit "${exit_code}"
}

main "$@"
