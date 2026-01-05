#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XA-vI v4.0 Extended+ - Container Manager
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey (xyalaxxx90@gmail.com)
# Container & Virtualisierung Manager für Termux
# ==============================================================================

set -euo pipefail

# Farben
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_DIR="$HOME/xtreme_ai_system"
CONTAINER_DIR="$INSTALL_DIR/containers"

# ==============================================================================
# BANNER
# ==============================================================================
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                 📦  CONTAINER MANAGER  📦                        ║
║                                                                  ║
║            XTREME XA-vI Container & VM Manager                   ║
║          © Elektronikx-Center-Matte ® | Cyborg System           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ==============================================================================
# LOGGING
# ==============================================================================
success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${CYAN}ℹ${NC} $1"; }

# ==============================================================================
# PROOT-DISTRO MANAGEMENT
# ==============================================================================
list_available_distros() {
    info "Verfügbare Distributionen:"
    echo ""
    proot-distro list
}

install_distro() {
    local distro=$1
    
    info "Installiere $distro..."
    proot-distro install "$distro"
    
    if [ $? -eq 0 ]; then
        success "$distro installiert"
        
        # Post-Install Setup
        info "Führe Post-Install Setup aus..."
        proot-distro login "$distro" -- bash -c "
            apt-get update && apt-get upgrade -y
            apt-get install -y sudo vim git curl wget
        "
        
        success "Setup abgeschlossen"
    else
        error "Installation fehlgeschlagen"
        return 1
    fi
}

launch_distro() {
    local distro=$1
    
    info "Starte $distro..."
    proot-distro login "$distro"
}

remove_distro() {
    local distro=$1
    
    warn "Lösche $distro..."
    read -p "Sicher? (j/N): " -r
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        proot-distro remove "$distro"
        success "$distro gelöscht"
    fi
}

# ==============================================================================
# DOCKER-STYLE CONTAINER
# ==============================================================================
create_container() {
    local name=$1
    local base_distro=$2
    local container_path="$CONTAINER_DIR/$name"
    
    info "Erstelle Container '$name' basierend auf $base_distro..."
    
    # Installiere Base-Distro falls nötig
    if ! proot-distro list | grep -q "$base_distro (installed)"; then
        install_distro "$base_distro"
    fi
    
    # Container-Verzeichnis
    mkdir -p "$container_path"
    
    # Startup-Script
    cat > "$container_path/start.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login $base_distro --bind $container_path:/workspace
EOF
    
    chmod +x "$container_path/start.sh"
    
    # Container-Info
    cat > "$container_path/info.txt" << EOF
Container: $name
Base: $base_distro
Created: $(date)
Path: $container_path
EOF
    
    success "Container '$name' erstellt"
    echo "Start mit: bash $container_path/start.sh"
}

