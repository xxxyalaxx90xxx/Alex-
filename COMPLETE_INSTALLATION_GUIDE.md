# Complete Installation System Guide

## Overview

The Complete Installation System (`install_k8s_complete.sh`) is an enterprise-grade Kubernetes installation tool with comprehensive features including preflight checks, professional logging, state management, and extensive OS support.

## Quick Start

```bash
# Simple installation (recommended)
chmod +x install_k8s_complete.sh
sudo ./install_k8s_complete.sh
```

The installer will:
1. Display system information
2. Run preflight checks
3. Auto-select the best installation mode
4. Install Kubernetes or K3s
5. Verify the installation
6. Save installation state

## Features

### 1. Comprehensive Preflight Checks

Before installation, the system validates:
- **Required commands**: curl, awk, grep, sed
- **Network connectivity**: Tests access to K8s repositories
- **Disk space**: Ensures sufficient storage (2-5GB)
- **Memory**: Validates minimum RAM requirements
- **Swap configuration**: Checks for swap status

### 2. Professional Logging

- **Colored output**: Color-coded messages (✓✗⚠ℹ▶)
- **Log files**: Detailed logs saved to `~/k8s_install_YYYYMMDD_HHMMSS.log`
- **Timestamped entries**: Each log entry includes timestamp and level
- **Multiple levels**: ERROR, SUCCESS, WARNING, INFO, PROGRESS

### 3. State Management

- **Installation state**: Saves configuration to `~/.k8s_install_state`
- **Restore capability**: Can reference previous installation settings
- **Audit trail**: Complete record of installation parameters

### 4. Smart Resource Detection

Automatically detects and configures based on:
- **Architecture**: AMD64, ARM64, ARMv7, ARMv6
- **Memory**: Total RAM available
- **CPU cores**: Number of cores
- **OS distribution**: CentOS, RHEL, Ubuntu, Debian, Fedora, openSUSE, Arch, Alpine
- **OS version**: Specific version numbers
- **Device type**: Server, workstation, or mobile device

### 5. Post-Installation Verification

After installation:
- Verifies cluster nodes are accessible
- Checks system pods are running
- Validates kubeconfig file
- Provides summary of installation

## Environment Variables

### Installation Mode
```bash
# Force lightweight (K3s)
INSTALL_MODE=lightweight sudo ./install_k8s_complete.sh

# Force full Kubernetes
INSTALL_MODE=full sudo ./install_k8s_complete.sh
```

### Network Configuration
```bash
# Custom API server address
ADVERTISE_ADDRESS=192.168.1.100 sudo ./install_k8s_complete.sh

# Custom pod network CIDR
POD_CIDR=10.50.0.0/16 sudo ./install_k8s_complete.sh
```

### Version Control
```bash
# Specific Kubernetes version
KUBERNETES_VERSION=1.29 sudo ./install_k8s_complete.sh

# Specific K3s version
K3S_VERSION=v1.28.5+k3s1 sudo ./install_k8s_complete.sh
```

### Logging and Output
```bash
# Custom log file location
LOG_FILE=/var/log/k8s_install.log sudo ./install_k8s_complete.sh

# Disable colored output
NO_COLOR=1 sudo ./install_k8s_complete.sh
```

### Automation
```bash
# Skip preflight checks (not recommended)
SKIP_PREFLIGHT=1 sudo ./install_k8s_complete.sh

# Automated installation (no prompts)
AUTO_INSTALL=1 sudo ./install_k8s_complete.sh

# Combined for CI/CD
AUTO_INSTALL=1 INSTALL_MODE=lightweight sudo ./install_k8s_complete.sh
```

### Memory and Resources
```bash
# Custom minimum memory requirement (MB)
MIN_MEMORY_MB=1536 sudo ./install_k8s_complete.sh

# Configure hugepages (full mode only)
HUGEPAGES_2MI=256 sudo ./install_k8s_complete.sh
```

### Kubeconfig
```bash
# Custom kubeconfig location
KUBECONFIG_FILE=/opt/k8s/config sudo ./install_k8s_complete.sh
```

## Supported Operating Systems

### Red Hat Family
- **CentOS** 7, 8, 9
- **RHEL** 7, 8, 9
- **Fedora** 35+
- **Rocky Linux** 8, 9
- **AlmaLinux** 8, 9

Package Manager: yum/dnf

### Debian Family
- **Ubuntu** 18.04 (Bionic), 20.04 (Focal), 22.04 (Jammy), 24.04 (Noble)
- **Debian** 9 (Stretch), 10 (Buster), 11 (Bullseye), 12 (Bookworm)

Package Manager: apt

