#!/data/data/com.termux/files/usr/bin/bash
#
# Xtreme XA-vI ® Server Manager
# Starte und verwalte verschiedene Development Server
# By Alexander Mathey XAi-Cyborg ©®
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

SERVERS_DIR="$HOME/.dev-servers"
PIDS_DIR="$SERVERS_DIR/pids"

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
    ║    Xtreme XA-vI ® Server Manager               ║
    ║    Development Server Control                  ║
    ╚════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Initialisierung
init_server_manager() {
    mkdir -p "$SERVERS_DIR" "$PIDS_DIR"
}

# HTTP Server starten (Python)
start_http_server() {
    local port="${1:-8000}"
    local directory="${2:-.}"
    
    log_info "Starte HTTP Server auf Port $port..."
    
    if command -v python &> /dev/null; then
        cd "$directory"
        python -m http.server "$port" > "$SERVERS_DIR/http_${port}.log" 2>&1 &
        echo $! > "$PIDS_DIR/http_${port}.pid"
        log_success "HTTP Server läuft auf http://localhost:$port"
        log_info "PID: $(cat $PIDS_DIR/http_${port}.pid)"
        log_info "Log: $SERVERS_DIR/http_${port}.log"
    else
        log_error "Python nicht installiert"
        return 1
    fi
}

# Node.js Server starten
start_node_server() {
    local port="${1:-3000}"
    local file="${2:-index.js}"
    
    log_info "Starte Node.js Server..."
    
    if command -v node &> /dev/null; then
        if [ ! -f "$file" ]; then
            log_error "Datei nicht gefunden: $file"
            return 1
        fi
        
        node "$file" > "$SERVERS_DIR/node_${port}.log" 2>&1 &
        echo $! > "$PIDS_DIR/node_${port}.pid"
        log_success "Node.js Server läuft auf Port $port"
        log_info "PID: $(cat $PIDS_DIR/node_${port}.pid)"
    else
        log_error "Node.js nicht installiert"
        return 1
    fi
}

# PHP Server starten
start_php_server() {
    local port="${1:-8080}"
    local directory="${2:-.}"
    
    log_info "Starte PHP Server auf Port $port..."
    
    if command -v php &> /dev/null; then
        cd "$directory"
        php -S "localhost:$port" > "$SERVERS_DIR/php_${port}.log" 2>&1 &
        echo $! > "$PIDS_DIR/php_${port}.pid"
        log_success "PHP Server läuft auf http://localhost:$port"
        log_info "PID: $(cat $PIDS_DIR/php_${port}.pid)"
    else
        log_error "PHP nicht installiert"
        return 1
    fi
}

# Nginx starten
start_nginx() {
    log_info "Starte Nginx..."
    
    if command -v nginx &> /dev/null; then
        nginx
        log_success "Nginx gestartet"
        log_info "Config: $PREFIX/etc/nginx/nginx.conf"
    else
        log_warning "Nginx nicht installiert"
        log_info "Installiere mit: pkg install nginx"
        return 1
    fi
}

# Redis starten
start_redis() {
    local port="${1:-6379}"
    
    log_info "Starte Redis auf Port $port..."
    
    if command -v redis-server &> /dev/null; then
        redis-server --port "$port" --daemonize yes \
            --logfile "$SERVERS_DIR/redis_${port}.log" \
            --pidfile "$PIDS_DIR/redis_${port}.pid"
        log_success "Redis läuft auf Port $port"
    else
        log_warning "Redis nicht installiert"
        log_info "Installiere mit: pkg install redis"
        return 1
    fi
}

# PostgreSQL starten
start_postgres() {
    log_info "Starte PostgreSQL..."
    
    if command -v pg_ctl &> /dev/null; then
        local pgdata="$PREFIX/var/lib/postgresql"
        
        if [ ! -d "$pgdata" ]; then
            log_info "Initialisiere PostgreSQL..."
            mkdir -p "$pgdata"
            initdb -D "$pgdata"
        fi
        
        pg_ctl -D "$pgdata" -l "$SERVERS_DIR/postgres.log" start
        log_success "PostgreSQL gestartet"
    else
        log_warning "PostgreSQL nicht installiert"
        log_info "Installiere mit: pkg install postgresql"
        return 1
    fi
}

# Server stoppen
stop_server() {
    local server_type="$1"
    local port="$2"
    
    local pid_file="$PIDS_DIR/${server_type}_${port}.pid"
    
    if [ ! -f "$pid_file" ]; then
        log_error "Server nicht gefunden: ${server_type} auf Port ${port}"
        return 1
    fi
    
    local pid=$(cat "$pid_file")
    
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        rm "$pid_file"
        log_success "Server gestoppt: ${server_type} (PID: $pid)"
    else
        log_warning "Server läuft nicht (PID: $pid)"
        rm "$pid_file"
    fi
}

