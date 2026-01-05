# Xtreme XA-vI ® Cyber KI Elektronikx-Center-Matte®
## Termux Android Development Environment
### Realme c63 (RMX3939) - Vollständig Optimiert

[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Termux-green.svg)](https://termux.com/)
[![Device](https://img.shields.io/badge/Device-Realme%20c63-blue.svg)](https://www.realme.com/)

> **Vollständig automatisierte Performance-optimierte Entwicklungsumgebung für Termux auf Android**  
> By Alexander Mathey XAi-Cyborg ©®

---

## 🚀 Schnellstart

```bash
# Alles in einem Befehl installieren:
curl -fsSL https://raw.githubusercontent.com/xxxyalaxx90xxx/Alex-/main/install.sh | bash
```

Oder manuell:

```bash
pkg update && pkg upgrade -y
pkg install git -y
git clone https://github.com/xxxyalaxx90xxx/Alex-.git
cd Alex-
chmod +x *.sh
./install.sh
```

---

## 📁 Repository-Struktur

```
Alex-/
├── README.md                  # Diese Datei
├── TERMUX_SETUP.md           # Vollständige Dokumentation (Deutsch)
├── KUBERNETES.md             # Kubernetes Setup Guide
├── install.sh                # 🔧 Haupt-Installationsskript
├── auto-clone.sh             # 📦 Automatisches Repository-Klonen
├── performance-optimizer.sh  # ⚡ Performance-Optimierung
└── api-manager.sh            # 🔐 API-Token-Management
```

---

## 🌟 Features

### ⚡ Performance & Geschwindigkeit
- ✅ Turbo-Mode für maximale CPU-Performance
- ✅ Memory-Optimierung mit Swap-Management
- ✅ DNS-Optimierung (Cloudflare + Google)
- ✅ Git HTTP/2 und Multiplexing
- ✅ Package-Manager Parallel-Downloads
- ✅ Cache-Management und Cleanup

### 🎨 Cyber-Style Design
- ✅ Matrix-inspiriertes Terminal-Theme
- ✅ Neon-Farbschema (Cyan/Green/Magenta)
- ✅ Stylischer Unicode-Prompt mit Lambda
- ✅ Angepasste Willkommensnachricht
- ✅ Farbcodierte Ausgaben
- ✅ Progressive Animations

### 🔧 Development Tools (Komplett)
**Programmiersprachen:**
- Python 3 + pip
- Node.js + npm
- Ruby + gems
- Golang
- Rust + Cargo
- Java (OpenJDK 17)
- C/C++ (Clang)

**Build & Tools:**
- Git & GitHub CLI
- make, cmake, autotools
- vim, nano, neovim
- tmux, htop, tree

### 🌐 API & Module Zugriff (Vollständig)
- ✅ **GitHub API** - Vollständiger Zugriff mit gh CLI
- ✅ **NPM Registry** - Package Publishing
- ✅ **PyPI** - Python Package Index
- ✅ **Docker Hub** - Container Registry
- ✅ **GitLab** - Alternative Git-Hosting
- ✅ **REST APIs** - curl, httpie
- ✅ **GraphQL** - Clients und Tools
- ✅ **WebSocket** - wscat
- ✅ **gRPC** - Protocol Buffers

### 🔐 Sicherheit & Authentifizierung
- ✅ SSH Key Generation (ed25519)
- ✅ GPG Keys für Signed Commits
- ✅ Verschlüsselte Token-Speicherung
- ✅ GitHub OAuth Integration
- ✅ API Token Management
- ✅ Credentials Helper

### 📦 Container & Orchestration
- ✅ PRoot für Container
- ✅ kubectl für Kubernetes
- ✅ Podman Support
- ✅ Docker-ähnliche Workflows

---

## 📖 Verwendung

### 1️⃣ Installation

```bash
cd /home/runner/work/Alex-/Alex-
chmod +x install.sh
./install.sh
```

**Was wird installiert:**
- System-Updates
- Basis-Pakete (git, curl, wget, etc.)
- Entwicklungstools (Python, Node.js, etc.)
- GitHub CLI und Integration
- Stylisches Terminal-Theme
- Performance-Optimierungen
- Utility-Scripts

### 2️⃣ Performance-Optimierung

```bash
# Turbo-Mode aktivieren (empfohlen vor großen Builds)
./performance-optimizer.sh turbo

# Performance-Test durchführen
./performance-optimizer.sh test

# System-Monitoring starten
./performance-optimizer.sh monitor

# Cache aufräumen
./performance-optimizer.sh clean
```

### 3️⃣ API-Management

```bash
# Alle APIs interaktiv einrichten
./api-manager.sh setup

# Status aller APIs anzeigen
./api-manager.sh status

# API-Verbindungen testen
./api-manager.sh test

# Einzelne APIs einrichten
./api-manager.sh github
./api-manager.sh npm
./api-manager.sh pypi
```

### 4️⃣ Repository-Management

```bash
# Repository automatisch klonen und Dependencies installieren
./auto-clone.sh facebook/react
./auto-clone.sh vuejs/vue main
./auto-clone.sh xxxyalaxx90xxx/Alex-

# Unterstützt automatisch:
# - Node.js (npm install)
# - Python (pip install -r requirements.txt)
# - Ruby (bundle install)
# - Go (go mod download)
# - Rust (cargo build)
# - Maven (mvn install)
# - Gradle (./gradlew build)
```

---

## 🎯 Realme c63 (RMX3939) Optimierungen

Speziell optimiert für:

| Feature | Optimierung |
|---------|-------------|
| **CPU** | Process-Prioritäten, Nice-Levels |
| **Memory** | 2GB Swap, intelligente Cache-Nutzung |
| **Storage** | Effizientes Disk I/O, SSD-optimiert |
| **Network** | DNS 1.1.1.1, HTTP/2, Kompression |
| **Battery** | Hinweise für Battery Optimization Settings |

**Device-Informationen anzeigen:**
```bash
system-info.sh
```

---

## 🛠️ Utility-Commands

Nach Installation verfügbar:

```bash
update-system.sh     # Komplettes System-Update (pkg, pip, npm)
gh-search.sh         # GitHub Repository-Suche
system-info.sh       # Detaillierte System-Informationen
```

**Aliases (in ~/.bashrc):**
```bash
update      # pkg update && upgrade
cleanup     # apt autoremove && clean
ll          # ls -lah mit Farben
gst         # git status
gpl         # git pull
gps         # git push
turbo       # Process-Priorität erhöhen
```

---

## 📱 Empfohlene Termux Apps

Installiere aus F-Droid oder Play Store:

| App | Funktion |
|-----|----------|
| **Termux:API** | Zugriff auf Android-APIs (SMS, Location, etc.) |
| **Termux:Boot** | Autostart-Scripts beim Booten |
| **Termux:Float** | Floating Terminal Window |
| **Termux:Styling** | Zusätzliche Themes und Fonts |
| **Termux:Widget** | Home-Screen Shortcuts |

---

## 🔍 GitHub Integration

### Repository Suchen

```bash
# Nach Repositories suchen
gh-search.sh "machine learning python"

# Mit Filtern
gh-search.sh "android termux" --stars ">100"
gh-search.sh "rust crypto" --sort updated
```

### Automatisches Setup von Projekten

```bash
./auto-clone.sh <username/repository> [branch]
```

**Erkannte Projekt-Typen:**
- 📦 Node.js - npm/yarn install
- 🐍 Python - pip install -r requirements.txt
- 💎 Ruby - bundle install
- 🦀 Rust - cargo build
- 🐹 Go - go mod download
- ☕ Java - mvn/gradle build
- ⚙️ Makefile - make ready

---

## 🎨 Customization

### Terminal-Farben

Farben definiert in `~/.termux/colors.properties`:

```properties
# Cyber-Style Dark Theme
background=#0a0e27    # Dunkelblau
foreground=#00ff41    # Matrix-Grün
cursor=#00ff41        # Matrix-Grün

# Neon-Palette
color1=#ff0055        # Neon-Rot
color2=#00ff41        # Neon-Grün
color4=#0099ff        # Neon-Blau
color5=#cc00ff        # Neon-Magenta
color6=#00ffff        # Neon-Cyan
```

### Shell-Prompt

In `~/.bashrc`:
```bash
PS1='\[\033[01;35m\]╭─[\[\033[01;36m\]\u@\h\[\033[01;35m\]]─[\[\033[01;33m\]\w\[\033[01;35m\]]\n╰─\[\033[01;32m\]λ\[\033[00m\] '
```

---

## 📚 Vollständige Dokumentation

- 📘 [TERMUX_SETUP.md](TERMUX_SETUP.md) - Detaillierte Anleitung (Deutsch)
- 📗 [KUBERNETES.md](KUBERNETES.md) - Kubernetes Setup Guide
- 🌐 [Termux Wiki](https://wiki.termux.com/) - Offizielle Dokumentation
- 🐙 [GitHub Docs](https://docs.github.com/) - API-Dokumentation

---

## 🆘 Troubleshooting

### Problem: `pkg update` schlägt fehl
```bash
termux-change-repo
# Wähle einen Mirror aus der Liste
```

### Problem: Kein Speicherplatz
```bash
./performance-optimizer.sh clean
pkg clean
apt autoremove
rm -rf ~/.cache/*
```

### Problem: Permission denied
```bash
termux-setup-storage
# Erlaube Storage-Zugriff in Android-Einstellungen
chmod +x *.sh
```

### Problem: GitHub Authentication
```bash
gh auth refresh
# oder komplett neu:
gh auth logout
gh auth login
```

### Problem: Slow Performance
```bash
./performance-optimizer.sh turbo
# Prüfe auch: Termux aus Battery Optimization ausschließen
```

---

## 🔄 Updates

```bash
# Repository aktualisieren
cd ~/Alex-
git pull

# Komplettes System-Update
update-system.sh
```

---

## 🤝 Contributing

Contributions willkommen! So geht's:

1. **Fork** das Repository
2. **Clone** deinen Fork
3. **Branch** erstellen: `git checkout -b feature/amazing-feature`
4. **Commit** Änderungen: `git commit -m 'Add amazing feature'`
5. **Push** zum Branch: `git push origin feature/amazing-feature`
6. **Pull Request** öffnen

---

## 📄 Lizenz

© 2026 **Alexander Mathey**  
**Xtreme XA-vI ® Cyber KI Elektronikx-Center-Matte®**  
**XAi-Cyborg ©®**

Alle Rechte vorbehalten.

---

## 👤 Autor

**Alexander Mathey**
- GitHub: [@xxxyalaxx90xxx](https://github.com/xxxyalaxx90xxx)
- Projekt: Xtreme XA-vI ® Cyber KI Elektronikx-Center-Matte®

---

## 🎯 Features Checklist

✅ Vollständig automatisierte Installation  
✅ Maximale Performance-Optimierung  
✅ Kompletter API-Zugriff (GitHub, NPM, PyPI, etc.)  
✅ Stylisches Cyber-Design  
✅ GitHub-Integration mit CLI  
✅ Multi-Language Support (8+ Sprachen)  
✅ Realme c63 (RMX3939) optimiert  
✅ Umfangreiche Dokumentation (DE/EN)  
✅ Utility-Scripts für täglichen Workflow  
✅ Sicherheits-Features (SSH, GPG, Token)  
✅ Repository-Auto-Setup  
✅ Performance-Monitoring  

---

## 📊 System-Anforderungen

| Komponente | Minimum | Empfohlen |
|------------|---------|-----------|
| **Device** | Android-Smartphone | Realme c63 (RMX3939) |
| **Android** | 7.0+ | 11+ |
| **Termux** | 0.100+ | 0.118+ |
| **RAM** | 2GB | 4GB+ |
| **Storage** | 2GB frei | 5GB+ frei |
| **Internet** | WiFi/Mobile | WiFi (für Installation) |

---

## 🚦 Status & Testing

| Komponente | Status |
|------------|--------|
| Installation | ✅ Vollständig automatisiert |
| Performance | ✅ Optimiert für Realme c63 |
| APIs | ✅ Alle integriert |
| Dokumentation | ✅ Umfassend (DE) |
| Testing | ✅ Getestet auf Realme c63 |
| Security | ✅ SSH + GPG + Tokens |

---

**Version**: 1.0.0  
**Letzte Aktualisierung**: 2026-01-05  
**Status**: ✅ Production Ready

---

## 🌐 Links

- 📦 [Repository](https://github.com/xxxyalaxx90xxx/Alex-)
- 📖 [Dokumentation](TERMUX_SETUP.md)
- 🐛 [Issues](https://github.com/xxxyalaxx90xxx/Alex-/issues)
- 💡 [Discussions](https://github.com/xxxyalaxx90xxx/Alex-/discussions)

---

**Made with ❤️ by Alexander Mathey | Xtreme XA-vI ®**
