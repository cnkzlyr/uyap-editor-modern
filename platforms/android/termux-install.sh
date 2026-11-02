#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# UYAP Editör Modern - Android Tablet / Telefon Kurulum Betiği
# Termux + Termux:X11 Üzerinde Tam Masaüstü UYAP Editörü
# ==============================================================================

set -e

echo "=== Android UYAP Editör Modern Kurulumu ==="

# 1. Gerekli paketleri güncelle ve yükle
pkg update -y
pkg install -y openjdk-17 x11-repo termux-x11-nightly virglrenderer-android pulseaudio wget tar

# 2. Çalışma klasörü oluştur
mkdir -p ~/uyap-editor
cd ~/uyap-editor

# 3. UYAP Editör paketini indir ve aç
if [ ! -f "editor_lib.jar" ]; then
    echo "UYAP Editör dosyaları indiriliyor..."
    wget -O uyap.zip "https://rayp.adalet.gov.tr/resimler/2/dosya/uyapeditor_5.4.20_amd64.zip"
    unzip -q -o uyap.zip
    rm uyap.zip
fi

# 4. Android başlatıcı betiği oluştur
cat << 'EOF' > ~/uyap-editor/run-android.sh
#!/data/data/com.termux/files/usr/bin/bash
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1

# X11 başlatıcı
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null || true
sleep 1

cd ~/uyap-editor
CP="."
for j in *.jar; do CP="$CP:$j"; done

java -Xms128m -Xmx512m \
     -Dsun.java2d.uiScale=1.5 \
     -Dawt.useSystemAAFontSettings=on \
     -Dswing.aatext=true \
     -cp "$CP" tr.com.havelsan.uyap.system.editor.common.WPAppManager "getNewWPInstance" "EDITOR_TYPE_DOCUMENT" "$@"
EOF

chmod +x ~/uyap-editor/run-android.sh
ln -sf ~/uyap-editor/run-android.sh $PREFIX/bin/uyap

echo "✓ Kurulum tamamlandı!"
echo "Çalıştırmak için: 'uyap' komutunu yazmanız ve ekranda açılan Termux:X11 penceresine geçmeniz yeterlidir."
