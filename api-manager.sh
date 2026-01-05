#!/data/data/com.termux/files/usr/bin/bash
#
# Xtreme XA-vI ® API Access Manager
# Vollständiger API-Zugriff für GitHub, NPM, PyPI und mehr
# By Alexander Mathey XAi-Cyborg ©®
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

CONFIG_DIR="$HOME/.config/api-tokens"
TOKEN_FILE="$CONFIG_DIR/tokens.enc"

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
    ╔═══════════════════════════════════════════════════╗
    ║   Xtreme XA-vI ® API Access Manager               ║
    ║   Vollständiger Zugriff auf alle APIs             ║
    ╚═══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Setup-Verzeichnis
setup_config_dir() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        chmod 700 "$CONFIG_DIR"
        log_success "Config-Verzeichnis erstellt: $CONFIG_DIR"
    fi
}

# GitHub Token speichern
setup_github() {
    log_info "GitHub-Token Setup"
    echo ""
    
    if command -v gh &> /dev/null; then
        log_info "GitHub CLI installiert, verwende 'gh auth login'"
        gh auth login
        log_success "GitHub authentifiziert"
    else
        log_warning "GitHub CLI nicht installiert"
        log_info "Installiere mit: pkg install gh"
        echo ""
        read -p "GitHub Personal Access Token eingeben (oder Enter zum Überspringen): " GITHUB_TOKEN
        
        if [ ! -z "$GITHUB_TOKEN" ]; then
            echo "export GITHUB_TOKEN='$GITHUB_TOKEN'" > "$CONFIG_DIR/github"
            chmod 600 "$CONFIG_DIR/github"
            log_success "GitHub Token gespeichert"
        fi
    fi
}

# NPM Token speichern
setup_npm() {
    log_info "NPM-Token Setup"
    echo ""
    
    if ! command -v npm &> /dev/null; then
        log_warning "npm nicht installiert"
        log_info "Installiere mit: pkg install nodejs"
        return
    fi
    
    read -p "NPM Token eingeben (oder Enter zum Überspringen): " NPM_TOKEN
    
    if [ ! -z "$NPM_TOKEN" ]; then
        npm config set //registry.npmjs.org/:_authToken "$NPM_TOKEN"
        log_success "NPM Token gespeichert"
    fi
}

# PyPI Token speichern
setup_pypi() {
    log_info "PyPI-Token Setup"
    echo ""
    
    if ! command -v pip &> /dev/null; then
        log_warning "pip nicht installiert"
        log_info "Installiere mit: pkg install python"
        return
    fi
    
    read -p "PyPI Token eingeben (oder Enter zum Überspringen): " PYPI_TOKEN
    
    if [ ! -z "$PYPI_TOKEN" ]; then
        mkdir -p "$HOME/.pypirc"
        cat > "$HOME/.pypirc" << EOF
[distutils]
index-servers =
    pypi

[pypi]
username = __token__
password = $PYPI_TOKEN
EOF
        chmod 600 "$HOME/.pypirc"
        log_success "PyPI Token gespeichert"
    fi
}

# Docker Hub Token
setup_dockerhub() {
    log_info "Docker Hub Token Setup"
    echo ""
    
    read -p "Docker Hub Username: " DOCKER_USER
    read -sp "Docker Hub Password/Token: " DOCKER_TOKEN
    echo ""
    
    if [ ! -z "$DOCKER_USER" ] && [ ! -z "$DOCKER_TOKEN" ]; then
        mkdir -p "$HOME/.docker"
        cat > "$HOME/.docker/config.json" << EOF
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "$(echo -n "$DOCKER_USER:$DOCKER_TOKEN" | base64)"
        }
    }
}
EOF
        chmod 600 "$HOME/.docker/config.json"
        log_success "Docker Hub Token gespeichert"
    fi
}

# GitLab Token
setup_gitlab() {
    log_info "GitLab Token Setup"
    echo ""
    
    read -p "GitLab Personal Access Token: " GITLAB_TOKEN
    
    if [ ! -z "$GITLAB_TOKEN" ]; then
        git config --global gitlab.token "$GITLAB_TOKEN"
        echo "export GITLAB_TOKEN='$GITLAB_TOKEN'" > "$CONFIG_DIR/gitlab"
        chmod 600 "$CONFIG_DIR/gitlab"
        log_success "GitLab Token gespeichert"
    fi
}

