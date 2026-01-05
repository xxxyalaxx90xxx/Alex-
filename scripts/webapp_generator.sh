#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XA-vI v4.0 - Offline Web App Generator
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
WEBAPP_DIR="$INSTALL_DIR/webapps"

# ==============================================================================
# BANNER
# ==============================================================================
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      🌐 XTREME XA-vI OFFLINE WEB APP GENERATOR v4.0 🌐         ║
║                                                                  ║
║  Erstelle Progressive Web Apps mit Offline-Support              ║
║  © Elektronikx-Center-Matte ®                                   ║
║  by Alexander Mathey (xyalaxxx90@gmail.com)                     ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ==============================================================================
# HILFSFUNKTIONEN
# ==============================================================================
log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# ==============================================================================
# PWA ERSTELLEN
# ==============================================================================
create_pwa() {
    echo -e "\n${BLUE}${BOLD}=== Progressive Web App Creator ===${NC}\n"
    
    read -p "App Name: " app_name
    read -p "App Beschreibung: " app_description
    read -p "Theme Color (hex, z.B. #667eea): " theme_color
    
    local app_dir="$WEBAPP_DIR/${app_name}"
    
    if [ -d "$app_dir" ]; then
        log_error "App existiert bereits!"
        return 1
    fi
    
    mkdir -p "$app_dir"/{css,js,img,data}
    cd "$app_dir"
    
    # index.html
    cat > index.html << HTML
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="${app_description}">
    <meta name="theme-color" content="${theme_color}">
    
    <title>${app_name}</title>
    
    <link rel="manifest" href="/manifest.json">
    <link rel="icon" type="image/png" href="/img/icon-192.png">
    <link rel="apple-touch-icon" href="/img/icon-192.png">
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div class="app-container">
        <header class="app-header">
            <h1>🚀 ${app_name}</h1>
            <p class="app-subtitle">${app_description}</p>
            <div class="status-indicator">
                <span id="online-status">⚫ Offline</span>
            </div>
        </header>
        
        <main class="app-main">
            <section class="welcome-section">
                <h2>Welcome to ${app_name}</h2>
                <p>Diese App funktioniert auch offline!</p>
                
                <div class="feature-grid">
                    <div class="feature-card">
                        <div class="feature-icon">📱</div>
                        <h3>Installierbar</h3>
                        <p>Als App auf Ihrem Gerät</p>
                    </div>
                    
                    <div class="feature-card">
                        <div class="feature-icon">⚡</div>
                        <h3>Schnell</h3>
                        <p>Sofortiges Laden</p>
                    </div>
                    
                    <div class="feature-card">
                        <div class="feature-icon">🔒</div>
                        <h3>Offline</h3>
                        <p>Funktioniert ohne Internet</p>
                    </div>
                    
                    <div class="feature-card">
                        <div class="feature-icon">🎨</div>
                        <h3>Modern</h3>
                        <p>Schönes Design</p>
                    </div>
                </div>
                
                <div class="action-section">
                    <button onclick="saveData()" class="btn-primary">Daten speichern</button>
                    <button onclick="loadData()" class="btn-secondary">Daten laden</button>
                    <button onclick="clearData()" class="btn-danger">Daten löschen</button>
                </div>
                
                <div id="data-display" class="data-display"></div>
            </section>
        </main>
        
        <footer class="app-footer">
            <p>© Elektronikx-Center-Matte ®</p>
            <p>by Alexander Mathey (xyalaxxx90@gmail.com)</p>
            <p class="version">Version 1.0.0</p>
        </footer>
    </div>
    
    <div id="install-prompt" class="install-prompt" style="display:none;">
        <p>📱 Installiere ${app_name} als App!</p>
        <button onclick="installApp()" class="btn-install">Installieren</button>
        <button onclick="dismissInstall()" class="btn-dismiss">Später</button>
    </div>
    
    <script src="/js/app.js"></script>
</body>
</html>
HTML
    
    # manifest.json
    cat > manifest.json << MANIFEST
{
  "name": "${app_name}",
  "short_name": "${app_name}",
  "description": "${app_description}",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "${theme_color}",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/img/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/img/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "categories": ["productivity", "utilities"],
  "screenshots": [],
  "shortcuts": [
    {
      "name": "Start ${app_name}",
      "short_name": "Start",
      "description": "Starte die App",
      "url": "/",
      "icons": [{ "src": "/img/icon-192.png", "sizes": "192x192" }]
    }
  ]
}
MANIFEST
    
    # Service Worker
    cat > sw.js << 'SW'
/**
 * XTREME XA-vI Service Worker
 * © Elektronikx-Center-Matte ®
 * by Alexander Mathey
 */

const CACHE_NAME = 'xtreme-xai-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/css/style.css',
  '/js/app.js',
  '/manifest.json'
];

// Install
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Cache geöffnet');
        return cache.addAll(urlsToCache);
      })
  );
});

