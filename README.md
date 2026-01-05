# Alex- Repository

## XTREME XAI v4.0.0 - Ultimate AI System für Termux/Android

### ⚡ Schnellstart für Termux

```bash
# Komplette Installation in einem Befehl:
pkg install git -y && git clone https://github.com/xxxyalaxx90xxx/Alex-.git && cd Alex- && chmod +x install.sh && ./install.sh
```

**Oder mit Quick-Install Script:**

```bash
# Quick-Install herunterladen und ausführen
cd ~ && git clone https://github.com/xxxyalaxx90xxx/Alex-.git && cd Alex- && chmod +x quick-install.sh && ./quick-install.sh
```

📖 **Detaillierte Anleitung:** Siehe [TERMUX_INSTALLATION.md](TERMUX_INSTALLATION.md)

---

### Übersicht
XTREME XAI v4.0.0 ist ein vollständiges AI-System, optimiert für Android-Geräte mit Termux. Entwickelt speziell für das Realme C63 RMX3939, bietet es eine umfassende Plattform für künstliche Intelligenz, Machine Learning und Datenanalyse direkt auf Ihrem mobilen Gerät.

**Entwickelt von:** Alexander Mathey ©  
**Organisation:** Elektronikx-Center-Matte ®  
**Version:** 4.0.0  
**Datum:** 2026-01-05

---

### Systemanforderungen

#### Hardware (Optimiert für Realme C63 RMX3939)
- **CPU:** Unisoc Tiger T612 (2x Cortex-A75 @ 1.8GHz + 6x Cortex-A55 @ 1.6GHz)
- **RAM:** Mindestens 4GB (8GB empfohlen, 8GB LPDDR4X optimal)
- **Speicher:** Mindestens 10GB frei (256GB UFS 2.2 optimal)
- **Architektur:** ARM64/aarch64

#### Software
- **Betriebssystem:** Android mit Termux installiert
- **Termux Version:** Aktuell (F-Droid empfohlen)
- **Internet:** Erforderlich für Installation
- **Berechtigungen:** Storage-Zugriff (termux-setup-storage)

---

### Schnellstart

#### 1. Repository klonen
```bash
# Repository klonen
pkg install git
git clone https://github.com/xxxyalaxx90xxx/Alex-.git
cd Alex-
```

#### 2. Installation starten
```bash
# Installationsscript ausführbar machen
chmod +x install.sh

# Installation starten
./install.sh
```

Die Installation führt automatisch folgende Schritte aus:
- ✓ System Pre-Checks (10 Schritte)
- ✓ Installation von System-Abhängigkeiten
- ✓ Installation von Python-Paketen
- ✓ Installation von Node.js-Paketen
- ✓ XAI Systemkonfiguration
- ✓ Erfolgsbestätigung mit Systeminformationen

#### 3. XAI starten
```bash
# XAI Launcher starten
./xai.sh

# Oder nach Setup über Alias
xai
```

---

### Verwendung

#### Interaktives Menü
Nach dem Start von `./xai.sh` erscheint ein interaktives Menü:

```
╔══════════════════════════════════════════════════════════════════════╗
║                    XAI v4.0.0 - Ultimate AI System                   ║
║                    Optimiert für Termux/Android                      ║
╚══════════════════════════════════════════════════════════════════════╝

Hauptmenü:
──────────────────────────────────────────────────────────
1. System-Status anzeigen
2. AI-Module starten
3. Konfiguration bearbeiten
4. Updates durchführen
5. Logs anzeigen
6. System beenden
──────────────────────────────────────────────────────────
```

#### Kommandozeilen-Verwendung
```bash
# System-Status anzeigen
./xai.sh status

# Logs anzeigen
./xai.sh logs

# Version anzeigen
./xai.sh version

# Hilfe anzeigen
./xai.sh help
```

#### Nach vollständigem Setup (neue Shell)
```bash
# XAI starten
xai

# Status prüfen
xai-status

# Logs live verfolgen
xai-logs
```

---

### Verzeichnisstruktur

Nach der Installation wird folgende Struktur unter `~/xai/` erstellt:

```
~/xai/
├── bin/          # Ausführbare Dateien und Scripts
│   └── xai       # XAI Launcher
├── config/       # Konfigurationsdateien
│   ├── env.sh           # Umgebungsvariablen
│   ├── config.json      # Hauptkonfiguration
│   └── autostart.sh     # Autostart-Script
├── data/         # Daten und Datenbanken
├── logs/         # Log-Dateien
│   └── xai.log          # Haupt-Logdatei
└── models/       # AI-Modelle (zukünftig)
```

---

### Konfiguration

#### Hauptkonfiguration
Die Hauptkonfiguration befindet sich in `~/xai/config/config.json`:

```json
{
  "xai": {
    "version": "4.0.0",
    "name": "XTREME XAI",
    "developer": "Alexander Mathey",
    "organization": "Elektronikx-Center-Matte"
  },
  "system": {
    "device": "Realme C63 RMX3939",
    "cpu": "Unisoc Tiger T612",
    "ram_gb": 8,
    "storage_gb": 256
  },
  "settings": {
    "log_level": "INFO",
    "max_log_size_mb": 100,
    "enable_autostart": false,
    "theme": "dark"
  }
}
```

Bearbeiten mit: `./xai.sh` → Option 3 oder `nano ~/xai/config/config.json`

#### Umgebungsvariablen
Umgebungsvariablen werden automatisch aus `~/xai/config/env.sh` geladen:
- `XAI_HOME` - XAI Hauptverzeichnis
- `XAI_BIN` - Ausführbare Dateien
- `XAI_CONFIG` - Konfigurationsverzeichnis
- `XAI_DATA` - Datenverzeichnis
- `XAI_LOGS` - Log-Verzeichnis
- `XAI_MODELS` - Modellverzeichnis
- `XAI_VERSION` - Aktuelle Version

