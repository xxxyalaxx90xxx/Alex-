#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XA-vI v4.0 Pro - Plugin System
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey (xyalaxxx90@gmail.com)
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
PLUGIN_DIR="$INSTALL_DIR/plugins"
LOG_FILE="$INSTALL_DIR/logs/plugins_$(date +%Y%m%d).log"

# ==============================================================================
# BANNER
# ==============================================================================
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║              🔌  PLUGIN SYSTEM v4.0 Pro                         ║
║                                                                  ║
║         Erweiterbar | Modular | Anpassbar | Flexibel           ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║  © Elektronikx-Center-Matte ®                                   ║
║  Cyborg System by Alexander Mathey                              ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ==============================================================================
# LOGGING
# ==============================================================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# ==============================================================================
# PLUGIN STRUCTURE
# ==============================================================================
init_plugin_system() {
    mkdir -p "$PLUGIN_DIR"/{enabled,disabled,templates}
    
    # Plugin Manifest Template
    cat > "$PLUGIN_DIR/templates/manifest.json" << 'MANIFEST'
{
  "name": "Plugin Name",
  "version": "1.0.0",
  "description": "Plugin Description",
  "author": "Your Name",
  "category": "utility",
  "dependencies": [],
  "entry_point": "main.sh",
  "config": {
    "option1": "value1"
  }
}
MANIFEST
    
    # Plugin Script Template
    cat > "$PLUGIN_DIR/templates/main.sh" << 'TEMPLATE'
#!/data/data/com.termux/files/usr/bin/bash
# Plugin Main Script

PLUGIN_NAME="MyPlugin"
PLUGIN_VERSION="1.0.0"

# Plugin Initialization
init() {
    echo "Initializing $PLUGIN_NAME v$PLUGIN_VERSION"
}

# Main Function
main() {
    echo "Running $PLUGIN_NAME"
    # Your plugin code here
}

# Cleanup
cleanup() {
    echo "Cleanup $PLUGIN_NAME"
}

# Execute
init
main
cleanup
TEMPLATE
    
    chmod +x "$PLUGIN_DIR/templates/main.sh"
    
    success "Plugin System initialisiert"
}

