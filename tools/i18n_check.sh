#!/usr/bin/env bash
# Confere se todo texto traduzível tem entrada em scripts/core/i18n.gd.
# Fontes: tr("...") nos scripts e os textos de dados (name/desc/text) em core/.
set -euo pipefail
cd "$(dirname "$0")/.."
keys=$(grep -oE '^\s*"([^"\]|\.)*": \[' scripts/core/i18n.gd | sed -E 's/^\s*"(.*)": \[$/\1/' | sort -u)
used=$( { grep -rhoE --exclude=i18n.gd 'tr\("([^"\]|\.)*"\)' scripts | sed -E 's/^tr\("(.*)"\)$/\1/'
          grep -rhoE '"(name|desc|text)": "[^"]+"' scripts/core | sed -E 's/^"[a-z]+": "(.*)"$/\1/'
          grep -hoE '^const (TABS|QUALITY_NAMES) := \[.*\]' scripts/ui/screens/settings_screen.gd | grep -oE '"[^"]+"' | tr -d '"'
          printf '%s\n' "Ligado" "Desligado"; } | sort -u)
missing=$(comm -23 <(echo "$used") <(echo "$keys"))
if [ -n "$missing" ]; then
  echo "Textos sem tradução em scripts/core/i18n.gd:"; echo "$missing"; exit 1
fi
echo "OK: todos os textos têm tradução."
