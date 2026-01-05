#!/usr/bin/env bash
set -euo pipefail

# Automated kubeadm install script for CentOS/RHEL 7 style hosts.
# Options:
#   ADVERTISE_ADDRESS: API server advertise address (defaults to first host IP)
#   POD_CIDR:           Pod network CIDR (default: 10.244.0.0/16 for flannel)
#   HUGEPAGES_2MI:      Number of 2Mi hugepages to configure (optional)
#   KUBECONFIG_FILE:    Path to write kubeconfig for kubectl (default: $HOME/.kube/config)
#   FLANNEL_MANIFEST_URL: URL for the flannel manifest (default pinned commit)
#   FLANNEL_MANIFEST_SHA256: Expected SHA256 for the flannel manifest (leave empty to skip check)
#   MAX_RETRIES:        Maximum number of retries for network operations (default: 3)
#   RETRY_DELAY:        Delay between retries in seconds (default: 5)
#   STARTUP_WAIT_SECONDS: Wait time for cluster components to start (default: 5)
#   DRY_RUN:            If set to "true", only show what would be done (default: false)
#   SKIP_CHECKS:        Skip prerequisite checks if set to "true" (default: false)
#   ENABLE_COLORS:      Enable colored output (default: auto-detect TTY)

# Color support detection and setup
if [[ "${ENABLE_COLORS:-auto}" == "auto" ]]; then
  if [[ -t 1 ]]; then
    ENABLE_COLORS="true"
  else
    ENABLE_COLORS="false"
  fi
fi

# Color codes
if [[ "${ENABLE_COLORS}" == "true" ]]; then
  COLOR_RESET='\033[0m'
  COLOR_INFO='\033[0;36m'     # Cyan
  COLOR_SUCCESS='\033[0;32m'  # Green
  COLOR_ERROR='\033[0;31m'    # Red
  COLOR_WARN='\033[0;33m'     # Yellow
else
  COLOR_RESET=''
  COLOR_INFO=''
  COLOR_SUCCESS=''
  COLOR_ERROR=''
  COLOR_WARN=''
fi

# Logging functions
log_info() {
  echo -e "${COLOR_INFO}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]${COLOR_RESET} $*"
}

log_error() {
  echo -e "${COLOR_ERROR}[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]${COLOR_RESET} $*" >&2
}

log_success() {
  echo -e "${COLOR_SUCCESS}[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS]${COLOR_RESET} $*"
}

log_warn() {
  echo -e "${COLOR_WARN}[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]${COLOR_RESET} $*"
}

# Retry function for network operations
retry_command() {
  local max_attempts="${MAX_RETRIES:-3}"
  local retry_delay="${RETRY_DELAY:-5}"
  local attempt=1
  local exit_code=0
  
  while [ $attempt -le $max_attempts ]; do
    if "$@"; then
      return 0
    fi
    exit_code=$?
    if [ $attempt -lt $max_attempts ]; then
      log_info "Command failed (attempt $attempt/$max_attempts), retrying in ${retry_delay}s..."
      sleep "$retry_delay"
    fi
    attempt=$((attempt + 1))
  done
  
  log_error "Command failed after $max_attempts attempts"
  return $exit_code
}

# Validation functions
validate_ip_address() {
  local ip="$1"
  # Check for valid IP format and reject leading zeros
  if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    IFS='.' read -ra OCTETS <<< "$ip"
    for octet in "${OCTETS[@]}"; do
      # Check for leading zeros (except for just "0")
      if [[ "${#octet}" -gt 1 && "${octet:0:1}" == "0" ]]; then
        return 1
      fi
      # Check octet is in valid range
      if [ "$octet" -gt 255 ]; then
        return 1
      fi
    done
    return 0
  fi
  return 1
}

validate_cidr() {
  local cidr="$1"
  if [[ "$cidr" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]{1,2})$ ]]; then
    # Extract IP and prefix
    local ip="${cidr%/*}"
    local prefix="${cidr#*/}"
    # Validate IP part
    if ! validate_ip_address "$ip"; then
      return 1
    fi
    # Validate prefix is numeric and in range 0-32
    if ! [[ "$prefix" =~ ^[0-9]+$ ]] || [ "$prefix" -gt 32 ]; then
      return 1
    fi
    return 0
  fi
  return 1
}

