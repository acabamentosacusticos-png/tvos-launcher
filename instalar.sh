#!/usr/bin/env bash
# Instala o launcher na Google TV por Wi-Fi (ADB).
# Uso: ./instalar.sh IP_DA_TV [app-release.apk] [--substituir-launcher]
#   IP_DA_TV pode ser "192.168.1.50" ou "192.168.1.50:PORTA" (depuração sem fios do Android 11+).
set -u

TV_IP=""
APK="app-release.apk"
SUBSTITUIR=0
for arg in "$@"; do
  case "$arg" in
    --substituir-launcher) SUBSTITUIR=1 ;;
    *.apk) APK="$arg" ;;
    *) TV_IP="$arg" ;;
  esac
done

if [ -z "$TV_IP" ]; then
  echo "Uso: $0 IP_DA_TV [app-release.apk] [--substituir-launcher]"
  exit 1
fi
if ! command -v adb >/dev/null 2>&1; then
  echo "adb não encontrado. Instala o Android platform-tools e tenta outra vez."
  exit 1
fi
if [ ! -f "$APK" ]; then
  echo "APK não encontrado: $APK"
  exit 1
fi

case "$TV_IP" in
  *:*) S="$TV_IP" ;;
  *) S="$TV_IP:5555" ;;
esac

echo "A ligar a $S ..."
adb connect "$S" >/dev/null 2>&1
STATE="$(adb -s "$S" get-state 2>&1)"
if [ "$STATE" != "device" ]; then
  echo "Não consegui ligar (estado: $STATE)."
  echo "Confirma que a depuração por rede está ativa e aceita o pedido de autorização no ecrã da TV."
  exit 1
fi

echo "A instalar o launcher ..."
adb -s "$S" install -r "$APK" || { echo "Falha na instalação."; exit 1; }

echo "A definir como ecrã inicial ..."
adb -s "$S" shell cmd package set-home-activity com.tvos.launcher/.MainActivity

if [ "$SUBSTITUIR" -eq 1 ]; then
  echo "A desativar o launcher original da Google TV (reversível com restaurar.sh) ..."
  for pkg in com.google.android.apps.tv.launcherx com.google.android.tvlauncher; do
    adb -s "$S" shell pm disable-user --user 0 "$pkg"
  done
fi

adb -s "$S" shell am start -n com.tvos.launcher/.MainActivity >/dev/null 2>&1
echo "Feito. Se o botão Home continuar a abrir o ecrã original, repete com --substituir-launcher."
