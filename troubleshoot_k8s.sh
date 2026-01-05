#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Kubernetes Troubleshooting Automation Script
# ============================================================================
# Automatically detects and fixes common Kubernetes issues
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

AUTO_FIX="${AUTO_FIX:-false}"
ISSUES_FOUND=0
ISSUES_FIXED=0

log() {
  local level="$1"
  shift
  local message="$*"
  
  case "${level}" in
    ERROR)
      echo -e "${RED}✗ ${message}${RESET}" >&2
      ;;
    SUCCESS)
      echo -e "${GREEN}✓ ${message}${RESET}"
      ;;
    WARNING)
      echo -e "${YELLOW}⚠ ${message}${RESET}"
      ;;
    INFO)
      echo -e "${CYAN}ℹ ${message}${RESET}"
      ;;
    HEADER)
      echo -e "${BOLD}${CYAN}${message}${RESET}"
      ;;
    FIX)
      echo -e "${GREEN}🔧 ${message}${RESET}"
      ;;
  esac
}

check_kubectl() {
  log "INFO" "Checking kubectl availability..."
  
  if ! command -v kubectl >/dev/null 2>&1; then
    ((ISSUES_FOUND++))
    log "ERROR" "kubectl not found"
    
    if [ "${AUTO_FIX}" = "true" ]; then
      log "FIX" "Attempting to fix kubectl..."
      
      # Try to symlink from k3s
      if command -v k3s >/dev/null 2>&1; then
        sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl
        log "SUCCESS" "kubectl linked from k3s"
        ((ISSUES_FIXED++))
      else
        log "ERROR" "Cannot auto-fix: k3s not found"
      fi
    else
      log "INFO" "Fix: sudo ln -s /usr/local/bin/k3s /usr/local/bin/kubectl"
    fi
    return 1
  fi
  
  log "SUCCESS" "kubectl is available"
  return 0
}

check_cluster_connectivity() {
  log "INFO" "Checking cluster connectivity..."
  
  if ! kubectl cluster-info >/dev/null 2>&1; then
    ((ISSUES_FOUND++))
    log "ERROR" "Cannot connect to cluster"
    
    if [ "${AUTO_FIX}" = "true" ]; then
      log "FIX" "Attempting to fix cluster connectivity..."
      
      # Check if K3s service is running
      if systemctl list-units --type=service | grep -q k3s; then
        if ! systemctl is-active --quiet k3s; then
          sudo systemctl start k3s
          sleep 10
          if kubectl cluster-info >/dev/null 2>&1; then
            log "SUCCESS" "K3s service started"
            ((ISSUES_FIXED++))
          fi
        fi
      elif systemctl list-units --type=service | grep -q kubelet; then
        if ! systemctl is-active --quiet kubelet; then
          sudo systemctl start kubelet
          sleep 10
        fi
      fi
    else
      log "INFO" "Fix: Check service status with 'systemctl status k3s' or 'systemctl status kubelet'"
    fi
    return 1
  fi
  
  log "SUCCESS" "Cluster is accessible"
  return 0
}

