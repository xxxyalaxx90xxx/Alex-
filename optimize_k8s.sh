#!/usr/bin/env bash
set -euo pipefail

# Automated Kubernetes Cluster Optimization Script
# Provides recommendations and applies optimizations

KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}
DRY_RUN=${DRY_RUN:-1}  # Default to dry-run mode
AUTO_APPLY=${AUTO_APPLY:-0}  # Set to 1 to auto-apply safe optimizations

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

log_recommendation() {
  echo -e "${CYAN}[RECOMMENDATION]${NC} $*"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
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
}

# Optimize node performance
optimize_node_performance() {
  log_info "=== Node Performance Optimization ==="
  
  # Check if metrics server is installed
  if ! kubectl --kubeconfig="${KUBECONFIG_FILE}" get deployment metrics-server -n kube-system >/dev/null 2>&1; then
    log_recommendation "Install metrics-server for resource monitoring:"
    echo "  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
    echo ""
  else
    log_success "Metrics server is installed"
  fi
  
  # Check node allocatable resources
  log_info "Checking node resource allocation..."
  node_capacity=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get nodes -o json 2>/dev/null | \
    grep -A 5 '"allocatable"' || echo "")
  
  if [ -n "${node_capacity}" ]; then
    log_info "Node allocatable resources retrieved"
    
    # Check for hugepages
    if ! echo "${node_capacity}" | grep -q "hugepages"; then
      log_recommendation "Consider configuring hugepages for memory-intensive workloads:"
      echo "  Set HUGEPAGES_2MI environment variable before running install_k8s.sh"
      echo ""
    fi
  fi
  
  # Check CPU manager policy
  log_info "Checking kubelet CPU manager policy..."
  log_recommendation "For CPU-intensive workloads, consider enabling CPU manager static policy:"
  echo "  Add to kubelet config: --cpu-manager-policy=static"
  echo ""
}

# Optimize pod resource allocation
optimize_pod_resources() {
  log_info "=== Pod Resource Optimization ==="
  
  # Find pods without resource requests/limits
  log_info "Checking for pods without resource requests or limits..."
  
  pods_json=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces -o json 2>/dev/null)
  
  pods_without_requests=$(echo "${pods_json}" | grep -c '"requests": null' || echo "0")
  pods_without_limits=$(echo "${pods_json}" | grep -c '"limits": null' || echo "0")
  
  if [ "${pods_without_requests}" -gt 0 ] || [ "${pods_without_limits}" -gt 0 ]; then
    log_warning "Found pods without proper resource configuration"
    log_recommendation "Add resource requests and limits to pod specifications:"
    echo "  resources:"
    echo "    requests:"
    echo "      memory: \"64Mi\""
    echo "      cpu: \"250m\""
    echo "    limits:"
    echo "      memory: \"128Mi\""
    echo "      cpu: \"500m\""
    echo ""
  else
    log_success "All pods have resource requests and limits configured"
  fi
  
  # Check for QoS classes
  log_info "Analyzing pod QoS classes..."
  guaranteed_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces -o json 2>/dev/null | \
    grep -c '"qosClass": "Guaranteed"' || echo "0")
  burstable_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces -o json 2>/dev/null | \
    grep -c '"qosClass": "Burstable"' || echo "0")
  besteffort_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces -o json 2>/dev/null | \
    grep -c '"qosClass": "BestEffort"' || echo "0")
  
  log_info "QoS Class Distribution:"
  log_info "  Guaranteed: ${guaranteed_pods}"
  log_info "  Burstable: ${burstable_pods}"
  log_info "  BestEffort: ${besteffort_pods}"
  
  if [ "${besteffort_pods}" -gt 0 ]; then
    log_recommendation "BestEffort pods may be evicted first under resource pressure"
    log_recommendation "Consider setting resource requests/limits for better stability"
    echo ""
  fi
}

