#!/bin/bash
# XAI v4.0.0 - Systemkonfiguration
# Entwickler: Alexander Mathey ©
# Organisation: Elektronikx-Center-Matte ®
# Datum: 2026-01-05

# Farben für bessere UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# XAI Verzeichnisse
XAI_HOME="$HOME/xai"
XAI_BIN="$XAI_HOME/bin"
XAI_CONFIG="$XAI_HOME/config"
XAI_DATA="$XAI_HOME/data"
XAI_LOGS="$XAI_HOME/logs"
XAI_MODELS="$XAI_HOME/models"

# Hilfsfunktionen
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Verzeichnisstruktur erstellen
create_directory_structure() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         Erstelle XAI Verzeichnisstruktur                  ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    directories=(
        "$XAI_HOME"
        "$XAI_BIN"
        "$XAI_CONFIG"
        "$XAI_DATA"
        "$XAI_LOGS"
        "$XAI_MODELS"
    )
    
    for dir in "${directories[@]}"; do
        if mkdir -p "$dir" 2>/dev/null; then
            print_success "Verzeichnis erstellt: $dir"
        else
            print_error "Fehler beim Erstellen: $dir"
            return 1
        fi
    done
    
    echo ""
}

# Umgebungsvariablen setzen
setup_environment_variables() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         Umgebungsvariablen konfigurieren                  ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    # XAI Umgebungsvariablen
    cat > "$XAI_CONFIG/env.sh" << 'EOF'
# XAI v4.0.0 Umgebungsvariablen
export XAI_HOME="$HOME/xai"
export XAI_BIN="$XAI_HOME/bin"
export XAI_CONFIG="$XAI_HOME/config"
export XAI_DATA="$XAI_HOME/data"
export XAI_LOGS="$XAI_HOME/logs"
export XAI_MODELS="$XAI_HOME/models"
export XAI_VERSION="4.0.0"

# PATH erweitern
export PATH="$XAI_BIN:$PATH"
EOF
    
    print_success "Umgebungsvariablen konfiguriert: $XAI_CONFIG/env.sh"
    echo ""
}

# Bash-Profile anpassen
setup_bash_profile() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         Bash-Profile anpassen                             ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    # .bashrc oder .bash_profile finden
    if [ -f "$HOME/.bashrc" ]; then
        PROFILE_FILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        PROFILE_FILE="$HOME/.bash_profile"
    else
        PROFILE_FILE="$HOME/.bashrc"
        touch "$PROFILE_FILE"
    fi
    
    # Prüfen ob XAI bereits konfiguriert ist
    if grep -q "XAI v4.0.0" "$PROFILE_FILE" 2>/dev/null; then
        print_info "XAI ist bereits in $PROFILE_FILE konfiguriert"
    else
        # XAI Konfiguration hinzufügen
        cat >> "$PROFILE_FILE" << 'EOF'

# XAI v4.0.0 Konfiguration
if [ -f "$HOME/xai/config/env.sh" ]; then
    source "$HOME/xai/config/env.sh"
fi

# XAI Alias
alias xai="$HOME/xai/bin/xai"
alias xai-status="$HOME/xai/bin/xai status"
alias xai-logs="tail -f $HOME/xai/logs/xai.log"
EOF
        print_success "Bash-Profile aktualisiert: $PROFILE_FILE"
    fi
    
    echo ""
}

# XAI Kommandos registrieren
register_xai_commands() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         XAI Kommandos registrieren                        ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    # xai.sh nach bin kopieren
    if [ -f "./xai.sh" ]; then
        cp "./xai.sh" "$XAI_BIN/xai"
        chmod +x "$XAI_BIN/xai"
        print_success "XAI Launcher registriert: $XAI_BIN/xai"
    else
        print_error "xai.sh nicht gefunden"
    fi
    
    echo ""
}