SUDO_CMD="sudo"
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  SUDO_CMD=""
fi

# Dry-run mode
DRY_RUN=${DRY_RUN:-false}
if [[ "${DRY_RUN}" == "true" ]]; then
  log_warn "DRY RUN MODE - No changes will be made"
  SUDO_CMD="echo [DRY-RUN] sudo"
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Prerequisite check function
check_prerequisites() {
  log_info "Checking prerequisites..."
  local failed=0
  
  # Check if running as root or with sudo
  if [[ "${DRY_RUN}" != "true" ]]; then
    if [[ "${EUID:-$(id -u)}" -ne 0 ]] && ! command_exists sudo; then
      log_error "This script must be run as root or with sudo available"
      failed=1
    fi
  fi
  
  # Check minimum memory requirement (2GB recommended)
  local min_memory_kb=$((2 * 1024 * 1024))
  local total_memory_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
  if [ "$total_memory_kb" -lt "$min_memory_kb" ]; then
    log_warn "System has less than 2GB RAM ($(( total_memory_kb / 1024 / 1024 ))GB). Kubernetes may not run properly."
  fi
  
  # Check disk space (minimum 10GB free in /var)
  if command_exists df; then
    local var_space_kb=$(df /var 2>/dev/null | awk 'NR==2 {print $4}')
    local min_disk_kb=$((10 * 1024 * 1024))
    if [ -n "$var_space_kb" ] && [ "$var_space_kb" -lt "$min_disk_kb" ]; then
      log_warn "Less than 10GB free space in /var ($(( var_space_kb / 1024 / 1024 ))GB available)"
    fi
  fi
  
  # Check network connectivity
  if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    log_warn "No internet connectivity detected. Installation may fail."
  fi
  
  # Check if ports are available
  for port in 6443 2379 2380 10250 10251 10252; do
    if command_exists ss && ss -tuln | grep -q ":${port} "; then
      log_warn "Port ${port} is already in use. Kubernetes may fail to start."
    fi
  done
  
  # Check if firewalld or iptables might interfere
  if systemctl is-active --quiet firewalld 2>/dev/null; then
    log_warn "firewalld is active. This may interfere with Kubernetes networking."
  fi
  
  if [ $failed -eq 1 ]; then
    log_error "Prerequisite checks failed"
    return 1
  fi
  
  log_success "Prerequisite checks passed"
  return 0
}

get_primary_ip() {
  if command_exists hostname; then
    ip_out=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -n "${ip_out}" ]; then
      echo "${ip_out}"
      return
    fi
  fi
  if command_exists ip; then
    ip route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'
  fi
}

resolve_path() {
  if command_exists realpath; then
    realpath -m "$1"
  elif command_exists python3; then
    python3 - "$1" <<'PY'
import pathlib, sys
print(pathlib.Path(sys.argv[1]).expanduser().resolve(strict=False))
PY
  else
    echo "$1"
  fi
}

# Backup existing configuration file
backup_file() {
  local file="$1"
  if [ -f "$file" ]; then
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backing up ${file} to ${backup}"
    if [[ "${DRY_RUN}" != "true" ]]; then
      $SUDO_CMD cp "$file" "$backup"
    fi
  fi
}

# Auto-detect and validate configuration
log_info "Detecting system configuration..."

# Run prerequisite checks unless skipped
SKIP_CHECKS=${SKIP_CHECKS:-false}
if [[ "${SKIP_CHECKS}" != "true" ]]; then
  if ! check_prerequisites; then
    log_error "Prerequisite checks failed. Set SKIP_CHECKS=true to bypass."
    exit 1
  fi
fi

# Detect available memory for better defaults
TOTAL_MEMORY_KB=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
TOTAL_MEMORY_GB=$((TOTAL_MEMORY_KB / 1024 / 1024))
log_info "Total system memory: ${TOTAL_MEMORY_GB} GB"

# Detect and validate IP address
ADVERTISE_ADDRESS=${ADVERTISE_ADDRESS:-$(get_primary_ip)}
if [ -z "${ADVERTISE_ADDRESS}" ]; then
  log_error "Unable to determine ADVERTISE_ADDRESS automatically. Set ADVERTISE_ADDRESS explicitly."
  exit 1
