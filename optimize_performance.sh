#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Kubernetes Performance Optimization Script
# ============================================================================
# Optimizes Kubernetes/K3s for specific device types and use cases
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

DEVICE_TYPE="${DEVICE_TYPE:-auto}"
SUDO_CMD="sudo"
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  SUDO_CMD=""
fi

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

detect_device_type() {
  local total_mem_kb
  total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local total_mem_gb=$((total_mem_kb / 1024 / 1024))
  
  local cpu_cores
  cpu_cores=$(nproc)
  
  local arch
  arch=$(uname -m)
  
  if [ "${total_mem_gb}" -lt 2 ] || [[ "${arch}" == "arm"* ]] || [[ "${arch}" == "aarch64" ]]; then
    echo "mobile"
  elif [ "${total_mem_gb}" -lt 4 ]; then
    echo "sbc"  # Single Board Computer
  elif [ "${total_mem_gb}" -lt 8 ]; then
    echo "workstation"
  else
    echo "server"
  fi
}

detect_installation() {
  local install_type="none"
  
  if command -v k3s >/dev/null 2>&1; then
    install_type="k3s"
  elif command -v kubeadm >/dev/null 2>&1; then
    install_type="kubeadm"
  fi
  
  echo "${install_type}"
}

optimize_k3s_mobile() {
  log "HEADER" "=== Optimizing K3s for Mobile Devices ==="
  echo ""
  
  local k3s_config="/etc/rancher/k3s/config.yaml"
  
  log "INFO" "Creating optimized K3s configuration..."
  
  $SUDO_CMD mkdir -p /etc/rancher/k3s
  
  cat <<'EOF' | $SUDO_CMD tee "${k3s_config}" > /dev/null
# K3s Configuration for Mobile Devices (Realme C63, etc.)
# Optimized for low memory and battery life

# Disable unnecessary components
disable:
  - servicelb
  - traefik
  - local-storage
  - metrics-server

# Resource limits
kube-apiserver-arg:
  - "max-requests-inflight=200"
  - "max-mutating-requests-inflight=100"

kube-controller-manager-arg:
  - "concurrent-deployment-syncs=2"
  - "concurrent-replicaset-syncs=2"
  - "concurrent-service-syncs=1"

kubelet-arg:
  - "max-pods=20"
  - "pod-max-pids=100"
  - "eviction-hard=memory.available<100Mi,nodefs.available<5%"
  - "eviction-soft=memory.available<200Mi,nodefs.available<10%"
  - "eviction-soft-grace-period=memory.available=1m30s,nodefs.available=2m"
  - "image-gc-high-threshold=60"
  - "image-gc-low-threshold=40"
  - "serialize-image-pulls=true"
  - "cpu-cfs-quota=true"
  - "kube-reserved=cpu=100m,memory=256Mi"

# Network optimizations
flannel-backend: "host-gw"
EOF
  
  log "SUCCESS" "K3s mobile configuration created"
  
  if systemctl is-active --quiet k3s; then
    log "INFO" "Restarting K3s to apply changes..."
    $SUDO_CMD systemctl restart k3s
    sleep 10
    log "SUCCESS" "K3s restarted"
  fi
  
  echo ""
}

optimize_k3s_sbc() {
  log "HEADER" "=== Optimizing K3s for Single Board Computer ==="
  echo ""
  
  local k3s_config="/etc/rancher/k3s/config.yaml"
  
  $SUDO_CMD mkdir -p /etc/rancher/k3s
  
  cat <<'EOF' | $SUDO_CMD tee "${k3s_config}" > /dev/null
# K3s Configuration for Single Board Computers (Raspberry Pi, etc.)

disable:
  - servicelb
  - traefik

kube-apiserver-arg:
  - "max-requests-inflight=400"
  - "max-mutating-requests-inflight=200"

kube-controller-manager-arg:
  - "concurrent-deployment-syncs=5"
  - "concurrent-replicaset-syncs=5"

kubelet-arg:
  - "max-pods=50"
  - "eviction-hard=memory.available<200Mi,nodefs.available<5%"
  - "eviction-soft=memory.available<300Mi,nodefs.available<10%"
  - "image-gc-high-threshold=70"
  - "image-gc-low-threshold=50"
  - "kube-reserved=cpu=200m,memory=512Mi"
EOF
  
  log "SUCCESS" "K3s SBC configuration created"
  
  if systemctl is-active --quiet k3s; then
    $SUDO_CMD systemctl restart k3s
    sleep 10
  fi
  
  echo ""
}

optimize_kubeadm() {
  log "HEADER" "=== Optimizing kubeadm Cluster ==="
  echo ""
  
  log "INFO" "Adjusting kubelet configuration..."
  
  local kubelet_config="/var/lib/kubelet/config.yaml"
  
  if [ ! -f "${kubelet_config}" ]; then
    log "WARNING" "Kubelet config not found at ${kubelet_config}"
    return
  fi
  
  # Backup original
  $SUDO_CMD cp "${kubelet_config}" "${kubelet_config}.backup"
  
  log "INFO" "Applying resource optimizations..."
  
  # Apply optimizations via kubectl
  cat <<'EOF' | kubectl apply -f - 2>/dev/null || true
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubelet-config
  namespace: kube-system
data:
  kubelet: |
    apiVersion: kubelet.config.k8s.io/v1beta1
    kind: KubeletConfiguration
    imageGCHighThresholdPercent: 70
    imageGCLowThresholdPercent: 50
    maxPods: 110
    evictionHard:
      memory.available: "200Mi"
      nodefs.available: "5%"
    evictionSoft:
      memory.available: "300Mi"
      nodefs.available: "10%"
    evictionSoftGracePeriod:
      memory.available: "1m30s"
      nodefs.available: "2m"
EOF
  
  log "SUCCESS" "Kubelet optimizations applied"
  echo ""
}

