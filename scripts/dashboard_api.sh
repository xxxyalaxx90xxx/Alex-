#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XA-vI v4.0 Pro - Dashboard Backend API Server
# © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey (xyalaxxx90@gmail.com)
# ==============================================================================

set -euo pipefail

# Farben
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

INSTALL_DIR="$HOME/xtreme_ai_system"
PORT=5000

echo -e "${CYAN}Starting XTREME XA-vI Dashboard API Server...${NC}"

# Python-basierter API Server
cat > "/tmp/xai_dashboard_api.py" << 'PYAPI'
#!/usr/bin/env python3
"""
XTREME XA-vI Dashboard API Server
© Elektronikx-Center-Matte ® | Alexander Mathey
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import psutil
import os
import subprocess
import json
from datetime import datetime

app = Flask(__name__)
CORS(app)

@app.route('/')
def index():
    return jsonify({
        'name': 'XTREME XA-vI Dashboard API',
        'version': '4.0 Pro',
        'copyright': '© Elektronikx-Center-Matte ®',
        'developer': 'Alexander Mathey',
        'status': 'running'
    })

@app.route('/api/system/stats')
def system_stats():
    """Get system statistics"""
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return jsonify({
            'cpu': {
                'percent': cpu_percent,
                'count': psutil.cpu_count(),
                'freq': psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None
            },
            'memory': {
                'total': memory.total,
                'used': memory.used,
                'free': memory.free,
                'percent': memory.percent
            },
            'disk': {
                'total': disk.total,
                'used': disk.used,
                'free': disk.free,
                'percent': disk.percent
            },
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/system/processes')
def processes():
    """Get running processes"""
    try:
        procs = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                procs.append(proc.info)
            except:
                pass
        
        # Sort by CPU usage
        procs.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
        
        return jsonify({
            'processes': procs[:20],  # Top 20
            'total': len(procs)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/network/connections')
def network_connections():
    """Get network connections"""
    try:
        connections = psutil.net_connections(kind='inet')
        conn_list = []
        
        for conn in connections[:50]:  # Limit to 50
            conn_list.append({
                'local_addr': f"{conn.laddr.ip}:{conn.laddr.port}" if conn.laddr else None,
                'remote_addr': f"{conn.raddr.ip}:{conn.raddr.port}" if conn.raddr else None,
                'status': conn.status,
                'pid': conn.pid
            })
        
        return jsonify({
            'connections': conn_list,
            'total': len(connections)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/network/io')
def network_io():
    """Get network I/O statistics"""
    try:
        net_io = psutil.net_io_counters()
        
        return jsonify({
            'bytes_sent': net_io.bytes_sent,
            'bytes_recv': net_io.bytes_recv,
            'packets_sent': net_io.packets_sent,
            'packets_recv': net_io.packets_recv,
            'errin': net_io.errin,
            'errout': net_io.errout,
            'dropin': net_io.dropin,
            'dropout': net_io.dropout
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/services/status')
def services_status():
    """Check status of key services"""
    services = {}
    
    # Check PostgreSQL
    try:
        subprocess.run(['pg_isready'], capture_output=True, timeout=2)
        services['postgresql'] = 'running'
    except:
        services['postgresql'] = 'stopped'
    
    # Check Redis
    try:
        subprocess.run(['redis-cli', 'ping'], capture_output=True, timeout=2)
        services['redis'] = 'running'
    except:
        services['redis'] = 'stopped'
    
    # Check Tor
    try:
        result = subprocess.run(['pgrep', '-f', 'tor'], capture_output=True)
        services['tor'] = 'running' if result.returncode == 0 else 'stopped'
    except:
        services['tor'] = 'unknown'
    
    return jsonify(services)

@app.route('/api/containers/list')
def containers_list():
    """List PRoot containers"""
    try:
        result = subprocess.run(
            ['proot-distro', 'list'],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        containers = []
        for line in result.stdout.split('\n'):
            if line.strip() and not line.startswith('*'):
                containers.append(line.strip())
        
        return jsonify({
            'containers': containers,
            'count': len(containers)
        })
    except Exception as e:
        return jsonify({'error': str(e), 'containers': [], 'count': 0})

@app.route('/api/security/scan')
def security_scan():
    """Quick security scan"""
    issues = []
    
    # Check for world-writable files
    try:
        result = subprocess.run(
            ['find', os.path.expanduser('~'), '-type', 'f', '-perm', '-002'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        writable_files = result.stdout.strip().split('\n')
        if len(writable_files) > 1:  # More than just empty
            issues.append({
                'type': 'world_writable',
                'count': len(writable_files),
                'severity': 'medium'
            })
    except:
        pass
    
    # Check for suspicious processes
    suspicious = ['nc', 'netcat', 'ncat']
    for proc in psutil.process_iter(['name']):
        try:
            if proc.info['name'] in suspicious:
                issues.append({
                    'type': 'suspicious_process',
                    'process': proc.info['name'],
                    'severity': 'high'
                })
        except:
            pass
    
    return jsonify({
        'issues': issues,
        'count': len(issues),
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/logs/recent')
def recent_logs():
    """Get recent log entries"""
    log_dir = os.path.expanduser('~/xtreme_ai_system/logs')
    logs = []
    
    try:
        if os.path.exists(log_dir):
            log_files = sorted(
                [f for f in os.listdir(log_dir) if f.endswith('.log')],
                key=lambda x: os.path.getmtime(os.path.join(log_dir, x)),
                reverse=True
            )
            
            for log_file in log_files[:5]:  # Last 5 log files
                file_path = os.path.join(log_dir, log_file)
                try:
                    with open(file_path, 'r') as f:
                        lines = f.readlines()
                        logs.append({
                            'file': log_file,
                            'lines': lines[-10:]  # Last 10 lines
                        })
                except:
                    pass
        
        return jsonify({
            'logs': logs,
            'count': len(logs)
        })
    except Exception as e:
        return jsonify({'error': str(e), 'logs': [], 'count': 0})

@app.route('/api/backup/list')
def backup_list():
    """List available backups"""
    backup_dir = os.path.expanduser('~/xtreme_backups')
    backups = []
    
    try:
        if os.path.exists(backup_dir):
            for f in os.listdir(backup_dir):
                if f.endswith('.tar.gz'):
                    file_path = os.path.join(backup_dir, f)
                    stat = os.stat(file_path)
                    backups.append({
                        'name': f,
                        'size': stat.st_size,
                        'created': datetime.fromtimestamp(stat.st_ctime).isoformat()
                    })
            
            backups.sort(key=lambda x: x['created'], reverse=True)
        
        return jsonify({
            'backups': backups,
            'count': len(backups)
        })
    except Exception as e:
        return jsonify({'error': str(e), 'backups': [], 'count': 0})

if __name__ == '__main__':
    print("=" * 70)
    print("  XTREME XA-vI Dashboard API Server v4.0 Pro")
    print("  © Elektronikx-Center-Matte ®")
    print("  Cyborg System by Alexander Mathey")
    print("=" * 70)
    print("")
    print(f"  API Server running on: http://0.0.0.0:5000")
    print(f"  API Documentation: http://localhost:5000/")
    print("")
    print("  Endpoints:")
    print("    GET /api/system/stats       - System statistics")
    print("    GET /api/system/processes   - Running processes")
    print("    GET /api/network/connections - Network connections")
    print("    GET /api/network/io         - Network I/O stats")
    print("    GET /api/services/status    - Service status")
    print("    GET /api/containers/list    - Container list")
    print("    GET /api/security/scan      - Security scan")
    print("    GET /api/logs/recent        - Recent logs")
    print("    GET /api/backup/list        - Backup list")
    print("")
    print("=" * 70)
    
    app.run(host='0.0.0.0', port=5000, debug=False)
PYAPI

# Prüfe Abhängigkeiten
if ! python -c "import flask" 2>/dev/null; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pip install flask flask-cors psutil
fi

# Starte Server
echo ""
python "/tmp/xai_dashboard_api.py"
