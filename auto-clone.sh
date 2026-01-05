#!/data/data/com.termux/files/usr/bin/bash
#
# Xtreme XA-vI ® GitHub Repository Auto-Clone und Setup
# By Alexander Mathey XAi-Cyborg ©®
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Prüfe Argumente
if [ -z "$1" ]; then
    echo "Usage: auto-clone.sh <username/repository> [branch]"
    echo ""
    echo "Beispiele:"
    echo "  auto-clone.sh facebook/react"
    echo "  auto-clone.sh vuejs/vue main"
    echo "  auto-clone.sh xxxyalaxx90xxx/Alex- copilot/optimize-performance-all-in-one"
    exit 1
fi

REPO=$1
BRANCH=${2:-main}
REPO_NAME=$(echo $REPO | cut -d'/' -f2)
PROJECTS_DIR="$HOME/projects"

log_info "Klone Repository: $REPO"
log_info "Branch: $BRANCH"

# Erstelle Projects-Verzeichnis
mkdir -p "$PROJECTS_DIR"
cd "$PROJECTS_DIR"

# Clone Repository
if [ -d "$REPO_NAME" ]; then
    log_info "Repository existiert bereits, update wird durchgeführt..."
    cd "$REPO_NAME"
    git pull origin "$BRANCH" || log_error "Pull fehlgeschlagen"
else
    log_info "Clone Repository..."
    git clone "https://github.com/$REPO.git" || log_error "Clone fehlgeschlagen"
    cd "$REPO_NAME"
    
    if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
        git checkout "$BRANCH" || log_info "Branch $BRANCH nicht gefunden, bleibe auf default branch"
    fi
fi

log_success "Repository geklont: $PROJECTS_DIR/$REPO_NAME"

# Auto-detect und Setup
log_info "Erkenne Projekt-Typ..."

if [ -f "package.json" ]; then
    log_info "Node.js Projekt erkannt"
    if command -v npm &> /dev/null; then
        log_info "Installiere npm dependencies..."
        npm install
        log_success "npm dependencies installiert"
    fi
fi

if [ -f "requirements.txt" ]; then
    log_info "Python Projekt erkannt"
    if command -v pip &> /dev/null; then
        log_info "Installiere pip dependencies..."
        pip install -r requirements.txt
        log_success "pip dependencies installiert"
    fi
fi

if [ -f "Gemfile" ]; then
    log_info "Ruby Projekt erkannt"
    if command -v bundle &> /dev/null; then
        log_info "Installiere Ruby gems..."
        bundle install
        log_success "Ruby gems installiert"
    fi
fi

if [ -f "go.mod" ]; then
    log_info "Go Projekt erkannt"
    if command -v go &> /dev/null; then
        log_info "Lade Go dependencies..."
        go mod download
        log_success "Go dependencies geladen"
    fi
fi

if [ -f "Cargo.toml" ]; then
    log_info "Rust Projekt erkannt"
    if command -v cargo &> /dev/null; then
        log_info "Baue Rust Projekt..."
        cargo build
        log_success "Rust Projekt gebaut"
    fi
fi

if [ -f "pom.xml" ]; then
    log_info "Maven Projekt erkannt"
    if command -v mvn &> /dev/null; then
        log_info "Baue Maven Projekt..."
        mvn clean install
        log_success "Maven Projekt gebaut"
    fi
fi

if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    log_info "Gradle Projekt erkannt"
    if [ -f "gradlew" ]; then
        log_info "Baue Gradle Projekt..."
        chmod +x gradlew
        ./gradlew build
        log_success "Gradle Projekt gebaut"
    fi
fi

if [ -f "Makefile" ]; then
    log_info "Makefile gefunden"
    log_info "Tipp: Verwende 'make' um das Projekt zu bauen"
fi

if [ -f "docker-compose.yml" ]; then
    log_info "Docker Compose gefunden"
    log_info "Tipp: Docker ist in Termux limitiert, verwende proot stattdessen"
fi

if [ -f "README.md" ]; then
    log_info "README gefunden"
    log_info "Erste 20 Zeilen:"
    head -n 20 README.md
fi

log_success "Setup abgeschlossen!"
log_info "Projekt-Verzeichnis: $PROJECTS_DIR/$REPO_NAME"
echo ""
echo "Nächste Schritte:"
echo "  cd $PROJECTS_DIR/$REPO_NAME"
echo "  cat README.md  # Dokumentation lesen"
