@echo off
rem Otimiza a Google TV por Wi-Fi (ADB), sem root.
rem Uso: otimizar.bat IP_DA_TV [fator_animacoes]   (por defeito 0.5; 0 desliga as animacoes)
rem      otimizar.bat IP_DA_TV --listar            (lista as apps instaladas)
setlocal
set TV_IP=%~1
set SCALE=%~2

if "%TV_IP%"=="" (
  echo Uso: otimizar.bat IP_DA_TV [fator_animacoes ou --listar]
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
  echo Nao consegui ligar. Confirma a depuracao por rede e a autorizacao na TV.
  exit /b 1
)

if /i "%SCALE%"=="--listar" (
  echo == Apps instaladas por ti ==
  adb -s %S% shell pm list packages -3
  echo.
  echo == Apps do sistema/fabricante ==
  adb -s %S% shell pm list packages -s
  exit /b 0
)
if "%SCALE%"=="" set SCALE=0.5

echo 1/4 Animacoes a %SCALE%x ...
for %%k in (window_animation_scale transition_animation_scale animator_duration_scale) do adb -s %S% shell settings put global %%k %SCALE%

echo 2/4 A libertar cache das apps ...
adb -s %S% shell pm trim-caches 999G >nul 2>nul

echo 3/4 A desativar apps da lista-debloat.txt ...
if exist "%~dp0lista-debloat.txt" (
  for /f "usebackq eol=# tokens=1" %%p in ("%~dp0lista-debloat.txt") do (
    echo    - %%p
    adb -s %S% shell pm disable-user --user 0 %%p
  )
)

echo 4/4 A compilar as apps - pode demorar alguns minutos ...
adb -s %S% shell cmd package compile -m speed-profile -a

echo Concluido. Reinicia a TV para sentir o efeito completo.
endlocal
