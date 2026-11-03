# ==============================================================================
# UYAP Editor Modern - Windows Otomatik Kurulum ve Yapilandirma Betigi
# PowerShell 5.1+ Uyumlu
# ==============================================================================

Write-Host "=== UYAP Editor Modern - Windows Kurulumu ===" -ForegroundColor Cyan

$InstallDir = "$env:LOCALAPPDATA\UYAPEditorModern"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$CacheDir = "$env:TEMP\uyap_install_cache"

if (-not (Test-Path $CacheDir)) {
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}

# 1. Klasorleri Olustur
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

Write-Host "[1/6] Editor dosyalari kopyalaniyor..." -ForegroundColor Yellow
Copy-Item -Path "$ScriptDir\bin\*" -Destination $InstallDir -Force
if (Test-Path "$RootDir\dist\uyap-modernizer.jar") {
    Copy-Item -Path "$RootDir\dist\uyap-modernizer.jar" -Destination $InstallDir -Force
}

# Resmi UYAP kurulu ise JAR ve varliklari kopyala
$FoundUyap = $false
$OfficialDirs = @(
    (Join-Path ${env:ProgramFiles(x86)} "UYAP\UYAPEditor"),
    (Join-Path $env:ProgramFiles "UYAP\UYAPEditor"),
    "C:\UYAPEditor"
)
foreach ($dir in $OfficialDirs) {
    if (Test-Path "$dir\editor_lib.jar") {
        Write-Host "Resmi UYAP kurulumu bulundu ($dir), kütüphaneler kopyalanıyor..." -ForegroundColor Green
        Copy-Item -Path "$dir\*.jar" -Destination $InstallDir -Force -ErrorAction SilentlyContinue
        Copy-Item -Path "$dir\*.ico" -Destination $InstallDir -Force -ErrorAction SilentlyContinue
        Copy-Item -Path "$dir\*.gif" -Destination $InstallDir -Force -ErrorAction SilentlyContinue
        if (Test-Path "$dir\images") {
            Copy-Item -Path "$dir\images" -Destination $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$dir\jdk-14.0.2") {
            Copy-Item -Path "$dir\jdk-14.0.2" -Destination $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        $FoundUyap = $true
        break
    }
}

# Resmi UYAP bulunamadıysa ve kütüphaneler eksikse doğrudan resmi MSI'dan çek
if (-not $FoundUyap -and -not (Test-Path "$InstallDir\editor_lib.jar")) {
    Write-Host "Resmi UYAP paketleri indiriliyor (Adalet Bakanligi)..." -ForegroundColor Yellow
    $MsiFile = "$CacheDir\uki.msi"
    if (-not (Test-Path $MsiFile)) {
        curl.exe -sL "https://rayp.adalet.gov.tr/resimler/2/dosya/UKI_V5.4.20.msi" -o $MsiFile
    }
    $MsiExtract = "$CacheDir\msi_out"
    if (-not (Test-Path "$MsiExtract\editor_lib.jar")) {
        New-Item -ItemType Directory -Path $MsiExtract -Force | Out-Null
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/a `"$MsiFile`" /qn TARGETDIR=`"$MsiExtract`"" -Wait
    }
    Copy-Item -Path "$MsiExtract\*.jar" -Destination $InstallDir -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$MsiExtract\*.ico" -Destination $InstallDir -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$MsiExtract\*.gif" -Destination $InstallDir -Force -ErrorAction SilentlyContinue
}

# 2. OpenJDK 14.0.2 Windows x64 Kontrolu / Indirme
$JavaDir = "$InstallDir\jdk-14.0.2"
if (-not (Test-Path "$JavaDir\bin\javaw.exe")) {
    Write-Host "[2/6] OpenJDK 14.0.2 Windows x64 indiriliyor..." -ForegroundColor Yellow
    $JdkZip = "$CacheDir\openjdk-14.0.2_windows-x64_bin.zip"
    if (-not (Test-Path $JdkZip)) {
        $JdkUrl = "https://download.java.net/java/GA/jdk14.0.2/205943a0976c4ed48cb16f1043c5c647/12/GPL/openjdk-14.0.2_windows-x64_bin.zip"
        curl.exe -L $JdkUrl -o $JdkZip
    }
    Write-Host "OpenJDK 14.0.2 arşivden çıkartılıyor..." -ForegroundColor Yellow
    Expand-Archive -Path $JdkZip -DestinationPath "$CacheDir\jdk_temp" -Force
    Copy-Item -Path "$CacheDir\jdk_temp\jdk-14.0.2" -Destination $InstallDir -Recurse -Force
}

# 3. E-İmza AKİS PKCS#11 Sürücüsü (akisp11.dll)
Write-Host "[3/6] E-Imza surucu kutuphaneleri (AKIS) hazirlaniyor..." -ForegroundColor Yellow
if (-not (Test-Path "$InstallDir\akisp11.dll")) {
    $SysAkis = "$env:SystemRoot\System32\akisp11.dll"
    if (Test-Path $SysAkis) {
        Copy-Item $SysAkis "$InstallDir\akisp11.dll" -Force
    } else {
        $AkisUrl = "https://raw.githubusercontent.com/ferhat-mousavi/kamusm-akis-signature/main/akis_lib/akisp11.dll"
        curl.exe -sL $AkisUrl -o "$InstallDir\akisp11.dll"
    }
}

# 4. Yerel Başlatıcılar (.exe) Derleme
Write-Host "[4/6] Yerel baslaticilar (.exe) yapilandiriliyor..." -ForegroundColor Yellow
$CscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$LauncherCs = "$ScriptDir\src\Launcher.cs"
$DokumanExe = "$InstallDir\UYAP Dokuman Editoru.exe"
$SablonExe = "$InstallDir\UYAP Sablon Editoru.exe"

if ((Test-Path $CscPath) -and (Test-Path $LauncherCs)) {
    & $CscPath /target:winexe /win32icon:"$InstallDir\uyapicon.ico" /out:"$DokumanExe" $LauncherCs | Out-Null
    & $CscPath /target:winexe /define:TEMPLATE_MODE /win32icon:"$InstallDir\uyap_ki_icon.ico" /out:"$SablonExe" $LauncherCs | Out-Null
}

# 5. Masaustu ve Baslat Menusu Kisayollari
Write-Host "[5/6] Kisayollar olusturuluyor..." -ForegroundColor Yellow
$WshShell = New-Object -ComObject WScript.Shell
$DesktopPath = [Environment]::GetFolderPath("Desktop")

# Doküman Kısayolu
$Shortcut = $WshShell.CreateShortcut("$DesktopPath\UYAP Dokuman Editoru Modern.lnk")
if (Test-Path $DokumanExe) {
    $Shortcut.TargetPath = $DokumanExe
    $Shortcut.IconLocation = "$InstallDir\uyapicon.ico"
} else {
    $Shortcut.TargetPath = "wscript.exe"
    $Shortcut.Arguments = """$InstallDir\dokuman.vbs"""
}
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.Description = "UYAP Dokuman Editoru Modern (120Hz & E-Imza)"
$Shortcut.Save()

# Şablon Kısayolu
$ShortcutSablon = $WshShell.CreateShortcut("$DesktopPath\UYAP Sablon Editoru Modern.lnk")
if (Test-Path $SablonExe) {
    $ShortcutSablon.TargetPath = $SablonExe
    $ShortcutSablon.IconLocation = "$InstallDir\uyap_ki_icon.ico"
} else {
    $ShortcutSablon.TargetPath = "wscript.exe"
    $ShortcutSablon.Arguments = """$InstallDir\sablon.vbs"""
}
$ShortcutSablon.WorkingDirectory = $InstallDir
$ShortcutSablon.Description = "UYAP Sablon Editoru Modern (120Hz & E-Imza)"
$ShortcutSablon.Save()

# 6. .udf ve .usf Dosya Iliskilendirmesi
Write-Host "[6/6] Dosya iliskilendirmesi yapiliyor (.udf / .usf)..." -ForegroundColor Yellow
if (Test-Path $DokumanExe) {
    cmd /c "assoc .udf=UYAP.Document"
    cmd /c "ftype UYAP.Document=`"$DokumanExe`" `"%1`""
    cmd /c "assoc .usf=UYAP.Template"
    cmd /c "ftype UYAP.Template=`"$SablonExe`" `"%1`""
} else {
    cmd /c "assoc .udf=UYAP.Document"
    cmd /c "ftype UYAP.Document=wscript.exe `"$InstallDir\dokuman.vbs`" `"%1`""
    cmd /c "assoc .usf=UYAP.Template"
    cmd /c "ftype UYAP.Template=wscript.exe `"$InstallDir\sablon.vbs`" `"%1`""
}

# 7. Yapilandirma Dosyalari
$UkiDir = "$env:USERPROFILE\.uki"
if (-not (Test-Path $UkiDir)) {
    New-Item -ItemType Directory -Path $UkiDir -Force | Out-Null
}
if ((Test-Path "$RootDir\config\modernizer.properties") -and (-not (Test-Path "$UkiDir\modernizer.properties"))) {
    Copy-Item "$RootDir\config\modernizer.properties" "$UkiDir\" -Force
}
if ((Test-Path "$RootDir\config\uyap.conf") -and (-not (Test-Path "$UkiDir\uyap.conf"))) {
    Copy-Item "$RootDir\config\uyap.conf" "$UkiDir\" -Force
}

Write-Host "`n[OK] Windows kurulumu basariyla tamamlandi!" -ForegroundColor Green
