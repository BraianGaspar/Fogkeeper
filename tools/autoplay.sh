#!/usr/bin/env bash
# Roda N partidas com o bot e mostra o resumo de cada uma.
# Uso: GODOT=/caminho/do/godot tools/autoplay.sh [num_partidas]
set -euo pipefail
GODOT="${GODOT:-godot}"
RUNS="${1:-5}"
cd "$(dirname "$0")/.."
wins=0
for seed in $(seq 1 "$RUNS"); do
  out=$("$GODOT" --headless --path . --fixed-fps 20 -- --autoplay --seed="$seed" 2>&1 | grep -E "\[autoplay\] FIM|SCRIPT ERROR|ERROR" || true)
  echo "seed $seed: $out"
  if grep -q "vitória=true" <<<"$out"; then wins=$((wins+1)); fi
done
echo "Vitórias do bot: $wins / $RUNS"
