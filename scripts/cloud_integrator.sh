#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XA-vI v4.0 Extended+ - Cloud Integration Manager
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey (xyalaxxx90@gmail.com)
# Cloud Storage & Remote Server Integration für Termux
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
CLOUD_DIR="$INSTALL_DIR/cloud"
CONFIG_FILE="$CLOUD_DIR/cloud_config.conf"

# ==============================================================================
# BANNER
# ==============================================================================
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                   ☁️  CLOUD INTEGRATOR ☁️                        ║
║                                                                  ║
║              XTREME XA-vI Cloud Storage Manager                  ║
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
# RCLONE SETUP
# ==============================================================================
install_rclone() {
    info "Installiere rclone..."
    
    if command -v rclone &> /dev/null; then
        success "rclone bereits installiert"
        return 0
    fi
    
    # Download rclone
    cd /tmp
    curl -O https://downloads.rclone.org/rclone-current-linux-arm64.zip || {
        error "Download fehlgeschlagen"
        return 1
    }
    
    unzip -q rclone-current-linux-arm64.zip
    cp rclone-*/rclone "$PREFIX/bin/"
    chmod +x "$PREFIX/bin/rclone"
    rm -rf rclone-*
    
    success "rclone installiert"
}

# ==============================================================================
# CLOUD PROVIDER KONFIGURATION
# ==============================================================================
configure_gdrive() {
    info "Google Drive Konfiguration..."
    echo ""
    echo "1. Browser öffnet sich automatisch"
    echo "2. Mit Google-Konto anmelden"
    echo "3. Zugriff erlauben"
    echo "4. Bestätigungscode kopieren"
    echo ""
    read -p "Fortfahren? (j/N): " -r
    if [[ ! $REPLY =~ ^[Jj]$ ]]; then
        return 1
    fi
    
    rclone config create gdrive drive scope=drive
    success "Google Drive konfiguriert"
}

configure_dropbox() {
    info "Dropbox Konfiguration..."
    echo ""
    echo "1. Browser öffnet sich automatisch"
    echo "2. Mit Dropbox-Konto anmelden"
    echo "3. Zugriff erlauben"
    echo ""
    read -p "Fortfahren? (j/N): " -r
    if [[ ! $REPLY =~ ^[Jj]$ ]]; then
        return 1
    fi
    
    rclone config create dropbox dropbox
    success "Dropbox konfiguriert"
}

configure_onedrive() {
    info "OneDrive Konfiguration..."
    echo ""
    echo "1. Browser öffnet sich automatisch"
    echo "2. Mit Microsoft-Konto anmelden"
    echo "3. Zugriff erlauben"
    echo ""
    read -p "Fortfahren? (j/N): " -r
    if [[ ! $REPLY =~ ^[Jj]$ ]]; then
        return 1
    fi
    
    rclone config create onedrive onedrive
    success "OneDrive konfiguriert"
}

configure_mega() {
    info "MEGA Konfiguration..."
    echo ""
    read -p "MEGA Email: " mega_email
    read -sp "MEGA Passwort: " mega_pass
    echo ""
    
    rclone config create mega mega user="$mega_email" pass="$(rclone obscure "$mega_pass")"
    success "MEGA konfiguriert"
}

configure_ssh() {
    info "SSH/SFTP Server Konfiguration..."
    echo ""
    read -p "Server Host: " ssh_host
    read -p "Username: " ssh_user
    read -p "Port (22): " ssh_port
    ssh_port=${ssh_port:-22}
    
    rclone config create ssh_server sftp host="$ssh_host" user="$ssh_user" port="$ssh_port"
    success "SSH Server konfiguriert"
}

# ==============================================================================
# SYNC FUNKTIONEN
# ==============================================================================
sync_upload() {
    local remote=$1
    local local_path=$2
    local remote_path=$3
    
    info "Uploade zu $remote..."
    rclone sync "$local_path" "$remote:$remote_path" \
        --progress \
        --transfers 4 \
        --checkers 8 \
        --contimeout 60s \
        --timeout 300s \
        --retries 3
    
    if [ $? -eq 0 ]; then
        success "Upload abgeschlossen"
    else
        error "Upload fehlgeschlagen"
        return 1
    fi
}

sync_download() {
    local remote=$1
    local remote_path=$2
    local local_path=$3
    
    info "Downloade von $remote..."
    rclone sync "$remote:$remote_path" "$local_path" \
        --progress \
        --transfers 4 \
        --checkers 8 \
        --contimeout 60s \
        --timeout 300s \
        --retries 3
    
    if [ $? -eq 0 ]; then
        success "Download abgeschlossen"
    else
        error "Download fehlgeschlagen"
        return 1
    fi
}

sync_bidirectional() {
    local remote=$1
    local local_path=$2
    local remote_path=$3
    
    info "Bidirektionale Synchronisation..."
    rclone sync "$local_path" "$remote:$remote_path" --progress
    rclone sync "$remote:$remote_path" "$local_path" --progress
    
    success "Synchronisation abgeschlossen"
}

# ==============================================================================
# BACKUP FUNKTIONEN
# ==============================================================================
cloud_backup() {
    local remote=$1
    
    info "Erstelle Cloud-Backup..."
    
    # Backup erstellen
    local backup_name="xtreme_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_path="/tmp/$backup_name"
    
    tar -czf "$backup_path" -C "$HOME" "xtreme_ai_system" 2>/dev/null || {
        error "Backup-Erstellung fehlgeschlagen"
        return 1
    }
    
    # Upload
    rclone copy "$backup_path" "$remote:XAI_Backups/" --progress
    
    # Cleanup
    rm -f "$backup_path"
    
    success "Cloud-Backup erstellt: $backup_name"
}

