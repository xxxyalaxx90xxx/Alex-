#!/data/data/com.termux/files/usr/bin/bash
#
# Xtreme XA-vI ® Development Environment Manager
# Verwalte verschiedene Entwicklungsumgebungen
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

ENV_DIR="$HOME/.dev-environments"

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
    ║    Xtreme XA-vI ® Dev Environment Manager      ║
    ║    Manage Multiple Development Environments    ║
    ╚════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Initialisiere Environment Manager
init_env_manager() {
    mkdir -p "$ENV_DIR"
    
    if [ ! -f "$ENV_DIR/environments.json" ]; then
        echo '{"environments": []}' > "$ENV_DIR/environments.json"
    fi
}

# Node.js Environment erstellen
create_node_env() {
    local env_name="$1"
    local node_version="${2:-lts}"
    
    log_info "Erstelle Node.js Environment: $env_name"
    
    local env_path="$ENV_DIR/$env_name"
    mkdir -p "$env_path"
    
    # Node Version Manager Setup
    if ! command -v nvm &> /dev/null; then
        log_info "Installiere nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    # Node.js installieren
    nvm install "$node_version"
    nvm use "$node_version"
    
    # Package.json erstellen
    cd "$env_path"
    npm init -y
    
    log_success "Node.js Environment erstellt: $env_name"
    log_info "Aktiviere mit: cd $env_path && nvm use $node_version"
}

# Python Environment erstellen
create_python_env() {
    local env_name="$1"
    local python_version="${2:-3}"
    
    log_info "Erstelle Python Environment: $env_name"
    
    local env_path="$ENV_DIR/$env_name"
    
    # Virtual Environment erstellen
    python$python_version -m venv "$env_path"
    
    log_success "Python Environment erstellt: $env_name"
    log_info "Aktiviere mit: source $env_path/bin/activate"
    
    # Basis-Pakete installieren
    log_info "Installiere Basis-Pakete..."
    source "$env_path/bin/activate"
    pip install --upgrade pip
    pip install wheel setuptools
    deactivate
    
    log_success "Python Environment bereit"
}

# Go Environment erstellen
create_go_env() {
    local env_name="$1"
    
    log_info "Erstelle Go Environment: $env_name"
    
    local env_path="$ENV_DIR/$env_name"
    mkdir -p "$env_path/src" "$env_path/bin" "$env_path/pkg"
    
    # Go Environment Setup-Script
    cat > "$env_path/activate.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash
export GOPATH="$env_path"
export PATH="\$GOPATH/bin:\$PATH"
echo "Go Environment aktiviert: $env_name"
echo "GOPATH: \$GOPATH"
EOF
    
    chmod +x "$env_path/activate.sh"
    
    log_success "Go Environment erstellt: $env_name"
    log_info "Aktiviere mit: source $env_path/activate.sh"
}

# Rust Environment erstellen
create_rust_env() {
    local env_name="$1"
    
    log_info "Erstelle Rust Environment: $env_name"
    
    local env_path="$ENV_DIR/$env_name"
    mkdir -p "$env_path"
    
    cd "$env_path"
    cargo init --name "$env_name"
    
    log_success "Rust Environment erstellt: $env_name"
    log_info "Projekt in: $env_path"
}

# Docker-ähnliche Container Environment
create_container_env() {
    local env_name="$1"
    local distro="${2:-ubuntu}"
    
    log_info "Erstelle Container Environment: $env_name ($distro)"
    
    if ! command -v proot-distro &> /dev/null; then
        log_info "Installiere proot-distro..."
        pkg install proot-distro -y
    fi
    
    # Installation des Distros
    proot-distro install "$distro" --override-alias "$env_name"
    
    log_success "Container Environment erstellt: $env_name"
    log_info "Starte mit: proot-distro login $env_name"
}

