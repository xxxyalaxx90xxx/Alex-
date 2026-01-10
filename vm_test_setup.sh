#!/bin/bash
# VM Test Setup Script - Virtual Machine Environment for Testing
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
VM_NAME="${VM_NAME:-k8s-test-vm}"
VM_MEMORY="${VM_MEMORY:-4096}"
VM_CPUS="${VM_CPUS:-2}"
VM_DISK="${VM_DISK:-20G}"
PLATFORM="${1:-docker}"

echo -e "${BLUE}=== VM Test Environment Setup ===${NC}"
echo "Platform: $PLATFORM"
echo "VM Name: $VM_NAME"
echo "Memory: $VM_MEMORY MB"
echo "CPUs: $VM_CPUS"
echo "Disk: $VM_DISK"
echo

# Check platform
case "$PLATFORM" in
    docker)
        setup_docker_test_env
        ;;
    virtualbox)
        setup_virtualbox_vm
        ;;
    qemu)
        setup_qemu_vm
        ;;
    *)
        echo -e "${RED}Unknown platform: $PLATFORM${NC}"
        echo "Supported: docker, virtualbox, qemu"
        exit 1
        ;;
esac

function setup_docker_test_env() {
    echo -e "${GREEN}Setting up Docker test environment...${NC}"
    
    # Create Dockerfile for testing
    cat > Dockerfile.test <<'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install basic requirements
RUN apt-get update && apt-get install -y \
    curl wget git vim nano \
    sudo systemd systemd-sysv \
    python3 python3-pip \
    nodejs npm \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create test user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/testuser

# Copy all scripts
COPY *.sh /home/testuser/
RUN chown -R testuser:testuser /home/testuser && \
    chmod +x /home/testuser/*.sh

USER testuser

CMD ["/bin/bash"]
EOF

    echo -e "${GREEN}Building Docker test image...${NC}"
    docker build -f Dockerfile.test -t "$VM_NAME:latest" .
    
    echo -e "${GREEN}Starting test container...${NC}"
    docker run -d --name "$VM_NAME" \
        --privileged \
        --memory="${VM_MEMORY}m" \
        --cpus="$VM_CPUS" \
        "$VM_NAME:latest" sleep infinity
    
    echo -e "${GREEN}Test environment ready!${NC}"
    echo "Enter with: docker exec -it $VM_NAME /bin/bash"
    echo "Run tests: docker exec $VM_NAME ./comprehensive_test.sh --no-backups"
}

function setup_virtualbox_vm() {
    echo -e "${GREEN}Setting up VirtualBox VM...${NC}"
    
    if ! command -v VBoxManage &> /dev/null; then
        echo -e "${RED}VirtualBox not installed!${NC}"
        exit 1
    fi
    
    # Create VM
    VBoxManage createvm --name "$VM_NAME" --register --ostype Ubuntu_64
    
    # Configure VM
    VBoxManage modifyvm "$VM_NAME" \
        --memory "$VM_MEMORY" \
        --cpus "$VM_CPUS" \
        --nic1 nat \
        --natpf1 "ssh,tcp,,2222,,22" \
        --natpf1 "http,tcp,,8080,,8080"
    
    # Create disk
    VBoxManage createhd --filename "$HOME/VirtualBox VMs/$VM_NAME/$VM_NAME.vdi" --size "${VM_DISK//G/}000"
    VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
    VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/$VM_NAME/$VM_NAME.vdi"
    
    echo -e "${GREEN}VirtualBox VM created: $VM_NAME${NC}"
    echo "Attach Ubuntu ISO and start: VBoxManage startvm $VM_NAME"
}

function setup_qemu_vm() {
    echo -e "${GREEN}Setting up QEMU VM...${NC}"
    
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        echo -e "${RED}QEMU not installed!${NC}"
        exit 1
    fi
    
    # Create disk image
    qemu-img create -f qcow2 "$VM_NAME.qcow2" "$VM_DISK"
    
    echo -e "${GREEN}QEMU VM disk created: $VM_NAME.qcow2${NC}"
    echo "Start with: qemu-system-x86_64 -m $VM_MEMORY -smp $VM_CPUS -hda $VM_NAME.qcow2 -cdrom ubuntu.iso"
}

# Cleanup function
function cleanup() {
    echo -e "${YELLOW}Cleaning up test environment...${NC}"
    
    case "$PLATFORM" in
        docker)
            docker stop "$VM_NAME" 2>/dev/null || true
            docker rm "$VM_NAME" 2>/dev/null || true
            ;;
        virtualbox)
            VBoxManage controlvm "$VM_NAME" poweroff 2>/dev/null || true
            VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true
            ;;
    esac
    
    echo -e "${GREEN}Cleanup complete${NC}"
}

# Run appropriate setup
case "$PLATFORM" in
    --platform)
        PLATFORM="$2"
        ;&
    docker|virtualbox|qemu)
        setup_${PLATFORM//-/_}_test_env
        ;;
    --cleanup)
        cleanup
        ;;
    *)
        echo "Usage: $0 [docker|virtualbox|qemu|--cleanup]"
        exit 1
        ;;
esac