### SUSE Family
- **openSUSE Leap** 15.x
- **openSUSE Tumbleweed**
- **SLES** 15

Package Manager: zypper

### Other Distributions
- **Arch Linux** (Rolling release)
- **Alpine Linux** 3.x (Experimental)

Package Managers: pacman, apk

## Installation Modes

### Lightweight Mode (K3s)

**Auto-selected when:**
- Total RAM < 2GB
- Mobile device detected (Termux, ARM with low resources)
- User forces with `INSTALL_MODE=lightweight`

**Features:**
- Single binary installation
- Minimal footprint (~512MB RAM)
- Fast startup (10-30 seconds)
- Built-in CNI
- SQLite backend (default)
- No external dependencies

**Components disabled on very low memory (<2GB):**
- Traefik (ingress controller)
- ServiceLB (load balancer)

### Full Mode (kubeadm)

**Auto-selected when:**
- Total RAM ≥ 2GB
- AMD64 architecture
- User forces with `INSTALL_MODE=full`

**Features:**
- Complete Kubernetes feature set
- Etcd backend
- Flannel CNI
- Hugepages support
- Full control plane components
- Production-ready

## Installation Process

### Phase 1: System Detection
1. Detect architecture (AMD64, ARM64, ARM)
2. Detect OS and version
3. Check available memory
4. Count CPU cores
5. Check disk space
6. Determine if mobile device
7. Auto-select installation mode

### Phase 2: Preflight Checks
1. Verify required commands
2. Test network connectivity
3. Validate disk space
4. Confirm memory requirements
5. Check swap configuration

### Phase 3: Installation

#### For K3s (Lightweight):
1. Download K3s installer
2. Verify downloaded file
3. Execute installation with optimizations
4. Configure kubectl access
5. Wait for cluster ready

#### For kubeadm (Full):
1. Configure package repository
2. Install Kubernetes packages
3. Setup container runtime (containerd)
4. Configure hugepages (if requested)
5. Initialize control plane
6. Deploy CNI (Flannel)
7. Configure kubectl access

### Phase 4: Verification
1. Check kubeconfig file exists
2. Verify cluster nodes accessible
3. List system pods
4. Display status summary

### Phase 5: Finalization
1. Save installation state
2. Display success message
3. Provide next steps
4. Show log file location

## Output Examples

### System Information Display
```
╔════════════════════════════════════════╗
║     Kubernetes Installation System     ║
╠════════════════════════════════════════╣
║ Architecture:    arm64
║ OS:              ubuntu 22.04
║ Memory:          3800 MB
║ CPU Cores:       8
║ Disk Space:      15360 MB
║ Install Mode:    lightweight
╚════════════════════════════════════════╝
```

### Colored Log Messages
- ✓ SUCCESS: Green checkmark for successful operations
- ✗ ERROR: Red X for failures
- ⚠ WARNING: Yellow warning symbol
- ℹ INFO: Cyan information symbol
- ▶ PROGRESS: Blue arrow for ongoing operations

### Installation State File
Located at `~/.k8s_install_state`:
```
INSTALL_DATE=2026-01-05T20:15:00+00:00
INSTALL_MODE=lightweight
ARCH=arm64
OS_TYPE=ubuntu
OS_VERSION=22.04
ADVERTISE_ADDRESS=192.168.1.100
POD_CIDR=10.42.0.0/16
KUBECONFIG_FILE=/home/user/.kube/config
LOG_FILE=/home/user/k8s_install_20260105_201500.log
```

## Troubleshooting

### Issue: Preflight check fails
**Solution**: Review the specific check that failed:
- Network: Verify internet connectivity
- Disk: Free up space
- Memory: Close applications or add RAM
- Commands: Install missing utilities

Skip checks only if you understand the risks:
```bash
SKIP_PREFLIGHT=1 sudo ./install_k8s_complete.sh
```

### Issue: Installation hangs at "Waiting for K3s to be ready"
**Solution**: 
1. Check logs: `tail -f ~/k8s_install_*.log`
2. Verify K3s service: `sudo systemctl status k3s`
3. Check system resources: `free -h`, `df -h`

### Issue: Package manager not recognized
**Solution**: The script supports yum, dnf, apt, zypper, pacman, apk. If your OS uses a different package manager, you may need to install packages manually.

### Issue: Colors not displaying correctly
**Solution**: Disable colors:
```bash
NO_COLOR=1 sudo ./install_k8s_complete.sh
```

### Issue: Need to reinstall
**Solution**: First uninstall:
```bash
sudo ./uninstall_k8s.sh
```
Then reinstall.

## Uninstallation

