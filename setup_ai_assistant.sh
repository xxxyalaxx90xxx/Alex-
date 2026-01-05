#!/bin/bash

# AI Integration System for Kubernetes
# Provides AI-powered assistance, analysis, and automation
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
AI_DIR="${HOME}/.k8s-ai"
MODELS_DIR="${AI_DIR}/models"
CONFIG_FILE="${AI_DIR}/config.yaml"
INSTALL_GPT4ALL="${INSTALL_GPT4ALL:-true}"
INSTALL_OLLAMA="${INSTALL_OLLAMA:-true}"
INSTALL_LLAMA="${INSTALL_LLAMA:-true}"

# Print functions
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Check dependencies
check_dependencies() {
    print_header "Checking Dependencies"
    
    local deps=("python3" "pip3" "curl" "git")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            print_success "$dep is installed"
        else
            print_error "$dep is missing"
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_warning "Installing missing dependencies..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y python3 python3-pip curl git
        elif command -v pkg &> /dev/null; then
            pkg update && pkg install -y python pip curl git
        else
            print_error "Cannot install dependencies automatically"
            exit 1
        fi
    fi
}

# Create directory structure
setup_directories() {
    print_header "Setting Up Directories"
    
    mkdir -p "${AI_DIR}"
    mkdir -p "${MODELS_DIR}"
    mkdir -p "${AI_DIR}/logs"
    mkdir -p "${AI_DIR}/cache"
    mkdir -p "${AI_DIR}/configs"
    
    print_success "Directory structure created"
}

# Install Python packages
install_python_packages() {
    print_header "Installing Python AI Packages"
    
    print_info "Installing transformers and dependencies..."
    pip3 install --user transformers torch torchvision accelerate
    
    print_info "Installing LangChain for AI workflows..."
    pip3 install --user langchain langchain-community
    
    print_info "Installing vector database..."
    pip3 install --user chromadb faiss-cpu
    
    print_info "Installing AI utilities..."
    pip3 install --user openai anthropic
    
    print_info "Installing analysis tools..."
    pip3 install --user pandas numpy scikit-learn
    
    print_success "Python packages installed"
}

# Install GPT4All
install_gpt4all() {
    if [ "$INSTALL_GPT4ALL" != "true" ]; then
        print_info "Skipping GPT4All installation"
        return
    fi
    
    print_header "Installing GPT4All"
    
    pip3 install --user gpt4all
    
    # Download a small model
    print_info "Downloading GPT4All model (this may take a while)..."
    python3 -c "
from gpt4all import GPT4All
import os
os.makedirs('${MODELS_DIR}', exist_ok=True)
model = GPT4All('orca-mini-3b-gguf2-q4_0.gguf', model_path='${MODELS_DIR}')
print('Model downloaded successfully')
"
    
    print_success "GPT4All installed"
}

# Install Ollama
install_ollama() {
    if [ "$INSTALL_OLLAMA" != "true" ]; then
        print_info "Skipping Ollama installation"
        return
    fi
    
    print_header "Installing Ollama"
    
    if command -v ollama &> /dev/null; then
        print_success "Ollama already installed"
        return
    fi
    
    # Install Ollama
    curl -fsSL https://ollama.ai/install.sh | sh
    
    # Pull a small model
    print_info "Pulling Ollama model..."
    ollama pull tinyllama
    
    print_success "Ollama installed"
}

# Install LLaMA.cpp
install_llama_cpp() {
    if [ "$INSTALL_LLAMA" != "true" ]; then
        print_info "Skipping LLaMA.cpp installation"
        return
    fi
    
    print_header "Installing LLaMA.cpp"
    
    cd "${AI_DIR}"
    
    if [ ! -d "llama.cpp" ]; then
        git clone https://github.com/ggerganov/llama.cpp.git
        cd llama.cpp
        make
        print_success "LLaMA.cpp compiled"
    else
        print_success "LLaMA.cpp already installed"
    fi
}