fi
if ! validate_ip_address "${ADVERTISE_ADDRESS}"; then
  log_error "Invalid ADVERTISE_ADDRESS: ${ADVERTISE_ADDRESS}"
  exit 1
fi
log_info "Using ADVERTISE_ADDRESS: ${ADVERTISE_ADDRESS}"

# Validate POD_CIDR
POD_CIDR=${POD_CIDR:-10.244.0.0/16}
if ! validate_cidr "${POD_CIDR}"; then
  log_error "Invalid POD_CIDR: ${POD_CIDR}"
  exit 1
fi
log_info "Using POD_CIDR: ${POD_CIDR}"

HUGEPAGES_2MI=${HUGEPAGES_2MI:-}
KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}
FLANNEL_COMMIT=${FLANNEL_COMMIT:-629cd70d816e56853aac967f92ed3dade7275baf}
FLANNEL_MANIFEST_URL=${FLANNEL_MANIFEST_URL:-"https://raw.githubusercontent.com/flannel-io/flannel/${FLANNEL_COMMIT}/Documentation/kube-flannel.yml"}
FLANNEL_MANIFEST_SHA256=${FLANNEL_MANIFEST_SHA256:-6583e9607befbf3c46cd04eb6fd960c2a446453b83699d95904bace95f49c410}
MAX_RETRIES=${MAX_RETRIES:-3}
RETRY_DELAY=${RETRY_DELAY:-5}

log_info "[1/6] Configure Kubernetes yum repository"
$SUDO_CMD tee /etc/yum.repos.d/kubernetes.repo >/dev/null <<'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF
log_success "Kubernetes repository configured"

log_info "[2/6] Set SELinux to permissive mode"
if [ -f /etc/selinux/config ]; then
  backup_file /etc/selinux/config
fi
$SUDO_CMD setenforce 0 2>/dev/null || true
$SUDO_CMD sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config || true
log_success "SELinux set to permissive mode"

log_info "[3/6] Install kubelet, kubeadm, kubectl"
if ! retry_command $SUDO_CMD yum install -y kubelet kubeadm kubectl; then
  log_error "Failed to install Kubernetes components"
  exit 1
fi
$SUDO_CMD systemctl enable --now kubelet
log_success "Kubernetes components installed and kubelet enabled"

log_info "[4/6] Ensure containerd has CRI enabled"
if ! command_exists containerd; then
  log_info "Installing containerd..."
  if ! retry_command $SUDO_CMD yum install -y containerd; then
    log_error "Failed to install containerd"
    exit 1
  fi
fi
$SUDO_CMD mkdir -p /etc/containerd
if [ ! -f /etc/containerd/config.toml ]; then
  log_info "Generating default containerd configuration..."
  $SUDO_CMD containerd config default | $SUDO_CMD tee /etc/containerd/config.toml >/dev/null
else
  backup_file /etc/containerd/config.toml
fi
# Pattern to match: disabled_plugins = ["cri"] or disabled_plugins = ['cri']
# This regex matches the line where CRI is explicitly disabled
CRI_DISABLED_PATTERN='^[[:space:]]*disabled_plugins[[:space:]]*=[[:space:]]*\[[[:space:]]*["\047]cri["\047][[:space:]]*\]'
CRI_DISABLED_REPLACEMENT='# disabled_plugins = ["cri"]'
if $SUDO_CMD grep -Eq "${CRI_DISABLED_PATTERN}" /etc/containerd/config.toml; then
  log_info "Enabling CRI plugin in containerd..."
  $SUDO_CMD sed -i -E "s/${CRI_DISABLED_PATTERN}/${CRI_DISABLED_REPLACEMENT}/g" /etc/containerd/config.toml
fi
$SUDO_CMD systemctl enable --now containerd
$SUDO_CMD systemctl restart containerd
log_success "Containerd configured with CRI enabled"

