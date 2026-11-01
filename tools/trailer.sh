#!/usr/bin/env bash
# Grava os trailers (inglês e português) em build/trailer_en.avi e build/trailer_pt.avi.
# Abre uma janela durante a gravação (~1 min cada). Uso: GODOT=/caminho/do/godot tools/trailer.sh
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
mkdir -p build
for lang in en pt; do
  "$GODOT" --path . --resolution 1920x1080 --fixed-fps 30 --write-movie "$(pwd)/build/trailer_$lang.avi" -- --trailer=$lang
done
ls -l build/trailer_*.avi
