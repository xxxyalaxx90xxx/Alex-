#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Kubernetes/K3s Upgrade Script
# ============================================================================
# Upgrades Kubernetes or K3s to a newer version
# Backs up configuration before upgrading
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

SUDO_CMD="sudo"
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  SUDO_CMD=""
fi

BACKUP_BEFORE_UPGRADE=${BACKUP_BEFORE_UPGRADE:-true}
TARGET_VERSION="${1:-}"

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

detect_installation() {
  local install_type="none"
  
  if command -v k3s >/dev/null 2>&1; then
    install_type="k3s"
  elif command -v kubeadm >/dev/null 2>&1; then
    install_type="kubeadm"
  fi
  
  echo "${install_type}"
}

get_current_version() {
  local install_type="$1"
  
  case "${install_type}" in
    k3s)
      k3s --version 2>/dev/null | head -1 | awk '{print $3}' || echo "unknown"
      ;;
    kubeadm)
      kubeadm version -o short 2>/dev/null || echo "unknown"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

backup_before_upgrade() {
  log "INFO" "Creating backup before upgrade..."
  
  if [ -f "./backup_k8s.sh" ]; then
    if bash ./backup_k8s.sh backup; then
      log "SUCCESS" "Backup created successfully"
      return 0
    else
      log "WARNING" "Backup creation failed"
      return 1
    fi
  else
    log "WARNING" "backup_k8s.sh not found, skipping backup"
    return 1
  fi
}

upgrade_k3s() {
  local target_version="$1"
  
  log "HEADER" "=== Upgrading K3s ==="
  echo ""
  
  local current_version
  current_version=$(get_current_version "k3s")
  
  log "INFO" "Current version: ${current_version}"
  
  if [ -n "${target_version}" ]; then
    log "INFO" "Target version: ${target_version}"
  else
    log "INFO" "Target version: latest"
  fi
  
  echo ""
  
  # Download K3s install script
  log "INFO" "Downloading K3s upgrade script..."
  local k3s_installer
  k3s_installer=$(mktemp)
  
  if ! curl -fsSL https://get.k3s.io -o "${k3s_installer}"; then
    log "ERROR" "Failed to download K3s installer"
    rm -f "${k3s_installer}"
    exit 1
  fi
  
  # Run upgrade
  log "INFO" "Running K3s upgrade..."
  
  if [ -n "${target_version}" ]; then
    INSTALL_K3S_VERSION="${target_version}" sh "${k3s_installer}"
  else
    sh "${k3s_installer}"
  fi
  
  rm -f "${k3s_installer}"
  
  # Verify upgrade
  local new_version
  new_version=$(get_current_version "k3s")
  
  log "SUCCESS" "K3s upgraded successfully"
  log "INFO" "New version: ${new_version}"
  
  # Restart K3s
  log "INFO" "Restarting K3s service..."
  $SUDO_CMD systemctl restart k3s
  
  # Wait for cluster to be ready
  log "INFO" "Waiting for cluster to be ready..."
  sleep 10
  
  local kubeconfig="/etc/rancher/k3s/k3s.yaml"
  if [ -f "$HOME/.kube/config" ]; then
    kubeconfig="$HOME/.kube/config"
  fi
  
  if KUBECONFIG="${kubeconfig}" kubectl get nodes >/dev/null 2>&1; then
    log "SUCCESS" "Cluster is ready"
  else
    log "WARNING" "Cluster may not be fully ready yet"
  fi
}