# Standard-Konfigurationsdateien erstellen
create_config_files() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         Konfigurationsdateien erstellen                   ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    # config.json
    cat > "$XAI_CONFIG/config.json" << 'EOF'
{
  "xai": {
    "version": "4.0.0",
    "name": "XTREME XAI",
    "developer": "Alexander Mathey",
    "organization": "Elektronikx-Center-Matte"
  },
  "system": {
    "device": "Realme C63 RMX3939",
    "cpu": "Unisoc Tiger T612",
    "ram_gb": 8,
    "storage_gb": 256
  },
  "settings": {
    "log_level": "INFO",
    "max_log_size_mb": 100,
    "enable_autostart": false,
    "theme": "dark"
  }
}
EOF
    print_success "Konfigurationsdatei erstellt: $XAI_CONFIG/config.json"
    
    # Log-Datei initialisieren
    echo "$(date '+%Y-%m-%d %H:%M:%S') - XAI v4.0.0 Setup abgeschlossen" > "$XAI_LOGS/xai.log"
    print_success "Log-Datei initialisiert: $XAI_LOGS/xai.log"
    
    echo ""
}

# Autostart-Optionen konfigurieren
configure_autostart() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         Autostart-Optionen konfigurieren                  ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
    
    # Autostart-Script erstellen
    cat > "$XAI_CONFIG/autostart.sh" << 'EOF'
#!/bin/bash
# XAI v4.0.0 Autostart Script
# Wird beim Termux-Start ausgeführt (optional)

# XAI Umgebung laden
if [ -f "$HOME/xai/config/env.sh" ]; then
    source "$HOME/xai/config/env.sh"
fi

# XAI Banner anzeigen
echo "XAI v4.0.0 - Ultimate AI System"
echo "Entwickelt von Alexander Mathey"

# Optional: XAI automatisch starten
# Kommentiere die folgende Zeile ein, um XAI beim Start auszuführen:
# $HOME/xai/bin/xai
EOF
    chmod +x "$XAI_CONFIG/autostart.sh"
    print_success "Autostart-Script erstellt: $XAI_CONFIG/autostart.sh"
    
    print_info "Hinweis: Autostart ist standardmäßig deaktiviert"
    print_info "Zum Aktivieren: Bearbeite $XAI_CONFIG/config.json"
    
    echo ""
}

# Zusammenfassung anzeigen
show_setup_summary() {
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}         XAI Setup erfolgreich abgeschlossen!              ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${WHITE}Erstellte Verzeichnisse:${NC}"
    echo -e "${CYAN}├──${NC} $XAI_HOME"
    echo -e "${CYAN}│   ├──${NC} bin/       ${YELLOW}(Ausführbare Dateien)${NC}"
    echo -e "${CYAN}│   ├──${NC} config/    ${YELLOW}(Konfigurationsdateien)${NC}"
    echo -e "${CYAN}│   ├──${NC} data/      ${YELLOW}(Daten und Datenbanken)${NC}"
    echo -e "${CYAN}│   ├──${NC} logs/      ${YELLOW}(Log-Dateien)${NC}"
    echo -e "${CYAN}│   └──${NC} models/    ${YELLOW}(AI-Modelle)${NC}"
    
    echo -e "\n${WHITE}Konfigurationsdateien:${NC}"
    echo -e "${CYAN}•${NC} $XAI_CONFIG/env.sh"
    echo -e "${CYAN}•${NC} $XAI_CONFIG/config.json"
    echo -e "${CYAN}•${NC} $XAI_CONFIG/autostart.sh"
    
    echo -e "\n${WHITE}Verfügbare Kommandos (nach neuer Shell):${NC}"
    echo -e "${GREEN}•${NC} xai              ${YELLOW}(XAI starten)${NC}"
    echo -e "${GREEN}•${NC} xai-status       ${YELLOW}(System-Status)${NC}"
    echo -e "${GREEN}•${NC} xai-logs         ${YELLOW}(Logs anzeigen)${NC}"
    
    echo -e "\n${BLUE}ℹ${NC} Starte eine neue Shell oder führe aus: ${GREEN}source ~/.bashrc${NC}\n"
}

# Hauptprogramm
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║          XAI v4.0.0 Systemkonfiguration                 ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    create_directory_structure
    setup_environment_variables
    setup_bash_profile
    register_xai_commands
    create_config_files
    configure_autostart
    show_setup_summary
    
    exit 0
}

# Script ausführen
main
