#!/bin/bash

#######################################
# GitHub MCP Server Integration
# Integrates GitHub Model Context Protocol server for AI-powered GitHub operations
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©
#######################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="${GITHUB_MCP_DIR:-$HOME/.github-mcp-server}"
NODE_VERSION="${NODE_VERSION:-18}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in supported environment
check_environment() {
    log_info "Checking environment..."
    
    if [[ -n "$TERMUX_VERSION" ]]; then
        ENV_TYPE="termux"
        log_info "Detected Termux environment"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        ENV_TYPE="wsl"
        log_info "Detected WSL environment"
    else
        ENV_TYPE="linux"
        log_info "Detected Linux environment"
    fi
}

# Install Node.js if not present
install_nodejs() {
    log_info "Checking Node.js installation..."
    
    if command -v node >/dev/null 2>&1; then
        NODE_VER=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ $NODE_VER -ge 18 ]]; then
            log_success "Node.js $(node --version) already installed"
            return 0
        else
            log_warning "Node.js version too old, will upgrade"
        fi
    fi
    
    log_info "Installing Node.js ${NODE_VERSION}..."
    
    if [[ "$ENV_TYPE" == "termux" ]]; then
        pkg update -y
        pkg install -y nodejs
    elif command -v apt-get >/dev/null 2>&1; then
        # Ubuntu/Debian
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif command -v yum >/dev/null 2>&1; then
        # CentOS/RHEL
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | sudo bash -
        sudo yum install -y nodejs
    else
        log_error "Unsupported package manager"
        return 1
    fi
    
    log_success "Node.js installed successfully"
}

# Install GitHub MCP Server
install_github_mcp() {
    log_info "Installing GitHub MCP Server..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Clone repository if not exists
    if [[ ! -d "$INSTALL_DIR/.git" ]]; then
        log_info "Cloning GitHub MCP Server repository..."
        git clone https://github.com/github/github-mcp-server.git .
    else
        log_info "Repository already exists, pulling latest changes..."
        git pull
    fi
    
    # Install dependencies
    log_info "Installing npm dependencies..."
    npm install
    
    # Build the project
    log_info "Building GitHub MCP Server..."
    npm run build
    
    log_success "GitHub MCP Server installed successfully"
}

# Configure GitHub token
configure_github_token() {
    log_info "Configuring GitHub authentication..."
    
    if [[ -z "$GITHUB_TOKEN" ]]; then
        log_warning "GITHUB_TOKEN not set. You'll need to configure it manually."
        log_info "Create a GitHub Personal Access Token at: https://github.com/settings/tokens"
        log_info "Set it with: export GITHUB_TOKEN='your_token_here'"
        
        # Create config template
        cat > "$INSTALL_DIR/config.json" <<EOF
{
  "githubToken": "\${GITHUB_TOKEN}",
  "defaultOwner": "",
  "defaultRepo": ""
}
EOF
        log_info "Configuration template created at: $INSTALL_DIR/config.json"
    else
        cat > "$INSTALL_DIR/config.json" <<EOF
{
  "githubToken": "${GITHUB_TOKEN}",
  "defaultOwner": "",
  "defaultRepo": ""
}
EOF
        log_success "GitHub token configured"
    fi
}

# Create helper scripts
create_helpers() {
    log_info "Creating helper scripts..."
    
    # Create github-mcp command
    cat > "$HOME/.local/bin/github-mcp" <<'EOF'
#!/bin/bash
GITHUB_MCP_DIR="${GITHUB_MCP_DIR:-$HOME/.github-mcp-server}"
cd "$GITHUB_MCP_DIR"
node dist/index.js "$@"
EOF
    chmod +x "$HOME/.local/bin/github-mcp"
    
    # Create AI integration wrapper
    cat > "$HOME/.local/bin/ai-github" <<'EOF'
#!/bin/bash
# AI-powered GitHub operations using MCP server

GITHUB_MCP_DIR="${GITHUB_MCP_DIR:-$HOME/.github-mcp-server}"

show_help() {
    cat << HELP
AI-powered GitHub Operations

Usage: ai-github [command] [options]

Commands:
  repos           List repositories
  issues          List issues
  prs             List pull requests
  search CODE     Search code across repositories
  analyze REPO    Analyze repository with AI
  suggest ISSUE   Get AI suggestions for an issue
  review PR       AI-powered PR review
  commit MSG      Generate commit message with AI
  help            Show this help

Examples:
  ai-github repos
  ai-github issues --state open
  ai-github search "kubernetes cluster"
  ai-github analyze owner/repo
  ai-github suggest 123
  ai-github review 456
  ai-github commit "Add new feature"

HELP
}

case "$1" in
    repos)
        github-mcp repos list "${@:2}"
        ;;
    issues)
        github-mcp issues list "${@:2}"
        ;;
    prs)
        github-mcp pulls list "${@:2}"
        ;;
    search)
        github-mcp search code "${@:2}"
        ;;
    analyze)
        if [[ -z "$2" ]]; then
            echo "Error: Repository required"
            echo "Usage: ai-github analyze owner/repo"
            exit 1
        fi
        echo "Analyzing repository $2 with AI..."
        github-mcp repos get "$2" | ai-assistant "Analyze this GitHub repository"
        ;;
    suggest)
        if [[ -z "$2" ]]; then
            echo "Error: Issue number required"
            echo "Usage: ai-github suggest 123"
            exit 1
        fi
        echo "Getting AI suggestions for issue #$2..."
        github-mcp issues get "$2" | ai-assistant "Suggest solutions for this GitHub issue"
        ;;
    review)
        if [[ -z "$2" ]]; then
            echo "Error: PR number required"
            echo "Usage: ai-github review 456"
            exit 1
        fi
        echo "AI reviewing pull request #$2..."
        github-mcp pulls get "$2" | ai-assistant "Review this pull request and provide feedback"
        ;;
    commit)
        if [[ -z "$2" ]]; then
            echo "Error: Commit message required"
            echo "Usage: ai-github commit 'Add new feature'"
            exit 1
        fi
        echo "Generating detailed commit message with AI..."
        git diff --cached | ai-assistant "Generate a detailed commit message for this change. Original message: $2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run 'ai-github help' for usage information"
        exit 1
        ;;