# ==============================================================================
# CREATE PLUGIN
# ==============================================================================
create_plugin() {
    echo ""
    echo -e "${CYAN}=== Plugin Erstellen ===${NC}"
    echo ""
    
    read -p "Plugin Name: " plugin_name
    read -p "Version (1.0.0): " plugin_version
    plugin_version=${plugin_version:-1.0.0}
    read -p "Beschreibung: " plugin_desc
    read -p "Autor: " plugin_author
    read -p "Kategorie (utility/monitoring/security/development): " plugin_cat
    plugin_cat=${plugin_cat:-utility}
    
    plugin_slug=$(echo "$plugin_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    plugin_path="$PLUGIN_DIR/disabled/$plugin_slug"
    
    mkdir -p "$plugin_path"
    
    # Create Manifest
    cat > "$plugin_path/manifest.json" << NEWMANIFEST
{
  "name": "$plugin_name",
  "version": "$plugin_version",
  "description": "$plugin_desc",
  "author": "$plugin_author",
  "category": "$plugin_cat",
  "dependencies": [],
  "entry_point": "main.sh",
  "config": {}
}
NEWMANIFEST
    
    # Create Main Script
    cat > "$plugin_path/main.sh" << NEWSCRIPT
#!/data/data/com.termux/files/usr/bin/bash
# $plugin_name v$plugin_version
# $plugin_desc

PLUGIN_NAME="$plugin_name"
PLUGIN_VERSION="$plugin_version"

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "\${CYAN}=== \${PLUGIN_NAME} v\${PLUGIN_VERSION} ===\${NC}"
echo ""

# TODO: Implement your plugin functionality here

echo ""
echo -e "\${GREEN}✓ Plugin executed successfully\${NC}"
NEWSCRIPT
    
    chmod +x "$plugin_path/main.sh"
    
    # Create README
    cat > "$plugin_path/README.md" << NEWREADME
# $plugin_name

$plugin_desc

## Version
$plugin_version

## Author
$plugin_author

## Category
$plugin_cat

## Usage

\`\`\`bash
bash $plugin_path/main.sh
\`\`\`

## Configuration

Edit \`manifest.json\` to configure the plugin.

## License

© Elektronikx-Center-Matte ®
NEWREADME
    
    success "Plugin '$plugin_name' erstellt: $plugin_path"
    info "Bearbeite: $plugin_path/main.sh"
}

# ==============================================================================
# LIST PLUGINS
# ==============================================================================
list_plugins() {
    echo ""
    echo -e "${CYAN}=== Installierte Plugins ===${NC}"
    echo ""
    
    # Enabled
    echo -e "${GREEN}Aktiv:${NC}"
    if [ -d "$PLUGIN_DIR/enabled" ]; then
        for plugin in "$PLUGIN_DIR/enabled"/*; do
            if [ -d "$plugin" ]; then
                if [ -f "$plugin/manifest.json" ]; then
                    name=$(grep '"name"' "$plugin/manifest.json" | cut -d'"' -f4)
                    version=$(grep '"version"' "$plugin/manifest.json" | cut -d'"' -f4)
                    echo "  ✓ $name v$version"
                fi
            fi
        done
    fi
    
    echo ""
    echo -e "${YELLOW}Deaktiviert:${NC}"
    if [ -d "$PLUGIN_DIR/disabled" ]; then
        for plugin in "$PLUGIN_DIR/disabled"/*; do
            if [ -d "$plugin" ]; then
                if [ -f "$plugin/manifest.json" ]; then
                    name=$(grep '"name"' "$plugin/manifest.json" | cut -d'"' -f4)
                    version=$(grep '"version"' "$plugin/manifest.json" | cut -d'"' -f4)
                    echo "  ○ $name v$version"
                fi
            fi
        done
    fi
}

# ==============================================================================
# ENABLE/DISABLE PLUGIN
# ==============================================================================
toggle_plugin() {
    local action=$1
    
    echo ""
    read -p "Plugin Name (Slug): " plugin_slug
    
    if [ "$action" = "enable" ]; then
        if [ -d "$PLUGIN_DIR/disabled/$plugin_slug" ]; then
            mv "$PLUGIN_DIR/disabled/$plugin_slug" "$PLUGIN_DIR/enabled/"
            success "Plugin '$plugin_slug' aktiviert"
        else
            error "Plugin nicht gefunden"
        fi
    else
        if [ -d "$PLUGIN_DIR/enabled/$plugin_slug" ]; then
            mv "$PLUGIN_DIR/enabled/$plugin_slug" "$PLUGIN_DIR/disabled/"
            success "Plugin '$plugin_slug' deaktiviert"
        else
            error "Plugin nicht gefunden"
        fi
    fi
}

# ==============================================================================
# RUN PLUGIN
# ==============================================================================
run_plugin() {
    echo ""
    read -p "Plugin Name (Slug): " plugin_slug
    
    if [ -f "$PLUGIN_DIR/enabled/$plugin_slug/main.sh" ]; then
        bash "$PLUGIN_DIR/enabled/$plugin_slug/main.sh"
    elif [ -f "$PLUGIN_DIR/disabled/$plugin_slug/main.sh" ]; then
        bash "$PLUGIN_DIR/disabled/$plugin_slug/main.sh"
    else
        error "Plugin nicht gefunden"
    fi
}

# ==============================================================================
# RUN ALL ENABLED PLUGINS
# ==============================================================================
run_all_plugins() {
    echo ""
    echo -e "${CYAN}=== Starte alle aktiven Plugins ===${NC}"
    echo ""
    
    if [ -d "$PLUGIN_DIR/enabled" ]; then
        for plugin in "$PLUGIN_DIR/enabled"/*; do
            if [ -d "$plugin" ] && [ -f "$plugin/main.sh" ]; then
                name=$(basename "$plugin")
                echo -e "${CYAN}Running: $name${NC}"
                bash "$plugin/main.sh"
                echo ""
            fi
        done
    fi
    
    success "Alle Plugins ausgeführt"
}

# ==============================================================================
# INSTALL SAMPLE PLUGINS
# ==============================================================================
install_sample_plugins() {
    info "Installiere Beispiel-Plugins..."
    
    # 1. System Info Plugin
    mkdir -p "$PLUGIN_DIR/disabled/sysinfo"
    
    cat > "$PLUGIN_DIR/disabled/sysinfo/manifest.json" << 'SYSINFO_MANIFEST'
{
  "name": "System Info",
  "version": "1.0.0",
  "description": "Display detailed system information",
  "author": "XTREME XA-vI Team",
  "category": "monitoring",
  "dependencies": [],
  "entry_point": "main.sh"
}
SYSINFO_MANIFEST
    
    cat > "$PLUGIN_DIR/disabled/sysinfo/main.sh" << 'SYSINFO_SCRIPT'
#!/data/data/com.termux/files/usr/bin/bash
echo "=== System Information ==="
echo ""
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Arch: $(uname -m)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
echo ""
echo "CPU:"
lscpu 2>/dev/null | grep -E "Model name|CPU\(s\):" || cat /proc/cpuinfo | grep "model name" | head -1
echo ""
echo "Memory:"
free -h
SYSINFO_SCRIPT
    chmod +x "$PLUGIN_DIR/disabled/sysinfo/main.sh"
    
    # 2. Quick Backup Plugin
    mkdir -p "$PLUGIN_DIR/disabled/quickbackup"
    
    cat > "$PLUGIN_DIR/disabled/quickbackup/manifest.json" << 'BACKUP_MANIFEST'
{
  "name": "Quick Backup",
  "version": "1.0.0",
  "description": "Quick backup of important files",
  "author": "XTREME XA-vI Team",
  "category": "utility",
  "dependencies": [],
  "entry_point": "main.sh"
}
BACKUP_MANIFEST
    
    cat > "$PLUGIN_DIR/disabled/quickbackup/main.sh" << 'BACKUP_SCRIPT'
#!/data/data/com.termux/files/usr/bin/bash
BACKUP_DIR="$HOME/xtreme_backups/quick"
mkdir -p "$BACKUP_DIR"

echo "=== Quick Backup ==="
echo ""
tar -czf "$BACKUP_DIR/quick_$(date +%Y%m%d_%H%M%S).tar.gz" \
    ~/xtreme_ai_system/config \
    ~/xtreme_ai_system/data 2>/dev/null

echo "✓ Backup created in $BACKUP_DIR"
ls -lh "$BACKUP_DIR" | tail -1
BACKUP_SCRIPT
    chmod +x "$PLUGIN_DIR/disabled/quickbackup/main.sh"
    
    success "Beispiel-Plugins installiert"
    info "Aktiviere mit: Plugin aktivieren"
}

# ==============================================================================
# MAIN MENU
# ==============================================================================
main_menu() {
    while true; do
        show_banner
        
        echo ""
        echo -e "${CYAN}=== Plugin Management ===${NC}"
        echo ""
        echo "1) Plugin erstellen"
        echo "2) Plugins auflisten"
        echo "3) Plugin aktivieren"
        echo "4) Plugin deaktivieren"
        echo "5) Plugin ausführen"
        echo "6) Alle aktiven Plugins ausführen"
        echo "7) Beispiel-Plugins installieren"
        echo "8) Plugin löschen"
        echo ""
        echo "0) Beenden"
        echo ""
        read -p "Wähle Option: " choice
        
        case $choice in
            1) create_plugin ;;
            2) list_plugins ;;
            3) toggle_plugin "enable" ;;
            4) toggle_plugin "disable" ;;
            5) run_plugin ;;
            6) run_all_plugins ;;
            7) install_sample_plugins ;;
            8)
                read -p "Plugin Name (Slug): " plugin_slug
                rm -rf "$PLUGIN_DIR/enabled/$plugin_slug" "$PLUGIN_DIR/disabled/$plugin_slug"
                success "Plugin gelöscht"
                ;;
            0) exit 0 ;;
            *) error "Ungültige Option" ;;
        esac
        
        echo ""
        read -p "Drücke Enter um fortzufahren..."
    done
}

# ==============================================================================
# INIT
# ==============================================================================
mkdir -p "$INSTALL_DIR/logs"

if [ ! -d "$PLUGIN_DIR" ]; then
    init_plugin_system
fi

main_menu
