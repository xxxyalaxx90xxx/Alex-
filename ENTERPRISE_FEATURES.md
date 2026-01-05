# XTREME XA-vI v4.0 Enterprise - Enterprise Features Guide

© Elektronikx-Center-Matte ® | Cyborg System by Alexander Mathey (xyalaxxx90@gmail.com)

---

## 📋 Inhaltsverzeichnis

1. [Database Manager](#database-manager)
2. [Network Manager](#network-manager)
3. [Dashboard API Server](#dashboard-api-server)
4. [Plugin System](#plugin-system)
5. [Use Cases](#use-cases)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## 🗄️ Database Manager

### Übersicht

Der Database Manager bietet vollständige Unterstützung für 5 populäre Datenbank-Systeme:

- **PostgreSQL** - Enterprise SQL-Datenbank
- **MariaDB/MySQL** - Weit verbreitete SQL-Datenbank
- **MongoDB** - NoSQL Dokumenten-Datenbank
- **Redis** - In-Memory Key-Value Store
- **SQLite** - Eingebettete SQL-Datenbank

### Installation

```bash
bash scripts/database_manager.sh
```

### PostgreSQL

**Features:**
- Vollständige PostgreSQL Installation
- Automatische Initialisierung
- Start/Stop Scripts
- Backup & Restore
- Database Management

**Verwendung:**
```bash
# PostgreSQL installieren
# Option 1 im Menü

# Server starten
bash ~/xtreme_ai_system/databases/postgresql/start.sh

# Mit psql verbinden
psql -h localhost -U $USER

# Datenbank erstellen
createdb myapp

# Backup
pg_dump myapp > backup.sql

# Restore
psql myapp < backup.sql
```

**Connection String:**
```
postgresql://localhost:5432/dbname?user=$USER
```

### MariaDB/MySQL

**Features:**
- MariaDB Installation (MySQL-kompatibel)
- Automatisches Setup
- Database Tools
- Import/Export

**Verwendung:**
```bash
# MariaDB installieren
# Option 2 im Menü

# Server starten
bash ~/xtreme_ai_system/databases/mariadb/start.sh

# MySQL Shell
mysql -u root

# Datenbank erstellen
CREATE DATABASE myapp;

# Backup
mysqldump -u root myapp > backup.sql
```

### MongoDB

**Features:**
- MongoDB via PRoot Ubuntu
- Document Store
- JSON-basiert
- Skalierbar

**Setup:**
```bash
# MongoDB Setup
bash ~/xtreme_ai_system/databases/mongodb/setup.sh

# Server starten
bash ~/xtreme_ai_system/databases/mongodb/start.sh

# Mit mongo Shell verbinden
proot-distro login ubuntu -- mongo
```

### Redis

**Features:**
- In-Memory Datenbank
- Key-Value Store
- Pub/Sub Messaging
- Caching

**Verwendung:**
```bash
# Redis installieren
# Option 4 im Menü

# Server starten
bash ~/xtreme_ai_system/databases/redis/start.sh

# Redis CLI
redis-cli

# Basic Commands
SET key "value"
GET key
EXPIRE key 3600
```

**Use Cases:**
- Session Storage
- Caching
- Message Queue
- Real-time Analytics

### SQLite

**Features:**
- Embedded Database
- Zero Configuration
- Single File
- ACID Compliant

**Verwendung:**
```bash
# SQLite installieren
# Option 5 im Menü

# Datenbank erstellen
sqlite3 ~/xtreme_ai_system/databases/sqlite/myapp.db

# SQL Befehle
CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);
INSERT INTO users VALUES (1, 'John');
SELECT * FROM users;
```

---

## 🌐 Network Manager

### Übersicht

Comprehensive Network Management Tools für:
- Port Forwarding & Tunneling
- Network Monitoring
- Network Security
- Proxy Management

### Features

#### 1. Port Forwarding & Tunneling

**SSH Tunnel (Local → Remote):**
```bash
# Zugriff auf Remote-Service lokal
ssh -L 8080:localhost:80 user@remote-server

# Beispiel: Remote MySQL lokal nutzen
ssh -L 3306:localhost:3306 user@db-server
mysql -h localhost -P 3306
```

**SSH Tunnel (Remote → Local):**
```bash
# Lokalen Service remote verfügbar machen
ssh -R 8080:localhost:80 user@remote-server
```

**SOCKS Proxy:**
```bash
# SOCKS5 Proxy über SSH
ssh -D 1080 user@proxy-server

# In Browser konfigurieren:
# SOCKS5: localhost:1080
```

**Reverse SSH Tunnel:**
```bash
# Remote-Zugriff auf lokales System
ssh -R 2222:localhost:22 user@remote-server

# Von remote aus verbinden:
ssh -p 2222 localhost
```

#### 2. Network Monitoring

**Aktive Verbindungen:**
```bash
# Alle Verbindungen
netstat -tupn

# Nur Listening Ports
netstat -tuln

# Mit PIDs
ss -tupn
```

**Bandbreiten-Monitor:**
```bash
# Installiere vnstat
pkg install vnstat

# Live Monitor
vnstat -l

# Statistiken
vnstat -d  # Daily
vnstat -m  # Monthly
```

**Network Tools:**
```bash
# Ping Test
ping -c 5 google.com

# Traceroute
traceroute google.com

# DNS Lookup
nslookup google.com
dig google.com

# Port Scan (lokal)
nmap localhost
```

#### 3. Network Security

**Offene Ports prüfen:**
```bash
# Listening Ports
netstat -tuln | grep LISTEN

# Mit Service-Namen
lsof -i -P | grep LISTEN
```

**Verdächtige Verbindungen:**
```bash
# ESTABLISHED Connections
netstat -tupn | grep ESTABLISHED

# Sortiert nach Count
netstat -tupn | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr
```

**Firewall (iptables - requires root):**
```bash
# Port blockieren
iptables -A INPUT -p tcp --dport 8080 -j DROP

# DDoS Schutz
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# Regeln anzeigen
iptables -L -n -v
```

#### 4. Proxy Management

**Privoxy (HTTP Proxy):**
```bash
# Installieren
pkg install privoxy

# Starten
privoxy

# Proxy: localhost:8118
```

**SOCKS → HTTP Konvertierung:**
```bash
# Privoxy mit SOCKS Backend
echo "forward-socks5 / 127.0.0.1:9050 ." > /tmp/privoxy.conf
echo "listen-address 127.0.0.1:8118" >> /tmp/privoxy.conf
privoxy /tmp/privoxy.conf
```

**ProxyChains:**
```bash
# Konfiguration
cat > ~/.proxychains.conf << EOF
strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
socks5 127.0.0.1 9050
EOF

# Verwendung
proxychains4 curl ifconfig.me
proxychains4 wget https://example.com
```

### Network Tools

**HTTP Server:**
```bash
# Python HTTP Server
python -m http.server 8000

# Mit spezifischem Verzeichnis
cd /path/to/files
python -m http.server 8080
```

**TCP/UDP Test Server:**
```bash
# TCP Listener
nc -l -p 8080

# UDP Listener
nc -u -l -p 8080

# Test Connection
echo "Hello" | nc localhost 8080
```

**Speed Test:**
```bash
# Speedtest CLI
pkg install speedtest-cli
speedtest-cli

# Oder
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -
```

---

## 📊 Dashboard API Server

### Übersicht

RESTful API Server für das Web Dashboard mit Echtzeit-Daten.

### Features

- System Statistics (CPU, RAM, Disk)
- Process Monitoring
- Network Connections
- Service Status
- Container List
- Security Scanning
- Log Management
- Backup List

### Installation & Start

```bash
# Automatische Dependency-Installation
bash scripts/dashboard_api.sh
```

**Server läuft auf:** `http://localhost:5000`

### API Endpoints

#### 1. System Information

**GET /**
```json
{
  "name": "XTREME XA-vI Dashboard API",
  "version": "4.0 Pro",
  "copyright": "© Elektronikx-Center-Matte ®",
  "developer": "Alexander Mathey",
  "status": "running"
}
```

#### 2. System Statistics

**GET /api/system/stats**
```json
{
  "cpu": {
    "percent": 45.2,
    "count": 8,
    "freq": {
      "current": 1800.0,
      "min": 300.0,
      "max": 1800.0
    }
  },
  "memory": {
    "total": 8589934592,
    "used": 4294967296,
    "free": 4294967296,
    "percent": 50.0
  },
  "disk": {
    "total": 274877906944,
    "used": 137438953472,
    "free": 137438953472,
    "percent": 50.0
  },
  "timestamp": "2026-01-05T15:00:00"
}
```

#### 3. Running Processes

**GET /api/system/processes**
```json
{
  "processes": [
    {
      "pid": 1234,
      "name": "python",
      "cpu_percent": 12.5,
      "memory_percent": 5.2
    }
  ],
  "total": 156
}
```

#### 4. Network Connections

**GET /api/network/connections**
```json
{
  "connections": [
    {
      "local_addr": "127.0.0.1:5000",
      "remote_addr": "127.0.0.1:52341",
      "status": "ESTABLISHED",
      "pid": 12345
    }
  ],
  "total": 23
}
```

#### 5. Network I/O

**GET /api/network/io**
```json
{
  "bytes_sent": 1048576000,
  "bytes_recv": 2097152000,
  "packets_sent": 1000000,
  "packets_recv": 1500000,
  "errin": 0,
  "errout": 0,
  "dropin": 0,
  "dropout": 0
}
```

#### 6. Service Status

**GET /api/services/status**
```json
{
  "postgresql": "running",
  "redis": "running",
  "tor": "stopped"
}
```

#### 7. Container List

**GET /api/containers/list**
```json
{
  "containers": [
    "ubuntu",
    "debian",
    "arch"
  ],
  "count": 3
}
```

#### 8. Security Scan

**GET /api/security/scan**
```json
{
  "issues": [
    {
      "type": "world_writable",
      "count": 5,
      "severity": "medium"
    }
  ],
  "count": 1,
  "timestamp": "2026-01-05T15:00:00"
}
```

#### 9. Recent Logs

**GET /api/logs/recent**
```json
{
  "logs": [
    {
      "file": "system_20260105.log",
      "lines": ["Line 1", "Line 2"]
    }
  ],
  "count": 1
}
```

#### 10. Backup List

**GET /api/backup/list**
```json
{
  "backups": [
    {
      "name": "backup_20260105.tar.gz",
      "size": 1073741824,
      "created": "2026-01-05T12:00:00"
    }
  ],
  "count": 1
}
```

### Usage Examples

**cURL:**
```bash
# System Stats
curl http://localhost:5000/api/system/stats

# Pretty Print
curl -s http://localhost:5000/api/system/stats | python -m json.tool

# With Authentication (if implemented)
curl -H "Authorization: Bearer token" http://localhost:5000/api/system/stats
```

**JavaScript (Fetch):**
```javascript
// Get System Stats
fetch('http://localhost:5000/api/system/stats')
  .then(response => response.json())
  .then(data => {
    console.log('CPU:', data.cpu.percent + '%');
    console.log('Memory:', data.memory.percent + '%');
  });

// Auto-update every 2 seconds
setInterval(() => {
  fetch('http://localhost:5000/api/system/stats')
    .then(response => response.json())
    .then(data => updateDashboard(data));
}, 2000);
```

**Python:**
```python
import requests

# Get Stats
response = requests.get('http://localhost:5000/api/system/stats')
data = response.json()

print(f"CPU: {data['cpu']['percent']}%")
print(f"Memory: {data['memory']['percent']}%")
```

---

## 🔌 Plugin System

### Übersicht

Erweiterbares Plugin-System für Custom Tools und Scripts.

### Features

- Plugin Creation Wizard
- Template System
- Enable/Disable Plugins
- Plugin Execution
- Sample Plugins

### Plugin Structure

```
plugin_name/
├── manifest.json    # Plugin Metadata
├── main.sh          # Entry Point
└── README.md        # Documentation
```

### Creating a Plugin

#### 1. Interactive Creation

```bash
bash scripts/plugin_system.sh
# Option 1: Plugin erstellen
```

**Input:**
- Plugin Name
- Version
- Description
- Author
- Category (utility/monitoring/security/development)

#### 2. Manual Creation

**manifest.json:**
```json
{
  "name": "My Plugin",
  "version": "1.0.0",
  "description": "My custom plugin",
  "author": "Your Name",
  "category": "utility",
  "dependencies": [],
  "entry_point": "main.sh",
  "config": {}
}
```

**main.sh:**
```bash
#!/data/data/com.termux/files/usr/bin/bash

PLUGIN_NAME="My Plugin"
PLUGIN_VERSION="1.0.0"

echo "=== $PLUGIN_NAME v$PLUGIN_VERSION ==="
echo ""

# Your plugin code here

echo "✓ Done"
```

### Sample Plugins

#### 1. System Info Plugin

```bash
#!/data/data/com.termux/files/usr/bin/bash
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
free -h
```

#### 2. Quick Backup Plugin

```bash
#!/data/data/com.termux/files/usr/bin/bash
BACKUP_DIR="$HOME/xtreme_backups/quick"
mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_DIR/quick_$(date +%Y%m%d_%H%M%S).tar.gz" \
    ~/xtreme_ai_system/config \
    ~/xtreme_ai_system/data

echo "✓ Backup created"
```

### Plugin Management

**Enable Plugin:**
```bash
# Via Menu: Option 3
# Or manually:
mv ~/xtreme_ai_system/plugins/disabled/my_plugin \
   ~/xtreme_ai_system/plugins/enabled/
```

**Disable Plugin:**
```bash
# Via Menu: Option 4
# Or manually:
mv ~/xtreme_ai_system/plugins/enabled/my_plugin \
   ~/xtreme_ai_system/plugins/disabled/
```

**Run Plugin:**
```bash
# Single Plugin
bash ~/xtreme_ai_system/plugins/enabled/my_plugin/main.sh

# All Enabled Plugins
# Via Menu: Option 6
```

### Advanced Plugin Development

#### With Configuration

**manifest.json:**
```json
{
  "config": {
    "api_key": "YOUR_KEY",
    "endpoint": "https://api.example.com",
    "timeout": 30
  }
}
```

**Reading Config in main.sh:**
```bash
CONFIG_FILE="$(dirname "$0")/manifest.json"
API_KEY=$(grep '"api_key"' "$CONFIG_FILE" | cut -d'"' -f4)
ENDPOINT=$(grep '"endpoint"' "$CONFIG_FILE" | cut -d'"' -f4)

curl -H "Authorization: Bearer $API_KEY" "$ENDPOINT"
```

#### With Dependencies

**manifest.json:**
```json
{
  "dependencies": ["curl", "jq", "python"]
}
```

**Check in main.sh:**
```bash
# Check Dependencies
for dep in curl jq python; do
    if ! command -v $dep &> /dev/null; then
        echo "Error: $dep not installed"
        exit 1
    fi
done
```

---

## 💼 Use Cases

### 1. Full-Stack Development Environment

```bash
# Setup Database
bash scripts/database_manager.sh
# Install PostgreSQL

# Start API Server
bash scripts/dashboard_api.sh

# Develop App
bash scripts/app_builder.sh
# Create Node.js Web App

# Monitor Performance
bash scripts/network_manager.sh
# Track Connections
```

### 2. Microservices Architecture

```bash
# Container für jeden Service
bash scripts/container_manager.sh
# Service 1: Ubuntu mit Node.js
# Service 2: Debian mit Python
# Service 3: Alpine mit Go

# Datenbank-Backend
# PostgreSQL für Haupt-DB
# Redis für Caching
# MongoDB für Logs

# API Gateway
# Dashboard API Server

# Monitoring
# Network Manager
# Performance Monitor
```

### 3. Data Science Workstation

```bash
# PostgreSQL für Daten-Storage
# Redis für Caching
# Python Environment (AI Integration)
# Jupyter via Container
# TensorFlow Lite Models
# Dashboard API für Visualisierung
```

### 4. DevOps Platform

```bash
# Database Management
# - PostgreSQL für Config Management
# - Redis für Job Queue

# Network Management
# - SSH Tunnels für Remote Access
# - VPN für Secure Connections

# Automation
# - Automated Backups
# - Scheduled Tasks
# - Custom Plugins für CI/CD

# Monitoring
# - Dashboard API
# - Performance Tracking
# - Security Scans
```

---

## 🎯 Best Practices

### Database Management

1. **Regelmäßige Backups:**
   ```bash
   # Daily Backup Cron
   0 2 * * * pg_dump myapp > ~/backups/myapp_$(date +\%Y\%m\%d).sql
   ```

2. **Connection Pooling:**
   - Verwende pgbouncer für PostgreSQL
   - Redis Connection Pool in Apps

3. **Security:**
   - Starke Passwörter
   - Firewall Regeln
   - Encrypted Connections

### Network Security

1. **Firewall Rules:**
   - Nur notwendige Ports öffnen
   - Use iptables oder termux-api

2. **Tunneling:**
   - SSH Tunnels für sensitive Daten
   - VPN für Remote Access

3. **Monitoring:**
   - Regelmäßige Scans
   - Log-Analyse
   - Alert-System

### API Development

1. **Rate Limiting:**
   ```python
   from flask_limiter import Limiter
   limiter = Limiter(app, key_func=get_remote_address)
   
   @app.route('/api/data')
   @limiter.limit("10 per minute")
   def get_data():
       return jsonify(data)
   ```

2. **Authentication:**
   - JWT Tokens
   - API Keys
   - OAuth2

3. **Error Handling:**
   ```python
   @app.errorhandler(404)
   def not_found(error):
       return jsonify({'error': 'Not found'}), 404
   ```

### Plugin Development

1. **Error Handling:**
   ```bash
   set -euo pipefail
   trap 'echo "Error on line $LINENO"' ERR
   ```

2. **Logging:**
   ```bash
   LOG_FILE="$HOME/xtreme_ai_system/logs/plugin_$(date +%Y%m%d).log"
   log() {
       echo "[$(date)] $1" | tee -a "$LOG_FILE"
   }
   ```

3. **Testing:**
   ```bash
   # Test Mode
   if [[ "${TEST_MODE:-0}" == "1" ]]; then
       echo "Running in test mode"
       # Mock functions
   fi
   ```

---

## 🔧 Troubleshooting

### Database Issues

**PostgreSQL won't start:**
```bash
# Check logs
tail -f ~/xtreme_ai_system/logs/postgresql.log

# Check data directory
ls -la ~/xtreme_ai_system/databases/postgresql/data

# Reinitialize
rm -rf ~/xtreme_ai_system/databases/postgresql/data
initdb ~/xtreme_ai_system/databases/postgresql/data
```

**Redis connection refused:**
```bash
# Check if running
redis-cli ping

# Check port
netstat -tuln | grep 6379

# Restart
redis-cli shutdown
redis-server
```

### Network Issues

**SSH Tunnel not working:**
```bash
# Check SSH connection
ssh user@server echo "OK"

# Verbose mode
ssh -v -L 8080:localhost:80 user@server

# Check if port is already in use
lsof -i :8080
```

**Port already in use:**
```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>
```

### API Server Issues

**Port 5000 in use:**
```bash
# Change port in script
export PORT=5001
bash scripts/dashboard_api.sh
```

**Dependencies missing:**
```bash
# Install manually
pip install flask flask-cors psutil
```

**Permission denied:**
```bash
# Check file permissions
chmod +x scripts/dashboard_api.sh

# Check Python permissions
which python
ls -la $(which python)
```

### Plugin Issues

**Plugin not executing:**
```bash
# Check permissions
chmod +x ~/xtreme_ai_system/plugins/enabled/my_plugin/main.sh

# Check shebang
head -1 ~/xtreme_ai_system/plugins/enabled/my_plugin/main.sh
# Should be: #!/data/data/com.termux/files/usr/bin/bash

# Test manually
bash ~/xtreme_ai_system/plugins/enabled/my_plugin/main.sh
```

---

## 📚 Additional Resources

### Documentation
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Redis Docs](https://redis.io/documentation)
- [Flask Docs](https://flask.palletsprojects.com/)

### Tutorials
- Database Design Best Practices
- RESTful API Design
- SSH Tunnel Guide

### Support
- GitHub Issues
- Email: xyalaxxx90@gmail.com
- © Elektronikx-Center-Matte ®

---

**Version:** 4.0 Enterprise  
**Status:** ✅ Production Ready  
**Last Updated:** 2026-01-05

© Elektronikx-Center-Matte ®  
Cyborg System by Alexander Mathey (xyalaxxx90@gmail.com)