// Fetch
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        if (response) {
          return response;
        }
        
        return fetch(event.request).then(response => {
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }
          
          const responseToCache = response.clone();
          caches.open(CACHE_NAME)
            .then(cache => {
              cache.put(event.request, responseToCache);
            });
          
          return response;
        });
      })
  );
});

// Activate
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('Lösche alten Cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});
SW
    
    # CSS
    cat > css/style.css << 'CSS'
/**
 * XTREME XA-vI PWA Styles
 * © Elektronikx-Center-Matte ®
 */

:root {
  --primary-color: #667eea;
  --secondary-color: #764ba2;
  --success-color: #48bb78;
  --danger-color: #f56565;
  --text-color: #2d3748;
  --bg-color: #f7fafc;
  --card-bg: #ffffff;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  color: var(--text-color);
  min-height: 100vh;
  line-height: 1.6;
}

.app-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem;
}

.app-header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-radius: 20px;
  padding: 2rem;
  margin-bottom: 2rem;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  text-align: center;
}

.app-header h1 {
  font-size: 2.5rem;
  color: var(--primary-color);
  margin-bottom: 0.5rem;
}

.app-subtitle {
  color: #718096;
  font-size: 1.1rem;
}

.status-indicator {
  margin-top: 1rem;
  padding: 0.5rem 1rem;
  background: rgba(0, 0, 0, 0.05);
  border-radius: 20px;
  display: inline-block;
}

.status-indicator.online {
  background: rgba(72, 187, 120, 0.1);
  color: var(--success-color);
}

.app-main {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-radius: 20px;
  padding: 2rem;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  margin-bottom: 2rem;
}

.welcome-section h2 {
  color: var(--primary-color);
  margin-bottom: 1rem;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
  margin: 2rem 0;
}

.feature-card {
  background: var(--bg-color);
  padding: 1.5rem;
  border-radius: 15px;
  text-align: center;
  transition: transform 0.3s ease;
}

.feature-card:hover {
  transform: translateY(-5px);
}

.feature-icon {
  font-size: 3rem;
  margin-bottom: 0.5rem;
}

.feature-card h3 {
  color: var(--primary-color);
  margin-bottom: 0.5rem;
}

.action-section {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
  margin: 2rem 0;
}

button {
  padding: 12px 24px;
  border: none;
  border-radius: 10px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 600;
}

.btn-primary {
  background: var(--primary-color);
  color: white;
}

.btn-primary:hover {
  background: #5568d3;
  transform: scale(1.05);
}

.btn-secondary {
  background: #cbd5e0;
  color: var(--text-color);
}

.btn-secondary:hover {
  background: #a0aec0;
  transform: scale(1.05);
}

.btn-danger {
  background: var(--danger-color);
  color: white;
}

.btn-danger:hover {
  background: #e53e3e;
  transform: scale(1.05);
}

.data-display {
  margin-top: 2rem;
  padding: 1.5rem;
  background: var(--bg-color);
  border-radius: 10px;
  min-height: 100px;
}

.app-footer {
  text-align: center;
  color: white;
  padding: 1.5rem;
  background: rgba(0, 0, 0, 0.2);
  backdrop-filter: blur(10px);
  border-radius: 20px;
}

.version {
  margin-top: 0.5rem;
  font-size: 0.9rem;
  opacity: 0.8;
}

.install-prompt {
  position: fixed;
  bottom: 20px;
  right: 20px;
  background: white;
  padding: 1.5rem;
  border-radius: 15px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
  z-index: 1000;
  max-width: 300px;
}

.btn-install {
  background: var(--success-color);
  color: white;
  margin-right: 0.5rem;
}

.btn-dismiss {
  background: #e2e8f0;
  color: var(--text-color);
}

@media (max-width: 768px) {
  .app-header h1 {
    font-size: 2rem;
  }
  
  .feature-grid {
    grid-template-columns: 1fr;
  }
  
  .action-section {
    flex-direction: column;
  }
}
CSS
    
    # JavaScript
    cat > js/app.js << 'JS'
/**
 * XTREME XA-vI PWA Application
 * © Elektronikx-Center-Matte ®
 * by Alexander Mathey
 */

// Service Worker registrieren
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js')
      .then(reg => console.log('Service Worker registriert:', reg.scope))
      .catch(err => console.log('Service Worker Fehler:', err));
  });
}

// Online/Offline Status
function updateOnlineStatus() {
  const status = document.getElementById('online-status');
  if (navigator.onLine) {
    status.textContent = '🟢 Online';
    status.parentElement.classList.add('online');
  } else {
    status.textContent = '⚫ Offline';
    status.parentElement.classList.remove('online');
  }
}

window.addEventListener('online', updateOnlineStatus);
window.addEventListener('offline', updateOnlineStatus);
window.addEventListener('load', updateOnlineStatus);

// Install Prompt
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;
  document.getElementById('install-prompt').style.display = 'block';
});

