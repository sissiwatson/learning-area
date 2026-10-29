#!/usr/bin/env bash
# Vérifications visuelles dans un écran virtuel (Linux, nécessite xvfb-run).
# Usage : tools/visual_checks.sh <dossier_sortie> [scénario...]
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
out="$(realpath -m "$1")"; shift
xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --path . \
	--rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x720 \
	-s tools/visual_checks.gd -- "$out" "$@"