# Alle Server stoppen
stop_all_servers() {
    log_info "Stoppe alle Server..."
    
    if [ -d "$PIDS_DIR" ]; then
        for pid_file in "$PIDS_DIR"/*.pid; do
            if [ -f "$pid_file" ]; then
                local pid=$(cat "$pid_file")
                local server_name=$(basename "$pid_file" .pid)
                
                if kill -0 "$pid" 2>/dev/null; then
                    kill "$pid"
                    log_success "Gestoppt: $server_name (PID: $pid)"
                fi
                rm "$pid_file"
            fi
        done
    fi
    
    # Nginx separat stoppen
    if command -v nginx &> /dev/null; then
        nginx -s stop 2>/dev/null && log_success "Nginx gestoppt"
    fi
    
    # PostgreSQL separat stoppen
    if command -v pg_ctl &> /dev/null; then
        pg_ctl -D "$PREFIX/var/lib/postgresql" stop 2>/dev/null && log_success "PostgreSQL gestoppt"
    fi
}

# Laufende Server anzeigen
list_servers() {
    log_info "Laufende Server:"
    echo ""
    
    local found=0
    
    if [ -d "$PIDS_DIR" ]; then
        for pid_file in "$PIDS_DIR"/*.pid; do
            if [ -f "$pid_file" ]; then
                local pid=$(cat "$pid_file")
                local server_name=$(basename "$pid_file" .pid)
                
                if kill -0 "$pid" 2>/dev/null; then
                    echo -e "${GREEN}●${NC} $server_name (PID: $pid)"
                    
                    # Port-Info anzeigen
                    if command -v netstat &> /dev/null; then
                        local port=$(netstat -tulpn 2>/dev/null | grep "$pid" | awk '{print $4}' | cut -d':' -f2 | head -1)
                        if [ ! -z "$port" ]; then
                            echo "  Port: $port"
                        fi
                    fi
                    found=1
                else
                    echo -e "${RED}○${NC} $server_name (nicht laufend)"
                    rm "$pid_file"
                fi
                echo ""
            fi
        done
    fi
    
    if [ $found -eq 0 ]; then
        log_warning "Keine laufenden Server gefunden"
    fi
}

# Server-Logs anzeigen
show_logs() {
    local server_type="$1"
    local port="$2"
    local lines="${3:-50}"
    
    local log_file="$SERVERS_DIR/${server_type}_${port}.log"
    
    if [ -f "$log_file" ]; then
        log_info "Letzte $lines Zeilen von ${server_type}_${port}:"
        echo ""
        tail -n "$lines" "$log_file"
    else
        log_error "Log-Datei nicht gefunden: $log_file"
    fi
}

# Server-Status
server_status() {
    log_info "Server-Status:"
    echo ""
    
    # Ports anzeigen
    if command -v netstat &> /dev/null; then
        log_info "Offene Ports:"
        netstat -tulpn 2>/dev/null | grep LISTEN | awk '{print "  " $4 " -> " $7}'
    fi
    
    echo ""
    list_servers
}

# Hilfe
show_help() {
    echo "Xtreme XA-vI Server Manager"
    echo ""
    echo "Usage: server-manager.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  start-http [port] [dir]     - Python HTTP Server"
    echo "  start-node [port] [file]    - Node.js Server"
    echo "  start-php [port] [dir]      - PHP Server"
    echo "  start-nginx                 - Nginx Web Server"
    echo "  start-redis [port]          - Redis Server"
    echo "  start-postgres              - PostgreSQL Server"
    echo "  stop <type> <port>          - Stoppe spezifischen Server"
    echo "  stop-all                    - Stoppe alle Server"
    echo "  list                        - Liste laufende Server"
    echo "  logs <type> <port> [lines]  - Zeige Server-Logs"
    echo "  status                      - Server-Status"
    echo "  help                        - Diese Hilfe"
    echo ""
    echo "Beispiele:"
    echo "  ./server-manager.sh start-http 8000"
    echo "  ./server-manager.sh start-node 3000 app.js"
    echo "  ./server-manager.sh stop http 8000"
    echo "  ./server-manager.sh logs http 8000 100"
}

# Main
main() {
    init_server_manager
    
    case "${1:-help}" in
        start-http)
            show_banner
            start_http_server "$2" "$3"
            ;;
        start-node)
            show_banner
            start_node_server "$2" "$3"
            ;;
        start-php)
            show_banner
            start_php_server "$2" "$3"
            ;;
        start-nginx)
            show_banner
            start_nginx
            ;;
        start-redis)
            show_banner
            start_redis "$2"
            ;;
        start-postgres)
            show_banner
            start_postgres
            ;;
        stop)
            show_banner
            stop_server "$2" "$3"
            ;;
        stop-all)
            show_banner
            stop_all_servers
            ;;
        list)
            show_banner
            list_servers
            ;;
        logs)
            show_banner
            show_logs "$2" "$3" "$4"
            ;;
        status)
            show_banner
            server_status
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