# API-Keys anzeigen
show_api_status() {
    log_info "API-Status:"
    echo ""
    
    # GitHub
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        echo -e "${GREEN}✓${NC} GitHub: Authentifiziert (gh CLI)"
    elif [ -f "$CONFIG_DIR/github" ]; then
        echo -e "${GREEN}✓${NC} GitHub: Token gespeichert"
    else
        echo -e "${RED}✗${NC} GitHub: Nicht konfiguriert"
    fi
    
    # NPM
    if [ -f "$HOME/.npmrc" ] && grep -q "authToken" "$HOME/.npmrc"; then
        echo -e "${GREEN}✓${NC} NPM: Token konfiguriert"
    else
        echo -e "${RED}✗${NC} NPM: Nicht konfiguriert"
    fi
    
    # PyPI
    if [ -f "$HOME/.pypirc" ]; then
        echo -e "${GREEN}✓${NC} PyPI: Token konfiguriert"
    else
        echo -e "${RED}✗${NC} PyPI: Nicht konfiguriert"
    fi
    
    # Docker Hub
    if [ -f "$HOME/.docker/config.json" ]; then
        echo -e "${GREEN}✓${NC} Docker Hub: Konfiguriert"
    else
        echo -e "${RED}✗${NC} Docker Hub: Nicht konfiguriert"
    fi
    
    # GitLab
    if [ -f "$CONFIG_DIR/gitlab" ]; then
        echo -e "${GREEN}✓${NC} GitLab: Token gespeichert"
    else
        echo -e "${RED}✗${NC} GitLab: Nicht konfiguriert"
    fi
    
    # SSH Keys
    if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
        echo -e "${GREEN}✓${NC} SSH: Keys vorhanden"
    else
        echo -e "${RED}✗${NC} SSH: Keine Keys"
    fi
    
    # GPG Keys
    if command -v gpg &> /dev/null && [ $(gpg --list-secret-keys | grep -c "sec") -gt 0 ]; then
        echo -e "${GREEN}✓${NC} GPG: Keys vorhanden"
    else
        echo -e "${RED}✗${NC} GPG: Keine Keys"
    fi
}

# API-Test durchführen
test_apis() {
    log_info "Teste API-Verbindungen..."
    echo ""
    
    # GitHub API Test
    log_info "Teste GitHub API..."
    if curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/rate_limit | grep -q "rate"; then
        log_success "GitHub API: OK"
        RATE_LIMIT=$(curl -s https://api.github.com/rate_limit | grep -o '"limit":[0-9]*' | head -1 | cut -d':' -f2)
        echo "  Rate Limit: $RATE_LIMIT requests/hour"
    else
        log_error "GitHub API: Fehler"
    fi
    
    # NPM Registry Test
    log_info "Teste NPM Registry..."
    if curl -s https://registry.npmjs.org/express | grep -q "name"; then
        log_success "NPM Registry: OK"
    else
        log_error "NPM Registry: Fehler"
    fi
    
    # PyPI Test
    log_info "Teste PyPI..."
    if curl -s https://pypi.org/pypi/requests/json | grep -q "info"; then
        log_success "PyPI: OK"
    else
        log_error "PyPI: Fehler"
    fi
    
    echo ""
}

# Repository-Zugriff testen
test_repo_access() {
    log_info "Teste Repository-Zugriff..."
    echo ""
    
    # GitHub
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        log_info "Teste GitHub Repository-Zugriff..."
        REPOS=$(gh repo list --limit 5 2>/dev/null | wc -l)
        if [ $REPOS -gt 0 ]; then
            log_success "GitHub: $REPOS Repositories gefunden"
            gh repo list --limit 5
        else
            log_warning "GitHub: Keine Repositories oder kein Zugriff"
        fi
    fi
    
    echo ""
}

# Automatisches Setup aller APIs
auto_setup() {
    show_banner
    setup_config_dir
    
    log_info "Automatisches Setup wird gestartet..."
    echo ""
    
    read -p "GitHub einrichten? (y/n): " choice
    [ "$choice" = "y" ] && setup_github
    
    read -p "NPM einrichten? (y/n): " choice
    [ "$choice" = "y" ] && setup_npm
    
    read -p "PyPI einrichten? (y/n): " choice
    [ "$choice" = "y" ] && setup_pypi
    
    read -p "Docker Hub einrichten? (y/n): " choice
    [ "$choice" = "y" ] && setup_dockerhub
    
    read -p "GitLab einrichten? (y/n): " choice
    [ "$choice" = "y" ] && setup_gitlab
    
    echo ""
    log_success "Setup abgeschlossen!"
    echo ""
    show_api_status
}

# Hilfe anzeigen
show_help() {
    echo "Xtreme XA-vI API Access Manager"
    echo ""
    echo "Usage: api-manager.sh [command]"
    echo ""
    echo "Commands:"
    echo "  setup       - Interaktives Setup aller APIs"
    echo "  status      - Zeige Status aller APIs"
    echo "  test        - Teste API-Verbindungen"
    echo "  github      - GitHub einrichten"
    echo "  npm         - NPM einrichten"
    echo "  pypi        - PyPI einrichten"
    echo "  docker      - Docker Hub einrichten"
    echo "  gitlab      - GitLab einrichten"
    echo "  help        - Diese Hilfe anzeigen"
    echo ""
    echo "Beispiele:"
    echo "  ./api-manager.sh setup"
    echo "  ./api-manager.sh status"
    echo "  ./api-manager.sh test"
}

# Main
main() {
    setup_config_dir
    
    case "${1:-setup}" in
        setup)
            auto_setup
            ;;
        status)
            show_banner
            show_api_status
            ;;
        test)
            show_banner
            test_apis
            test_repo_access
            ;;
        github)
            show_banner
            setup_github
            ;;
        npm)
            show_banner
            setup_npm
            ;;
        pypi)
            show_banner
            setup_pypi
            ;;
        docker)
            show_banner
            setup_dockerhub
            ;;
        gitlab)
            show_banner
            setup_gitlab
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
