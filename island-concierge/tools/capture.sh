#!/usr/bin/env bash
# Capture d'écran d'une scène dans un écran virtuel (Linux, nécessite xvfb-run).
# Usage : tools/capture.sh res://scenes/main.tscn /tmp/main.png [images]
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
out="$(realpath -m "$2")"
xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --path . \
	--rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x720 \
	-s tools/capture.gd -- "$1" "$out" "${3:-10}"
