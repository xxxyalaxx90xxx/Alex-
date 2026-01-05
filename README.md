# Alex - Comprehensive Kubernetes Installation System

> **Production-ready Kubernetes installation and management suite for all devices - from mobile phones to enterprise servers**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28-blue.svg)](https://kubernetes.io/)
[![K3s](https://img.shields.io/badge/K3s-Latest-green.svg)](https://k3s.io/)

## 📖 Quick Navigation

- **New User?** → See [QUICKSTART.md](QUICKSTART.md) (5-minute setup)
- **Production Deployment?** → Use [Complete Installation](#-complete-installation-system-newest---v20)
- **Mobile/ARM Device?** → Use [Optimized Installation](#-optimized-installation-realme-c63--mobile-devices-support)
- **Need Help?** → Check [Troubleshooting](#-troubleshooting) or [Documentation](#-documentation)

## ✨ Complete Toolkit

| Tool | Purpose | Key Features |
|------|---------|--------------|
| **install_k8s_complete.sh** | Production installation | Preflight checks, logging, 8+ OS support, validation |
| **install_k8s_optimized.sh** | Mobile/ARM installation | Auto-detection, K3s support, Realme C63 optimized |
| **install_k8s.sh** | Legacy installation | Quick CentOS/RHEL setup |
| **upgrade_k8s.sh** | Version upgrades | K3s/kubeadm upgrade with backup |
| **validate_k8s.sh** | Testing & validation | 12 comprehensive tests, health checks |
| **backup_k8s.sh** | Backup & restore | Full cluster backup, resource export |
| **analyze_k8s.sh** | Cluster analysis | 11 analysis sections, health assessment |
| **setup_monitoring.sh** | Monitoring stack | Prometheus, Grafana, Metrics Server |
| **optimize_performance.sh** | ⭐ NEW: Performance tuning | Device-specific optimizations |
| **troubleshoot_k8s.sh** | ⭐ NEW: Auto troubleshoot | Detect & fix common issues |
| **uninstall_k8s.sh** | Clean removal | Complete cleanup, CNI removal |

### 🔧 CI/CD Templates
- **`.github/workflows/k8s-ci.yml`** - GitHub Actions workflow
- **`gitlab-ci-template.yml`** - GitLab CI/CD template

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

---

## 🧪 Validation & Testing (NEW)

Validate your Kubernetes installation with comprehensive automated tests:

```bash
chmod +x validate_k8s.sh
./validate_k8s.sh
```

### Test Coverage:
1. **kubectl availability** - Verifies kubectl installation and version
2. **Kubeconfig file** - Checks kubeconfig exists and is readable
3. **Cluster connectivity** - Tests connection to API server
4. **Node status** - Validates all nodes are Ready
5. **System pods** - Checks all system pods are Running
6. **CNI network plugin** - Verifies network plugin status
7. **CoreDNS** - Validates DNS service is operational
8. **Services** - Checks service availability
9. **Workload deployment** - Tests pod deployment capability
10. **Resource limits** - Checks metrics server (if available)
11. **RBAC** - Validates role-based access control
12. **Storage** - Verifies storage classes configuration

### Example Output:
```
✓ kubectl is installed
✓ Kubeconfig file exists
✓ Can connect to cluster
✓ All nodes are Ready
✓ All system pods are Running
...
Passed: 10 | Failed: 0 | Warnings: 2
```

---

## 💾 Backup & Restore (NEW)

Protect your cluster configuration and resources with automated backups:

### Create Backup
```bash
chmod +x backup_k8s.sh
./backup_k8s.sh backup
```

Backs up:
- Kubeconfig files
- K3s/Kubernetes configuration
- etcd data (if available)
- All Kubernetes resources (deployments, services, configmaps, secrets, PVCs)
- Cluster metadata

### List Backups
```bash
./backup_k8s.sh list
```

### Restore from Backup
```bash
./backup_k8s.sh restore ~/k8s_backups/k8s_backup_20260105_120000.tar.gz
```

### Custom Backup Location
```bash
BACKUP_DIR=/opt/backups ./backup_k8s.sh backup
```

**Backup includes:**
- Full cluster configuration
- All namespaces and resources
- Secrets (for disaster recovery)
- Compressed tarball for easy transfer

---

## 🔄 Upgrade & Updates (NEW)

Upgrade your Kubernetes or K3s installation to newer versions:

```bash
chmod +x upgrade_k8s.sh

# Upgrade K3s to latest
sudo ./upgrade_k8s.sh

# Upgrade K3s to specific version
sudo ./upgrade_k8s.sh v1.28.5+k3s1

# Upgrade kubeadm to specific version
sudo ./upgrade_k8s.sh 1.29.0

# Skip backup before upgrade (not recommended)
BACKUP_BEFORE_UPGRADE=false sudo ./upgrade_k8s.sh
```

### Features:
- Automatic backup before upgrade
- Supports both K3s and kubeadm
- Version-specific upgrades
- Cluster validation after upgrade
- Rollback capability (via backup)

---

## 📊 Monitoring Setup (NEW)

Set up a complete monitoring stack with one command:

```bash
chmod +x setup_monitoring.sh
./setup_monitoring.sh
```

### Installs:
- **Metrics Server** - Resource metrics (CPU, memory) for `kubectl top`
- **Prometheus** - Metrics collection and time-series database
- **Grafana** - Visualization and dashboards

### Access:
```bash
# Get node IP
kubectl get nodes -o wide

# Access Prometheus: http://<node-ip>:<prometheus-port>
# Access Grafana: http://<node-ip>:<grafana-port>
# Default Grafana credentials: admin/admin
```

### Customization:
```bash
# Skip specific components
INSTALL_METRICS_SERVER=false ./setup_monitoring.sh
INSTALL_PROMETHEUS=false ./setup_monitoring.sh
INSTALL_GRAFANA=false ./setup_monitoring.sh

# Custom namespace
MONITORING_NAMESPACE=observability ./setup_monitoring.sh
```

---

## 🔄 CI/CD Integration (NEW)

### GitHub Actions

Use the provided workflow template:

```yaml
# .github/workflows/k8s-ci.yml is included
```

The workflow:
- Installs K3s in CI environment
- Runs validation tests
- Performs cluster analysis
- Creates backup
- Tests on multiple Ubuntu versions
- Uploads artifacts

### GitLab CI/CD

Copy the provided template:

```bash
cp gitlab-ci-template.yml .gitlab-ci.yml
```

Features:
- Multi-stage pipeline (install, validate, backup, cleanup)
- Multi-OS testing (Ubuntu 20.04, 22.04, Debian 11)
- Artifact preservation
- Automatic cleanup

### Jenkins

Example Jenkinsfile:

```groovy
pipeline {
    agent any
    
    stages {
        stage('Install K8s') {
            steps {
                sh 'chmod +x install_k8s_optimized.sh'
                sh 'sudo AUTO_INSTALL=1 INSTALL_MODE=lightweight ./install_k8s_optimized.sh'
            }
        }
        
        stage('Validate') {
            steps {
                sh 'sudo ./validate_k8s.sh'
            }
        }
        
        stage('Backup') {
            steps {
                sh 'sudo ./backup_k8s.sh backup'
                archiveArtifacts artifacts: '**/*.tar.gz', fingerprint: true
            }
        }
    }
    
    post {
        always {
            sh 'sudo ./uninstall_k8s.sh --force || true'
        }
    }
}
```

---

---

## ⚡ Performance Optimization (NEW)

Optimize your cluster for specific device types and use cases:

```bash
chmod +x optimize_performance.sh

# Auto-detect device type and optimize
sudo ./optimize_performance.sh

# Optimize for specific device type
DEVICE_TYPE=mobile sudo ./optimize_performance.sh
DEVICE_TYPE=sbc sudo ./optimize_performance.sh
DEVICE_TYPE=server sudo ./optimize_performance.sh
```

### Optimizations Applied

**For Mobile Devices (Realme C63, etc.)**:
- Limits max pods to 20
- Disables unnecessary components (ServiceLB, Traefik)
- Aggressive memory eviction (<100Mi available)
- Frequent image garbage collection
- Host-gateway network backend (lowest overhead)

**For All Device Types**:
- Kernel parameter tuning (network, memory)
- Increased file limits
- Docker/Containerd optimization
- Reduced swap usage

### Performance Tips by Device

| Device Type | Max Recommended Pods | Resource Usage | Best For |
|-------------|---------------------|----------------|----------|
| Mobile | 10-20 | 400MB-800MB | Learning, testing |
| SBC | 20-50 | 800MB-1.5GB | Edge computing, IoT |
| Workstation | 50-100 | 1GB-2GB | Development |
| Server | 100+ | 2GB-4GB | Production |

---

## 🔍 Automated Troubleshooting (NEW)

Automatically detect and fix common Kubernetes issues:

```bash
chmod +x troubleshoot_k8s.sh

# Diagnose issues
./troubleshoot_k8s.sh

# Diagnose and auto-fix issues
AUTO_FIX=true sudo ./troubleshoot_k8s.sh
```

### Checks Performed

1. ✓ kubectl availability
2. ✓ Kubeconfig permissions  
3. ✓ Cluster connectivity
4. ✓ Node status (all Ready)
5. ✓ Pod health (no CrashLoops)
6. ✓ DNS functionality (CoreDNS)
7. ✓ Disk space (<85% usage)
8. ✓ Memory usage (<90% usage)

### Auto-Fix Capabilities

When `AUTO_FIX=true`:
- Creates kubectl symlink from k3s
- Fixes kubeconfig permissions (600)
- Starts stopped services (k3s, kubelet)
- Deletes and recreates failed pods
- Prunes unused Docker/Containerd images
- Restarts CoreDNS deployment
- Creates missing kubeconfig from K3s

### Example Output

```
✓ kubectl is available
✓ Kubeconfig permissions are correct
✓ Cluster is accessible
✗ 1 node(s) not Ready
  🔧 Restarting K3s service...
  ✓ Node status improved
✓ All pods are running
✓ CoreDNS is running
✓ Disk space is sufficient (45%)
✓ Memory usage is acceptable (62%)

Issues found: 1
Issues fixed: 1
```

---

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 5 minutes
- **[ADVANCED_GUIDE.md](ADVANCED_GUIDE.md)** ⭐ NEW - Performance tuning, troubleshooting, best practices
- **[COMPLETE_INSTALLATION_GUIDE.md](COMPLETE_INSTALLATION_GUIDE.md)** - Comprehensive installation guide (12KB)
- **[OPTIMIZED_INSTALLATION_GUIDE.md](OPTIMIZED_INSTALLATION_GUIDE.md)** - Mobile device guide (8KB)
- **[ANALYSIS_EXAMPLE.md](ANALYSIS_EXAMPLE.md)** - Analysis output examples

---

## 🔧 Troubleshooting

### Quick Fixes

#### kubectl not found
```bash
# For K3s
sudo ln -s /usr/local/bin/k3s /usr/local/bin/kubectl

# Add to PATH
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

#### Permission denied on kubeconfig
```bash
sudo chown $(id -u):$(id -g) $HOME/.kube/config
chmod 600 $HOME/.kube/config
```

#### Pods not starting
```bash
# Run validation
./validate_k8s.sh

# Check specific pod
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

#### Cluster not accessible
```bash
# Check service status
sudo systemctl status kubelet  # for kubeadm
sudo systemctl status k3s      # for K3s

# Verify kubeconfig
cat $HOME/.kube/config

# For K3s, use correct path
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

### Getting Help

1. **Run validation**: `./validate_k8s.sh` - Identifies issues
2. **Run analysis**: `./analyze_k8s.sh` - Generates detailed report
3. **Check logs**: Review installation logs in home directory
4. **Review documentation**: See guides in repository

---

## 🎯 Use Cases

| Use Case | Recommended Script | Why |
|----------|-------------------|-----|
| Production Server | `install_k8s_complete.sh` | Full validation, logging, support |
| Realme C63 / Mobile | `install_k8s_optimized.sh` | Optimized for ARM, low memory |
| Raspberry Pi | `install_k8s_optimized.sh` | K3s support, ARM architecture |
| Development/Testing | `install_k8s_complete.sh` | Easy validation and backup |
| CI/CD Pipeline | `install_k8s_complete.sh` | Automated mode, no prompts |
| Quick Lab Setup | `install_k8s.sh` | Fastest installation |

---

## 🆘 Support Matrix

### Operating Systems
| OS | Versions | Status | Install Script |
|----|----------|--------|----------------|
| CentOS/RHEL | 7, 8, 9 | ✅ Tested | Complete, Legacy |
| Ubuntu | 18.04-24.04 | ✅ Tested | Complete, Optimized |
| Debian | 9-12 | ✅ Tested | Complete, Optimized |
| Fedora | 35+ | ✅ Supported | Complete |
| openSUSE | Leap, Tumbleweed | ✅ Supported | Complete |
| Arch Linux | Rolling | ✅ Supported | Complete |
| Alpine | 3.x | ⚠️ Experimental | Complete |

### Devices
| Device | Min RAM | Architecture | Status |
|--------|---------|--------------|--------|
| Realme C63 | 1GB | ARM64 | ✅ Optimized |
| Raspberry Pi 4 | 1GB | ARM64 | ✅ Tested |
| Raspberry Pi 3 | 1GB | ARM64 | ✅ Tested |
| Standard Server | 2GB | AMD64 | ✅ Tested |
| Workstation | 2GB | AMD64 | ✅ Supported |

---

## 📊 Feature Comparison

| Feature | Complete | Optimized | Legacy | Validate | Backup | Analyze |
|---------|----------|-----------|--------|----------|--------|---------|
| Installation | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Validation Tests | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Backup/Restore | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Health Analysis | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Preflight Checks | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Logging | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ |
| Multi-OS | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| Mobile Support | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |

---

## 🔐 Security

All scripts follow security best practices:
- ✅ No pipe-to-shell execution
- ✅ GPG key verification
- ✅ File integrity checks
- ✅ Proper cleanup handlers
- ✅ Path validation
- ✅ Secure kubeconfig handling

---

## 📝 License

This project is open source and available under the MIT License.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

---

**Made with ❤️ for the Kubernetes community**

Deepseek
