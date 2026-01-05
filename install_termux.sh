#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Automated Kubernetes setup script for Termux (Android)
# This script installs and configures k3s (lightweight Kubernetes) on Termux
# Note: Full kubeadm is not supported on Termux/Android architecture

# Options:
#   POD_CIDR:           Pod network CIDR (default: 10.42.0.0/16 for k3s)
#   KUBECONFIG_FILE:    Path to write kubeconfig for kubectl (default: $HOME/.kube/config)
#   K3S_VERSION:        Version of k3s to install (default: latest stable)
#   AUTO_YES:           Skip confirmations (default: false, set to "true" for full automation)

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

# Check for storage permissions
check_storage_permission() {
  if [ ! -d "$HOME/storage" ] || [ ! -L "$HOME/storage" ]; then
    echo "Storage access not configured. Setting up storage access..."
    echo "This allows Termux to access shared storage on your device."
    if command_exists termux-setup-storage; then
      echo "Please grant storage permission when prompted..."
      termux-setup-storage || echo "Warning: Storage setup failed or was denied"
      sleep 2
    else
      echo "Warning: termux-setup-storage not available"
    fi
  else
    echo "Storage access already configured ✓"
  fi
}

# Configuration
POD_CIDR=${POD_CIDR:-10.42.0.0/16}
KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}
K3S_VERSION=${K3S_VERSION:-}
AUTO_YES=${AUTO_YES:-false}

# Check storage permissions
check_storage_permission

echo ""
echo "[1/8] Update Termux packages"
if [ "$AUTO_YES" = "true" ]; then
  pkg update -y
  pkg upgrade -y
else
  echo "Updating package lists..."
  pkg update -y
  echo "Upgrading packages (this may take a while)..."
  pkg upgrade -y
fi

echo "[2/8] Install required packages"
pkg install -y root-repo
pkg install -y wget curl proot-distro

# Install additional useful tools
echo "Installing additional tools (git, nano, openssh)..."
pkg install -y git nano openssh 2>/dev/null || echo "Some optional packages skipped"

echo "[3/8] Install proot-distro Ubuntu"
if ! proot-distro list | grep -q "ubuntu (installed)"; then
  echo "Installing Ubuntu distribution (this will download ~200MB)..."
  if [ "$AUTO_YES" = "true" ]; then
    proot-distro install ubuntu
  else
    echo "This may take several minutes depending on your connection..."
    proot-distro install ubuntu
  fi
else
  echo "Ubuntu distribution already installed ✓"
fi

echo "[4/8] Create k3s installation script for proot environment"
cat > /tmp/k3s_install_inner.sh <<'INNER_SCRIPT'
#!/bin/bash
set -euo pipefail

echo "Setting up k3s in proot Ubuntu environment..."

# Install dependencies in Ubuntu proot
echo "Installing dependencies..."
apt-get update -qq
apt-get install -y curl wget iptables ca-certificates

# Download and install k3s
echo "Downloading and installing k3s..."
K3S_VERSION="${K3S_VERSION:-}"
if [ -n "${K3S_VERSION}" ]; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${K3S_VERSION}" sh -
else
  curl -sfL https://get.k3s.io | sh -
fi

# Wait for k3s to start
echo "Waiting for k3s to initialize..."
sleep 10

# Check k3s status
if command -v systemctl >/dev/null 2>&1; then
  systemctl status k3s --no-pager || echo "k3s status check completed"
elif command -v service >/dev/null 2>&1; then
  service k3s status || echo "k3s status check completed"
else
  echo "k3s service manager not available, skipping status check"
fi

# Verify k3s installation
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
  echo "k3s configuration file found ✓"
else
  echo "Warning: k3s configuration file not found"
fi

echo "k3s installation complete in proot environment"
INNER_SCRIPT

