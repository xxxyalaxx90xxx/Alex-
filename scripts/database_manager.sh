#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XA-vI v4.0 Pro - Database Manager
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey (xyalaxxx90@gmail.com)
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
DB_DIR="$INSTALL_DIR/databases"
LOG_FILE="$INSTALL_DIR/logs/database_$(date +%Y%m%d).log"

# ==============================================================================
# BANNER
# ==============================================================================
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║              🗄️  DATABASE MANAGER v4.0 Pro                      ║
║                                                                  ║
║         PostgreSQL | MySQL | MongoDB | Redis | SQLite          ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║  © Elektronikx-Center-Matte ®                                   ║
║  Cyborg System by Alexander Mathey                              ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ==============================================================================
# LOGGING
# ==============================================================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# ==============================================================================
# POSTGRESQL MANAGEMENT
# ==============================================================================
install_postgresql() {
    info "Installiere PostgreSQL..."
    
    pkg install -y postgresql 2>&1 | tee -a "$LOG_FILE"
    
    mkdir -p "$DB_DIR/postgresql"
    
    if [ ! -d "$DB_DIR/postgresql/data" ]; then
        initdb "$DB_DIR/postgresql/data"
        success "PostgreSQL initialisiert"
    fi
    
    # Konfiguration
    cat > "$DB_DIR/postgresql/start.sh" << 'PGSTART'
#!/data/data/com.termux/files/usr/bin/bash
pg_ctl -D ~/xtreme_ai_system/databases/postgresql/data -l ~/xtreme_ai_system/logs/postgresql.log start
echo "PostgreSQL gestartet auf Port 5432"
echo "Verbinden: psql -h localhost -U $USER"
PGSTART
    
    cat > "$DB_DIR/postgresql/stop.sh" << 'PGSTOP'
#!/data/data/com.termux/files/usr/bin/bash
pg_ctl -D ~/xtreme_ai_system/databases/postgresql/data stop
echo "PostgreSQL gestoppt"
PGSTOP
    
    chmod +x "$DB_DIR/postgresql"/*.sh
    
    success "PostgreSQL installiert"
    info "Start: bash $DB_DIR/postgresql/start.sh"
    info "Stop: bash $DB_DIR/postgresql/stop.sh"
}

manage_postgresql() {
    echo ""
    echo -e "${CYAN}=== PostgreSQL Manager ===${NC}"
    echo ""
    echo "1) PostgreSQL starten"
    echo "2) PostgreSQL stoppen"
    echo "3) Status prüfen"
    echo "4) Datenbank erstellen"
    echo "5) Backup erstellen"
    echo "6) Backup wiederherstellen"
    echo "7) psql Shell öffnen"
    echo "0) Zurück"
    echo ""
    read -p "Wähle Option: " choice
    
    case $choice in
        1)
            bash "$DB_DIR/postgresql/start.sh"
            ;;
        2)
            bash "$DB_DIR/postgresql/stop.sh"
            ;;
        3)
            pg_ctl -D "$DB_DIR/postgresql/data" status
            ;;
        4)
            read -p "Datenbankname: " dbname
            createdb "$dbname"
            success "Datenbank '$dbname' erstellt"
            ;;
        5)
            read -p "Datenbankname: " dbname
            pg_dump "$dbname" > "$DB_DIR/postgresql/${dbname}_$(date +%Y%m%d).sql"
            success "Backup erstellt"
            ;;
        6)
            read -p "Datenbankname: " dbname
            read -p "Backup-Datei: " backup
            psql "$dbname" < "$backup"
            success "Backup wiederhergestellt"
            ;;
        7)
            psql
            ;;
    esac
}

# ==============================================================================
# MARIADB/MYSQL MANAGEMENT
# ==============================================================================
install_mariadb() {
    info "Installiere MariaDB..."
    
    pkg install -y mariadb 2>&1 | tee -a "$LOG_FILE"
    
    mkdir -p "$DB_DIR/mariadb"
    
    if [ ! -d "$PREFIX/var/lib/mysql" ]; then
        mysql_install_db
        success "MariaDB initialisiert"
    fi
    
    # Start/Stop Scripts
    cat > "$DB_DIR/mariadb/start.sh" << 'MYSTART'
#!/data/data/com.termux/files/usr/bin/bash
mysqld_safe --datadir=$PREFIX/var/lib/mysql &
sleep 3
echo "MariaDB gestartet"
echo "Verbinden: mysql -u root"
MYSTART
    
    cat > "$DB_DIR/mariadb/stop.sh" << 'MYSTOP'
#!/data/data/com.termux/files/usr/bin/bash
mysqladmin -u root shutdown
echo "MariaDB gestoppt"
MYSTOP
    
    chmod +x "$DB_DIR/mariadb"/*.sh
    
    success "MariaDB installiert"
}

manage_mariadb() {
    echo ""
    echo -e "${CYAN}=== MariaDB Manager ===${NC}"
    echo ""
    echo "1) MariaDB starten"
    echo "2) MariaDB stoppen"
    echo "3) MySQL Shell öffnen"
    echo "4) Datenbank erstellen"
    echo "5) Backup erstellen"
    echo "6) Backup wiederherstellen"
    echo "0) Zurück"
    echo ""
    read -p "Wähle Option: " choice
    
    case $choice in
        1)
            bash "$DB_DIR/mariadb/start.sh"
            ;;
        2)
            bash "$DB_DIR/mariadb/stop.sh"
            ;;
        3)
            mysql -u root
            ;;
        4)
            read -p "Datenbankname: " dbname
            mysql -u root -e "CREATE DATABASE $dbname;"
            success "Datenbank '$dbname' erstellt"
            ;;
        5)
            read -p "Datenbankname: " dbname
            mysqldump -u root "$dbname" > "$DB_DIR/mariadb/${dbname}_$(date +%Y%m%d).sql"
            success "Backup erstellt"
            ;;
        6)
            read -p "Datenbankname: " dbname
            read -p "Backup-Datei: " backup
            mysql -u root "$dbname" < "$backup"
            success "Backup wiederhergestellt"
            ;;
    esac
}

# ==============================================================================
# MONGODB MANAGEMENT
# ==============================================================================
install_mongodb() {
    info "Installiere MongoDB..."
    
    # MongoDB via PRoot (Ubuntu)
    if ! command -v proot-distro &> /dev/null; then
        pkg install -y proot-distro
    fi
    
    if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
        proot-distro install ubuntu
    fi
    
    mkdir -p "$DB_DIR/mongodb"
    
    cat > "$DB_DIR/mongodb/setup.sh" << 'MONGOSETUP'
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu -- bash -c "
apt update
apt install -y mongodb
mkdir -p /data/db
"
MONGOSETUP
    
    cat > "$DB_DIR/mongodb/start.sh" << 'MONGOSTART'
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu -- bash -c "
mongod --dbpath /data/db --bind_ip 0.0.0.0 --port 27017 &
"
echo "MongoDB gestartet auf Port 27017"
MONGOSTART
    
    chmod +x "$DB_DIR/mongodb"/*.sh
    
    success "MongoDB Setup erstellt"
    info "Setup: bash $DB_DIR/mongodb/setup.sh"
}

# ==============================================================================
# REDIS MANAGEMENT
# ==============================================================================
install_redis() {
    info "Installiere Redis..."
    
    pkg install -y redis 2>&1 | tee -a "$LOG_FILE"
    
    mkdir -p "$DB_DIR/redis"
    
    cat > "$DB_DIR/redis/start.sh" << 'REDISSTART'
#!/data/data/com.termux/files/usr/bin/bash
redis-server --daemonize yes --dir ~/xtreme_ai_system/databases/redis
echo "Redis gestartet auf Port 6379"
echo "Verbinden: redis-cli"
REDISSTART
    
    cat > "$DB_DIR/redis/stop.sh" << 'REDISSTOP'
#!/data/data/com.termux/files/usr/bin/bash
redis-cli shutdown
echo "Redis gestoppt"
REDISSTOP
    
    chmod +x "$DB_DIR/redis"/*.sh
    
    success "Redis installiert"
}

manage_redis() {
    echo ""
    echo -e "${CYAN}=== Redis Manager ===${NC}"
    echo ""
    echo "1) Redis starten"
    echo "2) Redis stoppen"
    echo "3) Redis CLI öffnen"
    echo "4) Backup erstellen (RDB)"
    echo "5) Status prüfen"
    echo "0) Zurück"
    echo ""
    read -p "Wähle Option: " choice
    
    case $choice in
        1)
            bash "$DB_DIR/redis/start.sh"
            ;;
        2)
            bash "$DB_DIR/redis/stop.sh"
            ;;
        3)
            redis-cli
            ;;
        4)
            redis-cli BGSAVE
            cp "$DB_DIR/redis/dump.rdb" "$DB_DIR/redis/backup_$(date +%Y%m%d).rdb"
            success "Backup erstellt"
            ;;
        5)
            redis-cli ping
            ;;
    esac
}

# ==============================================================================
# SQLITE MANAGEMENT
# ==============================================================================
install_sqlite() {
    info "Installiere SQLite..."
    
    pkg install -y sqlite 2>&1 | tee -a "$LOG_FILE"
    
    mkdir -p "$DB_DIR/sqlite"
    
    success "SQLite installiert"
}

manage_sqlite() {
    echo ""
    echo -e "${CYAN}=== SQLite Manager ===${NC}"
    echo ""
    echo "1) Neue Datenbank erstellen"
    echo "2) Datenbank öffnen"
    echo "3) Backup erstellen"
    echo "4) Alle Datenbanken anzeigen"
    echo "0) Zurück"
    echo ""
    read -p "Wähle Option: " choice
    
    case $choice in
        1)
            read -p "Datenbankname: " dbname
            sqlite3 "$DB_DIR/sqlite/${dbname}.db" ".databases"
            success "Datenbank '$dbname.db' erstellt"
            ;;
        2)
            read -p "Datenbankname: " dbname
            sqlite3 "$DB_DIR/sqlite/${dbname}.db"
            ;;
        3)
            read -p "Datenbankname: " dbname
            cp "$DB_DIR/sqlite/${dbname}.db" "$DB_DIR/sqlite/${dbname}_$(date +%Y%m%d).db.bak"
            success "Backup erstellt"
            ;;
        4)
            ls -lh "$DB_DIR/sqlite"/*.db 2>/dev/null || echo "Keine Datenbanken gefunden"
            ;;
    esac
}

# ==============================================================================
# MAIN MENU
# ==============================================================================
main_menu() {
    while true; do
        show_banner
        
        echo -e "${CYAN}=== Installierte Datenbanken ===${NC}"
        echo ""
        
        command -v psql &> /dev/null && echo -e "${GREEN}✓${NC} PostgreSQL" || echo -e "${RED}✗${NC} PostgreSQL"
        command -v mysql &> /dev/null && echo -e "${GREEN}✓${NC} MariaDB/MySQL" || echo -e "${RED}✗${NC} MariaDB/MySQL"
        [ -f "$DB_DIR/mongodb/start.sh" ] && echo -e "${GREEN}✓${NC} MongoDB" || echo -e "${RED}✗${NC} MongoDB"
        command -v redis-server &> /dev/null && echo -e "${GREEN}✓${NC} Redis" || echo -e "${RED}✗${NC} Redis"
        command -v sqlite3 &> /dev/null && echo -e "${GREEN}✓${NC} SQLite" || echo -e "${RED}✗${NC} SQLite"
        
        echo ""
        echo -e "${CYAN}=== Installation ===${NC}"
        echo ""
        echo "1) PostgreSQL installieren"
        echo "2) MariaDB installieren"
        echo "3) MongoDB installieren"
        echo "4) Redis installieren"
        echo "5) SQLite installieren"
        echo ""
        echo -e "${CYAN}=== Management ===${NC}"
        echo ""
        echo "6) PostgreSQL verwalten"
        echo "7) MariaDB verwalten"
        echo "8) Redis verwalten"
        echo "9) SQLite verwalten"
        echo ""
        echo "0) Beenden"
        echo ""
        read -p "Wähle Option: " choice
        
        case $choice in
            1) install_postgresql ;;
            2) install_mariadb ;;
            3) install_mongodb ;;
            4) install_redis ;;
            5) install_sqlite ;;
            6) manage_postgresql ;;
            7) manage_mariadb ;;
            8) manage_redis ;;
            9) manage_sqlite ;;
            0) exit 0 ;;
            *) error "Ungültige Option" ;;
        esac
        
        echo ""
        read -p "Drücke Enter um fortzufahren..."
    done
}

# ==============================================================================
# INIT
# ==============================================================================
mkdir -p "$DB_DIR" "$INSTALL_DIR/logs"

main_menu
