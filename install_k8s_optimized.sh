#!/usr/bin/env bash
set -euo pipefail

# Automated Kubernetes/K3s install script with mobile device support
# Supports: CentOS/RHEL, Ubuntu/Debian, and resource-constrained devices (Realme C63, etc.)
#
# Options:
#   INSTALL_MODE:       "full" (kubeadm) or "lightweight" (k3s) - auto-detected based on resources
#   ADVERTISE_ADDRESS:  API server advertise address (defaults to first host IP)
#   POD_CIDR:           Pod network CIDR (default: 10.244.0.0/16 for flannel, 10.42.0.0/16 for k3s)
#   HUGEPAGES_2MI:      Number of 2Mi hugepages to configure (optional, disabled on mobile)
#   KUBECONFIG_FILE:    Path to write kubeconfig for kubectl (default: $HOME/.kube/config)
#   FLANNEL_MANIFEST_URL: URL for the flannel manifest (default pinned commit)
#   MIN_MEMORY_MB:      Minimum memory required in MB (default: 1024 for k3s, 2048 for full)

SUDO_CMD="sudo"
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  SUDO_CMD=""
fi

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

# Detect system architecture
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
    armv7l|armv6l)
      echo "arm"
      ;;
    *)
      echo "unsupported"
      ;;
  esac
}

# Detect OS and distribution
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

# Get available memory in MB
get_available_memory() {
  local mem_kb
  mem_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
  echo $((mem_kb / 1024))
}

# Get CPU cores
get_cpu_cores() {
  nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "1"
}

# Detect if running on mobile/resource-constrained device
is_mobile_device() {
  local mem_mb
  mem_mb=$(get_available_memory)
  local cpu_cores
  cpu_cores=$(get_cpu_cores)
  
  # Check for Termux environment or low resources
  if [ -n "${TERMUX_VERSION:-}" ] || [ -n "${PREFIX:-}" ]; then
    return 0
  fi
  
  # Check for mobile device characteristics (< 4GB RAM, <= 4 cores, ARM architecture)
  local arch
  arch=$(detect_architecture)
  if [ "${mem_mb}" -lt 4096 ] && [ "${cpu_cores}" -le 4 ] && [ "${arch}" != "amd64" ]; then
    return 0
  fi
  
  return 1
}

# Determine optimal installation mode
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

# System information
ARCH=$(detect_architecture)
OS_TYPE=$(detect_os)
MEM_MB=$(get_available_memory)
CPU_CORES=$(get_cpu_cores)
INSTALL_MODE=$(determine_install_mode)

echo "=== System Detection ==="
echo "Architecture: ${ARCH}"
echo "OS Type: ${OS_TYPE}"
echo "Memory: ${MEM_MB} MB"
echo "CPU Cores: ${CPU_CORES}"
echo "Install Mode: ${INSTALL_MODE}"
echo ""

if [ "${ARCH}" = "unsupported" ]; then
  echo "ERROR: Unsupported architecture: $(uname -m)" >&2
  exit 1
fi

# Configuration
ADVERTISE_ADDRESS=${ADVERTISE_ADDRESS:-$(get_primary_ip)}
KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}

if [ "${INSTALL_MODE}" = "lightweight" ]; then
  POD_CIDR=${POD_CIDR:-10.42.0.0/16}
  MIN_MEMORY_MB=${MIN_MEMORY_MB:-1024}
  HUGEPAGES_2MI=""  # Disable hugepages on lightweight mode
else
  POD_CIDR=${POD_CIDR:-10.244.0.0/16}
  MIN_MEMORY_MB=${MIN_MEMORY_MB:-2048}
  HUGEPAGES_2MI=${HUGEPAGES_2MI:-}
fi

FLANNEL_COMMIT=${FLANNEL_COMMIT:-629cd70d816e56853aac967f92ed3dade7275baf}
FLANNEL_MANIFEST_URL=${FLANNEL_MANIFEST_URL:-"https://raw.githubusercontent.com/flannel-io/flannel/${FLANNEL_COMMIT}/Documentation/kube-flannel.yml"}
FLANNEL_MANIFEST_SHA256=${FLANNEL_MANIFEST_SHA256:-6583e9607befbf3c46cd04eb6fd960c2a446453b83699d95904bace95f49c410}

if [ -z "${ADVERTISE_ADDRESS}" ]; then
  echo "Unable to determine ADVERTISE_ADDRESS automatically. Set ADVERTISE_ADDRESS explicitly." >&2
  exit 1
fi

# Check minimum memory
if [ "${MEM_MB}" -lt "${MIN_MEMORY_MB}" ]; then
  echo "WARNING: Available memory (${MEM_MB} MB) is below recommended minimum (${MIN_MEMORY_MB} MB)" >&2
  echo "Installation may fail or result in poor performance." >&2
  read -p "Do you want to continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Install based on mode
