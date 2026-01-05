# XTREME XAI v4.0 - Extended Support & Features Guide

## 📚 Erweiterte Unterstützung

Dieses Dokument beschreibt die erweiterten Features und Support-Tools von XTREME XAI v4.0.

---

## 🎮 Emulatoren & Virtualisierung

### Emulator Installer

**Script:** `scripts/emulator_installer.sh`

Automatische Installation und Konfiguration von:

#### 1. QEMU (Virtualisierung)
- **x86_64 VMs** - Vollständige PC-Virtualisierung
- **ARM64 VMs** - ARM-basierte Systeme
- **Custom ISOs** - Eigene Betriebssysteme installieren
- **Launcher Script** - Einfache VM-Verwaltung

**Verwendung:**
```bash
bash scripts/emulator_installer.sh
# Option 1 wählen für QEMU
# Dann: bash ~/xtreme_ai_system/emulators/qemu-launcher.sh
```

#### 2. PRoot / proot-distro
- **Ubuntu** - Vollständiges Ubuntu in Termux
- **Debian** - Stabile Debian-Umgebung
- **Arch Linux** - Rolling-Release Distribution
- **Alpine** - Leichtgewichtige Distribution

**Verwendung:**
```bash
bash scripts/emulator_installer.sh
# Option 2 wählen für PRoot
# Dann: bash ~/xtreme_ai_system/emulators/proot-helper.sh
```

**Quick Commands:**
```bash
# Ubuntu installieren
proot-distro install ubuntu

# Ubuntu starten
proot-distro login ubuntu

# In Ubuntu (als root)
apt update && apt upgrade
apt install python3 nodejs git
```

#### 3. Box64 (x86_64 auf ARM)
- Führt x86_64 Programme auf ARM64 aus
- Ideal für proprietäre Software
- Wrapper-Script für einfache Nutzung

**Verwendung:**
```bash
bash ~/xtreme_ai_system/emulators/box64-run.sh /path/to/x86_64_program
```

#### 4. Wine (Windows Emulation)
- Führt Windows .exe Programme aus
- Wine-Konfiguration
- Windows Explorer Integration

**Verwendung:**
```bash
bash ~/xtreme_ai_system/emulators/wine-helper.sh
```

#### 5. DosBox (DOS Emulation)
- Alte DOS-Spiele und Programme
- Konfigurierbar
- Launcher für einfachen Zugriff

**Verwendung:**
```bash
bash ~/xtreme_ai_system/emulators/dosbox-launcher.sh
```

#### 6. X11/VNC Support
- Desktop-Umgebung (XFCE4)
- VNC Server für Remote-Zugriff
- Grafische Anwendungen

**Verwendung:**
```bash
bash ~/xtreme_ai_system/emulators/start-vnc.sh
# Dann mit VNC Viewer zu localhost:5901 verbinden
```

---

## 🔐 VPN Integration

### VPN Manager

**Script:** `scripts/vpn_manager.sh`

Unterstützte VPN-Protokolle:

#### 1. OpenVPN
- Standard VPN-Protokoll
- .ovpn Konfigurations-Support
- Automatische Verbindungsverwaltung

**Setup:**
```bash
bash scripts/vpn_manager.sh
# Option 1 - OpenVPN installieren
# .ovpn Datei in ~/xtreme_ai_system/vpn/configs/ kopieren
# Über Manager verbinden
```

#### 2. WireGuard
- Modernes, schnelles VPN
- Schlüsselpaar-Generierung
- Einfache Konfiguration

**Setup:**
```bash
bash scripts/vpn_manager.sh
# Option 2 - WireGuard installieren
# Schlüsselpaar generieren
# .conf Datei erstellen
```

**WireGuard Konfigurationsbeispiel:**
```ini
[Interface]
PrivateKey = <dein_private_key>
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <server_public_key>
Endpoint = vpn.server.com:51820
AllowedIPs = 0.0.0.0/0
```

#### 3. Shadowsocks
- Proxy-basiertes VPN
- Umgeht Zensur
- JSON-Konfiguration

**Setup:**
```bash
bash scripts/vpn_manager.sh
# Option 3 - Shadowsocks installieren
# Config in ~/xtreme_ai_system/vpn/configs/shadowsocks.json erstellen
```

#### 4. V2Ray
- Fortgeschrittenes Proxy-Tool
- Multiple Protokolle
- Flexible Konfiguration

**Setup:**
```bash
bash scripts/vpn_manager.sh
# Option 4 - V2Ray installieren
```

### VPN Connection Tester

Testet VPN-Verbindungen umfassend:
```bash
bash ~/xtreme_ai_system/vpn/vpn-test.sh
```

**Prüft:**
- Gateway-Konfiguration
- DNS-Auflösung
- Internet-Konnektivität
- Externe IP-Adresse
- DNS-Server

---

## 🕵️ Tor Browser & Anonymität

### Tor Integration

