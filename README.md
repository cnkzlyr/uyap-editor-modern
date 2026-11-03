# UYAP Editör Modern ⚡

Resmi **UYAP Doküman & Şablon Editörü** için geliştirilmiş çoklu platform (Linux, Windows, macOS, Android), 120Hz/240Hz akıcı kaydırma (smooth scroll), modern tema desteği (FlatLaf), sorunsuz `.udf` / `.usf` dosya ilişkilendirmesi ve tam e-imza (AKİS / Arkİmza / TBB Token) entegrasyonuna sahip modernizasyon paketi.

---

## 🚀 Öne Çıkan Özellikler

* **📄 Çift Tıklama ile Doğrudan Dosya Açma (.udf & .usf):**
  * Masaüstü veya dosya yöneticisinde (GNOME Nautilus, KDE Dolphin, Windows Explorer, macOS Finder) `.udf` ve `.usf` dosyalarına çift tıklandığında belgenin boş sayfa yerine eksiksiz olarak açılması.
  * `file://` URI çözümleme, URL-decode (`%20` ve Türkçe karakterler) ve otomatik mutlak yol dönüşümü.
  * Çoklu dosya seçimi desteği (birden fazla dosya seçilip Enter'a basıldığında tüm pencerelerin açılması).
  * `.udf` açılırken Doküman Editörü, `.usf` açılırken Şablon Editörü modunun otomatik devreye girmesi.
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
  * **Linux:** Fedora, Ubuntu, Debian, Pardus, Arch Linux (MIME tanımları ve HiDPI ikon seti dahil).
  * **Windows:** Windows 10 & 11 (PowerShell tek tıkla kurulum, sessiz VBS başlatıcı, `.udf`/`.usf` kayıt defteri eşleme).
  * **macOS:** Apple Silicon (M1/M2/M3/M4) ve Intel işlemcili Mac'ler (Doküman ve Şablon başlatıcıları).
  * **Android:** Termux & Termux:X11 + Fluxbox üzerinden tablet ve telefonlarda tam masaüstü UYAP deneyimi.

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
Kurulum sonrasında uygulama menünüzden **UYAP Doküman Editörü Modern** veya **UYAP Şablon Editörü Modern**'i açabilir, herhangi bir `.udf` ya da `.usf` dosyasına çift tıklayabilir veya terminalden şu komutları kullanabilirsiniz:
* Doküman Editörü: `uyap-dokuman [dosya.udf]`
* Şablon Editörü: `uyap-sablon [dosya.usf]`

### 2. Windows 10 & 11
PowerShell'i (Yönetici olarak) açın ve çalıştırın:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\platforms\windows\install.ps1
```
* Masaüstünüze siyah konsol penceresi açılmaksızın çalışan modern başlatıcı kısayolları eklenir.
* `.udf` ve `.usf` dosyaları otomatik olarak ilişkilendirilir; çift tıklandığında doğrudan belge açılır.

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

## 📝 Sürüm Notları (Changelog)

### v2.1.0 (2026-11-03)
* **⚡ Başlatıcı ve Symlink Yolu Düzeltmesi:**
  * `uyap-dokuman` ve `uyap-sablon` sembolik bağ (symlink) üzerinden çalıştırıldığında `BASH_SOURCE` yolunun `~/.local/bin` kalması ve `uyap-modernizer.jar` dosyasını bulamayıp uygulamanın açılmaması sorunu giderildi.
  * Kanonik dizin çözümleme (`readlink -f` / `dirname`) ve otomatik çoklu dizin tarama mantığı eklendi.
* **📂 Çift Tıklama Boş Sayfa Sorunu Giderildi:**
  * Dosya yöneticilerinde `.udf` ve `.usf` belgelerine çift tıklandığında editörün boş sayfa ile açılmasına sebep olan argüman iletim sorunu kökten çözüldü.
  * `file://` URI şemaları, URL encoding (`%20`, Türkçe karakter kodlamaları) ve bağıl yollar otomatik olarak sistem dosya yoluna dönüştürülüyor.
  * Çoklu dosya açma (birden fazla dosya seçilip açıldığında her biri için ayrı pencere oluşturulması) desteği eklendi.
* **🗂️ Eksiksiz MIME ve İkon Entegrasyonu:**
  * `udf.xml` Shared-MIME veritabanı tanımı Linux paketine dahil edildi (`.udf`, `.UDF`, `.usf`, `.USF`).
  * 16x16'dan 256x256'ya kadar tüm HiDPI belge ve şablon ikonları yerleştirildi.
  * Masaüstü kısayollarında `Categories` ve `StartupNotify` standartlaştırıldı.
* **🖥️ Windows, macOS ve Android İyileştirmeleri:**
  * Windows `dokuman.bat` ve `sablon.bat` içindeki `BASE_DIR` dizin tespiti ve tırnaklı dosya argümanı çözümlemesi güncellendi.
  * macOS için hem Doküman hem Şablon başlatıcıları ve Gatekeeper temizliği yapılandırıldı.
  * Android Termux başlatıcısına argüman çözümleme ve şablon/doküman algılama eklendi.

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
