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

# The skills read ../../standards and ../../domains relative to where they are
# installed, so those have to be linked alongside. Missing, pre-flight-review
# reviews against no gates at all and reports the diff clean.
for home in "$CLAUDE_HOME" "$DEVIN_HOME"; do
  for shared in standards domains persona; do
    [ "$(readlink "$home/$shared")" = "$here/$shared" ] \
      || { echo "FAIL: $shared not linked into $home"; exit 1; }
  done
  [ -f "$home/skills/pre-flight-review/../../standards/review-checklist.md" ] \
    || { echo "FAIL: gates unreachable from the installed skill in $home"; exit 1; }
done

# The push gate is registered globally, and reinstalling updates it in place.
gate_count() {
  python3 -c '
import json, sys
hooks = json.load(open(sys.argv[1])).get("hooks", {}).get("PreToolUse", [])
print(sum(1 for m in hooks for h in m.get("hooks", [])
          if h.get("command", "").endswith("require-pre-flight-review.sh")))
' "$1"
}
[ "$(gate_count "$DEVIN_HOME/config.json")" -eq 1 ] \
  || { echo "FAIL: push gate not registered exactly once"; exit 1; }

# A pre-existing config must survive having the hook added to it.
python3 -c '
import json, sys
c = json.load(open(sys.argv[1])); c["theme_mode"] = "dark"; json.dump(c, open(sys.argv[1], "w"))
' "$DEVIN_HOME/config.json"
"$here/install.sh" >/dev/null
[ "$(gate_count "$DEVIN_HOME/config.json")" -eq 1 ] \
  || { echo "FAIL: push gate duplicated on reinstall"; exit 1; }
grep -q '"theme_mode"' "$DEVIN_HOME/config.json" \
  || { echo "FAIL: existing user config clobbered"; exit 1; }

echo PASS