if [ "${INSTALL_MODE}" = "lightweight" ]; then
  echo "=== Installing K3s (Lightweight Kubernetes) ==="
  echo "Optimized for resource-constrained devices like Realme C63"
  echo ""
  
  # K3s installation
  echo "[1/3] Installing K3s"
  
  # Prepare K3s install command
  K3S_EXTRA_ARGS=""
  
  # Optimize for low resources
  if [ "${MEM_MB}" -lt 2048 ]; then
    K3S_EXTRA_ARGS="${K3S_EXTRA_ARGS} --disable=traefik --disable=servicelb"
  fi
  
  # Install K3s
  if ! command_exists k3s; then
    echo "Downloading K3s installer..."
    k3s_installer=$(mktemp)
    cleanup_k3s_installer() { rm -f "${k3s_installer}"; }
    trap cleanup_k3s_installer EXIT
    
    curl -sfL https://get.k3s.io -o "${k3s_installer}"
    
    # Verify installer was downloaded successfully
    if [ ! -s "${k3s_installer}" ]; then
      echo "Failed to download K3s installer" >&2
      exit 1
    fi
    
    # Execute installer
    INSTALL_K3S_EXEC="server --bind-address=${ADVERTISE_ADDRESS} --cluster-cidr=${POD_CIDR} ${K3S_EXTRA_ARGS}" sh "${k3s_installer}"
    
    trap - EXIT
    cleanup_k3s_installer
  else
    echo "K3s already installed, skipping..."
  fi
  
  echo "[2/3] Configure kubectl access"
  resolved_kubeconfig=$(resolve_path "${KUBECONFIG_FILE}")
  
  if [ -z "${resolved_kubeconfig}" ]; then
    echo "Unable to resolve KUBECONFIG_FILE path." >&2
    exit 1
  fi
  
  $SUDO_CMD mkdir -p "$(dirname "${resolved_kubeconfig}")"
  
  if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    $SUDO_CMD cp /etc/rancher/k3s/k3s.yaml "${resolved_kubeconfig}"
    $SUDO_CMD chown "$(id -u):$(id -g)" "${resolved_kubeconfig}"
  fi
  
  echo "[3/3] Verify installation"
  export KUBECONFIG="${resolved_kubeconfig}"
  
  # Wait for K3s to be ready
  echo "Waiting for K3s to be ready..."
  for _ in {1..30}; do
    if kubectl get nodes >/dev/null 2>&1; then
      echo "K3s is ready!"
      break
    fi
    sleep 2
  done
  
  kubectl get nodes
  
  echo ""
  echo "=== K3s Installation Complete ==="
  echo "Lightweight Kubernetes cluster is ready for Realme C63 and similar devices"
  echo "Kubeconfig: ${resolved_kubeconfig}"
  echo ""
  echo "Optimizations applied:"
  echo "  - Lightweight K3s distribution"
  echo "  - Minimal resource footprint"
  echo "  - Disabled heavy components (traefik, servicelb) on low memory"
  echo "  - ARM/ARM64 architecture support"
  