if [ -n "${HUGEPAGES_2MI}" ]; then
  if ! [[ "${HUGEPAGES_2MI}" =~ ^[0-9]+$ ]]; then
    log_error "HUGEPAGES_2MI must be a numeric value."
    exit 1
  fi
  requested_kb=$((HUGEPAGES_2MI * 2048))
  mem_available_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || true)
  mem_total_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || true)
  memory_limit_kb=""
  memory_label=""
  if [ -n "${mem_available_kb}" ]; then
    memory_limit_kb="${mem_available_kb}"
    memory_label="available"
  elif [ -n "${mem_total_kb}" ]; then
    memory_limit_kb="${mem_total_kb}"
    memory_label="total"
  fi
  if [ -n "${memory_limit_kb}" ] && [ "${requested_kb}" -ge "${memory_limit_kb}" ]; then
    log_error "HUGEPAGES_2MI requests ${requested_kb} KiB which exceeds ${memory_label} memory (${memory_limit_kb} KiB)."
    exit 1
  fi
  log_info "[5/6] Configure hugepages (${HUGEPAGES_2MI} x 2Mi)"
  printf '%s\n' "${HUGEPAGES_2MI}" | $SUDO_CMD tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages >/dev/null
  # Verify hugepages were configured
  actual_hugepages=$($SUDO_CMD cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages 2>/dev/null || echo "0")
  if [ "${actual_hugepages}" -eq "${HUGEPAGES_2MI}" ]; then
    log_success "Hugepages configured successfully: ${actual_hugepages} x 2Mi"
  else
    log_error "Failed to configure hugepages. Requested: ${HUGEPAGES_2MI}, Actual: ${actual_hugepages}"
    exit 1
  fi
else
  log_info "[5/6] Skip hugepage configuration (HUGEPAGES_2MI not set)"
fi

log_info "[6/6] Initialize control plane with kubeadm"
log_info "This may take several minutes..."
if ! $SUDO_CMD kubeadm init \
  --ignore-preflight-errors Swap \
  --apiserver-advertise-address="${ADVERTISE_ADDRESS}" \
  --pod-network-cidr="${POD_CIDR}"; then
  log_error "kubeadm initialization failed"
  exit 1
fi
log_success "Control plane initialized successfully"

log_info "[post] Configure kubectl access"
resolved_home=$(resolve_path "${HOME}")
resolved_kubeconfig=$(resolve_path "${KUBECONFIG_FILE}")

if [ -z "${resolved_kubeconfig}" ]; then
  log_error "Unable to resolve KUBECONFIG_FILE path."
  exit 1
fi

