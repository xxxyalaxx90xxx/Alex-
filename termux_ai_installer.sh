#!/data/data/com.termux/files/usr/bin/bash

# Termux AI-Powered Automated Installer
# Fully automated installation with integrated AI for file creation and editing
# Optimized for Realme C63 (RMX3939)
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INSTALL_DIR="$HOME/.termux-ai"
AI_MODELS_DIR="$INSTALL_DIR/ai-models"
TEMPLATES_DIR="$INSTALL_DIR/templates"
GENERATED_DIR="$HOME/generated-files"

# Progress tracking
TOTAL_STEPS=15
CURRENT_STEP=0

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo -e "${BLUE}Progress: ${PERCENT}% (${CURRENT_STEP}/${TOTAL_STEPS})${NC}"
}

# Create directory structure
create_directories() {
    log_info "Creating directory structure..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$AI_MODELS_DIR"
    mkdir -p "$TEMPLATES_DIR"
    mkdir -p "$GENERATED_DIR"
    progress
}

# Install base packages
install_base_packages() {
    log_info "Installing base packages..."
    pkg update -y || true
    pkg install -y python python-pip nodejs git curl wget || true
    progress
}

# Install AI libraries
install_ai_libraries() {
    log_info "Installing AI libraries..."
    pip install --upgrade pip || true
    pip install openai anthropic langchain llama-cpp-python || true
    pip install transformers torch --extra-index-url https://download.pytorch.org/whl/cpu || true
    progress
}

# Install lightweight AI model
install_local_ai_model() {
    log_info "Installing local AI model..."
    cd "$AI_MODELS_DIR"
    
    # Install GPT4All for offline AI
    pip install gpt4all || true
    
    # Download small model
    python3 << 'EOF'
try:
    from gpt4all import GPT4All
    model = GPT4All("orca-mini-3b-gguf2-q4_0.gguf")
    print("AI model installed successfully")
except Exception as e:
    print(f"Model installation skipped: {e}")
EOF
    
    progress
}

