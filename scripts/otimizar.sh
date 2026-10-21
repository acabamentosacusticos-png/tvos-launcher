#!/usr/bin/env bash
# Otimiza a Google TV por Wi-Fi (ADB), sem root e sem alterar o sistema.
# Uso: ./otimizar.sh IP_DA_TV [fator_animacoes]    (fator por defeito: 0.5; 0 desliga as animações)
#      ./otimizar.sh IP_DA_TV --listar             (lista as apps instaladas)
set -u

TV_IP=""
SCALE="0.5"
LISTAR=0
for arg in "$@"; do
  case "$arg" in
    --listar) LISTAR=1 ;;
    [0-9]*.[0-9]* | [0-9]) [ -n "$TV_IP" ] && SCALE="$arg" || TV_IP="$arg" ;;
    *) TV_IP="$arg" ;;
  esac
done

if [ -z "$TV_IP" ]; then
  echo "Uso: $0 IP_DA_TV [fator_animacoes | --listar]"
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
  echo "Não consegui ligar (estado: $STATE). Confirma a depuração por rede e a autorização na TV."
  exit 1
fi

if [ "$LISTAR" -eq 1 ]; then
  echo "== Apps instaladas por ti =="
  adb -s "$S" shell pm list packages -3 | sed 's/^package://' | sort
  echo
  echo "== Apps do sistema/fabricante =="
  adb -s "$S" shell pm list packages -s | sed 's/^package://' | sort
  exit 0
fi

echo "1/4 Animações a ${SCALE}x ..."
for key in window_animation_scale transition_animation_scale animator_duration_scale; do
  adb -s "$S" shell settings put global "$key" "$SCALE"
done

echo "2/4 A libertar cache das apps ..."
adb -s "$S" shell pm trim-caches 999G >/dev/null 2>&1 || true

echo "3/4 A desativar apps da lista-debloat.txt ..."
LISTA="$(dirname "$0")/lista-debloat.txt"
if [ -f "$LISTA" ]; then
  while IFS= read -r linha; do
    pkg="${linha%%#*}"
    pkg="$(printf '%s' "$pkg" | tr -d '[:space:]')"
    [ -z "$pkg" ] && continue
    echo "   - $pkg"
    adb -s "$S" shell pm disable-user --user 0 "$pkg"
  done < "$LISTA"
fi

echo "4/4 A compilar as apps para arrancarem mais depressa (pode demorar alguns minutos) ..."
adb -s "$S" shell cmd package compile -m speed-profile -a

echo "Concluído. Reinicia a TV para sentir o efeito completo."
