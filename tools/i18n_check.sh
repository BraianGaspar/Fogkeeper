#!/usr/bin/env bash
# Confere se todo texto traduzível tem entrada em scripts/core/i18n.gd.
# Fontes: tr("...") e translate("...") nos scripts; textos de dados
# ("chave": "Valor com maiúscula ou espaço") em core/, Sfx.GROUP_NAMES e
# GameInput.ACTION_NAMES; e as listas de opções da tela de configurações.
set -euo pipefail
cd "$(dirname "$0")/.."
keys=$(grep -oE '^\s*"([^"\]|\.)*": \[' scripts/core/i18n.gd | sed -E 's/^\s*"(.*)": \[$/\1/' | sort -u)
used=$( { grep -rhoE --exclude=i18n.gd '(tr|translate)\("([^"\]|\.)*"\)' scripts | sed -E 's/^(tr|translate)\("(.*)"\)$/\2/'
          grep -hoE '"[a-z_0-9]+": "[^"]+"' scripts/core/balance.gd scripts/core/maps.gd scripts/core/keepers.gd scripts/core/day_cycle.gd \
              scripts/core/upgrades.gd scripts/core/game_input.gd scripts/core/achievements.gd scripts/core/bestiary.gd scripts/core/damage_stats.gd scripts/audio/sfx.gd \
            | sed -E 's/^"[a-z_0-9]+": "(.*)"$/\1/' | grep -E '[A-ZÀ-Ý ]'
          grep -hoE '^const [A-Z_]+_NAMES := \[.*\]|^const TABS := \[.*\]' scripts/ui/screens/settings_screen.gd | grep -oE '"[^"]+"' | tr -d '"'
          printf '%s\n' "Ligado" "Desligado" "Principal" "Alternativa"; } | sort -u)
missing=$(comm -23 <(echo "$used") <(echo "$keys"))
if [ -n "$missing" ]; then
  echo "Textos sem tradução em scripts/core/i18n.gd:"; echo "$missing"; exit 1
fi
# Os outros idiomas (scripts/i18n/*.gd) precisam ter todas as chaves de I18n.TEXTS.
for f in scripts/i18n/*.gd; do
  have=$(grep -oE '^\s*"([^"\]|\\.)*": "' "$f" | sed -E 's/^\s*"(.*)": "$/\1/' | sort -u)
  gap=$(comm -23 <(echo "$keys") <(echo "$have"))
  if [ -n "$gap" ]; then
    echo "Faltam $(echo "$gap" | wc -l) textos em $f, por exemplo:"; echo "$gap" | head -5; exit 1
  fi
done
echo "OK: todos os textos têm tradução."