### Interactive Uninstall
```bash
sudo ./uninstall_k8s.sh
```
This will:
1. Detect installation type (K3s or kubeadm)
2. Prompt for confirmation
3. Remove all components
4. Clean up files and configurations

### Force Uninstall (No Prompts)
```bash
sudo ./uninstall_k8s.sh --force
```

### What Gets Removed
- Kubernetes/K3s binaries
- Configuration files (/etc/kubernetes, /etc/rancher)
- Data directories (/var/lib/kubelet, /var/lib/rancher)
- Kubeconfig files (~/.kube)
- Package repositories
- Installation state files
- CNI network interfaces
- iptables rules

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Install Kubernetes
  run: |
    chmod +x install_k8s_complete.sh
    AUTO_INSTALL=1 INSTALL_MODE=lightweight sudo ./install_k8s_complete.sh
    
- name: Verify Installation
  run: |
    export KUBECONFIG=$HOME/.kube/config
    kubectl get nodes
    kubectl get pods --all-namespaces
```

### GitLab CI Example
```yaml
install_k8s:
  script:
    - chmod +x install_k8s_complete.sh
    - AUTO_INSTALL=1 sudo ./install_k8s_complete.sh
    - export KUBECONFIG=$HOME/.kube/config
    - kubectl get nodes
```

### Jenkins Pipeline Example
```groovy
stage('Install Kubernetes') {
    steps {
        sh '''
            chmod +x install_k8s_complete.sh
            AUTO_INSTALL=1 INSTALL_MODE=lightweight sudo ./install_k8s_complete.sh
        '''
    }
}
```

## Performance Expectations

### Realme C63 (4GB RAM, ARM64)
- **Installation time**: 3-5 minutes (K3s)
- **Memory usage**: ~700MB (system + K3s)
- **Startup time**: 30-60 seconds
- **Recommended workloads**: Development, testing, edge computing

### Raspberry Pi 4 (4GB RAM, ARM64)
- **Installation time**: 3-5 minutes (K3s)
- **Memory usage**: ~800MB (system + K3s)
- **Startup time**: 30-45 seconds
- **Recommended workloads**: IoT, home automation, learning

### Standard Server (8GB RAM, AMD64)
- **Installation time**: 5-10 minutes (full K8s)
- **Memory usage**: ~1.5GB (system + control plane)
- **Startup time**: 2-3 minutes
- **Recommended workloads**: Production, multi-tenant

## Security Considerations

1. **No pipe-to-shell**: All external scripts downloaded to files first
2. **GPG verification**: Package repositories verified with GPG keys
3. **File integrity**: Downloaded files checked for existence and size
4. **Least privilege**: Uses sudo only when necessary
5. **Clean tempfiles**: Proper cleanup with trap handlers
6. **Path validation**: Kubeconfig paths validated before writing

## Best Practices

1. **Review logs**: Always check log files after installation
2. **Save state**: Keep `~/.k8s_install_state` for reference
3. **Verify installation**: Run analysis script after install
4. **Resource monitoring**: Monitor system resources post-installation
5. **Regular updates**: Keep Kubernetes/K3s updated
6. **Backup kubeconfig**: Save kubeconfig file securely

## Comparison with Other Scripts

| Aspect | Complete | Optimized | Legacy |
|--------|----------|-----------|--------|
| Complexity | High | Medium | Low |
| Features | Most | Medium | Basic |
| Validation | Extensive | Basic | None |
| Logging | Professional | Basic | None |
| OS Support | 8+ distros | 3 distros | 1 family |
| Use Case | Production | Mobile/ARM | Quick setup |

## Additional Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Analysis Script Guide](ANALYSIS_EXAMPLE.md)
- [Optimized Installation Guide](OPTIMIZED_INSTALLATION_GUIDE.md)

## Support Matrix

| Platform | Architecture | Min RAM | Status |
|----------|-------------|---------|--------|
| Realme C63 | ARM64 | 1GB | ✅ Tested |
| Raspberry Pi 4 | ARM64 | 1GB | ✅ Tested |
| Raspberry Pi 3 | ARM64 | 1GB | ✅ Tested |
| Ubuntu Server 22.04 | AMD64 | 2GB | ✅ Tested |
| CentOS 8 | AMD64 | 2GB | ✅ Tested |
| Debian 11 | AMD64 | 2GB | ✅ Tested |
| Fedora 38 | AMD64 | 2GB | ✅ Tested |
| openSUSE Leap | AMD64 | 2GB | ✅ Supported |
| Arch Linux | AMD64 | 2GB | ✅ Supported |
| Alpine Linux | AMD64/ARM | 1GB | ⚠️ Experimental |
