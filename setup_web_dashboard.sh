#!/bin/bash

# Web Dashboard Setup Script
# Author: Alexander Mathey (xyalaxxx90@gmail.com)
# Copyright: Elektronikx-Center-Matte ® ™ By Alexander Mathey ©

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DASHBOARD_PORT="${DASHBOARD_PORT:-8080}"
DASHBOARD_USER="${DASHBOARD_USER:-admin}"
DASHBOARD_PASS="${DASHBOARD_PASS:-admin123}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/k8s-dashboard}"
THEME="${THEME:-dark}"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif [ -f /data/data/com.termux ]; then
        OS="termux"
    else
        OS=$(uname -s)
    fi
    
    print_info "Detected OS: $OS"
}

# Install Node.js if not present
install_nodejs() {
    print_info "Checking Node.js installation..."
    
    if command -v node &> /dev/null; then
        print_success "Node.js already installed: $(node --version)"
        return 0
    fi
    
    print_info "Installing Node.js..."
    
    if [ "$OS" = "termux" ]; then
        pkg install -y nodejs
    elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
        sudo yum install -y nodejs
    else
        print_error "Unsupported OS for automatic Node.js installation"
        return 1
    fi
    
    print_success "Node.js installed successfully"
}

# Create dashboard application
create_dashboard() {
    print_info "Creating dashboard application..."
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Create package.json
    cat > package.json <<'EOF'
{
  "name": "k8s-dashboard",
  "version": "1.0.0",
  "description": "Kubernetes Management Dashboard",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "express-basic-auth": "^1.2.1",
    "ws": "^8.14.2",
    "axios": "^1.6.0"
  }
}
EOF
    
    # Create server.js
    cat > server.js <<'EOFSERVER'
const express = require('express');
const basicAuth = require('express-basic-auth');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const WebSocket = require('ws');

const app = express();
const PORT = process.env.DASHBOARD_PORT || 8080;
const USERNAME = process.env.DASHBOARD_USER || 'admin';
const PASSWORD = process.env.DASHBOARD_PASS || 'admin123';

// Authentication middleware
app.use(basicAuth({
    users: { [USERNAME]: PASSWORD },
    challenge: true,
    realm: 'K8s Dashboard'
}));

app.use(express.json());
app.use(express.static('public'));

// API endpoints
app.get('/api/cluster/info', (req, res) => {
    exec('kubectl cluster-info', (error, stdout, stderr) => {
        if (error) {
            res.json({ status: 'error', message: stderr });
        } else {
            res.json({ status: 'success', info: stdout });
        }
    });
});

app.get('/api/nodes', (req, res) => {
    exec('kubectl get nodes -o json', (error, stdout, stderr) => {
        if (error) {
            res.json({ status: 'error', message: stderr });
        } else {
            res.json({ status: 'success', data: JSON.parse(stdout) });
        }
    });
});

app.get('/api/pods', (req, res) => {
    exec('kubectl get pods --all-namespaces -o json', (error, stdout, stderr) => {
        if (error) {
            res.json({ status: 'error', message: stderr });
        } else {
            res.json({ status: 'success', data: JSON.parse(stdout) });
        }
    });
});

app.get('/api/services', (req, res) => {
    exec('kubectl get services --all-namespaces -o json', (error, stdout, stderr) => {
        if (error) {
            res.json({ status: 'error', message: stderr });
        } else {
            res.json({ status: 'success', data: JSON.parse(stdout) });
        }
    });
});

app.get('/api/deployments', (req, res) => {
    exec('kubectl get deployments --all-namespaces -o json', (error, stdout, stderr) => {
        if (error) {
            res.json({ status: 'error', message: stderr });
        } else {
            res.json({ status: 'success', data: JSON.parse(stdout) });
        }
    });
});

app.get('/api/system/info', (req, res) => {
    const info = {
        arch: process.arch,
        platform: process.platform,
        nodeVersion: process.version,
        uptime: process.uptime()
    };
    res.json({ status: 'success', info });
});

