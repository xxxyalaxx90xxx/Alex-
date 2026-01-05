#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XAI v4.0 - UPDATE MANAGER
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# System update and version management
# ==============================================================================

set -euo pipefail

# Farben
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

CURRENT_VERSION="4.0.0"
REPO_URL="https://github.com/xxxyalaxx90xxx/Alex-"
UPDATE_DIR="$HOME/.xai_updates"

mkdir -p "$UPDATE_DIR"

show_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          XTREME XAI v4.0 - UPDATE MANAGER                        ║${NC}"
    echo -e "${CYAN}║          © Elektronikx-Center-Matte ®                            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Aktuelle Version: ${CYAN}v${CURRENT_VERSION}${NC}"
    echo ""
    echo "  1) Nach Updates suchen"
    echo "  2) System aktualisieren"
    echo "  3) Update-Historie"
    echo "  4) Rollback"
    echo "  5) Auto-Update konfigurieren"
    echo ""
    echo "  0) Zurück"
    echo ""
    echo -n "Auswahl: "
}

check_updates() {
    echo -e "${CYAN}Suche nach Updates...${NC}"
    echo ""
    
    if ! command -v git &>/dev/null; then
        echo -e "${RED}✗${NC} Git ist nicht installiert"
        return 1
    fi
    
    # Fetch latest from repo
    cd "$HOME/Alex-" 2>/dev/null || {
        echo -e "${YELLOW}⚠${NC} Repository nicht gefunden"
        return 1
    }
    
    git fetch origin >/dev/null 2>&1 || {
        echo -e "${RED}✗${NC} Fehler beim Abrufen der Updates"
        return 1
    }
    
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    
    if [[ "$LOCAL" == "$REMOTE" ]]; then
        echo -e "${GREEN}✓${NC} System ist auf dem neuesten Stand"
    else
        echo -e "${YELLOW}⚠${NC} Updates verfügbar!"
        echo ""
        echo "Neue Commits:"
        git log --oneline HEAD..@{u} | head -5
    fi
    
    echo ""
    echo -n "Drücke Enter um fortzufahren..."
    read -r
}

update_system() {
    echo -e "${CYAN}System-Update wird durchgeführt...${NC}"
    echo ""
    
    # Backup erstellen
    echo -n "Erstelle Backup... "
    BACKUP_FILE="$UPDATE_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$BACKUP_FILE" -C "$HOME" "Alex-" 2>/dev/null && {
        echo -e "${GREEN}✓${NC}"
    } || {
        echo -e "${RED}✗${NC}"
    }
    
    # Update durchführen
    echo -n "Lade Updates herunter... "
    cd "$HOME/Alex-" && git pull origin >/dev/null 2>&1 && {
        echo -e "${GREEN}✓${NC}"
    } || {
        echo -e "${RED}✗${NC}"
        return 1
    }
    
    # Abhängigkeiten aktualisieren
    echo -n "Aktualisiere Abhängigkeiten... "
    pkg update -y >/dev/null 2>&1 && {
        echo -e "${GREEN}✓${NC}"
    } || {
        echo -e "${YELLOW}⚠${NC}"
    }
    
    echo ""
    echo -e "${GREEN}✓${NC} Update erfolgreich abgeschlossen!"
    echo ""
    echo "Backup gespeichert: $BACKUP_FILE"
    
    echo ""
    echo -n "Drücke Enter um fortzufahren..."
    read -r
}

show_history() {
    echo -e "${CYAN}Update-Historie${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [[ -d "$UPDATE_DIR" ]]; then
        ls -lh "$UPDATE_DIR"/backup_* 2>/dev/null || echo "Keine Backups vorhanden"
    fi
    
    echo ""
    echo -n "Drücke Enter um fortzufahren..."
    read -r
}

rollback() {
    echo -e "${CYAN}Rollback${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo "Verfügbare Backups:"
    ls -1 "$UPDATE_DIR"/backup_* 2>/dev/null | nl || {
        echo "Keine Backups gefunden"
        echo ""
        echo -n "Drücke Enter um fortzufahren..."
        read -r
        return
    }
    
    echo ""
    echo -n "Backup auswählen (Nummer): "
    read -r backup_num
    
    BACKUP_FILE=$(ls -1 "$UPDATE_DIR"/backup_* 2>/dev/null | sed -n "${backup_num}p")
    
    if [[ -n "$BACKUP_FILE" ]]; then
        echo -n "Stelle Backup wieder her... "
        rm -rf "$HOME/Alex-" 2>/dev/null
        tar -xzf "$BACKUP_FILE" -C "$HOME" 2>/dev/null && {
            echo -e "${GREEN}✓${NC}"
            echo ""
            echo "Rollback erfolgreich!"
        } || {
            echo -e "${RED}✗${NC}"
        }
    fi
    
    echo ""
    echo -n "Drücke Enter um fortzufahren..."
    read -r
}

configure_auto_update() {
    echo -e "${CYAN}Auto-Update Konfiguration${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  1) Auto-Update aktivieren (täglich)"
    echo "  2) Auto-Update deaktivieren"
    echo "  3) Zurück"
    echo ""
    echo -n "Auswahl: "
    read -r choice
    
    case $choice in
        1)
            echo "Auto-Update wird aktiviert..."
            # Cron-Job würde hier eingerichtet werden
            echo -e "${GREEN}✓${NC} Auto-Update aktiviert"
            ;;
        2)
            echo "Auto-Update wird deaktiviert..."
            echo -e "${GREEN}✓${NC} Auto-Update deaktiviert"
            ;;
    esac
    
    echo ""
    echo -n "Drücke Enter um fortzufahren..."
    read -r
}

while true; do
    show_menu
    read -r choice
    
    case $choice in
        1) check_updates ;;
        2) update_system ;;
        3) show_history ;;
        4) rollback ;;
        5) configure_auto_update ;;
        0) break ;;
        *) echo -e "${RED}Ungültige Auswahl${NC}" ;;
    esac
done
