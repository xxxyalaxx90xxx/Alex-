#!/data/data/com.termux/files/usr/bin/bash

################################################################################
# Termux Android Complete Automated Installer with Acode & Style Customization
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©
# Version: 1.0
# 
# Fully automated installation for Termux Android including:
# - Acode IDE with all plugins and themes
# - Complete development environment
# - Database stack
# - Termux customization (colors, fonts, styles)
# - Termux:API integration
# - Termux:Widget setup
# - Storage access configuration
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.termux-acode"
ACODE_PLUGINS_DIR="$HOME/.acode-plugins"
TERMUX_STYLE_DIR="$HOME/.termux"
LOG_FILE="$HOME/termux_acode_install.log"

# Feature flags (can be controlled via environment variables)
INSTALL_ACODE="${INSTALL_ACODE:-true}"
INSTALL_DATABASES="${INSTALL_DATABASES:-true}"
INSTALL_DEV_TOOLS="${INSTALL_DEV_TOOLS:-true}"
CUSTOMIZE_TERMUX="${CUSTOMIZE_TERMUX:-true}"
SETUP_TERMUX_API="${SETUP_TERMUX_API:-true}"
SETUP_WIDGETS="${SETUP_WIDGETS:-true}"

# Progress tracking
TOTAL_STEPS=12
CURRENT_STEP=0

################################################################################
# Helper Functions
################################################################################