if [[ "${resolved_kubeconfig}" != "${resolved_home}" && "${resolved_kubeconfig}" != "${resolved_home}"/* ]]; then
  log_error "Refusing to write kubeconfig outside of ${resolved_home}. Set KUBECONFIG_FILE under your home directory."
  exit 1
fi

KUBECONFIG_FILE="${resolved_kubeconfig}"
$SUDO_CMD mkdir -p "$(dirname "${KUBECONFIG_FILE}")"
$SUDO_CMD cp /etc/kubernetes/admin.conf "${KUBECONFIG_FILE}"
$SUDO_CMD chown "$(id -u):$(id -g)" "${KUBECONFIG_FILE}"
log_success "kubectl configured at ${KUBECONFIG_FILE}"

log_info "[post] Deploy flannel CNI (${POD_CIDR})"
if ! command_exists curl; then
  log_error "curl is required to download the flannel manifest."
  exit 1
fi
manifest_tmp=$(mktemp)
cleanup_manifest() { rm -f "${manifest_tmp}"; }
trap cleanup_manifest EXIT

log_info "Downloading flannel manifest with retry logic..."
if ! retry_command curl -L --fail "${FLANNEL_MANIFEST_URL}" -o "${manifest_tmp}"; then
  log_error "Failed to download flannel manifest after multiple attempts"
  exit 1
fi

if [ -n "${FLANNEL_MANIFEST_SHA256}" ]; then
  log_info "Verifying flannel manifest checksum..."
  downloaded_sha=$(sha256sum "${manifest_tmp}" | awk '{print $1}')
  if [ "${downloaded_sha}" != "${FLANNEL_MANIFEST_SHA256}" ]; then
    log_error "Flannel manifest checksum mismatch (expected ${FLANNEL_MANIFEST_SHA256}, got ${downloaded_sha})."
    exit 1
  fi
  log_success "Flannel manifest checksum verified"
fi

log_info "Applying flannel manifest..."
if ! kubectl --kubeconfig="${KUBECONFIG_FILE}" apply -f "${manifest_tmp}"; then
  log_error "Failed to apply flannel manifest"
  exit 1
fi
log_success "Flannel CNI deployed"
trap - EXIT
cleanup_manifest

if [ -n "${HUGEPAGES_2MI}" ]; then
  log_info "[post] Restart kubelet to pick up hugepages"
  $SUDO_CMD systemctl restart kubelet
  log_success "Kubelet restarted"
fi

log_success "========================================="
log_success "Cluster initialization complete!"
log_success "========================================="
log_info ""
log_info "Configuration Summary:"
log_info "  - Advertise Address: ${ADVERTISE_ADDRESS}"
log_info "  - Pod Network CIDR: ${POD_CIDR}"
log_info "  - Kubeconfig: ${KUBECONFIG_FILE}"
if [ -n "${HUGEPAGES_2MI}" ]; then
  log_info "  - Hugepages: ${HUGEPAGES_2MI} x 2Mi"
fi
log_info ""
log_info "Verifying cluster health..."

# Wait for components to start (configurable)
STARTUP_WAIT_SECONDS=${STARTUP_WAIT_SECONDS:-5}
sleep "$STARTUP_WAIT_SECONDS"

# Comprehensive cluster health check
run_health_checks() {
  local check_failed=0
  
  log_info "Running comprehensive health checks..."
  
  # Check node status
  if command_exists kubectl; then
    log_info "Node status:"
    node_output=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get nodes -o wide 2>&1)
    if [ $? -eq 0 ]; then
      echo "$node_output"
      
      # Check if node is Ready
      if echo "$node_output" | grep -q " Ready "; then
        log_success "Node is Ready"
      else
        log_warn "Node is not in Ready state yet"
        check_failed=1
      fi
    else
      log_error "Unable to get node status - cluster may need more time to initialize"
      echo "$node_output"
      check_failed=1
    fi
    
    log_info ""
    log_info "System pods status:"
    pods_output=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get pods --all-namespaces 2>&1)
    if [ $? -eq 0 ]; then
      echo "$pods_output"
      
      # Count pending/failed pods
      pending_count=$(echo "$pods_output" | grep -c "Pending" || true)
      failed_count=$(echo "$pods_output" | grep -c "Error\|CrashLoopBackOff" || true)
      
      if [ "$pending_count" -gt 0 ]; then
        log_warn "${pending_count} pod(s) are in Pending state"
      fi
      if [ "$failed_count" -gt 0 ]; then
        log_warn "${failed_count} pod(s) are in Failed/Error state"
        check_failed=1
      fi
    else
      log_error "Unable to get pods status - cluster may need more time to initialize"
      echo "$pods_output"
      check_failed=1
    fi
    
    # Check component status
    log_info ""
    log_info "Kubernetes component status:"
    component_output=$(kubectl --kubeconfig="${KUBECONFIG_FILE}" get componentstatuses 2>&1)
    if [ $? -eq 0 ]; then
      echo "$component_output"
    else
      log_warn "Unable to get component status (this is normal for newer Kubernetes versions)"
    fi
    
    log_info ""
    log_info "To use kubectl, run: export KUBECONFIG=${KUBECONFIG_FILE}"
  else
    log_error "kubectl command not found in PATH"
    check_failed=1
  fi
  
  return $check_failed
}

# Check node status
run_health_checks

log_info ""
log_success "Installation completed successfully!"
log_info ""
log_info "Next steps:"
log_info "  1. Export kubeconfig: export KUBECONFIG=${KUBECONFIG_FILE}"
log_info "  2. Wait for all pods to be Running: kubectl get pods --all-namespaces -w"
log_info "  3. Deploy your applications"
log_info ""
log_info "Troubleshooting:"
log_info "  - Check logs: journalctl -u kubelet -f"
log_info "  - Check events: kubectl get events --all-namespaces"
log_info "  - Check pod logs: kubectl logs -n <namespace> <pod-name>"
