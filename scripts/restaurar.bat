@echo off
rem Desfaz as alteracoes: animacoes normais, reativa o launcher original e as apps desativadas.
rem Uso: restaurar.bat IP_DA_TV [--remover-launcher]
setlocal
set TV_IP=%~1
set REMOVER=%~2

if "%TV_IP%"=="" (
  echo Uso: restaurar.bat IP_DA_TV [--remover-launcher]
  exit /b 1
)

where adb >nul 2>nul
if errorlevel 1 (
  echo adb nao encontrado. Instala o Android platform-tools e adiciona ao PATH.
  exit /b 1
)

set S=%TV_IP%
echo %TV_IP%| find ":" >nul || set S=%TV_IP%:5555

adb connect %S% >nul 2>nul
adb -s %S% get-state 2>nul | find "device" >nul
if errorlevel 1 (
  echo Nao consegui ligar.
  exit /b 1
)

echo A repor as animacoes ...
for %%k in (window_animation_scale transition_animation_scale animator_duration_scale) do adb -s %S% shell settings put global %%k 1.0

echo A reativar o launcher original ...
adb -s %S% shell pm enable --user 0 com.google.android.apps.tv.launcherx >nul 2>nul
adb -s %S% shell pm enable --user 0 com.google.android.tvlauncher >nul 2>nul

if exist "%~dp0lista-debloat.txt" (
  echo A reativar as apps da lista-debloat.txt ...
  for /f "usebackq eol=# tokens=1" %%p in ("%~dp0lista-debloat.txt") do adb -s %S% shell pm enable --user 0 %%p >nul 2>nul
)

if /i "%REMOVER%"=="--remover-launcher" (
  echo A remover o TV Launcher ...
  adb -s %S% uninstall com.tvos.launcher
)

echo Feito. Reinicia a TV para aplicar tudo.
endlocal