function installApp() {
  const promptEl = document.getElementById('install-prompt');
  promptEl.style.display = 'none';
  
  if (deferredPrompt) {
    deferredPrompt.prompt();
    deferredPrompt.userChoice.then((choiceResult) => {
      if (choiceResult.outcome === 'accepted') {
        console.log('App installiert');
      }
      deferredPrompt = null;
    });
  }
}

function dismissInstall() {
  document.getElementById('install-prompt').style.display = 'none';
}

// LocalStorage Funktionen
function saveData() {
  const data = {
    timestamp: new Date().toISOString(),
    message: 'Daten von XTREME XA-vI App',
    user: 'Alexander Mathey',
    copyright: '© Elektronikx-Center-Matte ®'
  };
  
  localStorage.setItem('xai-data', JSON.stringify(data));
  alert('✅ Daten gespeichert!');
  loadData();
}

function loadData() {
  const data = localStorage.getItem('xai-data');
  const display = document.getElementById('data-display');
  
  if (data) {
    const parsed = JSON.parse(data);
    display.innerHTML = `
      <h3>📦 Gespeicherte Daten:</h3>
      <pre>${JSON.stringify(parsed, null, 2)}</pre>
    `;
  } else {
    display.innerHTML = '<p>Keine Daten vorhanden</p>';
  }
}

function clearData() {
  if (confirm('Wirklich alle Daten löschen?')) {
    localStorage.clear();
    alert('✅ Daten gelöscht!');
    document.getElementById('data-display').innerHTML = '';
  }
}

// Initial load
loadData();

console.log('XTREME XA-vI App geladen');
console.log('© Elektronikx-Center-Matte ®');
console.log('by Alexander Mathey (xyalaxxx90@gmail.com)');
JS
    
    # Erstelle Placeholder Icons
    log_info "Erstelle Icon-Placeholders..."
    
    # 192x192 Icon (Base64 PNG)
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > img/icon-192.png
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > img/icon-512.png
    
    # README
    cat > README.md << README
# ${app_name}

${app_description}

Progressive Web App mit Offline-Support

© Elektronikx-Center-Matte ®  
Entwicklung: Alexander Mathey (xyalaxxx90@gmail.com)

## Features

- ✅ Offline-Funktionalität
- ✅ Installierbar als App
- ✅ Service Worker
- ✅ LocalStorage
- ✅ Responsive Design

## Start

\`\`\`bash
cd $app_dir
python -m http.server 8000
# oder
npx http-server
\`\`\`

Dann öffne: http://localhost:8000

## License

© Elektronikx-Center-Matte ®
README
    
    log_success "PWA erstellt: $app_dir"
    log_info "Starten mit: cd $app_dir && python -m http.server 8000"
}

# ==============================================================================
# HAUPTMENÜ
# ==============================================================================
show_menu() {
    while true; do
        show_banner
        
        echo -e "${BOLD}Web App Generator:${NC}\n"
        echo "  1) Progressive Web App (PWA) erstellen"
        echo "  2) Bestehende PWA erweitern"
        echo "  3) Alle Web Apps anzeigen"
        echo "  4) Web App starten"
        echo "  0) Beenden"
        echo ""
        
        read -p "Auswahl [0-4]: " choice
        
        case $choice in
            1)
                mkdir -p "$WEBAPP_DIR"
                create_pwa
                read -p "Drücke Enter zum Fortfahren..."
                ;;
            2)
                log_info "Feature kommt bald..."
                read -p "Drücke Enter zum Fortfahren..."
                ;;
            3)
                echo -e "\n${CYAN}=== Web Apps ===${NC}\n"
                find "$WEBAPP_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || echo "Keine Apps gefunden"
                echo ""
                read -p "Drücke Enter zum Fortfahren..."
                ;;
            4)
                echo -e "\n${CYAN}=== Web Apps ===${NC}\n"
                local apps=($(find "$WEBAPP_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null))
                
                if [ ${#apps[@]} -eq 0 ]; then
                    log_error "Keine Apps gefunden"
                else
                    for i in "${!apps[@]}"; do
                        echo "$((i+1))) $(basename "${apps[$i]}")"
                    done
                    
                    read -p "App starten [1-${#apps[@]}]: " app_choice
                    if [[ "$app_choice" =~ ^[0-9]+$ ]] && [ "$app_choice" -ge 1 ] && [ "$app_choice" -le "${#apps[@]}" ]; then
                        cd "${apps[$((app_choice-1))]}"
                        log_info "Starte Server auf Port 8000..."
                        python -m http.server 8000
                    fi
                fi
                ;;
            0)
                log_info "Auf Wiedersehen!"
                exit 0
                ;;
            *)
                log_error "Ungültige Auswahl"
                sleep 1
                ;;
        esac
    done
}

# ==============================================================================
# MAIN
# ==============================================================================
main() {
    show_menu
}

main "$@"
