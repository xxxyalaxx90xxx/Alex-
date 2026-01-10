#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Kubernetes/K3s Uninstall Script
# ============================================================================
# This script uninstalls Kubernetes or K3s installations
# Usage: sudo ./uninstall_k8s.sh [--force]
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

SUDO_CMD="sudo"
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  SUDO_CMD=""
fi

FORCE_MODE=false
if [ "${1:-}" = "--force" ]; then
  FORCE_MODE=true
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
  esac
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

uninstall_k3s() {
  log "INFO" "Uninstalling K3s..."
  
  if [ -x /usr/local/bin/k3s-uninstall.sh ]; then
    log "INFO" "Running K3s uninstall script..."
    $SUDO_CMD /usr/local/bin/k3s-uninstall.sh
    log "SUCCESS" "K3s uninstalled"
  else
    log "WARNING" "K3s uninstall script not found"
    log "INFO" "Attempting manual cleanup..."
    
    # Stop and disable K3s service
    $SUDO_CMD systemctl stop k3s 2>/dev/null || true
    $SUDO_CMD systemctl disable k3s 2>/dev/null || true
    
    # Remove K3s files
    $SUDO_CMD rm -rf /etc/rancher/k3s
    $SUDO_CMD rm -rf /var/lib/rancher/k3s
    $SUDO_CMD rm -f /usr/local/bin/k3s
    $SUDO_CMD rm -f /usr/local/bin/kubectl
    $SUDO_CMD rm -f /usr/local/bin/crictl
    $SUDO_CMD rm -f /usr/local/bin/ctr
    
    log "SUCCESS" "Manual K3s cleanup complete"
  fi
}

uninstall_kubeadm() {
  log "INFO" "Uninstalling Kubernetes (kubeadm)..."
  
  # Reset kubeadm
  if command -v kubeadm >/dev/null 2>&1; then
    log "INFO" "Running kubeadm reset..."
    $SUDO_CMD kubeadm reset --force 2>/dev/null || true
    log "SUCCESS" "Kubeadm reset complete"
  fi
  
  # Stop and disable services
  $SUDO_CMD systemctl stop kubelet 2>/dev/null || true
  $SUDO_CMD systemctl disable kubelet 2>/dev/null || true
  $SUDO_CMD systemctl stop containerd 2>/dev/null || true
  $SUDO_CMD systemctl disable containerd 2>/dev/null || true
  
  # Detect package manager and remove packages
  if command -v yum >/dev/null 2>&1; then
    log "INFO" "Removing Kubernetes packages (yum)..."
    $SUDO_CMD yum remove -y kubelet kubeadm kubectl 2>/dev/null || true
  elif command -v dnf >/dev/null 2>&1; then
    log "INFO" "Removing Kubernetes packages (dnf)..."
    $SUDO_CMD dnf remove -y kubelet kubeadm kubectl 2>/dev/null || true
  elif command -v apt-get >/dev/null 2>&1; then
    log "INFO" "Removing Kubernetes packages (apt)..."
    $SUDO_CMD apt-mark unhold kubelet kubeadm kubectl 2>/dev/null || true
    $SUDO_CMD apt-get remove -y kubelet kubeadm kubectl 2>/dev/null || true
    $SUDO_CMD apt-get purge -y kubelet kubeadm kubectl 2>/dev/null || true
    $SUDO_CMD apt-get autoremove -y 2>/dev/null || true
  fi
  
  # Remove Kubernetes directories
  $SUDO_CMD rm -rf /etc/kubernetes
  $SUDO_CMD rm -rf /var/lib/kubelet
  $SUDO_CMD rm -rf /var/lib/etcd
  $SUDO_CMD rm -rf /etc/cni/net.d
  $SUDO_CMD rm -rf /opt/cni/bin
  
  # Remove repository files
  $SUDO_CMD rm -f /etc/yum.repos.d/kubernetes.repo
  $SUDO_CMD rm -f /etc/apt/sources.list.d/kubernetes.list
  $SUDO_CMD rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  
  log "SUCCESS" "Kubernetes uninstall complete"
}

cleanup_common() {
  log "INFO" "Cleaning up common files..."
  
  # Remove kubeconfig
  rm -f "${HOME}/.kube/config"
  rm -rf "${HOME}/.kube"
  
  # Remove installation state
  rm -f "${HOME}/.k8s_install_state"
  
  # Clean up iptables rules
  log "INFO" "Cleaning up iptables rules..."
  $SUDO_CMD iptables -F 2>/dev/null || true
  $SUDO_CMD iptables -t nat -F 2>/dev/null || true
  $SUDO_CMD iptables -t mangle -F 2>/dev/null || true
  $SUDO_CMD iptables -X 2>/dev/null || true
  
  # Remove CNI network interfaces
  log "INFO" "Removing CNI network interfaces..."
  # Match common CNI interface patterns: cni, flannel, weave, calico, cilium, vxlan, veth
  for iface in $(ip link show | grep -oP 'cni[0-9]+|flannel\.[0-9]+|weave[a-z0-9-]+|cali[a-z0-9]+|lxc[a-z0-9]+|vxlan\.[0-9]+|veth[a-z0-9]+|tunl[0-9]+' || true); do
    $SUDO_CMD ip link delete "${iface}" 2>/dev/null || true
  done
  
  log "SUCCESS" "Common cleanup complete"
}

main() {
  echo -e "${CYAN}╔════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║   Kubernetes Uninstall Script         ║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${RESET}"
  echo ""
  
  # Detect installation
  local install_type
  install_type=$(detect_installation)
  
  if [ "${install_type}" = "none" ]; then
    log "INFO" "No Kubernetes installation detected"
    exit 0
  fi
  
  log "INFO" "Detected installation type: ${install_type}"
  echo ""
  
  # Confirm uninstall
  if [ "${FORCE_MODE}" = false ]; then
    log "WARNING" "This will remove all Kubernetes components and data"
    read -p "Are you sure you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log "INFO" "Uninstall cancelled"
      exit 0
    fi
    echo ""
  fi
  
  # Perform uninstall
  case "${install_type}" in
    k3s)
      uninstall_k3s
      ;;
    kubeadm)
      uninstall_kubeadm
      ;;
  esac
  
  # Common cleanup
  cleanup_common
  
  echo ""
  log "SUCCESS" "═══════════════════════════════════════════════════════"
  log "SUCCESS" " Kubernetes uninstall completed successfully!"
  log "SUCCESS" "═══════════════════════════════════════════════════════"
  echo ""
  log "INFO" "You may need to reboot your system to complete the cleanup"
}

main "$@"
