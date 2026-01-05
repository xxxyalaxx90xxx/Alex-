#!/usr/bin/env bash
set -euo pipefail

# Automated kubeadm install script for CentOS/RHEL 7 style hosts.
# Options:
#   ADVERTISE_ADDRESS: API server advertise address (defaults to first host IP)
#   POD_CIDR:           Pod network CIDR (default: 10.244.0.0/16 for flannel)
#   HUGEPAGES_2MI:      Number of 2Mi hugepages to configure (optional)
#   KUBECONFIG_FILE:    Path to write kubeconfig for kubectl (default: $HOME/.kube/config)

SUDO_CMD="sudo"
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  SUDO_CMD=""
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

get_primary_ip() {
  if command_exists hostname; then
    hostname -I 2>/dev/null | awk '{print $1}' | head -n1
  fi
}

ADVERTISE_ADDRESS=${ADVERTISE_ADDRESS:-$(get_primary_ip)}
POD_CIDR=${POD_CIDR:-10.244.0.0/16}
HUGEPAGES_2MI=${HUGEPAGES_2MI:-}
KUBECONFIG_FILE=${KUBECONFIG_FILE:-$HOME/.kube/config}

if [ -z "${ADVERTISE_ADDRESS}" ]; then
  echo "Unable to determine ADVERTISE_ADDRESS automatically. Set ADVERTISE_ADDRESS explicitly." >&2
  exit 1
fi

echo "[1/6] Configure Kubernetes yum repository"
$SUDO_CMD tee /etc/yum.repos.d/kubernetes.repo >/dev/null <<'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

echo "[2/6] Set SELinux to permissive mode"
$SUDO_CMD setenforce 0 2>/dev/null || true
$SUDO_CMD sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config || true

echo "[3/6] Install kubelet, kubeadm, kubectl"
$SUDO_CMD yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
$SUDO_CMD systemctl enable --now kubelet

echo "[4/6] Ensure containerd has CRI enabled"
if ! command_exists containerd; then
  $SUDO_CMD yum install -y containerd
fi
$SUDO_CMD mkdir -p /etc/containerd
if [ ! -f /etc/containerd/config.toml ]; then
  $SUDO_CMD containerd config default | $SUDO_CMD tee /etc/containerd/config.toml >/dev/null
fi
$SUDO_CMD sed -i 's/^disabled_plugins = \["cri"\]/# disabled_plugins = ["cri"]/g' /etc/containerd/config.toml
$SUDO_CMD systemctl enable --now containerd
$SUDO_CMD systemctl restart containerd

if [ -n "${HUGEPAGES_2MI}" ]; then
  echo "[5/6] Configure hugepages (${HUGEPAGES_2MI} x 2Mi)"
  $SUDO_CMD bash -c "echo ${HUGEPAGES_2MI} > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages"
else
  echo "[5/6] Skip hugepage configuration (HUGEPAGES_2MI not set)"
fi

echo "[6/6] Initialize control plane with kubeadm"
$SUDO_CMD kubeadm init \
  --ignore-preflight-errors Swap \
  --apiserver-advertise-address="${ADVERTISE_ADDRESS}" \
  --pod-network-cidr="${POD_CIDR}"

echo "[post] Configure kubectl access"
$SUDO_CMD mkdir -p "$(dirname "${KUBECONFIG_FILE}")"
$SUDO_CMD cp /etc/kubernetes/admin.conf "${KUBECONFIG_FILE}"
$SUDO_CMD chown "$(id -u):$(id -g)" "${KUBECONFIG_FILE}"

echo "[post] Deploy flannel CNI (${POD_CIDR})"
kubectl --kubeconfig="${KUBECONFIG_FILE}" apply -f https://raw.githubusercontent.com/coreos/flannel/v0.22.0/Documentation/kube-flannel.yml

if [ -n "${HUGEPAGES_2MI}" ]; then
  echo "[post] Restart kubelet to pick up hugepages"
  $SUDO_CMD systemctl restart kubelet
fi

echo "Cluster initialization complete."
