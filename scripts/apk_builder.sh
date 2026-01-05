#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# XTREME XA-vI v4.0 - APK Builder
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
BUILD_TOOLS_DIR="$INSTALL_DIR/android-build-tools"
OUTPUT_DIR="$INSTALL_DIR/apk-output"

# ==============================================================================
# BANNER
# ==============================================================================
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║          📦 XTREME XA-vI APK BUILDER v4.0 📦                    ║
║                                                                  ║
║  Baue Android APKs direkt auf Termux                            ║
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

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# ==============================================================================
# ANDROID SDK SETUP
# ==============================================================================
setup_android_sdk() {
    log_info "Prüfe Android Build Tools..."
    
    if [ ! -d "$BUILD_TOOLS_DIR" ]; then
        log_warn "Android Build Tools nicht gefunden"
        read -p "Jetzt installieren? (j/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Jj]$ ]]; then
            install_build_tools
        else
            log_error "Build Tools erforderlich!"
            return 1
        fi
    fi
    
    log_success "Build Tools verfügbar"
}

install_build_tools() {
    log_info "Installiere Android Build Tools..."
    
    # Installiere erforderliche Pakete
    pkg install -y wget aapt apksigner dx ecj
    
    mkdir -p "$BUILD_TOOLS_DIR"
    
    # AAPT (Android Asset Packaging Tool)
    if ! command -v aapt >/dev/null 2>&1; then
        log_info "Installiere AAPT..."
        pkg install -y aapt
    fi
    
    # DX (Dex Compiler)
    if ! command -v dx >/dev/null 2>&1; then
        log_info "Installiere DX..."
        pkg install -y dx
    fi
    
    # APKSigner
    if ! command -v apksigner >/dev/null 2>&1; then
        log_info "Installiere APKSigner..."
        pkg install -y apksigner
    fi
    
    # ECJ (Eclipse Java Compiler)
    if ! command -v ecj >/dev/null 2>&1; then
        log_info "Installiere ECJ..."
        pkg install -y ecj
    fi
    
    log_success "Build Tools installiert"
}

# ==============================================================================
# KEYSTORE ERSTELLEN
# ==============================================================================
create_keystore() {
    local keystore_file="$BUILD_TOOLS_DIR/xtreme.keystore"
    
    if [ -f "$keystore_file" ]; then
        log_info "Keystore existiert bereits"
        return 0
    fi
    
    log_info "Erstelle Keystore für APK-Signierung..."
    
    keytool -genkeypair \
        -v \
        -keystore "$keystore_file" \
        -alias xtreme \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass xtreme123 \
        -keypass xtreme123 \
        -dname "CN=Elektronikx-Center-Matte, OU=Development, O=XTREME, L=City, S=State, C=DE"
    
    log_success "Keystore erstellt: $keystore_file"
}

