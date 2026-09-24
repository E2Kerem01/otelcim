#!/usr/bin/env bash
# Reseeds the emulators, then runs Maestro flows sequentially on the one device.
#   .maestro/run.sh                 # everything in config.yaml
#   .maestro/run.sh .maestro/m3_*   # one slice (each flow gets a fresh seed)
# Prereqs: firebase emulators (auth,firestore --project otelcim-7f0ba) running,
# E2E APK installed (flutter build apk --debug --dart-define=E2E_USE_EMULATOR=true).
set -u
export PATH="$HOME/.maestro/bin:/c/Users/kmeti/AppData/Local/Android/Sdk/platform-tools:$PATH"
cd "$(dirname "$0")/.."
OUT=${MAESTRO_OUT:-build/maestro}; mkdir -p "$OUT"
APP=com.example.otelcim
LOCALE=${E2E_LOCALE:-tr}
reset_app() {  # fresh install state, fixed locale, no permission dialogs
  adb shell pm clear $APP >/dev/null
  adb shell cmd locale set-app-locales $APP --locales "$LOCALE" >/dev/null
  for perm in POST_NOTIFICATIONS ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION; do
    adb shell pm grant $APP android.permission.$perm 2>/dev/null
  done
}
flows=("$@"); [ ${#flows[@]} -eq 0 ] && flows=(.maestro/smoke/*.yaml .maestro/m*/*.yaml)
pass=0; fail=0
for f in "${flows[@]}"; do
  [ -d "$f" ] && { set -- "$f"/*.yaml; } || set -- "$f"
  for flow in "$@"; do
    case "$flow" in */common/*|*/seed/*|*/_*) continue;; esac
    profile=$(sed -n 's/^# seed: *\([a-z]*\).*/\1/p' "$flow" | head -1)  # e.g. "# seed: many"
    node .maestro/seed/seed.mjs $profile >/dev/null || { echo "SEED FAILED"; exit 2; }
    reset_app
    name=$(basename "$flow" .yaml)
    if maestro test "$flow" --format junit --output "$OUT/$name.xml" \
         --test-output-dir "$OUT/$name" > "$OUT/$name.log" 2>&1; then
      echo "PASS $flow"; pass=$((pass+1))
    else
      # the app is still on the failing screen: keep its UI tree for debugging
      maestro hierarchy > "$OUT/$name.hierarchy.json" 2>/dev/null
      echo "FAIL $flow  (log: $OUT/$name.log)"; fail=$((fail+1))
    fi
  done
done
echo "TOTAL pass=$pass fail=$fail"