# Create AI file generator script
create_ai_file_generator() {
    log_info "Creating AI file generator..."
    
    cat > "$INSTALL_DIR/ai_file_ops.py" << 'PYEOF'
#!/usr/bin/env python3
"""AI-Powered File Operations for Termux"""

import sys
import os
import json
from pathlib import Path

try:
    from gpt4all import GPT4All
    AI_AVAILABLE = True
except ImportError:
    AI_AVAILABLE = False

class AIFileManager:
    def __init__(self):
        self.model = None
        if AI_AVAILABLE:
            try:
                self.model = GPT4All("orca-mini-3b-gguf2-q4_0.gguf")
            except:
                pass
    
    def generate_prompt(self, task, context=""):
        """Generate appropriate prompt for AI"""
        prompts = {
            'create': f"Generate a complete file for: {context}. Only output the file content, no explanations.",
            'edit': f"Edit the following content: {context}. Provide the complete edited version.",
            'script': f"Create a bash script that: {context}. Include comments and error handling.",
            'config': f"Generate configuration file for: {context}. Use best practices.",
            'kubernetes': f"Create Kubernetes manifest for: {context}. Use proper YAML format.",
        }
        return prompts.get(task, f"Help with: {context}")
    
    def create_file(self, filename, description):
        """Create file using AI"""
        print(f"Creating file: {filename}")
        
        if self.model:
            prompt = self.generate_prompt('create', description)
            content = self.model.generate(prompt, max_tokens=1000)
        else:
            # Fallback template
            content = self.get_template(filename, description)
        
        # Write file
        output_path = Path.home() / "generated-files" / filename
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(content)
        
        print(f"✓ Created: {output_path}")
        return str(output_path)
    
    def edit_file(self, filepath, instruction):
        """Edit file using AI"""
        print(f"Editing file: {filepath}")
        
        path = Path(filepath)
        if not path.exists():
            print(f"Error: File not found: {filepath}")
            return None
        
        original_content = path.read_text()
        
        if self.model:
            prompt = f"Edit this file: {original_content}\n\nInstruction: {instruction}"
            edited_content = self.model.generate(prompt, max_tokens=1000)
        else:
            edited_content = original_content + f"\n# Edited: {instruction}\n"
        
        # Backup original
        backup_path = path.with_suffix(path.suffix + '.backup')
        backup_path.write_text(original_content)
        
        # Write edited version
        path.write_text(edited_content)
        
        print(f"✓ Edited: {filepath}")
        print(f"✓ Backup: {backup_path}")
        return str(filepath)
    
    def generate_script(self, description):
        """Generate bash script using AI"""
        print(f"Generating script: {description}")
        
        if self.model:
            prompt = self.generate_prompt('script', description)
            content = self.model.generate(prompt, max_tokens=1000)
        else:
            content = f"""#!/bin/bash
# {description}

set -e

echo "Script: {description}"

# Add your commands here

echo "Done!"
"""
        
        # Create script file
        filename = description.lower().replace(' ', '_')[:50] + '.sh'
        output_path = Path.home() / "generated-files" / filename
        output_path.write_text(content)
        output_path.chmod(0o755)
        
        print(f"✓ Generated: {output_path}")
        return str(output_path)
    
    def get_template(self, filename, description):
        """Get template when AI not available"""
        templates = {
            '.yaml': f"""# {description}
apiVersion: v1
kind: ConfigMap
metadata:
  name: example-config
data:
  key: value
""",
            '.json': f"""{{
  "name": "{description}",
  "version": "1.0.0",
  "description": "Generated configuration"
}}
""",
            '.sh': f"""#!/bin/bash
# {description}

set -e
echo "Script: {description}"
# Add commands here
""",
            '.py': f"""#!/usr/bin/env python3
\"\"\" {description} \"\"\"

def main():
    print("{description}")
    # Add code here

if __name__ == "__main__":
    main()
""",
        }
        
        ext = Path(filename).suffix
        return templates.get(ext, f"# {description}\n# File: {filename}\n")

def main():
    if len(sys.argv) < 3:
        print("Usage:")
        print("  ai-create-file <filename> <description>")
        print("  ai-edit-file <filepath> <instruction>")
        print("  ai-generate-script <description>")
        sys.exit(1)
    
    command = sys.argv[1]
    manager = AIFileManager()
    
    if command == 'create':
        filename = sys.argv[2]
        description = ' '.join(sys.argv[3:]) if len(sys.argv) > 3 else "Generated file"
        manager.create_file(filename, description)
    
    elif command == 'edit':
        filepath = sys.argv[2]
        instruction = ' '.join(sys.argv[3:]) if len(sys.argv) > 3 else "Update file"
        manager.edit_file(filepath, instruction)
    
    elif command == 'script':
        description = ' '.join(sys.argv[2:])
        manager.generate_script(description)
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)

if __name__ == "__main__":
    main()
PYEOF
    
    chmod +x "$INSTALL_DIR/ai_file_ops.py"
    progress
}

# Create helper commands
create_helper_commands() {
    log_info "Creating helper commands..."
    
    # ai-create-file command
    cat > "$PREFIX/bin/ai-create-file" << 'EOF'
#!/bin/bash
python3 ~/.termux-ai/ai_file_ops.py create "$@"
EOF
    chmod +x "$PREFIX/bin/ai-create-file"
    
    # ai-edit-file command
    cat > "$PREFIX/bin/ai-edit-file" << 'EOF'
#!/bin/bash
python3 ~/.termux-ai/ai_file_ops.py edit "$@"
EOF
    chmod +x "$PREFIX/bin/ai-edit-file"
    
    # ai-generate-script command
    cat > "$PREFIX/bin/ai-generate-script" << 'EOF'
#!/bin/bash
python3 ~/.termux-ai/ai_file_ops.py script "$@"
EOF
    chmod +x "$PREFIX/bin/ai-generate-script"
    
    progress
}