# ==============================================================================
# APK AUS PROJEKT BAUEN
# ==============================================================================
build_apk_from_project() {
    local project_dir="$1"
    
    if [ ! -d "$project_dir" ]; then
        log_error "Projektverzeichnis nicht gefunden: $project_dir"
        return 1
    fi
    
    cd "$project_dir"
    
    log_info "Baue APK aus Projekt: $(basename "$project_dir")"
    
    # Prüfe Projektstruktur
    if [ ! -f "app/src/main/AndroidManifest.xml" ]; then
        log_error "Kein gültiges Android-Projekt!"
        return 1
    fi
    
    # Projekt-Setup
    local app_name=$(basename "$project_dir")
    local build_dir="$project_dir/build"
    local output_apk="$OUTPUT_DIR/${app_name}.apk"
    
    mkdir -p "$build_dir"/{gen,obj,apk}
    mkdir -p "$OUTPUT_DIR"
    
    # 1. Ressourcen kompilieren
    log_info "[1/5] Kompiliere Ressourcen..."
    aapt package -f -m \
        -J "$build_dir/gen" \
        -M app/src/main/AndroidManifest.xml \
        -S app/src/main/res \
        -I "$PREFIX/share/java/android.jar" \
        -F "$build_dir/resources.ap_"
    
    # 2. Java-Quellen kompilieren
    log_info "[2/5] Kompiliere Java-Quellen..."
    
    find app/src/main/java -name "*.java" > "$build_dir/sources.txt"
    find "$build_dir/gen" -name "*.java" >> "$build_dir/sources.txt"
    
    ecj -d "$build_dir/obj" \
        -classpath "$PREFIX/share/java/android.jar" \
        @"$build_dir/sources.txt"
    
    # 3. DEX erstellen
    log_info "[3/5] Erstelle DEX..."
    dx --dex --output="$build_dir/classes.dex" "$build_dir/obj"
    
    # 4. APK zusammenbauen
    log_info "[4/5] Baue APK..."
    cd "$build_dir"
    
    # Kopiere DEX in APK-Struktur
    mkdir -p apk
    cp classes.dex apk/
    
    # Erstelle unsigned APK
    cd apk
    aapt package -f \
        -M "$project_dir/app/src/main/AndroidManifest.xml" \
        -S "$project_dir/app/src/main/res" \
        -I "$PREFIX/share/java/android.jar" \
        -F "$build_dir/unsigned.apk" .
    
    # Füge DEX hinzu
    cd "$build_dir"
    aapt add unsigned.apk classes.dex
    
    # 5. APK signieren
    log_info "[5/5] Signiere APK..."
    apksigner sign \
        --ks "$BUILD_TOOLS_DIR/xtreme.keystore" \
        --ks-key-alias xtreme \
        --ks-pass pass:xtreme123 \
        --key-pass pass:xtreme123 \
        --out "$output_apk" \
        unsigned.apk
    
    log_success "APK erfolgreich gebaut!"
    log_info "Ausgabe: $output_apk"
    
    # APK-Info
    local apk_size=$(du -h "$output_apk" | cut -f1)
    log_info "Größe: $apk_size"
}

# ==============================================================================
# WEB APP ZU APK
# ==============================================================================
webapp_to_apk() {
    echo -e "\n${BLUE}${BOLD}=== Web App zu APK Converter ===${NC}\n"
    
    read -p "App Name: " app_name
    read -p "Package Name (com.example.app): " package_name
    read -p "Web URL oder lokaler Pfad: " web_source
    
    local build_dir="$INSTALL_DIR/temp/webapp_${app_name}"
    
    mkdir -p "$build_dir/app/src/main"/{java,res,assets}
    mkdir -p "$build_dir/app/src/main/res"/{layout,values,drawable,mipmap}
    
    cd "$build_dir"
    
    # Wenn lokaler Pfad, kopiere Web-Dateien
    if [ -d "$web_source" ]; then
        log_info "Kopiere Web-Dateien..."
        cp -r "$web_source"/* app/src/main/assets/
    fi
    
    # Android Manifest
    cat > app/src/main/AndroidManifest.xml << MANIFEST
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="${package_name}">
    
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="${app_name}"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">
        
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
MANIFEST
    
    # MainActivity mit WebView
    local java_path=$(echo "$package_name" | tr '.' '/')
    mkdir -p "app/src/main/java/${java_path}"
    
    cat > "app/src/main/java/${java_path}/MainActivity.java" << JAVA
package ${package_name};

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebSettings;
import android.webkit.WebViewClient;

/**
 * XTREME XA-vI Web App
 * © Elektronikx-Center-Matte ®
 * by Alexander Mathey (xyalaxxx90@gmail.com)
 */
public class MainActivity extends Activity {
    private WebView webView;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        
        webView.setWebViewClient(new WebViewClient());
        
        // Lade URL oder lokale Datei
        String url = "${web_source}";
        if (url.startsWith("http")) {
            webView.loadUrl(url);
        } else {
            webView.loadUrl("file:///android_asset/index.html");
        }
        
        setContentView(webView);
    }
    
    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
JAVA
    
    # strings.xml
    cat > app/src/main/res/values/strings.xml << STRINGS
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">${app_name}</string>
</resources>
STRINGS
    
    # Baue APK
    build_apk_from_project "$build_dir"
    
    # Cleanup
    rm -rf "$build_dir"
}

