#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Kubernetes Installation Validation and Testing Script
# ============================================================================
# Validates that a Kubernetes installation is working correctly
# Runs comprehensive tests on the cluster
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}
if [ -f /etc/rancher/k3s/k3s.yaml ] && [ ! -f "$HOME/.kube/config" ]; then
  KUBECONFIG_FILE=/etc/rancher/k3s/k3s.yaml
fi

export KUBECONFIG="${KUBECONFIG_FILE}"

PASSED=0
FAILED=0
WARNINGS=0

log() {
  local level="$1"
  shift
  local message="$*"
  
  case "${level}" in
    PASS)
      echo -e "${GREEN}✓ ${message}${RESET}"
      PASSED=$((PASSED + 1))
      ;;
    FAIL)
      echo -e "${RED}✗ ${message}${RESET}"
      FAILED=$((FAILED + 1))
      ;;
    WARN)
      echo -e "${YELLOW}⚠ ${message}${RESET}"
      WARNINGS=$((WARNINGS + 1))
      ;;
    INFO)
      echo -e "${CYAN}ℹ ${message}${RESET}"
      ;;
    HEADER)
      echo -e "${BOLD}${CYAN}${message}${RESET}"
      ;;
  esac
}

# Test 1: kubectl availability
test_kubectl() {
  log "HEADER" "=== Test 1: kubectl Command ==="
  
  if command -v kubectl >/dev/null 2>&1; then
    log "PASS" "kubectl is installed"
    
    local version
    version=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)
    log "INFO" "Version: ${version}"
  else
    log "FAIL" "kubectl is not installed or not in PATH"
  fi
  echo ""
}

# Test 2: Kubeconfig file
test_kubeconfig() {
  log "HEADER" "=== Test 2: Kubeconfig File ==="
  
  if [ -f "${KUBECONFIG_FILE}" ]; then
    log "PASS" "Kubeconfig file exists at ${KUBECONFIG_FILE}"
    
    if [ -r "${KUBECONFIG_FILE}" ]; then
      log "PASS" "Kubeconfig file is readable"
    else
      log "FAIL" "Kubeconfig file is not readable"
    fi
  else
    log "FAIL" "Kubeconfig file not found at ${KUBECONFIG_FILE}"
  fi
  echo ""
}

# Test 3: Cluster connectivity
test_cluster_connectivity() {
  log "HEADER" "=== Test 3: Cluster Connectivity ==="
  
  if kubectl cluster-info >/dev/null 2>&1; then
    log "PASS" "Can connect to cluster"
    
    local cluster_info
    cluster_info=$(kubectl cluster-info 2>/dev/null)
    log "INFO" "Cluster endpoint accessible"
  else
    log "FAIL" "Cannot connect to cluster"
    return
  fi
  echo ""
}

# Test 4: Node status
test_nodes() {
  log "HEADER" "=== Test 4: Node Status ==="
  
  local nodes
  nodes=$(kubectl get nodes --no-headers 2>/dev/null || echo "")
  
  if [ -z "${nodes}" ]; then
    log "FAIL" "No nodes found in cluster"
    return
  fi
  
  local total_nodes ready_nodes
  total_nodes=$(echo "${nodes}" | wc -l)
  ready_nodes=$(echo "${nodes}" | grep -c "Ready" || echo 0)
  
  log "INFO" "Total nodes: ${total_nodes}"
  log "INFO" "Ready nodes: ${ready_nodes}"
  
  if [ "${ready_nodes}" -eq "${total_nodes}" ]; then
    log "PASS" "All nodes are Ready"
  else
    log "FAIL" "Not all nodes are Ready (${ready_nodes}/${total_nodes})"
  fi
  echo ""
}

# Test 5: System pods
test_system_pods() {
  log "HEADER" "=== Test 5: System Pods ==="
  
  local pods
  pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null || echo "")
  
  if [ -z "${pods}" ]; then
    log "WARN" "No pods found in kube-system namespace"
    return
  fi
  
  local total_pods running_pods
  total_pods=$(echo "${pods}" | wc -l)
  running_pods=$(echo "${pods}" | grep -c "Running" || echo 0)
  
  log "INFO" "Total system pods: ${total_pods}"
  log "INFO" "Running pods: ${running_pods}"
  
  if [ "${running_pods}" -eq "${total_pods}" ]; then
    log "PASS" "All system pods are Running"
  else
    log "FAIL" "Not all system pods are Running (${running_pods}/${total_pods})"
    
    # Show non-running pods
    local non_running
    non_running=$(echo "${pods}" | grep -v "Running" || echo "")
    if [ -n "${non_running}" ]; then
      log "INFO" "Non-running pods:"
      echo "${non_running}" | while read -r line; do
        echo "  ${line}"
      done
    fi
  fi
  echo ""
}

# Test 6: CNI pods
test_cni_pods() {
  log "HEADER" "=== Test 6: CNI Network Plugin ==="
  
  # Check for flannel
  local flannel_pods
  flannel_pods=$(kubectl get pods -n kube-flannel --no-headers 2>/dev/null || echo "")
  
  if [ -n "${flannel_pods}" ]; then
    local total running
    total=$(echo "${flannel_pods}" | wc -l)
    running=$(echo "${flannel_pods}" | grep -c "Running" || echo 0)
    
    if [ "${running}" -eq "${total}" ]; then
      log "PASS" "Flannel CNI pods are Running (${running}/${total})"
    else
      log "FAIL" "Not all Flannel pods are Running (${running}/${total})"
    fi
  else
    log "INFO" "Flannel CNI not detected (may be using different CNI or K3s built-in)"
  fi
  echo ""
}

