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

# Devin: does not expand @-imports, so link each persona file as a global rule.
mkdir -p "$DEVIN_RULES_DIR"
for f in beliefs voice; do
  ln -sfn "$REPO_DIR/persona/$f.md" "$DEVIN_RULES_DIR/engineering-persona-$f.md"
  echo "linked persona $f into $DEVIN_RULES_DIR/engineering-persona-$f.md"
done
link_skills "$DEVIN_DIR/skills"

echo "note: for Cursor/Windsurf, add these as user rules (best-effort, manual):"
echo "  $REPO_DIR/persona/beliefs.md"
echo "  $REPO_DIR/persona/voice.md"
