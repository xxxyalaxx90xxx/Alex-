# Alex - Complete Automated, Optimized, and Analyzed K8S Setup

## 🚀 Fully Automated Installation, Analysis & Optimization

This repository provides a complete solution for Kubernetes cluster setup with automated installation, verification, analysis, and optimization capabilities.

## Quick Start

### Option 1: Complete Automated Workflow (Recommended)

Run the complete automation script after installing the cluster:

```bash
# 1. Install the cluster
chmod +x install_k8s.sh
sudo ./install_k8s.sh

# 2. Run complete automation (verify + analyze + optimize)
chmod +x complete_k8s.sh
./complete_k8s.sh
```

**What it does:**
- ✅ Verifies cluster installation and health
- 🔍 Analyzes performance, security, and resources  
- ⚡ Provides optimization recommendations

**Options:**
```bash
./complete_k8s.sh --help              # Show all options
./complete_k8s.sh --verify-only       # Only verification
./complete_k8s.sh --analyze-only      # Only analysis
./complete_k8s.sh --skip-verify       # Skip verification step
```

### Option 2: Individual Scripts

### 1. Install Kubernetes Cluster

Run the automated installation script to install kubeadm/kubelet/kubectl, enable containerd CRI, initialize the control plane, apply flannel, and optionally configure hugepages:

```bash
chmod +x install_k8s.sh
# optionally set ADVERTISE_ADDRESS, POD_CIDR, HUGEPAGES_2MI, KUBECONFIG_FILE
sudo ./install_k8s.sh
```

**Defaults:**
- `ADVERTISE_ADDRESS`: first host IP (from `hostname -I`)
- `POD_CIDR`: `10.244.0.0/16`
- `HUGEPAGES_2MI`: not configured unless set
- `KUBECONFIG_FILE`: `$HOME/.kube/config`

### 2. Verify Cluster Installation

After installation, verify the cluster is operational:

```bash
chmod +x verify_k8s.sh
./verify_k8s.sh
```

This script performs comprehensive checks:
- ✓ kubectl availability and connectivity
- ✓ API server health and responsiveness
- ✓ Node status and readiness
- ✓ System pods (kube-apiserver, etcd, scheduler, etc.)
- ✓ CNI plugin (flannel) status
- ✓ DNS functionality
- ✓ Container runtime verification
- ✓ Resource availability

### 3. Analyze Cluster Health

Run comprehensive cluster analysis:

```bash
chmod +x analyze_k8s.sh
./analyze_k8s.sh
```

**Analysis includes:**
- **Health**: Node and pod status, system components
- **Resources**: CPU/memory usage, resource limits
- **Performance**: API server responsiveness, restart counts
- **Security**: Privileged containers, RBAC, network policies
- **Storage**: PV/PVC status and usage

### 4. Get Optimization Recommendations

Receive tailored optimization recommendations:

```bash
chmod +x optimize_k8s.sh
./optimize_k8s.sh
```

**Optimization areas:**
- **Performance**: Node performance, CPU manager policies
- **Resources**: Pod resource requests/limits, QoS classes
- **Networking**: CNI configuration, network policies, service types
- **Storage**: Storage classes, PV management
- **Security**: Pod security, RBAC, privileged containers
- **High Availability**: Control plane redundancy, component scaling
- **Monitoring**: Metrics server, logging, observability

**Environment variables:**
- `DRY_RUN=1` (default): Show recommendations only
- `DRY_RUN=0`: Apply safe optimizations automatically

## 📋 Complete Workflow Example

```bash
# 1. Install the cluster
sudo ./install_k8s.sh

# 2. Verify installation was successful
./verify_k8s.sh

# 3. Analyze cluster health and performance
./analyze_k8s.sh

# 4. Get optimization recommendations
./optimize_k8s.sh

# 5. Monitor cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

## Features

### ✨ Complete Automation
- **Zero manual configuration**: Automated repository setup, containerd CRI configuration, kubeadm initialization
- **Intelligent defaults**: Automatically detects host IP, sets up pod network, configures kubectl
- **Error handling**: Robust error checking and validation at each step
- **Flexible configuration**: Environment variables for customization

### 🔍 Comprehensive Analysis
- **Health monitoring**: Real-time cluster and component health checks
- **Performance metrics**: API server responsiveness, resource usage tracking
- **Security auditing**: Privileged container detection, RBAC analysis
- **Resource tracking**: Pod/node resources, QoS classes, storage utilization

### ⚡ Intelligent Optimization
- **Best practices**: Recommendations based on Kubernetes best practices
- **Performance tuning**: CPU manager policies, hugepages configuration
- **Security hardening**: Pod security standards, RBAC least privilege
- **High availability**: Multi-master recommendations, component redundancy
- **Observability**: Monitoring and logging solution suggestions

### ✅ Automated Verification
- **Post-install validation**: Ensures all components are operational
- **DNS testing**: Verifies internal cluster DNS resolution
- **Component health**: Validates API server, etcd, scheduler, controller-manager
- **Network verification**: Checks CNI plugin functionality
- **Detailed reporting**: Pass/fail/warning counts with actionable information

## Manual Installation Steps (Alternative)

If you prefer manual installation, follow these steps:

### Install kubelet

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

## 🎯 Advanced Usage

### Custom Configuration

```bash
# Install with custom settings
export ADVERTISE_ADDRESS="192.168.1.100"
export POD_CIDR="10.100.0.0/16"
export HUGEPAGES_2MI="256"
export KUBECONFIG_FILE="$HOME/.kube/my-config"
sudo ./install_k8s.sh
```

### Analysis Options

```bash
# Verbose output
VERBOSE=1 ./analyze_k8s.sh

