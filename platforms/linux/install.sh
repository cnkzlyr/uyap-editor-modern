#!/bin/bash
set -e

# ==============================================================================
# UYAP Editör Modern - Linux Tek Tıkla Kurulum Betiği
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== UYAP Editör Modern Kurulumu ===${NC}"

INSTALL_DIR="$HOME/.local/share/uyap-editor-modern"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
MIME_DIR="$HOME/.local/share/mime"
ICONS_DIR="$HOME/.local/share/icons/hicolor"

mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$DESKTOP_DIR" "$MIME_DIR/packages" "$ICONS_DIR"

echo -e "[1/5] Editör dosyaları hazırlanıyor..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# JAR dosyalarını kopyala
if [ -d "/usr/share/UYAPEditor" ]; then
    cp -rf /usr/share/UYAPEditor/*.jar "$INSTALL_DIR/" 2>/dev/null || true
    [ -d "/usr/share/UYAPEditor/images" ] && cp -rf /usr/share/UYAPEditor/images "$INSTALL_DIR/"
fi

# Modernizer JAR'ı kopyala
if [ -f "$ROOT_DIR/dist/uyap-modernizer.jar" ]; then
    cp -f "$ROOT_DIR/dist/uyap-modernizer.jar" "$INSTALL_DIR/"
fi

# Başlatıcıları kopyala
cp -f "$SCRIPT_DIR/bin/dokuman.sh" "$INSTALL_DIR/"
cp -f "$SCRIPT_DIR/bin/sablon.sh" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/dokuman.sh" "$INSTALL_DIR/sablon.sh"

ln -sf "$INSTALL_DIR/dokuman.sh" "$BIN_DIR/uyap-dokuman"
ln -sf "$INSTALL_DIR/sablon.sh" "$BIN_DIR/uyap-sablon"

echo -e "[2/5] Java 14.0.2 kontrol ediliyor..."
if [ ! -d "$INSTALL_DIR/jdk-14.0.2" ]; then
    if [ -d "/usr/share/UYAPEditor/jdk-14.0.2" ]; then
        ln -sf /usr/share/UYAPEditor/jdk-14.0.2 "$INSTALL_DIR/jdk-14.0.2"
    elif [ -d "$HOME/.local/share/jvm/jdk-14.0.2" ]; then
        ln -sf "$HOME/.local/share/jvm/jdk-14.0.2" "$INSTALL_DIR/jdk-14.0.2"
    else
        echo "OpenJDK 14.0.2 indiriliyor..."
        curl -sL "https://download.java.net/java/GA/jdk14.0.2/205943a0927447a7be1a4c57fb773708/12/GPL/openjdk-14.0.2_linux-x64_bin.tar.gz" | tar -xz -C "$INSTALL_DIR"
    fi
fi

echo -e "[3/5] E-İmza sürücü ve kütüphane bağlantıları..."
mkdir -p "$HOME/.local/lib"
if [ -f "$HOME/.local/opt/Akia/libakisp11.so" ]; then
    ln -sf "$HOME/.local/opt/Akia/libakisp11.so" "$HOME/.local/lib/libakisp11.so"
fi

echo -e "[4/5] Masaüstü kısayolları ve MIME ilişkilendirmeleri..."
cp -f "$SCRIPT_DIR/desktop/"*.desktop "$DESKTOP_DIR/" 2>/dev/null || true
cp -f "$SCRIPT_DIR/desktop/"*.xml "$MIME_DIR/packages/" 2>/dev/null || true

update-mime-database "$MIME_DIR" 2>/dev/null || true
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo -e "[5/5] Yapılandırma dosyaları..."
mkdir -p "$HOME/.uki"
[ ! -f "$HOME/.uki/modernizer.properties" ] && cp -f "$ROOT_DIR/config/modernizer.properties" "$HOME/.uki/"
[ ! -f "$HOME/.uki/uyap.conf" ] && cp -f "$ROOT_DIR/config/uyap.conf" "$HOME/.uki/"

echo -e "${GREEN}✓ Kurulum başarıyla tamamlandı!${NC}"
echo -e "Çalıştırmak için: ${BLUE}uyap-dokuman${NC} veya ${BLUE}uyap-sablon${NC}"