upgrade_kubeadm() {
  local target_version="$1"
  
  log "HEADER" "=== Upgrading Kubernetes (kubeadm) ==="
  echo ""
  
  local current_version
  current_version=$(get_current_version "kubeadm")
  
  log "INFO" "Current version: ${current_version}"
  
  if [ -z "${target_version}" ]; then
    log "ERROR" "Target version must be specified for kubeadm upgrade"
    log "INFO" "Usage: $0 <version> (e.g., $0 1.29.0)"
    exit 1
  fi
  
  log "INFO" "Target version: ${target_version}"
  echo ""
  
  # Detect package manager
  local pkg_manager=""
  if command -v apt-get >/dev/null 2>&1; then
    pkg_manager="apt"
  elif command -v yum >/dev/null 2>&1; then
    pkg_manager="yum"
  elif command -v dnf >/dev/null 2>&1; then
    pkg_manager="dnf"
  else
    log "ERROR" "Unsupported package manager"
    exit 1
  fi
  
  # Upgrade kubeadm first
  log "INFO" "Upgrading kubeadm..."
  
  case "${pkg_manager}" in
    apt)
      $SUDO_CMD apt-mark unhold kubeadm
      $SUDO_CMD apt-get update
      $SUDO_CMD apt-get install -y kubeadm="${target_version}-*"
      $SUDO_CMD apt-mark hold kubeadm
      ;;
    yum|dnf)
      $SUDO_CMD ${pkg_manager} install -y kubeadm-"${target_version}"
      ;;
  esac
  
  # Plan upgrade
  log "INFO" "Planning upgrade..."
  $SUDO_CMD kubeadm upgrade plan
  
  echo ""
  log "WARNING" "This will upgrade the control plane components"
  read -p "Continue with upgrade? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "INFO" "Upgrade cancelled"
    exit 0
  fi
  
  # Apply upgrade
  log "INFO" "Applying upgrade..."
  $SUDO_CMD kubeadm upgrade apply "v${target_version}" -y
  
  # Upgrade kubelet and kubectl
  log "INFO" "Upgrading kubelet and kubectl..."
  
  case "${pkg_manager}" in
    apt)
      $SUDO_CMD apt-mark unhold kubelet kubectl
      $SUDO_CMD apt-get install -y kubelet="${target_version}-*" kubectl="${target_version}-*"
      $SUDO_CMD apt-mark hold kubelet kubectl
      ;;
    yum|dnf)
      $SUDO_CMD ${pkg_manager} install -y kubelet-"${target_version}" kubectl-"${target_version}"
      ;;
  esac
  
  # Restart kubelet
  log "INFO" "Restarting kubelet..."
  $SUDO_CMD systemctl daemon-reload
  $SUDO_CMD systemctl restart kubelet
  
  # Wait for cluster to be ready
  log "INFO" "Waiting for cluster to be ready..."
  sleep 15
  
  if kubectl get nodes >/dev/null 2>&1; then
    log "SUCCESS" "Cluster is ready"
  else
    log "WARNING" "Cluster may not be fully ready yet"
  fi
  
  log "SUCCESS" "Kubernetes upgraded successfully"
  log "INFO" "New version: $(get_current_version 'kubeadm')"
}

show_usage() {
  cat <<EOF
Kubernetes/K3s Upgrade Script

Usage: $0 [version]

Arguments:
  version     Target version (optional for K3s, required for kubeadm)
              Examples: v1.28.5+k3s1 (K3s), 1.29.0 (kubeadm)

Environment Variables:
  BACKUP_BEFORE_UPGRADE    Create backup before upgrade (default: true)

Examples:
  # Upgrade K3s to latest
  $0

  # Upgrade K3s to specific version
  $0 v1.28.5+k3s1

  # Upgrade kubeadm to specific version
  $0 1.29.0

  # Skip backup
  BACKUP_BEFORE_UPGRADE=false $0

Notes:
  - Always backup before upgrading production systems
  - Test upgrades in non-production environment first
  - Read release notes before upgrading
  - Upgrades are done in-place (no downtime for K3s, brief downtime for kubeadm)

EOF
}

main() {
  if [ "${TARGET_VERSION}" = "-h" ] || [ "${TARGET_VERSION}" = "--help" ]; then
    show_usage
    exit 0
  fi
  
  log "HEADER" "╔════════════════════════════════════════╗"
  log "HEADER" "║   Kubernetes Upgrade Script            ║"
  log "HEADER" "╚════════════════════════════════════════╝"
  echo ""
  
  # Detect installation
  local install_type
  install_type=$(detect_installation)
  
  if [ "${install_type}" = "none" ]; then
    log "ERROR" "No Kubernetes installation detected"
    exit 1
  fi
  
  log "INFO" "Detected installation: ${install_type}"
  
  # Create backup if enabled
  if [ "${BACKUP_BEFORE_UPGRADE}" = "true" ]; then
    backup_before_upgrade || log "WARNING" "Continuing without backup"
    echo ""
  fi
  
  # Perform upgrade
  case "${install_type}" in
    k3s)
      upgrade_k3s "${TARGET_VERSION}"
      ;;
    kubeadm)
      upgrade_kubeadm "${TARGET_VERSION}"
      ;;
  esac
  
  echo ""
  log "SUCCESS" "═══════════════════════════════════════════════════════"
  log "SUCCESS" " Upgrade completed successfully!"
  log "SUCCESS" "═══════════════════════════════════════════════════════"
  echo ""
  log "INFO" "Next steps:"
  log "INFO" "  1. Verify cluster: kubectl get nodes"
  log "INFO" "  2. Check pods: kubectl get pods --all-namespaces"
  log "INFO" "  3. Run validation: ./validate_k8s.sh"
  log "INFO" "  4. Run analysis: ./analyze_k8s.sh"
}

main "$@"
