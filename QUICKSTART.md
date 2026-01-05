# XTREME XAI v4.0 - Quick Start Guide

## 🚀 Schnellstart

Willkommen bei **XTREME XAI v4.0**! Diese Anleitung hilft dir, schnell loszulegen.

### 1️⃣ Installation (5 Minuten)

```bash
# Repository klonen
git clone https://github.com/xxxyalaxx90xxx/Alex-.git
cd Alex-

# Installation starten
bash install.sh
```

Der Installer führt automatisch durch:
- ✅ System-Pre-Checks
- ✅ Dependency-Installation
- ✅ Verzeichnis-Setup
- ✅ Konfiguration

### 2️⃣ Erste Schritte

#### Interaktives Menü öffnen
```bash
bash scripts/xai_menu.sh
```

Das Hauptmenü bietet Zugriff auf alle Funktionen:
1. System-Check ausführen
2. System optimieren
3. Backup erstellen
4. Performance-Monitor
5. Security-Check
und mehr...

#### System-Check durchführen
```bash
bash core/system_check.sh
```
Prüft Hardware, Software, Netzwerk und mehr.

#### System optimieren
```bash
bash core/optimization.sh
```
Optimiert CPU, RAM, Netzwerk und I/O.

### 3️⃣ Wichtige Befehle

#### Backup erstellen
```bash
bash core/backup_manager.sh create
```

#### Performance überwachen
```bash
bash scripts/performance.sh
```
Zeigt Echtzeit-Statistiken für CPU, RAM, Disk, Netzwerk.

#### Security-Scan
```bash
bash scripts/security.sh
```
Prüft auf Sicherheitsprobleme und Malware.

#### Speicher optimieren
```bash
bash scripts/storage_optimizer.sh
```
Bereinigt Caches, temporäre Dateien und mehr.

#### System-Diagnose
```bash
bash scripts/system_doctor.sh
```
Umfassende Diagnose mit Empfehlungen.

### 4️⃣ Web-Dashboard

```bash
# Dashboard öffnen (Methode 1)
termux-open web_ui/dashboard.html

# Dashboard mit Server (Methode 2)
cd web_ui
python -m http.server 8080
# Dann öffnen: http://localhost:8080/dashboard.html
```

### 5️⃣ Tipps & Tricks

#### Aliase einrichten
Füge zu `~/.bashrc` hinzu:
```bash
alias xai='bash ~/path/to/scripts/xai_menu.sh'
alias xai-check='bash ~/path/to/core/system_check.sh'
alias xai-optimize='bash ~/path/to/core/optimization.sh'
alias xai-backup='bash ~/path/to/core/backup_manager.sh'
alias xai-perf='bash ~/path/to/scripts/performance.sh'
```

Dann einfach `xai` eingeben für das Hauptmenü!

#### Automatische Optimierung
Für tägliche Optimierung:
```bash
crontab -e
# Füge hinzu:
0 3 * * * bash ~/path/to/core/optimization.sh > /dev/null 2>&1
```

#### Performance-Snapshot
Schneller Snapshot ohne Live-Monitoring:
```bash
bash scripts/performance.sh --snapshot
```

### 6️⃣ Fehlerbehebung

#### Problem: Installation schlägt fehl
```bash
pkg update -y && pkg upgrade -y
bash install.sh
```

#### Problem: Speicher voll
```bash
bash scripts/storage_optimizer.sh
```

#### Problem: System langsam
```bash
bash core/optimization.sh
bash scripts/system_doctor.sh
```

#### Problem: SD-Karte nicht erkannt
```bash
termux-setup-storage
```

### 7️⃣ Weitere Hilfe

#### Hilfe zu einzelnen Scripts
```bash
bash core/backup_manager.sh help
bash scripts/performance.sh --help
```

#### Logs überprüfen
```bash
ls -lh ~/xtreme_ai_system/logs/
tail -50 ~/xtreme_ai_system/logs/performance_*.log
```

#### System-Status
```bash
bash scripts/system_doctor.sh
```

### 8️⃣ Best Practices

✅ **Täglich:**
- Performance-Monitor kurz checken
- System-Status im Dashboard ansehen

✅ **Wöchentlich:**
- Backup erstellen
- Security-Scan durchführen
- Storage-Optimizer ausführen

✅ **Monatlich:**
- Vollständige System-Diagnose
- Alte Logs bereinigen
- Updates installieren

### 9️⃣ Erweiterte Features

#### Backup automatisieren
```bash
# Tägliches Backup um 2 Uhr nachts
crontab -e
# Füge hinzu:
0 2 * * * bash ~/path/to/core/backup_manager.sh create
```

#### Performance-Logging
```bash
# Kontinuierliches Logging im Hintergrund
nohup bash scripts/performance.sh --snapshot >> ~/perf.log 2>&1 &
```

#### Dashboard als Service
```bash
# In tmux/screen Session starten
tmux new -s xai-dashboard
cd web_ui
python -m http.server 8080
# Detach mit Ctrl+B, dann D
```

### 🎯 Nächste Schritte

1. ✅ Installation abschließen
2. ✅ Ersten System-Check durchführen
3. ✅ Dashboard aufrufen
4. ✅ Erstes Backup erstellen
5. ✅ Konfiguration anpassen

### 📚 Weitere Dokumentation

- **README.md** - Vollständige Dokumentation
- **IMPLEMENTATION_SUMMARY.md** - Technische Details
- **config.template.conf** - Konfigurationsvorlage

### 💬 Support

Bei Problemen:
1. System-Doctor ausführen
2. Logs überprüfen
3. README konsultieren

---

**Version:** 4.0.0  
**© Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©**

**Status:** ✅ Production Ready
