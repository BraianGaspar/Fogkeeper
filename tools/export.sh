#!/usr/bin/env bash
# Exporta o jogo para build/windows/Fogkeeper.exe (um arquivo só, com o .pck embutido).
# Requer os templates de exportação 4.4.1 instalados (Editor → Gerenciar modelos de exportação).
# Uso: GODOT=/caminho/do/godot tools/export.sh
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
mkdir -p build/windows
"$GODOT" --headless --path . --script tools/make_icon.gd
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "Windows Desktop" build/windows/Fogkeeper.exe
ls -l build/windows/Fogkeeper.exe
