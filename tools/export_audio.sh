#!/usr/bin/env bash
# Exporta a trilha e os efeitos sintetizados do jogo para a versão Roblox:
# o Godot grava cada som em WAV (tools/export_audio.gd) e o ffmpeg converte
# para OGG em roblox/audio/, prontos para enviar ao Roblox
# (roblox/tools/upload_audio.ps1 ou Creator Hub; ids em shared/SoundIds.luau).
# Uso: GODOT=/caminho/do/godot FFMPEG=/caminho/do/ffmpeg tools/export_audio.sh
set -euo pipefail
GODOT="${GODOT:-godot}"
FFMPEG="${FFMPEG:-ffmpeg}"
cd "$(dirname "$0")/.."
"$GODOT" --headless --path . --script tools/export_audio.gd
mkdir -p roblox/audio
for wav in build/audio_wav/*.wav; do
  name="$(basename "$wav" .wav)"
  "$FFMPEG" -v error -y -i "$wav" -c:a libvorbis -q:a 5 "roblox/audio/$name.ogg"
done
ls roblox/audio | wc -l