cloud_restore() {
    local remote=$1
    
    info "Liste verfügbare Backups..."
    echo ""
    
    rclone ls "$remote:XAI_Backups/" | grep ".tar.gz" || {
        error "Keine Backups gefunden"
        return 1
    }
    
    echo ""
    read -p "Backup-Name zum Wiederherstellen: " backup_name
    
    # Download
    rclone copy "$remote:XAI_Backups/$backup_name" /tmp/ --progress
    
    # Restore
    info "Stelle Backup wieder her..."
    tar -xzf "/tmp/$backup_name" -C "$HOME"
    
    rm -f "/tmp/$backup_name"
    success "Backup wiederhergestellt"
}

# ==============================================================================
# AUTO-SYNC
# ==============================================================================
setup_autosync() {
    local remote=$1
    local interval=$2
    
    info "Richte Auto-Sync ein..."
    
    # Cron-Job erstellen
    local cron_script="$CLOUD_DIR/autosync.sh"
    
    cat > "$cron_script" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# Auto-Sync Script
rclone sync "$INSTALL_DIR/projects" "$remote:XAI_Projects/" --quiet
rclone sync "$INSTALL_DIR/data" "$remote:XAI_Data/" --quiet
EOF
    
    chmod +x "$cron_script"
    
    # Termux:boot Setup-Anleitung
    echo ""
    info "Für Auto-Sync bei Start:"
    echo "1. pkg install termux-services"
    echo "2. sv-enable crond"
    echo "3. crontab -e"
    echo "4. Füge hinzu: */$interval * * * * $cron_script"
    
    success "Auto-Sync konfiguriert"
}

# ==============================================================================
# MOUNT FUNKTIONEN
# ==============================================================================
mount_cloud() {
    local remote=$1
    local mount_point="$CLOUD_DIR/mounts/$remote"
    
    mkdir -p "$mount_point"
    
    info "Mounte $remote..."
    rclone mount "$remote:" "$mount_point" \
        --daemon \
        --vfs-cache-mode writes \
        --allow-other \
        --dir-cache-time 72h
    
    success "Cloud gemountet: $mount_point"
}

unmount_cloud() {
    local remote=$1
    local mount_point="$CLOUD_DIR/mounts/$remote"
    
    if mountpoint -q "$mount_point" 2>/dev/null; then
        fusermount -u "$mount_point"
        success "Cloud unmounted"
    else
        warn "Cloud nicht gemountet"
    fi
}

# ==============================================================================
# HAUPTMENÜ
# ==============================================================================
main_menu() {
    while true; do
        show_banner
        
        echo -e "${WHITE}${BOLD}Cloud-Provider:${NC}"
        echo "  1) Google Drive"
        echo "  2) Dropbox"
        echo "  3) OneDrive"
        echo "  4) MEGA"
        echo "  5) SSH/SFTP Server"
        echo ""
        echo -e "${WHITE}${BOLD}Funktionen:${NC}"
        echo "  6) Datei/Ordner hochladen"
        echo "  7) Datei/Ordner herunterladen"
        echo "  8) Synchronisieren (bidirektional)"
        echo "  9) Cloud-Backup erstellen"
        echo " 10) Cloud-Backup wiederherstellen"
        echo " 11) Auto-Sync einrichten"
        echo " 12) Cloud mounten"
        echo " 13) Cloud unmounten"
        echo ""
        echo " 14) Konfiguration anzeigen"
        echo "  0) Beenden"
        echo ""
        read -p "Auswahl: " choice
        
        case $choice in
            1) configure_gdrive ;;
            2) configure_dropbox ;;
            3) configure_onedrive ;;
            4) configure_mega ;;
            5) configure_ssh ;;
            6)
                read -p "Lokaler Pfad: " local_path
                read -p "Remote Name (gdrive/dropbox/...): " remote
                read -p "Remote Pfad: " remote_path
                sync_upload "$remote" "$local_path" "$remote_path"
                ;;
            7)
                read -p "Remote Name: " remote
                read -p "Remote Pfad: " remote_path
                read -p "Lokaler Pfad: " local_path
                sync_download "$remote" "$remote_path" "$local_path"
                ;;
            8)
                read -p "Remote Name: " remote
                read -p "Lokaler Pfad: " local_path
                read -p "Remote Pfad: " remote_path
                sync_bidirectional "$remote" "$local_path" "$remote_path"
                ;;
            9)
                read -p "Remote Name: " remote
                cloud_backup "$remote"
                ;;
            10)
                read -p "Remote Name: " remote
                cloud_restore "$remote"
                ;;
            11)
                read -p "Remote Name: " remote
                read -p "Intervall in Minuten (60): " interval
                interval=${interval:-60}
                setup_autosync "$remote" "$interval"
                ;;
            12)
                read -p "Remote Name: " remote
                mount_cloud "$remote"
                ;;
            13)
                read -p "Remote Name: " remote
                unmount_cloud "$remote"
                ;;
            14)
                rclone config show
                ;;
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
    mkdir -p "$CLOUD_DIR/mounts"
    
    if ! command -v rclone &> /dev/null; then
        install_rclone || exit 1
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================
init
main_menu
