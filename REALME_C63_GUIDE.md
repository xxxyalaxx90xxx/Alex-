# Realme C63 (RMX3939) Complete Setup Guide

Complete guide for running Kubernetes and development environments on Realme C63 mobile devices with full Linux/Windows support through Termux and WSL.

## Table of Contents

1. [Device Specifications](#device-specifications)
2. [Installation Methods](#installation-methods)
3. [Termux Setup](#termux-setup)
4. [Windows WSL Setup](#windows-wsl-setup)
5. [Proot Linux Distribution](#proot-linux-distribution)
6. [Database Installation](#database-installation)
7. [Development Tools](#development-tools)
8. [K3s Kubernetes](#k3s-kubernetes)
9. [Performance Optimization](#performance-optimization)
10. [Troubleshooting](#troubleshooting)

## Device Specifications

### Realme C63 (RMX3939)

| Specification | Details |
|---------------|---------|
| **Chipset** | Unisoc T612 (12nm) |
| **CPU** | Octa-core (2x2.0 GHz Cortex-A75 & 6x1.8 GHz Cortex-A55) |
| **GPU** | Mali-G57 |
| **RAM** | 4GB / 6GB / 8GB variants |
| **Storage** | 64GB / 128GB / 256GB |
| **Architecture** | ARM64 (aarch64) |
| **OS** | Android 14, Realme UI 5.0 |

### Recommended Configuration

- **Minimum RAM**: 4GB (for basic K3s)
- **Recommended RAM**: 6GB+ (for K3s + databases)
- **Free Storage**: 5GB+ for complete setup
- **Android Version**: 9.0+ (for Termux compatibility)

## Installation Methods

### Quick Start (Termux)

```bash
# 1. Install Termux from F-Droid (recommended) or GitHub
# 2. Update packages
pkg update && pkg upgrade

# 3. Download and run Realme C63 setup script
curl -O https://raw.githubusercontent.com/xxxyalaxx90xxx/Alex-/main/setup_realme_c63.sh
chmod +x setup_realme_c63.sh
./setup_realme_c63.sh

# 4. Install with K3s (optional)
./setup_realme_c63.sh --with-k3s
```

### Quick Start (Windows WSL)

```powershell
# 1. Enable WSL2 (PowerShell as Administrator)
wsl --install

# 2. Inside WSL Ubuntu, download setup script
curl -O https://raw.githubusercontent.com/xxxyalaxx90xxx/Alex-/main/setup_windows_wsl.sh
chmod +x setup_windows_wsl.sh

# 3. Run with sudo
sudo ./setup_windows_wsl.sh
```

## Termux Setup

### 1. Install Termux

**Recommended**: Install from [F-Droid](https://f-droid.org/en/packages/com.termux/)
- Better maintained
- Frequent updates
- Compatible with latest Android versions

**Alternative**: [GitHub Releases](https://github.com/termux/termux-app/releases)

### 2. Initial Configuration

```bash
# Update package lists
pkg update

# Upgrade all packages
pkg upgrade -y

# Install essential tools
pkg install -y wget curl git openssh proot-distro

# Setup storage access (grants access to Android filesystem)
termux-setup-storage
```

### 3. Automatic Setup

```bash
# Download setup script
wget https://raw.githubusercontent.com/xxxyalaxx90xxx/Alex-/main/setup_realme_c63.sh

# Make executable
chmod +x setup_realme_c63.sh

# Run complete setup
./setup_realme_c63.sh

# Or customize installation
INSTALL_POSTGRESQL=true \
INSTALL_MYSQL=true \
INSTALL_REDIS=true \
./setup_realme_c63.sh --distro ubuntu
```

## Windows WSL Setup

### 1. Enable WSL2

Open PowerShell as Administrator:

```powershell
# Install WSL2
wsl --install

# List available distributions
wsl --list --online

# Install specific distribution (Ubuntu recommended)
wsl --install -d Ubuntu

# Set WSL2 as default
wsl --set-default-version 2
```

### 2. Configure WSL2

```powershell
# Check WSL version
wsl --list --verbose

# Upgrade distribution to WSL2 if needed
wsl --set-version Ubuntu 2
```

### 3. Run WSL Setup Script

Inside WSL:

```bash
# Download setup script
wget https://raw.githubusercontent.com/xxxyalaxx90xxx/Alex-/main/setup_windows_wsl.sh
chmod +x setup_windows_wsl.sh

# Run with sudo
sudo ./setup_windows_wsl.sh

# Shutdown and restart WSL
exit
```

In PowerShell:

```powershell
wsl --shutdown
wsl
```

## Proot Linux Distribution

Proot allows running full Linux distributions inside Termux without root access.

### 1. Install Proot Distribution

```bash
# Install proot-distro
pkg install proot-distro

# List available distributions
proot-distro list

# Install Ubuntu (recommended for Realme C63)
proot-distro install ubuntu

# Or install Debian
proot-distro install debian
```

### 2. Access Distribution

```bash
# Login to Ubuntu
proot-distro login ubuntu

# Login with root access
proot-distro login ubuntu --user root

# Run single command
proot-distro login ubuntu -- apt update
```

### 3. Setup K3s in Proot

```bash
# Inside proot distribution
proot-distro login ubuntu

# Download installation scripts
cd ~
git clone https://github.com/xxxyalaxx90xxx/Alex-.git
cd Alex-

# Run optimized installation
INSTALL_MODE=lightweight ./install_k8s_optimized.sh
```

## Database Installation

### Supported Databases

| Database | Termux | Proot | Windows WSL | Notes |
|----------|--------|-------|-------------|-------|
| PostgreSQL | ✅ | ✅ | ✅ | Full support |
| MySQL/MariaDB | ✅ | ✅ | ✅ | MariaDB in Termux |
| Redis | ✅ | ✅ | ✅ | In-memory cache |
| MongoDB | ❌ | ✅ | ✅ | Proot/WSL only |
| SQLite | ✅ | ✅ | ✅ | Built-in |

### PostgreSQL Setup

**Termux:**

```bash
# Install PostgreSQL
pkg install postgresql

# Initialize database
mkdir -p $PREFIX/var/lib/postgresql
initdb $PREFIX/var/lib/postgresql

# Start PostgreSQL
pg_ctl -D $PREFIX/var/lib/postgresql start

# Create user and database
createuser myuser
createdb mydb -O myuser

# Connect
psql mydb
```

**Proot/WSL:**

```bash
# Install
apt install postgresql

# Switch to postgres user
su - postgres

# Create user and database
createuser myuser
createdb mydb -O myuser

# Start service
service postgresql start
```

### MariaDB/MySQL Setup

**Termux:**

```bash
# Install MariaDB
pkg install mariadb

# Initialize MySQL
mysql_install_db

# Start MySQL
mysqld_safe &

# Secure installation
mysql_secure_installation

# Connect
mysql -u root -p
```

### Redis Setup

**All Platforms:**

```bash
# Termux
pkg install redis

# Ubuntu/Debian
apt install redis-server

# Start Redis
redis-server --daemonize yes

# Test connection
redis-cli ping
```

## Development Tools

### Programming Languages

```bash
# Python
pkg install python  # Termux
apt install python3 python3-pip  # Ubuntu

# Node.js
pkg install nodejs  # Termux
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install nodejs  # Ubuntu

# Go
pkg install golang  # Termux
apt install golang  # Ubuntu

# Rust
pkg install rust  # Termux
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh  # Ubuntu

# Java
pkg install openjdk-17  # Termux
apt install openjdk-17-jdk  # Ubuntu
```

### Development Tools

```bash
# Git
pkg install git

# Build tools
pkg install clang make cmake

# Text editors
pkg install vim nano emacs

# Network tools
pkg install openssh netcat-openbsd
```

## K3s Kubernetes

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 2GB | 4GB+ |
| Storage | 2GB free | 5GB+ free |
| CPU | 2 cores | 4+ cores |

### Installation

**Proot Linux:**

```bash
# Enter proot
proot-distro login ubuntu

# Clone repository
git clone https://github.com/xxxyalaxx90xxx/Alex-.git
cd Alex-

# Install K3s (lightweight mode)
INSTALL_MODE=lightweight sudo ./install_k8s_optimized.sh

# Or use complete installation
sudo ./install_k8s_complete.sh
```

**Windows WSL:**

```bash
# Use WSL setup script
sudo ./setup_windows_wsl.sh

# Or manual installation
curl -sfL https://get.k3s.io | sh -s - \
    --write-kubeconfig-mode 644 \
    --disable traefik \
    --flannel-backend=host-gw
```

### Verification

```bash
# Check K3s status
systemctl status k3s

# Verify nodes
kubectl get nodes

# Check pods
kubectl get pods --all-namespaces

# Run validation
./validate_k8s.sh
```

## Performance Optimization

### Realme C63 Specific Optimizations

```bash
# Run optimization script
./optimize_performance.sh

# Or manual optimizations:

# 1. Reduce swappiness
echo 10 > /proc/sys/vm/swappiness

# 2. Increase file limits
ulimit -n 65536

# 3. K3s resource limits (in proot)
export K3S_ARGS="--max-pods 20 --kube-api-burst 50"

# 4. Disable unnecessary K3s components
k3s server \
    --disable traefik \
    --disable servicelb \
    --disable metrics-server \
    --flannel-backend=host-gw
```

### Memory Management

```bash
# Monitor memory usage
free -h

# Check process memory
ps aux --sort=-%mem | head -10

# Clear cache (if needed)
sync && echo 3 > /proc/sys/vm/drop_caches
```

### Storage Optimization

```bash
# Clean package cache (Termux)
pkg clean

# Clean package cache (Ubuntu)
apt clean && apt autoclean

# Remove unused packages
pkg autoremove  # Termux
apt autoremove  # Ubuntu

# Find large files
du -sh /* | sort -h
```

## Troubleshooting

### Common Issues

#### 1. Termux Package Installation Fails

```bash
# Mirror issues - switch mirrors
termux-change-repo

# Or update manually
pkg update --force
```

#### 2. Proot Distribution Won't Start

```bash
# Reinstall distribution
proot-distro remove ubuntu
proot-distro install ubuntu

# Check available space
df -h
```

#### 3. K3s Won't Start in Proot

```bash
# Check systemd
systemctl status

# If systemd not available, try direct start
k3s server &

# Check logs
journalctl -u k3s -f
```

#### 4. Out of Memory

```bash
# Close unnecessary apps in Android
# Reduce K3s resource limits
export K3S_ARGS="--max-pods 10"

# Use host-gateway networking (lower overhead)
--flannel-backend=host-gw
```

#### 5. WSL2 Network Issues

```powershell
# In PowerShell (Administrator)
wsl --shutdown

# Restart WSL network
netsh winsock reset
netsh int ip reset
```

### Automated Troubleshooting

```bash
# Run diagnostics
./troubleshoot_k8s.sh

# Auto-fix common issues
sudo ./troubleshoot_k8s.sh --auto-fix
```

### Performance Issues

```bash
# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Analyze cluster
./analyze_k8s.sh

# Optimize
sudo ./optimize_performance.sh
```

## Integration Examples

### Deploy Sample Application

```bash
# Create namespace
kubectl create namespace demo

# Deploy nginx
kubectl create deployment nginx --image=nginx -n demo

# Expose service
kubectl expose deployment nginx --port=80 --type=NodePort -n demo

# Get service URL
kubectl get svc -n demo
```

### Database in Kubernetes

```bash
# Deploy PostgreSQL
kubectl create deployment postgres \
    --image=postgres:14 \
    -n demo \
    --env="POSTGRES_PASSWORD=mypassword"

# Expose service
kubectl expose deployment postgres --port=5432 -n demo
```

### Monitoring Stack

```bash
# Deploy monitoring
./setup_monitoring.sh

# Access Grafana
kubectl get svc -n monitoring
# Note the NodePort and access via http://localhost:<port>
```

## Best Practices

### For Realme C63

1. **Use K3s instead of full Kubernetes** - Lower resource footprint
2. **Limit max pods to 20-30** - Prevents memory exhaustion
3. **Use host-gateway networking** - Lower CPU overhead
4. **Disable unnecessary components** - traefik, servicelb if not needed
5. **Regular cleanup** - Remove unused containers and images
6. **Monitor resources** - Use `kubectl top` regularly

### For Windows WSL

1. **Allocate sufficient memory** - At least 4GB in .wslconfig
2. **Enable systemd** - Required for K3s service management
3. **Use WSL2** - WSL1 doesn't support Kubernetes well
4. **Restart WSL after config changes** - `wsl --shutdown`
5. **Keep Windows updated** - Latest WSL features

### For Termux

1. **Install from F-Droid** - More reliable than Play Store
2. **Grant storage permissions** - `termux-setup-storage`
3. **Use proot for K3s** - Can't run K3s directly in Termux
4. **Keep packages updated** - `pkg upgrade` regularly
5. **Backup important data** - Android may clear Termux data

## Additional Resources

- **Repository**: https://github.com/xxxyalaxx90xxx/Alex-
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Advanced Guide**: [ADVANCED_GUIDE.md](ADVANCED_GUIDE.md)
- **Optimized Installation**: [OPTIMIZED_INSTALLATION_GUIDE.md](OPTIMIZED_INSTALLATION_GUIDE.md)

## Support Matrix

| Feature | Termux | Proot | Windows WSL | Native Linux |
|---------|--------|-------|-------------|--------------|
| K3s | ❌ | ✅ | ✅ | ✅ |
| Full K8s | ❌ | ❌ | ✅ | ✅ |
| Databases | ✅ | ✅ | ✅ | ✅ |
| Dev Tools | ✅ | ✅ | ✅ | ✅ |
| GUI Apps | ❌ | ❌ | ✅ (WSLg) | ✅ |
| systemd | ❌ | ⚠️ | ✅ | ✅ |

✅ Full Support | ⚠️ Limited Support | ❌ Not Supported
