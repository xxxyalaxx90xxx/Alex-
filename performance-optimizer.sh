#!/data/data/com.termux/files/usr/bin/bash
#
# Xtreme XA-vI ® Performance Optimizer
# Maximale Geschwindigkeit für Realme c63 (RMX3939)
# By Alexander Mathey XAi-Cyborg ©®
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔════════════════════════════════════════════════╗
    ║    Xtreme XA-vI ® Performance Optimizer        ║
    ║    Realme c63 (RMX3939) Turbo Mode             ║
    ╚════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# System-Informationen
show_system_info() {
    log_info "System-Informationen:"
    echo ""
    
    # Device Info
    if command -v getprop &> /dev/null; then
        echo -e "${CYAN}Device:${NC} $(getprop ro.product.model 2>/dev/null || echo 'Unknown')"
        echo -e "${CYAN}Android:${NC} $(getprop ro.build.version.release 2>/dev/null || echo 'Unknown')"
        echo -e "${CYAN}SDK:${NC} $(getprop ro.build.version.sdk 2>/dev/null || echo 'Unknown')"
    fi
    
    # CPU Info
    if [ -f /proc/cpuinfo ]; then
        CPU_MODEL=$(cat /proc/cpuinfo | grep "Hardware" | head -n1 | cut -d: -f2 | xargs)
        [ -z "$CPU_MODEL" ] && CPU_MODEL=$(cat /proc/cpuinfo | grep "model name" | head -n1 | cut -d: -f2 | xargs)
        echo -e "${CYAN}CPU:${NC} $CPU_MODEL"
        
        CPU_CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
        echo -e "${CYAN}Cores:${NC} $CPU_CORES"
    fi
    
    # Memory Info
    if [ -f /proc/meminfo ]; then
        TOTAL_MEM=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
        FREE_MEM=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
        TOTAL_MEM_MB=$((TOTAL_MEM / 1024))
        FREE_MEM_MB=$((FREE_MEM / 1024))
        USED_MEM_MB=$((TOTAL_MEM_MB - FREE_MEM_MB))
        echo -e "${CYAN}Memory:${NC} ${USED_MEM_MB}MB / ${TOTAL_MEM_MB}MB (${FREE_MEM_MB}MB frei)"
    fi
    
    # Storage Info
    STORAGE=$(df -h $HOME | awk 'NR==2{printf "%s/%s (%s used)", $3,$2,$5}')
    echo -e "${CYAN}Storage:${NC} $STORAGE"
    
    # Termux Info
    if command -v termux-info &> /dev/null; then
        TERMUX_VERSION=$(termux-info | grep TERMUX_VERSION | cut -d= -f2 | tr -d '"')
        echo -e "${CYAN}Termux:${NC} $TERMUX_VERSION"
    fi
    
    echo ""
}

# Process-Priorität optimieren
optimize_process_priority() {
    log_info "Optimiere Process-Priorität..."
    
    # Nice-Level für aktuellen Shell-Prozess
    renice -n -10 -p $$ &> /dev/null || log_warning "Konnte Priorität nicht ändern (benötigt evtl. root)"
    
    log_success "Process-Priorität optimiert"
}

# Memory-Optimierung
optimize_memory() {
    log_info "Optimiere Memory..."
    
    # Swap-Check
    if [ -f "$HOME/swapfile" ]; then
        log_info "Swap-File gefunden"
        if ! swapon --show | grep -q "$HOME/swapfile"; then
            swapon "$HOME/swapfile" &> /dev/null && log_success "Swap aktiviert" || log_warning "Swap konnte nicht aktiviert werden"
        else
            log_success "Swap bereits aktiv"
        fi
    else
        log_warning "Kein Swap-File gefunden"
        log_info "Erstelle Swap-File (2GB)..."
        
        if command -v fallocate &> /dev/null; then
            fallocate -l 2G "$HOME/swapfile" && \
            chmod 600 "$HOME/swapfile" && \
            mkswap "$HOME/swapfile" && \
            swapon "$HOME/swapfile" && \
            log_success "Swap-File erstellt und aktiviert" || log_warning "Swap-Erstellung fehlgeschlagen"
        else
            log_warning "fallocate nicht verfügbar, überspringe Swap-Erstellung"
        fi
    fi
    
    log_success "Memory-Optimierung abgeschlossen"
}

# Netzwerk-Optimierung
optimize_network() {
    log_info "Optimiere Netzwerk..."
    
    # DNS-Server auf schnelle Server setzen
    cat > $PREFIX/etc/resolv.conf << 'EOF'
# Cloudflare DNS (schnell und privat)
nameserver 1.1.1.1
nameserver 1.0.0.1

# Google DNS (Fallback)
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
    
    log_success "DNS-Server optimiert (Cloudflare + Google)"
    
    # Git HTTP-Optimierung
    if command -v git &> /dev/null; then
        git config --global http.version HTTP/2
        git config --global http.postBuffer 524288000
        git config --global core.compression 0
        log_success "Git-Netzwerk optimiert"
    fi
}

