#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export LAUNCH_AGENTS_DIR="$tmp/agents"
export PERSONA_STATE_DIR="$tmp/state"
plist="$LAUNCH_AGENTS_DIR/com.engineering-persona.learn-sweep.plist"

"$here/schedule-sweep.sh" >/dev/null
[ -f "$plist" ] || { echo "FAIL: plist not installed"; exit 1; }
grep -q 'run-sweep.sh' "$plist" || { echo "FAIL: plist missing program"; exit 1; }
grep -q '<key>StartCalendarInterval</key>' "$plist" || { echo "FAIL: no schedule"; exit 1; }
if grep -q 'SWEEP_AGENT' "$plist"; then echo "FAIL: default should leave agent to auto-detect"; exit 1; fi
plutil -lint "$plist" >/dev/null || { echo "FAIL: invalid plist"; exit 1; }

SWEEP_AGENT=claude "$here/schedule-sweep.sh" >/dev/null
grep -q '<string>claude</string>' "$plist" || { echo "FAIL: SWEEP_AGENT not honored"; exit 1; }
plutil -lint "$plist" >/dev/null || { echo "FAIL: invalid plist with agent"; exit 1; }

"$here/schedule-sweep.sh" --remove >/dev/null
if [ -e "$plist" ]; then echo "FAIL: plist not removed"; exit 1; fi
echo PASS
