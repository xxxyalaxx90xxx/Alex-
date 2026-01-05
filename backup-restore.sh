#!/data/data/com.termux/files/usr/bin/bash
#
# Xtreme XA-vI ® Backup & Restore Tool
# Sichere deine Termux-Konfiguration und Daten
# By Alexander Mathey XAi-Cyborg ©®
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

BACKUP_DIR="$HOME/termux-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="termux_backup_${TIMESTAMP}"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔════════════════════════════════════════════════╗
    ║    Xtreme XA-vI ® Backup & Restore Tool        ║
    ║    Termux Configuration Manager                ║
    ╚════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Backup erstellen
create_backup() {
    log_info "Erstelle Backup..."
    
    mkdir -p "$BACKUP_DIR"
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$backup_path"
    
    # Konfigurationsdateien sichern
    log_info "Sichere Konfigurationsdateien..."
    if [ -f "$HOME/.bashrc" ]; then
        cp "$HOME/.bashrc" "$backup_path/bashrc" && log_success "bashrc gesichert"
    fi
    
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$backup_path/zshrc" && log_success "zshrc gesichert"
    fi
    
    if [ -d "$HOME/.termux" ]; then
        cp -r "$HOME/.termux" "$backup_path/termux_config" && log_success "Termux Config gesichert"
    fi
    
    if [ -f "$HOME/.gitconfig" ]; then
        cp "$HOME/.gitconfig" "$backup_path/gitconfig" && log_success "Git Config gesichert"
    fi
    
    # SSH Keys sichern
    if [ -d "$HOME/.ssh" ]; then
        log_info "Sichere SSH Keys..."
        mkdir -p "$backup_path/ssh"
        cp -r "$HOME/.ssh/"* "$backup_path/ssh/" 2>/dev/null && log_success "SSH Keys gesichert"
    fi
    
    # Installierte Pakete liste
    log_info "Erstelle Paketliste..."
    pkg list-installed > "$backup_path/packages.txt" 2>/dev/null && log_success "Paketliste erstellt"
    
    # Python Pakete
    if command -v pip &> /dev/null; then
        pip freeze > "$backup_path/python_packages.txt" 2>/dev/null && log_success "Python-Pakete aufgelistet"
    fi
    
    # Node.js Pakete
    if command -v npm &> /dev/null; then
        npm list -g --depth=0 > "$backup_path/npm_packages.txt" 2>/dev/null && log_success "npm-Pakete aufgelistet"
    fi
    
    # Scripts sichern
    if [ -d "$HOME/bin" ]; then
        cp -r "$HOME/bin" "$backup_path/bin" 2>/dev/null && log_success "User-Scripts gesichert"
    fi
    
    # Projekte-Verzeichnis Liste
    if [ -d "$HOME/projects" ]; then
        log_info "Erstelle Projektliste..."
        ls -la "$HOME/projects" > "$backup_path/projects_list.txt"
        log_success "Projektliste erstellt"
    fi
    
    # Backup komprimieren
    log_info "Komprimiere Backup..."
    cd "$BACKUP_DIR"
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
    rm -rf "$BACKUP_NAME"
    
    local backup_size=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
    log_success "Backup erstellt: ${BACKUP_NAME}.tar.gz (${backup_size})"
    log_info "Speicherort: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    
    echo ""
    log_info "Backup-Inhalt:"
    echo "  - Konfigurationsdateien (.bashrc, .zshrc, etc.)"
    echo "  - Termux-Einstellungen"
    echo "  - SSH Keys"
    echo "  - Paketlisten (pkg, pip, npm)"
    echo "  - User-Scripts"
    echo "  - Projektliste"
}

