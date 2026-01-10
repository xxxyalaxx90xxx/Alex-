#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Comprehensive Kubernetes/K3s Installation System
# ============================================================================
# Version: 2.0
# Supports: Multiple OS distributions, architectures, and device types
# Features: Auto-detection, validation, logging, rollback, health checks
#
# Supported OS: CentOS/RHEL 7-9, Ubuntu 18.04-24.04, Debian 9-12, 
#               Fedora 35+, Arch Linux, openSUSE, Alpine Linux, Termux
# Architectures: AMD64/x86_64, ARM64/aarch64, ARM/armv7l, ARM/armv6l
# Devices: Servers, workstations, mobile devices (Realme C63, etc.), 
#          Raspberry Pi, single-board computers
#
# Environment Variables:
#   INSTALL_MODE:        "full" (kubeadm) or "lightweight" (k3s) - auto-detected
#   ADVERTISE_ADDRESS:   API server advertise address (auto-detected)
#   POD_CIDR:            Pod network CIDR (10.244.0.0/16 or 10.42.0.0/16)
#   HUGEPAGES_2MI:       Number of 2Mi hugepages (optional, disabled on mobile)
#   KUBECONFIG_FILE:     Kubeconfig path (default: $HOME/.kube/config)
#   FLANNEL_MANIFEST_URL: Flannel manifest URL
#   K3S_VERSION:         Specific K3s version (optional)
#   KUBERNETES_VERSION:  Kubernetes version (default: 1.28)
#   MIN_MEMORY_MB:       Minimum memory required (1024 for k3s, 2048 for full)
#   LOG_FILE:            Installation log file path
#   NO_COLOR:            Disable colored output (set to any value)
#   SKIP_PREFLIGHT:      Skip preflight checks (not recommended)
#   AUTO_INSTALL:        Skip confirmations (for automation)
# ============================================================================

# Color definitions (unless NO_COLOR is set)
if [ -z "${NO_COLOR:-}" ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  MAGENTA='\033[0;35m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  MAGENTA=''
  CYAN=''
  BOLD=''
  RESET=''
fi

# Global configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_STATE_FILE="${HOME}/.k8s_install_state"
LOG_FILE="${LOG_FILE:-${HOME}/k8s_install_$(date +%Y%m%d_%H%M%S).log}"
BACKUP_DIR="${HOME}/.k8s_backup_$(date +%Y%m%d_%H%M%S)"

SUDO_CMD="sudo"
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  SUDO_CMD=""
fi

# ============================================================================
# Utility Functions
# ============================================================================

log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  echo "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
  
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
    PROGRESS)
      echo -e "${BLUE}▶ ${message}${RESET}"
      ;;
  esac
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
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

# ============================================================================
# System Detection Functions
# ============================================================================

detect_architecture() {
  local arch
  arch=$(uname -m)
  case "${arch}" in
    x86_64|amd64)
      echo "amd64"
      ;;
    aarch64|arm64)
      echo "arm64"
      ;;
    armv7l)
      echo "armv7"
      ;;
    armv6l)
      echo "armv6"
      ;;
    *)
      echo "unsupported"
      ;;
  esac
}

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "${ID}"
  elif command_exists lsb_release; then
    lsb_release -si | tr '[:upper:]' '[:lower:]'
  else
    echo "unknown"
  fi
}

detect_os_version() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "${VERSION_ID}"
  else
    echo "unknown"
  fi
}

get_available_memory() {
  local mem_kb
  mem_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
  echo $((mem_kb / 1024))
}

get_available_disk_space() {
  # Get available space in MB for root filesystem
  df / | awk 'NR==2 {print int($4/1024)}'
}

get_cpu_cores() {
  nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "1"
}

is_mobile_device() {
  local mem_mb
  mem_mb=$(get_available_memory)
  local cpu_cores
  cpu_cores=$(get_cpu_cores)
  
  # Check for Termux environment or low resources
  if [ -n "${TERMUX_VERSION:-}" ] || [ -n "${PREFIX:-}" ]; then
    return 0
  fi
  
  # Check for mobile device characteristics
  local arch
  arch=$(detect_architecture)
  if [ "${mem_mb}" -lt 4096 ] && [ "${cpu_cores}" -le 4 ] && [ "${arch}" != "amd64" ]; then
    return 0
  fi
  
  return 1
}