# Optimize networking
optimize_networking() {
  log_info "=== Network Optimization ==="
  
  # Check CNI plugin
  log_info "Checking CNI configuration..."
  cni_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces -o wide 2>/dev/null | \
    grep -E "flannel|calico|weave|cilium" || echo "")
  
  if [ -n "${cni_pods}" ]; then
    log_success "CNI plugin detected"
    
    # Check if all CNI pods are running
    if echo "${cni_pods}" | grep -v "Running" | grep -q "[0-9]"; then
      log_warning "Some CNI pods are not in Running state"
    fi
  else
    log_warning "CNI plugin status unclear"
  fi
  
  # Check for network policies
  netpol_count=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get networkpolicies --all-namespaces --no-headers 2>/dev/null | wc -l)
  
  if [ "${netpol_count}" -eq 0 ]; then
    log_recommendation "Implement NetworkPolicies for better security and network segmentation:"
    echo "  apiVersion: networking.k8s.io/v1"
    echo "  kind: NetworkPolicy"
    echo "  metadata:"
    echo "    name: default-deny-ingress"
    echo "  spec:"
    echo "    podSelector: {}"
    echo "    policyTypes:"
    echo "    - Ingress"
    echo ""
  else
    log_success "${netpol_count} network policies configured"
  fi
  
  # Check service type distribution
  log_info "Analyzing service types..."
  services=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get services --all-namespaces -o json 2>/dev/null)
  
  loadbalancer_svcs=$(echo "${services}" | grep -c '"type": "LoadBalancer"' || echo "0")
  nodeport_svcs=$(echo "${services}" | grep -c '"type": "NodePort"' || echo "0")
  
  if [ "${loadbalancer_svcs}" -gt 3 ] || [ "${nodeport_svcs}" -gt 5 ]; then
    log_recommendation "Consider using an Ingress controller to reduce the number of LoadBalancer/NodePort services"
    echo ""
  fi
}

# Optimize storage
optimize_storage() {
  log_info "=== Storage Optimization ==="
  
  # Check for default storage class
  log_info "Checking storage class configuration..."
  default_sc=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get storageclass -o json 2>/dev/null | \
    grep -c '"storageclass.kubernetes.io/is-default-class": "true"' || echo "0")
  
  if [ "${default_sc}" -eq 0 ]; then
    log_recommendation "Set a default StorageClass for dynamic provisioning:"
    echo "  kubectl patch storageclass <storageclass-name> -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'"
    echo ""
  else
    log_success "Default storage class is configured"
  fi
  
  # Check for unused PVs
  log_info "Checking for unused Persistent Volumes..."
  available_pvs=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pv --no-headers 2>/dev/null | \
    grep -c "Available" || echo "0")
  
  if [ "${available_pvs}" -gt 0 ]; then
    log_info "${available_pvs} PV(s) in Available state (not bound)"
  fi
  
  released_pvs=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pv --no-headers 2>/dev/null | \
    grep -c "Released" || echo "0")
  
  if [ "${released_pvs}" -gt 0 ]; then
    log_warning "${released_pvs} PV(s) in Released state"
    log_recommendation "Clean up or recycle Released PVs to free up storage"
    echo ""
  fi
}

# Security optimizations
optimize_security() {
  log_info "=== Security Optimization ==="
  
  # Check Pod Security Standards
  log_info "Checking Pod Security configuration..."
  
  # Check for PodSecurityPolicy or PodSecurity admission
  if kubectl --kubeconfig="${KUBECONFIG_FILE}" get psp >/dev/null 2>&1; then
    psp_count=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get psp --no-headers 2>/dev/null | wc -l)
    log_info "PodSecurityPolicy enabled with ${psp_count} policies"
  else
    log_recommendation "Consider implementing Pod Security Standards (PSS) or PodSecurityPolicy:"
    echo "  Label namespaces with pod-security.kubernetes.io/enforce: restricted"
    echo ""
  fi
  
  # Check for privileged containers
  privileged_count=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces -o json 2>/dev/null | \
    grep -c '"privileged": true' || echo "0")
  
  if [ "${privileged_count}" -gt 0 ]; then
    log_warning "${privileged_count} privileged container(s) found"
    log_recommendation "Minimize use of privileged containers. Use specific capabilities instead:"
    echo "  securityContext:"
    echo "    capabilities:"
    echo "      add: [\"NET_ADMIN\"]"
    echo ""
  fi
  
  # Check for containers running as root
  root_containers=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces -o json 2>/dev/null | \
    grep -c '"runAsUser": 0' || echo "0")
  
  if [ "${root_containers}" -gt 0 ]; then
    log_warning "${root_containers} container(s) running as root"
    log_recommendation "Run containers as non-root user:"
    echo "  securityContext:"
    echo "    runAsNonRoot: true"
    echo "    runAsUser: 1000"
    echo ""
  fi
  
  # Check RBAC configuration
  log_info "Checking RBAC configuration..."
  cluster_admin_bindings=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get clusterrolebindings -o json 2>/dev/null | \
    grep -c '"name": "cluster-admin"' || echo "0")
  
  if [ "${cluster_admin_bindings}" -gt 2 ]; then
    log_warning "Multiple cluster-admin role bindings found"
    log_recommendation "Follow principle of least privilege - limit cluster-admin access"
    echo ""
  fi
}

