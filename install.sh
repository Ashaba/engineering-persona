#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
SKILLS_DIR="$CLAUDE_DIR/skills"

mkdir -p "$CLAUDE_DIR" "$SKILLS_DIR"

MARK_BEGIN="<!-- engineering-persona:begin -->"
MARK_END="<!-- engineering-persona:end -->"

# Rebuild the managed block, preserving any existing user content.
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

ln -sfn "$REPO_DIR/skills/pre-flight-review" "$SKILLS_DIR/pre-flight-review"
echo "linked skill into $SKILLS_DIR/pre-flight-review"

echo "note: for Cursor/Windsurf, add these as user rules (best-effort, manual):"
echo "  $REPO_DIR/persona/beliefs.md"
echo "  $REPO_DIR/persona/voice.md"