determine_install_mode() {
  local mem_mb
  mem_mb=$(get_available_memory)
  
  if [ -n "${INSTALL_MODE:-}" ]; then
    echo "${INSTALL_MODE}"
    return
  fi
  
  # Auto-detect based on resources
  if is_mobile_device || [ "${mem_mb}" -lt 2048 ]; then
    echo "lightweight"
  else
    echo "full"
  fi
}

# ============================================================================
# Preflight Checks
# ============================================================================

check_network_connectivity() {
  log "PROGRESS" "Checking network connectivity..."
  
  local test_urls=(
    "https://get.k3s.io"
    "https://pkgs.k8s.io"
    "https://github.com"
  )
  
  for url in "${test_urls[@]}"; do
    if command_exists curl; then
      if ! curl -s --connect-timeout 5 -o /dev/null "${url}"; then
        log "WARNING" "Cannot reach ${url}"
      else
        log "SUCCESS" "Network connectivity OK"
        return 0
      fi
    elif command_exists wget; then
      if ! wget -q --timeout=5 --spider "${url}"; then
        log "WARNING" "Cannot reach ${url}"
      else
        log "SUCCESS" "Network connectivity OK"
        return 0
      fi
    fi
  done
  
  log "WARNING" "Network connectivity check failed - installation may fail"
  return 1
}

check_disk_space() {
  log "PROGRESS" "Checking disk space..."
  
  local available_mb
  available_mb=$(get_available_disk_space)
  local required_mb=5120  # 5GB minimum
  
  if [ -n "${INSTALL_MODE}" ] && [ "${INSTALL_MODE}" = "lightweight" ]; then
    required_mb=2048  # 2GB for K3s
  fi
  
  if [ "${available_mb}" -lt "${required_mb}" ]; then
    log "ERROR" "Insufficient disk space. Required: ${required_mb}MB, Available: ${available_mb}MB"
    return 1
  fi
  
  log "SUCCESS" "Disk space check passed (${available_mb}MB available)"
  return 0
}

check_memory() {
  log "PROGRESS" "Checking available memory..."
  
  local mem_mb
  mem_mb=$(get_available_memory)
  local min_required="${MIN_MEMORY_MB:-1024}"
  
  if [ "${mem_mb}" -lt "${min_required}" ]; then
    log "ERROR" "Insufficient memory. Required: ${min_required}MB, Available: ${mem_mb}MB"
    return 1
  fi
  
  log "SUCCESS" "Memory check passed (${mem_mb}MB available)"
  return 0
}

