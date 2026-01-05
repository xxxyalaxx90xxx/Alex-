# Alex - Comprehensive Kubernetes Installation System

## 🚀 Complete Installation System (NEWEST - v2.0)

**Enterprise-grade installation with comprehensive features, preflight checks, logging, and multi-OS support!**

The complete installation system provides a professional-grade experience with extensive validation, logging, and support for a wide range of systems.

```bash
chmod +x install_k8s_complete.sh
sudo ./install_k8s_complete.sh
```

### Key Features:
- ✅ **Comprehensive preflight checks** - Network, disk space, memory validation
- ✅ **Professional logging** - Colored output, detailed log files
- ✅ **State management** - Save and restore installation state
- ✅ **Multi-OS support** - CentOS/RHEL 7-9, Ubuntu 18.04-24.04, Debian 9-12, Fedora, openSUSE, Arch, Alpine
- ✅ **Multi-architecture** - AMD64, ARM64, ARMv7, ARMv6
- ✅ **Post-installation verification** - Automatic health checks
- ✅ **Smart resource detection** - Auto-selects best K8s distribution
- ✅ **Rollback support** - Uninstall script included
- ✅ **Mobile device optimization** - Realme C63, Termux, Android support

### Advanced Configuration:
```bash
# Automatic installation with all checks
sudo ./install_k8s_complete.sh

# Skip preflight checks (not recommended)
SKIP_PREFLIGHT=1 sudo ./install_k8s_complete.sh

# Automated installation (no prompts)
AUTO_INSTALL=1 sudo ./install_k8s_complete.sh

# Specific Kubernetes version
KUBERNETES_VERSION=1.29 sudo ./install_k8s_complete.sh

# Specific K3s version  
K3S_VERSION=v1.28.5+k3s1 sudo ./install_k8s_complete.sh

# Custom log file location
LOG_FILE=/var/log/k8s_install.log sudo ./install_k8s_complete.sh

# Disable colored output
NO_COLOR=1 sudo ./install_k8s_complete.sh
```

### Installation Modes:
| Mode | Description | Auto-Selected When |
|------|-------------|-------------------|
| **lightweight** (K3s) | Minimal footprint, fast startup | <2GB RAM, mobile devices, ARM |
| **full** (kubeadm) | Complete K8s features | ≥2GB RAM, x86_64 servers |

### Supported Operating Systems:
| OS Family | Versions | Package Manager | Status |
|-----------|----------|----------------|--------|
| CentOS/RHEL | 7, 8, 9 | yum/dnf | ✅ Tested |
| Ubuntu | 18.04, 20.04, 22.04, 24.04 | apt | ✅ Tested |
| Debian | 9, 10, 11, 12 | apt | ✅ Tested |
| Fedora | 35+ | dnf | ✅ Supported |
| openSUSE | Leap, Tumbleweed | zypper | ✅ Supported |
| Arch Linux | Rolling | pacman | ✅ Supported |
| Alpine Linux | 3.x | apk | ⚠️ Experimental |

### Uninstallation:
```bash
# Interactive uninstall
sudo ./uninstall_k8s.sh

# Force uninstall (no prompts)
sudo ./uninstall_k8s.sh --force
```

---

## 🚀 Optimized Installation (Realme C63 & Mobile Devices Support)

**Automatic installation with resource detection and optimization for mobile devices!**

The new optimized installer automatically detects your system and chooses the best Kubernetes distribution:
- **Full Kubernetes (kubeadm)** for servers and powerful machines (>2GB RAM)
- **Lightweight K3s** for resource-constrained devices like Realme C63, mobile devices, and ARM devices (<2GB RAM)

```bash
chmod +x install_k8s_optimized.sh
sudo ./install_k8s_optimized.sh
```

### Features:
- ✅ **Automatic resource detection** - Detects CPU, memory, architecture
- ✅ **Smart installation mode** - Chooses optimal K8s distribution
- ✅ **Multi-architecture support** - AMD64, ARM64, ARM (mobile devices)
- ✅ **Multi-OS support** - CentOS/RHEL, Ubuntu/Debian
- ✅ **Mobile device optimization** - Special optimizations for Realme C63 and similar devices
- ✅ **Minimal resource footprint** - K3s uses <512MB RAM
- ✅ **Termux support** - Can run in Android Termux environment

### Configuration Options:
```bash
# Force lightweight mode (K3s) even on powerful machines
INSTALL_MODE=lightweight sudo ./install_k8s_optimized.sh

# Force full Kubernetes mode
INSTALL_MODE=full sudo ./install_k8s_optimized.sh

# Custom API server address
ADVERTISE_ADDRESS=192.168.1.100 sudo ./install_k8s_optimized.sh

# Skip memory check prompt
yes | sudo ./install_k8s_optimized.sh
```

### System Requirements:
| Device Type | Minimum RAM | Recommended | K8s Distribution |
|------------|-------------|-------------|------------------|
| Mobile devices (Realme C63, etc.) | 1GB | 2GB | K3s (Lightweight) |
| ARM devices (Raspberry Pi, etc.) | 1GB | 2GB | K3s (Lightweight) |
| Standard servers | 2GB | 4GB | Full Kubernetes |