# JSON output format
OUTPUT_FORMAT=json ./analyze_k8s.sh
```

### Optimization Modes

```bash
# Dry-run mode (default) - recommendations only
DRY_RUN=1 ./optimize_k8s.sh

# Apply safe optimizations automatically
DRY_RUN=0 AUTO_APPLY=1 ./optimize_k8s.sh
```

### Custom kubeconfig

```bash
# Use custom kubeconfig for all scripts
export KUBECONFIG_FILE="/path/to/kubeconfig"
./verify_k8s.sh
./analyze_k8s.sh
./optimize_k8s.sh
```

## 📊 Sample Output

### Verification Output
```
==========================================
  Kubernetes Cluster Verification
==========================================
[✓ PASS] kubectl is available
[✓ PASS] Kubeconfig file exists
[✓ PASS] Successfully connected to cluster
[✓ PASS] API server is healthy
[✓ PASS] All 1 node(s) are Ready
[✓ PASS] kube-apiserver is running
[✓ PASS] CoreDNS is running
[✓ PASS] Flannel CNI is running
[✓ PASS] No failed pods detected

Checks Passed:  15
Warnings:       2
Checks Failed:  0

✓ All critical checks passed!
✓ Cluster is operational and ready for use
```

### Analysis Summary
```
=== Cluster Health Analysis ===
[✓] All 1 nodes are Ready
[✓] Running: 8 pods
[✓] kube-apiserver is running
[✓] CoreDNS is running

=== Performance Analysis ===
[✓] API server response time: 245ms (Good)
[✓] No pods with excessive restarts

=== Security Analysis ===
[✓] RBAC is enabled
[⚠] No network policies found - consider implementing network segmentation
```

## 🔧 Troubleshooting

### Cluster not accessible
```bash
# Check kubeconfig
ls -la ~/.kube/config
cat ~/.kube/config

# Test connectivity
kubectl cluster-info
kubectl get nodes
```

### Pods not starting
```bash
# Check pod details
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Run verification
./verify_k8s.sh
```

### Performance issues
```bash
# Run analysis to identify bottlenecks
./analyze_k8s.sh

# Get optimization recommendations
./optimize_k8s.sh

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

## 📝 Requirements

- CentOS/RHEL 7+ or compatible Linux distribution
- Root or sudo access
- Internet connectivity (for package downloads)
- At least 2GB RAM
- 2 CPUs or more

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## 📄 License

This project is provided as-is for educational and operational purposes.

---

## Check Status (After Installation)

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

## 🤖 GitHub MCP Server Integration

This repository also includes documentation for setting up and using the GitHub MCP (Model Context Protocol) Server, which enables AI-powered tools to interact with GitHub repositories, issues, pull requests, and workflows.

**See [GITHUB_MCP_SERVER.md](./GITHUB_MCP_SERVER.md) for complete installation and configuration instructions.**

### Quick Start with GitHub MCP Server

The GitHub MCP Server allows you to:
- Interact with GitHub repositories through AI tools
- Manage issues and pull requests via AI assistants
- Execute GitHub Actions workflows programmatically
- Search code and analyze repositories

Supports:
- ✅ GitHub.com
- ✅ GitHub Enterprise Server
- ✅ GitHub Enterprise Cloud with data residency (ghe.com)

### Compatible IDEs

- VS Code / VS Code Insiders (with one-click install)
- JetBrains IDEs (IntelliJ IDEA, PyCharm, WebStorm, etc.)
- Visual Studio
- Eclipse
- Any IDE supporting MCP

For detailed setup instructions, troubleshooting, and security best practices, refer to [GITHUB_MCP_SERVER.md](./GITHUB_MCP_SERVER.md).

---

Deepseek
