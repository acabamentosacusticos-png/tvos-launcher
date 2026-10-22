@echo off
rem Instala o launcher na Google TV por Wi-Fi (ADB).
rem Uso: instalar.bat IP_DA_TV [app-release.apk] [--substituir-launcher]
setlocal
set TV_IP=%~1
set APK=%~2
set SUBST=%~3

if "%TV_IP%"=="" (
  echo Uso: instalar.bat IP_DA_TV [app-release.apk] [--substituir-launcher]
  exit /b 1
)
if "%APK%"=="" set APK=app-release.apk

where adb >nul 2>nul
if errorlevel 1 (
  echo adb nao encontrado. Instala o Android platform-tools e adiciona ao PATH.
  exit /b 1
)
if not exist "%APK%" (
  echo APK nao encontrado: %APK%
  exit /b 1
)

set S=%TV_IP%
echo %TV_IP%| find ":" >nul || set S=%TV_IP%:5555

echo A ligar a %S% ...
adb connect %S% >nul 2>nul
adb -s %S% get-state 2>nul | find "device" >nul
if errorlevel 1 (
  echo Nao consegui ligar. Confirma a depuracao por rede e aceita o pedido de autorizacao na TV.
  exit /b 1
)

echo A instalar o launcher ...
adb -s %S% install -r "%APK%"
if errorlevel 1 (
  echo Falha na instalacao.
  exit /b 1
)

echo A definir como ecra inicial ...
adb -s %S% shell cmd package set-home-activity com.tvos.launcher/.MainActivity

if /i "%SUBST%"=="--substituir-launcher" (
  echo A desativar o launcher original da Google TV - reversivel com restaurar.bat
  adb -s %S% shell pm disable-user --user 0 com.google.android.apps.tv.launcherx
  adb -s %S% shell pm disable-user --user 0 com.google.android.tvlauncher
)

adb -s %S% shell am start -n com.tvos.launcher/.MainActivity >nul 2>nul
echo Feito. Se o botao Home continuar a abrir o ecra original, repete com --substituir-launcher.
endlocal