check_required_commands() {
  log "PROGRESS" "Checking required commands..."
  
  local required_cmds=("curl" "awk" "grep" "sed")
  local missing_cmds=()
  
  for cmd in "${required_cmds[@]}"; do
    if ! command_exists "${cmd}"; then
      missing_cmds+=("${cmd}")
    fi
  done
  
  if [ ${#missing_cmds[@]} -gt 0 ]; then
    log "ERROR" "Missing required commands: ${missing_cmds[*]}"
    return 1
  fi
  
  log "SUCCESS" "All required commands available"
  return 0
}

check_swap() {
  log "PROGRESS" "Checking swap configuration..."
  
  if [ -n "${INSTALL_MODE}" ] && [ "${INSTALL_MODE}" = "full" ]; then
    if swapon -s 2>/dev/null | grep -q .; then
      log "WARNING" "Swap is enabled - kubeadm will use --ignore-preflight-errors=Swap"
    fi
  fi
  
  return 0
}

run_preflight_checks() {
  if [ -n "${SKIP_PREFLIGHT:-}" ]; then
    log "WARNING" "Skipping preflight checks"
    return 0
  fi
  
  log "INFO" "Running preflight checks..."
  echo ""
  
  local checks_passed=true
  
  check_required_commands || checks_passed=false
  check_network_connectivity || checks_passed=false
  check_disk_space || checks_passed=false
  check_memory || checks_passed=false
  check_swap
  
  echo ""
  
  if [ "${checks_passed}" = false ]; then
    log "ERROR" "Preflight checks failed"
    if [ -z "${AUTO_INSTALL:-}" ]; then
      read -p "Continue anyway? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
      fi
    else
      exit 1
    fi
  else
    log "SUCCESS" "All preflight checks passed"
  fi
  
  echo ""
}

# ============================================================================
# System Information
# ============================================================================

display_system_info() {
  local arch mem_mb cpu_cores os_type os_version disk_mb install_mode
  
  arch=$(detect_architecture)
  mem_mb=$(get_available_memory)
  cpu_cores=$(get_cpu_cores)
  os_type=$(detect_os)
  os_version=$(detect_os_version)
  disk_mb=$(get_available_disk_space)
  install_mode=$(determine_install_mode)
  
  log "INFO" "System Information:"
  echo -e "${CYAN}╔════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║     Kubernetes Installation System     ║${RESET}"
  echo -e "${CYAN}╠════════════════════════════════════════╣${RESET}"
  echo -e "${CYAN}║${RESET} Architecture:    ${BOLD}${arch}${RESET}"
  echo -e "${CYAN}║${RESET} OS:              ${BOLD}${os_type} ${os_version}${RESET}"
  echo -e "${CYAN}║${RESET} Memory:          ${BOLD}${mem_mb} MB${RESET}"
  echo -e "${CYAN}║${RESET} CPU Cores:       ${BOLD}${cpu_cores}${RESET}"
  echo -e "${CYAN}║${RESET} Disk Space:      ${BOLD}${disk_mb} MB${RESET}"
  echo -e "${CYAN}║${RESET} Install Mode:    ${BOLD}${install_mode}${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${RESET}"
  echo ""
  
  # Store system info
  export ARCH="${arch}"
  export OS_TYPE="${os_type}"
  export OS_VERSION="${os_version}"
  export MEM_MB="${mem_mb}"
  export CPU_CORES="${cpu_cores}"
  export DISK_MB="${disk_mb}"
  export INSTALL_MODE="${install_mode}"
}

# ============================================================================
# Package Manager Functions
# ============================================================================

detect_package_manager() {
  if command_exists yum; then
    echo "yum"
  elif command_exists dnf; then
    echo "dnf"
  elif command_exists apt-get; then
    echo "apt"
  elif command_exists apk; then
    echo "apk"
  elif command_exists pacman; then
    echo "pacman"
  elif command_exists zypper; then
    echo "zypper"
  else
    echo "unknown"
  fi
}

install_package() {
  local pkg="$1"
  local pkg_manager
  pkg_manager=$(detect_package_manager)
  
  log "PROGRESS" "Installing package: ${pkg}"
  
  case "${pkg_manager}" in
    yum|dnf)
      $SUDO_CMD ${pkg_manager} install -y "${pkg}"
      ;;
    apt)
      $SUDO_CMD apt-get install -y "${pkg}"
      ;;
    apk)
      $SUDO_CMD apk add "${pkg}"
      ;;
    pacman)
      $SUDO_CMD pacman -S --noconfirm "${pkg}"
      ;;
    zypper)
      $SUDO_CMD zypper install -y "${pkg}"
      ;;
    *)
      log "ERROR" "Unknown package manager"
      return 1
      ;;
  esac
}

# ============================================================================
# Installation State Management
# ============================================================================

save_install_state() {
  cat > "${INSTALL_STATE_FILE}" <<EOF
INSTALL_DATE=$(date -Iseconds)
INSTALL_MODE=${INSTALL_MODE}
ARCH=${ARCH}
OS_TYPE=${OS_TYPE}
OS_VERSION=${OS_VERSION}
ADVERTISE_ADDRESS=${ADVERTISE_ADDRESS}
POD_CIDR=${POD_CIDR}
KUBECONFIG_FILE=${KUBECONFIG_FILE}
LOG_FILE=${LOG_FILE}
EOF
  
  log "INFO" "Installation state saved to ${INSTALL_STATE_FILE}"
}

load_install_state() {
  if [ -f "${INSTALL_STATE_FILE}" ]; then
    . "${INSTALL_STATE_FILE}"
    return 0
  fi
  return 1
}

# ============================================================================
# Kubernetes Version Management
# ============================================================================

KUBERNETES_VERSION="${KUBERNETES_VERSION:-1.28}"

get_k8s_repo_config() {
  local os_type="$1"
  
  case "${os_type}" in
    centos|rhel|fedora|rocky|almalinux)
      cat <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
      ;;
    *)
      echo ""
      ;;
  esac
}

# ============================================================================
# K3s Installation (Lightweight Mode)
# ============================================================================

