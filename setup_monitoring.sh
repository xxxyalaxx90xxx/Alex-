#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Kubernetes Monitoring Setup Script
# ============================================================================
# Sets up monitoring stack (Prometheus, Grafana, Metrics Server)
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

MONITORING_NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
INSTALL_METRICS_SERVER="${INSTALL_METRICS_SERVER:-true}"
INSTALL_PROMETHEUS="${INSTALL_PROMETHEUS:-true}"
INSTALL_GRAFANA="${INSTALL_GRAFANA:-true}"

KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}
if [ -f /etc/rancher/k3s/k3s.yaml ] && [ ! -f "$HOME/.kube/config" ]; then
  KUBECONFIG_FILE=/etc/rancher/k3s/k3s.yaml
fi

export KUBECONFIG="${KUBECONFIG_FILE}"

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
  esac
}

check_prerequisites() {
  log "INFO" "Checking prerequisites..."
  
  if ! command -v kubectl >/dev/null 2>&1; then
    log "ERROR" "kubectl not found"
    exit 1
  fi
  
  if ! kubectl cluster-info >/dev/null 2>&1; then
    log "ERROR" "Cannot connect to cluster"
    exit 1
  fi
  
  log "SUCCESS" "Prerequisites OK"
}

install_metrics_server() {
  log "HEADER" "=== Installing Metrics Server ==="
  echo ""
  
  log "INFO" "Checking if Metrics Server is already installed..."
  if kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
    log "WARNING" "Metrics Server already installed"
    return 0
  fi
  
  log "INFO" "Downloading Metrics Server manifest..."
  local metrics_manifest
  metrics_manifest=$(mktemp)
  
  if ! curl -fsSL https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml -o "${metrics_manifest}"; then
    log "ERROR" "Failed to download Metrics Server manifest"
    rm -f "${metrics_manifest}"
    return 1
  fi
  
  log "INFO" "Applying Metrics Server manifest..."
  kubectl apply -f "${metrics_manifest}"
  
  rm -f "${metrics_manifest}"
  
  log "INFO" "Waiting for Metrics Server to be ready..."
  kubectl wait --for=condition=available --timeout=120s deployment/metrics-server -n kube-system 2>/dev/null || true
  
  log "SUCCESS" "Metrics Server installed"
  echo ""
}

install_prometheus() {
  log "HEADER" "=== Installing Prometheus ==="
  echo ""
  
  # Create namespace
  log "INFO" "Creating monitoring namespace..."
  kubectl create namespace "${MONITORING_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
  
  # Create Prometheus configuration
  log "INFO" "Creating Prometheus configuration..."
  
  cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    scrape_configs:
      - job_name: 'kubernetes-apiservers'
        kubernetes_sd_configs:
        - role: endpoints
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: default;kubernetes;https
      
      - job_name: 'kubernetes-nodes'
        kubernetes_sd_configs:
        - role: node
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
          action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
          target_label: __address__
EOF
  
  # Create Prometheus deployment
  log "INFO" "Creating Prometheus deployment..."
  
  cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        args:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus'
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
        - name: storage
          mountPath: /prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
      - name: storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: NodePort
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
EOF
  
  log "INFO" "Waiting for Prometheus to be ready..."
  kubectl wait --for=condition=available --timeout=120s deployment/prometheus -n "${MONITORING_NAMESPACE}" 2>/dev/null || true
  
  log "SUCCESS" "Prometheus installed"
  
  # Get NodePort
  local nodeport
  nodeport=$(kubectl get service prometheus -n "${MONITORING_NAMESPACE}" -o jsonpath='{.spec.ports[0].nodePort}')
  log "INFO" "Prometheus accessible at: http://<node-ip>:${nodeport}"
  echo ""
}

install_grafana() {
  log "HEADER" "=== Installing Grafana ==="
  echo ""
  
  # Create Grafana deployment
  log "INFO" "Creating Grafana deployment..."
  
  cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
      volumes:
      - name: grafana-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: NodePort
EOF
  
  log "INFO" "Waiting for Grafana to be ready..."
  kubectl wait --for=condition=available --timeout=120s deployment/grafana -n "${MONITORING_NAMESPACE}" 2>/dev/null || true
  
  log "SUCCESS" "Grafana installed"
  
  # Get NodePort
  local nodeport
  nodeport=$(kubectl get service grafana -n "${MONITORING_NAMESPACE}" -o jsonpath='{.spec.ports[0].nodePort}')
  log "INFO" "Grafana accessible at: http://<node-ip>:${nodeport}"
  log "INFO" "Default credentials - Username: admin, Password: admin"
  echo ""
}

show_summary() {
  log "HEADER" "=== Monitoring Setup Summary ==="
  echo ""
  
  log "INFO" "Installed components:"
  
  if [ "${INSTALL_METRICS_SERVER}" = "true" ]; then
    echo "  ✓ Metrics Server (in kube-system namespace)"
  fi
  
  if [ "${INSTALL_PROMETHEUS}" = "true" ]; then
    local prom_port
    prom_port=$(kubectl get service prometheus -n "${MONITORING_NAMESPACE}" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
    echo "  ✓ Prometheus (NodePort: ${prom_port})"
  fi
  
  if [ "${INSTALL_GRAFANA}" = "true" ]; then
    local grafana_port
    grafana_port=$(kubectl get service grafana -n "${MONITORING_NAMESPACE}" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
    echo "  ✓ Grafana (NodePort: ${grafana_port})"
  fi
  
  echo ""
  log "INFO" "Access instructions:"
  log "INFO" "  1. Get node IP: kubectl get nodes -o wide"
  log "INFO" "  2. Access Prometheus: http://<node-ip>:<prometheus-port>"
  log "INFO" "  3. Access Grafana: http://<node-ip>:<grafana-port>"
  log "INFO" "  4. Add Prometheus as datasource in Grafana: http://prometheus:9090"
  
  echo ""
  log "INFO" "Test metrics server:"
  log "INFO" "  kubectl top nodes"
  log "INFO" "  kubectl top pods --all-namespaces"
}

main() {
  log "HEADER" "╔════════════════════════════════════════╗"
  log "HEADER" "║   Kubernetes Monitoring Setup          ║"
  log "HEADER" "╚════════════════════════════════════════╝"
  echo ""
  
  check_prerequisites
  echo ""
  
  if [ "${INSTALL_METRICS_SERVER}" = "true" ]; then
    install_metrics_server
  fi
  
  if [ "${INSTALL_PROMETHEUS}" = "true" ]; then
    install_prometheus
  fi
  
  if [ "${INSTALL_GRAFANA}" = "true" ]; then
    install_grafana
  fi
  
  show_summary
  
  echo ""
  log "SUCCESS" "═══════════════════════════════════════════════════════"
  log "SUCCESS" " Monitoring setup completed!"
  log "SUCCESS" "═══════════════════════════════════════════════════════"
}

main "$@"