// Database endpoints
app.get('/api/databases', (req, res) => {
    const databases = {
        mysql: { port: 3306, ui: 'http://localhost:8081' },
        postgresql: { port: 5432, ui: 'http://localhost:8085' },
        redis: { port: 6379, ui: 'http://localhost:8083' },
        mongodb: { port: 27017, ui: 'http://localhost:8084' }
    };
    res.json({ status: 'success', databases });
});

// AI Assistant integration
app.post('/api/ai/query', (req, res) => {
    const { query } = req.body;
    exec(`ai-assistant "${query}"`, (error, stdout, stderr) => {
        if (error) {
            res.json({ status: 'error', message: 'AI assistant not available' });
        } else {
            res.json({ status: 'success', response: stdout });
        }
    });
});

const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`Dashboard running on http://0.0.0.0:${PORT}`);
    console.log(`Username: ${USERNAME}`);
});

// WebSocket for real-time updates
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws) => {
    console.log('WebSocket client connected');
    
    // Send updates every 5 seconds
    const interval = setInterval(() => {
        exec('kubectl get pods --all-namespaces -o json', (error, stdout) => {
            if (!error && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({ type: 'pods', data: JSON.parse(stdout) }));
            }
        });
    }, 5000);
    
    ws.on('close', () => {
        clearInterval(interval);
        console.log('WebSocket client disconnected');
    });
});
EOFSERVER
    
    # Create public directory
    mkdir -p public
    
    # Create index.html
    cat > public/index.html <<'EOFHTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kubernetes Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: #0f1419;
            color: #e6edf3;
            line-height: 1.6;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }
        
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
        }
        
        h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .subtitle {
            opacity: 0.9;
            font-size: 1.1em;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .card {
            background: #1c2128;
            border: 1px solid #30363d;
            border-radius: 10px;
            padding: 20px;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.4);
        }
        
        .card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 15px;
            border-bottom: 1px solid #30363d;
        }
        
        .card-title {
            font-size: 1.3em;
            font-weight: 600;
        }
        
        .status {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 500;
        }
        
        .status.success {
            background: #238636;
            color: white;
        }
        
        .status.error {
            background: #da3633;
            color: white;
        }
        
        .status.warning {
            background: #9e6a03;
            color: white;
        }
        
        .metric {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #30363d;
        }
        
        .metric:last-child {
            border-bottom: none;
        }
        
        .metric-label {
            color: #8b949e;
        }
        
        .metric-value {
            font-weight: 600;
            font-size: 1.1em;
        }
        
        .button {
            background: #238636;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 1em;
            transition: background 0.2s;
        }
        
        .button:hover {
            background: #2ea043;
        }
        
        .button.secondary {
            background: #21262d;
            border: 1px solid #30363d;
        }
        
        .button.secondary:hover {
            background: #30363d;
        }
        
        #aiChat {
            background: #1c2128;
            border: 1px solid #30363d;
            border-radius: 10px;
            padding: 20px;
            margin-top: 30px;
        }
        
        #aiInput {
            width: 100%;
            padding: 15px;
            background: #0d1117;
            border: 1px solid #30363d;
            border-radius: 6px;
            color: #e6edf3;
            font-size: 1em;
            margin-bottom: 15px;
        }
        
        #aiResponse {
            background: #0d1117;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 15px;
            min-height: 100px;
            max-height: 400px;
            overflow-y: auto;
            white-space: pre-wrap;
        }
        
        .loading {
            text-align: center;
            padding: 40px;
            color: #8b949e;
        }
        
        @media (max-width: 768px) {
            .grid {
                grid-template-columns: 1fr;
            }
            
            h1 {
                font-size: 1.8em;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🚀 Kubernetes Dashboard</h1>
            <div class="subtitle">Comprehensive cluster management and monitoring</div>
        </header>
        
        <div class="grid">
            <div class="card">
                <div class="card-header">
                    <div class="card-title">Cluster Status</div>
                    <div class="status success" id="clusterStatus">Healthy</div>
                </div>
                <div id="clusterInfo">
                    <div class="loading">Loading...</div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <div class="card-title">Nodes</div>
                    <button class="button secondary" onclick="refreshData()">Refresh</button>
                </div>
                <div id="nodesInfo">
                    <div class="loading">Loading...</div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <div class="card-title">Pods</div>
                    <div id="podCount">0</div>
                </div>
                <div id="podsInfo">
                    <div class="loading">Loading...</div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <div class="card-title">Services</div>
                    <div id="serviceCount">0</div>
                </div>
                <div id="servicesInfo">
                    <div class="loading">Loading...</div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <div class="card-title">Databases</div>
                </div>
                <div id="databasesInfo">
                    <div class="metric">
                        <span class="metric-label">MySQL</span>
                        <a href="http://localhost:8081" target="_blank" class="button secondary">Open</a>
                    </span>
                    <div class="metric">
                        <span class="metric-label">PostgreSQL</span>
                        <a href="http://localhost:8085" target="_blank" class="button secondary">Open</a>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Redis</span>
                        <a href="http://localhost:8083" target="_blank" class="button secondary">Open</a>
                    </div>
                    <div class="metric">
                        <span class="metric-label">MongoDB</span>
                        <a href="http://localhost:8084" target="_blank" class="button secondary">Open</a>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <div class="card-title">System Info</div>
                </div>
                <div id="systemInfo">
                    <div class="loading">Loading...</div>
                </div>
            </div>
        </div>
        
        <div id="aiChat">
            <h2 style="margin-bottom: 20px;">🤖 AI Assistant</h2>
            <input type="text" id="aiInput" placeholder="Ask about your cluster (e.g., 'What's wrong with my pods?')">
            <button class="button" onclick="queryAI()">Ask AI</button>
            <div id="aiResponse" style="margin-top: 15px;"></div>
        </div>
    </div>
    
    <script>
        // Fetch cluster info
        async function fetchClusterInfo() {
            try {
                const response = await fetch('/api/cluster/info');
                const data = await response.json();
                document.getElementById('clusterInfo').innerHTML = `<pre style="color: #8b949e; font-size: 0.9em;">${data.info || data.message}</pre>`;
            } catch (error) {
                document.getElementById('clusterInfo').innerHTML = '<div class="metric"><span class="metric-label">Error</span><span class="metric-value status error">Failed to connect</span></div>';
            }
        }
        
        // Fetch nodes
        async function fetchNodes() {
            try {
                const response = await fetch('/api/nodes');
                const data = await response.json();
                if (data.status === 'success' && data.data.items) {
                    const html = data.data.items.map(node => `
                        <div class="metric">
                            <span class="metric-label">${node.metadata.name}</span>
                            <span class="metric-value status success">Ready</span>
                        </div>
                    `).join('');
                    document.getElementById('nodesInfo').innerHTML = html;
                }
            } catch (error) {
                document.getElementById('nodesInfo').innerHTML = '<div class="metric"><span>Error loading nodes</span></div>';
            }
        }
        
        // Fetch pods
        async function fetchPods() {
            try {
                const response = await fetch('/api/pods');
                const data = await response.json();
                if (data.status === 'success' && data.data.items) {
                    document.getElementById('podCount').textContent = data.data.items.length;
                    const running = data.data.items.filter(p => p.status.phase === 'Running').length;
                    const html = `
                        <div class="metric">
                            <span class="metric-label">Total</span>
                            <span class="metric-value">${data.data.items.length}</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Running</span>
                            <span class="metric-value status success">${running}</span>
                        </div>
                    `;
                    document.getElementById('podsInfo').innerHTML = html;
                }
            } catch (error) {
                document.getElementById('podsInfo').innerHTML = '<div class="metric"><span>Error loading pods</span></div>';
            }
        }
        
        // Fetch services
        async function fetchServices() {
            try {
                const response = await fetch('/api/services');
                const data = await response.json();
                if (data.status === 'success' && data.data.items) {
                    document.getElementById('serviceCount').textContent = data.data.items.length;
                    const html = data.data.items.slice(0, 5).map(svc => `
                        <div class="metric">
                            <span class="metric-label">${svc.metadata.name}</span>
                            <span class="metric-value">${svc.spec.type}</span>
                        </div>
                    `).join('');
                    document.getElementById('servicesInfo').innerHTML = html;
                }
            } catch (error) {
                document.getElementById('servicesInfo').innerHTML = '<div class="metric"><span>Error loading services</span></div>';
            }
        }
        
        // Fetch system info
        async function fetchSystemInfo() {
            try {
                const response = await fetch('/api/system/info');
                const data = await response.json();
                if (data.status === 'success') {
                    const html = `
                        <div class="metric">
                            <span class="metric-label">Platform</span>
                            <span class="metric-value">${data.info.platform}</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Architecture</span>
                            <span class="metric-value">${data.info.arch}</span>
                        </div>
                        <div class="metric">
                            <span class="metric-label">Node Version</span>
                            <span class="metric-value">${data.info.nodeVersion}</span>
                        </div>
                    `;
                    document.getElementById('systemInfo').innerHTML = html;
                }
            } catch (error) {
                document.getElementById('systemInfo').innerHTML = '<div class="metric"><span>Error loading system info</span></div>';
            }
        }
        
        // Query AI
        async function queryAI() {
            const query = document.getElementById('aiInput').value;
            if (!query) return;
            
            document.getElementById('aiResponse').textContent = 'Thinking...';
            
            try {
                const response = await fetch('/api/ai/query', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ query })
                });
                const data = await response.json();
                document.getElementById('aiResponse').textContent = data.response || data.message;
            } catch (error) {
                document.getElementById('aiResponse').textContent = 'Error: Unable to connect to AI assistant';
            }
        }
        
        // Refresh all data
        function refreshData() {
            fetchClusterInfo();
            fetchNodes();
            fetchPods();
            fetchServices();
            fetchSystemInfo();
        }
        
        // WebSocket for real-time updates
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const ws = new WebSocket(`${protocol}//${window.location.host}`);
        
        ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            if (data.type === 'pods' && data.data.items) {
                document.getElementById('podCount').textContent = data.data.items.length;
            }
        };
        
        // Initial load
        refreshData();
        
        // Auto-refresh every 30 seconds
        setInterval(refreshData, 30000);
        
        // Enter key for AI
        document.getElementById('aiInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') queryAI();
        });
    </script>
