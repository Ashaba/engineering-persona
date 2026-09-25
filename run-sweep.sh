#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${SWEEP_LOG:-$HOME/.claude/engineering-persona/sweep.log}"
mkdir -p "$(dirname "$LOG")"
cd "$REPO_DIR"

PROMPT="Run the learn-sweep skill: sweep new eg-internal PR reviews since the watermark, generalize and scrub them into persona rules, dedup, and open a single gated PR on this repo. Do not merge it, do not commit to main, do not post to any source PR."

{
  echo "=== sweep $(date -u +%FT%TZ) ==="
  claude -p "$PROMPT" \
    --add-dir "$REPO_DIR" \
    --allowed-tools "Bash(git checkout *) Bash(git switch *) Bash(git branch *) Bash(git add *) Bash(git commit *) Bash(git push *) Bash(git diff *) Bash(git status *) Bash(git rev-parse *) Bash(git log *) Bash(gh pr view *) Bash(gh pr list *) Bash(gh pr create *) Bash(gh search *) Bash(gh auth *) Bash($REPO_DIR/scrub-check.sh *) Read Edit Write" \
    --permission-mode acceptEdits
  echo "=== done $(date -u +%FT%TZ) ==="
} >> "$LOG" 2>&1
