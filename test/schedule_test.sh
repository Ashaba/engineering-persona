#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export LAUNCH_AGENTS_DIR="$tmp/agents"
plist="$LAUNCH_AGENTS_DIR/com.engineering-persona.learn-sweep.plist"

"$here/schedule-sweep.sh" >/dev/null
[ -f "$plist" ] || { echo "FAIL: plist not installed"; exit 1; }
grep -q 'run-sweep.sh' "$plist" || { echo "FAIL: plist missing program"; exit 1; }
grep -q '<key>StartCalendarInterval</key>' "$plist" || { echo "FAIL: no schedule"; exit 1; }

"$here/schedule-sweep.sh" --remove >/dev/null
if [ -e "$plist" ]; then echo "FAIL: plist not removed"; exit 1; fi
echo PASS
