#!/usr/bin/env bash
# Vérifications visuelles dans un écran virtuel (Linux, nécessite xvfb-run).
# Usage : tools/visual_checks.sh <dossier_sortie> [scénario...]
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
out="$(realpath -m "$1")"; shift
RES="${RES:-1280x720}"
xvfb-run -a -s "-screen 0 2600x1700x24" "$GODOT" --path . \
	--rendering-method gl_compatibility --audio-driver Dummy --resolution "$RES" \
	-s tools/visual_checks.gd -- "$out" "$@"
