# Advanced Kubernetes Management Guide

This guide covers advanced usage scenarios, performance optimization, troubleshooting, and best practices for the comprehensive Kubernetes management system.

## Table of Contents

1. [Performance Optimization](#performance-optimization)
2. [Automated Troubleshooting](#automated-troubleshooting)
3. [Production Best Practices](#production-best-practices)
4. [Multi-Environment Setup](#multi-environment-setup)
5. [Advanced CI/CD Integration](#advanced-cicd-integration)
6. [Disaster Recovery](#disaster-recovery)

---

## Performance Optimization

### Device-Specific Optimization

The `optimize_performance.sh` script automatically optimizes your Kubernetes cluster based on device type.

#### Automatic Optimization

```bash
chmod +x optimize_performance.sh
sudo ./optimize_performance.sh
```

The script auto-detects your device type:
- **Mobile** (<2GB RAM, ARM architecture): Realme C63, smartphones
- **SBC** (2-4GB RAM): Raspberry Pi, Orange Pi
- **Workstation** (4-8GB RAM): Development machines
- **Server** (>8GB RAM): Production servers

#### Manual Device Type

```bash
# Optimize for mobile device
DEVICE_TYPE=mobile sudo ./optimize_performance.sh

# Optimize for Raspberry Pi
DEVICE_TYPE=sbc sudo ./optimize_performance.sh

# Optimize for server
DEVICE_TYPE=server sudo ./optimize_performance.sh
```

### Optimization Features

#### For Mobile Devices (Realme C63, etc.)

- **Max pods**: Limited to 20
- **Disabled components**: ServiceLB, Traefik, Local Storage, Metrics Server
- **Memory thresholds**: Aggressive eviction (<100Mi available)
- **Image management**: Frequent garbage collection
- **Network**: Host-gateway backend (lowest overhead)
- **Resource reservations**: Minimal (CPU: 100m, Memory: 256Mi)

#### For Single Board Computers

- **Max pods**: 50
- **Disabled components**: ServiceLB, Traefik
- **Memory thresholds**: Conservative (<200Mi available)
- **Resource reservations**: CPU: 200m, Memory: 512Mi

#### System-Level Optimizations

All device types benefit from:
- **Kernel parameters**: Network stack tuning, memory management
- **File limits**: Increased file handles and processes
- **Docker optimization**: Log rotation, storage driver configuration
- **Swap**: Reduced swappiness (vm.swappiness=1)

### Performance Monitoring

After optimization:

```bash
# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Run validation
./validate_k8s.sh

# Analyze cluster health
./analyze_k8s.sh
```

### Expected Performance

| Device Type | Max Pods | CPU Usage | Memory Usage | Boot Time |
|-------------|----------|-----------|--------------|-----------|
| Mobile | 10-20 | 30-50% | 400-800MB | 30-45s |
| SBC | 20-50 | 40-60% | 800MB-1.5GB | 25-40s |
| Workstation | 50-100 | 30-50% | 1-2GB | 15-30s |
| Server | 100+ | 20-40% | 2-4GB | 10-20s |

---

## Automated Troubleshooting

### Quick Diagnostics

```bash
chmod +x troubleshoot_k8s.sh
./troubleshoot_k8s.sh
```

The script checks:
1. ✓ kubectl availability
2. ✓ Kubeconfig permissions
3. ✓ Cluster connectivity
4. ✓ Node status
5. ✓ Pod health
6. ✓ DNS functionality (CoreDNS)
7. ✓ Disk space
8. ✓ Memory usage

### Auto-Fix Mode

Automatically resolve common issues:

```bash
AUTO_FIX=true sudo ./troubleshoot_k8s.sh
```

**Auto-fixes**:
- Creates kubectl symlink from k3s
- Fixes kubeconfig permissions
- Starts stopped services (K3s, kubelet)
- Restarts failed pods
- Cleans disk space (prunes images)
- Restarts CoreDNS
- Creates missing kubeconfig

### Manual Troubleshooting

#### Issue: Pods Stuck in Pending

```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Common fixes:
# 1. Insufficient resources - scale down or add nodes
# 2. No persistent volume - check storage classes
# 3. Node affinity - check node labels
```

#### Issue: Nodes Not Ready

```bash
# Check node details
kubectl describe node <node-name>

# Check kubelet logs
sudo journalctl -u kubelet -n 100

# Common fixes:
sudo systemctl restart kubelet
sudo systemctl restart k3s
```

#### Issue: DNS Resolution Failures

```bash
# Test DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Fix:
kubectl rollout restart deployment/coredns -n kube-system
```

#### Issue: High Memory Usage

```bash
# Check pod memory
kubectl top pods --all-namespaces --sort-by memory

# Set resource limits
kubectl set resources deployment <name> --limits=memory=512Mi
```

---

## Production Best Practices

### Security Hardening

1. **RBAC Configuration**
   ```bash
   # Disable anonymous access
   # Edit kube-apiserver configuration
   --anonymous-auth=false
   ```

2. **Network Policies**
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: deny-all
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     - Egress
   ```

3. **Pod Security Policies**
   ```yaml
   apiVersion: policy/v1beta1
   kind: PodSecurityPolicy
   metadata:
     name: restricted
   spec:
     privileged: false
     allowPrivilegeEscalation: false
     requiredDropCapabilities:
       - ALL
     runAsUser:
       rule: MustRunAsNonRoot
   ```

### Resource Management

1. **Set Resource Limits**
   ```yaml
   resources:
     requests:
       cpu: 100m
       memory: 128Mi
     limits:
       cpu: 500m
       memory: 512Mi
   ```

2. **Implement Quotas**
   ```yaml
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: compute-quota
   spec:
     hard:
       requests.cpu: "10"
       requests.memory: 10Gi
       limits.cpu: "20"
       limits.memory: 20Gi
   ```

### High Availability

For production clusters:

1. **Multiple Master Nodes** (kubeadm)
2. **etcd Backup Strategy**
3. **Load Balancer** for API server
4. **Node Anti-Affinity** for critical workloads

---

## Multi-Environment Setup

### Development Environment

```bash
# Lightweight K3s installation
INSTALL_MODE=lightweight sudo ./install_k8s_optimized.sh

# Skip monitoring stack
# Fast iteration
```

### Staging Environment

```bash
# Complete installation with validation
sudo ./install_k8s_complete.sh

# Enable monitoring
./setup_monitoring.sh

# Regular validation
./validate_k8s.sh
```

### Production Environment

```bash
# Complete installation with all checks
AUTO_INSTALL=0 sudo ./install_k8s_complete.sh

# Custom Kubernetes version
KUBERNETES_VERSION=1.28 sudo ./install_k8s_complete.sh

# Enable monitoring
./setup_monitoring.sh

# Setup backups
./backup_k8s.sh backup

# Schedule regular backups (cron)
0 2 * * * /path/to/backup_k8s.sh backup
```

---

## Advanced CI/CD Integration

### GitHub Actions Matrix Testing

```yaml
strategy:
  matrix:
    k8s-version: ['1.26', '1.27', '1.28', '1.29']
    os: [ubuntu-20.04, ubuntu-22.04]

steps:
  - name: Install Kubernetes
    run: |
      KUBERNETES_VERSION=${{ matrix.k8s-version }} \
      sudo ./install_k8s_complete.sh
```

### GitLab CI with Validation Gates

```yaml
validate:
  stage: test
  script:
    - ./validate_k8s.sh
  allow_failure: false  # Block pipeline on validation failure

deploy:
  stage: deploy
  dependencies:
    - validate
  only:
    - master
```

### Jenkins Pipeline with Monitoring

```groovy
stage('Post-Deploy Monitoring') {
    steps {
        sh './setup_monitoring.sh'
        sh 'kubectl port-forward -n monitoring svc/grafana 3000:3000 &'
        
        // Run smoke tests
        sh './validate_k8s.sh'
    }
}
```

---

## Disaster Recovery

### Backup Strategy

#### Daily Backups

```bash
# Create daily backup (automated via cron)
0 2 * * * /usr/local/bin/backup_k8s.sh backup

# Rotate backups (keep last 7 days)
find ~/k8s_backups -name "*.tar.gz" -mtime +7 -delete
```

#### Pre-Upgrade Backups

```bash
# Automatic backup before upgrade
BACKUP_BEFORE_UPGRADE=true sudo ./upgrade_k8s.sh
```

### Recovery Procedures

#### Full Cluster Recovery

```bash
# 1. Install Kubernetes
sudo ./install_k8s_complete.sh

# 2. Restore from backup
./backup_k8s.sh restore ~/k8s_backups/k8s_backup_YYYYMMDD_HHMMSS.tar.gz

# 3. Validate restoration
./validate_k8s.sh

# 4. Verify applications
kubectl get pods --all-namespaces
```

#### Partial Recovery

```bash
# Extract specific namespace from backup
tar -xzf backup.tar.gz namespaces/my-namespace/

# Restore specific resources
kubectl apply -f namespaces/my-namespace/deployments/
```

### Testing Recovery

Regularly test your backups:

```bash
# 1. Create test cluster
sudo ./install_k8s_optimized.sh

# 2. Deploy test application
kubectl create deployment test --image=nginx

# 3. Create backup
./backup_k8s.sh backup

# 4. Uninstall
sudo ./uninstall_k8s.sh --force

# 5. Reinstall
sudo ./install_k8s_optimized.sh

# 6. Restore
./backup_k8s.sh restore <backup-file>

# 7. Verify
kubectl get deployment test
```

---

## Performance Tuning Tips

### For Mobile Devices

1. **Minimize pod count** - Run only essential services
2. **Use resource limits** - Prevent memory exhaustion
3. **Disable swap** - Improves performance
4. **Use host network** - For critical pods
5. **Monitor battery** - Track power consumption

### For Production

1. **Enable monitoring** - Prometheus + Grafana
2. **Set up alerts** - Resource thresholds
3. **Use HPA** - Horizontal Pod Autoscaler
4. **Implement PDB** - Pod Disruption Budgets
5. **Regular maintenance** - Updates, backups, cleanup

---

## Monitoring Best Practices

### Metrics to Track

- **Node CPU/Memory** - Resource utilization
- **Pod Restart Count** - Stability indicator
- **Network Traffic** - I/O patterns
- **Disk I/O** - Storage performance
- **API Server Latency** - Cluster responsiveness

### Grafana Dashboards

After installing monitoring stack:

1. Access Grafana (see setup_monitoring.sh output for URL)
2. Login with admin/admin
3. Add Prometheus datasource: http://prometheus:9090
4. Import dashboards:
   - Kubernetes Cluster Monitoring (ID: 7249)
   - Node Exporter Full (ID: 1860)
   - Kubernetes Pod Overview (ID: 6417)

---

## Troubleshooting Decision Tree

```
Issue Detected
    ├─ Pods not starting?
    │   ├─ Check resources: kubectl describe pod
    │   ├─ Check images: kubectl get events
    │   └─ Fix: Scale down or add resources
    │
    ├─ Network issues?
    │   ├─ Check DNS: nslookup kubernetes.default
    │   ├─ Check CNI: kubectl get pods -n kube-system
    │   └─ Fix: Restart CoreDNS or CNI pods
    │
    ├─ Performance slow?
    │   ├─ Check resources: kubectl top nodes/pods
    │   ├─ Check disk: df -h
    │   └─ Fix: Run optimize_performance.sh
    │
    └─ Cluster unreachable?
        ├─ Check service: systemctl status k3s/kubelet
        ├─ Check kubeconfig: cat ~/.kube/config
        └─ Fix: Run troubleshoot_k8s.sh with AUTO_FIX=true
```

---

## Getting Help

1. **Run diagnostics**: `./troubleshoot_k8s.sh`
2. **Check analysis**: `./analyze_k8s.sh`
3. **Review logs**: `sudo journalctl -u k3s -n 100`
4. **Validation tests**: `./validate_k8s.sh`

---

**Last Updated**: January 2026
**Version**: 3.0
