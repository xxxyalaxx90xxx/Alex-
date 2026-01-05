#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XA-vI v4.0 Extended+ - Automation Suite
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey (xyalaxxx90@gmail.com)
# Task Automation & Scripting Framework
# ==============================================================================

set -euo pipefail

# Farben
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_DIR="$HOME/xtreme_ai_system"
AUTOMATION_DIR="$INSTALL_DIR/automation"
TASKS_DIR="$AUTOMATION_DIR/tasks"
LOGS_DIR="$AUTOMATION_DIR/logs"

# ==============================================================================
# BANNER
# ==============================================================================
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                  ⚙️  AUTOMATION SUITE  ⚙️                        ║
║                                                                  ║
║          XTREME XA-vI Task Automation Framework                  ║
║          © Elektronikx-Center-Matte ® | Cyborg System           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ==============================================================================
# LOGGING
# ==============================================================================
success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${CYAN}ℹ${NC} $1"; }

log_task() {
    local task_name=$1
    local status=$2
    local log_file="$LOGS_DIR/task_$(date +%Y%m%d).log"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $task_name - $status" >> "$log_file"
}

# ==============================================================================
# TASK TEMPLATES
# ==============================================================================
create_backup_task() {
    local task_name=$1
    local task_file="$TASKS_DIR/${task_name}.sh"
    
    cat > "$task_file" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Automatischer Backup-Task
BACKUP_DIR="$HOME/xtreme_ai_system/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

tar -czf "$BACKUP_DIR/auto_backup_$TIMESTAMP.tar.gz" \
    "$HOME/xtreme_ai_system/projects" \
    "$HOME/xtreme_ai_system/data"

# Alte Backups löschen (älter als 7 Tage)
find "$BACKUP_DIR" -name "auto_backup_*.tar.gz" -mtime +7 -delete

echo "Backup erstellt: auto_backup_$TIMESTAMP.tar.gz"
EOF
    
    chmod +x "$task_file"
    success "Backup-Task erstellt: $task_name"
}