list_containers() {
    info "Vorhandene Container:"
    echo ""
    
    if [ -d "$CONTAINER_DIR" ]; then
        for container in "$CONTAINER_DIR"/*; do
            if [ -d "$container" ]; then
                local name=$(basename "$container")
                echo -e "${GREEN}▸${NC} $name"
                if [ -f "$container/info.txt" ]; then
                    cat "$container/info.txt" | grep "Base:" | sed 's/^/  /'
                fi
            fi
        done
    else
        warn "Keine Container gefunden"
    fi
}

remove_container() {
    local name=$1
    local container_path="$CONTAINER_DIR/$name"
    
    if [ ! -d "$container_path" ]; then
        error "Container '$name' nicht gefunden"
        return 1
    fi
    
    warn "Lösche Container '$name'..."
    read -p "Sicher? (j/N): " -r
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        rm -rf "$container_path"
        success "Container gelöscht"
    fi
}

# ==============================================================================
# QEMU VM MANAGEMENT
# ==============================================================================
create_vm() {
    local name=$1
    local size=$2
    local vm_path="$CONTAINER_DIR/vms/$name"
    
    mkdir -p "$vm_path"
    
    info "Erstelle VM '$name' mit ${size}GB..."
    
    # Virtuelle Disk erstellen
    qemu-img create -f qcow2 "$vm_path/disk.qcow2" "${size}G"
    
    # VM-Konfiguration
    cat > "$vm_path/config.conf" << EOF
name=$name
disk=$vm_path/disk.qcow2
memory=2048
cpus=2
arch=aarch64
EOF
    
    # Start-Script
    cat > "$vm_path/start.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash
qemu-system-aarch64 \\
    -M virt \\
    -cpu cortex-a72 \\
    -smp 2 \\
    -m 2048 \\
    -drive file=$vm_path/disk.qcow2,if=virtio \\
    -netdev user,id=net0 \\
    -device virtio-net,netdev=net0 \\
    -nographic
EOF
    
    chmod +x "$vm_path/start.sh"
    
    success "VM '$name' erstellt"
    echo "Start mit: bash $vm_path/start.sh"
    echo ""
    info "Hinweis: ISO für Installation benötigt"
}

list_vms() {
    info "Vorhandene VMs:"
    echo ""
    
    local vm_dir="$CONTAINER_DIR/vms"
    if [ -d "$vm_dir" ]; then
        for vm in "$vm_dir"/*; do
            if [ -d "$vm" ]; then
                local name=$(basename "$vm")
                echo -e "${GREEN}▸${NC} $name"
                if [ -f "$vm/config.conf" ]; then
                    cat "$vm/config.conf" | sed 's/^/  /'
                fi
            fi
        done
    else
        warn "Keine VMs gefunden"
    fi
}

# ==============================================================================
# CHROOT ENVIRONMENTS
# ==============================================================================
create_chroot() {
    local name=$1
    local chroot_path="$CONTAINER_DIR/chroots/$name"
    
    info "Erstelle Chroot-Umgebung '$name'..."
    
    mkdir -p "$chroot_path"
    
    # Basis-Verzeichnisse
    mkdir -p "$chroot_path"/{bin,lib,lib64,usr,etc,proc,sys,dev,tmp,home}
    
    # Wichtige Binaries kopieren
    cp -r "$PREFIX/bin" "$chroot_path/usr/"
    cp -r "$PREFIX/lib" "$chroot_path/usr/"
    
    # Mount-Script
    cat > "$chroot_path/mount.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
mount --bind /proc $1/proc
mount --bind /sys $1/sys
mount --bind /dev $1/dev
EOF
    
    chmod +x "$chroot_path/mount.sh"
    
    # Umount-Script
    cat > "$chroot_path/umount.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
umount $1/proc
umount $1/sys
umount $1/dev
EOF
    
    chmod +x "$chroot_path/umount.sh"
    
    success "Chroot-Umgebung erstellt"
}

# ==============================================================================
# SNAPSHOT MANAGEMENT
# ==============================================================================
create_snapshot() {
    local container=$1
    local snapshot_name="${container}_snapshot_$(date +%Y%m%d_%H%M%S)"
    local snapshot_path="$CONTAINER_DIR/snapshots/$snapshot_name.tar.gz"
    
    mkdir -p "$CONTAINER_DIR/snapshots"
    
    info "Erstelle Snapshot von '$container'..."
    
    tar -czf "$snapshot_path" -C "$CONTAINER_DIR" "$container" 2>/dev/null || {
        error "Snapshot-Erstellung fehlgeschlagen"
        return 1
    }
    
    success "Snapshot erstellt: $snapshot_name"
}

restore_snapshot() {
    local snapshot=$1
    local snapshot_path="$CONTAINER_DIR/snapshots/$snapshot"
    
    if [ ! -f "$snapshot_path" ]; then
        error "Snapshot nicht gefunden"
        return 1
    fi
    
    info "Stelle Snapshot wieder her..."
    tar -xzf "$snapshot_path" -C "$CONTAINER_DIR"
    
    success "Snapshot wiederhergestellt"
}

list_snapshots() {
    info "Verfügbare Snapshots:"
    echo ""
    
    local snapshot_dir="$CONTAINER_DIR/snapshots"
    if [ -d "$snapshot_dir" ]; then
        ls -lh "$snapshot_dir"/*.tar.gz 2>/dev/null || warn "Keine Snapshots gefunden"
    else
        warn "Keine Snapshots gefunden"
    fi
}

# ==============================================================================
# HAUPTMENÜ
# ==============================================================================
main_menu() {
    while true; do
        show_banner
        
        echo -e "${WHITE}${BOLD}PRoot Distributionen:${NC}"
        echo "  1) Verfügbare Distros anzeigen"
        echo "  2) Distribution installieren"
        echo "  3) Distribution starten"
        echo "  4) Distribution entfernen"
        echo ""
        echo -e "${WHITE}${BOLD}Container:${NC}"
        echo "  5) Container erstellen"
        echo "  6) Container auflisten"
        echo "  7) Container entfernen"
        echo ""
        echo -e "${WHITE}${BOLD}Virtuelle Maschinen:${NC}"
        echo "  8) VM erstellen"
        echo "  9) VMs auflisten"
        echo ""
        echo -e "${WHITE}${BOLD}Snapshots:${NC}"
        echo " 10) Snapshot erstellen"
        echo " 11) Snapshot wiederherstellen"
        echo " 12) Snapshots auflisten"
        echo ""
        echo "  0) Beenden"
        echo ""
        read -p "Auswahl: " choice
        
        case $choice in
            1) list_available_distros ;;
            2)
                read -p "Distro-Name (ubuntu/debian/arch/alpine): " distro
                install_distro "$distro"
                ;;
            3)
                read -p "Distro-Name: " distro
                launch_distro "$distro"
                ;;
            4)
                read -p "Distro-Name: " distro
                remove_distro "$distro"
                ;;
            5)
                read -p "Container-Name: " name
                read -p "Base-Distro (ubuntu/debian/arch): " base
                create_container "$name" "$base"
                ;;
            6) list_containers ;;
            7)
                read -p "Container-Name: " name
                remove_container "$name"
                ;;
            8)
                read -p "VM-Name: " name
                read -p "Disk-Größe in GB (10): " size
                size=${size:-10}
                create_vm "$name" "$size"
                ;;
            9) list_vms ;;
            10)
                read -p "Container-Name: " name
                create_snapshot "$name"
                ;;
            11)
                list_snapshots
                echo ""
                read -p "Snapshot-Name: " snapshot
                restore_snapshot "$snapshot"
                ;;
            12) list_snapshots ;;
            0) break ;;
            *) error "Ungültige Auswahl" ;;
        esac
        
        echo ""
        read -p "Drücke Enter zum Fortfahren..."
    done
}

# ==============================================================================
# INITIALISIERUNG
# ==============================================================================
init() {
    mkdir -p "$CONTAINER_DIR"/{vms,chroots,snapshots}
    
    # Prüfe proot-distro
    if ! command -v proot-distro &> /dev/null; then
        warn "proot-distro nicht installiert"
        read -p "Jetzt installieren? (j/N): " -r
        if [[ $REPLY =~ ^[Jj]$ ]]; then
            pkg install -y proot-distro
        fi
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================
init
main_menu
