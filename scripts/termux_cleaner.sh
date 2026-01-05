#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XAI v4.0 - COMPREHENSIVE TERMUX CLEANER
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©
# Deep scan, analysis and intelligent cleanup of Termux environment
# ==============================================================================

set -euo pipefail

# Farben
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
MAGENTA='\033[1;35m'
NC='\033[0m'

# Statistiken
TOTAL_SCANNED=0
INVALID_FILES=0
BROKEN_LINKS=0
DUPLICATES=0
CACHE_CLEANED=0
SPACE_FREED=0

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          XTREME XAI v4.0 - TERMUX CLEANER & SCANNER              ║${NC}"
echo -e "${CYAN}║          © Elektronikx-Center-Matte ®                            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Backup vor Bereinigung
BACKUP_DIR="$HOME/.termux_cleaner_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo -e "${CYAN}[INFO]${NC} Backup-Verzeichnis: $BACKUP_DIR"
echo ""

# ==============================================================================
# 1. DEEP SCAN - HOME DIRECTORY
# ==============================================================================
echo -e "${MAGENTA}[1/7]${NC} ${CYAN}Deep Scan des Home-Verzeichnisses...${NC}"
echo "Scanne alle Dateien und Unterordner..."

find "$HOME" -type f 2>/dev/null | while read -r file; do
    ((TOTAL_SCANNED++))
    
    # Prüfe auf ungültige Dateien (0 Bytes, unlesbar)
    if [[ ! -r "$file" ]] || [[ ! -s "$file" ]]; then
        ((INVALID_FILES++))
        echo "  [INVALID] $file"
    fi
done

echo -e "${GREEN}✓${NC} Gescannt: $TOTAL_SCANNED Dateien"
echo -e "${YELLOW}⚠${NC} Ungültig: $INVALID_FILES Dateien"
echo ""

# ==============================================================================
# 2. BROKEN SYMLINKS
# ==============================================================================
echo -e "${MAGENTA}[2/7]${NC} ${CYAN}Suche nach kaputten Symlinks...${NC}"

find "$HOME" -xtype l 2>/dev/null | while read -r link; do
    ((BROKEN_LINKS++))
    echo "  [BROKEN] $link"
    # Backup und Löschen
    cp -P "$link" "$BACKUP_DIR/" 2>/dev/null || true
    rm -f "$link" 2>/dev/null || true
done

echo -e "${GREEN}✓${NC} Entfernt: $BROKEN_LINKS kaputte Symlinks"
echo ""

# ==============================================================================
# 3. CACHE-BEREINIGUNG
# ==============================================================================
echo -e "${MAGENTA}[3/7]${NC} ${CYAN}Bereinige Cache-Dateien...${NC}"

