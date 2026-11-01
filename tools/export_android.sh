#!/usr/bin/env bash
# Exporta o APK de teste (assinado com a chave de debug) para build/android/Fogkeeper.apk.
# Requer: templates Android 4.4.1, JDK 17 e Android SDK configurados nas
# Configurações do Editor (export/android/java_sdk_path e android_sdk_path).
# Para instalar num celular ligado por USB (com depuração USB ativa):
#   adb install -r build/android/Fogkeeper.apk
# Uso: GODOT=/caminho/do/godot tools/export_android.sh
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
mkdir -p build/android
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-debug "Android" build/android/Fogkeeper.apk
ls -l build/android/Fogkeeper.apk
