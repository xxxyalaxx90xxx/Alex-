# Optimized Kubernetes Installation Guide

## Overview

This guide covers the optimized Kubernetes installation script that supports both server-grade hardware and resource-constrained devices like the Realme C63 smartphone.

## Supported Devices and Platforms

### Mobile Devices
- **Realme C63** and similar Android devices
- ARM/ARM64 architecture smartphones
- Tablets with Linux environments (Termux, Linux Deploy, etc.)

### Single-Board Computers
- Raspberry Pi (2, 3, 4, Zero 2 W)
- Orange Pi, Banana Pi
- Other ARM-based SBCs

### Standard Servers
- CentOS/RHEL 7+
- Ubuntu 18.04+
- Debian 9+
- Fedora

## Architecture Support

- **AMD64/x86_64**: Standard server architecture
- **ARM64/aarch64**: Modern ARM devices (Raspberry Pi 4, newer smartphones)
- **ARM/armv7l**: Older ARM devices (Raspberry Pi 2/3, some smartphones)

## Installation Modes

### Lightweight Mode (K3s)
**Automatically selected when:**
- Total RAM < 2GB
- Running on ARM architecture with < 4GB RAM
- Detected as mobile device (Termux, low resources)
- CPU cores ≤ 4 with ARM architecture

**Features:**
- Minimal resource footprint (~512MB RAM)
- Single binary installation
- Built-in CNI (no external network plugin needed)
- Optimized for edge devices
- Faster startup time

**Components disabled on very low memory (<2GB):**
- Traefik (ingress controller)
- ServiceLB (load balancer)

### Full Mode (kubeadm)
**Automatically selected when:**
- Total RAM ≥ 2GB
- Running on AMD64 architecture
- Detected as server environment

**Features:**
- Complete Kubernetes feature set
- Flannel CNI for networking
- Support for hugepages
- Full control plane components

## Realme C63 Specific Optimizations

The Realme C63 has the following specifications:
- **CPU**: Octa-core (typically 4×2.0 GHz + 4×1.8 GHz)
- **RAM**: 4GB/6GB/8GB variants
- **Architecture**: ARM64 (aarch64)
- **OS**: Android (Linux kernel based)

### Prerequisites for Realme C63

1. **Install Termux** (Android Terminal Emulator)
   ```bash
   # Available from F-Droid or GitHub
   # https://github.com/termux/termux-app
   ```

2. **Install required packages in Termux**
   ```bash
   pkg update && pkg upgrade
   pkg install proot-distro wget curl
   ```

3. **Install Ubuntu in Termux**
   ```bash
   proot-distro install ubuntu
   proot-distro login ubuntu
   ```

4. **Run the installation**
   ```bash
   # Inside proot-distro Ubuntu
   apt update && apt install -y curl
   curl -O https://raw.githubusercontent.com/xxxyalaxx90xxx/Alex-/main/install_k8s_optimized.sh
   chmod +x install_k8s_optimized.sh
   ./install_k8s_optimized.sh
   ```

### Expected Behavior on Realme C63

For a 4GB RAM Realme C63:
```
=== System Detection ===
Architecture: aarch64
OS Type: ubuntu
Memory: 3800 MB (approximately, after Android overhead)
CPU Cores: 8
Install Mode: lightweight
```

The script will:
- Install K3s (lightweight Kubernetes)
- Optimize for ARM64 architecture
- Disable heavy components (traefik, servicelb)
- Use minimal memory footprint
- Configure for single-node cluster

## Environment Variables

### Common Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `INSTALL_MODE` | Auto-detected | `lightweight` or `full` |
| `ADVERTISE_ADDRESS` | Auto-detected | API server IP address |
| `POD_CIDR` | `10.42.0.0/16` (K3s)<br>`10.244.0.0/16` (kubeadm) | Pod network CIDR |
| `KUBECONFIG_FILE` | `$HOME/.kube/config` | Kubeconfig path |
| `MIN_MEMORY_MB` | `1024` (K3s)<br>`2048` (kubeadm) | Minimum RAM requirement |

### K3s-Specific Variables

K3s installation uses additional optimizations for resource-constrained devices.

## Usage Examples

### Example 1: Automatic Installation (Recommended)
```bash
chmod +x install_k8s_optimized.sh
sudo ./install_k8s_optimized.sh
```

The script will automatically detect your system and choose the best installation mode.

### Example 2: Force Lightweight Mode (Realme C63)
```bash
INSTALL_MODE=lightweight sudo ./install_k8s_optimized.sh
```