check_node_status() {
  log "INFO" "Checking node status..."
  
  local not_ready_nodes
  not_ready_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready" | wc -l)
  
  if [ "${not_ready_nodes}" -gt 0 ]; then
    ((ISSUES_FOUND++))
    log "ERROR" "${not_ready_nodes} node(s) not Ready"
    
    kubectl get nodes
    
    if [ "${AUTO_FIX}" = "true" ]; then
      log "FIX" "Attempting to fix node issues..."
      
      # Restart kubelet on not ready nodes
      local node_name
      node_name=$(kubectl get nodes --no-headers | grep -v " Ready" | awk '{print $1}' | head -1)
      
      if [ -n "${node_name}" ]; then
        log "INFO" "Restarting services for node: ${node_name}"
        
        if systemctl list-units --type=service | grep -q k3s; then
          sudo systemctl restart k3s
        elif systemctl list-units --type=service | grep -q kubelet; then
          sudo systemctl restart kubelet
        fi
        
        sleep 15
        
        local still_not_ready
        still_not_ready=$(kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready" | wc -l)
        
        if [ "${still_not_ready}" -lt "${not_ready_nodes}" ]; then
          log "SUCCESS" "Node status improved"
          ((ISSUES_FIXED++))
        fi
      fi
    else
      log "INFO" "Fix: kubectl describe node <node-name>"
    fi
    return 1
  fi
  
  log "SUCCESS" "All nodes are Ready"
  return 0
}

check_pod_status() {
  log "INFO" "Checking pod status..."
  
  local failed_pods
  failed_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -E "Error|CrashLoopBackOff|ImagePullBackOff|Pending" | wc -l)
  
  if [ "${failed_pods}" -gt 0 ]; then
    ((ISSUES_FOUND++))
    log "ERROR" "${failed_pods} pod(s) in failed state"
    
    kubectl get pods --all-namespaces | grep -E "Error|CrashLoopBackOff|ImagePullBackOff|Pending" || true
    
    if [ "${AUTO_FIX}" = "true" ]; then
      log "FIX" "Attempting to fix pod issues..."
      
      # Delete failed pods to trigger recreation
      kubectl get pods --all-namespaces --no-headers | grep -E "Error|CrashLoopBackOff" | while read -r namespace pod_name rest; do
        log "INFO" "Deleting failed pod: ${namespace}/${pod_name}"
        kubectl delete pod "${pod_name}" -n "${namespace}" --grace-period=0 --force 2>/dev/null || true
      done
      
      sleep 10
      
      local still_failed
      still_failed=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -E "Error|CrashLoopBackOff" | wc -l)
      
      if [ "${still_failed}" -lt "${failed_pods}" ]; then
        log "SUCCESS" "Some pod issues resolved"
        ((ISSUES_FIXED++))
      fi
    else
      log "INFO" "Fix: kubectl describe pod <pod-name> -n <namespace>"
    fi
    return 1
  fi
  
  log "SUCCESS" "All pods are running"
  return 0
}

check_disk_space() {
  log "INFO" "Checking disk space..."
  
  local disk_usage
  disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
  
  if [ "${disk_usage}" -gt 85 ]; then
    ((ISSUES_FOUND++))
    log "ERROR" "Disk usage is ${disk_usage}% (critical)"
    
    if [ "${AUTO_FIX}" = "true" ]; then
      log "FIX" "Attempting to free disk space..."
      
      # Clean docker/containerd images
      if command -v docker >/dev/null 2>&1; then
        log "INFO" "Pruning Docker images..."
        sudo docker system prune -af --volumes 2>/dev/null || true
      fi
      
      if command -v crictl >/dev/null 2>&1; then
        log "INFO" "Pruning containerd images..."
        sudo crictl rmi --prune 2>/dev/null || true
      fi
      
      # Clean journal logs
      log "INFO" "Cleaning journal logs..."
      sudo journalctl --vacuum-time=7d 2>/dev/null || true
      
      local new_usage
      new_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
      
      if [ "${new_usage}" -lt "${disk_usage}" ]; then
        log "SUCCESS" "Disk space freed (${disk_usage}% -> ${new_usage}%)"
        ((ISSUES_FIXED++))
      fi
    else
      log "INFO" "Fix: docker system prune -af or crictl rmi --prune"
    fi
    return 1
  fi
  
  log "SUCCESS" "Disk space is sufficient (${disk_usage}%)"
  return 0
}

check_dns() {
  log "INFO" "Checking DNS functionality..."
  
  local coredns_ready
  coredns_ready=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep "Running" | wc -l)
  
  if [ "${coredns_ready}" -eq 0 ]; then
    ((ISSUES_FOUND++))
    log "ERROR" "CoreDNS is not running"
    
    if [ "${AUTO_FIX}" = "true" ]; then
      log "FIX" "Attempting to fix CoreDNS..."
      
      # Restart CoreDNS pods
      kubectl rollout restart deployment/coredns -n kube-system 2>/dev/null || true
      
      sleep 10
      
      coredns_ready=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep "Running" | wc -l)
      
      if [ "${coredns_ready}" -gt 0 ]; then
        log "SUCCESS" "CoreDNS restarted"
        ((ISSUES_FIXED++))
      fi
    else
      log "INFO" "Fix: kubectl rollout restart deployment/coredns -n kube-system"
    fi
    return 1
  fi
  
  log "SUCCESS" "CoreDNS is running"
  return 0
}