show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║    ████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗            ║
║    ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝            ║
║       ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝             ║
║       ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗             ║
║       ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗            ║
║       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝            ║
║                                                                       ║
║               Complete Automated Installation                         ║
║                  with Acode IDE & Customization                      ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${MAGENTA}   Author: Alexander Mathey | Elektronikx-Center-Matte ® ™${NC}"
    echo ""
}

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗ [ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠ [WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${CYAN}ℹ [INFO]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓ [SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    
    # Progress bar configuration
    local BAR_LENGTH=33  # Total length of the progress bar
    local BAR_SCALE=3    # Scale divisor: percent / BAR_SCALE determines filled bar length
    local filled=$((percent / BAR_SCALE))
    local empty=$((BAR_LENGTH - filled))
    
    echo ""
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC} Step ${MAGENTA}$CURRENT_STEP${NC}/${MAGENTA}$TOTAL_STEPS${NC} ${CYAN}[${GREEN}$(printf '█%.0s' $(seq 1 $filled))${NC}$(printf '░%.0s' $(seq 1 $empty))${CYAN}]${NC} ${GREEN}$percent%${NC}"
    echo -e "${BOLD}${CYAN}║${NC} $1"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "This script must be run in Termux!"
        exit 1
    fi
}

################################################################################
# Step 1: Update and Setup Termux
################################################################################

setup_termux() {
    progress "Setting up Termux base system..."
    
    # Update package lists
    log "Updating package lists..."
    pkg update -y >> "$LOG_FILE" 2>&1
    
    # Upgrade existing packages
    log "Upgrading packages..."
    pkg upgrade -y >> "$LOG_FILE" 2>&1
    
    # Install essential packages
    log "Installing essential packages..."
    pkg install -y wget curl git openssh termux-tools termux-api >> "$LOG_FILE" 2>&1
    
    # Setup storage access
    if [ ! -d "$HOME/storage" ]; then
        log "Setting up storage access..."
        termux-setup-storage
        sleep 2
    fi
    
    log "Termux base system ready!"
}

################################################################################
# Step 2: Install Acode IDE
################################################################################

install_acode() {
    if [ "$INSTALL_ACODE" != "true" ]; then
        progress "Skipping Acode installation..."
        return
    fi
    
    progress "Installing Acode IDE..."
    
    # Check if Acode APK exists or download
    local acode_apk="$HOME/acode-latest.apk"
    
    if [ ! -f "$acode_apk" ]; then
        log "Downloading Acode APK..."
        wget -O "$acode_apk" "https://github.com/deadlyjack/Acode/releases/latest/download/acode.apk" >> "$LOG_FILE" 2>&1
    fi
    
    # Install via termux-api if available
    if command -v termux-open &> /dev/null; then
        log "Opening Acode APK for installation..."
        termux-open "$acode_apk"
        info "Please install Acode manually when prompted"
        sleep 3
    else
        warning "termux-open not available. Please install Acode manually from: $acode_apk"
    fi
    
    # Create Acode plugins directory
    mkdir -p "$ACODE_PLUGINS_DIR"
    
    # Create Acode configuration
    cat > "$ACODE_PLUGINS_DIR/config.json" <<'EOF'
{
  "theme": "dark",
  "fontSize": 14,
  "fontFamily": "FiraCode",
  "tabSize": 2,
  "useSoftTab": true,
  "lineHeight": 1.5,
  "showSpaces": false,
  "showLineNumbers": true,
  "wordWrap": true,
  "autoSave": true,
  "autoSaveInterval": 3000,
  "linting": true,
  "formatting": true
}
EOF
    
    log "Acode IDE configuration created!"
}

################################################################################
# Step 3: Install Acode Plugins & Themes
################################################################################

setup_acode_plugins() {
    if [ "$INSTALL_ACODE" != "true" ]; then
        progress "Skipping Acode plugins..."
        return
    fi
    
    progress "Setting up Acode plugins and themes..."
    
    # Create plugins list
    mkdir -p "$ACODE_PLUGINS_DIR/plugins"
    
    # Recommended plugins list
    cat > "$ACODE_PLUGINS_DIR/recommended-plugins.txt" <<'EOF'
# Acode Recommended Plugins
- Acode Plugin: Language Support
- Acode Plugin: Git Integration
- Acode Plugin: Terminal
- Acode Plugin: File Manager
- Acode Plugin: Prettier
- Acode Plugin: ESLint
- Acode Plugin: Docker
- Acode Plugin: Kubernetes
- Acode Plugin: Python Support
- Acode Plugin: Markdown Preview
EOF
    
    # Create theme configurations
    mkdir -p "$ACODE_PLUGINS_DIR/themes"
    
    # Dark theme
    cat > "$ACODE_PLUGINS_DIR/themes/dark-custom.json" <<'EOF'
{
  "name": "Dark Custom",
  "type": "dark",
  "colors": {
    "background": "#1e1e1e",
    "foreground": "#d4d4d4",
    "selection": "#264f78",
    "lineHighlight": "#2a2a2a",
    "cursor": "#ffffff"
  }
}
EOF
    
    # Light theme
    cat > "$ACODE_PLUGINS_DIR/themes/light-custom.json" <<'EOF'
{
  "name": "Light Custom",
  "type": "light",
  "colors": {
    "background": "#ffffff",
    "foreground": "#000000",
    "selection": "#add6ff",
    "lineHighlight": "#f0f0f0",
    "cursor": "#000000"
  }
}
EOF
    
    log "Acode plugins and themes configured!"
}

################################################################################
# Step 4: Customize Termux Appearance
################################################################################

customize_termux_style() {
    if [ "$CUSTOMIZE_TERMUX" != "true" ]; then
        progress "Skipping Termux customization..."
        return
    fi
    
    progress "Customizing Termux appearance..."
    
    mkdir -p "$TERMUX_STYLE_DIR"
    
    # Install additional fonts
    log "Installing Powerline fonts..."
    pkg install -y ncurses-utils >> "$LOG_FILE" 2>&1
    
    # Download and install FiraCode font
    local font_dir="$HOME/.termux/font"
    mkdir -p "$font_dir"
    
    if [ ! -f "$font_dir/FiraCode.ttf" ]; then
        log "Downloading FiraCode font..."
        wget -O "$font_dir/FiraCode.ttf" \
            "https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip" >> "$LOG_FILE" 2>&1 || true
    fi
    
    # Create color schemes
    log "Creating color schemes..."
    
    # Dark color scheme
    cat > "$TERMUX_STYLE_DIR/colors-dark.properties" <<'EOF'
# Dark Color Scheme for Termux
background=#1e1e1e
foreground=#d4d4d4
cursor=#ffffff

color0=#000000
color1=#cd3131
color2=#0dbc79
color3=#e5e510
color4=#2472c8
color5=#bc3fbc
color6=#11a8cd
color7=#e5e5e5
color8=#666666
color9=#f14c4c
color10=#23d18b
color11=#f5f543
color12=#3b8eea
color13=#d670d6
color14=#29b8db
color15=#e5e5e5
EOF
    
    # Light color scheme
    cat > "$TERMUX_STYLE_DIR/colors-light.properties" <<'EOF'
# Light Color Scheme for Termux
background=#ffffff
foreground=#000000
cursor=#000000

color0=#000000
color1=#cd3131
color2=#00bc00
color3=#949800
color4=#0451a5
color5=#bc05bc
color6=#0598bc
color7=#555555
color8=#666666
color9=#cd3131
color10=#14ce14
color11=#b5ba00
color12=#0451a5
color13=#bc05bc
color14=#0598bc
color15=#a5a5a5
EOF
    
    # Dracula theme
    cat > "$TERMUX_STYLE_DIR/colors-dracula.properties" <<'EOF'
# Dracula Theme for Termux
background=#282a36
foreground=#f8f8f2
cursor=#f8f8f2

color0=#000000
color1=#ff5555
color2=#50fa7b
color3=#f1fa8c
color4=#bd93f9
color5=#ff79c6
color6=#8be9fd
color7=#bfbfbf
color8=#4d4d4d
color9=#ff6e67
color10=#5af78e
color11=#f4f99d
color12=#caa9fa
color13=#ff92d0
color14=#9aedfe
color15=#e6e6e6
EOF
    
    # Apply default dark theme
    ln -sf "$TERMUX_STYLE_DIR/colors-dark.properties" "$TERMUX_STYLE_DIR/colors.properties"
    
    # Create termux.properties for customization
    cat > "$TERMUX_STYLE_DIR/termux.properties" <<'EOF'
# Termux Properties - Customization Options

# Use black as background
# use-black-ui = true

# Hide soft keyboard
# hide-soft-keyboard-on-startup = true

# Fullscreen mode
fullscreen = true

# Use Volume keys as special keys
use-fullscreen-workaround = true

# Bell character
bell-character = beep

# Vibrate on bell
vibrate = true

# Terminal cursor style (block, underline, bar)
terminal-cursor-style = block

# Terminal cursor blink
terminal-cursor-blink-rate = 0

# Extra keys row
extra-keys = [ \
 ['ESC','/','-','HOME','UP','END','PGUP'], \
 ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN'] \
]
EOF
    
    log "Termux appearance customized!"
    info "Available color schemes: dark, light, dracula"
    info "To change: ln -sf ~/.termux/colors-[scheme].properties ~/.termux/colors.properties"
}

################################################################################
# Step 5: Install Development Tools
################################################################################

install_dev_tools() {
    if [ "$INSTALL_DEV_TOOLS" != "true" ]; then
        progress "Skipping development tools..."
        return
    fi
    
    progress "Installing development tools..."
    
    log "Installing programming languages..."
    pkg install -y \
        python \
        nodejs \
        golang \
        rust \
        ruby \
        php \
        perl >> "$LOG_FILE" 2>&1
    
    log "Installing build tools..."
    pkg install -y \
        clang \
        make \
        cmake \
        autoconf \
        automake \
        libtool \
        pkg-config >> "$LOG_FILE" 2>&1
    
    log "Installing version control..."
    pkg install -y git gh >> "$LOG_FILE" 2>&1
    
    log "Installing editors..."
    pkg install -y vim nano micro >> "$LOG_FILE" 2>&1
    
    log "Installing utilities..."
    pkg install -y \
        jq \
        yq \
        htop \
        tree \
        zip \
        unzip \
        tar \
        gzip >> "$LOG_FILE" 2>&1
    
    # Install Python packages
    log "Installing Python packages..."
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    pip install \
        requests \
        flask \
        django \
        numpy \
        pandas \
        jupyter >> "$LOG_FILE" 2>&1
    
    # Install Node.js packages
    log "Installing Node.js packages..."
    npm install -g \
        yarn \
        pm2 \
        typescript \
        eslint \
        prettier \
        nodemon >> "$LOG_FILE" 2>&1
    
    log "Development tools installed!"
}

################################################################################
# Step 6: Install Database Stack
################################################################################

install_databases() {
    if [ "$INSTALL_DATABASES" != "true" ]; then
        progress "Skipping databases..."
        return
    fi
    
    progress "Installing database stack..."
    
    log "Installing PostgreSQL..."
    pkg install -y postgresql >> "$LOG_FILE" 2>&1
    
    log "Installing MariaDB..."
    pkg install -y mariadb >> "$LOG_FILE" 2>&1
    
    log "Installing Redis..."
    pkg install -y redis >> "$LOG_FILE" 2>&1
    
    log "Installing MongoDB..."
    pkg install -y mongodb >> "$LOG_FILE" 2>&1 || warning "MongoDB may not be available on this architecture"
    
    # Initialize databases
    log "Initializing PostgreSQL..."
    mkdir -p "$HOME/.postgresql"
    initdb "$HOME/.postgresql/data" >> "$LOG_FILE" 2>&1 || true
    
    log "Initializing MariaDB..."
    mysql_install_db >> "$LOG_FILE" 2>&1 || true
    
    log "Database stack installed!"
}

################################################################################
# Step 7: Setup Termux:API
################################################################################

setup_termux_api() {
    if [ "$SETUP_TERMUX_API" != "true" ]; then
        progress "Skipping Termux:API setup..."
        return
    fi
    
    progress "Setting up Termux:API..."
    
    # Install Termux:API package
    pkg install -y termux-api >> "$LOG_FILE" 2>&1
    
    # Create API helper scripts
    mkdir -p "$HOME/bin"
    
    # Battery info script
    cat > "$HOME/bin/battery-info" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
termux-battery-status | jq '.'
EOF
    
    # Camera capture script
    cat > "$HOME/bin/camera-capture" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
OUTPUT="${1:-$HOME/storage/dcim/capture_$(date +%Y%m%d_%H%M%S).jpg}"
termux-camera-photo "$OUTPUT"
echo "Photo saved to: $OUTPUT"
EOF
    
    # Notification script
    cat > "$HOME/bin/notify" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
TITLE="${1:-Notification}"
MESSAGE="${2:-Message}"
termux-notification --title "$TITLE" --content "$MESSAGE"
EOF
    
    # Location script
    cat > "$HOME/bin/get-location" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
termux-location | jq '.'
EOF
    
    chmod +x "$HOME/bin"/*
    
    info "Termux:API scripts created in ~/bin/"
    info "Note: Install Termux:API app from F-Droid for full functionality"
    
    log "Termux:API setup complete!"
}

################################################################################
# Step 8: Setup Termux:Widget
################################################################################

setup_widgets() {
    if [ "$SETUP_WIDGETS" != "true" ]; then
        progress "Skipping widget setup..."
        return
    fi
    
    progress "Setting up Termux:Widget..."
    
    # Create widget scripts directory
    mkdir -p "$HOME/.shortcuts"
    
    # Quick commands widget
    cat > "$HOME/.shortcuts/quick-commands" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "=== Quick Commands ==="
echo "1. System Info"
echo "2. Battery Status"
echo "3. Start Acode"
echo "4. Start Databases"
echo "5. Network Info"
EOF
    
    # Start development environment widget
    cat > "$HOME/.shortcuts/start-dev" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Starting development environment..."
# Start databases
redis-server --daemonize yes
pg_ctl -D "$HOME/.postgresql/data" start
# Start Acode (if installed)
termux-open-url "acode://open"
EOF
    
    # Stop all services widget
    cat > "$HOME/.shortcuts/stop-all" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Stopping all services..."
redis-cli shutdown
pg_ctl -D "$HOME/.postgresql/data" stop
pkill -f node
pkill -f python
EOF
    
    chmod +x "$HOME/.shortcuts"/*
    
    info "Widget scripts created in ~/.shortcuts/"
    info "Note: Install Termux:Widget app from F-Droid to use widgets"
    
    log "Widget setup complete!"
}

################################################################################
# Step 9: Create Style Switcher
################################################################################

create_style_switcher() {
    progress "Creating style switcher utility..."
    
    cat > "$HOME/bin/termux-style" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash

STYLE_DIR="$HOME/.termux"

show_help() {
    echo "Termux Style Switcher"
    echo ""
    echo "Usage: termux-style [OPTION]"
    echo ""
    echo "Options:"
    echo "  dark      - Switch to dark theme"
    echo "  light     - Switch to light theme"
    echo "  dracula   - Switch to Dracula theme"
    echo "  list      - List available themes"
    echo "  font      - Change font"
    echo "  help      - Show this help"
}

list_themes() {
    echo "Available themes:"
    ls -1 "$STYLE_DIR"/colors-*.properties | sed 's/.*colors-/  - /' | sed 's/.properties//'
}

switch_theme() {
    local theme="$1"
    if [ -f "$STYLE_DIR/colors-$theme.properties" ]; then
        ln -sf "$STYLE_DIR/colors-$theme.properties" "$STYLE_DIR/colors.properties"
        echo "Switched to $theme theme"
        echo "Restart Termux to apply changes"
        termux-reload-settings
    else
        echo "Theme not found: $theme"
        list_themes
    fi
}

case "${1:-help}" in
    dark|light|dracula)
        switch_theme "$1"
        ;;
    list)
        list_themes
        ;;
    font)
        echo "Font management coming soon"
        ;;
    help|*)
        show_help
        ;;
esac
EOF
    
    chmod +x "$HOME/bin/termux-style"
    
    log "Style switcher created! Use: termux-style [dark|light|dracula]"
}

################################################################################
# Step 10: Create Quick Start Guide
################################################################################

create_quick_start() {
    progress "Creating quick start guide..."
    
    cat > "$HOME/TERMUX_QUICKSTART.md" <<'EOF'
# Termux + Acode Quick Start Guide

## Installed Components

### Acode IDE
- Configuration: ~/.acode-plugins/
- Plugins: ~/.acode-plugins/plugins/
- Themes: ~/.acode-plugins/themes/

### Development Tools
- Python, Node.js, Go, Rust, Ruby, PHP
- Git, GitHub CLI
- Vim, Nano, Micro editors

### Databases
- PostgreSQL: `pg_ctl -D ~/.postgresql/data start`
- MariaDB: `mysqld_safe &`
- Redis: `redis-server --daemonize yes`
- MongoDB: `mongod --fork --logpath ~/mongodb.log`

### Termux Customization
- Style switcher: `termux-style [dark|light|dracula]`
- Configuration: ~/.termux/termux.properties
- Colors: ~/.termux/colors.properties

## Quick Commands

### Start Development Environment
```bash
./bin/start-dev
```

### Change Termux Theme
```bash
termux-style dark    # Dark theme
termux-style light   # Light theme
termux-style dracula # Dracula theme
```

### Termux:API Commands
```bash
battery-info         # Show battery status
camera-capture      # Take photo
notify "Title" "Msg" # Send notification
get-location        # Get GPS location
```

### Widget Shortcuts
- Available in ~/.shortcuts/
- Use Termux:Widget app to add to home screen

## Customization

### Edit Termux Properties
```bash
nano ~/.termux/termux.properties
```

### Edit Color Scheme
```bash
nano ~/.termux/colors.properties
```

### Install Additional Packages
```bash
pkg search <package>
pkg install <package>
```

## Support
- Termux: https://termux.dev/docs
- Acode: https://acode.foxdebug.com
- Author: Alexander Mathey (xyalaxxx90@gmail.com)
EOF
    
    log "Quick start guide created: ~/TERMUX_QUICKSTART.md"
}

################################################################################
# Step 11: Setup Bashrc & Aliases
################################################################################

setup_bashrc() {
    progress "Setting up bash configuration..."
    
    # Backup existing bashrc
    [ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$HOME/.bashrc.backup"
    
    cat >> "$HOME/.bashrc" <<'EOF'

# ==============================================================================
# Termux + Acode Custom Configuration
# ==============================================================================

# Add bin to PATH
export PATH="$HOME/bin:$PATH"

# Aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Development aliases
alias py='python'
alias node='node'
alias npm='npm'
alias git='git'

# Database aliases
alias pg-start='pg_ctl -D ~/.postgresql/data start'
alias pg-stop='pg_ctl -D ~/.postgresql/data stop'
alias redis-start='redis-server --daemonize yes'
alias redis-stop='redis-cli shutdown'

# Termux aliases
alias theme='termux-style'
alias storage='cd ~/storage'
alias reload='termux-reload-settings'

# Custom prompt
PS1='\[\033[01;32m\]\u@termux\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Welcome message
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Termux + Acode Development Environment ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Quick commands:"
echo "  termux-style [dark|light|dracula]  - Change theme"
echo "  cat ~/TERMUX_QUICKSTART.md         - View guide"
echo ""
EOF
    
    log "Bash configuration updated!"
}

################################################################################
# Step 12: Final Setup & Verification
################################################################################

final_setup() {
    progress "Completing final setup..."
    
    # Reload Termux settings
    termux-reload-settings >> "$LOG_FILE" 2>&1 || true
    
    # Create desktop shortcuts info
    cat > "$HOME/INSTALL_NOTES.txt" <<EOF
================================================================================
Termux + Acode Installation Complete!
================================================================================

Installed Tools:
- Acode IDE (APK: ~/acode-latest.apk)
- Development tools: Python, Node.js, Go, Rust, Ruby, PHP
- Databases: PostgreSQL, MariaDB, Redis, MongoDB
- Termux:API integration
- Termux:Widget shortcuts

Customization:
- 3 color themes: dark, light, dracula
- Style switcher: termux-style [theme]
- Configuration: ~/.termux/termux.properties

Quick Start:
- Read guide: cat ~/TERMUX_QUICKSTART.md
- Change theme: termux-style dark
- Start dev env: ~/bin/start-dev

Additional Apps Needed (from F-Droid):
1. Termux:API - For API functionality
2. Termux:Widget - For home screen widgets
3. Acode - Code editor (install APK if not done)

Next Steps:
1. Restart Termux to apply all changes
2. Install Termux:API and Termux:Widget from F-Droid
3. Install Acode APK if not already installed
4. Customize appearance with: termux-style

Author: Alexander Mathey (xyalaxxx90@gmail.com)
Copyright: Elektronikx-Center-Matte ® ™
================================================================================
EOF
    
    log "Installation complete!"
    cat "$HOME/INSTALL_NOTES.txt"
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    show_banner
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  📝 Installation Details"
    echo -e "${CYAN}║${NC}  Log file: ${YELLOW}$LOG_FILE${NC}"
    echo -e "${CYAN}║${NC}  Install directory: ${YELLOW}$INSTALL_DIR${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    info "Starting comprehensive installation..."
    echo ""
    
    # Pre-installation checks
    check_termux
    
    # Installation steps
    setup_termux
    install_acode
    setup_acode_plugins
    customize_termux_style
    install_dev_tools
    install_databases
    setup_termux_api
    setup_widgets
    create_style_switcher
    create_quick_start
    setup_bashrc
    final_setup
    
    # Installation complete banner
    clear
    echo -e "${GREEN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║                     🎉 Installation Complete! 🎉                      ║
║                                                                       ║
║         Your Termux environment is now fully configured!             ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC} 📌 Important Next Steps:"
    echo -e "${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}   ${CYAN}1.${NC} 🔄 Restart Termux to apply all changes"
    echo -e "${YELLOW}║${NC}   ${CYAN}2.${NC} 📱 Install Termux:API and Termux:Widget from F-Droid"
    echo -e "${YELLOW}║${NC}   ${CYAN}3.${NC} 📦 Install Acode from: ${GREEN}~/acode-latest.apk${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ⚡ Quick Commands:"
    echo -e "${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}termux-style dark${NC}   - Switch to dark theme"
    echo -e "${CYAN}║${NC}   ${GREEN}termux-style light${NC}  - Switch to light theme"
    echo -e "${CYAN}║${NC}   ${GREEN}termux-style dracula${NC} - Switch to Dracula theme"
    echo -e "${CYAN}║${NC}   ${GREEN}cat ~/TERMUX_QUICKSTART.md${NC} - View complete guide"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${MAGENTA}${BOLD}✨ Enjoy your fully customized Termux + Acode environment! ✨${NC}"
    echo ""
}

# Run main installation
main "$@"