create_cleanup_task() {
    local task_name=$1
    local task_file="$TASKS_DIR/${task_name}.sh"
    
    cat > "$task_file" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Automatischer Cleanup-Task

# Cache bereinigen
rm -rf "$HOME/xtreme_ai_system/data/cache"/*
rm -rf "$HOME/xtreme_ai_system/data/temp"/*

# Package Caches
pkg clean
pip cache purge 2>/dev/null
npm cache clean --force 2>/dev/null

# Alte Logs komprimieren
find "$HOME/xtreme_ai_system/logs" -name "*.log" -mtime +7 -exec gzip {} \;

echo "Cleanup abgeschlossen"
EOF
    
    chmod +x "$task_file"
    success "Cleanup-Task erstellt: $task_name"
}

create_monitoring_task() {
    local task_name=$1
    local task_file="$TASKS_DIR/${task_name}.sh"
    
    cat > "$task_file" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Automatischer Monitoring-Task

LOG_FILE="$HOME/xtreme_ai_system/logs/monitoring_$(date +%Y%m%d).log"

{
    echo "=== Monitoring Report $(date) ==="
    echo ""
    
    # CPU
    echo "CPU Load:"
    cat /proc/loadavg
    echo ""
    
    # RAM
    echo "Memory:"
    free -h
    echo ""
    
    # Disk
    echo "Disk Usage:"
    df -h "$HOME"
    echo ""
    
    # Processes
    echo "Top Processes:"
    ps aux | head -10
    
} >> "$LOG_FILE"

echo "Monitoring-Daten gespeichert"
EOF
    
    chmod +x "$task_file"
    success "Monitoring-Task erstellt: $task_name"
}

create_update_task() {
    local task_name=$1
    local task_file="$TASKS_DIR/${task_name}.sh"
    
    cat > "$task_file" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Automatischer Update-Task

# System Updates
pkg update && pkg upgrade -y

# Python Packages
pip install --upgrade pip
pip list --outdated | tail -n +3 | awk '{print $1}' | xargs -n1 pip install -U

# Node.js Packages (global)
npm update -g

echo "Updates abgeschlossen"
EOF
    
    chmod +x "$task_file"
    success "Update-Task erstellt: $task_name"
}

create_custom_task() {
    local task_name=$1
    local task_file="$TASKS_DIR/${task_name}.sh"
    
    cat > "$task_file" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Custom Task - Editiere diesen Task nach deinen Wünschen

echo "Custom Task ausgeführt: $(date)"

# Dein Code hier...

EOF
    
    chmod +x "$task_file"
    success "Custom-Task erstellt: $task_name"
    info "Bearbeite: $task_file"
}

# ==============================================================================
# TASK EXECUTION
# ==============================================================================
run_task() {
    local task_file=$1
    local task_name=$(basename "$task_file" .sh)
    
    info "Führe Task aus: $task_name"
    
    if [ ! -f "$task_file" ]; then
        error "Task nicht gefunden: $task_file"
        log_task "$task_name" "FAILED - Not found"
        return 1
    fi
    
    if ! bash "$task_file" 2>&1 | tee -a "$LOGS_DIR/${task_name}_$(date +%Y%m%d_%H%M%S).log"; then
        error "Task fehlgeschlagen: $task_name"
        log_task "$task_name" "FAILED"
        return 1
    fi
    
    success "Task abgeschlossen: $task_name"
    log_task "$task_name" "SUCCESS"
}

run_all_tasks() {
    info "Führe alle Tasks aus..."
    
    for task in "$TASKS_DIR"/*.sh; do
        if [ -f "$task" ]; then
            run_task "$task"
            echo ""
        fi
    done
    
    success "Alle Tasks abgeschlossen"
}

# ==============================================================================
# SCHEDULER
# ==============================================================================
schedule_task() {
    local task_name=$1
    local schedule=$2
    
    info "Plane Task '$task_name' mit Zeitplan: $schedule"
    
    # Termux:API Reminder erstellen (Hinweis)
    cat << EOF

Für Scheduling verwende eine dieser Optionen:

1. Termux:Boot + Cron:
   - pkg install termux-services
   - sv-enable crond
   - crontab -e
   - Füge hinzu: $schedule bash $TASKS_DIR/${task_name}.sh

2. Termux:API:
   - pkg install termux-api
   - termux-notification mit Timer
   
3. Tasker App:
   - Intent an Termux senden
   - Plugin: Termux:Task

Beispiel Cron-Syntax:
  */30 * * * *  - Alle 30 Minuten
  0 */6 * * *   - Alle 6 Stunden
  0 2 * * *     - Täglich um 2:00 Uhr
  0 0 * * 0     - Jeden Sonntag um Mitternacht

EOF
}

# ==============================================================================
# WORKFLOW BUILDER
# ==============================================================================
create_workflow() {
    local workflow_name=$1
    local workflow_file="$AUTOMATION_DIR/workflows/${workflow_name}.workflow"
    
    mkdir -p "$AUTOMATION_DIR/workflows"
    
    cat > "$workflow_file" << 'EOF'
# Workflow Definition
# Format: task_name | condition | on_success | on_failure

# Beispiel:
# backup | always | notify_success | notify_failure
# cleanup | after:backup | - | log_error
# monitoring | schedule:*/30 | - | -

EOF
    
    success "Workflow erstellt: $workflow_name"
    info "Bearbeite: $workflow_file"
}

