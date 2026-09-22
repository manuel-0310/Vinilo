#!/bin/sh
# Captura el simulador y deja una copia reducida para revisar rápido.
#   tool/shot.sh nombre  → /tmp/vinilo_shots/nombre.png (y nombre_s.png a 900px de alto)
set -e
DEVICE="${SIM_DEVICE:-9B5FCCD2-D3ED-4B32-AD82-D6764E4A46B4}"
NAME="${1:-shot}"
OUT_DIR="${SHOT_DIR:-/tmp/vinilo_shots}"
mkdir -p "$OUT_DIR"
xcrun simctl io "$DEVICE" screenshot "$OUT_DIR/$NAME.png" >/dev/null 2>&1
sips -Z 900 "$OUT_DIR/$NAME.png" --out "$OUT_DIR/${NAME}_s.png" >/dev/null 2>&1
echo "$OUT_DIR/${NAME}_s.png"
