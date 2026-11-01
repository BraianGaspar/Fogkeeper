#!/usr/bin/env bash
# Grava os trailers (inglês e português) e converte para MP4 (H.264), o formato
# que qualquer player abre e que a Steam recomenda:
#   build/trailer_en.mp4 e build/trailer_pt.mp4
# Grava quadro a quadro em PNG (o AVI/MJPEG do Godot saía com quadros
# corrompidos) e em tela cheia (a janela de 1920x1080 não cabe numa tela 1080p
# com a barra de tarefas). Ocupa a tela por ~1 min por idioma; não mexa no PC.
# Requer ffmpeg (winget install Gyan.FFmpeg).
# Uso: GODOT=/caminho/do/godot FFMPEG=/caminho/do/ffmpeg tools/trailer.sh
set -euo pipefail
GODOT="${GODOT:-godot}"
FFMPEG="${FFMPEG:-ffmpeg}"
cd "$(dirname "$0")/.."
mkdir -p build
for lang in en pt; do
  frames="build/frames_$lang"
  rm -rf "$frames"
  mkdir -p "$frames"
  "$GODOT" --path . --fullscreen --resolution 1920x1080 --fixed-fps 30 \
    --write-movie "$(pwd)/$frames/frame.png" -- --trailer=$lang
  "$FFMPEG" -v error -y -framerate 30 -i "$frames/frame%08d.png" -i "$frames/frame.wav" \
    -vf "scale=1920:1080:flags=lanczos,format=yuv420p" -c:v libx264 -preset slow -crf 18 \
    -c:a aac -b:a 192k -shortest -movflags +faststart "build/trailer_$lang.mp4"
  rm -rf "$frames"
done
ls -l build/trailer_*.mp4
