#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# UYAP Editör Modern - Android Tablet / Telefon Kurulum Betiği
# Termux + Termux:X11 Üzerinde Tam Masaüstü UYAP Editörü
# ==============================================================================

set -e

echo "=== Android UYAP Editör Modern Kurulumu ==="

# 1. Gerekli paketleri güncelle ve yükle
pkg update -y
pkg install -y x11-repo wget tar unzip
pkg update -y
pkg install -y openjdk-17 termux-x11-nightly pulseaudio

# 2. Çalışma klasörü oluştur
mkdir -p ~/uyap-editor
cd ~/uyap-editor

# 3. UYAP Editör paketini indir ve aç
if [ ! -f "editor_lib.jar" ]; then
    echo "UYAP Editör paketleri indiriliyor..."
    wget -c -O uyap.zip "https://rayp.adalet.gov.tr/resimler/2/dosya/uyapeditor_5.4.20_amd64.zip"
    unzip -q -o uyap.zip
    rm -f uyap.zip
    
    echo "DEB paketi açılıyor..."
    dpkg -x uyapeditor_5.4.20_amd64.deb . 2>/dev/null || (ar -x uyapeditor_5.4.20_amd64.deb && tar -xf data.tar.*)
    mv usr/share/UYAPEditor/*.jar .
    [ -d "usr/share/UYAPEditor/images" ] && mv usr/share/UYAPEditor/images .
    rm -rf usr cups-bsd* uyapeditor* data.tar.* control.tar.* debian-binary 2>/dev/null || true
fi

# 4. Android başlatıcı betiği oluştur
cat << 'EOF' > ~/uyap-editor/run-android.sh
#!/data/data/com.termux/files/usr/bin/bash
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1

# X11 Sunucusu ve Ekranı Başlat
if ! pgrep -f "termux-x11" >/dev/null; then
    termux-x11 :0 >/dev/null 2>&1 &
    sleep 1
fi
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null || true
sleep 1

cd ~/uyap-editor
CP="."
for j in *.jar; do CP="$CP:$j"; done

java --add-opens java.base/java.lang=ALL-UNNAMED \
     --add-opens java.base/java.lang.reflect=ALL-UNNAMED \
     --add-opens java.base/java.util=ALL-UNNAMED \
     --add-opens java.desktop/java.awt=ALL-UNNAMED \
     --add-opens java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens java.desktop/sun.awt=ALL-UNNAMED \
     --add-opens java.desktop/sun.swing=ALL-UNNAMED \
     -Xms128m -Xmx768m \
     -Dsun.java2d.uiScale=1.25 \
     -Dawt.useSystemAAFontSettings=on \
     -Dswing.aatext=true \
     -cp "$CP" tr.com.havelsan.uyap.system.editor.common.WPAppManager "getNewWPInstance" "EDITOR_TYPE_DOCUMENT" "$@"
EOF

chmod +x ~/uyap-editor/run-android.sh
ln -sf ~/uyap-editor/run-android.sh $PREFIX/bin/uyap

echo "✓ Kurulum tamamlandı!"
echo "Çalıştırmak için: 'uyap' komutunu yazmanız ve ekranda açılan Termux:X11 penceresine geçmeniz yeterlidir."