---

## 📊 Installation Script Comparison

Choose the right installation script for your needs:

| Feature | Complete (v2.0) | Optimized | Legacy |
|---------|----------------|-----------|--------|
| **Script** | `install_k8s_complete.sh` | `install_k8s_optimized.sh` | `install_k8s.sh` |
| **Best For** | Production, Enterprise | Mobile, ARM devices | Simple servers |
| **Preflight Checks** | ✅ Comprehensive | ❌ Basic | ❌ None |
| **Logging** | ✅ Professional | ❌ Basic | ❌ None |
| **Colored Output** | ✅ Yes | ❌ No | ❌ No |
| **State Management** | ✅ Yes | ❌ No | ❌ No |
| **Post-Verification** | ✅ Automatic | ❌ Manual | ❌ Manual |
| **Multi-OS Support** | ✅ 8+ distros | ✅ 3 distros | ✅ CentOS/RHEL |
| **Uninstall Script** | ✅ Included | ❌ Manual | ❌ Manual |
| **Mobile Optimization** | ✅ Yes | ✅ Yes | ❌ No |
| **K3s Support** | ✅ Yes | ✅ Yes | ❌ No |
| **Configuration Options** | 10+ options | 6 options | 4 options |
| **Lines of Code** | ~800 | ~435 | ~170 |

### Quick Selection Guide:
- **🏢 Production/Enterprise**: Use `install_k8s_complete.sh` - Most features, best validation
- **📱 Mobile/ARM Devices**: Use `install_k8s_optimized.sh` or `install_k8s_complete.sh` - Both support K3s
- **🚀 Quick Setup**: Use `install_k8s.sh` - Fastest, minimal configuration
- **🔧 Custom Requirements**: Use `install_k8s_complete.sh` - Most configurable

---

## Fully automated install (Legacy)

Run the provided script to install kubeadm/kubelet/kubectl, enable containerd CRI, initialize the control plane, apply flannel, and optionally configure hugepages without manual edits:

```
chmod +x install_k8s.sh
# optionally set ADVERTISE_ADDRESS, POD_CIDR, HUGEPAGES_2MI, KUBECONFIG_FILE
sudo ./install_k8s.sh
```

Defaults:
- `ADVERTISE_ADDRESS`: first host IP (from `hostname -I`)
- `POD_CIDR`: `10.244.0.0/16`
- `HUGEPAGES_2MI`: not configured unless set
- `KUBECONFIG_FILE`: `$HOME/.kube/config`

## Install kubelet

```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repomd.xml.key
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl

sudo systemctl enable --now kubelet
```

## Enable CRI

```
# comment out line: `disabled_plugins = ["cri"]`
sudo vim /etc/containerd/config.toml

# restart containerd
sudo systemctl restart containerd
```

## Setup K8S
```
# replace "172.26.10.67" with the IP address of your machine
sudo kubeadm init --ignore-preflight-errors Swap --apiserver-advertise-address=172.26.10.67 --pod-network-cidr=10.244.0.0/16
# follow instructions to copy kubeconfig file to $HOME/.kube/config


kubectl create -f https://raw.githubusercontent.com/flannel-io/flannel/629cd70d816e56853aac967f92ed3dade7275baf/Documentation/kube-flannel.yml

or
https://raw.githubusercontent.com/flannel-io/flannel/629cd70d816e56853aac967f92ed3dade7275baf/Documentation/kube-flannel.yml
```

## Setup Hugepage
```
# set hugepage
sudo bash -c "echo 256 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages"

# restart kubelet
sudo systemctl restart kubelet

# check if kubelet has recognized hugepage
kubectl get nodes -oyaml | grep hugepages-2Mi
```

## Check Status

```
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

## Analyze Cluster Data (Datenanalyse)

After setting up the Kubernetes cluster, you can run a comprehensive data analysis to check the cluster health and generate a detailed report:

```
chmod +x analyze_k8s.sh
./analyze_k8s.sh
```

**Now supports both Full Kubernetes and K3s installations!** The script automatically detects your K8s distribution and kubeconfig location.

The analysis script will:
- Detect system architecture and resources (optimized for Realme C63 and mobile devices)
- Identify K8s distribution (Full Kubernetes or K3s)
- Collect cluster version and configuration information
- Analyze node status and resource allocation
- Review all pods across namespaces and their health
- Check network configuration (CNI plugins)
- Examine storage resources (PV, PVC, StorageClasses)
- Review recent events and warnings
- Assess component health
- Generate a comprehensive summary report

By default, the report is saved to `k8s_analysis_report.txt`. You can customize the output file:

```
OUTPUT_FILE=my_report.txt ./analyze_k8s.sh
```

If your kubeconfig is in a non-standard location:

```
KUBECONFIG_FILE=/path/to/kubeconfig ./analyze_k8s.sh
```

The analysis provides:
- Summary statistics (nodes, pods, namespaces)
- Overall cluster health assessment
- Detailed information for troubleshooting
- Resource utilization metrics (if metrics-server is installed)

For more details on the analysis output and examples, see [ANALYSIS_EXAMPLE.md](ANALYSIS_EXAMPLE.md)

Deepseek