else
  # Full Kubernetes installation (existing logic)
  echo "=== Installing Full Kubernetes (kubeadm) ==="
  echo ""
  
  echo "[1/6] Configure Kubernetes yum repository"
  if [ "${OS_TYPE}" = "centos" ] || [ "${OS_TYPE}" = "rhel" ] || [ "${OS_TYPE}" = "fedora" ]; then
    $SUDO_CMD tee /etc/yum.repos.d/kubernetes.repo >/dev/null <<'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF
    
    echo "[2/6] Set SELinux to permissive mode"
    $SUDO_CMD setenforce 0 2>/dev/null || true
    $SUDO_CMD sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config 2>/dev/null || true
    
    echo "[3/6] Install kubelet, kubeadm, kubectl"
    $SUDO_CMD yum install -y kubelet kubeadm kubectl
    $SUDO_CMD systemctl enable --now kubelet
    
  elif [ "${OS_TYPE}" = "ubuntu" ] || [ "${OS_TYPE}" = "debian" ]; then
    echo "[2/6] Install dependencies"
    $SUDO_CMD apt-get update
    $SUDO_CMD apt-get install -y apt-transport-https ca-certificates curl gnupg
    
    echo "[3/6] Add Kubernetes repository"
    # Download GPG key to temporary file first
    gpg_key_tmp=$(mktemp)
    cleanup_gpg_key() { rm -f "${gpg_key_tmp}"; }
    trap cleanup_gpg_key EXIT
    
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key -o "${gpg_key_tmp}"
    
    # Verify key was downloaded
    if [ ! -s "${gpg_key_tmp}" ]; then
      echo "Failed to download Kubernetes GPG key" >&2
      exit 1
    fi
    
    # Create keyrings directory if it doesn't exist
    $SUDO_CMD mkdir -p /etc/apt/keyrings
    
    # Add the GPG key
    $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg < "${gpg_key_tmp}"
    
    # Add repository
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | $SUDO_CMD tee /etc/apt/sources.list.d/kubernetes.list
    
    trap - EXIT
    cleanup_gpg_key
    
    $SUDO_CMD apt-get update
    $SUDO_CMD apt-get install -y kubelet kubeadm kubectl
    $SUDO_CMD apt-mark hold kubelet kubeadm kubectl
    $SUDO_CMD systemctl enable --now kubelet
    
  else
    echo "Unsupported OS: ${OS_TYPE}. Please install kubelet, kubeadm, kubectl manually." >&2
    exit 1
  fi
  
  echo "[4/6] Ensure containerd has CRI enabled"
  if ! command_exists containerd; then
    if [ "${OS_TYPE}" = "ubuntu" ] || [ "${OS_TYPE}" = "debian" ]; then
      $SUDO_CMD apt-get install -y containerd
    else
      $SUDO_CMD yum install -y containerd
    fi
  fi
  
  $SUDO_CMD mkdir -p /etc/containerd
  if [ ! -f /etc/containerd/config.toml ]; then
    $SUDO_CMD containerd config default | $SUDO_CMD tee /etc/containerd/config.toml >/dev/null
  fi
  
  if $SUDO_CMD grep -Eq '^[[:space:]]*disabled_plugins[[:space:]]*=[[:space:]]*\[[[:space:]]*["'\'']cri["'\''][[:space:]]*\]' /etc/containerd/config.toml; then
    $SUDO_CMD sed -i -E 's/^[[:space:]]*disabled_plugins[[:space:]]*=[[:space:]]*\[[[:space:]]*["'\'']cri["'\''][[:space:]]*\]/# disabled_plugins = ["cri"]/g' /etc/containerd/config.toml
  fi
  
  $SUDO_CMD systemctl enable --now containerd
  $SUDO_CMD systemctl restart containerd
  
  if [ -n "${HUGEPAGES_2MI}" ]; then
    if ! [[ "${HUGEPAGES_2MI}" =~ ^[0-9]+$ ]]; then
      echo "HUGEPAGES_2MI must be a numeric value." >&2
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
      echo "HUGEPAGES_2MI requests ${requested_kb} KiB which exceeds ${memory_label} memory (${memory_limit_kb} KiB)." >&2
      exit 1
    fi
    echo "[5/6] Configure hugepages (${HUGEPAGES_2MI} x 2Mi)"
    printf '%s\n' "${HUGEPAGES_2MI}" | $SUDO_CMD tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages >/dev/null
  else
    echo "[5/6] Skip hugepage configuration (HUGEPAGES_2MI not set)"
  fi
  
  echo "[6/6] Initialize control plane with kubeadm"
  $SUDO_CMD kubeadm init \
    --ignore-preflight-errors Swap \
    --apiserver-advertise-address="${ADVERTISE_ADDRESS}" \
    --pod-network-cidr="${POD_CIDR}"
  
  echo "[post] Configure kubectl access"
  resolved_home=$(resolve_path "${HOME}")
  resolved_kubeconfig=$(resolve_path "${KUBECONFIG_FILE}")
  
  if [ -z "${resolved_kubeconfig}" ]; then
    echo "Unable to resolve KUBECONFIG_FILE path." >&2
    exit 1
  fi
  
  if [[ "${resolved_kubeconfig}" != "${resolved_home}" && "${resolved_kubeconfig}" != "${resolved_home}"/* ]]; then
    echo "Refusing to write kubeconfig outside of ${resolved_home}. Set KUBECONFIG_FILE under your home directory." >&2
    exit 1
  fi
  
  KUBECONFIG_FILE="${resolved_kubeconfig}"
  $SUDO_CMD mkdir -p "$(dirname "${KUBECONFIG_FILE}")"
  $SUDO_CMD cp /etc/kubernetes/admin.conf "${KUBECONFIG_FILE}"
  $SUDO_CMD chown "$(id -u):$(id -g)" "${KUBECONFIG_FILE}"
  
  echo "[post] Deploy flannel CNI (${POD_CIDR})"
  if ! command_exists curl; then
    echo "curl is required to download the flannel manifest." >&2
    exit 1
  fi
  manifest_tmp=$(mktemp)
  cleanup_manifest() { rm -f "${manifest_tmp}"; }
  trap cleanup_manifest EXIT
  curl -fsSL --fail "${FLANNEL_MANIFEST_URL}" -o "${manifest_tmp}"
  if [ -n "${FLANNEL_MANIFEST_SHA256}" ]; then
    downloaded_sha=$(sha256sum "${manifest_tmp}" | awk '{print $1}')
    if [ "${downloaded_sha}" != "${FLANNEL_MANIFEST_SHA256}" ]; then
      echo "Flannel manifest checksum mismatch (got ${downloaded_sha})." >&2
      exit 1
    fi
  fi
  kubectl --kubeconfig="${KUBECONFIG_FILE}" apply -f "${manifest_tmp}"
  trap - EXIT
  cleanup_manifest
  
  if [ -n "${HUGEPAGES_2MI}" ]; then
    echo "[post] Restart kubelet to pick up hugepages"
    $SUDO_CMD systemctl restart kubelet
  fi
  
  echo "Cluster initialization complete."
fi