**Script:** `scripts/tor_integration.sh`

#### 1. Tor Network
- SOCKS5 Proxy (Port 9050)
- Control Port (Port 9051)
- Anonymes Surfen

**Installation:**
```bash
bash scripts/tor_integration.sh
# Option 1 - Tor installieren
```

**Tor starten:**
```bash
bash ~/xtreme_ai_system/tor/tor-manager.sh
# Option 1 - Tor starten
```

#### 2. Tor Browser

**Optionen:**
1. **Offizielle Tor Browser App** (Empfohlen)
   - Download: https://www.torproject.org/download/#android
   - Vollständig integriert
   - Automatische Updates

2. **Firefox + Orbot**
   - Orbot aus F-Droid installieren
   - Firefox Proxy auf 127.0.0.1:9050 setzen

3. **Brave Browser mit Tor**
   - Integrierte Tor-Tabs
   - Einfach zu nutzen

#### 3. Orbot (Tor für Android)

**Setup:**
```bash
bash scripts/tor_integration.sh
# Option 3 - Orbot Setup-Anleitung
```

**Features:**
- VPN-Modus für alle Apps
- App-spezifisches Routing
- Transparent Proxy

#### 4. torsocks

Führt beliebige Befehle über Tor aus:

```bash
# Mit Tor-Wrapper
bash ~/xtreme_ai_system/tor/tor-wrapper.sh curl https://check.torproject.org

# Direkt
torsocks curl https://ifconfig.me
torsocks wget https://example.com
torsocks ssh user@host
```

#### 5. Hidden Services (.onion)

Eigene .onion-Adresse erstellen:

```bash
bash ~/xtreme_ai_system/tor/tor-manager.sh
# Option 8 - Hidden Service einrichten
# Local Port angeben (z.B. 8080)
# Onion-Adresse wird generiert
```

**Dein Service:**
```bash
# Starte lokalen Webserver
python -m http.server 8080

# Service ist über .onion-Adresse erreichbar
# Adresse in ~/.tor/hidden_service/hostname
```

#### 6. Neue Identität

IP-Adresse über Tor wechseln:

```bash
bash ~/xtreme_ai_system/tor/tor-manager.sh
# Option 7 - Neue Tor-Identität
```

### Tor Connection Test

```bash
bash ~/xtreme_ai_system/tor/tor-test.sh
```

**Prüft:**
- Tor-Status
- Tor-Verbindung
- Externe IP über Tor
- Vergleich mit normaler IP

---

## 🛠️ Zusätzliche Support-Tools

### 1. System Doctor (Erweitert)

**Script:** `scripts/system_doctor.sh`

**10-Punkt-Diagnose:**
1. Hardware (CPU, RAM, Temperatur)
2. Speicher (Intern + SD-Karte)
3. Netzwerk (Konnektivität, DNS)
4. Prozesse (Zombies, High CPU/RAM)
5. Installation (Verzeichnisse, Scripts)
6. Logs (Fehler-Analyse)
7. Sicherheit (Berechtigungen, Prozesse)
8. Performance (Load, I/O, Benchmarks)
9. Batterie (Termux)
10. Empfehlungen (Automatisch)

**Verwendung:**
```bash
bash scripts/system_doctor.sh
```

### 2. Storage Optimizer (Erweitert)

**Script:** `scripts/storage_optimizer.sh`

**Features:**
- Package-Manager-Cache (pkg, pip, npm)
- App-Cache-Bereinigung
- Alte Logs (>30 Tage)
- Große Dateien finden (>100MB)
- Duplikat-Erkennung
- Verzeichnis-Analyse
- Temp-Dateien-Cleanup

**Modi:**
```bash
# Interaktiv
bash scripts/storage_optimizer.sh

# Automatisch
bash scripts/storage_optimizer.sh auto

# Schnell (nur Caches)
bash scripts/storage_optimizer.sh quick
```

---

## 🎯 Use Cases & Szenarien

### Szenario 1: Entwicklungsumgebung

```bash
# 1. Linux-Distribution installieren
bash scripts/emulator_installer.sh
# PRoot → Ubuntu installieren

# 2. In Ubuntu wechseln
proot-distro login ubuntu

# 3. Dev-Tools installieren
apt update
apt install build-essential python3 nodejs git vim

# 4. Projekt klonen und entwickeln
git clone https://github.com/user/project
cd project
```

### Szenario 2: Anonymes Surfen

```bash
# 1. Tor installieren
bash scripts/tor_integration.sh
# Alle installieren (Option 6)

# 2. Tor starten
bash ~/xtreme_ai_system/tor/tor-manager.sh
# Tor starten (Option 1)

# 3. Verbindung testen
bash ~/xtreme_ai_system/tor/tor-test.sh

# 4. Tor Browser nutzen oder torsocks
torsocks firefox
```

### Szenario 3: VPN für alle Apps

