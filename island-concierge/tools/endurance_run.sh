#!/usr/bin/env bash
# Recette d'endurance (Linux, nécessite xvfb-run) : scène complète en temps
# réel, joueur automatique, mesures toutes les 10 s dans un CSV.
# Usage : tools/endurance_run.sh <durée_s> <fichier_csv>
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
RES="${RES:-1280x720}"
log="$(mktemp)"
set +e
xvfb-run -a -s "-screen 0 2600x1700x24" "$GODOT" --path . \
	--rendering-method gl_compatibility --audio-driver Dummy --resolution "$RES" \
	-s tools/endurance_run.gd -- "${1:-300}" "$(realpath -m "${2:-endurance.csv}")" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
set -e
if grep -qE "SCRIPT ERROR|^(USER )?ERROR:" "$log"; then
	echo "ÉCHEC : erreur pendant l'endurance (voir ci-dessus)." >&2
	status=1
fi
rm -f "$log"
exit "$status"
