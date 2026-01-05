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
#   INSTALL_TRIVY:      Install Trivy security scanner (default: false, set to 'true' to enable)

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

ADVERTISE_ADDRESS=${ADVERTISE_ADDRESS:-$(get_primary_ip)}
POD_CIDR=${POD_CIDR:-10.244.0.0/16}
HUGEPAGES_2MI=${HUGEPAGES_2MI:-}
KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}
FLANNEL_COMMIT=${FLANNEL_COMMIT:-629cd70d816e56853aac967f92ed3dade7275baf}
FLANNEL_MANIFEST_URL=${FLANNEL_MANIFEST_URL:-"https://raw.githubusercontent.com/flannel-io/flannel/${FLANNEL_COMMIT}/Documentation/kube-flannel.yml"}
FLANNEL_MANIFEST_SHA256=${FLANNEL_MANIFEST_SHA256:-6583e9607befbf3c46cd04eb6fd960c2a446453b83699d95904bace95f49c410}
INSTALL_TRIVY=${INSTALL_TRIVY:-false}

if [ -z "${ADVERTISE_ADDRESS}" ]; then
  echo "Unable to determine ADVERTISE_ADDRESS automatically. Set ADVERTISE_ADDRESS explicitly." >&2
  exit 1
fi

echo "[1/6] Configure Kubernetes yum repository"
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
$SUDO_CMD sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config || true

echo "[3/6] Install kubelet, kubeadm, kubectl"
$SUDO_CMD yum install -y kubelet kubeadm kubectl
$SUDO_CMD systemctl enable --now kubelet

echo "[4/6] Ensure containerd has CRI enabled"
if ! command_exists containerd; then
  $SUDO_CMD yum install -y containerd
fi
$SUDO_CMD mkdir -p /etc/containerd
if [ ! -f /etc/containerd/config.toml ]; then
  $SUDO_CMD containerd config default | $SUDO_CMD tee /etc/containerd/config.toml >/dev/null
fi
if $SUDO_CMD grep -Eq '^[[:space:]]*disabled_plugins[[:space:]]*=[[:space:]]*\[[[:space:]]*["'\"'\"']cri["'\"'\"'][[:space:]]*\]' /etc/containerd/config.toml; then
  $SUDO_CMD sed -i -E 's/^[[:space:]]*disabled_plugins[[:space:]]*=[[:space:]]*\[[[:space:]]*["'\"'\"']cri["'\"'\"'][[:space:]]*\]/# disabled_plugins = ["cri"]/g' /etc/containerd/config.toml
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
curl -L --fail "${FLANNEL_MANIFEST_URL}" -o "${manifest_tmp}"
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

if [ "${INSTALL_TRIVY}" = "true" ]; then
  echo "[post] Install Trivy security scanner"
  if ! command_exists wget && ! command_exists curl; then
    echo "wget or curl is required to download Trivy." >&2
    exit 1
  fi
  
  TRIVY_VERSION=${TRIVY_VERSION:-0.58.1}
  TRIVY_ARCH=$(uname -m)
  case "${TRIVY_ARCH}" in
    x86_64) TRIVY_ARCH="64bit" ;;
    aarch64) TRIVY_ARCH="ARM64" ;;
    *) echo "Unsupported architecture: ${TRIVY_ARCH}" >&2; exit 1 ;;
  esac
  
  TRIVY_URL="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${TRIVY_ARCH}.tar.gz"
  trivy_tmp=$(mktemp -d)
  cleanup_trivy() { rm -rf "${trivy_tmp}"; }
  trap cleanup_trivy EXIT
  
  if command_exists curl; then
    curl -L --fail "${TRIVY_URL}" -o "${trivy_tmp}/trivy.tar.gz"
  else
    wget -O "${trivy_tmp}/trivy.tar.gz" "${TRIVY_URL}"
  fi
  
  tar -xzf "${trivy_tmp}/trivy.tar.gz" -C "${trivy_tmp}"
  $SUDO_CMD mv "${trivy_tmp}/trivy" /usr/local/bin/trivy
  $SUDO_CMD chmod +x /usr/local/bin/trivy
  trap - EXIT
  cleanup_trivy
  
  echo "[post] Trivy installed successfully. Run 'trivy --version' to verify."
fi

echo "Cluster initialization complete."