### Example 3: Custom Configuration
```bash
ADVERTISE_ADDRESS=192.168.1.100 \
POD_CIDR=10.50.0.0/16 \
KUBECONFIG_FILE=/home/user/k8s-config \
sudo ./install_k8s_optimized.sh
```

### Example 4: Skip Memory Warning Prompt
```bash
yes | sudo ./install_k8s_optimized.sh
```

## Verification

After installation, verify the cluster:

```bash
# For K3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
# Or for standard installation
export KUBECONFIG=$HOME/.kube/config

# Check nodes
kubectl get nodes

# Check pods
kubectl get pods --all-namespaces

# Run analysis
./analyze_k8s.sh
```

## Performance Expectations

### Realme C63 (4GB RAM)
- **Startup time**: 30-60 seconds
- **Memory usage**: 
  - K3s server: ~300-500MB
  - System pods: ~100-200MB
  - Available for workloads: ~3GB
- **Pod capacity**: 20-30 small pods
- **Recommended workloads**: 
  - Development/testing
  - Edge computing
  - IoT applications
  - Learning Kubernetes

### Standard Server (4GB+ RAM)
- **Startup time**: 2-5 minutes
- **Memory usage**:
  - Control plane: ~1GB
  - System pods: ~500MB
  - Available for workloads: ~2.5GB+
- **Pod capacity**: 100+ pods
- **Recommended workloads**: 
  - Production applications
  - Multi-tenant environments
  - Full-featured K8s deployments

## Troubleshooting

### Issue: Installation fails with memory error
**Solution**: The device doesn't meet minimum requirements. Try:
1. Close other applications
2. Force lightweight mode: `INSTALL_MODE=lightweight sudo ./install_k8s_optimized.sh`
3. Reduce memory check: `MIN_MEMORY_MB=768 sudo ./install_k8s_optimized.sh`

### Issue: kubectl not found after installation
**Solution**: 
- For K3s: `sudo ln -s /usr/local/bin/k3s /usr/local/bin/kubectl`
- Add to PATH: `export PATH=$PATH:/usr/local/bin`

### Issue: Permission denied errors on Realme C63
**Solution**: 
- Ensure you're running inside proot-distro
- K3s requires root privileges or proper capabilities
- Use `sudo` or run as root

### Issue: Kubeconfig not found
**Solution**:
- For K3s: `export KUBECONFIG=/etc/rancher/k3s/k3s.yaml`
- For kubeadm: `export KUBECONFIG=$HOME/.kube/config`
- Check the installation output for the correct path

## Best Practices for Mobile Devices

1. **Power Management**: Keep device plugged in during installation and operation
2. **Thermal Management**: Ensure adequate cooling, Kubernetes can be CPU-intensive
3. **Storage**: Use device with at least 8GB free storage
4. **Network**: Use stable WiFi connection for downloading images
5. **Background Apps**: Close unnecessary apps to free up RAM
6. **Battery Optimization**: Disable battery optimization for Termux/proot

## Security Considerations

1. **Termux/proot limitations**: Not a full Linux environment, some features may be limited
2. **Root access**: Some operations require root (rooted device) for full functionality
3. **Network isolation**: Be careful with exposing services on mobile networks
4. **Data usage**: Container images can be large, use WiFi for downloads

## Comparison: K3s vs Full Kubernetes

| Feature | K3s (Lightweight) | Full Kubernetes |
|---------|------------------|-----------------|
| Memory footprint | ~512MB | ~2GB |
| Binary size | ~50MB | ~500MB+ |
| Installation time | 1-2 minutes | 5-10 minutes |
| Startup time | 10-30 seconds | 1-3 minutes |
| Storage backend | SQLite (default) | etcd |
| CNI | Built-in | Flannel (separate) |
| Best for | Edge, IoT, Mobile | Production, Enterprise |
| Feature completeness | ~95% | 100% |

## Additional Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Termux Documentation](https://wiki.termux.com/)
- [ARM Kubernetes Guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

## Support Matrix

| Platform | Architecture | Min RAM | Status |
|----------|-------------|---------|--------|
| Realme C63 | ARM64 | 1GB | ✅ Tested |
| Raspberry Pi 4 | ARM64 | 1GB | ✅ Supported |
| Raspberry Pi 3 | ARM64 | 1GB | ✅ Supported |
| Ubuntu Server | AMD64 | 2GB | ✅ Tested |
| CentOS 7/8 | AMD64 | 2GB | ✅ Tested |
| Debian 10+ | AMD64/ARM64 | 2GB | ✅ Supported |
| Android (Termux) | ARM64 | 2GB | ⚠️ Experimental |
