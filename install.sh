#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
DEVIN_DIR="${DEVIN_HOME:-$HOME/.config/devin}"
DEVIN_RULES_DIR="${DEVIN_RULES_HOME:-$HOME/.devin/rules}"

link_skills() {
  mkdir -p "$1"
  for skill_dir in "$REPO_DIR"/skills/*/; do
    name="$(basename "$skill_dir")"
    ln -sfn "${skill_dir%/}" "$1/$name"
    echo "linked skill $name into $1/$name"
  done
}

# The skills reach sideways for the gates and the domain lenses, as
# ../../standards and ../../domains. Installed as a symlink into an agent home,
# that resolves inside the agent home rather than back here, so those have to
# be linked alongside. Without them pre-flight-review reviews against nothing
# and reports a clean diff, which is worse than not running at all.
link_shared() {
  mkdir -p "$1"
  for dir in standards domains persona; do
    ln -sfn "$REPO_DIR/$dir" "$1/$dir"
    echo "linked $dir into $1/$dir"
  done
}

# Register the push gate in the Devin user config, so it applies in every repo
# rather than only those that remembered to add it. Devin collects hooks from
# every source and runs them all, so this sits alongside whatever a project
# defines. Written with python3 to preserve the rest of the file: the config
# holds the model choice and the org id, and clobbering it to add a hook would
# be a poor trade.
install_push_gate() {
  local config="$1"
  mkdir -p "$(dirname "$config")"
  [ -f "$config" ] || echo '{}' > "$config"
  HOOK_CMD="$REPO_DIR/hooks/require-pre-flight-review.sh" python3 - "$config" <<'PY'
import json, os, sys

path, command = sys.argv[1], os.environ["HOOK_CMD"]
with open(path) as fh:
    config = json.load(fh)

entry = {"type": "command", "command": command, "timeout": 10}
pre = config.setdefault("hooks", {}).setdefault("PreToolUse", [])

# Match on our command, not on position: the user may have added hooks of their
# own, and reinstalling must update ours rather than append a duplicate.
for matcher in pre:
    hooks = matcher.get("hooks", [])
    for i, hook in enumerate(hooks):
        if hook.get("command", "").endswith("require-pre-flight-review.sh"):
            hooks[i] = entry
            break
    else:
        continue
    break
else:
    pre.append({"matcher": "^exec$", "hooks": [entry]})

with open(path, "w") as fh:
    json.dump(config, fh, indent=2)
    fh.write("\n")
print(f"registered the pre-flight-review push gate in {path}")
PY
}

# Claude Code: a managed block of @-imports in CLAUDE.md, preserving user content.
mkdir -p "$CLAUDE_DIR"
MARK_BEGIN="<!-- engineering-persona:begin -->"
MARK_END="<!-- engineering-persona:end -->"
if [ -f "$CLAUDE_MD" ]; then
  tmp="$(mktemp)"
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0==b {skip=1} skip && $0==e {skip=0; next} !skip {print}
  ' "$CLAUDE_MD" > "$tmp"
  mv "$tmp" "$CLAUDE_MD"
else
  : > "$CLAUDE_MD"
fi
{
  printf '%s\n' "$MARK_BEGIN"
  printf '@%s/persona/beliefs.md\n' "$REPO_DIR"
  printf '@%s/persona/voice.md\n' "$REPO_DIR"
  printf '%s\n' "$MARK_END"
} >> "$CLAUDE_MD"
echo "linked persona into $CLAUDE_MD"
link_skills "$CLAUDE_DIR/skills"
link_shared "$CLAUDE_DIR"

# Devin: does not expand @-imports, so link each persona file as a global rule.
mkdir -p "$DEVIN_RULES_DIR"
for f in beliefs voice; do
  ln -sfn "$REPO_DIR/persona/$f.md" "$DEVIN_RULES_DIR/engineering-persona-$f.md"
  echo "linked persona $f into $DEVIN_RULES_DIR/engineering-persona-$f.md"
done
link_skills "$DEVIN_DIR/skills"
link_shared "$DEVIN_DIR"
install_push_gate "$DEVIN_DIR/config.json"

echo "note: for Cursor/Windsurf, add these as user rules (best-effort, manual):"
echo "  $REPO_DIR/persona/beliefs.md"
echo "  $REPO_DIR/persona/voice.md"
