# ==============================================================================
# UYAP Editor Modern - Windows Otomatik Kurulum ve Yapilandirma Betigi
# PowerShell 5.1+ Uyumlu
# ==============================================================================

Write-Host "=== UYAP Editor Modern - Windows Kurulumu ===" -ForegroundColor Cyan

$InstallDir = "$env:LOCALAPPDATA\UYAPEditorModern"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# 1. Klasorleri Olustur
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

Write-Host "[1/5] Editor dosyalari kopyalaniyor..." -ForegroundColor Yellow
Copy-Item -Path "$ScriptDir\bin\*" -Destination $InstallDir -Force
if (Test-Path "$RootDir\dist\uyap-modernizer.jar") {
    Copy-Item -Path "$RootDir\dist\uyap-modernizer.jar" -Destination $InstallDir -Force
}

# Resmi UYAP kurulu ise JAR dosyalarini kopyala
$OfficialDirs = @(
    "${env:ProgramFiles(x86)}\UYAP\UYAPEditor",
    "$env:ProgramFiles\UYAP\UYAPEditor",
    "C:\UYAPEditor"
)
foreach ($dir in $OfficialDirs) {
    if (Test-Path "$dir\editor_lib.jar") {
        Write-Host "Resmi UYAP kurulumu bulundu ($dir), kütüphaneler kopyalanıyor..." -ForegroundColor Green
        Copy-Item -Path "$dir\*.jar" -Destination $InstallDir -Force -ErrorAction SilentlyContinue
        if (Test-Path "$dir\images") {
            Copy-Item -Path "$dir\images" -Destination $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$dir\jdk-14.0.2") {
            Copy-Item -Path "$dir\jdk-14.0.2" -Destination $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        break
    }
}

# 2. OpenJDK 14.0.2 Windows x64 Kontrolu / Indirme
$JavaDir = "$InstallDir\jdk-14.0.2"
if (-not (Test-Path "$JavaDir\bin\javaw.exe")) {
    Write-Host "[2/5] OpenJDK 14.0.2 Windows x64 indiriliyor..." -ForegroundColor Yellow
    $JdkZip = "$env:TEMP\openjdk-14.0.2_windows-x64_bin.zip"
    $JdkUrl = "https://download.java.net/java/GA/jdk14.0.2/205943a0927447a7be1a4c57fb773708/12/GPL/openjdk-14.0.2_windows-x64_bin.zip"
    Invoke-WebRequest -Uri $JdkUrl -OutFile $JdkZip
    Expand-Archive -Path $JdkZip -DestinationPath $InstallDir -Force
    Remove-Item $JdkZip -Force
}

# 3. Masaustu ve Baslat Menusu Kisayollari
Write-Host "[3/5] Kisayollar olusturuluyor..." -ForegroundColor Yellow
$WshShell = New-Object -ComObject WScript.Shell

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$Shortcut = $WshShell.CreateShortcut("$DesktopPath\UYAP Dokuman Editoru Modern.lnk")
$Shortcut.TargetPath = "wscript.exe"
$Shortcut.Arguments = """$InstallDir\dokuman.vbs"""
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.Description = "UYAP Dokuman Editoru Modern (120Hz & E-Imza)"
$Shortcut.Save()

$ShortcutSablon = $WshShell.CreateShortcut("$DesktopPath\UYAP Sablon Editoru Modern.lnk")
$ShortcutSablon.TargetPath = "wscript.exe"
$ShortcutSablon.Arguments = """$InstallDir\sablon.vbs"""
$ShortcutSablon.WorkingDirectory = $InstallDir
$ShortcutSablon.Description = "UYAP Sablon Editoru Modern (120Hz & E-Imza)"
$ShortcutSablon.Save()

# 4. .udf ve .usf Dosya Iliskilendirmesi
Write-Host "[4/5] Dosya iliskilendirmesi yapiliyor (.udf / .usf)..." -ForegroundColor Yellow
cmd /c "assoc .udf=UYAP.Document"
cmd /c "ftype UYAP.Document=wscript.exe `"$InstallDir\dokuman.vbs`" `"%1`""
cmd /c "assoc .usf=UYAP.Template"
cmd /c "ftype UYAP.Template=wscript.exe `"$InstallDir\sablon.vbs`" `"%1`""

# 5. Yapilandirma Dosyalari
Write-Host "[5/5] Yapilandirma dosyalari..." -ForegroundColor Yellow
$UkiDir = "$env:USERPROFILE\.uki"
if (-not (Test-Path $UkiDir)) {
    New-Item -ItemType Directory -Path $UkiDir -Force | Out-Null
}
if (Test-Path "$RootDir\config\modernizer.properties" -and -not (Test-Path "$UkiDir\modernizer.properties")) {
    Copy-Item "$RootDir\config\modernizer.properties" "$UkiDir\" -Force
}
if (Test-Path "$RootDir\config\uyap.conf" -and -not (Test-Path "$UkiDir\uyap.conf")) {
    Copy-Item "$RootDir\config\uyap.conf" "$UkiDir\" -Force
}

Write-Host "✓ Windows kurulumu basariyla tamamlandi!" -ForegroundColor Green
