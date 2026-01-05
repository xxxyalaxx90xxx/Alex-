# XAI v4.0.0 - Termux Installation Guide

## Schnell-Installation für Termux auf Android

### Voraussetzungen
- **Android-Gerät**: Realme C63 RMX3939 (oder kompatibel)
- **Termux installiert**: Von F-Droid (empfohlen) oder GitHub
- **Internetverbindung**: Aktiv und stabil
- **Freier Speicher**: Mindestens 10GB

---

## Installation in 3 Schritten

### Schritt 1: Termux vorbereiten

```bash
# Termux Storage-Berechtigungen aktivieren
termux-setup-storage

# Paketlisten aktualisieren
pkg update && pkg upgrade -y

# Git installieren
pkg install git -y
```

---

### Schritt 2: XAI v4.0.0 herunterladen und installieren

```bash
# Repository klonen
git clone https://github.com/xxxyalaxx90xxx/Alex-.git

# In das Verzeichnis wechseln
cd Alex-

# Installationsscript ausführbar machen
chmod +x install.sh xai-setup.sh xai.sh

# Installation starten
./install.sh
```

**Hinweis**: Die Installation dauert je nach Internetgeschwindigkeit 10-30 Minuten.

---

### Schritt 3: XAI starten

```bash
# XAI Launcher starten
./xai.sh

# ODER nach neuer Shell-Sitzung:
xai
```

---

## Vollständiger One-Liner

Für erfahrene Benutzer - Installation in einem Befehl:

```bash
termux-setup-storage && pkg update && pkg upgrade -y && pkg install git -y && git clone https://github.com/xxxyalaxx90xxx/Alex-.git && cd Alex- && chmod +x install.sh xai-setup.sh xai.sh && ./install.sh
```

---

## Nach der Installation

### Verfügbare Kommandos

```bash
# XAI starten
xai

# System-Status anzeigen
xai-status

# Logs live verfolgen
xai-logs

# Oder direkt:
./xai.sh status
./xai.sh logs
./xai.sh version
./xai.sh help
```

### XAI Menu-Optionen

Beim Start von `xai` erscheint ein interaktives Menü:

```
1. System-Status anzeigen
2. AI-Module starten
3. Konfiguration bearbeiten
4. Updates durchführen
5. Logs anzeigen
6. System beenden
```

---

## Verzeichnisstruktur nach Installation

```
~/xai/
├── bin/          # Ausführbare Dateien
│   └── xai       # XAI Launcher
├── config/       # Konfigurationsdateien
│   ├── env.sh
│   ├── config.json
│   └── autostart.sh
├── data/         # Daten
├── logs/         # Log-Dateien
│   └── xai.log
└── models/       # AI-Modelle
```

---

## Troubleshooting

### Problem: "Permission denied"
```bash
chmod +x install.sh xai-setup.sh xai.sh
```

### Problem: "No space left on device"
```bash
# Speicherplatz prüfen
df -h .
# Alte Dateien löschen oder auf SD-Karte verschieben
```

### Problem: "pip install failed"
```bash
# Einzelne Pakete manuell installieren
pip install numpy pandas requests colorama rich
```

### Problem: Termux Storage nicht verfügbar
```bash
# Berechtigungen erneut erteilen
termux-setup-storage
# Termux App-Berechtigungen in Android-Einstellungen prüfen
```

### Problem: Installation schlägt fehl
```bash
# Logs prüfen
cat ~/.xai_install_logs/pip_install.log

# Termux zurücksetzen und neu versuchen
pkg clean
pkg update && pkg upgrade -y
```

---

## Updates

### XAI aktualisieren
```bash
cd ~/Alex-
git pull
./install.sh
```

### System-Pakete aktualisieren
```bash
pkg update && pkg upgrade -y
```

### Python-Pakete aktualisieren
```bash
cd ~/Alex-
pip install --upgrade -r requirements.txt
```

---

## Deinstallation

```bash
# XAI Verzeichnis entfernen
rm -rf ~/xai

# Repository entfernen
rm -rf ~/Alex-

# Bash-Profile bereinigen (optional)
nano ~/.bashrc
# Entferne die XAI-Konfigurationszeilen
```

---

## Systemanforderungen

| Komponente | Minimum | Empfohlen | Realme C63 |
|------------|---------|-----------|------------|
| **CPU** | ARM64/aarch64 | 8 Kerne | Unisoc Tiger T612 (8 Kerne) |
| **RAM** | 4GB | 8GB | 8GB LPDDR4X |
| **Speicher** | 10GB frei | 20GB frei | 256GB UFS 2.2 |
| **Android** | 7.0+ | 11.0+ | Android (Termux) |
| **Internet** | WLAN/Mobile | WLAN | Erforderlich |

---

## Wichtige Hinweise

⚠️ **pip upgrade ist in Termux verboten** - Nicht versuchen, pip zu aktualisieren!

⚠️ **Batterieverbrauch** - Installation kann batterieverbrauchend sein, Netzteil empfohlen

⚠️ **Speicherplatz** - Stelle sicher, dass mindestens 10GB frei sind

⚠️ **Termux-Berechtigungen** - Storage-Zugriff muss erlaubt sein

✅ **Kompatibilität** - Optimiert für Realme C63 RMX3939, funktioniert auf den meisten ARM64 Android-Geräten

---

## Support

- **Repository**: https://github.com/xxxyalaxx90xxx/Alex-
- **Entwickler**: Alexander Mathey ©
- **Organisation**: Elektronikx-Center-Matte ®
- **Version**: 4.0.0
- **Datum**: 2026-01-05

---

## Copyright

**© Elektronikx-Center-Matte ®**  
**© Alexander Mathey 2026**

Alle Rechte vorbehalten.
