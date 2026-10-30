#!/usr/bin/env bash
# Vérifications visuelles dans un écran virtuel (Linux, nécessite xvfb-run).
# Usage : tools/visual_checks.sh <dossier_sortie> [scénario...]
# Échoue si le moteur signale une erreur de script ou une erreur moteur.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
out="$(realpath -m "$1")"; shift
RES="${RES:-1280x720}"
log="$(mktemp)"
set +e
xvfb-run -a -s "-screen 0 2600x1700x24" "$GODOT" --path . \
	--rendering-method gl_compatibility --audio-driver Dummy --resolution "$RES" \
	-s tools/visual_checks.gd -- "$out" "$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
set -e
if grep -qE "SCRIPT ERROR|^(USER )?ERROR:" "$log"; then
	echo "ÉCHEC : erreur pendant les captures (voir ci-dessus)." >&2
	status=1
fi
rm -f "$log"
exit "$status"
