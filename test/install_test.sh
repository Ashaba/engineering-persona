#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export CLAUDE_HOME="$tmp/.claude"
export DEVIN_HOME="$tmp/.config/devin"
export DEVIN_RULES_HOME="$tmp/.devin/rules"
mkdir -p "$CLAUDE_HOME"
printf '# my notes\nkeep me\n' > "$CLAUDE_HOME/CLAUDE.md"

"$here/install.sh" >/dev/null
grep -q 'keep me' "$CLAUDE_HOME/CLAUDE.md" || { echo "FAIL: clobbered user content"; exit 1; }
grep -q "@$here/persona/beliefs.md" "$CLAUDE_HOME/CLAUDE.md" || { echo "FAIL: beliefs import missing"; exit 1; }
grep -q "@$here/persona/voice.md" "$CLAUDE_HOME/CLAUDE.md" || { echo "FAIL: voice import missing"; exit 1; }
for home in "$CLAUDE_HOME" "$DEVIN_HOME"; do
  for skill in pre-flight-review learn-from-review learn-sweep; do
    [ -L "$home/skills/$skill" ] || { echo "FAIL: $skill not symlinked into $home"; exit 1; }
  done
done
for f in beliefs voice; do
  rule="$DEVIN_RULES_HOME/engineering-persona-$f.md"
  [ "$(readlink "$rule")" = "$here/persona/$f.md" ] || { echo "FAIL: devin $f rule not linked"; exit 1; }
  grep -q '^trigger: always_on$' "$rule" || { echo "FAIL: devin $f rule not always-on"; exit 1; }
done

# idempotent: second run keeps exactly one managed block
"$here/install.sh" >/dev/null
[ "$(grep -c 'engineering-persona:begin' "$CLAUDE_HOME/CLAUDE.md")" -eq 1 ] || { echo "FAIL: duplicate managed block"; exit 1; }

grep -q 'keep me' "$CLAUDE_HOME/CLAUDE.md" || { echo "FAIL: user content lost on second run"; exit 1; }

echo PASS
