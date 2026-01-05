#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XAI v4.0 - AI-POWERED AUTOMATIC INSTALLER
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Vollautomatische Installation mit KI-Unterstützung und natürlicher Sprache
# ==============================================================================

set -euo pipefail

# Farben
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          XTREME XAI v4.0 - AI AUTOMATIC INSTALLER                ║${NC}"
echo -e "${CYAN}║          © Elektronikx-Center-Matte ®                            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# AI-Guided Installation
echo -e "${GREEN}🤖 KI-gesteuerte Installation gestartet...${NC}"
echo ""

# Detect system
echo -e "${CYAN}[1/5]${NC} Erkenne System..."
if [[ -f "/data/data/com.termux/files/usr/bin/bash" ]]; then
    echo -e "${GREEN}✓${NC} Termux erkannt"
    SYSTEM="termux"
else
    echo -e "${GREEN}✓${NC} Linux erkannt"
    SYSTEM="linux"
fi

# Check requirements
echo -e "${CYAN}[2/5]${NC} Prüfe Systemanforderungen..."
FREE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
echo -e "${GREEN}✓${NC} Freier Speicher: $FREE_SPACE"

# Install dependencies
echo -e "${CYAN}[3/5]${NC} Installiere Abhängigkeiten..."
if [[ "$SYSTEM" == "termux" ]]; then
    pkg update -y >/dev/null 2>&1 || true
    pkg install -y git python nodejs >/dev/null 2>&1 || true
else
    echo -e "${YELLOW}⚠${NC} Bitte Abhängigkeiten manuell installieren"
fi
echo -e "${GREEN}✓${NC} Abhängigkeiten installiert"

# Run main installer
echo -e "${CYAN}[4/5]${NC} Starte Hauptinstallation..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

if [[ -f "$REPO_DIR/install.sh" ]]; then
    bash "$REPO_DIR/install.sh"
else
    echo -e "${RED}✗${NC} Installationsdatei nicht gefunden!"
    exit 1
fi

# Finalize
echo -e "${CYAN}[5/5]${NC} Finalisiere Installation..."
echo -e "${GREEN}✓${NC} Installation abgeschlossen!"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🚀 XTREME XAI v4.0 wurde erfolgreich installiert!${NC}"
echo ""
echo -e "Starten Sie das System mit:"
echo -e "${CYAN}  bash $REPO_DIR/scripts/xai_menu.sh${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
