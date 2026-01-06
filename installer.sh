#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Fully automated Termux all-in-one setup for dev/VM/AI use-cases.
# Usage: bash installer.sh --auto

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND
export PIP_DISABLE_PIP_VERSION_CHECK=1
export PIP_NO_INPUT=1

AUTO=false
for arg in "$@"; do
  case "${arg}" in
    --auto) AUTO=true ;;
    -h|--help)
      cat <<'EOF'
Usage: bash installer.sh --auto
Performs an unattended install of the Termux dev/VM/AI environment.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      exit 1
      ;;
  esac
done

if [ "${AUTO}" != "true" ]; then
  echo "Run with --auto for unattended install." >&2
  exit 1
fi

LOG_FILE=${LOG_FILE:-"$HOME/.cache/termux-auto-install/install.log"}
mkdir -p "$(dirname "${LOG_FILE}")"
exec > >(tee -a "${LOG_FILE}") 2>&1

PREFIX_EXPECTED="/data/data/com.termux/files/usr"
if [ "${PREFIX:-}" != "${PREFIX_EXPECTED}" ]; then
  echo "Warning: This script is intended for Termux (${PREFIX_EXPECTED}). PREFIX=${PREFIX:-unknown}" >&2
fi

log() {
  printf '%s %s\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*"
}

ISO_DEFAULT="${HOME}/storage/downloads/Win10.iso"

detect_resources() {
  TOTAL_MEM_KB=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
  TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
  CPU_CORES=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)
  STORAGE_MB=$(df -Pm "${HOME}" 2>/dev/null | awk 'NR==2 {print $4}')
  [ -z "${STORAGE_MB}" ] && STORAGE_MB=0
  KERNEL=$(uname -r 2>/dev/null || echo "unknown")
  DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "unknown")
  ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")
}

ensure_pkg_updated() {
  log "[1/6] Updating package metadata"
  pkg update -y
}

install_packages() {
  log "[2/6] Installing base packages"
  
  # Install core packages first
  pkg install -y python python-pip nodejs golang rust openjdk-17 \
    tmux git wget curl jq || {
      log "Error: Failed to install core packages" >&2
      exit 1
    }
  
  # Install optional packages (failures won't stop installation)
  pkg install -y proot-distro qemu-system-x86_64-headless tigervnc unzip || {
    log "Warning: Some optional packages failed to install (proot-distro, qemu, vnc)"
  }
}

configure_shell() {
  log "[3/6] Configuring shell and tmux"
  TMUX_CONF="${HOME}/.tmux.conf"
  if ! grep -q "termux-auto" "${TMUX_CONF}" 2>/dev/null; then
    cat >>"${TMUX_CONF}" <<'EOF'
# termux-auto defaults
set -g mouse on
set -g history-limit 10000
setw -g mode-keys vi
EOF
  fi

  BASHRC="${HOME}/.bashrc"
  if ! grep -q "termux-auto helpers" "${BASHRC}" 2>/dev/null; then
    cat >>"${BASHRC}" <<'EOF'
# termux-auto helpers
alias ai-dashboard='python $HOME/.local/share/termux-auto/ai_dashboard.py'
alias vm-win10='$HOME/.local/share/termux-auto/vm/run_win10.sh'
alias termux-auto-backup='termux-auto-backup'
alias termux-auto-restore='termux-auto-restore'
EOF
  fi
}

setup_ai_dashboard() {
  log "[4/6] Preparing AI dashboard (Flask)"
  python -m pip install --quiet "flask>=2.3,<3" >/dev/null
  DASH_DIR="${HOME}/.local/share/termux-auto"
  mkdir -p "${DASH_DIR}"
  cat >"${DASH_DIR}/ai_dashboard.py" <<'EOF'
#!/data/data/com.termux/files/usr/bin/python
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/")
def health():
    return jsonify(status="ok", message="Termux AI Dashboard ready")

@app.route("/info")
def info():
    return jsonify(
        model="placeholder",
        notes="Connect your AI backends to extend this dashboard."
    )

if __name__ == "__main__":
    port = int(os.environ.get("AI_DASHBOARD_PORT", "5000"))
    app.run(host="127.0.0.1", port=port)
EOF
  chmod +x "${DASH_DIR}/ai_dashboard.py"
}

setup_backup_tools() {
  log "[5/6] Installing backup/restore helpers"
  BIN_DIR="${PREFIX:-$PREFIX_EXPECTED}/bin"
  mkdir -p "${BIN_DIR}"
  cat >"${BIN_DIR}/termux-auto-backup" <<EOF
#!${PREFIX_EXPECTED}/bin/bash
set -euo pipefail
DEST=\${1:-\$HOME/storage/shared/termux-auto-backup.tar.gz}
if [ ! -d "\$(dirname "\${DEST}")" ]; then
  DEST="\${HOME}/.local/share/termux-auto/backups/backup.tar.gz"
fi
mkdir -p "\$(dirname "\${DEST}")"
FILES=()
for file_path in .bashrc .tmux.conf .local/share/termux-auto; do
  [ -e "\${HOME}/\${file_path}" ] && FILES+=("\${file_path}")
done
if [ "\${#FILES[@]}" -eq 0 ]; then
  echo "No files to backup."
  exit 0
fi
tar -czf "\${DEST}" -C "\${HOME}" "\${FILES[@]}"
echo "Backup written to \${DEST}"
EOF
  cat >"${BIN_DIR}/termux-auto-restore" <<EOF
#!${PREFIX_EXPECTED}/bin/bash
set -euo pipefail
SRC=\${1:-\$HOME/storage/shared/termux-auto-backup.tar.gz}
if [ ! -f "\${SRC}" ]; then
  SRC="\${HOME}/.local/share/termux-auto/backups/backup.tar.gz"
fi
if [ ! -f "\${SRC}" ]; then
  echo "Backup not found: \${SRC}" >&2
  exit 1
fi
if tar -tzf "\${SRC}" | grep -E '(^/)|(\.\.)' >/dev/null; then
  echo "Refusing to restore archive with unsafe paths: \${SRC}" >&2
  exit 1
fi
tar -xzf "\${SRC}" -C "\${HOME}" --no-same-owner --no-same-permissions
echo "Restored from \${SRC}"
EOF
  chmod +x "${BIN_DIR}/termux-auto-backup" "${BIN_DIR}/termux-auto-restore"
}

