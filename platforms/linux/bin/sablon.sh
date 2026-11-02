#!/bin/bash
# ==============================================================================
# UYAP Şablon Editörü - Modern Linux Başlatıcı
# Geliştirici: Can Kızılyar (github.com/cnkzlyr)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

[ -f "$HOME/.uki/uyap.conf" ] && . "$HOME/.uki/uyap.conf"

if [ -x "$BASE_DIR/jdk-14.0.2/bin/java" ]; then
    JAVA_CMD="$BASE_DIR/jdk-14.0.2/bin/java"
elif [ -x "$HOME/.local/share/jvm/jdk-14.0.2/bin/java" ]; then
    JAVA_CMD="$HOME/.local/share/jvm/jdk-14.0.2/bin/java"
elif [ -x "/usr/share/UYAPEditor/jdk-14.0.2/bin/java" ]; then
    JAVA_CMD="/usr/share/UYAPEditor/jdk-14.0.2/bin/java"
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

PCSC_LIB=""
for lib in /usr/lib64/libpcsclite.so.1 /usr/lib/x86_64-linux-gnu/libpcsclite.so.1 /usr/lib/libpcsclite.so.1 /lib64/libpcsclite.so.1 /usr/lib64/libpcsclite.so; do
    if [ -f "$lib" ]; then
        PCSC_LIB="$lib"
        break
    fi
done

export LD_LIBRARY_PATH="$HOME/.local/lib:$BASE_DIR:$BASE_DIR/jdk-14.0.2/lib:/usr/lib64:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
PKCS11_OPTS="-Djava.library.path=$HOME/.local/lib:$BASE_DIR:$BASE_DIR/jdk-14.0.2/lib:/usr/lib64:/usr/lib/x86_64-linux-gnu:/usr/lib"
[ -n "$PCSC_LIB" ] && PKCS11_OPTS="-Dsun.security.smartcardio.library=$PCSC_LIB $PKCS11_OPTS"

if [ "$UYAP_SCALE" != "" ] && [ "$UYAP_SCALE" != "auto" ]; then
    SCALE_OPTS="-Dsun.java2d.uiScale=$UYAP_SCALE"
else
    SCALE_OPTS="-Dsun.java2d.uiScale.enabled=true"
fi

FONT_OPTS="-Dawt.useSystemAAFontSettings=lcd -Dswing.aatext=true"
ACCEL_OPTS="-Dsun.java2d.xrender=false"
GC_OPTS="-XX:+UseG1GC -XX:+UseStringDeduplication"
MEM_OPTS="-Xms${UYAP_XMS:-256m} -Xmx${UYAP_XMX:-1024m}"
AGENT_OPTS="-javaagent:$BASE_DIR/uyap-modernizer.jar"

ALL_OPTS="$PKCS11_OPTS $MEM_OPTS $GC_OPTS $SCALE_OPTS $FONT_OPTS $ACCEL_OPTS $AGENT_OPTS"

exec "$JAVA_CMD" $ALL_OPTS -cp "$CP_PATH" tr.com.havelsan.uyap.system.editor.common.WPAppManager "getNewWPInstance" "EDITOR_TYPE_TEMPLATE" "$@"