install_k3s() {
  log "INFO" "Installing K3s (Lightweight Kubernetes)"
  echo ""
  
  # K3s version
  local k3s_version_arg=""
  if [ -n "${K3S_VERSION:-}" ]; then
    k3s_version_arg="INSTALL_K3S_VERSION=${K3S_VERSION}"
  fi
  
  # K3s extra arguments
  local k3s_extra_args=""
  
  # Optimize for low resources
  if [ "${MEM_MB}" -lt 2048 ]; then
    k3s_extra_args="${k3s_extra_args} --disable=traefik --disable=servicelb"
    log "INFO" "Disabling heavy components (traefik, servicelb) due to limited memory"
  fi
  
  log "PROGRESS" "[1/3] Downloading K3s installer..."
  local k3s_installer
  k3s_installer=$(mktemp)
  cleanup_k3s_installer() { rm -f "${k3s_installer}"; }
  trap cleanup_k3s_installer EXIT
  
  if ! curl -fsSL https://get.k3s.io -o "${k3s_installer}"; then
    log "ERROR" "Failed to download K3s installer"
    exit 1
  fi
  
  if [ ! -s "${k3s_installer}" ]; then
    log "ERROR" "Downloaded K3s installer is empty"
    exit 1
  fi
  
  log "PROGRESS" "[2/3] Installing K3s..."
  ${k3s_version_arg} INSTALL_K3S_EXEC="server --bind-address=${ADVERTISE_ADDRESS} --cluster-cidr=${POD_CIDR} ${k3s_extra_args}" sh "${k3s_installer}"
  
  trap - EXIT
  cleanup_k3s_installer
  
  log "PROGRESS" "[3/3] Configuring kubectl access..."
  local resolved_kubeconfig
  resolved_kubeconfig=$(resolve_path "${KUBECONFIG_FILE}")
  
  if [ -z "${resolved_kubeconfig}" ]; then
    log "ERROR" "Unable to resolve KUBECONFIG_FILE path"
    exit 1
  fi
  
  $SUDO_CMD mkdir -p "$(dirname "${resolved_kubeconfig}")"
  
  if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    $SUDO_CMD cp /etc/rancher/k3s/k3s.yaml "${resolved_kubeconfig}"
    $SUDO_CMD chown "$(id -u):$(id -g)" "${resolved_kubeconfig}"
  fi
  
  export KUBECONFIG="${resolved_kubeconfig}"
  
  log "PROGRESS" "Waiting for K3s to be ready..."
  local retries=0
  local max_retries=30
  while [ ${retries} -lt ${max_retries} ]; do
    if kubectl get nodes >/dev/null 2>&1; then
      log "SUCCESS" "K3s is ready!"
      break
    fi
    sleep 2
    retries=$((retries + 1))
  done
  
  if [ ${retries} -eq ${max_retries} ]; then
    log "WARNING" "K3s did not become ready within expected time"
  fi
  
  log "SUCCESS" "K3s installation complete"
  echo ""
  log "INFO" "Kubeconfig: ${resolved_kubeconfig}"
  log "INFO" "Optimizations applied:"
  log "INFO" "  - Lightweight K3s distribution"
  log "INFO" "  - Minimal resource footprint"
  if [ "${MEM_MB}" -lt 2048 ]; then
    log "INFO" "  - Disabled heavy components (traefik, servicelb)"
  fi
  log "INFO" "  - ${ARCH} architecture support"
}

# ============================================================================
# Full Kubernetes Installation (kubeadm)
# ============================================================================

install_full_kubernetes() {
  log "INFO" "Installing Full Kubernetes (kubeadm)"
  echo ""
  
  case "${OS_TYPE}" in
    centos|rhel|fedora|rocky|almalinux)
      install_full_kubernetes_rpm
      ;;
    ubuntu|debian)
      install_full_kubernetes_deb
      ;;
    arch)
      install_full_kubernetes_arch
      ;;
    opensuse*|sles)
      install_full_kubernetes_zypper
      ;;
    *)
      log "ERROR" "Unsupported OS for full Kubernetes: ${OS_TYPE}"
      exit 1
      ;;
  esac
}

