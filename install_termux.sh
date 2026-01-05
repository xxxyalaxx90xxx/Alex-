#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Automated Kubernetes setup script for Termux (Android)
# This script installs and configures k3s (lightweight Kubernetes) on Termux
# Note: Full kubeadm is not supported on Termux/Android architecture

# Options:
#   POD_CIDR:           Pod network CIDR (default: 10.42.0.0/16 for k3s)
#   KUBECONFIG_FILE:    Path to write kubeconfig for kubectl (default: $HOME/.kube/config)
#   K3S_VERSION:        Version of k3s to install (default: latest stable)

echo "============================================"
echo "Termux Kubernetes (k3s) Installation Script"
echo "============================================"
echo ""
echo "Note: This installs k3s (lightweight Kubernetes) as full kubeadm"
echo "      is not supported on Android/Termux architecture."
echo ""

# Check if running in Termux
if [ ! -d "/data/data/com.termux" ]; then
  echo "Error: This script is designed for Termux environment only." >&2
  echo "For standard Linux distributions, use install_k8s.sh instead." >&2
  exit 1
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Configuration
POD_CIDR=${POD_CIDR:-10.42.0.0/16}
KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}
K3S_VERSION=${K3S_VERSION:-}

echo "[1/7] Update Termux packages"
pkg update -y
pkg upgrade -y

echo "[2/7] Install required packages"
pkg install -y root-repo
pkg install -y wget curl proot-distro

echo "[3/7] Install proot-distro Ubuntu"
if ! proot-distro list | grep -q "ubuntu (installed)"; then
  echo "Installing Ubuntu distribution..."
  proot-distro install ubuntu
else
  echo "Ubuntu distribution already installed"
fi

echo "[4/7] Create k3s installation script for proot environment"
cat > /tmp/k3s_install_inner.sh <<'INNER_SCRIPT'
#!/bin/bash
set -euo pipefail

# Install dependencies in Ubuntu proot
apt-get update
apt-get install -y curl wget iptables

# Download and install k3s
K3S_VERSION="${K3S_VERSION:-}"
if [ -n "${K3S_VERSION}" ]; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${K3S_VERSION}" sh -
else
  curl -sfL https://get.k3s.io | sh -
fi

# Wait for k3s to start
sleep 10

# Check k3s status
systemctl status k3s || service k3s status || echo "k3s service check skipped"

echo "k3s installation complete in proot environment"
INNER_SCRIPT

echo "[5/7] Install k3s in proot Ubuntu environment"
echo "Note: This may take several minutes..."
# Copy script to proot environment
proot-distro login ubuntu -- mkdir -p /tmp 2>/dev/null || true
cat /tmp/k3s_install_inner.sh | proot-distro login ubuntu -- tee /tmp/k3s_install_inner.sh >/dev/null
proot-distro login ubuntu -- chmod +x /tmp/k3s_install_inner.sh
if ! proot-distro login ubuntu -- /tmp/k3s_install_inner.sh; then
  echo "Warning: k3s installation in proot encountered issues." >&2
  echo "You may need to manually complete the setup." >&2
fi
rm -f /tmp/k3s_install_inner.sh

echo "[6/7] Install kubectl in Termux"
if ! command_exists kubectl; then
  echo "Downloading kubectl..."
  KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  
  # Detect architecture
  ARCH=$(uname -m)
  case "${ARCH}" in
    aarch64|arm64)
      KUBECTL_ARCH="arm64"
      ;;
    armv7l|armv8l|arm)
      KUBECTL_ARCH="arm"
      ;;
    *)
      echo "Warning: Unsupported architecture ${ARCH}, trying arm64" >&2
      KUBECTL_ARCH="arm64"
      ;;
  esac
  
  if curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"; then
    chmod +x kubectl
    mkdir -p $PREFIX/bin
    mv kubectl $PREFIX/bin/
    echo "kubectl installed to $PREFIX/bin/kubectl"
  else
    echo "Error: Failed to download kubectl for architecture ${KUBECTL_ARCH}" >&2
    exit 1
  fi
else
  echo "kubectl already installed"
fi

echo "[7/7] Setup kubeconfig"
mkdir -p "$(dirname "${KUBECONFIG_FILE}")"

# Try to copy kubeconfig from proot environment
if proot-distro login ubuntu -- test -f /etc/rancher/k3s/k3s.yaml 2>/dev/null; then
  # Copy kubeconfig to Termux environment
  KUBECONFIG_TMP=$(mktemp)
  if proot-distro login ubuntu -- cat /etc/rancher/k3s/k3s.yaml > "${KUBECONFIG_TMP}" 2>/dev/null; then
    mv "${KUBECONFIG_TMP}" "${KUBECONFIG_FILE}"
    echo "Kubeconfig copied to ${KUBECONFIG_FILE}"
  else
    echo "Warning: Failed to read k3s.yaml from proot environment." >&2
    echo "You may need to manually configure kubectl access." >&2
    rm -f "${KUBECONFIG_TMP}"
  fi
else
  echo "Warning: Could not find k3s.yaml in proot environment." >&2
  echo "You may need to manually configure kubectl access." >&2
fi

# Set permissions
chmod 600 "${KUBECONFIG_FILE}" 2>/dev/null || true

echo ""
echo "============================================"
echo "Installation Complete!"
echo "============================================"
echo ""
echo "To use kubectl, run:"
echo "  export KUBECONFIG=${KUBECONFIG_FILE}"
echo "  kubectl get nodes"
echo ""
echo "To access the proot Ubuntu environment:"
echo "  proot-distro login ubuntu"
echo ""
echo "Note: k3s runs inside the proot Ubuntu environment."
echo "Some features may be limited on Android/Termux."
echo "============================================"
