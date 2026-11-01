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
              scripts/core/upgrades.gd scripts/core/game_input.gd scripts/audio/sfx.gd \
            | sed -E 's/^"[a-z_0-9]+": "(.*)"$/\1/' | grep -E '[A-ZÀ-Ý ]'
          grep -hoE '^const [A-Z_]+_NAMES := \[.*\]|^const TABS := \[.*\]' scripts/ui/screens/settings_screen.gd | grep -oE '"[^"]+"' | tr -d '"'
          printf '%s\n' "Ligado" "Desligado" "Principal" "Alternativa"; } | sort -u)
missing=$(comm -23 <(echo "$used") <(echo "$keys"))
if [ -n "$missing" ]; then
  echo "Textos sem tradução em scripts/core/i18n.gd:"; echo "$missing"; exit 1
fi
echo "OK: todos os textos têm tradução."
