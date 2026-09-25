#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export CLAUDE_HOME="$tmp/.claude"
mkdir -p "$CLAUDE_HOME"
printf '# my notes\nkeep me\n' > "$CLAUDE_HOME/CLAUDE.md"

"$here/install.sh" >/dev/null
grep -q 'keep me' "$CLAUDE_HOME/CLAUDE.md" || { echo "FAIL: clobbered user content"; exit 1; }
grep -q "@$here/persona/beliefs.md" "$CLAUDE_HOME/CLAUDE.md" || { echo "FAIL: beliefs import missing"; exit 1; }
grep -q "@$here/persona/voice.md" "$CLAUDE_HOME/CLAUDE.md" || { echo "FAIL: voice import missing"; exit 1; }
[ -L "$CLAUDE_HOME/skills/pre-flight-review" ] || { echo "FAIL: skill not symlinked"; exit 1; }

# idempotent: second run keeps exactly one managed block
"$here/install.sh" >/dev/null
[ "$(grep -c 'engineering-persona:begin' "$CLAUDE_HOME/CLAUDE.md")" -eq 1 ] || { echo "FAIL: duplicate managed block"; exit 1; }

grep -q 'keep me' "$CLAUDE_HOME/CLAUDE.md" || { echo "FAIL: user content lost on second run"; exit 1; }

echo PASS
