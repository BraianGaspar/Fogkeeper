#!/usr/bin/env bash
# Importa o projeto e roda alguns quadros em headless; falha se houver erro de script.
# Uso: GODOT=/caminho/do/godot tools/check.sh
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
log=$("$GODOT" --headless --path . --quit-after 300 -- --no-save 2>&1 || true)
if grep -qE "SCRIPT ERROR|Parse Error|ERROR:" <<<"$log"; then
  echo "$log" | grep -E "SCRIPT ERROR|Parse Error|ERROR:|at:" ; exit 1
fi
echo "OK: projeto carrega e roda sem erros."
bash tools/i18n_check.sh