---

### Features

#### Aktuell verfügbar (v4.0.0)
- ✅ Vollautomatische Installation für Termux
- ✅ Umfassende System Pre-Checks
- ✅ Optimierte Python & Node.js Umgebung
- ✅ Interaktives Menüsystem
- ✅ System-Monitoring und Status
- ✅ Log-Management
- ✅ Update-Management
- ✅ Konfigurationsverwaltung

#### In Entwicklung (kommende Versionen)
- 🔄 Natural Language Processing (NLP) Module
- 🔄 Computer Vision (CV) Module
- 🔄 Machine Learning Workflows
- 🔄 Datenanalyse-Tools
- 🔄 AI-Modell-Integration
- 🔄 Remote-API-Zugriff

---

### Troubleshooting

#### Installation schlägt fehl
```bash
# Prüfe Internetverbindung
ping -c 3 8.8.8.8

# Aktualisiere Termux Pakete
pkg update && pkg upgrade

# Prüfe freien Speicher
df -h .
```

#### Python-Pakete können nicht installiert werden
```bash
# Termux verwendet eigene Python-Version
# pip upgrade ist in Termux verboten - nicht versuchen!

# Einzelnes Paket manuell installieren
pip install <paket-name> --no-warn-script-location
```

#### XAI startet nicht
```bash
# Prüfe ob XAI installiert ist
ls -la ~/xai/

# Prüfe Berechtigungen
chmod +x ./xai.sh

# Prüfe Logs
cat ~/xai/logs/xai.log
```

#### Speicherprobleme
```bash
# Prüfe Speicherverbrauch
du -sh ~/xai/*

# Bereinige alte Logs
rm ~/xai/logs/*.log.old

# Bereinige alte Backups
rm -rf ~/xai.backup.*
```

#### Termux Storage nicht verfügbar
```bash
# Storage-Berechtigungen erteilen
termux-setup-storage

# Manuelle Berechtigungsprüfung
ls -la ~/storage/
```

---

### Updates

#### Manuelle Updates
```bash
# System aktualisieren
pkg update && pkg upgrade

# Python-Pakete aktualisieren
pip install --upgrade -r requirements.txt

# XAI aktualisieren (wenn Git-Repo)
git pull
```

#### Über XAI-Menü
```bash
# XAI starten
./xai.sh

# Option 4 wählen: "Updates durchführen"
```

---

### Deinstallation

```bash
# XAI Verzeichnis entfernen
rm -rf ~/xai

# Backup entfernen (falls vorhanden)
rm -rf ~/xai.backup.*

# Bash-Profile bereinigen (optional)
nano ~/.bashrc
# Entferne XAI-Konfigurationsblock
```

---

### Support und Kontakt

- **Entwickler:** Alexander Mathey
- **Organisation:** Elektronikx-Center-Matte ®
- **Repository:** https://github.com/xxxyalaxx90xxx/Alex-
- **Lizenz:** Copyright © 2026 Alexander Mathey

---

### Copyright-Hinweise

**© Elektronikx-Center-Matte ®**  
**© Alexander Mathey 2026**

Alle Rechte vorbehalten. Diese Software wurde entwickelt von Alexander Mathey für Elektronikx-Center-Matte ®. Die Nutzung, Vervielfältigung und Verbreitung unterliegt den Bedingungen der beigefügten Lizenz.

---
---

# Setup K8S by kubeadm

## Install kubelet

```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet
```

## Enable CRI

```
# comment out line: `disabled_plugins = ["cri"]`
sudo vim /etc/containerd/config.toml

# restart containerd
sudo systemctl restart containerd
```

## Setup K8S
```
# replace "172.26.10.67" with the IP address of your machine
sudo kubeadm init --ignore-preflight-errors Swap --apiserver-advertise-address=172.26.10.67 --pod-network-cidr=10.244.0.0/16
# follow instructions to copy kubeconfig file to $HOME/.kube/config


kubectl create -f https://raw.githubusercontent.com/coreos/flannel/v0.22.0/Documentation/kube-flannel.yml

or
https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
```

## Setup Hugepage
```
# set hugepage
sudo bash -c "echo 256 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages"

# restart kubelet
sudo systemctl restart kubelet

# check if kubelet has recognized huagepage
kubectl get nodes -oyaml | grep hugepages-2Mi
```

## Check Status

```
# check node status to be Ready
$kubectl get node
NAME                                              STATUS   ROLES           AGE    VERSION
ip-172-26-10-67.ap-northeast-1.compute.internal   Ready    control-plane   139m   v1.27.4

# all pods should be Running
$kubectl get pods --all-namespaces
NAMESPACE      NAME                                                                      READY   STATUS    RESTARTS      AGE
kube-flannel   kube-flannel-ds-h5dcn                                                     1/1     Running   0             138m
kube-system    coredns-5d78c9869d-g4x5w                                                  1/1     Running   0             139m
kube-system    coredns-5d78c9869d-x8hmd                                                  1/1     Running   0             139m
kube-system    etcd-ip-172-26-10-67.ap-northeast-1.compute.internal                      1/1     Running   0             139m
kube-system    kube-apiserver-ip-172-26-10-67.ap-northeast-1.compute.internal            1/1     Running   0             139m
kube-system    kube-controller-manager-ip-172-26-10-67.ap-northeast-1.compute.internal   1/1     Running   0             139m
kube-system    kube-proxy-zs75b                                                          1/1     Running   0             139m
kube-system    kube-scheduler-ip-172-26-10-67.ap-northeast-1.compute.internal            1/1     Running   0             139m
```

Deepseek