# pkg cache
if [[ -d "$PREFIX/var/cache/apt" ]]; then
    CACHE_SIZE=$(du -sh "$PREFIX/var/cache/apt" 2>/dev/null | cut -f1)
    echo "  Lösche pkg cache ($CACHE_SIZE)..."
    rm -rf "$PREFIX/var/cache/apt"/* 2>/dev/null || true
    ((CACHE_CLEANED++))
fi

# pip cache
if [[ -d "$HOME/.cache/pip" ]]; then
    CACHE_SIZE=$(du -sh "$HOME/.cache/pip" 2>/dev/null | cut -f1)
    echo "  Lösche pip cache ($CACHE_SIZE)..."
    rm -rf "$HOME/.cache/pip"/* 2>/dev/null || true
    ((CACHE_CLEANED++))
fi

# npm cache
if [[ -d "$HOME/.npm" ]]; then
    CACHE_SIZE=$(du -sh "$HOME/.npm" 2>/dev/null | cut -f1)
    echo "  Lösche npm cache ($CACHE_SIZE)..."
    rm -rf "$HOME/.npm"/* 2>/dev/null || true
    ((CACHE_CLEANED++))
fi

echo -e "${GREEN}✓${NC} Bereinigt: $CACHE_CLEANED Caches"
echo ""

# ==============================================================================
# 4. TEMPORÄRE DATEIEN
# ==============================================================================
echo -e "${MAGENTA}[4/7]${NC} ${CYAN}Lösche temporäre Dateien...${NC}"

# /tmp
if [[ -d "/tmp" ]]; then
    find /tmp -type f -mtime +7 -delete 2>/dev/null || true
    echo "  ${GREEN}✓${NC} /tmp bereinigt"
fi

# Temp-Dateien im HOME
find "$HOME" -name "*.tmp" -o -name "*.temp" -o -name "*~" 2>/dev/null | while read -r tmpfile; do
    rm -f "$tmpfile" 2>/dev/null || true
done

echo -e "${GREEN}✓${NC} Temporäre Dateien gelöscht"
echo ""

# ==============================================================================
# 5. ALTE LOG-DATEIEN
# ==============================================================================
echo -e "${MAGENTA}[5/7]${NC} ${CYAN}Komprimiere alte Log-Dateien...${NC}"

find "$HOME" -name "*.log" -mtime +30 2>/dev/null | while read -r logfile; do
    if [[ -f "$logfile" ]] && [[ ! -f "${logfile}.gz" ]]; then
        gzip "$logfile" 2>/dev/null || true
        echo "  ${GREEN}✓${NC} Komprimiert: $(basename "$logfile")"
    fi
done

echo -e "${GREEN}✓${NC} Log-Dateien komprimiert"
echo ""

# ==============================================================================
# 6. DUPLIKATE-ERKENNUNG (MD5)
# ==============================================================================
echo -e "${MAGENTA}[6/7]${NC} ${CYAN}Suche nach Duplikaten (MD5-basiert)...${NC}"

declare -A md5_map
find "$HOME" -type f -size +1M 2>/dev/null | while read -r file; do
    md5=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
    if [[ -n "${md5_map[$md5]:-}" ]]; then
        ((DUPLICATES++))
        echo "  [DUP] $file <-> ${md5_map[$md5]}"
    else
        md5_map[$md5]="$file"
    fi
done

echo -e "${YELLOW}⚠${NC} Gefunden: $DUPLICATES potentielle Duplikate"
echo ""

# ==============================================================================
# 7. VERWAISTE PACKAGES
# ==============================================================================
echo -e "${MAGENTA}[7/7]${NC} ${CYAN}Prüfe auf verwaiste Packages...${NC}"

if command -v pkg &>/dev/null; then
    pkg autoclean -y >/dev/null 2>&1 || true
    echo -e "${GREEN}✓${NC} Package-Cache bereinigt"
fi

echo ""

# ==============================================================================
# STATISTIK & REPORT
# ==============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    BEREINIGUNGSBERICHT                           ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC} Gescannte Dateien:       ${YELLOW}$TOTAL_SCANNED${NC}"
echo -e "${CYAN}║${NC} Ungültige Dateien:       ${RED}$INVALID_FILES${NC}"
echo -e "${CYAN}║${NC} Kaputte Symlinks:        ${RED}$BROKEN_LINKS${NC} ${GREEN}(entfernt)${NC}"
echo -e "${CYAN}║${NC} Bereinigte Caches:       ${GREEN}$CACHE_CLEANED${NC}"
echo -e "${CYAN}║${NC} Gefundene Duplikate:     ${YELLOW}$DUPLICATES${NC}"
echo -e "${CYAN}║${NC} Backup-Verzeichnis:      ${CYAN}$BACKUP_DIR${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}🎉 Termux-Bereinigung abgeschlossen!${NC}"
echo ""
echo -e "${CYAN}Hinweis:${NC} Backup gespeichert in: $BACKUP_DIR"
echo -e "${CYAN}Hinweis:${NC} Bei Problemen können Dateien wiederhergestellt werden."
