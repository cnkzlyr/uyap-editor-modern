# UYAP Editör Modern ⚡

Resmi **UYAP Doküman & Şablon Editörü** için geliştirilmiş çoklu platform (Linux, Windows, macOS, Android), 120Hz/240Hz akıcı kaydırma (smooth scroll), modern tema desteği (FlatLaf) ve tam e-imza (AKİS / Arkİmza / TBB Token) entegrasyonuna sahip modernizasyon paketi.

---

## 🚀 Öne Çıkan Özellikler

* **🎯 120Hz & 240Hz Akıcı Kaydırma (Word/Edge Stili):**
  * Ekran yenileme hızına duyarlı momentum ve üstel sönümleme algoritması.
  * Klavyeden tek tuşla açma/kapatma (**`F9`**).
* **🖊️ Tam E-İmza & Akıllı Kart Desteği:**
  * **Arkİmza** (ArkSigner / NES ECC) ve **TBB Kırmızı Token** (ACS ACR39U / TÜRKTRUST) otomatik sürücü ve slot algılama.
  * TÜBİTAK UEKAE ESYA API lisans denetim katmanı baypası (lisans hatası almadan sorunsuz e-imzalama).
* **🎨 Modern Arayüz Temaları (FlatLaf Entegre):**
  * Modern Açık (Flat Light) ve Modern Koyu (Flat Dark) tema seçenekleri.
  * Subpixel LCD font antialiasing ile keskin yazı tipi kalitesi.
* **📂 Kararlı ve Güvenilir Özgün Dosya Seçici:**
  * UYAP'ın tüm dosya türü filtrelerini (`*.udf`, `*.usf`, `*.pdf`, `*.*`) ve belge önizlemelerini destekleyen eksiksiz özgün dosya seçici.
* **🌐 Çoklu Platform Desteği:**
  * **Linux:** Fedora, Ubuntu, Debian, Pardus, Arch Linux.
  * **Windows:** Windows 10 & 11 (PowerShell tek tıkla kurulum, sessiz VBS başlatıcı).
  * **macOS:** Apple Silicon (M1/M2/M3/M4) ve Intel işlemcili Mac'ler.
  * **Android:** Termux & Termux:X11 üzerinden tablet ve telefonlarda tam masaüstü UYAP deneyimi.

---

## 📦 Kurulum ve Kullanım

### 1. Linux (Fedora, Ubuntu, Debian, Pardus, Arch)
Terminali açın ve tek satırda kurulumu gerçekleştirin:
```bash
git clone https://github.com/cnkzlyr/uyap-editor-modern.git
cd uyap-editor-modern/platforms/linux
chmod +x install.sh
./install.sh
```
Kurulum sonrasında uygulama menünüzden **UYAP Doküman Editörü Modern**'i açabilir veya terminalden şu komutları kullanabilirsiniz:
* Doküman Editörü: `uyap-dokuman`
* Şablon Editörü: `uyap-sablon`

### 2. Windows 10 & 11
PowerShell'i (Yönetici olarak) açın ve çalıştırın:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\platforms\windows\install.ps1
```
* Masaüstünüze siyah konsol penceresi açılmaksızın çalışan modern başlatıcı kısayolları eklenir ve `.udf` dosyaları otomatik olarak ilişkilendirilir.

### 3. macOS (Apple Silicon & Intel)
Terminalden çalıştırın:
```bash
cd platforms/macos
chmod +x install.sh
./install.sh
```

### 4. Android (Tablet & Telefon)
Android tabletlerde masaüstü UYAP Editör'ü çalıştırmak için:
1. **F-Droid**'den **Termux** ve **Termux:X11** uygulamalarını indirin.
2. Termux'a şu komutu yapıştırın:
   ```bash
   curl -sL https://raw.githubusercontent.com/cnkzlyr/uyap-editor-modern/main/platforms/android/termux-install.sh | bash
   ```
3. Kurulum bitince `uyap` yazarak tam editörü kullanın.

---

## 🛠️ Derleme (Geliştiriciler İçin)

Modernizer ajanını yeniden derlemek için:
```bash
chmod +x tools/build-agent.sh
./tools/build-agent.sh
```
Derlenen `uyap-modernizer.jar` dosyası `dist/` klasörüne oluşturulur.

---

## 🤖 Otomatik GitHub Sürüm Dağıtımı (CI/CD)

Yeni bir sürüm yayınlamak için depoya etiket (tag) göndermeniz yeterlidir:
```bash
git tag v2.1.0
git push origin v2.1.0
```
GitHub Actions iş akışı (`release.yml`) otomatik olarak devreye girerek Linux, Windows ve macOS için tüm kurulum paketlerini derler ve GitHub Releases sayfasına ekler.

---

## 📄 Lisans
Bu proje [Apache License 2.0](LICENSE) ile lisanslanmıştır. UYAP resmi kütüphanelerinin tüm hakları T.C. Adalet Bakanlığı'na aittir.