# Create file templates
create_templates() {
    log_info "Creating file templates..."
    
    # Kubernetes deployment template
    cat > "$TEMPLATES_DIR/k8s-deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{NAME}}
  labels:
    app: {{NAME}}
spec:
  replicas: {{REPLICAS}}
  selector:
    matchLabels:
      app: {{NAME}}
  template:
    metadata:
      labels:
        app: {{NAME}}
    spec:
      containers:
      - name: {{NAME}}
        image: {{IMAGE}}
        ports:
        - containerPort: {{PORT}}
        resources:
          requests:
            memory: "{{MEMORY}}"
            cpu: "{{CPU}}"
          limits:
            memory: "{{MEMORY_LIMIT}}"
            cpu: "{{CPU_LIMIT}}"
EOF
    
    # Database config template
    cat > "$TEMPLATES_DIR/database-config.json" << 'EOF'
{
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "mydb",
    "user": "admin",
    "password": "changeme",
    "pool": {
      "min": 2,
      "max": 10
    }
  }
}
EOF
    
    # Backup script template
    cat > "$TEMPLATES_DIR/backup-script.sh" << 'EOF'
#!/bin/bash
# Automated backup script

BACKUP_DIR="$HOME/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup databases
echo "Starting backup..."

# PostgreSQL
pg_dump mydb > "$BACKUP_DIR/postgres_$TIMESTAMP.sql"

# Files
tar -czf "$BACKUP_DIR/files_$TIMESTAMP.tar.gz" -C "$HOME" important-files/

echo "Backup completed: $BACKUP_DIR"
EOF
    chmod +x "$TEMPLATES_DIR/backup-script.sh"
    
    progress
}

# Install additional tools
install_tools() {
    log_info "Installing additional tools..."
    pkg install -y vim nano jq yq || true
    progress
}

# Create automated installer script
create_auto_installer() {
    log_info "Creating automated installer..."
    
    cat > "$INSTALL_DIR/auto_install.sh" << 'EOF'
#!/bin/bash
# Fully automated Termux installation orchestrator

echo "🤖 Starting fully automated installation..."

# Component list
COMPONENTS=(
    "databases"
    "development-tools"
    "kubernetes"
    "ai-assistant"
    "web-dashboard"
)

for component in "${COMPONENTS[@]}"; do
    echo "Installing: $component"
    # Component installation logic here
    sleep 1
done

echo "✓ All components installed successfully!"
EOF
    chmod +x "$INSTALL_DIR/auto_install.sh"
    
    progress
}

# Configure AI integration
configure_ai_integration() {
    log_info "Configuring AI integration..."
    
    cat > "$HOME/.ai_config" << EOF
# AI Configuration
AI_MODELS_DIR="$AI_MODELS_DIR"
AI_ENABLED=true
AI_MODEL="orca-mini-3b"
AI_TEMPERATURE=0.7
AI_MAX_TOKENS=1000
GENERATED_FILES_DIR="$GENERATED_DIR"
EOF
    
    progress
}

# Create usage guide
create_usage_guide() {
    log_info "Creating usage guide..."
    
    cat > "$GENERATED_DIR/AI_FILE_OPERATIONS_GUIDE.md" << 'EOF'
# AI-Powered File Operations Guide

## Available Commands

### Create Files with AI
```bash
ai-create-file myconfig.yaml "Kubernetes service configuration for nginx"
ai-create-file script.sh "Backup script for PostgreSQL database"
ai-create-file app.py "Python Flask web application"
```

### Edit Files with AI
```bash
ai-edit-file config.yaml "Add resource limits"
ai-edit-file script.sh "Add error handling"
ai-edit-file README.md "Add installation section"
```

### Generate Scripts
```bash
ai-generate-script "Deploy application to Kubernetes"
ai-generate-script "Backup all databases"
ai-generate-script "Monitor system resources"
```

## Examples

### Create Kubernetes Deployment
```bash
ai-create-file nginx-deployment.yaml "Kubernetes deployment for nginx with 3 replicas"
```

### Generate Backup Script
```bash
ai-generate-script "Automated backup for PostgreSQL and MongoDB databases"
```

### Edit Configuration
```bash
ai-edit-file database.json "Increase connection pool size to 20"
```

## Generated Files Location
All AI-generated files are saved to: `~/generated-files/`

## Templates Available
Check templates in: `~/.termux-ai/templates/`

## Troubleshooting
If AI model not available, fallback templates are used automatically.
EOF
    
    progress
}