# Package-Manager Optimierung
optimize_package_manager() {
    log_info "Optimiere Package-Manager..."
    
    # Apt/Pkg parallel downloads
    mkdir -p $PREFIX/etc/apt/apt.conf.d
    cat > $PREFIX/etc/apt/apt.conf.d/99parallel << 'EOF'
Acquire::Queue-Mode "host";
Acquire::http::Pipeline-Depth "5";
EOF
    
    log_success "Package-Manager optimiert"
}

# Cache aufräumen
clean_cache() {
    log_info "Räume Cache auf..."
    
    # Package cache
    if command -v pkg &> /dev/null; then
        pkg clean &> /dev/null || true
        log_success "Package-Cache gelöscht"
    fi
    
    # Pip cache
    if command -v pip &> /dev/null; then
        pip cache purge &> /dev/null || true
        log_success "Pip-Cache gelöscht"
    fi
    
    # npm cache
    if command -v npm &> /dev/null; then
        npm cache clean --force &> /dev/null || true
        log_success "npm-Cache gelöscht"
    fi
    
    # Temporäre Dateien
    rm -rf /tmp/* &> /dev/null || true
    rm -rf $HOME/.cache/* &> /dev/null || true
    
    log_success "Cache aufgeräumt"
}

# Turbo-Mode
enable_turbo_mode() {
    log_info "Aktiviere Turbo-Mode..."
    
    optimize_process_priority
    optimize_memory
    optimize_network
    optimize_package_manager
    
    log_success "Turbo-Mode aktiviert!"
}

# Performance-Test
run_performance_test() {
    log_info "Führe Performance-Test durch..."
    echo ""
    
    # CPU-Test (einfaches Benchmark)
    log_info "CPU-Test..."
    TIME_START=$(date +%s%N)
    for i in {1..100000}; do
        : # Leere Operation
    done
    TIME_END=$(date +%s%N)
    CPU_TIME=$(( (TIME_END - TIME_START) / 1000000 ))
    echo -e "${CYAN}CPU-Score:${NC} ${CPU_TIME}ms"
    
    # Memory-Test
    log_info "Memory-Test..."
    if [ -f /proc/meminfo ]; then
        AVAIL_MEM=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
        AVAIL_MEM_MB=$((AVAIL_MEM / 1024))
        echo -e "${CYAN}Verfügbarer RAM:${NC} ${AVAIL_MEM_MB}MB"
    fi
    
    # Disk-Test (Write-Speed)
    log_info "Disk-Test..."
    TIME_START=$(date +%s%N)
    dd if=/dev/zero of=/tmp/testfile bs=1M count=10 conv=fdatasync &> /dev/null
    TIME_END=$(date +%s%N)
    rm -f /tmp/testfile
    DISK_TIME=$(( (TIME_END - TIME_START) / 1000000 ))
    DISK_SPEED=$((10000 / DISK_TIME))
    echo -e "${CYAN}Write-Speed:${NC} ${DISK_SPEED}MB/s"
    
    # Netzwerk-Test
    log_info "Netzwerk-Test..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        PING_TIME=$(ping -c 4 8.8.8.8 | tail -1 | awk '{print $4}' | cut -d '/' -f 2)
        echo -e "${CYAN}Ping (Google DNS):${NC} ${PING_TIME}ms"
        log_success "Netzwerk aktiv"
    else
        log_warning "Netzwerk nicht erreichbar"
    fi
    
    echo ""
    log_success "Performance-Test abgeschlossen"
}

# Monitoring starten
start_monitoring() {
    log_info "Starte Monitoring (Ctrl+C zum Beenden)..."
    echo ""
    
    while true; do
        clear
        show_banner
        show_system_info
        
        echo -e "${CYAN}=== Top Processes ===${NC}"
        ps aux | head -n 6 | tail -n 5
        
        echo ""
        echo -e "${CYAN}=== Network ===${NC}"
        if command -v ifconfig &> /dev/null; then
            ifconfig 2>/dev/null | grep "inet " | head -n 2
        fi
        
        sleep 5
    done
}

# Hilfe anzeigen
show_help() {
    echo "Xtreme XA-vI Performance Optimizer"
    echo ""
    echo "Usage: performance-optimizer.sh [option]"
    echo ""
    echo "Options:"
    echo "  turbo       - Aktiviere Turbo-Mode (alle Optimierungen)"
    echo "  test        - Führe Performance-Test durch"
    echo "  clean       - Räume Cache auf"
    echo "  monitor     - Starte System-Monitoring"
    echo "  info        - Zeige System-Informationen"
    echo "  help        - Zeige diese Hilfe"
    echo ""
    echo "Beispiele:"
    echo "  ./performance-optimizer.sh turbo"
    echo "  ./performance-optimizer.sh test"
}

# Main
main() {
    case "${1:-turbo}" in
        turbo)
            show_banner
            show_system_info
            enable_turbo_mode
            ;;
        test)
            show_banner
            run_performance_test
            ;;
        clean)
            show_banner
            clean_cache
            ;;
        monitor)
            start_monitoring
            ;;
        info)
            show_banner
            show_system_info
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unbekannte Option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
