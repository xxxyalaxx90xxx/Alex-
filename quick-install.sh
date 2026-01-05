#!/bin/bash
# XAI v4.0.0 - Schnellinstallation für Termux
# © Elektronikx-Center-Matte ® - Alexander Mathey © 2026
#
# Dieses Script führt eine vollständige Installation von XAI v4.0.0
# auf Termux/Android durch.
#
# Verwendung:
#   curl -sL https://raw.githubusercontent.com/xxxyalaxx90xxx/Alex-/main/quick-install.sh | bash
#   ODER manuell herunterladen und ausführen

set -e

echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                          ║"
echo "║          XAI v4.0.0 - Schnellinstallation für Termux                   ║"
echo "║                                                                          ║"
echo "║        © Elektronikx-Center-Matte ® - Alexander Mathey © 2026          ║"
echo "║                                                                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Schritt 1: Termux Storage Setup
print_step "Schritt 1/5: Termux Storage einrichten..."
if [ ! -d "$HOME/storage" ]; then
    if command -v termux-setup-storage &> /dev/null; then
        termux-setup-storage
        print_success "Storage konfiguriert"
    else
        print_error "termux-setup-storage nicht verfügbar"
    fi
else
    print_success "Storage bereits konfiguriert"
fi

# Schritt 2: Pakete aktualisieren
print_step "Schritt 2/5: Termux-Pakete aktualisieren..."
pkg update -y && pkg upgrade -y
print_success "Pakete aktualisiert"

# Schritt 3: Git installieren
print_step "Schritt 3/5: Git installieren..."
if ! command -v git &> /dev/null; then
    pkg install git -y
    print_success "Git installiert"
else
    print_success "Git bereits installiert"
fi

# Schritt 4: Repository klonen
print_step "Schritt 4/5: XAI Repository klonen..."
if [ -d "$HOME/Alex-" ]; then
    echo "Repository existiert bereits, aktualisiere..."
    cd "$HOME/Alex-"
    git pull
else
    cd "$HOME"
    git clone https://github.com/xxxyalaxx90xxx/Alex-.git
    cd Alex-
fi
print_success "Repository bereit"

# Schritt 5: Installation starten
print_step "Schritt 5/5: XAI installieren..."
chmod +x install.sh xai-setup.sh xai.sh
./install.sh

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                   Installation abgeschlossen!                            ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "XAI starten mit:"
echo "  cd ~/Alex- && ./xai.sh"
echo ""
echo "Oder nach neuer Shell-Sitzung:"
echo "  xai"
echo ""