# Backup wiederherstellen
restore_backup() {
    log_info "Verfügbare Backups:"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR/*.tar.gz 2>/dev/null)" ]; then
        log_error "Keine Backups gefunden in $BACKUP_DIR"
        return 1
    fi
    
    local backups=($(ls -t "$BACKUP_DIR"/*.tar.gz))
    local i=1
    for backup in "${backups[@]}"; do
        local backup_name=$(basename "$backup")
        local backup_date=$(echo "$backup_name" | grep -oP '\d{8}_\d{6}')
        local backup_size=$(du -h "$backup" | cut -f1)
        echo "  $i) $backup_name (${backup_size})"
        i=$((i+1))
    done
    
    echo ""
    read -p "Wähle Backup-Nummer zum Wiederherstellen (oder Enter zum Abbrechen): " choice
    
    if [ -z "$choice" ]; then
        log_info "Wiederherstellung abgebrochen"
        return 0
    fi
    
    if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#backups[@]}" ]; then
        log_error "Ungültige Auswahl"
        return 1
    fi
    
    local selected_backup="${backups[$((choice-1))]}"
    log_info "Stelle wieder her: $(basename $selected_backup)"
    
    # Sicherheitsabfrage
    read -p "Dies überschreibt aktuelle Konfigurationen. Fortfahren? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        log_info "Wiederherstellung abgebrochen"
        return 0
    fi
    
    # Backup entpacken
    local temp_dir="/tmp/termux_restore_$$"
    mkdir -p "$temp_dir"
    tar -xzf "$selected_backup" -C "$temp_dir"
    
    local backup_name=$(basename "$selected_backup" .tar.gz)
    local restore_path="$temp_dir/$backup_name"
    
    # Konfigurationsdateien wiederherstellen
    log_info "Stelle Konfigurationsdateien wieder her..."
    
    if [ -f "$restore_path/bashrc" ]; then
        cp "$restore_path/bashrc" "$HOME/.bashrc" && log_success "bashrc wiederhergestellt"
    fi
    
    if [ -f "$restore_path/zshrc" ]; then
        cp "$restore_path/zshrc" "$HOME/.zshrc" && log_success "zshrc wiederhergestellt"
    fi
    
    if [ -d "$restore_path/termux_config" ]; then
        cp -r "$restore_path/termux_config" "$HOME/.termux" && log_success "Termux Config wiederhergestellt"
    fi
    
    if [ -f "$restore_path/gitconfig" ]; then
        cp "$restore_path/gitconfig" "$HOME/.gitconfig" && log_success "Git Config wiederhergestellt"
    fi
    
    # SSH Keys wiederherstellen
    if [ -d "$restore_path/ssh" ]; then
        log_info "Stelle SSH Keys wieder her..."
        mkdir -p "$HOME/.ssh"
        cp -r "$restore_path/ssh/"* "$HOME/.ssh/" 2>/dev/null
        chmod 700 "$HOME/.ssh"
        chmod 600 "$HOME/.ssh/"* 2>/dev/null
        log_success "SSH Keys wiederhergestellt"
    fi
    
    # Scripts wiederherstellen
    if [ -d "$restore_path/bin" ]; then
        cp -r "$restore_path/bin" "$HOME/bin" 2>/dev/null && log_success "User-Scripts wiederhergestellt"
    fi
    
    # Paketlisten anzeigen
    if [ -f "$restore_path/packages.txt" ]; then
        log_info "Paketliste gefunden - installiere mit:"
        echo "  cat $restore_path/packages.txt | cut -f1 | xargs pkg install"
    fi
    
    # Aufräumen
    rm -rf "$temp_dir"
    
    log_success "Wiederherstellung abgeschlossen!"
    log_warning "Starte Termux neu, um alle Änderungen zu übernehmen"
}

# Backups auflisten
list_backups() {
    log_info "Verfügbare Backups:"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR/*.tar.gz 2>/dev/null)" ]; then
        log_error "Keine Backups gefunden in $BACKUP_DIR"
        return 0
    fi
    
    local backups=($(ls -t "$BACKUP_DIR"/*.tar.gz))
    for backup in "${backups[@]}"; do
        local backup_name=$(basename "$backup")
        local backup_size=$(du -h "$backup" | cut -f1)
        local backup_date=$(stat -c %y "$backup" | cut -d'.' -f1)
        echo -e "${CYAN}Backup:${NC} $backup_name"
        echo -e "  Größe: $backup_size"
        echo -e "  Datum: $backup_date"
        echo ""
    done
    
    log_info "Gesamtanzahl: ${#backups[@]} Backup(s)"
    log_info "Speicherort: $BACKUP_DIR"
}

# Backup löschen
delete_backup() {
    list_backups
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR/*.tar.gz 2>/dev/null)" ]; then
        return 0
    fi
    
    echo ""
    read -p "Backup-Dateiname zum Löschen eingeben (oder Enter zum Abbrechen): " filename
    
    if [ -z "$filename" ]; then
        log_info "Abgebrochen"
        return 0
    fi
    
    local backup_file="$BACKUP_DIR/$filename"
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup nicht gefunden: $filename"
        return 1
    fi
    
    read -p "Wirklich löschen: $filename? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
        rm "$backup_file"
        log_success "Backup gelöscht: $filename"
    else
        log_info "Abgebrochen"
    fi
}

# Automatisches Backup
auto_backup() {
    log_info "Richte automatisches Backup ein..."
    
    # Erstelle Termux:Boot Script
    local boot_dir="$HOME/.termux/boot"
    mkdir -p "$boot_dir"
    
    cat > "$boot_dir/backup.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Auto-Backup beim Boot
~/Alex-/backup-restore.sh create
EOF
    
    chmod +x "$boot_dir/backup.sh"
    
    log_success "Auto-Backup konfiguriert"
    log_info "Backup wird beim Termux-Start erstellt"
    log_warning "Benötigt Termux:Boot App aus Play Store"
}

# Hilfe
show_help() {
    echo "Xtreme XA-vI Backup & Restore Tool"
    echo ""
    echo "Usage: backup-restore.sh [command]"
    echo ""
    echo "Commands:"
    echo "  create      - Erstelle neues Backup"
    echo "  restore     - Stelle Backup wieder her"
    echo "  list        - Liste alle Backups auf"
    echo "  delete      - Lösche ein Backup"
    echo "  auto        - Richte automatisches Backup ein"
    echo "  help        - Zeige diese Hilfe"
    echo ""
    echo "Beispiele:"
    echo "  ./backup-restore.sh create"
    echo "  ./backup-restore.sh restore"
    echo "  ./backup-restore.sh list"
}

# Main
main() {
    case "${1:-create}" in
        create)
            show_banner
            create_backup
            ;;
        restore)
            show_banner
            restore_backup
            ;;
        list)
            show_banner
            list_backups
            ;;
        delete)
            show_banner
            delete_backup
            ;;
        auto)
            show_banner
            auto_backup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unbekannter Befehl: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
