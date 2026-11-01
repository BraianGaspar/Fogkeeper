#!/usr/bin/env bash
# Roda N partidas com o bot e mostra o resumo de cada uma.
# Uso: GODOT=/caminho/do/godot tools/autoplay.sh [num_partidas] [--difficulty=D] [--map=M]
# Exemplo: tools/autoplay.sh 10 --difficulty=hard --map=fjord
set -euo pipefail
GODOT="${GODOT:-godot}"
RUNS="${1:-5}"
shift || true
cd "$(dirname "$0")/.."
wins=0
total=0
for seed in $(seq 1 "$RUNS"); do
  out=$("$GODOT" --headless --path . --fixed-fps 20 -- --autoplay --seed="$seed" "$@" 2>&1 \
    | grep -E "\[autoplay\] FIM|SCRIPT ERROR|ERROR:" | sed -E 's/  melhorias=.*//' || true)
  echo "seed $seed: $out"
  if grep -q "vitória=true" <<<"$out"; then wins=$((wins+1)); fi
  t=$(grep -oE "tempo=[0-9]+:[0-9]+" <<<"$out" | head -1 | cut -d= -f2 || true)
  if [ -n "$t" ]; then total=$((total + 10#${t%%:*} * 60 + 10#${t##*:})); fi
done
echo "Vitórias do bot: $wins / $RUNS   (tempo médio: $((total / RUNS / 60)):$(printf '%02d' $((total / RUNS % 60))))"