run_workflow() {
    local workflow_file=$1
    
    info "Führe Workflow aus: $(basename "$workflow_file")"
    
    while IFS='|' read -r task condition on_success on_failure; do
        # Skip Kommentare und leere Zeilen
        [[ "$task" =~ ^#.*$ ]] && continue
        [[ -z "$task" ]] && continue
        
        task=$(echo "$task" | tr -d ' ')
        
        info "Task: $task"
        
        if run_task "$TASKS_DIR/${task}.sh"; then
            [ -n "$on_success" ] && info "Success: $on_success"
        else
            [ -n "$on_failure" ] && warn "Failure: $on_failure"
        fi
    done < "$workflow_file"
}

# ==============================================================================
# TASK MANAGEMENT
# ==============================================================================
list_tasks() {
    info "Verfügbare Tasks:"
    echo ""
    
    if [ -d "$TASKS_DIR" ]; then
        for task in "$TASKS_DIR"/*.sh; do
            if [ -f "$task" ]; then
                local name=$(basename "$task" .sh)
                echo -e "${GREEN}▸${NC} $name"
                
                # Erste Kommentarzeile anzeigen
                local desc=$(grep "^#" "$task" | head -1 | sed 's/^# //')
                [ -n "$desc" ] && echo "  $desc"
            fi
        done
    else
        warn "Keine Tasks gefunden"
    fi
}

edit_task() {
    local task_name=$1
    local task_file="$TASKS_DIR/${task_name}.sh"
    
    if [ ! -f "$task_file" ]; then
        error "Task nicht gefunden: $task_name"
        return 1
    fi
    
    "${EDITOR:-nano}" "$task_file"
}

delete_task() {
    local task_name=$1
    local task_file="$TASKS_DIR/${task_name}.sh"
    
    if [ ! -f "$task_file" ]; then
        error "Task nicht gefunden: $task_name"
        return 1
    fi
    
    warn "Lösche Task '$task_name'..."
    read -p "Sicher? (j/N): " -r
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        rm "$task_file"
        success "Task gelöscht"
    fi
}

# ==============================================================================
# HAUPTMENÜ
# ==============================================================================
main_menu() {
    while true; do
        show_banner
        
        echo -e "${WHITE}${BOLD}Task-Vorlagen:${NC}"
        echo "  1) Backup-Task erstellen"
        echo "  2) Cleanup-Task erstellen"
        echo "  3) Monitoring-Task erstellen"
        echo "  4) Update-Task erstellen"
        echo "  5) Custom-Task erstellen"
        echo ""
        echo -e "${WHITE}${BOLD}Task-Ausführung:${NC}"
        echo "  6) Task ausführen"
        echo "  7) Alle Tasks ausführen"
        echo "  8) Tasks auflisten"
        echo "  9) Task bearbeiten"
        echo " 10) Task löschen"
        echo ""
        echo -e "${WHITE}${BOLD}Erweitert:${NC}"
        echo " 11) Task planen (Scheduler Info)"
        echo " 12) Workflow erstellen"
        echo " 13) Workflow ausführen"
        echo " 14) Logs anzeigen"
        echo ""
        echo "  0) Beenden"
        echo ""
        read -p "Auswahl: " choice
        
        case $choice in
            1)
                read -p "Task-Name: " name
                create_backup_task "$name"
                ;;
            2)
                read -p "Task-Name: " name
                create_cleanup_task "$name"
                ;;
            3)
                read -p "Task-Name: " name
                create_monitoring_task "$name"
                ;;
            4)
                read -p "Task-Name: " name
                create_update_task "$name"
                ;;
            5)
                read -p "Task-Name: " name
                create_custom_task "$name"
                ;;
            6)
                list_tasks
                echo ""
                read -p "Task-Name: " name
                run_task "$TASKS_DIR/${name}.sh"
                ;;
            7) run_all_tasks ;;
            8) list_tasks ;;
            9)
                list_tasks
                echo ""
                read -p "Task-Name: " name
                edit_task "$name"
                ;;
            10)
                list_tasks
                echo ""
                read -p "Task-Name: " name
                delete_task "$name"
                ;;
            11)
                read -p "Task-Name: " name
                read -p "Zeitplan (Cron): " schedule
                schedule_task "$name" "$schedule"
                ;;
            12)
                read -p "Workflow-Name: " name
                create_workflow "$name"
                ;;
            13)
                echo "Verfügbare Workflows:"
                ls "$AUTOMATION_DIR/workflows"/*.workflow 2>/dev/null || echo "Keine"
                echo ""
                read -p "Workflow-Name: " name
                run_workflow "$AUTOMATION_DIR/workflows/${name}.workflow"
                ;;
            14)
                echo "Letzte Logs:"
                tail -50 "$LOGS_DIR"/task_*.log 2>/dev/null || echo "Keine Logs"
                ;;
            0) break ;;
            *) error "Ungültige Auswahl" ;;
        esac
        
        echo ""
        read -p "Drücke Enter zum Fortfahren..."
    done
}

# ==============================================================================
# INITIALISIERUNG
# ==============================================================================
init() {
    mkdir -p "$AUTOMATION_DIR"/{tasks,workflows,logs}
}

# ==============================================================================
# MAIN
# ==============================================================================
init
main_menu