# ==============================================================================
# SIMPLE APK ERSTELLEN
# ==============================================================================
create_simple_apk() {
    echo -e "\n${BLUE}${BOLD}=== Einfache APK erstellen ===${NC}\n"
    
    read -p "App Name: " app_name
    read -p "Package Name (com.example.app): " package_name
    read -p "App Text/Nachricht: " app_message
    
    local build_dir="$INSTALL_DIR/temp/simple_${app_name}"
    
    mkdir -p "$build_dir/app/src/main"/{java,res/values}
    cd "$build_dir"
    
    # Android Manifest
    cat > app/src/main/AndroidManifest.xml << MANIFEST
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="${package_name}">
    
    <application
        android:allowBackup="true"
        android:label="${app_name}">
        
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
MANIFEST
    
    # MainActivity
    local java_path=$(echo "$package_name" | tr '.' '/')
    mkdir -p "app/src/main/java/${java_path}"
    
    cat > "app/src/main/java/${java_path}/MainActivity.java" << JAVA
package ${package_name};

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.LinearLayout;
import android.graphics.Color;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setBackgroundColor(Color.parseColor("#667eea"));
        layout.setPadding(50, 50, 50, 50);
        
        TextView titleView = new TextView(this);
        titleView.setText("${app_name}");
        titleView.setTextSize(24);
        titleView.setTextColor(Color.WHITE);
        titleView.setPadding(0, 0, 0, 30);
        
        TextView messageView = new TextView(this);
        messageView.setText("${app_message}");
        messageView.setTextSize(16);
        messageView.setTextColor(Color.WHITE);
        messageView.setPadding(0, 0, 0, 30);
        
        TextView copyrightView = new TextView(this);
        copyrightView.setText("© Elektronikx-Center-Matte ®\\nby Alexander Mathey");
        copyrightView.setTextSize(12);
        copyrightView.setTextColor(Color.LTGRAY);
        
        layout.addView(titleView);
        layout.addView(messageView);
        layout.addView(copyrightView);
        
        setContentView(layout);
    }
}
JAVA
    
    # strings.xml
    cat > app/src/main/res/values/strings.xml << STRINGS
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">${app_name}</string>
</resources>
STRINGS
    
    # Baue APK
    build_apk_from_project "$build_dir"
    
    # Cleanup
    rm -rf "$build_dir"
}

# ==============================================================================
# HAUPTMENÜ
# ==============================================================================
show_menu() {
    while true; do
        show_banner
        
        echo -e "${BOLD}APK Builder Optionen:${NC}\n"
        echo "  1) APK aus Android-Projekt bauen"
        echo "  2) Web App zu APK konvertieren"
        echo "  3) Einfache APK erstellen"
        echo "  4) Build Tools installieren/prüfen"
        echo "  5) Keystore erstellen"
        echo "  6) Gebaute APKs anzeigen"
        echo "  0) Beenden"
        echo ""
        
        read -p "Auswahl [0-6]: " choice
        
        case $choice in
            1)
                echo ""
                read -p "Projekt-Pfad: " project_path
                build_apk_from_project "$project_path"
                read -p "Drücke Enter zum Fortfahren..."
                ;;
            2)
                webapp_to_apk
                read -p "Drücke Enter zum Fortfahren..."
                ;;
            3)
                create_simple_apk
                read -p "Drücke Enter zum Fortfahren..."
                ;;
            4)
                install_build_tools
                read -p "Drücke Enter zum Fortfahren..."
                ;;
            5)
                create_keystore
                read -p "Drücke Enter zum Fortfahren..."
                ;;
            6)
                echo -e "\n${CYAN}=== Gebaute APKs ===${NC}\n"
                if [ -d "$OUTPUT_DIR" ]; then
                    ls -lh "$OUTPUT_DIR"/*.apk 2>/dev/null || echo "Keine APKs gefunden"
                else
                    echo "Output-Verzeichnis nicht gefunden"
                fi
                echo ""
                read -p "Drücke Enter zum Fortfahren..."
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
    setup_android_sdk
    create_keystore
    show_menu
}

main "$@"