echo "[5/8] Install k3s in proot Ubuntu environment"
echo "Note: This may take several minutes..."
echo "The script will:"
echo "  - Update package lists in Ubuntu"
echo "  - Install required dependencies"
echo "  - Download and install k3s"
echo "  - Configure k3s service"
echo ""

# Setup cleanup trap
cleanup_k3s_script() {
  rm -f /tmp/k3s_install_inner.sh
}
trap cleanup_k3s_script EXIT

# Copy script to proot environment
echo "Preparing proot environment..."
proot-distro login ubuntu -- mkdir -p /tmp 2>/dev/null || true
cat /tmp/k3s_install_inner.sh | proot-distro login ubuntu -- tee /tmp/k3s_install_inner.sh >/dev/null
proot-distro login ubuntu -- chmod +x /tmp/k3s_install_inner.sh

echo "Installing k3s (please be patient, this may take 5-10 minutes)..."
K3S_INSTALL_FAILED=false
if ! proot-distro login ubuntu -- /tmp/k3s_install_inner.sh; then
  K3S_INSTALL_FAILED=true
  echo ""
  echo "========================================" >&2
  echo "Warning: k3s installation in proot encountered issues." >&2
  echo "========================================" >&2
  echo "Troubleshooting steps:" >&2
  echo "  1. Check if proot-distro is working: proot-distro list" >&2
  echo "  2. Verify network connectivity: curl -I https://get.k3s.io" >&2
  echo "  3. Check available disk space: df -h" >&2
  echo "  4. Try manual installation: proot-distro login ubuntu" >&2
  echo "You may need to manually complete the setup." >&2
  echo "========================================" >&2
  echo ""
else
  echo "k3s installation completed successfully ✓"
fi

# Cleanup
trap - EXIT
cleanup_k3s_script

echo "[6/8] Install kubectl in Termux"
if ! command_exists kubectl; then
  echo "Downloading kubectl..."
  KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  
  if [ -z "${KUBECTL_VERSION}" ]; then
    echo "Error: Failed to retrieve kubectl version" >&2
    echo "This could be due to:" >&2
    echo "  - Network connectivity issues" >&2
    echo "  - Kubernetes download server unavailable" >&2
    echo "Please check your internet connection and try again." >&2
    exit 1
  fi
  
  echo "Latest kubectl version: ${KUBECTL_VERSION}"
  
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

echo "[7/8] Setup kubeconfig"
mkdir -p "$(dirname "${KUBECONFIG_FILE}")"

# Try to copy kubeconfig from proot environment
if proot-distro login ubuntu -- test -f /etc/rancher/k3s/k3s.yaml 2>/dev/null; then
  # Copy kubeconfig to Termux environment with secure permissions
  KUBECONFIG_TMP=$(mktemp)
  chmod 600 "${KUBECONFIG_TMP}"
  if proot-distro login ubuntu -- cat /etc/rancher/k3s/k3s.yaml > "${KUBECONFIG_TMP}" 2>/dev/null; then
    mv "${KUBECONFIG_TMP}" "${KUBECONFIG_FILE}"
    chmod 600 "${KUBECONFIG_FILE}"
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

echo "[8/8] Create helper scripts and verify installation"

# Create helper script to start k3s
cat > "$HOME/k3s-start.sh" <<'HELPER_START'
#!/data/data/com.termux/files/usr/bin/bash
echo "Starting k3s in proot Ubuntu environment..."
proot-distro login ubuntu -- systemctl start k3s 2>/dev/null || \
proot-distro login ubuntu -- service k3s start 2>/dev/null || \
echo "k3s service may already be running or service manager not available"
echo "k3s start command completed"
HELPER_START
chmod +x "$HOME/k3s-start.sh"

# Create helper script to stop k3s
cat > "$HOME/k3s-stop.sh" <<'HELPER_STOP'
#!/data/data/com.termux/files/usr/bin/bash
echo "Stopping k3s in proot Ubuntu environment..."
proot-distro login ubuntu -- systemctl stop k3s 2>/dev/null || \
proot-distro login ubuntu -- service k3s stop 2>/dev/null || \
echo "k3s service may not be running or service manager not available"
echo "k3s stop command completed"
HELPER_STOP
chmod +x "$HOME/k3s-stop.sh"

