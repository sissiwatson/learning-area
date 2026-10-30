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
# Délai maximal : un script de test qui ne compile pas peut bloquer GUT.
log="$(mktemp)"
set +e
timeout "${TEST_TIMEOUT:-600}" "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
set -e
# GUT classe un test interrompu par une erreur de script comme « risqué » :
# on le compte comme un échec.
if grep -qE "SCRIPT ERROR|Risky/Pending" "$log"; then
	echo "ÉCHEC : erreur de script ou test risqué (voir ci-dessus)." >&2
	status=1
fi
# Une erreur moteur (nœud libéré trop tôt, ressource manquante…) est un défaut
# même si aucune assertion n'échoue.
if grep -qE "^(USER )?ERROR:" "$log"; then
	echo "ÉCHEC : erreur moteur pendant les tests (voir ci-dessus)." >&2
	status=1
fi
rm -f "$log"
exit "$status"
