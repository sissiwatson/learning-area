#!/usr/bin/env bash
# Construit l'APK debug Android (preset "Android Debug", sans build Gradle).
#
# Prérequis (voir docs/ANDROID_EXPORT.md) :
#   - modèles d'export Godot 4.4.1 installés ;
#   - ANDROID_HOME : SDK Android avec platform-tools/adb et build-tools/*/apksigner ;
#   - une clé debug : GODOT_ANDROID_KEYSTORE_DEBUG_PATH (+ _USER, _PASSWORD),
#     par défaut ~/.android/debug.keystore / androiddebugkey / android.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
: "${ANDROID_HOME:?Définir ANDROID_HOME (chemin du SDK Android)}"
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:-$HOME/.android/debug.keystore}"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="${GODOT_ANDROID_KEYSTORE_DEBUG_USER:-androiddebugkey}"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="${GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD:-android}"

# Godot lit le chemin du SDK dans ses réglages d'éditeur : on l'y inscrit.
settings="${GODOT_EDITOR_SETTINGS:-$HOME/.config/godot/editor_settings-4.4.tres}"
if [[ ! -f "$settings" ]]; then
	"$GODOT" --headless --editor --quit >/dev/null 2>&1 || true
fi
if grep -q '^export/android/android_sdk_path' "$settings"; then
	sed -i "s|^export/android/android_sdk_path = .*|export/android/android_sdk_path = \"$ANDROID_HOME\"|" "$settings"
else
	echo "export/android/android_sdk_path = \"$ANDROID_HOME\"" >> "$settings"
fi

out="build/android/island-concierge-debug.apk"
mkdir -p "$(dirname "$out")"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-debug "Android Debug" "$out"
apksigner verify --print-certs "$out" | head -3 || true
ls -lh "$out"
