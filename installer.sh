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

detect_resources() {
  TOTAL_MEM_KB=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
  TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
  CPU_CORES=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)
  STORAGE_MB=$(df -Pm "${HOME}" 2>/dev/null | awk 'NR==2 {print $4}')
  KERNEL=$(uname -r 2>/dev/null || echo "unknown")
  DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "unknown")
  ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")
}

ensure_pkg_updated() {
  log "[1/6] Updating package metadata"
  pkg update -y >/dev/null
}

install_packages() {
  log "[2/6] Installing base packages"
  pkg install -y python python-pip nodejs golang rust openjdk-17 tmux git wget curl jq proot-distro qemu-system-x86_64-headless tigervnc unzip >/dev/null
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
  if ! grep -q "termux_auto_dashboard" "${BASHRC}" 2>/dev/null; then
    cat >>"${BASHRC}" <<'EOF'
# termux-auto helpers
alias ai-dashboard='python $HOME/.local/share/termux-auto/ai_dashboard.py'
alias vm-win10='$HOME/.local/share/termux-auto/run_win10.sh'
alias termux-auto-backup='termux-auto-backup'
alias termux-auto-restore='termux-auto-restore'
EOF
  fi
}

setup_ai_dashboard() {
  log "[4/6] Preparing AI dashboard (Flask)"
  python -m pip install --quiet "flask>=2.3,<4" >/dev/null
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
    app.run(host="0.0.0.0", port=port)
EOF
  chmod +x "${DASH_DIR}/ai_dashboard.py"
}

setup_backup_tools() {
  log "[5/6] Installing backup/restore helpers"
  BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"
  mkdir -p "${BIN_DIR}"
  cat >"${BIN_DIR}/termux-auto-backup" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
DEST=${1:-$HOME/storage/shared/termux-auto-backup.tar.gz}
mkdir -p "$(dirname "${DEST}")"
tar -czf "${DEST}" -C "${HOME}" .bashrc .tmux.conf .local/share/termux-auto 2>/dev/null
echo "Backup written to ${DEST}"
EOF
  cat >"${BIN_DIR}/termux-auto-restore" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
SRC=${1:-$HOME/storage/shared/termux-auto-backup.tar.gz}
if [ ! -f "${SRC}" ]; then
  echo "Backup not found: ${SRC}" >&2
  exit 1
fi
tar -xzf "${SRC}" -C "${HOME}"
echo "Restored from ${SRC}"
EOF
  chmod +x "${BIN_DIR}/termux-auto-backup" "${BIN_DIR}/termux-auto-restore"
}

setup_vm_profile() {
  log "[6/6] Preparing Windows 10 VM profile (placeholder)"
  VM_DIR="${HOME}/.local/share/termux-auto/vm"
  mkdir -p "${VM_DIR}"
  ISO_CANDIDATE="${HOME}/storage/downloads/Win10.iso"
  if [ -f "${ISO_CANDIDATE}" ]; then
    ISO_STATUS="present"
  else
    ISO_STATUS="missing"
  fi
  cat >"${VM_DIR}/run_win10.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ISO_PATH="${HOME}/storage/downloads/Win10.iso"
DISK_IMG="${HOME}/.local/share/termux-auto/vm/win10.qcow2"
mkdir -p "$(dirname "${DISK_IMG}")"
if [ ! -f "${ISO_PATH}" ]; then
  echo "Windows 10 ISO not found at ${ISO_PATH}. Place the ISO there and rerun." >&2
  exit 1
fi
if [ ! -f "${DISK_IMG}" ]; then
  qemu-img create -f qcow2 "${DISK_IMG}" 25G
fi
exec qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -cpu host \
  -drive file="${DISK_IMG}",if=virtio \
  -cdrom "${ISO_PATH}" -boot once=d -vnc :1 -net nic -net user
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
ensure_pkg_updated
install_packages
configure_shell
setup_ai_dashboard
setup_backup_tools
setup_vm_profile
write_config
self_test

log "Installation complete. Resources: ${CPU_CORES} cores, ${TOTAL_MEM_MB}MB RAM, ${STORAGE_MB}MB free, Android ${ANDROID_VERSION}, Kernel ${KERNEL}."
log "Dashboard: ai-dashboard (port 5000). VM runner: vm-win10. Backup: termux-auto-backup / termux-auto-restore."
