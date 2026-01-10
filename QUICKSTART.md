# Quick Start Guide

This guide will help you get Kubernetes running on your system in minutes.

## 📋 Prerequisites

- Linux system (CentOS/RHEL, Ubuntu/Debian, or compatible)
- Minimum 1GB RAM (2GB+ recommended)
- Root or sudo access
- Internet connection

## 🚀 Installation (3 Steps)

### Step 1: Download

```bash
git clone https://github.com/xxxyalaxx90xxx/Alex-.git
cd Alex-
```

### Step 2: Choose Your Installation Method

#### Option A: Complete System (Recommended)
Best for: Production, enterprise, comprehensive validation

```bash
chmod +x install_k8s_complete.sh
sudo ./install_k8s_complete.sh
```

#### Option B: Optimized System
Best for: Mobile devices (Realme C63), ARM devices, Raspberry Pi

```bash
chmod +x install_k8s_optimized.sh
sudo ./install_k8s_optimized.sh
```

#### Option C: Legacy System
Best for: Quick setup on CentOS/RHEL servers

```bash
chmod +x install_k8s.sh
sudo ./install_k8s.sh
```

### Step 3: Verify Installation

```bash
# Set kubeconfig
export KUBECONFIG=$HOME/.kube/config

# Check cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Run validation tests
chmod +x validate_k8s.sh
./validate_k8s.sh
```

## ✅ Post-Installation

### Run Analysis
```bash
chmod +x analyze_k8s.sh
./analyze_k8s.sh
```

### Create Backup
```bash
chmod +x backup_k8s.sh
./backup_k8s.sh backup
```

## 🎯 Quick Examples

### Deploy a Simple Application

```bash
# Create a deployment
kubectl create deployment nginx --image=nginx

# Expose it as a service
kubectl expose deployment nginx --port=80 --type=NodePort

# Check status
kubectl get deployments
kubectl get services
```

### Access Your Application

```bash
# Get the NodePort
kubectl get service nginx

# Access via: http://<node-ip>:<nodeport>
```

## 🔧 Troubleshooting

### Issue: kubectl not found
```bash
# For K3s, create symlink
sudo ln -s /usr/local/bin/k3s /usr/local/bin/kubectl

# Add to PATH
export PATH=$PATH:/usr/local/bin
```

### Issue: Permission denied
```bash
# Fix kubeconfig permissions
sudo chown $(id -u):$(id -g) $HOME/.kube/config
chmod 600 $HOME/.kube/config
```

### Issue: Pods not starting
```bash
# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes
```

### Issue: Cannot connect to cluster
```bash
# Check kubeconfig
cat $HOME/.kube/config

# For K3s, use correct kubeconfig
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Verify cluster is running
sudo systemctl status kubelet  # for kubeadm
sudo systemctl status k3s      # for K3s
```

## 📚 Next Steps

1. **Deploy workloads**: Start deploying your applications
2. **Set up monitoring**: Install Prometheus/Grafana
3. **Configure ingress**: Set up ingress controller
4. **Enable autoscaling**: Configure HPA
5. **Implement CI/CD**: Integrate with your pipeline

## 🗑️ Uninstall

```bash
chmod +x uninstall_k8s.sh
sudo ./uninstall_k8s.sh
```

## 🆘 Need Help?

- Run validation: `./validate_k8s.sh`
- Check analysis: `./analyze_k8s.sh`
- Review logs: Check log files in your home directory
- Documentation: See `COMPLETE_INSTALLATION_GUIDE.md`

## 🎓 Learning Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## 💡 Tips

1. **For mobile devices**: Always use `INSTALL_MODE=lightweight`
2. **For production**: Use the complete installation system
3. **For CI/CD**: Set `AUTO_INSTALL=1` to skip prompts
4. **Regular backups**: Run `./backup_k8s.sh backup` regularly
5. **Monitor resources**: Use `kubectl top nodes` and `kubectl top pods`

## 🔐 Security Best Practices

1. Keep your kubeconfig file secure (`chmod 600`)
2. Use RBAC for access control
3. Regularly update Kubernetes/K3s
4. Enable network policies
5. Use secrets for sensitive data
6. Regular security audits

## 📊 Performance Tips

### For Realme C63 / Mobile Devices:
- Use K3s (lightweight mode)
- Limit concurrent workloads
- Monitor memory usage
- Use resource limits on pods

### For Standard Servers:
- Use full Kubernetes
- Configure resource quotas
- Enable metrics server
- Use node affinity for workload placement

## ✨ Features At a Glance

| Feature | Complete | Optimized | Legacy |
|---------|----------|-----------|--------|
| Auto-detection | ✅ | ✅ | ❌ |
| Validation | ✅ | ❌ | ❌ |
| Logging | ✅ | ❌ | ❌ |
| Multi-OS | ✅ | ✅ | ❌ |
| Mobile Support | ✅ | ✅ | ❌ |
| Setup Time | 5-10 min | 3-5 min | 2-3 min |

---

**Ready to start?** Choose your installation method above and follow the steps!