check_memory() {
  log "INFO" "Checking memory usage..."
  
  local mem_usage
  mem_usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
  
  if [ "${mem_usage}" -gt 90 ]; then
    ((ISSUES_FOUND++))
    log "ERROR" "Memory usage is ${mem_usage}% (critical)"
    
    if [ "${AUTO_FIX}" = "true" ]; then
      log "FIX" "Memory is critically low - cannot auto-fix"
      log "INFO" "Consider: 1) Reducing pod count, 2) Adding more RAM, 3) Using resource limits"
    else
      log "INFO" "Fix: Reduce pod count or add resource limits"
    fi
    return 1
  fi
  
  log "SUCCESS" "Memory usage is acceptable (${mem_usage}%)"
  return 0
}

check_kubeconfig_permissions() {
  log "INFO" "Checking kubeconfig permissions..."
  
  if [ ! -f "${KUBECONFIG_FILE}" ]; then
    ((ISSUES_FOUND++))
    log "ERROR" "Kubeconfig not found at ${KUBECONFIG_FILE}"
    
    if [ "${AUTO_FIX}" = "true" ]; then
      log "FIX" "Attempting to create kubeconfig..."
      
      if [ -f /etc/rancher/k3s/k3s.yaml ]; then
        mkdir -p "$HOME/.kube"
        sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
        sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
        chmod 600 "$HOME/.kube/config"
        log "SUCCESS" "Kubeconfig created"
        ((ISSUES_FIXED++))
      fi
    else
      log "INFO" "Fix: cp /etc/rancher/k3s/k3s.yaml ~/.kube/config"
    fi
    return 1
  fi
  
  # Check permissions
  local perms
  perms=$(stat -c "%a" "${KUBECONFIG_FILE}" 2>/dev/null || stat -f "%A" "${KUBECONFIG_FILE}" 2>/dev/null)
  
  if [ "${perms}" != "600" ]; then
    ((ISSUES_FOUND++))
    log "WARNING" "Kubeconfig permissions are ${perms} (should be 600)"
    
    if [ "${AUTO_FIX}" = "true" ]; then
      chmod 600 "${KUBECONFIG_FILE}"
      log "SUCCESS" "Kubeconfig permissions fixed"
      ((ISSUES_FIXED++))
    else
      log "INFO" "Fix: chmod 600 ${KUBECONFIG_FILE}"
    fi
    return 1
  fi
  
  log "SUCCESS" "Kubeconfig permissions are correct"
  return 0
}

generate_report() {
  echo ""
  log "HEADER" "╔════════════════════════════════════════╗"
  log "HEADER" "║   Troubleshooting Summary              ║"
  log "HEADER" "╚════════════════════════════════════════╝"
  echo ""
  
  log "INFO" "Issues found: ${ISSUES_FOUND}"
  
  if [ "${AUTO_FIX}" = "true" ]; then
    log "INFO" "Issues fixed: ${ISSUES_FIXED}"
    
    if [ "${ISSUES_FIXED}" -gt 0 ]; then
      log "SUCCESS" "Some issues were automatically resolved"
    fi
    
    if [ $((ISSUES_FOUND - ISSUES_FIXED)) -gt 0 ]; then
      log "WARNING" "$((ISSUES_FOUND - ISSUES_FIXED)) issue(s) require manual intervention"
    fi
  else
    log "INFO" "Run with AUTO_FIX=true to attempt automatic fixes"
  fi
  
  echo ""
  
  if [ "${ISSUES_FOUND}" -eq 0 ]; then
    log "SUCCESS" "No issues detected - cluster is healthy!"
  fi
}

main() {
  log "HEADER" "╔════════════════════════════════════════╗"
  log "HEADER" "║   Kubernetes Troubleshooter            ║"
  log "HEADER" "╚════════════════════════════════════════╝"
  echo ""
  
  if [ "${AUTO_FIX}" = "true" ]; then
    log "WARNING" "Auto-fix mode enabled - changes will be made automatically"
    echo ""
  fi
  
  # Run checks
  check_kubectl || true
  echo ""
  
  check_kubeconfig_permissions || true
  echo ""
  
  check_cluster_connectivity || true
  echo ""
  
  check_node_status || true
  echo ""
  
  check_pod_status || true
  echo ""
  
  check_dns || true
  echo ""
  
  check_disk_space || true
  echo ""
  
  check_memory || true
  
  # Generate report
  generate_report
  
  # Exit code
  if [ "${ISSUES_FOUND}" -eq 0 ]; then
    exit 0
  elif [ "${AUTO_FIX}" = "true" ] && [ "${ISSUES_FIXED}" -eq "${ISSUES_FOUND}" ]; then
    exit 0
  else
    exit 1
  fi
}

main "$@"
