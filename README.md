# Alex - Setup K8S by kubeadm

## Table of Contents
- [Automated Installation for Linux (CentOS/RHEL)](#fully-automated-install-for-linux)
- [Automated Installation for Termux (Android)](#fully-automated-install-for-termux)
- [Manual Installation Steps](#manual-installation-steps)

## Fully automated install for Linux

Run the provided script to install kubeadm/kubelet/kubectl, enable containerd CRI, initialize the control plane, apply flannel, and optionally configure hugepages without manual edits:

```bash
chmod +x install_k8s.sh
# optionally set ADVERTISE_ADDRESS, POD_CIDR, HUGEPAGES_2MI, KUBECONFIG_FILE
sudo ./install_k8s.sh
```

Defaults:
- `ADVERTISE_ADDRESS`: first host IP (from `hostname -I`)
- `POD_CIDR`: `10.244.0.0/16`
- `HUGEPAGES_2MI`: not configured unless set
- `KUBECONFIG_FILE`: `$HOME/.kube/config`

## Fully automated install for Termux

For Android devices using Termux, use the specialized Termux installation script that sets up k3s (lightweight Kubernetes) in a proot environment with full automation:

```bash
chmod +x install_termux.sh
# For fully automated installation (no prompts)
AUTO_YES=true ./install_termux.sh

# Or with custom options
POD_CIDR=10.42.0.0/16 K3S_VERSION=v1.28.0 ./install_termux.sh
```

### Features

The Termux installation script provides:
- **Automatic permission setup** - Configures storage access automatically
- **Complete k3s installation** - Installs k3s in proot Ubuntu environment
- **kubectl installation** - Architecture detection (arm64/arm) and automatic download
- **Helper scripts** - Auto-generates management scripts for k3s
- **Verification** - Validates installation and reports status
- **Error handling** - Comprehensive troubleshooting guidance

### After Installation

Use kubectl from within Termux:

```bash
export KUBECONFIG=$HOME/.kube/config
kubectl get nodes

# Or use the helper wrapper
k3s-kubectl get nodes
```

### Helper Scripts

The installation creates these helper scripts:

```bash
~/k3s-start.sh   # Start k3s service
~/k3s-stop.sh    # Stop k3s service
~/k3s-status.sh  # Check k3s status
```

To access the proot Ubuntu environment where k3s runs:

```bash
proot-distro login ubuntu
```

**Note:** Full kubeadm is not supported on Android/Termux due to architecture limitations. The script installs k3s (lightweight Kubernetes) instead, which provides most Kubernetes functionality in a resource-constrained environment.

### Configuration Options

- `POD_CIDR`: `10.42.0.0/16` (k3s default)
- `KUBECONFIG_FILE`: `$HOME/.kube/config`
- `K3S_VERSION`: latest stable version
- `AUTO_YES`: `false` (set to `true` for fully automated installation)

## Manual Installation Steps

## Install kubelet

```bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl

sudo systemctl enable --now kubelet
```

## Enable CRI

```bash
# comment out line: `disabled_plugins = ["cri"]`
sudo vim /etc/containerd/config.toml

# restart containerd
sudo systemctl restart containerd
```

## Setup K8S
```bash
# replace "172.26.10.67" with the IP address of your machine
sudo kubeadm init --ignore-preflight-errors Swap --apiserver-advertise-address=172.26.10.67 --pod-network-cidr=10.244.0.0/16
# follow instructions to copy kubeconfig file to $HOME/.kube/config

# Apply flannel CNI network plugin
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/629cd70d816e56853aac967f92ed3dade7275baf/Documentation/kube-flannel.yml
```

## Setup Hugepage
```bash
# set hugepage
sudo bash -c "echo 256 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages"

# restart kubelet
sudo systemctl restart kubelet

# check if kubelet has recognized hugepage
kubectl get nodes -oyaml | grep hugepages-2Mi
```

## Check Status

```bash
# check node status to be Ready
$kubectl get node
NAME                                              STATUS   ROLES           AGE    VERSION
ip-172-26-10-67.ap-northeast-1.compute.internal   Ready    control-plane   139m   v1.27.4

# all pods should be Running
$kubectl get pods --all-namespaces
NAMESPACE      NAME                                                                      READY   STATUS    RESTARTS      AGE
kube-flannel   kube-flannel-ds-h5dcn                                                     1/1     Running   0             138m
kube-system    coredns-5d78c9869d-g4x5w                                                  1/1     Running   0             139m
kube-system    coredns-5d78c9869d-x8hmd                                                  1/1     Running   0             139m
kube-system    etcd-ip-172-26-10-67.ap-northeast-1.compute.internal                      1/1     Running   0             139m
kube-system    kube-apiserver-ip-172-26-10-67.ap-northeast-1.compute.internal            1/1     Running   0             139m
kube-system    kube-controller-manager-ip-172-26-10-67.ap-northeast-1.compute.internal   1/1     Running   0             139m
kube-system    kube-proxy-zs75b                                                          1/1     Running   0             139m
kube-system    kube-scheduler-ip-172-26-10-67.ap-northeast-1.compute.internal            1/1     Running   0             139m
```
