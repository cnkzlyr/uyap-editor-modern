#!/bin/bash
set -e

# ==============================================================================
# UYAP Editör Modern - macOS Kurulum ve Gatekeeper Yapılandırma Betiği
# ==============================================================================

echo "=== UYAP Editör Modern - macOS Kurulumu ==="

APP_DIR="/Applications/UYAP Dokuman Editoru.app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$APP_DIR/Contents/Java"

echo "[1/3] Editör ve Modernizer dosyaları kopyalanıyor..."
cp -f "$SCRIPT_DIR/bin/dokuman.sh" "$APP_DIR/Contents/MacOS/dokuman"
chmod +x "$APP_DIR/Contents/MacOS/dokuman"

if [ -f "$ROOT_DIR/dist/uyap-modernizer.jar" ]; then
    cp -f "$ROOT_DIR/dist/uyap-modernizer.jar" "$APP_DIR/Contents/Java/"
fi

echo "[2/3] Gatekeeper karantina özellikleri temizleniyor..."
xattr -cr "$APP_DIR" 2>/dev/null || true

echo "[3/3] PKCS#11 e-imza bağlantıları..."
mkdir -p /usr/local/lib
if [ -f "/Library/Application Support/Akis/libakisp11.dylib" ]; then
    ln -sf "/Library/Application Support/Akis/libakisp11.dylib" /usr/local/lib/libakisp11.dylib
fi

echo "✓ macOS kurulumu tamamlandı. Uygulamalarınızdan UYAP Doküman Editörü'nü başlatabilirsiniz."