# Test 7: CoreDNS
test_coredns() {
  log "HEADER" "=== Test 7: CoreDNS ==="
  
  local coredns_pods
  coredns_pods=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null || echo "")
  
  if [ -z "${coredns_pods}" ]; then
    log "WARN" "CoreDNS pods not found"
    return
  fi
  
  local total running
  total=$(echo "${coredns_pods}" | wc -l)
  running=$(echo "${coredns_pods}" | grep -c "Running" || echo 0)
  
  if [ "${running}" -eq "${total}" ]; then
    log "PASS" "CoreDNS pods are Running (${running}/${total})"
  else
    log "FAIL" "Not all CoreDNS pods are Running (${running}/${total})"
  fi
  echo ""
}

# Test 8: Service connectivity
test_services() {
  log "HEADER" "=== Test 8: Services ==="
  
  local services
  services=$(kubectl get services -n kube-system --no-headers 2>/dev/null || echo "")
  
  if [ -z "${services}" ]; then
    log "WARN" "No services found in kube-system"
    return
  fi
  
  local total
  total=$(echo "${services}" | wc -l)
  log "PASS" "Found ${total} services in kube-system"
  
  # Check for kube-dns service
  if echo "${services}" | grep -q "kube-dns"; then
    log "PASS" "kube-dns service exists"
  else
    log "WARN" "kube-dns service not found"
  fi
  echo ""
}

# Test 9: Deploy test pod
test_workload_deployment() {
  log "HEADER" "=== Test 9: Workload Deployment ==="
  
  log "INFO" "Creating test pod..."
  
  if kubectl run test-pod --image=busybox:latest --restart=Never --command -- sleep 60 >/dev/null 2>&1; then
    log "PASS" "Test pod created successfully"
    
    # Wait for pod to be running
    log "INFO" "Waiting for pod to be Running..."
    local retries=0
    local max_retries=30
    
    while [ ${retries} -lt ${max_retries} ]; do
      local status
      status=$(kubectl get pod test-pod -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
      
      if [ "${status}" = "Running" ]; then
        log "PASS" "Test pod is Running"
        break
      fi
      
      sleep 2
      retries=$((retries + 1))
    done
    
    if [ ${retries} -eq ${max_retries} ]; then
      log "FAIL" "Test pod did not reach Running state in time"
    fi
    
    # Cleanup
    log "INFO" "Cleaning up test pod..."
    kubectl delete pod test-pod --grace-period=0 --force >/dev/null 2>&1 || true
  else
    log "FAIL" "Failed to create test pod"
  fi
  echo ""
}

# Test 10: Resource quotas and limits
test_resource_limits() {
  log "HEADER" "=== Test 10: Resource Limits ==="
  
  local node_resources
  node_resources=$(kubectl top nodes 2>/dev/null || echo "")
  
  if [ -n "${node_resources}" ]; then
    log "PASS" "Metrics server is available"
    log "INFO" "Node resource usage:"
    echo "${node_resources}"
  else
    log "WARN" "Metrics server not available (kubectl top nodes failed)"
  fi
  echo ""
}

# Test 11: RBAC
test_rbac() {
  log "HEADER" "=== Test 11: RBAC Configuration ==="
  
  if kubectl auth can-i get pods --all-namespaces >/dev/null 2>&1; then
    log "PASS" "Current user has cluster-wide pod read permissions"
  else
    log "WARN" "Current user does not have cluster-wide pod read permissions"
  fi
  
  if kubectl auth can-i create deployments >/dev/null 2>&1; then
    log "PASS" "Current user can create deployments"
  else
    log "WARN" "Current user cannot create deployments"
  fi
  echo ""
}

# Test 12: Storage
test_storage() {
  log "HEADER" "=== Test 12: Storage Classes ==="
  
  local storage_classes
  storage_classes=$(kubectl get storageclass --no-headers 2>/dev/null || echo "")
  
  if [ -n "${storage_classes}" ]; then
    local total
    total=$(echo "${storage_classes}" | wc -l)
    log "PASS" "Found ${total} storage class(es)"
    
    # Check for default storage class
    if echo "${storage_classes}" | grep -q "(default)"; then
      log "PASS" "Default storage class is configured"
    else
      log "WARN" "No default storage class configured"
    fi
  else
    log "WARN" "No storage classes found"
  fi
  echo ""
}

# Summary
print_summary() {
  echo ""
  log "HEADER" "=== Test Summary ==="
  echo -e "${GREEN}Passed: ${PASSED}${RESET}"
  echo -e "${RED}Failed: ${FAILED}${RESET}"
  echo -e "${YELLOW}Warnings: ${WARNINGS}${RESET}"
  echo ""
  
  if [ ${FAILED} -eq 0 ]; then
    log "PASS" "All critical tests passed! ✓"
    return 0
  else
    log "FAIL" "Some tests failed. Please review the output above."
    return 1
  fi
}

# Main
main() {
  echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║   Kubernetes Validation & Testing     ║${RESET}"
  echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${RESET}"
  echo ""
  
  test_kubectl
  test_kubeconfig
  test_cluster_connectivity
  test_nodes
  test_system_pods
  test_cni_pods
  test_coredns
  test_services
  test_workload_deployment
  test_resource_limits
  test_rbac
  test_storage
  
  print_summary
}

main "$@"