setup_vm_profile() {
  log "[6/6] Preparing Windows 10 VM profile (placeholder)"
  VM_DIR="${HOME}/.local/share/termux-auto/vm"
  mkdir -p "${VM_DIR}"
  ISO_CANDIDATE="${ISO_DEFAULT}"
  if [ "${TOTAL_MEM_MB}" -eq 0 ]; then
    VM_RAM=${VM_RAM:-2048}
  else
    VM_RAM=${VM_RAM:-$((TOTAL_MEM_MB / 3))}
  fi
  [ "${VM_RAM}" -lt 1536 ] && VM_RAM=1536
  VM_CORES=${VM_CORES:-$CPU_CORES}
  [ "${VM_CORES}" -lt 1 ] && VM_CORES=1
  [ "${VM_CORES}" -gt 2 ] && VM_CORES=2
  if [ -f "${ISO_CANDIDATE}" ]; then
    ISO_STATUS="present"
  else
    ISO_STATUS="missing"
  fi
  cat >"${VM_DIR}/run_win10.sh" <<EOF
#!${PREFIX_EXPECTED}/bin/bash
set -euo pipefail
ISO_PATH="${ISO_CANDIDATE}"
DISK_IMG="${VM_DIR}/win10.qcow2"
VM_RAM=${VM_RAM}
VM_CORES=${VM_CORES}

mkdir -p "${VM_DIR}"

if [ ! -f "\${ISO_PATH}" ]; then
  echo "Windows 10 ISO not found at \${ISO_PATH}. Place the ISO there and rerun." >&2
  exit 1
fi

if [ ! -f "\${DISK_IMG}" ]; then
  echo "Creating virtual disk (\${DISK_IMG})..."
  qemu-img create -f qcow2 "\${DISK_IMG}" 25G || {
    echo "Failed to create disk image" >&2
    exit 1
  }
fi

KVM_ARGS=()
if [ -e /dev/kvm ]; then
  KVM_ARGS=(-enable-kvm -cpu host)
  echo "KVM acceleration enabled"
else
  echo "Warning: KVM not available, using software emulation (will be slow)"
fi

echo "Starting VM with \${VM_RAM}MB RAM, \${VM_CORES} cores"
exec qemu-system-x86_64 -m \${VM_RAM} -smp \${VM_CORES} "\${KVM_ARGS[@]}" \
  -drive file="\${DISK_IMG}",if=virtio \
  -cdrom "\${ISO_PATH}" -boot once=d -vnc :1 -nic user,model=virtio,restrict=on
EOF
  chmod +x "${VM_DIR}/run_win10.sh"
  cat >"${VM_DIR}/profile.json" <<EOF
{
  "iso_status": "${ISO_STATUS}",
  "iso_path": "${ISO_CANDIDATE}",
  "disk_image": "${VM_DIR}/win10.qcow2",
  "vnc_display": ":1"
}
EOF
}

write_config() {
  CFG_DIR="${HOME}/.config/termux-auto"
  mkdir -p "${CFG_DIR}"
  cat >"${CFG_DIR}/config.env" <<EOF
TOTAL_MEM_MB=${TOTAL_MEM_MB}
CPU_CORES=${CPU_CORES}
STORAGE_MB=${STORAGE_MB}
KERNEL="${KERNEL}"
DEVICE_MODEL="${DEVICE_MODEL}"
ANDROID_VERSION="${ANDROID_VERSION}"
EOF
}

self_test() {
  missing=()
  for cmd in python node go rustc javac qemu-system-x86_64; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      missing+=("${cmd}")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Warning: missing tools detected: ${missing[*]}" >&2
  fi
}

detect_resources

log "=========================================="
log "Termux Auto-Installer Starting"
log "=========================================="
log "System Resources:"
log "  CPU Cores: ${CPU_CORES}"
log "  RAM: ${TOTAL_MEM_MB} MB"
log "  Free Storage: ${STORAGE_MB} MB"
log "  Android: ${ANDROID_VERSION}"
log "  Kernel: ${KERNEL}"
log "  Device: ${DEVICE_MODEL}"
log "=========================================="

ensure_pkg_updated
install_packages
configure_shell
setup_ai_dashboard
setup_backup_tools
setup_vm_profile
write_config
self_test

log "=========================================="
log "Installation complete. Resources: ${CPU_CORES} cores, ${TOTAL_MEM_MB}MB RAM, ${STORAGE_MB}MB free, Android ${ANDROID_VERSION}, Kernel ${KERNEL}."
log "Dashboard: ai-dashboard (port 5000). VM runner: vm-win10. Backup: termux-auto-backup / termux-auto-restore."
log "=========================================="
