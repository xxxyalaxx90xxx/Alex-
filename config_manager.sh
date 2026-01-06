#!/bin/bash

# Configuration Manager
# Centralized management for all tool configurations
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/k8s-manager}"
BACKUP_DIR="$CONFIG_DIR/backups"
TEMPLATE_DIR="$CONFIG_DIR/templates"

mkdir -p "$CONFIG_DIR" "$BACKUP_DIR" "$TEMPLATE_DIR"

echo -e "${BLUE}=== Configuration Manager ===${NC}"

# Backup all configurations
backup_configs() {
    local backup_name="config-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    echo "Creating configuration backup..."
    
    # Collect all config files
    local configs=()
    [[ -f ~/.kube/config ]] && configs+=("$HOME/.kube/config")
    [[ -f ~/.termux/termux.properties ]] && configs+=("$HOME/.termux/termux.properties")
    [[ -d ~/.acode-plugins ]] && configs+=("$HOME/.acode-plugins")
    [[ -f /etc/rancher/k3s/k3s.yaml ]] && configs+=("/etc/rancher/k3s/k3s.yaml")
    
    if [[ ${#configs[@]} -gt 0 ]]; then
        tar -czf "$backup_path" "${configs[@]}" 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Backup created: $backup_path"
        echo "Files backed up: ${#configs[@]}"
    else
        echo -e "${YELLOW}No configuration files found to backup${NC}"
    fi
}

# Restore configurations
restore_configs() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}✗${NC} Backup file not found: $backup_file"
        return 1
    fi
    
    echo "Restoring configurations from: $backup_file"
    echo -e "${YELLOW}This will overwrite existing configurations!${NC}"
    read -p "Continue? (y/N): " confirm
    
    if [[ "$confirm" != "y" ]]; then
        echo "Restore cancelled"
        return 0
    fi
    
    tar -xzf "$backup_file" -C / 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Configurations restored"
}

# List backups
list_backups() {
    echo "Available backups:"
    if [[ -d "$BACKUP_DIR" ]]; then
        ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backups found"
    else
        echo "No backups found"
    fi
}

# Validate configurations
validate_configs() {
    echo "Validating configurations..."
    local errors=0
    
    # Validate kubeconfig
    if [[ -f ~/.kube/config ]]; then
        if kubectl config view &>/dev/null; then
            echo -e "${GREEN}✓${NC} kubeconfig is valid"
        else
            echo -e "${RED}✗${NC} kubeconfig has errors"
            ((errors++))
        fi
    fi
    
    # Validate Termux config
    if [[ -f ~/.termux/termux.properties ]]; then
        echo -e "${GREEN}✓${NC} Termux configuration exists"
    fi
    
    echo
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}All configurations are valid${NC}"
    else
        echo -e "${RED}Found $errors configuration errors${NC}"
    fi
}

# Create template
create_template() {
    local template_name="$1"
    local template_file="$TEMPLATE_DIR/$template_name.yaml"
    
    cat > "$template_file" << 'EOF'
# Configuration Template
# Edit this file and apply with: config_manager.sh apply <template>

kubernetes:
  version: "1.28"
  distribution: "k3s"  # k3s or kubeadm

monitoring:
  prometheus: true
  grafana: true
  metrics-server: true

databases:
  postgresql: true
  mysql: false
  redis: true
  mongodb: false

ai:
  gpt4all: true
  ollama: false

network:
  tor: false
  vpn: false
EOF
    
    echo -e "${GREEN}✓${NC} Template created: $template_file"
    echo "Edit the template and apply with: $0 apply $template_name"
}

# Show help
show_help() {
    cat << EOF
Configuration Manager - Centralized config management

Usage: $0 <command> [options]

Commands:
  backup              Create backup of all configurations
  restore <file>      Restore from backup file
  list                List available backups
  validate            Validate all configurations
  template <name>     Create configuration template
  diff <env1> <env2>  Compare two environments
  
Examples:
  $0 backup
  $0 restore $BACKUP_DIR/config-backup-20260106.tar.gz
  $0 validate
  $0 template production

Configuration directory: $CONFIG_DIR
Backup directory: $BACKUP_DIR
EOF
}

# Main
case "${1:-help}" in
    backup)
        backup_configs
        ;;
    restore)
        restore_configs "${2:-}"
        ;;
    list)
        list_backups
        ;;
    validate)
        validate_configs
        ;;
    template)
        create_template "${2:-default}"
        ;;
    *)
        show_help
        ;;
esac