install_full_kubernetes_rpm() {
  log "PROGRESS" "[1/6] Configuring Kubernetes yum repository..."
  get_k8s_repo_config "${OS_TYPE}" | $SUDO_CMD tee /etc/yum.repos.d/kubernetes.repo >/dev/null
  
  log "PROGRESS" "[2/6] Disabling SELinux (if present)..."
  $SUDO_CMD setenforce 0 2>/dev/null || true
  $SUDO_CMD sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config 2>/dev/null || true
  
  log "PROGRESS" "[3/6] Installing Kubernetes packages..."
  local pkg_manager
  pkg_manager=$(detect_package_manager)
  $SUDO_CMD ${pkg_manager} install -y --disableexcludes=kubernetes kubelet kubeadm kubectl
  $SUDO_CMD systemctl enable --now kubelet
  
  install_full_kubernetes_common
}

install_full_kubernetes_deb() {
  log "PROGRESS" "[1/6] Installing dependencies..."
  $SUDO_CMD apt-get update
  $SUDO_CMD apt-get install -y apt-transport-https ca-certificates curl gnupg
  
  log "PROGRESS" "[2/6] Adding Kubernetes repository..."
  local gpg_key_tmp
  gpg_key_tmp=$(mktemp)
  cleanup_gpg_key() { rm -f "${gpg_key_tmp}"; }
  trap cleanup_gpg_key EXIT
  
  curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/Release.key" -o "${gpg_key_tmp}"
  
  if [ ! -s "${gpg_key_tmp}" ]; then
    log "ERROR" "Failed to download Kubernetes GPG key"
    exit 1
  fi
  
  $SUDO_CMD mkdir -p /etc/apt/keyrings
  $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg < "${gpg_key_tmp}"
  
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /" | $SUDO_CMD tee /etc/apt/sources.list.d/kubernetes.list
  
  trap - EXIT
  cleanup_gpg_key
  
  log "PROGRESS" "[3/6] Installing Kubernetes packages..."
  $SUDO_CMD apt-get update
  $SUDO_CMD apt-get install -y kubelet kubeadm kubectl
  $SUDO_CMD apt-mark hold kubelet kubeadm kubectl
  $SUDO_CMD systemctl enable --now kubelet
  
  install_full_kubernetes_common
}

install_full_kubernetes_arch() {
  log "PROGRESS" "[1/6] Installing Kubernetes from AUR..."
  log "WARNING" "Arch Linux requires manual AUR installation"
  log "INFO" "Please install kubeadm, kubelet, kubectl from AUR manually"
  
  install_full_kubernetes_common
}

install_full_kubernetes_zypper() {
  log "PROGRESS" "[1/6] Adding Kubernetes repository..."
  $SUDO_CMD zypper addrepo -f "https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/rpm/" kubernetes
  
  log "PROGRESS" "[2/6] Importing GPG key..."
  $SUDO_CMD rpm --import "https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/rpm/repodata/repomd.xml.key"
  
  log "PROGRESS" "[3/6] Installing Kubernetes packages..."
  $SUDO_CMD zypper install -y kubelet kubeadm kubectl
  $SUDO_CMD systemctl enable --now kubelet
  
  install_full_kubernetes_common
}

