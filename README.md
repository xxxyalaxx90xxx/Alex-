# Alex - Setup K8S by kubeadm

## Fully automated install

Run the provided script to install kubeadm/kubelet/kubectl, enable containerd CRI, initialize the control plane, apply flannel, and optionally configure hugepages without manual edits:

```bash
chmod +x install_k8s.sh
# optionally set ADVERTISE_ADDRESS, POD_CIDR, HUGEPAGES_2MI, KUBECONFIG_FILE
sudo ./install_k8s.sh
```

### Features

The installation script now includes:
- **Comprehensive logging** with timestamps and color-coded output for better tracking
- **Automatic validation** of IP addresses and CIDR ranges
- **Prerequisite checks** to verify system requirements before installation
- **Retry logic** for network operations (configurable via MAX_RETRIES and RETRY_DELAY)
- **Progress indicators** for each installation step
- **Configuration backups** before modifying system files
- **Health checks** at the end to verify cluster status
- **Detailed summary** of configuration and cluster state
- **Error handling** with clear error messages
- **Dry-run mode** to preview changes without making them
- **Post-installation tests** to verify cluster functionality
- **Troubleshooting guidance** for common issues

### Environment Variables

Defaults:
- `ADVERTISE_ADDRESS`: first host IP (from `hostname -I`)
- `POD_CIDR`: `10.244.0.0/16`
- `HUGEPAGES_2MI`: not configured unless set
- `KUBECONFIG_FILE`: `$HOME/.kube/config`
- `MAX_RETRIES`: `3` (for network operations)
- `RETRY_DELAY`: `5` seconds (delay between retries)
- `STARTUP_WAIT_SECONDS`: `5` seconds (wait time for cluster components to start)
- `DRY_RUN`: `false` (set to `true` to preview changes without applying them)
- `SKIP_CHECKS`: `false` (set to `true` to skip prerequisite checks)
- `ENABLE_COLORS`: `auto` (set to `true` or `false` to force enable/disable colored output)

### Examples

**Basic installation:**
```bash
sudo ./install_k8s.sh
```

**Dry-run to preview changes:**
```bash
DRY_RUN=true sudo ./install_k8s.sh
```

**Custom configuration:**
```bash
ADVERTISE_ADDRESS=192.168.1.100 POD_CIDR=10.10.0.0/16 sudo ./install_k8s.sh
```

**With hugepages:**
```bash
HUGEPAGES_2MI=256 sudo ./install_k8s.sh
```

**Skip prerequisite checks:**
```bash
SKIP_CHECKS=true sudo ./install_k8s.sh
```

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

Deepseek
