#!/usr/bin/env bash
# Lance tous les tests GUT en mode headless.
# Usage : tools/run_tests.sh            (GODOT=/chemin/vers/godot pour un autre binaire)
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
expected="$(cat .godot-version)"
actual="$("$GODOT" --version | cut -d. -f1-4)"
if [[ "$actual" != "$expected" ]]; then
	echo "Avertissement : Godot $actual détecté, version figée : $expected" >&2
fi

mkdir -p tests/results
# Importe les ressources (traductions, textures) avant de lancer les tests.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json