install_full_kubernetes_common() {
  log "PROGRESS" "[4/6] Setting up container runtime (containerd)..."
  
  if ! command_exists containerd; then
    install_package containerd
  fi
  
  $SUDO_CMD mkdir -p /etc/containerd
  if [ ! -f /etc/containerd/config.toml ]; then
    $SUDO_CMD containerd config default | $SUDO_CMD tee /etc/containerd/config.toml >/dev/null
  fi
  
  # Disable CRI plugin if present
  if $SUDO_CMD grep -Eq '^[[:space:]]*disabled_plugins[[:space:]]*=[[:space:]]*\[[[:space:]]*["'\'']cri["'\''][[:space:]]*\]' /etc/containerd/config.toml; then
    $SUDO_CMD sed -i -E 's/^[[:space:]]*disabled_plugins[[:space:]]*=[[:space:]]*\[[[:space:]]*["'\'']cri["'\''][[:space:]]*\]/# disabled_plugins = ["cri"]/g' /etc/containerd/config.toml
  fi
  
  $SUDO_CMD systemctl enable --now containerd
  $SUDO_CMD systemctl restart containerd
  
  # Configure hugepages if requested
  if [ -n "${HUGEPAGES_2MI:-}" ]; then
    configure_hugepages
  else
    log "PROGRESS" "[5/6] Skipping hugepage configuration"
  fi
  
  log "PROGRESS" "[6/6] Initializing Kubernetes control plane..."
  $SUDO_CMD kubeadm init \
    --ignore-preflight-errors=Swap \
    --apiserver-advertise-address="${ADVERTISE_ADDRESS}" \
    --pod-network-cidr="${POD_CIDR}"
  
  # Configure kubectl
  local resolved_home resolved_kubeconfig
  resolved_home=$(resolve_path "${HOME}")
  resolved_kubeconfig=$(resolve_path "${KUBECONFIG_FILE}")
  
  if [ -z "${resolved_kubeconfig}" ]; then
    log "ERROR" "Unable to resolve KUBECONFIG_FILE path"
    exit 1
  fi
  
  if [[ "${resolved_kubeconfig}" != "${resolved_home}" && "${resolved_kubeconfig}" != "${resolved_home}"/* ]]; then
    log "ERROR" "Refusing to write kubeconfig outside of ${resolved_home}"
    exit 1
  fi
  
  $SUDO_CMD mkdir -p "$(dirname "${resolved_kubeconfig}")"
  $SUDO_CMD cp /etc/kubernetes/admin.conf "${resolved_kubeconfig}"
  $SUDO_CMD chown "$(id -u):$(id -g)" "${resolved_kubeconfig}"
  
  export KUBECONFIG="${resolved_kubeconfig}"
  
  # Deploy CNI (Flannel)
  deploy_flannel
  
  # Restart kubelet if hugepages were configured
  if [ -n "${HUGEPAGES_2MI:-}" ]; then
    log "PROGRESS" "Restarting kubelet to apply hugepages..."
    $SUDO_CMD systemctl restart kubelet
  fi
  
  log "SUCCESS" "Full Kubernetes installation complete"
}

configure_hugepages() {
  if ! [[ "${HUGEPAGES_2MI}" =~ ^[0-9]+$ ]]; then
    log "ERROR" "HUGEPAGES_2MI must be a numeric value"
    exit 1
  fi
  
  local requested_kb=$((HUGEPAGES_2MI * 2048))
  local mem_available_kb mem_total_kb memory_limit_kb memory_label
  
  mem_available_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || true)
  mem_total_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || true)
  
  if [ -n "${mem_available_kb}" ]; then
    memory_limit_kb="${mem_available_kb}"
    memory_label="available"
  elif [ -n "${mem_total_kb}" ]; then
    memory_limit_kb="${mem_total_kb}"
    memory_label="total"
  fi
  
  if [ -n "${memory_limit_kb}" ] && [ "${requested_kb}" -ge "${memory_limit_kb}" ]; then
    log "ERROR" "HUGEPAGES_2MI requests ${requested_kb} KiB which exceeds ${memory_label} memory (${memory_limit_kb} KiB)"
    exit 1
  fi
  
  log "PROGRESS" "[5/6] Configuring hugepages (${HUGEPAGES_2MI} x 2Mi)..."
  printf '%s\n' "${HUGEPAGES_2MI}" | $SUDO_CMD tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages >/dev/null
}

deploy_flannel() {
  log "PROGRESS" "Deploying Flannel CNI..."
  
  if ! command_exists kubectl; then
    log "ERROR" "kubectl not found"
    exit 1
  fi
  
  local flannel_commit="${FLANNEL_COMMIT:-629cd70d816e56853aac967f92ed3dade7275baf}"
  local flannel_url="${FLANNEL_MANIFEST_URL:-https://raw.githubusercontent.com/flannel-io/flannel/${flannel_commit}/Documentation/kube-flannel.yml}"
  local flannel_sha256="${FLANNEL_MANIFEST_SHA256:-6583e9607befbf3c46cd04eb6fd960c2a446453b83699d95904bace95f49c410}"
  
  local manifest_tmp
  manifest_tmp=$(mktemp)
  cleanup_manifest() { rm -f "${manifest_tmp}"; }
  trap cleanup_manifest EXIT
  
  curl -fsSL --fail "${flannel_url}" -o "${manifest_tmp}"
  
  if [ -n "${flannel_sha256}" ]; then
    local downloaded_sha
    downloaded_sha=$(sha256sum "${manifest_tmp}" | awk '{print $1}')
    if [ "${downloaded_sha}" != "${flannel_sha256}" ]; then
      log "ERROR" "Flannel manifest checksum mismatch (got ${downloaded_sha})"
      exit 1
    fi
  fi
  
  kubectl --kubeconfig="${KUBECONFIG_FILE}" apply -f "${manifest_tmp}"
  
  trap - EXIT
  cleanup_manifest
  
  log "SUCCESS" "Flannel CNI deployed"
}

# ============================================================================
# Post-Installation Verification
# ============================================================================

verify_installation() {
  log "INFO" "Verifying installation..."
  echo ""
  
  if [ ! -f "${KUBECONFIG_FILE}" ]; then
    log "ERROR" "Kubeconfig file not found: ${KUBECONFIG_FILE}"
    return 1
  fi
  
  export KUBECONFIG="${KUBECONFIG_FILE}"
  
  log "PROGRESS" "Checking cluster nodes..."
  if kubectl get nodes >/dev/null 2>&1; then
    kubectl get nodes
    log "SUCCESS" "Nodes are accessible"
  else
    log "ERROR" "Cannot access cluster nodes"
    return 1
  fi
  
  echo ""
  
  log "PROGRESS" "Checking system pods..."
  if kubectl get pods --all-namespaces >/dev/null 2>&1; then
    kubectl get pods --all-namespaces
    log "SUCCESS" "System pods are accessible"
  else
    log "WARNING" "Cannot list system pods"
  fi
  
  echo ""
  
  log "SUCCESS" "Installation verification complete"
  return 0
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
  # Initialize logging
  mkdir -p "$(dirname "${LOG_FILE}")"
  touch "${LOG_FILE}"
  
  log "INFO" "Kubernetes Installation System v2.0"
  log "INFO" "Log file: ${LOG_FILE}"
  echo ""
  
  # Display system information
  display_system_info
  
  # Validate architecture
  if [ "${ARCH}" = "unsupported" ]; then
    log "ERROR" "Unsupported architecture: $(uname -m)"
    exit 1
  fi
  
  # Run preflight checks
  run_preflight_checks
  
  # Set configuration based on install mode
  ADVERTISE_ADDRESS=${ADVERTISE_ADDRESS:-$(get_primary_ip)}
  
  if [ "${INSTALL_MODE}" = "lightweight" ]; then
    POD_CIDR=${POD_CIDR:-10.42.0.0/16}
    MIN_MEMORY_MB=${MIN_MEMORY_MB:-1024}
    HUGEPAGES_2MI=""  # Disable on lightweight
  else
    POD_CIDR=${POD_CIDR:-10.244.0.0/16}
    MIN_MEMORY_MB=${MIN_MEMORY_MB:-2048}
    HUGEPAGES_2MI=${HUGEPAGES_2MI:-}
  fi
  
  KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}
  
  if [ -z "${ADVERTISE_ADDRESS}" ]; then
    log "ERROR" "Unable to determine ADVERTISE_ADDRESS automatically"
    exit 1
  fi
  
  log "INFO" "Configuration:"
  log "INFO" "  Install Mode:     ${INSTALL_MODE}"
  log "INFO" "  Advertise Address: ${ADVERTISE_ADDRESS}"
  log "INFO" "  Pod CIDR:         ${POD_CIDR}"
  log "INFO" "  Kubeconfig:       ${KUBECONFIG_FILE}"
  echo ""
  
  # Confirm installation
  if [ -z "${AUTO_INSTALL:-}" ]; then
    read -p "Proceed with installation? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log "INFO" "Installation cancelled"
      exit 0
    fi
    echo ""
  fi
  
  # Perform installation
  if [ "${INSTALL_MODE}" = "lightweight" ]; then
    install_k3s
  else
    install_full_kubernetes
  fi
  
  # Save installation state
  save_install_state
  
  echo ""
  
  # Verify installation
  verify_installation
  
  echo ""
  log "SUCCESS" "═══════════════════════════════════════════════════════"
  log "SUCCESS" " Kubernetes installation completed successfully!"
  log "SUCCESS" "═══════════════════════════════════════════════════════"
  echo ""
  log "INFO" "Next steps:"
  log "INFO" "  1. Run analysis: ./analyze_k8s.sh"
  log "INFO" "  2. Deploy your applications"
  log "INFO" "  3. Check cluster status: kubectl get nodes"
  echo ""
  log "INFO" "Installation details:"
  log "INFO" "  Log file: ${LOG_FILE}"
  log "INFO" "  State file: ${INSTALL_STATE_FILE}"
  log "INFO" "  Kubeconfig: ${KUBECONFIG_FILE}"
}

# Execute main function
main "$@"
