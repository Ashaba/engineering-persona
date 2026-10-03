#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${PERSONA_STATE_DIR:-$HOME/.local/state/engineering-persona}"
LOG="${SWEEP_LOG:-$STATE_DIR/sweep.log}"
# launchd starts jobs with a minimal PATH that misses user-installed CLIs.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
AGENT="${SWEEP_AGENT:-}"
if [ -z "$AGENT" ]; then
  for candidate in devin claude; do
    command -v "$candidate" >/dev/null && { AGENT="$candidate"; break; }
  done
fi
mkdir -p "$STATE_DIR" "$(dirname "$LOG")"
cd "$REPO_DIR"

PROMPT="Run the learn-sweep skill: sweep new eg-internal PR reviews since the watermark, generalize and scrub them into persona rules, dedup, and open a single gated PR on this repo. Do not merge it, do not commit to main, do not post to any source PR."

run_claude() {
  claude -p "$PROMPT" \
    --add-dir "$REPO_DIR" --add-dir "$STATE_DIR" \
    --allowed-tools "Bash(git checkout *) Bash(git switch *) Bash(git branch *) Bash(git add *) Bash(git commit *) Bash(git push *) Bash(git diff *) Bash(git status *) Bash(git rev-parse *) Bash(git log *) Bash(gh pr view *) Bash(gh pr list *) Bash(gh pr create *) Bash(gh search *) Bash(gh auth *) Bash($REPO_DIR/scrub-check.sh *) Read Edit Write" \
    --permission-mode acceptEdits
}

# Print mode rejects any tool call that is not allowlisted, so this file is the scope.
run_devin() {
  local cfg; cfg="$(mktemp)"
  trap 'rm -f "$cfg"' RETURN
  cat > "$cfg" <<JSON
{
  "version": 1,
  "permissions": {
    "allow": [
      "Read($REPO_DIR/**)", "Write($REPO_DIR/**)",
      "Read($STATE_DIR/**)", "Write($STATE_DIR/**)",
      "Exec(git checkout)", "Exec(git switch)", "Exec(git branch)", "Exec(git add)",
      "Exec(git commit)", "Exec(git push)", "Exec(git diff)", "Exec(git status)",
      "Exec(git rev-parse)", "Exec(git log)",
      "Exec(gh pr view)", "Exec(gh pr list)", "Exec(gh pr create)", "Exec(gh search)", "Exec(gh auth)",
      "Exec(./scrub-check.sh)", "Exec($REPO_DIR/scrub-check.sh)"
    ],
    "deny": [
      "Exec(gh pr merge)", "Exec(gh pr review)", "Exec(gh pr comment)", "Exec(gh api)",
      "Exec(git push --force)", "Exec(git push -f)", "Exec(git push origin main)"
    ]
  }
}
JSON
  devin -p "$PROMPT" --config "$cfg" --permission-mode accept-edits --respect-workspace-trust false
}

{
  echo "=== sweep ($AGENT) $(date -u +%FT%TZ) ==="
  case "$AGENT" in
    claude) run_claude ;;
    devin) run_devin ;;
    "") echo "no agent found: install devin or claude, or set SWEEP_AGENT"; exit 2 ;;
    *) echo "unknown SWEEP_AGENT: $AGENT (use devin or claude)"; exit 2 ;;
  esac
  echo "=== done $(date -u +%FT%TZ) ==="
} >> "$LOG" 2>&1