# Environments auflisten
list_environments() {
    log_info "Verfügbare Entwicklungsumgebungen:"
    echo ""
    
    if [ ! -d "$ENV_DIR" ] || [ -z "$(ls -A $ENV_DIR 2>/dev/null)" ]; then
        log_warning "Keine Environments gefunden"
        return 0
    fi
    
    for env in "$ENV_DIR"/*; do
        if [ -d "$env" ]; then
            local env_name=$(basename "$env")
            local env_type="Unknown"
            
            # Environment-Typ erkennen
            if [ -f "$env/package.json" ]; then
                env_type="Node.js"
            elif [ -f "$env/bin/activate" ]; then
                env_type="Python"
            elif [ -f "$env/activate.sh" ]; then
                env_type="Go"
            elif [ -f "$env/Cargo.toml" ]; then
                env_type="Rust"
            fi
            
            echo -e "${CYAN}Environment:${NC} $env_name"
            echo -e "  Typ: $env_type"
            echo -e "  Pfad: $env"
            echo ""
        fi
    done
}

# Environment löschen
delete_environment() {
    local env_name="$1"
    
    if [ -z "$env_name" ]; then
        log_error "Environment-Name erforderlich"
        return 1
    fi
    
    local env_path="$ENV_DIR/$env_name"
    
    if [ ! -d "$env_path" ]; then
        log_error "Environment nicht gefunden: $env_name"
        return 1
    fi
    
    log_warning "Lösche Environment: $env_name"
    read -p "Fortfahren? (y/n): " confirm
    
    if [ "$confirm" = "y" ]; then
        rm -rf "$env_path"
        log_success "Environment gelöscht: $env_name"
    else
        log_info "Abgebrochen"
    fi
}

# Schnell-Setup für verschiedene Projekt-Typen
quick_setup() {
    local project_type="$1"
    local project_name="$2"
    
    case "$project_type" in
        react)
            log_info "Erstelle React App: $project_name"
            npx create-react-app "$project_name"
            log_success "React App erstellt"
            ;;
        vue)
            log_info "Erstelle Vue App: $project_name"
            npm create vue@latest "$project_name"
            log_success "Vue App erstellt"
            ;;
        flask)
            log_info "Erstelle Flask App: $project_name"
            mkdir -p "$project_name"
            cd "$project_name"
            python -m venv venv
            source venv/bin/activate
            pip install flask
            cat > app.py << 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello from Xtreme XA-vI!'

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
EOF
            log_success "Flask App erstellt"
            ;;
        express)
            log_info "Erstelle Express App: $project_name"
            mkdir -p "$project_name"
            cd "$project_name"
            npm init -y
            npm install express
            cat > index.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.send('Hello from Xtreme XA-vI!');
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
EOF
            log_success "Express App erstellt"
            ;;
        *)
            log_error "Unbekannter Projekt-Typ: $project_type"
            echo "Verfügbar: react, vue, flask, express"
            return 1
            ;;
    esac
}

# Hilfe
show_help() {
    echo "Xtreme XA-vI Development Environment Manager"
    echo ""
    echo "Usage: dev-env.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create-node <name> [version]   - Node.js Environment"
    echo "  create-python <name> [version] - Python Environment"
    echo "  create-go <name>               - Go Environment"
    echo "  create-rust <name>             - Rust Environment"
    echo "  create-container <name> [distro] - Container Environment"
    echo "  list                           - Liste alle Environments"
    echo "  delete <name>                  - Lösche Environment"
    echo "  quick <type> <name>            - Schnell-Setup (react/vue/flask/express)"
    echo "  help                           - Diese Hilfe"
    echo ""
    echo "Beispiele:"
    echo "  ./dev-env.sh create-node myapp 18"
    echo "  ./dev-env.sh create-python ml-project 3.11"
    echo "  ./dev-env.sh quick react my-react-app"
}

# Main
main() {
    init_env_manager
    
    case "${1:-help}" in
        create-node)
            show_banner
            create_node_env "$2" "$3"
            ;;
        create-python)
            show_banner
            create_python_env "$2" "$3"
            ;;
        create-go)
            show_banner
            create_go_env "$2"
            ;;
        create-rust)
            show_banner
            create_rust_env "$2"
            ;;
        create-container)
            show_banner
            create_container_env "$2" "$3"
            ;;
        list)
            show_banner
            list_environments
            ;;
        delete)
            show_banner
            delete_environment "$2"
            ;;
        quick)
            show_banner
            quick_setup "$2" "$3"
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
