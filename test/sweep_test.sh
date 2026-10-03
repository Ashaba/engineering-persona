#!/usr/bin/env bash
# Exercises agent selection in run-sweep.sh with stub agents; never calls a real one.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" PERSONA_STATE_DIR="$tmp/state"
log="$PERSONA_STATE_DIR/sweep.log"

stub() { mkdir -p "$1"; printf '#!/usr/bin/env bash\necho "stub %s ran"\n' "$2" > "$1/$2"; chmod +x "$1/$2"; }
stub "$tmp/both" devin; stub "$tmp/both" claude
stub "$tmp/claude-only" claude

sweep() { : > "$log" 2>/dev/null || true; PATH="$1:/usr/bin:/bin" "$here/run-sweep.sh"; }

sweep "$tmp/both"
grep -q 'stub devin ran' "$log" || { echo "FAIL: devin not preferred"; exit 1; }

sweep "$tmp/claude-only"
grep -q 'stub claude ran' "$log" || { echo "FAIL: claude fallback not used"; exit 1; }

SWEEP_AGENT=claude sweep "$tmp/both"
grep -q 'stub claude ran' "$log" || { echo "FAIL: SWEEP_AGENT override ignored"; exit 1; }

if sweep "$tmp/empty"; then echo "FAIL: ran with no agent"; exit 1; fi
grep -q 'no agent found' "$log" || { echo "FAIL: no-agent message missing"; exit 1; }

echo PASS