```bash
# 1. VPN installieren
bash scripts/vpn_manager.sh
# WireGuard oder OpenVPN

# 2. Konfiguration hinzufügen
# .conf oder .ovpn in ~/xtreme_ai_system/vpn/configs/

# 3. Verbinden
bash ~/xtreme_ai_system/vpn/wireguard-manager.sh
# oder
bash ~/xtreme_ai_system/vpn/openvpn-manager.sh

# 4. Testen
bash ~/xtreme_ai_system/vpn/vpn-test.sh
```

### Szenario 4: Windows-Programme ausführen

```bash
# 1. Wine installieren
bash scripts/emulator_installer.sh
# Option 4 - Wine

# 2. Windows-Programm ausführen
bash ~/xtreme_ai_system/emulators/wine-helper.sh
# Option 1 - Programm ausführen
# .exe Pfad angeben
```

---

## 📋 Checkliste für optimale Nutzung

### Täglich
- [ ] System-Status im Dashboard prüfen
- [ ] Verbindungssicherheit checken (VPN/Tor)

### Wöchentlich
- [ ] Storage Optimizer ausführen
- [ ] Backup erstellen
- [ ] Logs überprüfen

### Monatlich
- [ ] System Doctor ausführen
- [ ] Updates installieren
- [ ] Alte Backups bereinigen
- [ ] Emulator-Updates prüfen

---

## 🔧 Troubleshooting

### Emulatoren

**Problem: QEMU startet nicht**
```bash
# Lösung: KVM-Support prüfen
ls -l /dev/kvm
# Falls nicht vorhanden: ohne KVM starten
qemu-system-x86_64 -m 2048 -smp 2 <weitere_optionen>
```

**Problem: PRoot-Distribution installiert nicht**
```bash
# Lösung: Cache leeren
rm -rf ~/.cache/proot-distro
proot-distro install ubuntu
```

### VPN

**Problem: VPN verbindet nicht**
```bash
# 1. Konfiguration prüfen
cat ~/xtreme_ai_system/vpn/configs/<config>

# 2. Logs checken
tail -50 ~/xtreme_ai_system/logs/vpn_*.log

# 3. Netzwerk testen
ping 8.8.8.8
```

**Problem: DNS nach VPN-Verbindung**
```bash
# Lösung: DNS manuell setzen
echo "nameserver 1.1.1.1" > /etc/resolv.conf
```

### Tor

**Problem: Tor verbindet nicht**
```bash
# 1. Tor neu starten
bash ~/xtreme_ai_system/tor/tor-manager.sh
# Option 4 - Tor neu starten

# 2. Logs prüfen
cat ~/.tor/tor.log

# 3. Ports prüfen
netstat -tunlp | grep 9050
```

**Problem: Tor ist langsam**
```bash
# Lösung: Neue Identität anfordern
bash ~/xtreme_ai_system/tor/tor-manager.sh
# Option 7 - Neue Tor-Identität
```

---

## 📚 Weiterführende Ressourcen

### Emulatoren
- QEMU Dokumentation: https://www.qemu.org/docs/
- PRoot Dokumentation: https://proot-me.github.io/
- Wine HQ: https://www.winehq.org/

### VPN
- OpenVPN: https://openvpn.net/
- WireGuard: https://www.wireguard.com/
- Shadowsocks: https://shadowsocks.org/

### Tor
- Tor Project: https://www.torproject.org/
- Tor Browser Manual: https://tb-manual.torproject.org/
- Orbot: https://guardianproject.info/apps/org.torproject.android/

---

## 💡 Pro-Tipps

### 1. Kombiniere Tools
```bash
# VPN + Tor für maximale Anonymität
# 1. VPN verbinden
# 2. Dann Tor starten
# 3. Routing: Du → VPN → Tor → Internet
```

### 2. Automatisierung
```bash
# Cron-Job für VPN
crontab -e
# VPN automatisch bei Boot starten
@reboot bash ~/xtreme_ai_system/vpn/openvpn-manager.sh start
```

### 3. Aliase
```bash
# In ~/.bashrc
alias startvpn='bash ~/xtreme_ai_system/vpn/wireguard-manager.sh'
alias starttor='bash ~/xtreme_ai_system/tor/tor-manager.sh'
alias ubuntu='proot-distro login ubuntu'
```

---

## 🎓 Lernressourcen

### Für Einsteiger
1. **Termux Tutorial** - Grundlagen
2. **VPN Basics** - Was ist ein VPN?
3. **Tor Einführung** - Anonymes Surfen

### Für Fortgeschrittene
1. **QEMU Virtualisierung** - VMs erstellen
2. **Hidden Services** - .onion Websites hosten
3. **Network Security** - VPN & Tor kombinieren

---

**© Elektronikx-Center-Matte ®**  
**Entwicklung: Alexander Mathey ©**

**Version:** 4.0.0  
**Status:** ✅ Production Ready mit erweiterten Features