esac
EOF
    chmod +x "$HOME/.local/bin/ai-github"
    
    log_success "Helper scripts created"
}

# Create systemd service (for non-Termux)
create_service() {
    if [[ "$ENV_TYPE" == "termux" ]]; then
        log_info "Skipping systemd service creation in Termux"
        return 0
    fi
    
    log_info "Creating systemd service..."
    
    sudo tee /etc/systemd/system/github-mcp.service > /dev/null <<EOF
[Unit]
Description=GitHub MCP Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
Environment="GITHUB_TOKEN=${GITHUB_TOKEN}"
ExecStart=$(which node) $INSTALL_DIR/dist/index.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable github-mcp.service
    
    log_success "Systemd service created"
    log_info "Start with: sudo systemctl start github-mcp"
}

# Integrate with existing AI assistant
integrate_with_ai() {
    log_info "Integrating with AI assistant..."
    
    # Add GitHub MCP to AI assistant configuration
    if [[ -f "$HOME/.ai-assistant/config.json" ]]; then
        # Backup existing config
        cp "$HOME/.ai-assistant/config.json" "$HOME/.ai-assistant/config.json.bak"
        
        # Add GitHub MCP integration
        cat > "$HOME/.ai-assistant/github-mcp.json" <<EOF
{
  "enabled": true,
  "mcp_server_path": "$INSTALL_DIR",
  "commands": {
    "github": "github-mcp",
    "ai-github": "ai-github"
  },
  "capabilities": [
    "repository_access",
    "issue_management",
    "pull_request_review",
    "code_search",
    "ai_analysis"
  ]
}
EOF
        log_success "Integrated with AI assistant"
    else
        log_warning "AI assistant not found. Install it with: ./setup_ai_assistant.sh"
    fi
}

# Display usage information
show_usage() {
    cat << USAGE

${GREEN}GitHub MCP Server Installation Complete!${NC}

${BLUE}Configuration:${NC}
  Installation: $INSTALL_DIR
  Node.js: $(node --version)
  
${BLUE}Setup GitHub Token:${NC}
  1. Create token at: https://github.com/settings/tokens
  2. Set in environment: export GITHUB_TOKEN='your_token_here'
  3. Update config: $INSTALL_DIR/config.json

${BLUE}Available Commands:${NC}
  ${GREEN}github-mcp${NC}       - Direct MCP server access
  ${GREEN}ai-github${NC}        - AI-powered GitHub operations
  
${BLUE}Usage Examples:${NC}
  ${YELLOW}# List repositories${NC}
  ai-github repos
  
  ${YELLOW}# Search code${NC}
  ai-github search "kubernetes"
  
  ${YELLOW}# Analyze repository with AI${NC}
  ai-github analyze owner/repo
  
  ${YELLOW}# Get AI suggestions for issue${NC}
  ai-github suggest 123
  
  ${YELLOW}# AI review pull request${NC}
  ai-github review 456
  
  ${YELLOW}# Generate commit message with AI${NC}
  ai-github commit "Add feature"

${BLUE}Integration:${NC}
  - Works with existing AI assistant (ai-assistant command)
  - Integrated with analyze_k8s.sh for repo analysis
  - Compatible with all existing tools

${BLUE}Documentation:${NC}
  GitHub MCP Server: https://github.com/github/github-mcp-server
  Model Context Protocol: https://modelcontextprotocol.io

Run ${GREEN}ai-github help${NC} for more information.

USAGE
}

# Main installation
main() {
    echo ""
    log_info "========================================="
    log_info "GitHub MCP Server Integration"
    log_info "========================================="
    echo ""
    
    # Create bin directory if needed
    mkdir -p "$HOME/.local/bin"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    check_environment
    install_nodejs
    install_github_mcp
    configure_github_token
    create_helpers
    
    if [[ "$ENV_TYPE" != "termux" ]]; then
        create_service
    fi
    
    integrate_with_ai
    
    echo ""
    show_usage
    
    log_success "Installation completed successfully!"
}

# Run main function
main "$@"