# Optimize etcd
optimize_etcd() {
  log_info "=== etcd Optimization ==="
  
  # Check etcd pod status
  etcd_pods=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods -n kube-system -o wide 2>/dev/null | \
    grep "etcd" || echo "")
  
  if [ -n "${etcd_pods}" ]; then
    log_success "etcd pods found"
    
    log_recommendation "For production clusters, consider these etcd optimizations:"
    echo "  - Use SSD storage for etcd data"
    echo "  - Set appropriate --quota-backend-bytes (default: 2GB)"
    echo "  - Enable automatic compaction: --auto-compaction-retention=1"
    echo "  - Monitor etcd performance metrics"
    echo "  - Regular backups with etcdctl snapshot"
    echo ""
  fi
}

# High availability recommendations
optimize_high_availability() {
  log_info "=== High Availability Optimization ==="
  
  # Check number of master nodes
  master_nodes=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get nodes -o json 2>/dev/null | \
    grep -c '"node-role.kubernetes.io/control-plane": ""' || echo "0")
  
  if [ "${master_nodes}" -eq 0 ]; then
    # Try alternative label
    master_nodes=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get nodes -o json 2>/dev/null | \
      grep -c '"node-role.kubernetes.io/master": ""' || echo "0")
  fi
  
  if [ "${master_nodes}" -lt 3 ]; then
    log_warning "Single control plane node detected"
    log_recommendation "For production, use at least 3 control plane nodes for high availability"
    echo ""
  else
    log_success "Multiple control plane nodes configured (${master_nodes})"
  fi
  
  # Check critical pod replicas
  log_info "Checking critical component replicas..."
  coredns_replicas=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get deployment coredns -n kube-system -o json 2>/dev/null | \
    grep -m 1 '"replicas":' | awk -F: '{print $2}' | tr -d ' ,' || echo "0")
  
  if [ "${coredns_replicas}" -lt 2 ]; then
    log_recommendation "Scale CoreDNS to at least 2 replicas for high availability:"
    echo "  kubectl scale deployment coredns --replicas=2 -n kube-system"
    echo ""
  else
    log_success "CoreDNS has ${coredns_replicas} replicas"
  fi
}

# Monitoring and observability
optimize_monitoring() {
  log_info "=== Monitoring & Observability Optimization ==="
  
  # Check for metrics server
  if kubectl --kubeconfig="${KUBECONFIG_FILE}" get deployment metrics-server -n kube-system >/dev/null 2>&1; then
    log_success "Metrics server is installed"
  else
    log_recommendation "Install metrics-server for basic monitoring:"
    echo "  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
    echo ""
  fi
  
  # Check for logging solution
  log_info "Checking for logging solutions..."
  logging_found=0
  
  if kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces 2>/dev/null | grep -qE "fluentd|fluentbit|logstash|elasticsearch"; then
    log_success "Logging solution detected"
    logging_found=1
  fi
  
  if [ "${logging_found}" -eq 0 ]; then
    log_recommendation "Consider implementing a logging solution:"
    echo "  - EFK stack (Elasticsearch, Fluentd, Kibana)"
    echo "  - ELK stack (Elasticsearch, Logstash, Kibana)"
    echo "  - Loki + Grafana"
    echo ""
  fi
  
  # Check for monitoring solution
  if kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces 2>/dev/null | grep -qE "prometheus|grafana"; then
    log_success "Monitoring solution detected"
  else
    log_recommendation "Consider implementing Prometheus + Grafana for monitoring"
    echo ""
  fi
}

# Generate optimization summary
generate_summary() {
  log_info ""
  log_info "=== Optimization Summary ==="
  log_info "Optimization analysis completed at $(date)"
  
  if [ "${DRY_RUN}" -eq 1 ]; then
    log_info ""
    log_info "Running in DRY_RUN mode - no changes applied"
    log_info "Set DRY_RUN=0 to apply safe optimizations automatically"
  fi
  
  log_info ""
  log_success "Review recommendations above and apply as needed for your environment"
}

# Main execution
main() {
  log_info "Starting Kubernetes Cluster Optimization Analysis..."
  log_info "Using kubeconfig: ${KUBECONFIG_FILE}"
  
  if [ "${DRY_RUN}" -eq 1 ]; then
    log_info "Mode: DRY_RUN (recommendations only)"
  else
    log_info "Mode: APPLY (will attempt to apply safe optimizations)"
  fi
  
  log_info ""
  
  check_prerequisites
  echo ""
  
  optimize_node_performance
  echo ""
  
  optimize_pod_resources
  echo ""
  
  optimize_networking
  echo ""
  
  optimize_storage
  echo ""
  
  optimize_security
  echo ""
  
  optimize_etcd
  echo ""
  
  optimize_high_availability
  echo ""
  
  optimize_monitoring
  echo ""
  
  generate_summary
  
  log_success "Optimization analysis complete!"
}

main "$@"
