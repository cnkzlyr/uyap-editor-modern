#!/bin/bash
# ==============================================================================
# UYAP Doküman Editörü - Modern macOS Başlatıcı
# Apple Silicon (M1/M2/M3/M4) ve Intel Uyumlu
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

[ -f "$HOME/.uki/uyap.conf" ] && . "$HOME/.uki/uyap.conf"

if [ -x "$BASE_DIR/jdk-14.0.2/bin/java" ]; then
    JAVA_CMD="$BASE_DIR/jdk-14.0.2/bin/java"
elif [ -x "$BASE_DIR/Contents/Home/bin/java" ]; then
    JAVA_CMD="$BASE_DIR/Contents/Home/bin/java"
elif [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    JAVA_CMD="$JAVA_HOME/bin/java"
else
    JAVA_CMD="java"
fi

CP_PATH="$BASE_DIR/uyap-modernizer.jar:$BASE_DIR/."
for jar in "$BASE_DIR"/*.jar; do
    if [ "$jar" != "$BASE_DIR/*.jar" ] && [ "$jar" != "$BASE_DIR/uyap-modernizer.jar" ]; then
        CP_PATH="$CP_PATH:$jar"
    fi
done

# macOS PKCS#11 Kütüphane Yolları
PKCS11_OPTS="-Djava.library.path=/usr/local/lib:/opt/homebrew/lib:$BASE_DIR"

# macOS Native Menubar & Retina Ekran Ayarları
MAC_OPTS="-Dapple.laf.useScreenMenuBar=true -Dcom.apple.mrj.application.apple.menu.about.name=UYAP_Editor -Dapple.awt.application.appearance=system"
FONT_OPTS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"
MEM_OPTS="-Xms256m -Xmx1024m -XX:+UseG1GC -XX:+UseStringDeduplication"
AGENT_OPTS="-javaagent:$BASE_DIR/uyap-modernizer.jar"

ALL_OPTS="$PKCS11_OPTS $MAC_OPTS $MEM_OPTS $FONT_OPTS $AGENT_OPTS"

exec "$JAVA_CMD" $ALL_OPTS -cp "$CP_PATH" tr.com.havelsan.uyap.system.editor.common.WPAppManager "getNewWPInstance" "EDITOR_TYPE_DOCUMENT" "$@"