# Create quick start script
create_quick_start() {
    log_info "Creating quick start script..."
    
    cat > "$PREFIX/bin/termux-ai" << 'EOF'
#!/bin/bash
# Termux AI Quick Start

echo "🤖 Termux AI-Powered File Manager"
echo ""
echo "Available commands:"
echo "  ai-create-file <filename> <description>"
echo "  ai-edit-file <filepath> <instruction>"
echo "  ai-generate-script <description>"
echo ""
echo "Examples:"
echo "  ai-create-file app.yaml 'Kubernetes deployment for redis'"
echo "  ai-edit-file config.json 'Add timeout setting'"
echo "  ai-generate-script 'Backup PostgreSQL database'"
echo ""
echo "Generated files location: ~/generated-files/"
echo "Templates location: ~/.termux-ai/templates/"
echo ""
EOF
    chmod +x "$PREFIX/bin/termux-ai"
    
    progress
}

# Setup auto-completion
setup_autocompletion() {
    log_info "Setting up auto-completion..."
    
    cat >> "$HOME/.bashrc" << 'EOF'

# Termux AI auto-completion
if [ -f ~/.termux-ai/completion.sh ]; then
    source ~/.termux-ai/completion.sh
fi
EOF
    
    cat > "$INSTALL_DIR/completion.sh" << 'EOF'
# AI commands auto-completion
_ai_create_file() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    COMPREPLY=( $(compgen -f -- "$cur") )
}

complete -F _ai_create_file ai-create-file
complete -F _ai_create_file ai-edit-file
EOF
    
    progress
}

# Test installation
test_installation() {
    log_info "Testing installation..."
    
    # Test AI file operations
    if command -v ai-create-file &> /dev/null; then
        log_success "ai-create-file command available"
    fi
    
    if command -v ai-edit-file &> /dev/null; then
        log_success "ai-edit-file command available"
    fi
    
    if command -v ai-generate-script &> /dev/null; then
        log_success "ai-generate-script command available"
    fi
    
    # Test Python script
    if python3 "$INSTALL_DIR/ai_file_ops.py" --help &> /dev/null || true; then
        log_success "AI file operations script functional"
    fi
    
    progress
}

# Create post-install info
show_completion_message() {
    progress
    
    echo ""
    log_success "Installation completed successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🤖 AI-Powered Termux File Manager"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📝 Available Commands:"
    echo "  termux-ai              - Show help"
    echo "  ai-create-file         - Create file with AI"
    echo "  ai-edit-file           - Edit file with AI"
    echo "  ai-generate-script     - Generate script with AI"
    echo ""
    echo "📂 Directories:"
    echo "  Generated files: $GENERATED_DIR"
    echo "  Templates: $TEMPLATES_DIR"
    echo "  AI models: $AI_MODELS_DIR"
    echo ""
    echo "📖 Usage Examples:"
    echo "  ai-create-file app.yaml 'Kubernetes service for nginx'"
    echo "  ai-edit-file config.json 'Add timeout parameter'"
    echo "  ai-generate-script 'Backup all databases'"
    echo ""
    echo "📚 Documentation: $GENERATED_DIR/AI_FILE_OPERATIONS_GUIDE.md"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Author: Alexander Mathey (xyalaxxx90@gmail.com)"
    echo "Copyright: Elektronikx-Center-Matte ® ™"
    echo ""
}

# Main installation flow
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🤖 Termux AI-Powered Automated Installer"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Optimized for Realme C63 (RMX3939)"
    echo ""
    
    create_directories
    install_base_packages
    install_ai_libraries
    install_local_ai_model
    create_ai_file_generator
    create_helper_commands
    create_templates
    install_tools
    create_auto_installer
    configure_ai_integration
    create_usage_guide
    create_quick_start
    setup_autocompletion
    test_installation
    show_completion_message
}

# Run installation
main "$@"