</body>
</html>
EOFHTML
    
    print_success "Dashboard application created"
}

# Install dependencies
install_dependencies() {
    print_info "Installing Node.js dependencies..."
    
    cd "$INSTALL_DIR"
    npm install
    
    print_success "Dependencies installed"
}

# Create startup script
create_startup_script() {
    print_info "Creating startup script..."
    
    cat > "$HOME/dashboard-start.sh" <<EOF
#!/bin/bash
cd "$INSTALL_DIR"
export DASHBOARD_PORT=$DASHBOARD_PORT
export DASHBOARD_USER=$DASHBOARD_USER
export DASHBOARD_PASS=$DASHBOARD_PASS
npm start
EOF
    
    chmod +x "$HOME/dashboard-start.sh"
    
    print_success "Startup script created: $HOME/dashboard-start.sh"
}

# Create systemd service (if available)
create_systemd_service() {
    if ! command -v systemctl &> /dev/null; then
        print_warning "systemd not available, skipping service creation"
        return 0
    fi
    
    print_info "Creating systemd service..."
    
    sudo tee /etc/systemd/system/k8s-dashboard.service > /dev/null <<EOF
[Unit]
Description=Kubernetes Dashboard
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
Environment="DASHBOARD_PORT=$DASHBOARD_PORT"
Environment="DASHBOARD_USER=$DASHBOARD_USER"
Environment="DASHBOARD_PASS=$DASHBOARD_PASS"
ExecStart=$(which node) $INSTALL_DIR/server.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable k8s-dashboard
    
    print_success "Systemd service created"
}

# Main installation
main() {
    print_info "Starting Web Dashboard installation..."
    
    detect_os
    install_nodejs
    create_dashboard
    install_dependencies
    create_startup_script
    create_systemd_service
    
    print_success "Web Dashboard installed successfully!"
    echo ""
    print_info "Access the dashboard at: http://localhost:$DASHBOARD_PORT"
    print_info "Username: $DASHBOARD_USER"
    print_info "Password: $DASHBOARD_PASS"
    echo ""
    print_info "Start dashboard: $HOME/dashboard-start.sh"
    
    if command -v systemctl &> /dev/null; then
        print_info "Or use systemd: sudo systemctl start k8s-dashboard"
    fi
}

main