# Create AI assistant script
create_ai_assistant() {
    print_header "Creating AI Assistant Scripts"
    
    # Main AI assistant
    cat > "${HOME}/bin/ai-assistant" << 'EOF'
#!/usr/bin/env python3
import sys
import os
from gpt4all import GPT4All

def main():
    if len(sys.argv) < 2:
        print("Usage: ai-assistant <question>")
        sys.exit(1)
    
    question = " ".join(sys.argv[1:])
    
    model_path = os.path.expanduser("~/.k8s-ai/models")
    model = GPT4All('orca-mini-3b-gguf2-q4_0.gguf', model_path=model_path)
    
    # Context for Kubernetes
    context = """You are a helpful Kubernetes assistant. Answer questions about 
    Kubernetes clusters, troubleshooting, performance, and best practices."""
    
    prompt = f"{context}\n\nQuestion: {question}\nAnswer:"
    
    print("\n" + "="*60)
    print("AI Assistant Response:")
    print("="*60 + "\n")
    
    response = model.generate(prompt, max_tokens=500)
    print(response)
    print()

if __name__ == "__main__":
    main()
EOF
    
    chmod +x "${HOME}/bin/ai-assistant"
    
    # Cluster analysis script
    cat > "${HOME}/bin/ai-analyze-cluster" << 'EOF'
#!/bin/bash
# AI-powered cluster analysis

echo "🤖 AI Cluster Analysis"
echo "======================="
echo

# Get cluster info
kubectl cluster-info > /tmp/cluster-info.txt 2>&1
kubectl get nodes -o wide > /tmp/nodes.txt 2>&1
kubectl get pods --all-namespaces > /tmp/pods.txt 2>&1
kubectl top nodes > /tmp/resources.txt 2>&1

# Analyze with AI
ai-assistant "Analyze this Kubernetes cluster and provide recommendations: $(cat /tmp/cluster-info.txt /tmp/nodes.txt /tmp/pods.txt /tmp/resources.txt)"

rm -f /tmp/cluster-info.txt /tmp/nodes.txt /tmp/pods.txt /tmp/resources.txt
EOF
    
    chmod +x "${HOME}/bin/ai-analyze-cluster"
    
    # Documentation generator
    cat > "${HOME}/bin/ai-docs-generate" << 'EOF'
#!/bin/bash
# Generate documentation using AI

if [ -z "$1" ]; then
    echo "Usage: ai-docs-generate <directory>"
    exit 1
fi

echo "📝 Generating documentation for $1..."

for file in "$1"/*.sh; do
    if [ -f "$file" ]; then
        echo "Processing $(basename "$file")..."
        content=$(cat "$file")
        ai-assistant "Generate comprehensive documentation for this bash script: $content" > "${file}.md"
    fi
done

echo "✓ Documentation generated"
EOF
    
    chmod +x "${HOME}/bin/ai-docs-generate"
    
    # Troubleshooting assistant
    cat > "${HOME}/bin/ai-troubleshoot" << 'EOF'
#!/bin/bash
# AI-powered troubleshooting

echo "🔧 AI Troubleshooting Assistant"
echo "================================"
echo

# Gather diagnostic info
echo "Gathering cluster diagnostics..."

diagnostics=""
diagnostics+="NODES:\n$(kubectl get nodes 2>&1)\n\n"
diagnostics+="PODS:\n$(kubectl get pods --all-namespaces 2>&1)\n\n"
diagnostics+="EVENTS:\n$(kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20 2>&1)\n\n"

if [ -n "$1" ]; then
    diagnostics+="SPECIFIC ISSUE: $1\n\n"
fi

# Analyze
ai-assistant "You are a Kubernetes expert. Analyze these diagnostics and suggest solutions: $diagnostics"
EOF
    
    chmod +x "${HOME}/bin/ai-troubleshoot"
    
    print_success "AI assistant scripts created"
}

# Create configuration file
create_config() {
    print_header "Creating Configuration"
    
    cat > "${CONFIG_FILE}" << EOF
# AI Integration Configuration
ai:
  models:
    gpt4all:
      enabled: ${INSTALL_GPT4ALL}
      model: orca-mini-3b-gguf2-q4_0.gguf
      path: ${MODELS_DIR}
    ollama:
      enabled: ${INSTALL_OLLAMA}
      model: tinyllama
    llama_cpp:
      enabled: ${INSTALL_LLAMA}
      path: ${AI_DIR}/llama.cpp
  
  features:
    cluster_analysis: true
    troubleshooting: true
    documentation: true
    recommendations: true
    
  logging:
    level: info
    path: ${AI_DIR}/logs
EOF
    
    print_success "Configuration created"
}

# Test AI system
test_ai_system() {
    print_header "Testing AI System"
    
    print_info "Testing AI assistant..."
    if command -v ai-assistant &> /dev/null; then
        ai-assistant "What is Kubernetes?" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_success "AI assistant test passed"
        else
            print_warning "AI assistant test had issues (may need model download)"
        fi
    else
        print_error "AI assistant command not found"
    fi
}

# Print usage information
print_usage() {
    print_header "AI Integration Complete!"
    
    echo
    echo -e "${GREEN}Available Commands:${NC}"
    echo -e "  ${CYAN}ai-assistant <question>${NC}         - Ask AI anything about K8s"
    echo -e "  ${CYAN}ai-analyze-cluster${NC}             - AI-powered cluster analysis"
    echo -e "  ${CYAN}ai-troubleshoot [issue]${NC}        - AI troubleshooting help"
    echo -e "  ${CYAN}ai-docs-generate <dir>${NC}         - Generate documentation"
    echo
    echo -e "${GREEN}Examples:${NC}"
    echo -e "  ai-assistant \"How do I scale a deployment?\""
    echo -e "  ai-analyze-cluster"
    echo -e "  ai-troubleshoot \"pods are crashing\""
    echo -e "  ai-docs-generate ./scripts"
    echo
    echo -e "${YELLOW}Configuration:${NC} ${CONFIG_FILE}"
    echo -e "${YELLOW}Models Directory:${NC} ${MODELS_DIR}"
    echo
}

# Main installation
main() {
    print_header "AI Integration System Setup"
    echo -e "${MAGENTA}Author: Alexander Mathey (xyalaxxx90@gmail.com)${NC}"
    echo -e "${MAGENTA}Copyright: Elektronikx-Center-Matte ® ™${NC}"
    echo
    
    # Create bin directory if it doesn't exist
    mkdir -p "${HOME}/bin"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":${HOME}/bin:"* ]]; then
        echo 'export PATH="${HOME}/bin:$PATH"' >> "${HOME}/.bashrc"
        export PATH="${HOME}/bin:$PATH"
    fi
    
    check_dependencies
    setup_directories
    install_python_packages
    install_gpt4all
    install_ollama
    install_llama_cpp
    create_ai_assistant
    create_config
    test_ai_system
    print_usage
    
    print_success "AI Integration complete!"
}

main "$@"
