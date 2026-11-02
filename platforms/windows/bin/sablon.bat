@echo off
setlocal enabledelayedexpansion

:: ==============================================================================
:: UYAP Sablon Editoru - Modern Windows Baslatici
:: Gelistirici: Can Kizilyar (github.com/cnkzlyr)
:: ==============================================================================

set "BASE_DIR=%~dp0.."

if exist "%BASE_DIR%\jdk-14.0.2\bin\javaw.exe" (
    set "JAVA_CMD=%BASE_DIR%\jdk-14.0.2\bin\javaw.exe"
) else if defined JAVA_HOME if exist "%JAVA_HOME%\bin\javaw.exe" (
    set "JAVA_CMD=%JAVA_HOME%\bin\javaw.exe"
) else (
    set "JAVA_CMD=javaw.exe"
)

set "CP_PATH=%BASE_DIR%\uyap-modernizer.jar;%BASE_DIR%\*"
set "PKCS11_OPTS=-Djava.library.path=%BASE_DIR%;%SystemRoot%\System32;%SystemRoot%\SysWOW64"
set "FONT_OPTS=-Dawt.useSystemAAFontSettings=lcd -Dswing.aatext=true"
set "MEM_OPTS=-Xms256m -Xmx1024m -XX:+UseG1GC -XX:+UseStringDeduplication"
set "AGENT_OPTS=-javaagent:%BASE_DIR%\uyap-modernizer.jar"

start "" "%JAVA_CMD%" %PKCS11_OPTS% %MEM_OPTS% %FONT_OPTS% %AGENT_OPTS% -cp "%CP_PATH%" tr.com.havelsan.uyap.system.editor.common.WPAppManager "getNewWPInstance" "EDITOR_TYPE_TEMPLATE" %*