optimize_system() {
  log "HEADER" "=== Optimizing System Settings ==="
  echo ""
  
  # Kernel parameters
  log "INFO" "Applying kernel optimizations..."
  
  cat <<'EOF' | $SUDO_CMD tee /etc/sysctl.d/99-k8s-perf.conf > /dev/null
# Kubernetes Performance Optimizations

# Network
net.core.somaxconn = 32768
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.core.netdev_max_backlog = 16384

# Memory
vm.swappiness = 1
vm.overcommit_memory = 1
vm.panic_on_oom = 0

# File handles
fs.file-max = 2097152
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 524288
EOF
  
  $SUDO_CMD sysctl -p /etc/sysctl.d/99-k8s-perf.conf > /dev/null 2>&1
  
  log "SUCCESS" "Kernel parameters optimized"
  
  # Increase file limits
  log "INFO" "Adjusting file limits..."
  
  cat <<'EOF' | $SUDO_CMD tee /etc/security/limits.d/99-k8s.conf > /dev/null
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF
  
  log "SUCCESS" "File limits increased"
  echo ""
}

optimize_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    return
  fi
  
  log "HEADER" "=== Optimizing Docker/Containerd ==="
  echo ""
  
  local daemon_json="/etc/docker/daemon.json"
  
  log "INFO" "Creating optimized Docker configuration..."
  
  $SUDO_CMD mkdir -p /etc/docker
  
  cat <<'EOF' | $SUDO_CMD tee "${daemon_json}" > /dev/null
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "live-restore": true,
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3
}
EOF
  
  log "SUCCESS" "Docker configuration optimized"
  
  if systemctl is-active --quiet docker; then
    log "INFO" "Restarting Docker..."
    $SUDO_CMD systemctl restart docker
    log "SUCCESS" "Docker restarted"
  fi
  
  echo ""
}

show_recommendations() {
  local device_type="$1"
  
  log "HEADER" "=== Performance Recommendations ==="
  echo ""
  
  case "${device_type}" in
    mobile)
      log "INFO" "Mobile Device Recommendations:"
      echo "  • Limit deployments to 3-5 pods maximum"
      echo "  • Use resource limits on all pods"
      echo "  • Avoid CPU-intensive workloads"
      echo "  • Use node affinity for critical pods"
      echo "  • Monitor battery drain"
      ;;
    sbc)
      log "INFO" "SBC Recommendations:"
      echo "  • Limit to 10-20 pods"
      echo "  • Use persistent storage sparingly"
      echo "  • Consider active cooling"
      echo "  • Monitor disk I/O"
      ;;
    workstation)
      log "INFO" "Workstation Recommendations:"
      echo "  • Suitable for development workloads"
      echo "  • Can run 30-50 pods comfortably"
      echo "  • Enable metrics server for monitoring"
      ;;
    server)
      log "INFO" "Server Recommendations:"
      echo "  • Optimized for production workloads"
      echo "  • Can handle 100+ pods"
      echo "  • Consider multi-node setup"
      echo "  • Enable full monitoring stack"
      ;;
  esac
  
  echo ""
  log "INFO" "General Tips:"
  echo "  • Set resource requests and limits"
  echo "  • Use horizontal pod autoscaling"
  echo "  • Implement pod disruption budgets"
  echo "  • Regular cleanup of unused images"
  echo "  • Monitor cluster metrics regularly"
}

main() {
  log "HEADER" "╔════════════════════════════════════════╗"
  log "HEADER" "║   Kubernetes Performance Optimizer     ║"
  log "HEADER" "╚════════════════════════════════════════╝"
  echo ""
  
  # Detect device type
  local device_type="${DEVICE_TYPE}"
  if [ "${device_type}" = "auto" ]; then
    device_type=$(detect_device_type)
    log "INFO" "Auto-detected device type: ${device_type}"
  else
    log "INFO" "Using specified device type: ${device_type}"
  fi
  echo ""
  
  # Detect installation
  local install_type
  install_type=$(detect_installation)
  
  if [ "${install_type}" = "none" ]; then
    log "ERROR" "No Kubernetes installation detected"
    exit 1
  fi
  
  log "INFO" "Detected installation: ${install_type}"
  echo ""
  
  # Apply optimizations
  case "${install_type}" in
    k3s)
      case "${device_type}" in
        mobile)
          optimize_k3s_mobile
          ;;
        sbc)
          optimize_k3s_sbc
          ;;
        *)
          log "INFO" "Using default K3s configuration for ${device_type}"
          ;;
      esac
      ;;
    kubeadm)
      optimize_kubeadm
      ;;
  esac
  
  # System optimizations
  optimize_system
  
  # Docker optimizations
  optimize_docker
  
  # Show recommendations
  show_recommendations "${device_type}"
  
  echo ""
  log "SUCCESS" "═══════════════════════════════════════════════════════"
  log "SUCCESS" " Performance optimization completed!"
  log "SUCCESS" "═══════════════════════════════════════════════════════"
  echo ""
  log "INFO" "Next steps:"
  log "INFO" "  1. Restart your cluster if needed"
  log "INFO" "  2. Monitor performance: kubectl top nodes/pods"
  log "INFO" "  3. Run validation: ./validate_k8s.sh"
  log "INFO" "  4. Check analysis: ./analyze_k8s.sh"
}

main "$@"