# Create helper script to check k3s status
cat > "$HOME/k3s-status.sh" <<'HELPER_STATUS'
#!/data/data/com.termux/files/usr/bin/bash
echo "Checking k3s status in proot Ubuntu environment..."
proot-distro login ubuntu -- systemctl status k3s --no-pager 2>/dev/null || \
proot-distro login ubuntu -- service k3s status 2>/dev/null || \
echo "k3s service manager not available"
HELPER_STATUS
chmod +x "$HOME/k3s-status.sh"

# Create comprehensive kubectl wrapper
cat > "$PREFIX/bin/k3s-kubectl" <<'KUBECTL_WRAPPER'
#!/data/data/com.termux/files/usr/bin/bash
# Wrapper for kubectl with automatic kubeconfig setup
export KUBECONFIG="$HOME/.kube/config"
kubectl "$@"
KUBECTL_WRAPPER
chmod +x "$PREFIX/bin/k3s-kubectl"

echo ""
echo "Helper scripts created:"
echo "  $HOME/k3s-start.sh   - Start k3s service"
echo "  $HOME/k3s-stop.sh    - Stop k3s service"
echo "  $HOME/k3s-status.sh  - Check k3s status"
echo "  k3s-kubectl          - kubectl with auto-config (use: k3s-kubectl get nodes)"
echo ""

# Verify installation
echo "Verifying installation..."
echo ""
echo "✓ Checking kubectl installation..."
if command_exists kubectl; then
  kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null || echo "kubectl installed"
else
  echo "✗ kubectl not found in PATH"
fi

echo ""
echo "✓ Checking proot Ubuntu installation..."
if proot-distro list | grep -q "ubuntu (installed)"; then
  echo "Ubuntu proot environment is installed"
else
  echo "✗ Ubuntu proot environment not found"
fi

echo ""
echo "✓ Checking k3s configuration..."
if proot-distro login ubuntu -- test -f /etc/rancher/k3s/k3s.yaml 2>/dev/null; then
  echo "k3s configuration file exists"
else
  echo "✗ k3s configuration file not found"
fi

echo ""
echo "============================================"
if [ "${K3S_INSTALL_FAILED}" = "true" ]; then
  echo "Installation Completed with Warnings"
  echo "============================================"
  echo ""
  echo "NOTE: k3s installation encountered issues."
  echo "Some functionality may not work until k3s is properly installed."
  echo ""
  echo "Please review the error messages above and complete the setup manually."
  echo ""
else
  echo "Installation Complete Successfully!"
  echo "============================================"
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QUICK START GUIDE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Setup kubectl environment:"
echo "   export KUBECONFIG=${KUBECONFIG_FILE}"
echo "   echo 'export KUBECONFIG=${KUBECONFIG_FILE}' >> ~/.bashrc"
echo ""
echo "2. Test kubectl access:"
echo "   kubectl get nodes"
echo "   # or use: k3s-kubectl get nodes"
echo ""
echo "3. Access the proot Ubuntu environment:"
echo "   proot-distro login ubuntu"
echo ""
echo "4. Manage k3s service:"
echo "   ~/k3s-start.sh   # Start k3s"
echo "   ~/k3s-stop.sh    # Stop k3s"
echo "   ~/k3s-status.sh  # Check status"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "IMPORTANT NOTES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "• k3s runs inside the proot Ubuntu environment"
echo "• Some Kubernetes features may be limited on Android/Termux"
echo "• Storage is limited to Termux's available space"
echo "• Network policies may have limitations in proot"
echo ""
echo "For full automation, run with: AUTO_YES=true ./install_termux.sh"
echo ""
echo "============================================"
echo "Installation process completed!"
echo "============================================"
