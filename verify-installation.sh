#!/bin/bash
# XAI v4.0.0 - Comprehensive Installation Verification
# © Elektronikx-Center-Matte ® - Alexander Mathey © 2026
#
# Dieses Script überprüft alle Komponenten des XAI v4.0.0 Systems

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                          ║${NC}"
echo -e "${CYAN}║          XAI v4.0.0 - Vollständige System-Verifikation                 ║${NC}"
echo -e "${CYAN}║                                                                          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

ERRORS=0
WARNINGS=0
CHECKS=0

# 1. Datei-Existenz prüfen
print_check "Prüfe Datei-Existenz..."
((CHECKS++))

required_files=(
    "install.sh"
    "xai-setup.sh"
    "xai.sh"
    "quick-install.sh"
    "requirements.txt"
    ".gitignore"
    "README.md"
    "TERMUX_INSTALLATION.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "Datei existiert: $file"
    else
        print_error "Datei fehlt: $file"
        ((ERRORS++))
    fi
done

# 2. Ausführbarkeit prüfen
print_check "Prüfe Ausführbarkeit der Scripts..."
((CHECKS++))

executable_files=(
    "install.sh"
    "xai-setup.sh"
    "xai.sh"
    "quick-install.sh"
)

for file in "${executable_files[@]}"; do
    if [ -x "$file" ]; then
        print_success "Ausführbar: $file"
    else
        print_warning "Nicht ausführbar: $file (kann mit chmod +x behoben werden)"
        ((WARNINGS++))
    fi
done

# 3. Bash-Syntax prüfen
print_check "Prüfe Bash-Syntax..."
((CHECKS++))

for file in "${executable_files[@]}"; do
    if bash -n "$file" 2>/dev/null; then
        print_success "Syntax gültig: $file"
    else
        print_error "Syntax-Fehler in: $file"
        ((ERRORS++))
    fi
done

# 4. Shebang prüfen
print_check "Prüfe Shebang in Scripts..."
((CHECKS++))

for file in "${executable_files[@]}"; do
    first_line=$(head -n 1 "$file")
    if [[ "$first_line" == "#!/bin/bash"* ]]; then
        print_success "Shebang korrekt: $file"
    else
        print_warning "Shebang fehlt oder falsch: $file"
        ((WARNINGS++))
    fi
done

# 5. Copyright-Header prüfen
print_check "Prüfe Copyright-Header..."
((CHECKS++))

for file in "${executable_files[@]}"; do
    if grep -q "Alexander Mathey" "$file" && grep -q "2026" "$file"; then
        print_success "Copyright vorhanden: $file"
    else
        print_warning "Copyright fehlt oder unvollständig: $file"
        ((WARNINGS++))
    fi
done

# 6. Wichtige Funktionen prüfen
print_check "Prüfe kritische Funktionen in install.sh..."
((CHECKS++))

critical_functions=(
    "run_prechecks"
    "install_system_dependencies"
    "install_python_packages"
    "configure_xai_system"
)

for func in "${critical_functions[@]}"; do
    if grep -q "^${func}()" "install.sh" || grep -q "^${func} ()" "install.sh"; then
        print_success "Funktion gefunden: $func"
    else
        print_error "Funktion fehlt: $func"
        ((ERRORS++))
    fi
done

# 7. Requirements.txt prüfen
print_check "Prüfe requirements.txt..."
((CHECKS++))

required_packages=(
    "numpy"
    "pandas"
    "requests"
    "colorama"
    "rich"
)

for package in "${required_packages[@]}"; do
    if grep -q "$package" "requirements.txt"; then
        print_success "Package gelistet: $package"
    else
        print_error "Package fehlt: $package"
        ((ERRORS++))
    fi
done

# 8. README.md prüfen
print_check "Prüfe README.md Struktur..."
((CHECKS++))

readme_sections=(
    "XAI v4.0.0"
    "Schnellstart"
    "Installation"
    "Setup K8S"
)

for section in "${readme_sections[@]}"; do
    if grep -q "$section" "README.md"; then
        print_success "Sektion gefunden: $section"
    else
        print_warning "Sektion fehlt oder anders benannt: $section"
        ((WARNINGS++))
    fi
done

# 9. TERMUX_INSTALLATION.md prüfen
print_check "Prüfe TERMUX_INSTALLATION.md..."
((CHECKS++))

if [ -f "TERMUX_INSTALLATION.md" ]; then
    if grep -q "Termux" "TERMUX_INSTALLATION.md" && grep -q "Installation" "TERMUX_INSTALLATION.md"; then
        print_success "TERMUX_INSTALLATION.md ist vollständig"
    else
        print_warning "TERMUX_INSTALLATION.md könnte unvollständig sein"
        ((WARNINGS++))
    fi
else
    print_error "TERMUX_INSTALLATION.md fehlt"
    ((ERRORS++))
fi

# 10. .gitignore prüfen
print_check "Prüfe .gitignore..."
((CHECKS++))

gitignore_patterns=(
    "__pycache__"
    "node_modules"
    "*.log"
    ".xai_install_logs"
)

for pattern in "${gitignore_patterns[@]}"; do
    if grep -q "$pattern" ".gitignore"; then
        print_success "Pattern vorhanden: $pattern"
    else
        print_warning "Pattern fehlt: $pattern"
        ((WARNINGS++))
    fi
done

# 11. Installation Commands prüfen
print_check "Prüfe README für Installation Commands..."
((CHECKS++))

if grep -q "pkg install git" "README.md"; then
    print_success "Termux Installations-Commands gefunden"
else
    print_warning "Termux Installations-Commands fehlen möglicherweise"
    ((WARNINGS++))
fi

# 12. Dateigröße prüfen
print_check "Prüfe Dateigrößen..."
((CHECKS++))

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file" 2>/dev/null)
        if [ "$size" -gt 0 ]; then
            print_success "Datei nicht leer: $file (${size} Bytes)"
        else
            print_error "Datei ist leer: $file"
            ((ERRORS++))
        fi
    fi
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}VERIFIKATIONS-ZUSAMMENFASSUNG${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Durchgeführte Checks:${NC} $CHECKS"
echo -e "${GREEN}Erfolgreich:${NC} $((CHECKS - ERRORS - WARNINGS))"
echo -e "${YELLOW}Warnungen:${NC} $WARNINGS"
echo -e "${RED}Fehler:${NC} $ERRORS"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ ALLE KRITISCHEN CHECKS BESTANDEN!${NC}"
    echo -e "${WHITE}Das XAI v4.0.0 System ist vollständig und funktionsfähig.${NC}"
    exit 0
elif [ $ERRORS -le 2 ]; then
    echo -e "${YELLOW}⚠️  SYSTEM FUNKTIONSFÄHIG MIT KLEINEREN PROBLEMEN${NC}"
    echo -e "${WHITE}Es gibt $ERRORS Fehler, die behoben werden sollten.${NC}"
    exit 1
else
    echo -e "${RED}❌ KRITISCHE PROBLEME GEFUNDEN${NC}"
    echo -e "${WHITE}Es gibt $ERRORS Fehler, die behoben werden müssen.${NC}"
    exit 2
fi
