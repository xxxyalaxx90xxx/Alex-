#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Kubernetes Backup and Restore Script
# ============================================================================
# Backs up critical Kubernetes cluster configuration and resources
# Can restore from backup
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

BACKUP_DIR="${BACKUP_DIR:-${HOME}/k8s_backups}"
BACKUP_NAME="k8s_backup_$(date +%Y%m%d_%H%M%S)"
KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}

if [ -f /etc/rancher/k3s/k3s.yaml ] && [ ! -f "$HOME/.kube/config" ]; then
  KUBECONFIG_FILE=/etc/rancher/k3s/k3s.yaml
fi

export KUBECONFIG="${KUBECONFIG_FILE}"

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
    INFO)
      echo -e "${CYAN}ℹ ${message}${RESET}"
      ;;
  esac
}

backup_kubeconfig() {
  log "INFO" "Backing up kubeconfig..."
  
  if [ -f "${KUBECONFIG_FILE}" ]; then
    mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}/config"
    cp "${KUBECONFIG_FILE}" "${BACKUP_DIR}/${BACKUP_NAME}/config/kubeconfig"
    log "SUCCESS" "Kubeconfig backed up"
  else
    log "ERROR" "Kubeconfig not found at ${KUBECONFIG_FILE}"
  fi
}

backup_k3s_config() {
  log "INFO" "Backing up K3s configuration..."
  
  if [ -d /etc/rancher/k3s ]; then
    mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}/k3s"
    $SUDO_CMD cp -r /etc/rancher/k3s/* "${BACKUP_DIR}/${BACKUP_NAME}/k3s/" 2>/dev/null || true
    $SUDO_CMD chown -R "$(id -u):$(id -g)" "${BACKUP_DIR}/${BACKUP_NAME}/k3s" 2>/dev/null || true
    log "SUCCESS" "K3s configuration backed up"
  fi
}

backup_kubeadm_config() {
  log "INFO" "Backing up kubeadm configuration..."
  
  if [ -d /etc/kubernetes ]; then
    mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}/kubernetes"
    $SUDO_CMD cp -r /etc/kubernetes/* "${BACKUP_DIR}/${BACKUP_NAME}/kubernetes/" 2>/dev/null || true
    $SUDO_CMD chown -R "$(id -u):$(id -g)" "${BACKUP_DIR}/${BACKUP_NAME}/kubernetes" 2>/dev/null || true
    log "SUCCESS" "Kubernetes configuration backed up"
  fi
}

backup_etcd() {
  log "INFO" "Backing up etcd data..."
  
  if command -v etcdctl >/dev/null 2>&1; then
    mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}/etcd"
    
    # Try to backup etcd
    if $SUDO_CMD etcdctl snapshot save "${BACKUP_DIR}/${BACKUP_NAME}/etcd/snapshot.db" 2>/dev/null; then
      $SUDO_CMD chown "$(id -u):$(id -g)" "${BACKUP_DIR}/${BACKUP_NAME}/etcd/snapshot.db"
      log "SUCCESS" "etcd snapshot created"
    else
      log "INFO" "etcd snapshot failed (may require additional configuration)"
    fi
  else
    log "INFO" "etcdctl not available, skipping etcd backup"
  fi
}

backup_resources() {
  log "INFO" "Backing up Kubernetes resources..."
  
  mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}/resources"
  
  # Backup namespaces
  kubectl get namespaces -o yaml > "${BACKUP_DIR}/${BACKUP_NAME}/resources/namespaces.yaml" 2>/dev/null || true
  
  # Backup all resources in all namespaces
  local namespaces
  namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
  
  for ns in ${namespaces}; do
    mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}/resources/${ns}"
    
    # Deployments
    kubectl get deployments -n "${ns}" -o yaml > "${BACKUP_DIR}/${BACKUP_NAME}/resources/${ns}/deployments.yaml" 2>/dev/null || true
    
    # Services
    kubectl get services -n "${ns}" -o yaml > "${BACKUP_DIR}/${BACKUP_NAME}/resources/${ns}/services.yaml" 2>/dev/null || true
    
    # ConfigMaps
    kubectl get configmaps -n "${ns}" -o yaml > "${BACKUP_DIR}/${BACKUP_NAME}/resources/${ns}/configmaps.yaml" 2>/dev/null || true
    
    # Secrets (encrypted)
    kubectl get secrets -n "${ns}" -o yaml > "${BACKUP_DIR}/${BACKUP_NAME}/resources/${ns}/secrets.yaml" 2>/dev/null || true
    
    # PVCs
    kubectl get pvc -n "${ns}" -o yaml > "${BACKUP_DIR}/${BACKUP_NAME}/resources/${ns}/pvcs.yaml" 2>/dev/null || true
  done
  
  log "SUCCESS" "Kubernetes resources backed up"
}

backup_cluster() {
  log "INFO" "Starting cluster backup..."
  echo ""
  
  mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"
  
  backup_kubeconfig
  backup_k3s_config
  backup_kubeadm_config
  backup_etcd
  backup_resources
  
  # Create metadata file
  cat > "${BACKUP_DIR}/${BACKUP_NAME}/metadata.txt" <<EOF
Backup Date: $(date)
Hostname: $(hostname)
Kubernetes Version: $(kubectl version --short 2>/dev/null | head -1 || echo "Unknown")
EOF
  
  # Create tarball
  log "INFO" "Creating backup archive..."
  tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "${BACKUP_DIR}" "${BACKUP_NAME}"
  rm -rf "${BACKUP_DIR}/${BACKUP_NAME}"
  
  echo ""
  log "SUCCESS" "Backup completed successfully"
  log "INFO" "Backup location: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
  log "INFO" "Backup size: $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)"
}

list_backups() {
  log "INFO" "Available backups in ${BACKUP_DIR}:"
  echo ""
  
  if [ -d "${BACKUP_DIR}" ]; then
    find "${BACKUP_DIR}" -name "k8s_backup_*.tar.gz" -type f -exec ls -lh {} \; | awk '{print $9, "-", $5}' || echo "No backups found"
  else
    echo "No backup directory found"
  fi
}

restore_backup() {
  local backup_file="$1"
  
  if [ ! -f "${backup_file}" ]; then
    log "ERROR" "Backup file not found: ${backup_file}"
    exit 1
  fi
  
  log "INFO" "Restoring from backup: ${backup_file}"
  echo ""
  
  log "INFO" "Extracting backup..."
  local temp_dir
  temp_dir=$(mktemp -d)
  tar -xzf "${backup_file}" -C "${temp_dir}"
  
  local backup_name
  backup_name=$(basename "${backup_file}" .tar.gz)
  
  # Restore kubeconfig
  if [ -f "${temp_dir}/${backup_name}/config/kubeconfig" ]; then
    log "INFO" "Restoring kubeconfig..."
    mkdir -p "$(dirname "${KUBECONFIG_FILE}")"
    cp "${temp_dir}/${backup_name}/config/kubeconfig" "${KUBECONFIG_FILE}"
    log "SUCCESS" "Kubeconfig restored"
  fi
  
  # Restore resources
  if [ -d "${temp_dir}/${backup_name}/resources" ]; then
    log "INFO" "Restoring Kubernetes resources..."
    
    # Restore namespaces first
    if [ -f "${temp_dir}/${backup_name}/resources/namespaces.yaml" ]; then
      kubectl apply -f "${temp_dir}/${backup_name}/resources/namespaces.yaml" 2>/dev/null || true
    fi
    
    # Restore resources in each namespace
    for ns_dir in "${temp_dir}/${backup_name}/resources/"*/; do
      if [ -d "${ns_dir}" ]; then
        local ns
        ns=$(basename "${ns_dir}")
        
        if [ "${ns}" != "namespaces.yaml" ]; then
          log "INFO" "Restoring resources in namespace: ${ns}"
          
          # Apply all yamls in namespace directory
          for yaml in "${ns_dir}"/*.yaml; do
            if [ -f "${yaml}" ]; then
              kubectl apply -f "${yaml}" 2>/dev/null || true
            fi
          done
        fi
      fi
    done
    
    log "SUCCESS" "Resources restored"
  fi
  
  # Cleanup
  rm -rf "${temp_dir}"
  
  echo ""
  log "SUCCESS" "Restore completed successfully"
}

show_usage() {
  cat <<EOF
Kubernetes Backup and Restore Script

Usage: $0 [command] [options]

Commands:
  backup              Create a new backup
  restore <file>      Restore from backup file
  list                List available backups
  help                Show this help message

Environment Variables:
  BACKUP_DIR          Backup directory (default: ~/k8s_backups)
  KUBECONFIG_FILE     Kubeconfig file path

Examples:
  $0 backup
  $0 list
  $0 restore ~/k8s_backups/k8s_backup_20260105_120000.tar.gz

EOF
}

main() {
  local command="${1:-help}"
  
  case "${command}" in
    backup)
      backup_cluster
      ;;
    list)
      list_backups
      ;;
    restore)
      if [ $# -lt 2 ]; then
        log "ERROR" "Please specify backup file to restore"
        echo ""
        show_usage
        exit 1
      fi
      restore_backup "$2"
      ;;
    help|--help|-h)
      show_usage
      ;;
    *)
      log "ERROR" "Unknown command: ${command}"
      echo ""
      show_usage
      exit 1
      ;;
  esac
}

main "$@"
