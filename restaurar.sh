#!/usr/bin/env bash
# Desfaz as alterações: animações normais, reativa o launcher original e as apps desativadas.
# Uso: ./restaurar.sh IP_DA_TV [--remover-launcher]
set -u

TV_IP=""
REMOVER=0
for arg in "$@"; do
  case "$arg" in
    --remover-launcher) REMOVER=1 ;;
    *) TV_IP="$arg" ;;
  esac
done

if [ -z "$TV_IP" ]; then
  echo "Uso: $0 IP_DA_TV [--remover-launcher]"
  exit 1
fi
if ! command -v adb >/dev/null 2>&1; then
  echo "adb não encontrado. Instala o Android platform-tools e tenta outra vez."
  exit 1
fi

case "$TV_IP" in
  *:*) S="$TV_IP" ;;
  *) S="$TV_IP:5555" ;;
esac

adb connect "$S" >/dev/null 2>&1
STATE="$(adb -s "$S" get-state 2>&1)"
if [ "$STATE" != "device" ]; then
  echo "Não consegui ligar (estado: $STATE)."
  exit 1
fi

echo "A repor as animações ..."
for key in window_animation_scale transition_animation_scale animator_duration_scale; do
  adb -s "$S" shell settings put global "$key" 1.0
done

echo "A reativar o launcher original ..."
for pkg in com.google.android.apps.tv.launcherx com.google.android.tvlauncher; do
  adb -s "$S" shell pm enable --user 0 "$pkg" >/dev/null 2>&1
done

LISTA="$(dirname "$0")/lista-debloat.txt"
if [ -f "$LISTA" ]; then
  echo "A reativar as apps da lista-debloat.txt ..."
  while IFS= read -r linha; do
    pkg="${linha%%#*}"
    pkg="$(printf '%s' "$pkg" | tr -d '[:space:]')"
    [ -z "$pkg" ] && continue
    adb -s "$S" shell pm enable --user 0 "$pkg" >/dev/null 2>&1
  done < "$LISTA"
fi

if [ "$REMOVER" -eq 1 ]; then
  echo "A remover o TV Launcher ..."
  adb -s "$S" uninstall com.tvos.launcher
fi

echo "Feito. Reinicia a TV para aplicar tudo."
